//! BLE транспорт
//!
//! Базовая реализация BLE (Bluetooth Low Energy) для mesh-сети.
//! Использует FFI для вызова platform-specific кода (Android/iOS).

use crate::transport::{Transport, TransportType, TransportError, Peer};
use async_trait::async_trait;
use std::sync::Arc;
use tokio::sync::Mutex;

/// BLE Service UUID для Ya OK
/// Format: 0000xxxx-0000-1000-8000-00805f9b34fb
const YAOK_SERVICE_UUID: &str = "0000CAFE-0000-1000-8000-00805f9b34fb";

/// BLE Characteristic UUID для packet передачи
const YAOK_PACKET_CHAR_UUID: &str = "0000BEEF-0000-1000-8000-00805f9b34fb";

/// Platform-specific BLE interface (FFI)
#[repr(C)]
pub struct BleNativeInterface {
    /// Start BLE advertising
    pub start_advertising: extern "C" fn(*const u8, usize) -> i32,
    /// Stop BLE advertising
    pub stop_advertising: extern "C" fn() -> i32,
    /// Start BLE scanning
    pub start_scanning: extern "C" fn() -> i32,
    /// Stop BLE scanning
    pub stop_scanning: extern "C" fn() -> i32,
    /// Send packet via GATT
    pub send_gatt_packet: extern "C" fn(*const u8, usize, *const u8, usize) -> i32,
    /// Check if BLE is available
    pub is_ble_available: extern "C" fn() -> i32,
}

/// Stub implementations for non-Android/iOS platforms
#[cfg(not(any(target_os = "android", target_os = "ios")))]
extern "C" fn stub_start_advertising(_data: *const u8, _len: usize) -> i32 { -1 }
#[cfg(not(any(target_os = "android", target_os = "ios")))]
extern "C" fn stub_stop_advertising() -> i32 { -1 }
#[cfg(not(any(target_os = "android", target_os = "ios")))]
extern "C" fn stub_start_scanning() -> i32 { -1 }
#[cfg(not(any(target_os = "android", target_os = "ios")))]
extern "C" fn stub_stop_scanning() -> i32 { -1 }
#[cfg(not(any(target_os = "android", target_os = "ios")))]
extern "C" fn stub_send_gatt_packet(_addr: *const u8, _addr_len: usize, _data: *const u8, _data_len: usize) -> i32 { -1 }
#[cfg(not(any(target_os = "android", target_os = "ios")))]
extern "C" fn stub_is_ble_available() -> i32 { 0 }

/// Default stub interface for testing/desktop
#[cfg(not(any(target_os = "android", target_os = "ios")))]
fn get_default_interface() -> BleNativeInterface {
    BleNativeInterface {
        start_advertising: stub_start_advertising,
        stop_advertising: stub_stop_advertising,
        start_scanning: stub_start_scanning,
        stop_scanning: stub_stop_scanning,
        send_gatt_packet: stub_send_gatt_packet,
        is_ble_available: stub_is_ble_available,
    }
}

pub struct BleTransport {
    native_interface: Arc<BleNativeInterface>,
    is_listening: Arc<Mutex<bool>>,
}

impl BleTransport {
    pub fn new() -> Self {
        Self {
            #[cfg(not(any(target_os = "android", target_os = "ios")))]
            native_interface: Arc::new(get_default_interface()),
            #[cfg(any(target_os = "android", target_os = "ios"))]
            native_interface: Arc::new(Self::get_platform_interface()),
            is_listening: Arc::new(Mutex::new(false)),
        }
    }
    
    /// Set custom native interface (for testing or platform initialization)
    pub fn with_interface(interface: BleNativeInterface) -> Self {
        Self {
            native_interface: Arc::new(interface),
            is_listening: Arc::new(Mutex::new(false)),
        }
    }
    
    /// Get platform-specific interface (implemented on Android/iOS)
    #[cfg(any(target_os = "android", target_os = "ios"))]
    fn get_platform_interface() -> BleNativeInterface {
        // This would be initialized by JNI on Android or Swift on iOS
        // For now, return stub (actual implementation in platform layer)
        unsafe { std::mem::zeroed() }
    }
}

#[async_trait]
impl Transport for BleTransport {
    fn transport_type(&self) -> TransportType {
        TransportType::Ble
    }

    async fn is_available(&self) -> bool {
        // Call native BLE check
        let result = (self.native_interface.is_ble_available)();
        result > 0
    }

    async fn send_packet(&self, packet: &crate::core::Packet, destination: &str) -> Result<(), TransportError> {
        // Serialize packet to CBOR
        let mut packet_bytes = Vec::new();
        ciborium::ser::into_writer(packet, &mut packet_bytes)
            .map_err(|e| TransportError::SendFailed(format!("Serialization failed: {}", e)))?;
        
        // BLE GATT has MTU limit (typically 512 bytes)
        // For larger packets, we need chunking (handled by transport::chunking module)
        const BLE_MTU: usize = 512;
        if packet_bytes.len() > BLE_MTU {
            return Err(TransportError::SendFailed(
                format!("Packet too large for BLE: {} bytes (max {}). Use chunking.", 
                    packet_bytes.len(), BLE_MTU)
            ));
        }
        
        // Convert destination address to bytes
        let dest_bytes = destination.as_bytes();
        
        // Send via GATT characteristic
        let result = (self.native_interface.send_gatt_packet)(
            dest_bytes.as_ptr(),
            dest_bytes.len(),
            packet_bytes.as_ptr(),
            packet_bytes.len(),
        );
        
        if result < 0 {
            return Err(TransportError::SendFailed("BLE GATT send failed".to_string()));
        }
        
        Ok(())
    }

    async fn discover_peers(&self) -> Result<Vec<Peer>, TransportError> {
        // Start BLE scanning
        let result = (self.native_interface.start_scanning)();
        
        if result < 0 {
            return Err(TransportError::NotAvailable);
        }
        
        // In real implementation, this would:
        // 1. Scan for BLE devices advertising YAOK_SERVICE_UUID
        // 2. Read device addresses and names
        // 3. Return list of discovered peers
        
        // For now, return empty list (actual scanning happens in platform layer)
        Ok(Vec::new())
    }

    async fn start_listening(&self, _callback: Box<dyn Fn(crate::core::Packet) + Send + Sync>) -> Result<(), TransportError> {
        let mut is_listening = self.is_listening.lock().await;
        
        if *is_listening {
            return Err(TransportError::AlreadyListening);
        }
        
        // Prepare advertising data (service UUID)
        let adv_data = YAOK_SERVICE_UUID.as_bytes();
        
        // Start BLE advertising
        let result = (self.native_interface.start_advertising)(
            adv_data.as_ptr(),
            adv_data.len(),
        );
        
        if result < 0 {
            return Err(TransportError::NotAvailable);
        }
        
        *is_listening = true;
        
        // In real implementation, platform layer would:
        // 1. Start GATT server with YAOK_SERVICE_UUID
        // 2. Listen for writes to YAOK_PACKET_CHAR_UUID
        // 3. Deserialize packets and call callback
        // 4. Handle characteristic subscription/notification
        
        Ok(())
    }

    async fn stop_listening(&self) -> Result<(), TransportError> {
        let mut is_listening = self.is_listening.lock().await;
        
        if !*is_listening {
            return Ok(()); // Already stopped
        }
        
        // Stop BLE advertising
        let result = (self.native_interface.stop_advertising)();
        
        if result < 0 {
            return Err(TransportError::ReceiveFailed("Failed to stop advertising".to_string()));
        }
        
        *is_listening = false;
        Ok(())
    }
}