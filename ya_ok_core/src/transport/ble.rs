//! BLE транспорт

use crate::transport::{Transport, TransportType, TransportError, Peer};
use async_trait::async_trait;

pub struct BleTransport;

impl BleTransport {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl Transport for BleTransport {
    fn transport_type(&self) -> TransportType {
        TransportType::Ble
    }

    async fn is_available(&self) -> bool {
        // TODO: проверить доступность BLE
        true
    }

    async fn send_packet(&self, _packet: &crate::core::Packet, _destination: &str) -> Result<(), TransportError> {
        // TODO: реализовать BLE отправку
        Ok(())
    }

    async fn discover_peers(&self) -> Result<Vec<Peer>, TransportError> {
        // TODO: сканировать BLE устройства
        Ok(Vec::new())
    }

    async fn start_listening(&self, _callback: Box<dyn Fn(crate::core::Packet) + Send + Sync>) -> Result<(), TransportError> {
        // TODO: начать прослушивание BLE
        Ok(())
    }

    async fn stop_listening(&self) -> Result<(), TransportError> {
        // TODO: остановить прослушивание BLE
        Ok(())
    }
}