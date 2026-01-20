//! Sync - синхронизация через gossip protocol
//!
//! Gossip protocol для распространения сообщений:
//! - Периодическая синхронизация с пирами
//! - Обмен дайджестами сообщений
//! - Запрос недостающих сообщений

use crate::core::{Message, Packet};
use crate::storage::Storage;
use crate::transport::{TransportManager, Peer};
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use chrono::{DateTime, Utc};
use tokio::sync::RwLock;

/// Дайджест сообщения для gossip
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct MessageDigest {
    pub message_id: String,
    pub sender_id: String,
    pub timestamp: DateTime<Utc>,
    pub hash: [u8; 32], // SHA-256 хэш сообщения
}

/// Gossip сообщение
#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum GossipMessage {
    /// Запрос дайджестов от пира
    DigestRequest {
        since: DateTime<Utc>,
        max_count: usize,
    },

    /// Ответ с дайджестами
    DigestResponse {
        digests: Vec<MessageDigest>,
    },

    /// Запрос конкретных сообщений
    MessageRequest {
        message_ids: Vec<String>,
    },

    /// Ответ с сообщениями
    MessageResponse {
        messages: Vec<Message>,
    },
}

/// Gossip протокол
#[async_trait]
pub trait GossipProtocol: Send + Sync {
    /// Синхронизироваться с пиром
    async fn sync_with_peer(&self, peer: &Peer) -> Result<(), GossipError>;

    /// Обработать входящее gossip сообщение
    async fn handle_gossip_message(&self, message: GossipMessage, from_peer: &Peer) -> Result<(), GossipError>;

    /// Получить статистику синхронизации
    async fn get_sync_stats(&self) -> GossipStats;
}

/// Gossip реализация
pub struct Gossip {
    storage: Storage,
    transport_manager: TransportManager,
    /// Время последней синхронизации с каждым пиром
    last_sync: RwLock<std::collections::HashMap<String, DateTime<Utc>>>,
    /// Статистика
    stats: RwLock<GossipStats>,
}

impl Gossip {
    pub fn new(storage: Storage, transport_manager: TransportManager) -> Self {
        Self {
            storage,
            transport_manager,
            last_sync: RwLock::new(std::collections::HashMap::new()),
            stats: RwLock::new(GossipStats::default()),
        }
    }

    /// Создать дайджест для сообщения
    fn create_digest(message: &Message) -> Result<MessageDigest, GossipError> {
        use sha2::{Sha256, Digest};

        let message_data = serde_json::to_vec(message)
            .map_err(|_| GossipError::SerializationFailed)?;

        let hash = Sha256::digest(&message_data);
        let mut hash_bytes = [0u8; 32];
        hash_bytes.copy_from_slice(&hash);

        Ok(MessageDigest {
            message_id: message.id.clone(),
            sender_id: message.sender_id.clone(),
            timestamp: message.timestamp,
            hash: hash_bytes,
        })
    }

    /// Проверить дайджест
    fn verify_digest(&self, digest: &MessageDigest, message: &Message) -> bool {
        if let Ok(computed_digest) = Self::create_digest(message) {
            computed_digest.hash == digest.hash
        } else {
            false
        }
    }

    /// Запустить периодическую синхронизацию
    pub async fn start_periodic_sync(&self) {
        let gossip = self.clone();
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(std::time::Duration::from_secs(300)); // 5 мин

            loop {
                interval.tick().await;

                // Синхронизируемся со всеми известными пирами
                let peers = gossip.transport_manager.discover_all_peers().await
                    .unwrap_or_default();

                for peer in peers {
                    if let Err(_) = gossip.sync_with_peer(&peer).await {
                        // Логируем ошибку, но продолжаем
                    }
                }
            }
        });
    }
}

impl Clone for Gossip {
    fn clone(&self) -> Self {
        Self {
            storage: self.storage.clone(), // TODO: Storage needs Clone
            transport_manager: TransportManager::new(), // TODO: proper clone
            last_sync: RwLock::new(std::collections::HashMap::new()),
            stats: RwLock::new(GossipStats::default()),
        }
    }
}

