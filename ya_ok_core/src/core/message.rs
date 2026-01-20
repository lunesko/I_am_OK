//! Message - типы сообщений
//!
//! Три типа сообщений:
//! - Status: "Я ОК", "Зайнятий", "Пізніше"
//! - Text: до 256 байт
//! - Voice: до 7 секунд (chunked)

use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

/// Тип сообщения
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub enum MessageType {
    /// Статус присутствия
    Status,
    /// Короткий текст
    Text,
    /// Короткий голос
    Voice,
}

/// Статус присутствия
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub enum StatusType {
    #[serde(rename = "ok")]
    Ok,           // "Я ОК"

    #[serde(rename = "busy")]
    Busy,         // "Зайнятий"

    #[serde(rename = "later")]
    Later,        // "Пізніше"
}

/// Сообщение
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Message {
    /// Уникальный ID сообщения
    pub id: String,
    /// Тип сообщения
    pub message_type: MessageType,
    /// ID отправителя
    pub sender_id: String,
    /// Временная метка создания
    pub timestamp: DateTime<Utc>,
    /// Payload в зависимости от типа
    pub payload: MessagePayload,
}

impl Message {
    /// Создать новое сообщение
    pub fn new(sender_id: String, message_type: MessageType, payload: MessagePayload) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            message_type,
            sender_id,
            timestamp: Utc::now(),
            payload,
        }
    }

    /// Создать статус-сообщение
    pub fn status(sender_id: String, status: StatusType) -> Self {
        Self::new(
            sender_id,
            MessageType::Status,
            MessagePayload::Status(status),
        )
    }

    /// Создать текстовое сообщение
    pub fn text(sender_id: String, text: String) -> Result<Self, MessageError> {
        if text.len() > 256 {
            return Err(MessageError::TextTooLong(text.len()));
        }
        if !text.chars().all(|c| c.is_alphanumeric() || c.is_whitespace() || ".,!?".contains(c)) {
            return Err(MessageError::InvalidTextCharacters);
        }

        Ok(Self::new(
            sender_id,
            MessageType::Text,
            MessagePayload::Text(text),
        ))
    }

    /// Создать голосовое сообщение
    pub fn voice(sender_id: String, audio_data: Vec<u8>) -> Result<Self, MessageError> {
        // Проверяем размер (примерно 7 сек при 64kbps)
        const MAX_VOICE_BYTES: usize = 56_000; // ~7 сек при 64kbps
        if audio_data.len() > MAX_VOICE_BYTES {
            return Err(MessageError::VoiceTooLong(audio_data.len()));
        }

        Ok(Self::new(
            sender_id,
            MessageType::Voice,
            MessagePayload::Voice(audio_data),
        ))
    }

    /// Проверить валидность сообщения
    pub fn validate(&self) -> Result<(), MessageError> {
        match &self.payload {
            MessagePayload::Status(_) => Ok(()),
            MessagePayload::Text(text) => {
                if text.is_empty() {
                    return Err(MessageError::EmptyText);
                }
                if text.len() > 256 {
                    return Err(MessageError::TextTooLong(text.len()));
                }
                Ok(())
            }
            MessagePayload::Voice(data) => {
                if data.is_empty() {
                    return Err(MessageError::EmptyVoice);
                }
                const MAX_VOICE_BYTES: usize = 56_000;
                if data.len() > MAX_VOICE_BYTES {
                    return Err(MessageError::VoiceTooLong(data.len()));
                }
                Ok(())
            }
        }
    }
}

/// Payload сообщения
#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum MessagePayload {
    /// Статус присутствия
    Status(StatusType),
    /// Текст (макс 256 байт)
    Text(String),
    /// Голос (макс ~56KB для 7 сек)
    Voice(Vec<u8>),
}

/// Ошибки сообщений
#[derive(Debug, thiserror::Error)]
pub enum MessageError {
    #[error("Text too long: {0} bytes (max 256)")]
    TextTooLong(usize),

    #[error("Invalid text characters")]
    InvalidTextCharacters,

    #[error("Empty text message")]
    EmptyText,

    #[error("Voice too long: {0} bytes (max 56000)")]
    VoiceTooLong(usize),

    #[error("Empty voice message")]
    EmptyVoice,
}