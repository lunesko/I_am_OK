//! UDP транспорт с поддержкой DTLS (UDP over TLS)

use crate::transport::{Transport, TransportType, TransportError, Peer};
use async_trait::async_trait;
use tokio::net::TcpStream;
use tokio_rustls::TlsConnector;
use std::sync::Arc;
use tokio::io::{AsyncReadExt, AsyncWriteExt};

/// Конфигурация для UDP транспорта с DTLS
pub struct UdpTransportConfig {
    /// URL relay сервера (например, "i-am-ok-relay.fly.dev:40100")
    pub relay_url: String,
    
    /// SHA-256 fingerprint сертификата для certificate pinning
    /// Формат: "A1:B2:C3:D4:..." (hex с двоеточиями)
    pub pinned_cert_fingerprint: Option<String>,
    
    /// Отключить проверку TLS (только для тестирования!)
    pub tls_disabled: bool,
}

impl Default for UdpTransportConfig {
    fn default() -> Self {
        Self {
            relay_url: "i-am-ok-relay.fly.dev:40100".to_string(),
            pinned_cert_fingerprint: None,
            tls_disabled: false,
        }
    }
}

pub struct UdpTransport {
    pub(crate) config: UdpTransportConfig,
}

impl UdpTransport {
    pub fn new() -> Self {
        Self {
            config: UdpTransportConfig::default(),
        }
    }
    
    pub fn with_config(config: UdpTransportConfig) -> Self {
        Self { config }
    }
    
    /// Create TLS connection to relay server
    async fn connect_tls(&self) -> Result<tokio_rustls::client::TlsStream<TcpStream>, TransportError> {
        // Parse hostname from relay URL
        let host = self.config.relay_url
            .split(':')
            .next()
            .ok_or_else(|| TransportError::SendFailed("Invalid relay URL".to_string()))?;
        
        // Create TLS config with optional certificate pinning
        let tls_config = crate::transport::dtls::create_tls_config(
            self.config.pinned_cert_fingerprint.clone()
        ).map_err(|e| TransportError::SecurityError(format!("TLS config failed: {}", e)))?;
        
        let connector = TlsConnector::from(tls_config);
        
        // Connect TCP socket
        let tcp_stream = TcpStream::connect(&self.config.relay_url)
            .await
            .map_err(|e| TransportError::SendFailed(format!("TCP connect failed: {}", e)))?;
        
        // Perform TLS handshake
        let server_name = rustls::pki_types::ServerName::try_from(host.to_string())
            .map_err(|e| TransportError::SecurityError(format!("Invalid server name: {}", e)))?;
        
        let tls_stream = connector.connect(server_name, tcp_stream)
            .await
            .map_err(|e| TransportError::SecurityError(format!("TLS handshake failed: {}", e)))?;
        
        Ok(tls_stream)
    }
    
    /// Проверить certificate pinning (deprecated - now handled by PinnedCertVerifier)
    /// 
    /// Addresses FR-RELAY-001-05: System SHALL verify relay TLS certificate
    #[deprecated(note = "Certificate pinning is now handled by dtls::PinnedCertVerifier")]
    #[allow(dead_code)]
    pub(crate) fn verify_certificate_pin(&self, cert_fingerprint: &str) -> Result<(), TransportError> {
        if let Some(ref pinned) = self.config.pinned_cert_fingerprint {
            if cert_fingerprint != pinned {
                return Err(TransportError::SecurityError(
                    format!("Certificate pinning failed: expected {}, got {}", pinned, cert_fingerprint)
                ));
            }
        }
        Ok(())
    }
}

#[async_trait]
impl Transport for UdpTransport {
    fn transport_type(&self) -> TransportType {
        TransportType::Udp
    }

    async fn is_available(&self) -> bool {
        // Check if we can resolve relay URL
        if self.config.tls_disabled {
            return false; // TLS required for production
        }
        
        // Try to resolve relay hostname
        use tokio::net::lookup_host;
        match lookup_host(&self.config.relay_url).await {
            Ok(mut addrs) => addrs.next().is_some(),
            Err(_) => false,
        }
    }

    async fn send_packet(&self, packet: &crate::core::Packet, _destination: &str) -> Result<(), TransportError> {
        // Check if TLS is disabled (only for testing)
        if self.config.tls_disabled {
            return Err(TransportError::SecurityError("TLS is required for production".to_string()));
        }
        
        // Serialize packet to CBOR
        let mut packet_bytes = Vec::new();
        ciborium::ser::into_writer(packet, &mut packet_bytes)
            .map_err(|e| TransportError::SendFailed(format!("Serialization failed: {}", e)))?;
        
        // Create length-prefixed frame: [4 bytes length][packet data]
        let packet_len = packet_bytes.len() as u32;
        let mut frame = Vec::with_capacity(4 + packet_bytes.len());
        frame.extend_from_slice(&packet_len.to_be_bytes());
        frame.extend_from_slice(&packet_bytes);
        
        // Connect with TLS
        let mut tls_stream = self.connect_tls().await?;
        
        // Send packet
        tls_stream.write_all(&frame)
            .await
            .map_err(|e| TransportError::SendFailed(format!("Write failed: {}", e)))?;
        
        // Flush to ensure packet is sent
        tls_stream.flush()
            .await
            .map_err(|e| TransportError::SendFailed(format!("Flush failed: {}", e)))?;
        
        Ok(())
    }

    async fn discover_peers(&self) -> Result<Vec<Peer>, TransportError> {
        Ok(Vec::new())
    }

    async fn start_listening(&self, callback: Box<dyn Fn(crate::core::Packet) + Send + Sync>) -> Result<(), TransportError> {
        // Check if TLS is disabled
        if self.config.tls_disabled {
            return Err(TransportError::SecurityError("TLS is required for production".to_string()));
        }
        
        // Connect with TLS
        let mut tls_stream = self.connect_tls().await?;
        
        // Wrap callback in Arc for sharing across async tasks
        let callback = Arc::new(callback);
        
        // Read packets in a loop
        loop {
            // Read length prefix (4 bytes, big-endian)
            let mut len_bytes = [0u8; 4];
            match tls_stream.read_exact(&mut len_bytes).await {
                Ok(_) => {},
                Err(e) if e.kind() == std::io::ErrorKind::UnexpectedEof => {
                    // Connection closed gracefully
                    break;
                },
                Err(e) => {
                    return Err(TransportError::ReceiveFailed(format!("Read length failed: {}", e)));
                }
            }
            
            let packet_len = u32::from_be_bytes(len_bytes) as usize;
            
            // Sanity check: reject packets larger than 128KB
            if packet_len > 128 * 1024 {
                return Err(TransportError::ReceiveFailed(
                    format!("Packet too large: {} bytes", packet_len)
                ));
            }
            
            // Read packet data
            let mut packet_bytes = vec![0u8; packet_len];
            tls_stream.read_exact(&mut packet_bytes)
                .await
                .map_err(|e| TransportError::ReceiveFailed(format!("Read packet failed: {}", e)))?;
            
            // Deserialize packet
            match ciborium::de::from_reader(&packet_bytes[..]) {
                Ok(packet) => {
                    // Call callback with received packet
                    callback(packet);
                },
                Err(e) => {
                    // Log deserialization error but continue listening
                    eprintln!("Failed to deserialize packet: {}", e);
                    continue;
                }
            }
        }
        
        Ok(())
    }

    async fn stop_listening(&self) -> Result<(), TransportError> {
        Ok(())
    }
}