#[async_trait]
impl GossipProtocol for Gossip {
    async fn sync_with_peer(&self, peer: &Peer) -> Result<(), GossipError> {
        let mut stats = self.stats.write().await;

        // Проверяем, не слишком ли рано синхронизироваться
        let last_sync_time = self.last_sync.read().await.get(&peer.id).cloned();
        if let Some(last_sync) = last_sync_time {
            let elapsed = Utc::now().signed_duration_since(last_sync);
            if elapsed.num_minutes() < 5 {
                return Ok(()); // Слишком рано
            }
        }

        // Шаг 1: Запрашиваем дайджесты
        let request = GossipMessage::DigestRequest {
            since: last_sync_time.unwrap_or_else(|| Utc::now() - chrono::Duration::hours(24)),
            max_count: 100,
        };

        // Отправляем запрос
        self.send_gossip_message(&request, peer).await?;

        // Обновляем время последней синхронизации
        self.last_sync.write().await.insert(peer.id.clone(), Utc::now());

        stats.sync_sessions += 1;
        Ok(())
    }

    async fn handle_gossip_message(&self, message: GossipMessage, from_peer: &Peer) -> Result<(), GossipError> {
        match message {
            GossipMessage::DigestRequest { since, max_count } => {
                // Получаем дайджесты сообщений с момента since
                let messages = self.storage.get_messages_since(since)?;
                let digests: Vec<MessageDigest> = messages.iter()
                    .take(max_count)
                    .filter_map(|msg| Self::create_digest(msg).ok())
                    .collect();

                // Отправляем ответ
                let response = GossipMessage::DigestResponse { digests };
                self.send_gossip_message(&response, from_peer).await?;
            }

            GossipMessage::DigestResponse { digests } => {
                // Находим недостающие сообщения
                let mut missing_ids = Vec::new();

                for digest in digests {
                    if !self.storage.is_message_seen(&digest.message_id)? {
                        missing_ids.push(digest.message_id);
                    }
                }

                if !missing_ids.is_empty() {
                    // Запрашиваем недостающие сообщения
                    let request = GossipMessage::MessageRequest {
                        message_ids: missing_ids,
                    };
                    self.send_gossip_message(&request, from_peer).await?;
                }
            }

            GossipMessage::MessageRequest { message_ids } => {
                // Находим запрошенные сообщения
                let mut messages = Vec::new();

                for id in message_ids {
                    if let Some(message) = self.storage.get_message_by_id(&id)? {
                        messages.push(message);
                    }
                }

                // Отправляем ответ
                let response = GossipMessage::MessageResponse { messages };
                self.send_gossip_message(&response, from_peer).await?;
            }

            GossipMessage::MessageResponse { messages } => {
                // Сохраняем полученные сообщения
                for message in messages {
                    if let Err(_) = self.storage.store_message(&message) {
                        // Логируем ошибку, но продолжаем
                    }
                }
            }
        }

        Ok(())
    }

    async fn get_sync_stats(&self) -> GossipStats {
        self.stats.read().await.clone()
    }
}

impl Gossip {
    /// Отправить gossip сообщение
    async fn send_gossip_message(&self, message: &GossipMessage, peer: &Peer) -> Result<(), GossipError> {
        // Сериализуем в CBOR
        let data = ciborium::ser::into_writer(message, Vec::new())
            .map_err(|_| GossipError::SerializationFailed)?;

        // Отправляем как обычный пакет
        // TODO: реализовать отправку gossip сообщений через транспорт

        Ok(())
    }
}

/// Статистика gossip синхронизации
#[derive(Clone, Debug, Default, serde::Serialize, serde::Deserialize)]
pub struct GossipStats {
    pub sync_sessions: u64,
    pub messages_exchanged: u64,
    pub failed_syncs: u64,
}

/// Ошибки gossip протокола
#[derive(Debug, thiserror::Error)]
pub enum GossipError {
    #[error("Serialization failed")]
    SerializationFailed,

    #[error("Storage error: {0}")]
    StorageError(#[from] crate::storage::StorageError),

    #[error("Transport error: {0}")]
    TransportError(#[from] crate::transport::TransportError),

    #[error("Digest verification failed")]
    DigestVerificationFailed,
}

// TODO: добавить недостающие методы в Storage
impl Storage {
    fn get_messages_since(&self, _since: DateTime<Utc>) -> Result<Vec<Message>, crate::storage::StorageError> {
        // TODO: реализовать
        Ok(Vec::new())
    }

    fn get_message_by_id(&self, _id: &str) -> Result<Option<Message>, crate::storage::StorageError> {
        // TODO: реализовать
        Ok(None)
    }
}