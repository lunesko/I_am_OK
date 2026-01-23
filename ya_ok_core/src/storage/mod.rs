//! Storage - локальное хранилище
//!
//! Хранит сообщения локально с дедупликацией и TTL.
//! Использует SQLite для структурированных данных.

use crate::core::Message;
use rusqlite::{Connection, Result as SqlResult};
use serde::{Deserialize, Serialize};
use std::path::Path;
use chrono::{DateTime, Utc};

/// Запись в хранилище
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct StoredMessage {
    /// ID сообщения
    pub message_id: String,
    /// Сериализованное сообщение
    pub message_data: Vec<u8>,
    /// ID отправителя
    pub sender_id: String,
    /// Временная метка получения
    pub received_at: DateTime<Utc>,
    /// TTL в секундах
    pub ttl: u32,
    /// Флаг доставки
    pub delivered: bool,
}

/// Локальное хранилище
pub struct Storage {
    conn: Connection,
}

impl Storage {
    /// Создать новое хранилище
    pub fn new<P: AsRef<Path>>(path: P) -> Result<Self, StorageError> {
        let conn = Connection::open(path)?;

        // Создаем таблицы
        conn.execute(
            "CREATE TABLE IF NOT EXISTS messages (
                message_id TEXT PRIMARY KEY,
                message_data BLOB NOT NULL,
                sender_id TEXT NOT NULL,
                received_at TEXT NOT NULL,
                ttl INTEGER NOT NULL,
                delivered INTEGER NOT NULL DEFAULT 0
            )",
            [],
        )?;

        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_sender ON messages(sender_id)",
            [],
        )?;

        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_received ON messages(received_at)",
            [],
        )?;

        // Создаем таблицу для seen message IDs (дедупликация)
        conn.execute(
            "CREATE TABLE IF NOT EXISTS seen_messages (
                message_id TEXT PRIMARY KEY,
                seen_at TEXT NOT NULL
            )",
            [],
        )?;

        Ok(Self { conn })
    }

    /// Сохранить сообщение
    pub fn store_message(&self, message: &Message) -> Result<(), StorageError> {
        self.store_message_with_delivered(message, false)
    }

    /// Сохранить сообщение с флагом доставки
    pub fn store_message_with_delivered(&self, message: &Message, delivered: bool) -> Result<(), StorageError> {
        // Проверяем, не видели ли уже это сообщение
        if self.is_message_seen(&message.id)? {
            return Ok(()); // Уже видели, игнорируем
        }

        // Сериализуем сообщение
        let message_data = serde_json::to_vec(message)
            .map_err(|_| StorageError::SerializationFailed)?;

        // Сохраняем
        self.conn.execute(
            "INSERT OR REPLACE INTO messages (message_id, message_data, sender_id, received_at, ttl, delivered)
             VALUES (?, ?, ?, ?, ?, ?)",
            (
                &message.id,
                &message_data,
                &message.sender_id,
                Utc::now().to_rfc3339(),
                3600, // 1 час TTL по умолчанию
                delivered,
            ),
        )?;

        // Помечаем как seen
        self.mark_message_seen(&message.id)?;

        Ok(())
    }

    /// Получить все непереданные сообщения
    pub fn get_pending_messages(&self) -> Result<Vec<StoredMessage>, StorageError> {
        let mut stmt = self.conn.prepare(
            "SELECT message_id, message_data, sender_id, received_at, ttl, delivered
             FROM messages WHERE delivered = 0 ORDER BY received_at ASC"
        )?;

        let messages = stmt.query_map([], |row| {
            let message_data: Vec<u8> = row.get(1)?;
            let received_at_str: String = row.get(3)?;
            let received_at = DateTime::parse_from_rfc3339(&received_at_str)
                .map_err(|_| rusqlite::Error::InvalidColumnType(3, "received_at".to_string(), rusqlite::types::Type::Text))?
                .with_timezone(&Utc);

            Ok(StoredMessage {
                message_id: row.get(0)?,
                message_data,
                sender_id: row.get(2)?,
                received_at,
                ttl: row.get(4)?,
                delivered: row.get(5)?,
            })
        })?;

        messages.collect::<SqlResult<Vec<_>>>()
            .map_err(StorageError::DatabaseError)
    }

    /// Получить последние сообщения после указанной даты
    pub fn get_messages_since(&self, since: DateTime<Utc>) -> Result<Vec<Message>, StorageError> {
        let mut stmt = self.conn.prepare(
            "SELECT message_data, received_at FROM messages WHERE received_at > ? ORDER BY received_at ASC"
        )?;

        let messages = stmt.query_map([since.to_rfc3339()], |row| {
            let message_data: Vec<u8> = row.get(0)?;
            serde_json::from_slice(&message_data)
                .map_err(|_| rusqlite::Error::InvalidColumnType(0, "message_data".to_string(), rusqlite::types::Type::Blob))
        })?;

        messages.collect::<SqlResult<Vec<_>>>()
            .map_err(StorageError::DatabaseError)
    }

    /// Получить сообщение по ID
    pub fn get_message_by_id(&self, id: &str) -> Result<Option<Message>, StorageError> {
        let mut stmt = self.conn.prepare(
            "SELECT message_data FROM messages WHERE message_id = ?"
        )?;

        let mut rows = stmt.query([id])?;
        if let Some(row) = rows.next()? {
            let message_data: Vec<u8> = row.get(0)?;
            let message: Message = serde_json::from_slice(&message_data)
                .map_err(|_| StorageError::DeserializationFailed)?;
            Ok(Some(message))
        } else {
            Ok(None)
        }
    }

    /// Получить сообщения от отправителя
    pub fn get_messages_from(&self, sender_id: &str) -> Result<Vec<Message>, StorageError> {
        let mut stmt = self.conn.prepare(
            "SELECT message_data FROM messages WHERE sender_id = ? ORDER BY received_at DESC"
        )?;

        let messages = stmt.query_map([sender_id], |row| {
            let message_data: Vec<u8> = row.get(0)?;
            serde_json::from_slice(&message_data)
                .map_err(|_| rusqlite::Error::InvalidColumnType(0, "message_data".to_string(), rusqlite::types::Type::Blob))
        })?;

        messages.collect::<SqlResult<Vec<_>>>()
            .map_err(StorageError::DatabaseError)
    }

    /// Получить последние сообщения
    pub fn get_recent_messages(&self, limit: usize) -> Result<Vec<Message>, StorageError> {
        let mut stmt = self.conn.prepare(
            "SELECT message_data FROM messages ORDER BY received_at DESC LIMIT ?"
        )?;

        let messages = stmt.query_map([limit as i64], |row| {
            let message_data: Vec<u8> = row.get(0)?;
            serde_json::from_slice(&message_data)
                .map_err(|_| rusqlite::Error::InvalidColumnType(0, "message_data".to_string(), rusqlite::types::Type::Blob))
        })?;

        messages.collect::<SqlResult<Vec<_>>>()
            .map_err(StorageError::DatabaseError)
    }

    /// Отметить сообщение как доставленное
    pub fn mark_delivered(&self, message_id: &str) -> Result<(), StorageError> {
        self.conn.execute(
            "UPDATE messages SET delivered = 1 WHERE message_id = ?",
            [message_id],
        )?;
        Ok(())
    }

    /// Проверить, видели ли уже сообщение
    pub fn is_message_seen(&self, message_id: &str) -> Result<bool, StorageError> {
        let count: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM seen_messages WHERE message_id = ?",
            [message_id],
            |row| row.get(0),
        )?;
        Ok(count > 0)
    }

    /// Отметить сообщение как seen
    pub fn mark_message_seen(&self, message_id: &str) -> Result<(), StorageError> {
        self.conn.execute(
            "INSERT OR IGNORE INTO seen_messages (message_id, seen_at) VALUES (?, ?)",
            (message_id, Utc::now().to_rfc3339()),
        )?;
        Ok(())
    }

    /// Очистить истекшие сообщения
    pub fn cleanup_expired(&self) -> Result<usize, StorageError> {
        let now = Utc::now();

        // Получаем сообщения для проверки TTL
        let pending = self.get_pending_messages()?;

        let mut expired_count = 0;
        for msg in pending {
            let elapsed = now.signed_duration_since(msg.received_at);
            if elapsed.num_seconds() as u32 >= msg.ttl {
                self.conn.execute(
                    "DELETE FROM messages WHERE message_id = ?",
                    [&msg.message_id],
                )?;
                expired_count += 1;
            }
        }

        Ok(expired_count)
    }

    /// Получить статистику хранилища
    pub fn get_stats(&self) -> Result<StorageStats, StorageError> {
        let total_messages: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM messages",
            [],
            |row| row.get(0),
        )?;

        let pending_messages: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM messages WHERE delivered = 0",
            [],
            |row| row.get(0),
        )?;

        let seen_messages: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM seen_messages",
            [],
            |row| row.get(0),
        )?;

        Ok(StorageStats {
            total_messages: total_messages as usize,
            pending_messages: pending_messages as usize,
            seen_messages: seen_messages as usize,
        })
    }
}

/// Статистика хранилища
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct StorageStats {
    pub total_messages: usize,
    pub pending_messages: usize,
    pub seen_messages: usize,
}

/// Ошибки хранилища
#[derive(Debug, thiserror::Error)]
pub enum StorageError {
    #[error("Database error: {0}")]
    DatabaseError(#[from] rusqlite::Error),

    #[error("Serialization failed")]
    SerializationFailed,

    #[error("Deserialization failed")]
    DeserializationFailed,
}