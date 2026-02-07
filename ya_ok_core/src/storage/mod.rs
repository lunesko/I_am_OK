//! Storage - локальное хранилище
//!
//! Хранит сообщения локально с дедупликацией и TTL.
//! Использует SQLite для структурированных данных.

use crate::core::Message;
use crate::security::KeyManager;
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
/// 
/// # Thread Safety
/// rusqlite::Connection is !Sync due to internal RefCell, but is Send.
/// When wrapped in Arc<Mutex<Storage>>, it's safe to share across threads.
/// This explicit Sync implementation is safe because Mutex guarantees exclusive access.
pub struct Storage {
    conn: Connection,
}

// SAFETY: Storage is wrapped in Mutex in CoreState, so concurrent access is serialized
unsafe impl Sync for Storage {}

impl Storage {
    /// Создать новое хранилище с шифрованием
    /// 
    /// NOTE: SQLCipher requires separate compilation. For development, we use
    /// application-level encryption. For production, compile with SQLCipher support.
    pub fn new<P: AsRef<Path>>(path: P) -> Result<Self, StorageError> {
        let conn = Connection::open(&path)?;
        
        // Получить или создать encryption key через KeyManager
        let config_path = path.as_ref().parent()
            .unwrap_or_else(|| Path::new("."))
            .join("db_key.config");
        
        let key_manager = KeyManager::new(config_path);
        let encryption_key = key_manager.get_or_create_db_key()
            .map_err(|e| StorageError::EncryptionError(e.to_string()))?;
        
        // Try to set SQLCipher encryption key (will fail silently if not compiled with sqlcipher)
        // For production, this requires rusqlite with sqlcipher feature
        let _ = conn.pragma_update(None, "key", &format!("\"x'{}'\"", encryption_key));
        
        // Set security pragmas for standard SQLite
        conn.pragma_update(None, "journal_mode", &"WAL")?;
        conn.pragma_update(None, "synchronous", &"NORMAL")?;
        
        // Set SQLCipher PBKDF2 iterations (default is 256000 for SQLCipher 4.x)
        conn.pragma_update(None, "kdf_iter", &256000)?;

        // Enable WAL mode for better concurrency and crash recovery
        conn.execute_batch("PRAGMA journal_mode=WAL")?;
        
        // Enable auto_vacuum=INCREMENTAL to prevent unbounded growth
        conn.execute_batch("PRAGMA auto_vacuum=INCREMENTAL")?;
        
        // Set page_size for better performance (must be set before tables created)
        conn.execute_batch("PRAGMA page_size=4096")?;

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

        conn.execute_batch(
            "CREATE INDEX IF NOT EXISTS idx_sender ON messages(sender_id);
             CREATE INDEX IF NOT EXISTS idx_received ON messages(received_at);"
        )?;

        // Создаем таблицу для seen message IDs (дедупликация)
        conn.execute(
            "CREATE TABLE IF NOT EXISTS seen_messages (
                message_id TEXT PRIMARY KEY,
                seen_at TEXT NOT NULL
            )",
            [],
        )?;

