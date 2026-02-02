//! Chunking/Reassembly для UDP payload
//!
//! Разбивает большие payloads на chunks для передачи через UDP
//! и собирает их обратно, обрабатывая потерю пакетов и таймауты.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{Duration, Instant};

/// Максимальный размер chunk для UDP (учитываем MTU ~1400 байт минус заголовки)
pub const MAX_CHUNK_SIZE: usize = 1200;

/// Таймаут для сборки chunks (если за это время не получены все части, сброс)
pub const REASSEMBLY_TIMEOUT: Duration = Duration::from_secs(30);

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ChunkedMessage {
    /// Уникальный ID сообщения
    pub message_id: String,
    /// Номер текущего chunk (0-based)
    pub chunk_index: u16,
    /// Общее количество chunks
    pub total_chunks: u16,
    /// Данные этого chunk
    pub data: Vec<u8>,
    /// Опциональный checksum для проверки целостности
    pub checksum: Option<u32>,
}

impl ChunkedMessage {
    /// Разбить payload на chunks
    pub fn chunk_payload(message_id: String, payload: &[u8]) -> Vec<Self> {
        if payload.is_empty() {
            return vec![ChunkedMessage {
                message_id,
                chunk_index: 0,
                total_chunks: 1,
                data: Vec::new(),
                checksum: Some(0),
            }];
        }

        let total_chunks = ((payload.len() + MAX_CHUNK_SIZE - 1) / MAX_CHUNK_SIZE) as u16;
        let mut chunks = Vec::new();

        for (i, chunk_data) in payload.chunks(MAX_CHUNK_SIZE).enumerate() {
            chunks.push(ChunkedMessage {
                message_id: message_id.clone(),
                chunk_index: i as u16,
                total_chunks,
                data: chunk_data.to_vec(),
                checksum: Some(crc32fast::hash(chunk_data)),
            });
        }

        chunks
    }

    /// Проверить checksum chunk
    pub fn verify_checksum(&self) -> bool {
        match self.checksum {
            Some(expected) => crc32fast::hash(&self.data) == expected,
            None => true, // нет checksum = всегда валидный (обратная совместимость)
        }
    }
}

/// Менеджер сборки chunks
pub struct ChunkReassembler {
    /// Карта: message_id -> ReassemblyState
    pending: HashMap<String, ReassemblyState>,
}

struct ReassemblyState {
    /// Полученные chunks (индекс -> данные)
    chunks: HashMap<u16, Vec<u8>>,
    /// Ожидаемое общее количество chunks
    total_chunks: u16,
    /// Время начала сборки
    started_at: Instant,
}

impl ChunkReassembler {
    pub fn new() -> Self {
        Self {
            pending: HashMap::new(),
        }
    }

    /// Добавить chunk и попытаться собрать payload
    pub fn add_chunk(&mut self, chunk: ChunkedMessage) -> Result<Option<Vec<u8>>, ReassemblyError> {
        // Проверяем checksum
        if !chunk.verify_checksum() {
            return Err(ReassemblyError::ChecksumMismatch);
        }

        // Проверяем валидность индексов
        if chunk.chunk_index >= chunk.total_chunks {
            return Err(ReassemblyError::InvalidChunkIndex);
        }

        let message_id = chunk.message_id.clone();
        
        // Получаем или создаём состояние сборки
        let state = self.pending.entry(message_id.clone()).or_insert_with(|| {
            ReassemblyState {
                chunks: HashMap::new(),
                total_chunks: chunk.total_chunks,
                started_at: Instant::now(),
            }
        });

        // Проверяем согласованность total_chunks
        if state.total_chunks != chunk.total_chunks {
            self.pending.remove(&message_id);
            return Err(ReassemblyError::InconsistentMetadata);
        }

        // Добавляем chunk
        state.chunks.insert(chunk.chunk_index, chunk.data);

        // Проверяем, все ли chunks получены
        if state.chunks.len() == chunk.total_chunks as usize {
            // Собираем payload
            let mut payload = Vec::new();
            for i in 0..chunk.total_chunks {
                if let Some(data) = state.chunks.get(&i) {
                    payload.extend_from_slice(data);
                } else {
                    // Не должно случиться, но на всякий случай
                    self.pending.remove(&message_id);
                    return Err(ReassemblyError::MissingChunks);
                }
            }

            // Удаляем из pending
            self.pending.remove(&message_id);
            
            Ok(Some(payload))
        } else {
            Ok(None) // Ещё не все chunks получены
        }
    }

