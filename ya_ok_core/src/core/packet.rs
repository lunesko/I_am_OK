//! Packet - транспортный пакет
//!
//! Пакет содержит:
//! - Зашифрованное сообщение
//! - Метаданные для маршрутизации
//! - TTL и hops для предотвращения зацикливания

use crate::core::{Message, Crypto, EncryptedPayload};
use ciborium::{de, ser};
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use std::fmt;

/// Приоритет пакета
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, PartialOrd, Ord, Eq)]
pub enum Priority {
    Low = 0,     // Voice
    Medium = 1,  // Text
    High = 2,    // Status
}

/// Транспортный пакет
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Packet {
    /// ID сообщения
    pub message_id: String,
    /// ID отправителя
    pub sender_id: String,
    /// Публичный ключ отправителя (Ed25519) для верификации подписи
    #[serde(default)]
    pub sender_public_key: Vec<u8>,
    /// Публичный ключ отправителя (X25519) для обмена ключами
    #[serde(default)]
    pub sender_x25519_public_key: Vec<u8>,
    /// Временная метка создания
    pub timestamp: DateTime<Utc>,
    /// TTL (время жизни в секундах)
    pub ttl: u32,
    /// Количество hops (прыжков)
    pub hops: u32,
    /// Максимальное количество hops
    pub max_hops: u32,
    /// Приоритет пакета
    pub priority: Priority,
    /// Зашифрованный payload
    pub encrypted_payload: EncryptedPayload,
    /// Подпись отправителя
    pub signature: Vec<u8>,
}

impl Packet {
    /// Создать пакет из сообщения
    pub fn from_message(
        message: &Message,
        sender_identity: &crate::core::Identity,
        receiver_public_key: &[u8],
    ) -> Result<Self, PacketError> {
        // Сериализуем сообщение в CBOR
        let mut message_bytes = Vec::new();
        ser::into_writer(&message, &mut message_bytes)
            .map_err(|_| PacketError::SerializationFailed)?;

        // Генерируем ключи для шифрования
        let (sender_private, sender_public) = Crypto::generate_ephemeral_keypair();

        // Конвертируем публичный ключ получателя
        let mut receiver_key_bytes = [0u8; 32];
        if receiver_public_key.len() != 32 {
            return Err(PacketError::InvalidReceiverKey);
        }
        receiver_key_bytes.copy_from_slice(receiver_public_key);
        let receiver_public = x25519_dalek::PublicKey::from(receiver_key_bytes);

        // Шифруем payload
        let encrypted = Crypto::encrypt_payload(
            &sender_private,
            &sender_public,
            &receiver_public,
            &message_bytes,
        )?;

        // Определяем приоритет
        let priority = match message.message_type {
            crate::core::MessageType::Status => Priority::High,
            crate::core::MessageType::Text => Priority::Medium,
            crate::core::MessageType::Voice => Priority::Low,
        };

        // Создаем пакет
        let mut packet = Self {
            message_id: message.id.clone(),
            sender_id: message.sender_id.clone(),
            sender_public_key: sender_identity.public_key_bytes().to_vec(),
            sender_x25519_public_key: sender_identity
                .x25519_public_bytes()
                .map(|key| key.to_vec())
                .unwrap_or_default(),
            timestamp: message.timestamp,
            ttl: 3600, // 1 час по умолчанию
            hops: 0,
            max_hops: 10, // Максимум 10 прыжков
            priority,
            encrypted_payload: encrypted,
            signature: Vec::new(),
        };

        // Подписываем пакет
        let packet_data = packet.get_signing_data()?;
        let signature = sender_identity.sign(&packet_data)?;
        packet.signature = signature.to_bytes().to_vec();

        Ok(packet)
    }

