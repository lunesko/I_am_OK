//! Sync - синхронизация через gossip protocol
//!
//! Gossip protocol для распространения сообщений:
//! - Периодическая синхронизация с пирами
//! - Обмен дайджестами сообщений
//! - Запрос недостающих сообщений

use crate::core::{Message, MessagePayload, MessageType};
use crate::storage::Storage;
use crate::transport::{TransportManager, Peer};
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;
use tokio::sync::RwLock;
use std::sync::{Arc, Mutex};
use crate::core::{Identity, Packet};
use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine as _;

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
#[async_trait(?Send)]
pub trait GossipProtocol {
    /// Синхронизироваться с пиром
    async fn sync_with_peer(&self, peer: &Peer) -> Result<(), GossipError>;

    /// Обработать входящее gossip сообщение
    async fn handle_gossip_message(&self, message: GossipMessage, from_peer: &Peer) -> Result<(), GossipError>;

    /// Получить статистику синхронизации
    async fn get_sync_stats(&self) -> GossipStats;
}

/// Gossip реализация
pub struct Gossip {
    storage: Arc<Mutex<Storage>>,
    transport_manager: TransportManager,
    identity: Arc<RwLock<Option<Identity>>>,
    /// Время последней синхронизации с каждым пиром
    last_sync: RwLock<std::collections::HashMap<String, DateTime<Utc>>>,
    /// Статистика
    stats: RwLock<GossipStats>,
}

impl Gossip {
    pub fn new(
        storage: Arc<Mutex<Storage>>,
        transport_manager: TransportManager,
        identity: Arc<RwLock<Option<Identity>>>,
    ) -> Self {
        Self {
            storage,
            transport_manager,
            identity,
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
    /// Verify message digest matches actual message
    #[allow(dead_code)] // Reserved for future sync protocol
    fn verify_digest(&self, digest: &MessageDigest, message: &Message) -> bool {
        if let Ok(computed_digest) = Self::create_digest(message) {
            computed_digest.hash == digest.hash
        } else {
            false
        }
    }

    /// Запустить периодическую синхронизацию
    pub async fn start_periodic_sync(&self) {
        // TODO: фоновые задачи требуют Send + 'static, вернемся после стабилизации storage/transport.
    }

    pub(crate) fn encode_gossip(message: &GossipMessage) -> Result<String, GossipError> {
        let mut data = Vec::new();
        ciborium::ser::into_writer(message, &mut data)
            .map_err(|_| GossipError::SerializationFailed)?;
        Ok(format!("__gossip__:{}", BASE64.encode(&data)))
    }

    pub(crate) fn decode_gossip(text: &str) -> Result<Option<GossipMessage>, GossipError> {
        if !text.starts_with("__gossip__:") {
            return Ok(None);
        }
        let payload = text.trim_start_matches("__gossip__:");
        let decoded = BASE64.decode(payload).map_err(|_| GossipError::SerializationFailed)?;
        let message: GossipMessage = ciborium::de::from_reader(decoded.as_slice())
            .map_err(|_| GossipError::SerializationFailed)?;
        Ok(Some(message))
    }
}

#[async_trait(?Send)]
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
                let messages = self.storage.lock().unwrap().get_messages_since(since)?;
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
                    if !self.storage.lock().unwrap().is_message_seen(&digest.message_id)? {
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
                    if let Some(message) = self.storage.lock().unwrap().get_message_by_id(&id)? {
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
                    if let Err(_) = self.storage.lock().unwrap().store_message(&message) {
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
        // Нужна identity для подписи/шифрования пакета
        let identity = {
            let lock = self.identity.read().await;
            lock.clone().ok_or(GossipError::SerializationFailed)?
        };

        // Нужен X25519 публичный ключ получателя
        let receiver_key = match &peer.x25519_public_key {
            Some(key) if key.len() == 32 => {
                let mut buf = [0u8; 32];
                buf.copy_from_slice(key);
                buf
            }
            _ => return Err(GossipError::SerializationFailed),
        };

        // Кодируем gossip в текстовое сообщение
        let gossip_text = Self::encode_gossip(message)?;
        let msg = Message {
            id: Uuid::new_v4().to_string(),
            message_type: MessageType::Text,
            sender_id: identity.id.clone(),
            timestamp: Utc::now(),
            payload: MessagePayload::Text(gossip_text),
        };

        let packet = Packet::from_message(&msg, &identity, &receiver_key)
            .map_err(|_| GossipError::SerializationFailed)?;

        // Отправляем через транспорт
        self.transport_manager
            .send_packet(&packet, &peer.address)
            .await
            .map_err(|_| GossipError::SerializationFailed)?;

        // Обновляем статистику
        let mut stats = self.stats.write().await;
        stats.messages_exchanged += 1;

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

// TODO: активировать фоновую синхронизацию при готовых транспортных каналах