//! UDP транспорт

use crate::transport::{Transport, TransportType, TransportError, Peer};
use async_trait::async_trait;

pub struct UdpTransport;

impl UdpTransport {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl Transport for UdpTransport {
    fn transport_type(&self) -> TransportType {
        TransportType::Udp
    }

    async fn is_available(&self) -> bool {
        // TODO: проверить доступность интернета
        false // Пока не реализовано
    }

    async fn send_packet(&self, _packet: &crate::core::Packet, _destination: &str) -> Result<(), TransportError> {
        Err(TransportError::NotAvailable)
    }

    async fn discover_peers(&self) -> Result<Vec<Peer>, TransportError> {
        Ok(Vec::new())
    }

    async fn start_listening(&self, _callback: Box<dyn Fn(crate::core::Packet) + Send + Sync>) -> Result<(), TransportError> {
        Err(TransportError::NotAvailable)
    }

    async fn stop_listening(&self) -> Result<(), TransportError> {
        Ok(())
    }
}