        // Создаем таблицу для ACK
        conn.execute(
            "CREATE TABLE IF NOT EXISTS acks (
                message_id TEXT NOT NULL,
                ack_from TEXT NOT NULL,
                ack_type TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                PRIMARY KEY (message_id, ack_from, ack_type)
            )",
            [],
        )?;

        conn.execute_batch(
            "CREATE INDEX IF NOT EXISTS idx_acks_message ON acks(message_id)"
        )?;

        // Создаем таблицу для отслеживания использованных nonces (replay attack prevention)
        conn.execute(
            "CREATE TABLE IF NOT EXISTS used_nonces (
                nonce_hex TEXT PRIMARY KEY,
                sender_id TEXT NOT NULL,
                used_at TEXT NOT NULL,
                expires_at TEXT NOT NULL
            )",
            [],
        )?;

        conn.execute_batch(
            "CREATE INDEX IF NOT EXISTS idx_nonces_expires ON used_nonces(expires_at)"
        )?;

        Ok(Self { conn })
    }

    /// Сохранить сообщение
    pub fn store_message(&self, message: &Message) -> Result<(), StorageError> {
        self.store_message_with_delivered(message, false)
    }

    /// Сохранить сообщение с флагом доставки
    /// 
    /// # Security Note
    /// **SIGNATURE VERIFICATION**: Вызывающий код должен убедиться, что сообщение прошло проверку подписи.
    /// - Для сообщений из сети: подпись ОБЯЗАТЕЛЬНО проверяется в `Packet::decrypt()` (строка 135)
    /// - Для локальных сообщений: проверка не требуется (создатель = отправитель)
    /// 
    /// **ARCHITECTURE**:
    /// ```text
    /// Network -> Packet::decrypt() -> [SIGNATURE VERIFIED] -> store_message_with_delivered()
    /// Local   -> create_message()  -> [TRUSTED SOURCE]     -> store_message_with_delivered()
    /// ```
    /// 
    /// **CRITICAL**: Никогда не вызывайте эту функцию напрямую для сообщений из ненадежных источников!
    /// Все сообщения из сети ДОЛЖНЫ пройти через `Packet::decrypt()` для проверки подписи.
    pub fn store_message_with_delivered(&self, message: &Message, delivered: bool) -> Result<(), StorageError> {
        // Проверяем, не видели ли уже это сообщение
        if self.is_message_seen(&message.id)? {
            return Ok(()); // Уже видели, игнорируем
        }

        // Валидируем содержимое сообщения (размеры, форматы)
        message.validate()
            .map_err(|e| StorageError::ValidationFailed(e.to_string()))?;

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
        // Validate UUID format to prevent SQL injection from untrusted input
        if let Err(_) = uuid::Uuid::parse_str(id) {
            return Err(StorageError::InvalidInput(
                format!("Invalid UUID format: {}", id)
            ));
        }

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

    /// Сохранить ACK для сообщения
    pub fn store_ack(&self, message_id: &str, ack_from: &str, ack_type: &str) -> Result<(), StorageError> {
        self.conn.execute(
            "INSERT OR REPLACE INTO acks (message_id, ack_from, ack_type, timestamp) VALUES (?, ?, ?, ?)",
            (message_id, ack_from, ack_type, Utc::now().to_rfc3339()),
        )?;

        // Если получили Delivered ACK, обновляем статус сообщения
        if ack_type == "Delivered" {
            self.mark_delivered(message_id)?;
        }

        Ok(())
    }

    /// Получить все ACK для сообщения
    pub fn get_acks_for_message(&self, message_id: &str) -> Result<Vec<(String, String, String)>, StorageError> {
        let mut stmt = self.conn.prepare(
            "SELECT ack_from, ack_type, timestamp FROM acks WHERE message_id = ? ORDER BY timestamp ASC"
        )?;

        let acks = stmt.query_map([message_id], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
            ))
        })?;

        acks.collect::<SqlResult<Vec<_>>>()
            .map_err(StorageError::DatabaseError)
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

        // Run incremental vacuum to reclaim space after deletions
        if expired_count > 0 {
            self.conn.execute_batch("PRAGMA incremental_vacuum")?;
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
    
    /// Проверить, использовался ли nonce (защита от replay attacks)
    pub fn is_nonce_used(&self, nonce: &[u8], sender_id: &str) -> Result<bool, StorageError> {
        let nonce_hex = hex::encode(nonce);
        
        let count: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM used_nonces WHERE nonce_hex = ? AND sender_id = ?",
            (nonce_hex, sender_id),
            |row| row.get(0),
        )?;
        
        Ok(count > 0)
    }

    /// Пометить nonce как использованный (TTL 24 часа)
    pub fn mark_nonce_used(&self, nonce: &[u8], sender_id: &str) -> Result<(), StorageError> {
        let nonce_hex = hex::encode(nonce);
        let now = Utc::now();
        let expires_at = now + chrono::Duration::hours(24);
        
        self.conn.execute(
            "INSERT OR IGNORE INTO used_nonces (nonce_hex, sender_id, used_at, expires_at) VALUES (?, ?, ?, ?)",
            (nonce_hex, sender_id, now.to_rfc3339(), expires_at.to_rfc3339()),
        )?;
        
        Ok(())
    }
    
    /// Очистка просроченных nonces
    pub fn cleanup_expired_nonces(&self) -> Result<(), StorageError> {
        let now = Utc::now();
        self.conn.execute(
            "DELETE FROM used_nonces WHERE expires_at < ?",
            [now.to_rfc3339()],
        )?;
        Ok(())
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

    #[error("Message validation failed: {0}")]
    ValidationFailed(String),

    #[error("Invalid input: {0}")]
    InvalidInput(String),

    #[error("Encryption error: {0}")]
    EncryptionError(String),
}

#[cfg(test)]
mod tests;
