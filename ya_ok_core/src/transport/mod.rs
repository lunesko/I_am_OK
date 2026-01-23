//! Transport - транспортный слой
//!
//! Абстракция над различными каналами связи:
//! - BLE (Bluetooth Low Energy)
//! - Wi-Fi Direct
//! - UDP/IP (когда есть интернет)
//! - Спутниковые каналы (абстракция)

pub mod ble;
pub mod wifi_direct;
pub mod udp;
pub mod satellite;

use crate::core::Packet;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

/// Тип транспортного канала
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum TransportType {
    Ble,
    WifiDirect,
    Udp,
    Satellite,
}

/// Интерфейс транспорта
#[async_trait]
pub trait Transport: Send + Sync {
    /// Тип транспорта
    fn transport_type(&self) -> TransportType;

    /// Доступен ли транспорт
    async fn is_available(&self) -> bool;

    /// Отправить пакет
    async fn send_packet(&self, packet: &Packet, destination: &str) -> Result<(), TransportError>;

    /// Получить доступные узлы для обнаружения
    async fn discover_peers(&self) -> Result<Vec<Peer>, TransportError>;

    /// Начать прослушивание входящих пакетов
    async fn start_listening(&self, callback: Box<dyn Fn(Packet) + Send + Sync>) -> Result<(), TransportError>;

    /// Остановить прослушивание
    async fn stop_listening(&self) -> Result<(), TransportError>;
}

/// Информация об узле
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Peer {
    /// ID узла
    pub id: String,
    /// Тип транспорта
    pub transport_type: TransportType,
    /// Адрес/идентификатор для подключения
    pub address: String,
    /// Последнее время активности
    pub last_seen: chrono::DateTime<chrono::Utc>,
    /// Уровень сигнала (опционально)
    pub signal_strength: Option<i32>,
    /// Ed25519 публичный ключ (для верификации подписей)
    pub ed25519_public_key: Option<Vec<u8>>,
    /// X25519 публичный ключ (для ECDH шифрования)
    pub x25519_public_key: Option<Vec<u8>>,
}

/// Менеджер транспорта
pub struct TransportManager {
    transports: Vec<Box<dyn Transport>>,
}

impl TransportManager {
    pub fn new() -> Self {
        Self {
            transports: Vec::new(),
        }
    }

    /// Добавить транспорт
    pub fn add_transport(&mut self, transport: Box<dyn Transport>) {
        self.transports.push(transport);
    }

    /// Получить доступные транспорты
    pub fn available_transports(&self) -> Vec<TransportType> {
        self.transports
            .iter()
            .map(|t| t.transport_type())
            .collect()
    }

    /// Получить транспорт по типу
    pub fn get_transport(&self, transport_type: TransportType) -> Option<&dyn Transport> {
        self.transports
            .iter()
            .find(|t| t.transport_type() == transport_type)
            .map(|t| t.as_ref())
    }

    /// Отправить пакет через лучший доступный транспорт
    pub async fn send_packet(&self, packet: &Packet, destination: &str) -> Result<(), TransportError> {
        // Выбираем транспорт по приоритету
        let transport_order = [
            TransportType::Udp,        // Интернет - самый быстрый
            TransportType::WifiDirect, // Wi-Fi Direct - надежный
            TransportType::Ble,        // BLE - самый медленный но всегда есть
            TransportType::Satellite,  // Спутник - последний шанс
        ];

        for transport_type in &transport_order {
            if let Some(transport) = self.transports.iter().find(|t| t.transport_type() == *transport_type) {
                if transport.is_available().await {
                    return transport.send_packet(packet, destination).await;
                }
            }
        }

        Err(TransportError::NoTransportAvailable)
    }

    /// Обнаружить всех доступных пиров
    pub async fn discover_all_peers(&self) -> Result<Vec<Peer>, TransportError> {
        let mut all_peers = Vec::new();

        for transport in &self.transports {
            if transport.is_available().await {
                match transport.discover_peers().await {
                    Ok(mut peers) => all_peers.append(&mut peers),
                    Err(_) => continue, // Игнорируем ошибки отдельных транспортов
                }
            }
        }

        Ok(all_peers)
    }
}

impl Default for TransportManager {
    fn default() -> Self {
        Self::new()
    }
}

/// Ошибки транспорта
#[derive(Debug, thiserror::Error)]
pub enum TransportError {
    #[error("Transport not available")]
    NotAvailable,

    #[error("No transport available")]
    NoTransportAvailable,

    #[error("Send failed: {0}")]
    SendFailed(String),

    #[error("Receive failed: {0}")]
    ReceiveFailed(String),

    #[error("Discovery failed: {0}")]
    DiscoveryFailed(String),

    #[error("Invalid address: {0}")]
    InvalidAddress(String),

    #[error("Connection timeout")]
    Timeout,

    #[error("MTU exceeded")]
    MtuExceeded,
}