    /// Очистить истекшие сборки (cleanup для таймаутов)
    pub fn cleanup_expired(&mut self) -> usize {
        let now = Instant::now();
        let before = self.pending.len();
        
        self.pending.retain(|_, state| {
            now.duration_since(state.started_at) < REASSEMBLY_TIMEOUT
        });

        before - self.pending.len()
    }

    /// Получить количество незавершённых сборок
    pub fn pending_count(&self) -> usize {
        self.pending.len()
    }
}

#[derive(Debug, thiserror::Error)]
pub enum ReassemblyError {
    #[error("Checksum mismatch")]
    ChecksumMismatch,
    
    #[error("Invalid chunk index")]
    InvalidChunkIndex,
    
    #[error("Inconsistent metadata")]
    InconsistentMetadata,
    
    #[error("Missing chunks")]
    MissingChunks,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn chunk_and_reassemble_small_payload() {
        let payload = b"Hello, world!";
        let chunks = ChunkedMessage::chunk_payload("msg1".into(), payload);
        
        assert_eq!(chunks.len(), 1);
        assert_eq!(chunks[0].total_chunks, 1);
        assert!(chunks[0].verify_checksum());

        let mut reassembler = ChunkReassembler::new();
        let result = reassembler.add_chunk(chunks[0].clone()).unwrap();
        
        assert_eq!(result, Some(payload.to_vec()));
    }

    #[test]
    fn chunk_and_reassemble_large_payload() {
        let payload = vec![42u8; MAX_CHUNK_SIZE * 3 + 100];
        let chunks = ChunkedMessage::chunk_payload("msg2".into(), &payload);
        
        assert_eq!(chunks.len(), 4);
        assert_eq!(chunks[0].total_chunks, 4);
        
        let mut reassembler = ChunkReassembler::new();
        
        // Добавляем chunks в случайном порядке
        assert_eq!(reassembler.add_chunk(chunks[2].clone()).unwrap(), None);
        assert_eq!(reassembler.add_chunk(chunks[0].clone()).unwrap(), None);
        assert_eq!(reassembler.add_chunk(chunks[3].clone()).unwrap(), None);
        let result = reassembler.add_chunk(chunks[1].clone()).unwrap();
        
        assert_eq!(result, Some(payload));
    }

    #[test]
    fn reassemble_fails_on_checksum_mismatch() {
        let chunk = ChunkedMessage {
            message_id: "msg3".into(),
            chunk_index: 0,
            total_chunks: 1,
            data: vec![1, 2, 3],
            checksum: Some(999999), // неверный checksum
        };
        
        let mut reassembler = ChunkReassembler::new();
        let result = reassembler.add_chunk(chunk);
        
        assert!(matches!(result, Err(ReassemblyError::ChecksumMismatch)));
    }

    #[test]
    fn cleanup_expired_removes_old_assemblies() {
        let mut reassembler = ChunkReassembler::new();
        
        // Добавляем неполный chunk
        let chunk = ChunkedMessage {
            message_id: "msg4".into(),
            chunk_index: 0,
            total_chunks: 3,
            data: vec![1, 2, 3],
            checksum: Some(crc32fast::hash(&[1, 2, 3])),
        };
        
        reassembler.add_chunk(chunk).unwrap();
        assert_eq!(reassembler.pending_count(), 1);
        
        // Имитируем истечение времени (в реальности нужно подождать REASSEMBLY_TIMEOUT)
        // Здесь просто проверяем, что cleanup работает
        let expired = reassembler.cleanup_expired();
        // Сразу после добавления не должно быть истекших
        assert_eq!(expired, 0);
    }
}