    /// Расшифровать пакет
    pub fn decrypt(
        &self,
        receiver_identity: &crate::core::Identity,
    ) -> Result<Message, PacketError> {
        // Восстанавливаем identity отправителя из публичного ключа
        if self.sender_public_key.len() != 32 {
            return Err(PacketError::InvalidSenderKey);
        }
        let mut sender_key_bytes = [0u8; 32];
        sender_key_bytes.copy_from_slice(&self.sender_public_key);
        let sender_public = ed25519_dalek::VerifyingKey::from_bytes(&sender_key_bytes)
            .map_err(|_| PacketError::InvalidSenderKey)?;
        let sender_identity = crate::core::Identity::from_public_key(sender_public);

        // Верифицируем подпись отправителя
        let packet_data = self.get_signing_data()?;
        let signature_bytes: [u8; 64] = self.signature.as_slice().try_into()
            .map_err(|_| PacketError::InvalidSignature)?;
        let signature = ed25519_dalek::Signature::from_bytes(&signature_bytes);
        sender_identity.verify(&packet_data, &signature)?;

        // Используем ephemeral публичный ключ отправителя из encrypted_payload
        let sender_key_bytes: [u8; 32] = self.encrypted_payload.sender_public_key.as_slice()
            .try_into()
            .map_err(|_| PacketError::InvalidSenderKey)?;
        let sender_ephemeral_public = x25519_dalek::PublicKey::from(sender_key_bytes);

        // Используем сохраненный X25519 приватный ключ получателя
        let receiver_private = receiver_identity.x25519_secret()
            .ok_or(PacketError::CryptoError(crate::core::CryptoError::InvalidKey))?;

        // Расшифровываем payload
        let decrypted_bytes = Crypto::decrypt_payload(
            receiver_private,
            &sender_ephemeral_public,
            &self.encrypted_payload,
        )?;

        // Десериализуем сообщение
        let message: Message = de::from_reader(&decrypted_bytes[..])
            .map_err(|_| PacketError::DeserializationFailed)?;

        Ok(message)
    }

    /// Получить данные для подписи (без самой подписи)
    fn get_signing_data(&self) -> Result<Vec<u8>, PacketError> {
        // Создаем копию пакета без подписи для подписи
        let mut packet_copy = self.clone();
        packet_copy.signature = Vec::new();

        let mut data = Vec::new();
        ser::into_writer(&packet_copy, &mut data)
            .map_err(|_| PacketError::SerializationFailed)?;

        Ok(data)
    }

    /// Проверить, не истек ли TTL
    pub fn is_expired(&self) -> bool {
        let elapsed = Utc::now().signed_duration_since(self.timestamp);
        elapsed.num_seconds() as u32 >= self.ttl
    }

    /// Проверить, не превышен ли лимит hops
    pub fn can_forward(&self) -> bool {
        self.hops < self.max_hops
    }

    /// Увеличить счетчик hops
    pub fn increment_hops(&mut self) {
        self.hops += 1;
    }

    /// Сериализовать пакет в CBOR
    pub fn to_bytes(&self) -> Result<Vec<u8>, PacketError> {
        let mut bytes = Vec::new();
        ser::into_writer(self, &mut bytes)
            .map_err(|_| PacketError::SerializationFailed)?;
        Ok(bytes)
    }

    /// Десериализовать пакет из CBOR
    pub fn from_bytes(bytes: &[u8]) -> Result<Self, PacketError> {
        de::from_reader(bytes)
            .map_err(|_| PacketError::DeserializationFailed)
    }
}

impl fmt::Display for Packet {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "Packet(id={}, sender={}, priority={:?}, hops={}/{})",
            &self.message_id[..8],
            &self.sender_id[..8],
            self.priority,
            self.hops,
            self.max_hops
        )
    }
}

/// Ошибки пакетов
#[derive(Debug, thiserror::Error)]
pub enum PacketError {
    #[error("Serialization failed")]
    SerializationFailed,

    #[error("Deserialization failed")]
    DeserializationFailed,

    #[error("Invalid signature")]
    InvalidSignature,

    #[error("Invalid sender key")]
    InvalidSenderKey,

    #[error("Invalid receiver key")]
    InvalidReceiverKey,

    #[error("Identity error: {0}")]
    IdentityError(#[from] crate::core::IdentityError),

    #[error("Crypto error: {0}")]
    CryptoError(#[from] crate::core::CryptoError),
}