//! Routing - маршрутизация DTN (Store & Forward)
//!
//! Реализует Delay/Disruption Tolerant Networking:
//! - Store & Forward
//! - Приоритеты
//! - Flooding с дедупликацией
//! - TTL управление

use crate::core::{Packet, Priority};
use crate::storage::Storage;
use crate::transport::{TransportManager, Peer};
use async_trait::async_trait;
use std::collections::HashMap;
use tokio::sync::RwLock;
use chrono::{DateTime, Utc};

/// Интерфейс маршрутизатора
#[async_trait]
pub trait Router: Send + Sync {
    /// Обработать входящий пакет
    async fn handle_packet(&self, packet: Packet) -> Result<(), RoutingError>;

    /// Отправить пакет получателю
    async fn send_to(&self, packet: &Packet, destination: &str) -> Result<(), RoutingError>;

    /// Flood пакет всем известным узлам
    async fn flood_packet(&self, packet: Packet) -> Result<(), RoutingError>;

    /// Получить статистику маршрутизации
    async fn get_stats(&self) -> RoutingStats;
}

/// DTN маршрутизатор
pub struct DtnRouter {
    storage: Storage,
    transport_manager: TransportManager,
    /// Кэш известных узлов
    known_peers: RwLock<HashMap<String, Peer>>,
    /// Статистика
    stats: RwLock<RoutingStats>,
}

impl DtnRouter {
    pub fn new(storage: Storage, transport_manager: TransportManager) -> Self {
        Self {
            storage,
            transport_manager,
            known_peers: RwLock::new(HashMap::new()),
            stats: RwLock::new(RoutingStats::default()),
        }
    }

    /// Обновить список известных пиров
    pub async fn update_peers(&self, peers: Vec<Peer>) {
        let mut known_peers = self.known_peers.write().await;
        for peer in peers {
            known_peers.insert(peer.id.clone(), peer);
        }
    }

    /// Проверить, можем ли мы forward пакет
    fn can_forward(packet: &Packet) -> bool {
        !packet.is_expired() && packet.can_forward()
    }

    /// Выбрать лучший транспорт для пакета
    fn select_transport(&self, packet: &Packet) -> Option<&dyn crate::transport::Transport> {
        // Для высокоприоритетных пакетов используем быстрые транспорты
        match packet.priority {
            Priority::High => {
                // Сначала UDP, потом Wi-Fi Direct
                if let Some(transport) = self.transport_manager.transports.iter()
                    .find(|t| t.transport_type() == crate::transport::TransportType::Udp) {
                    return Some(&**transport);
                }
                if let Some(transport) = self.transport_manager.transports.iter()
                    .find(|t| t.transport_type() == crate::transport::TransportType::WifiDirect) {
                    return Some(&**transport);
                }
            }
            Priority::Medium => {
                // Wi-Fi Direct или BLE
                if let Some(transport) = self.transport_manager.transports.iter()
                    .find(|t| t.transport_type() == crate::transport::TransportType::WifiDirect) {
                    return Some(&**transport);
                }
            }
            Priority::Low => {
                // Любой доступный
            }
        }

        // Fallback: BLE (всегда доступен)
        self.transport_manager.transports.iter()
            .find(|t| t.transport_type() == crate::transport::TransportType::Ble)
            .map(|t| &**t)
    }
}

#[async_trait]
impl Router for DtnRouter {
    async fn handle_packet(&self, mut packet: Packet) -> Result<(), RoutingError> {
        let mut stats = self.stats.write().await;

        // Проверяем, можем ли forward
        if !Self::can_forward(&packet) {
            stats.dropped_packets += 1;
            return Ok(()); // Пакет истек или превысил лимит hops
        }

        // Проверяем дедупликацию
        if self.storage.is_message_seen(&packet.message_id)? {
            stats.duplicate_packets += 1;
            return Ok(()); // Уже видели
        }

        // Помечаем как seen
        self.storage.mark_message_seen(&packet.message_id)?;

        // Сохраняем для локальной доставки (если мы получатель)
        // TODO: проверка получателя

        // Увеличиваем hops
        packet.increment_hops();

        // Forward всем известным пирам (flooding)
        self.flood_packet(packet).await?;

        stats.processed_packets += 1;
        Ok(())
    }

    async fn send_to(&self, packet: &Packet, destination: &str) -> Result<(), RoutingError> {
        let known_peers = self.known_peers.read().await;

        if let Some(peer) = known_peers.get(destination) {
            // Отправляем напрямую получателю
            self.transport_manager.send_packet(packet, &peer.address).await?;
        } else {
            // Не знаем получателя - делаем flooding
            self.flood_packet(packet.clone()).await?;
        }

        Ok(())
    }

    async fn flood_packet(&self, packet: Packet) -> Result<(), RoutingError> {
        let known_peers = self.known_peers.read().await;

        if known_peers.is_empty() {
            // Нет известных пиров - сохраняем для поздней отправки
            let message = packet.decrypt(&self.storage, &[])?; // TODO: decryption
            self.storage.store_message(&message)?;
            return Ok(());
        }

        // Отправляем всем известным пирам
        for peer in known_peers.values() {
            if let Err(_) = self.transport_manager.send_packet(&packet, &peer.address).await {
                // Игнорируем ошибки отправки
                continue;
            }
        }

        Ok(())
    }

    async fn get_stats(&self) -> RoutingStats {
        self.stats.read().await.clone()
    }
}

/// Статистика маршрутизации
#[derive(Clone, Debug, Default, serde::Serialize, serde::Deserialize)]
pub struct RoutingStats {
    pub processed_packets: u64,
    pub dropped_packets: u64,
    pub duplicate_packets: u64,
    pub forwarded_packets: u64,
}

/// Ошибки маршрутизации
#[derive(Debug, thiserror::Error)]
pub enum RoutingError {
    #[error("Storage error: {0}")]
    StorageError(#[from] crate::storage::StorageError),

    #[error("Transport error: {0}")]
    TransportError(#[from] crate::transport::TransportError),

    #[error("Packet error: {0}")]
    PacketError(#[from] crate::core::PacketError),

    #[error("No route to destination")]
    NoRoute,

    #[error("Packet expired")]
    PacketExpired,
}