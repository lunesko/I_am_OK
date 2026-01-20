//! Policy - ограничения среды
//!
//! Policy определяет ограничения, которые ядро учитывает в зависимости от среды.
//! НЕ является "режимом" - это адаптация к условиям.

use crate::transport::TransportType;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;

/// Политика ограничений среды
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Policy {
    /// Максимальный размер текстового сообщения (байты)
    pub max_text_size: usize,

    /// Максимальная длина голосового сообщения (секунды)
    pub max_voice_seconds: u8,

    /// Максимальное количество хранимых сообщений
    pub max_stored_messages: usize,

    /// Разрешенные типы транспорта
    pub allowed_transports: HashSet<TransportType>,

    /// Приоритет статусов (true = статусы имеют высший приоритет)
    pub prioritize_status: bool,

    /// Максимальный TTL для сообщений (секунды)
    pub max_ttl_seconds: u32,

    /// Максимальное количество hops
    pub max_hops: u32,

    /// Включено ли сжатие данных
    pub enable_compression: bool,

    /// Включена ли автоматическая очистка
    pub enable_auto_cleanup: bool,
}

impl Policy {
    /// Дефолтная политика (гражданская среда)
    pub fn default() -> Self {
        Self {
            max_text_size: 256,
            max_voice_seconds: 7,
            max_stored_messages: 1000,
            allowed_transports: [
                TransportType::Ble,
                TransportType::WifiDirect,
                TransportType::Udp,
                TransportType::Satellite,
            ].into_iter().collect(),
            prioritize_status: false,
            max_ttl_seconds: 3600, // 1 час
            max_hops: 10,
            enable_compression: true,
            enable_auto_cleanup: true,
        }
    }

    /// Военная среда (жесткие ограничения)
    pub fn military() -> Self {
        Self {
            max_text_size: 128,
            max_voice_seconds: 3,
            max_stored_messages: 100,
            allowed_transports: [
                TransportType::Ble,
                TransportType::Satellite,
            ].into_iter().collect(),
            prioritize_status: true,
            max_ttl_seconds: 1800, // 30 мин
            max_hops: 5,
            enable_compression: true,
            enable_auto_cleanup: true,
        }
    }

    /// Коллапс (минимальные возможности)
    pub fn collapse() -> Self {
        Self {
            max_text_size: 64,
            max_voice_seconds: 0, // голос отключен
            max_stored_messages: 50,
            allowed_transports: [
                TransportType::Ble,
            ].into_iter().collect(),
            prioritize_status: true,
            max_ttl_seconds: 900, // 15 мин
            max_hops: 3,
            enable_compression: false, // экономим батарею
            enable_auto_cleanup: true,
        }
    }

    /// Автономная среда (нет интернета)
    pub fn offline() -> Self {
        let mut policy = Self::default();
        policy.allowed_transports.remove(&TransportType::Udp);
        policy.allowed_transports.remove(&TransportType::Satellite);
        policy.max_stored_messages = 500;
        policy
    }

    /// Проверить, разрешен ли транспорт
    pub fn is_transport_allowed(&self, transport: &TransportType) -> bool {
        self.allowed_transports.contains(transport)
    }

    /// Проверить размер текста
    pub fn validate_text_size(&self, text: &str) -> Result<(), PolicyError> {
        if text.len() > self.max_text_size {
            return Err(PolicyError::TextTooLong(text.len(), self.max_text_size));
        }
        Ok(())
    }

    /// Проверить длительность голоса
    pub fn validate_voice_length(&self, seconds: u8) -> Result<(), PolicyError> {
        if seconds > self.max_voice_seconds {
            return Err(PolicyError::VoiceTooLong(seconds, self.max_voice_seconds));
        }
        Ok(())
    }

    /// Проверить количество хранимых сообщений
    pub fn should_cleanup_storage(&self, current_count: usize) -> bool {
        current_count > self.max_stored_messages
    }

    /// Получить приоритет для типа сообщения
    pub fn get_message_priority(&self, message_type: &crate::core::MessageType) -> u8 {
        match message_type {
            crate::core::MessageType::Status => {
                if self.prioritize_status { 2 } else { 1 }
            }
            crate::core::MessageType::Text => 1,
            crate::core::MessageType::Voice => 0,
        }
    }
}

impl Default for Policy {
    fn default() -> Self {
        Self::default()
    }
}

/// Менеджер политик
pub struct PolicyManager {
    current_policy: Policy,
}

impl PolicyManager {
    pub fn new() -> Self {
        Self {
            current_policy: Policy::default(),
        }
    }

    /// Установить политику
    pub fn set_policy(&mut self, policy: Policy) {
        self.current_policy = policy;
    }

    /// Получить текущую политику
    pub fn get_policy(&self) -> &Policy {
        &self.current_policy
    }

    /// Автоматически определить политику на основе условий
    pub async fn auto_detect_policy(&mut self) {
        // TODO: Реализовать автоопределение на основе:
        // - наличия интернета
        // - геолокации
        // - времени суток
        // - уровня сигнала
        // - etc.

        // Пока что используем дефолт
        self.current_policy = Policy::default();
    }

    /// Проверить политику
    pub fn validate_message(&self, message: &crate::core::Message) -> Result<(), PolicyError> {
        match &message.payload {
            crate::core::MessagePayload::Text(text) => {
                self.current_policy.validate_text_size(text)?;
            }
            crate::core::MessagePayload::Voice(data) => {
                // Примерная оценка длительности (64kbps)
                let estimated_seconds = (data.len() / 8000) as u8; // 8KB = 1 сек при 64kbps
                self.current_policy.validate_voice_length(estimated_seconds)?;
            }
            crate::core::MessagePayload::Status(_) => {
                // Статусы всегда разрешены
            }
        }
        Ok(())
    }
}

impl Default for PolicyManager {
    fn default() -> Self {
        Self::new()
    }
}

/// Ошибки политик
#[derive(Debug, thiserror::Error)]
pub enum PolicyError {
    #[error("Text too long: {0} bytes (max {1})")]
    TextTooLong(usize, usize),

    #[error("Voice too long: {0}s (max {1}s)")]
    VoiceTooLong(u8, u8),

    #[error("Transport not allowed: {0:?}")]
    TransportNotAllowed(TransportType),

    #[error("Policy violation: {0}")]
    Violation(String),
}