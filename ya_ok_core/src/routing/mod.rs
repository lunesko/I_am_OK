//! Routing - маршрутизация DTN (Store & Forward)
//!
//! Реализует Delay/Disruption Tolerant Networking:
//! - Store & Forward
//! - Приоритеты
//! - Flooding с дедупликацией
//! - TTL управление

pub mod queue;

use crate::core::{Packet, Priority};
use crate::core::ack::{Ack, AckType};
use crate::storage::Storage;
use crate::transport::{TransportManager, Peer};
use queue::{DtnQueue, QueuedPacket};
use async_trait::async_trait;
use std::collections::HashMap;
use tokio::sync::RwLock;

/// Интерфейс маршрутизатора
#[async_trait(?Send)]
pub trait Router {
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
    /// Очередь для отложенной пересылки
    queue: RwLock<DtnQueue>,
    /// Статистика
    stats: RwLock<RoutingStats>,
}

impl DtnRouter {
    pub fn new(storage: Storage, transport_manager: TransportManager) -> Self {
        Self {
            storage,
            transport_manager,
            known_peers: RwLock::new(HashMap::new()),
            queue: RwLock::new(DtnQueue::new()),
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

    /// Получить доступ к known_peers (для чтения)
    pub fn known_peers(&self) -> &RwLock<HashMap<String, Peer>> {
        &self.known_peers
    }

    /// Проверить, можем ли мы forward пакет (TOCTOU-safe)
    fn can_forward(packet: &Packet) -> bool {
        packet.can_be_forwarded()
    }

    /// Выбрать лучший транспорт для пакета
    /// Select best transport for packet delivery
    #[allow(dead_code)] // Reserved for multi-transport routing
    fn select_transport(&self, packet: &Packet) -> Option<&dyn crate::transport::Transport> {
        // Для высокоприоритетных пакетов используем быстрые транспорты
        match packet.priority {
            Priority::High => {
                // Сначала UDP, потом Wi-Fi Direct
                if let Some(transport) = self.transport_manager.get_transport(crate::transport::TransportType::Udp) {
                    return Some(transport);
                }
                if let Some(transport) = self.transport_manager.get_transport(crate::transport::TransportType::WifiDirect) {
                    return Some(transport);
                }
            }
            Priority::Medium => {
                // Wi-Fi Direct или BLE
                if let Some(transport) = self.transport_manager.get_transport(crate::transport::TransportType::WifiDirect) {
                    return Some(transport);
                }
            }
            Priority::Low => {
                // Любой доступный
            }
        }

        // Fallback: BLE (всегда доступен)
        self.transport_manager.get_transport(crate::transport::TransportType::Ble)
    }

    /// Обработать очередь пакетов и попытаться отправить готовые
    pub async fn process_queue(&self) -> Result<usize, RoutingError> {
        let mut queue = self.queue.write().await;
        let mut sent_count = 0;

        // Получаем пакеты, готовые к отправке
        while let Some(mut queued) = queue.dequeue_ready() {
            let result = if let Some(target) = &queued.target_peer {
                self.send_to(&queued.packet, target).await
            } else {
                self.flood_packet(queued.packet.clone()).await
            };

            match result {
                Ok(_) => {
                    sent_count += 1;
                }
                Err(_) => {
                    // Отправка не удалась - возвращаем в очередь с инкрементом retry
                    queued.mark_attempt();
                    if queued.retry_count < 3 {
                        queue.enqueue(queued)?;
                    }
                }
            }
        }

        // Очищаем истекшие пакеты
        queue.cleanup_expired();

        Ok(sent_count)
    }

    /// Отправить ACK-сообщение отправителю
    pub async fn send_ack(&self, message_id: &str, ack_from: &str, ack_type: AckType) -> Result<(), RoutingError> {
        // Создаем ACK
        let _ack = match ack_type {
            AckType::Received => Ack::received(message_id.to_string(), ack_from.to_string()),
            AckType::Delivered => Ack::delivered(message_id.to_string(), ack_from.to_string()),
        };

        // Сохраняем ACK локально
        let ack_type_str = match ack_type {
            AckType::Received => "Received",
            AckType::Delivered => "Delivered",
        };
        self.storage.store_ack(message_id, ack_from, ack_type_str)?;

        // TODO: Отправить ACK отправителю оригинального сообщения
        // Это потребует создания специального ACK пакета

        Ok(())
    }

    /// Обработать входящий ACK
    pub async fn handle_ack(&self, ack: Ack) -> Result<(), RoutingError> {
        let ack_type_str = match ack.ack_type {
            AckType::Received => "Received",
            AckType::Delivered => "Delivered",
        };

        // Сохраняем ACK
        self.storage.store_ack(&ack.message_id, &ack.ack_from, ack_type_str)?;

        Ok(())
    }
}

#[async_trait(?Send)]
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

        // Отправляем Received ACK отправителю
        // TODO: получить peer_id текущего узла из конфигурации
        // self.send_ack(&packet.message_id, "current_peer_id", AckType::Received).await?;

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
            // Нет известных пиров - добавляем в очередь для поздней отправки
            let mut queue = self.queue.write().await;
            queue.enqueue(QueuedPacket::new(packet, None))?;
            return Ok(());
        }

        // Отправляем всем известным пирам
        let mut success_count = 0;
        for peer in known_peers.values() {
            if let Ok(_) = self.transport_manager.send_packet(&packet, &peer.address).await {
                success_count += 1;
            }
        }

        // Если никому не удалось отправить - добавляем в очередь
        if success_count == 0 {
            let mut queue = self.queue.write().await;
            queue.enqueue(QueuedPacket::new(packet, None))?;
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

    #[error("Queue error: {0}")]
    QueueError(#[from] queue::QueueError),

    #[error("No route to destination")]
    NoRoute,

    #[error("Packet expired")]
    PacketExpired,
}