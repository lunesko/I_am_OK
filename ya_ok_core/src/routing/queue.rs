//! DTN Queue - очереди для Store & Forward
//!
//! Управляет очередями пакетов для отложенной пересылки с приоритетами и retry.

use crate::core::{Packet, Priority};
use std::collections::{HashMap, VecDeque};
use std::time::{Duration, Instant};

/// Максимальный размер очереди на приоритет
const MAX_QUEUE_SIZE_PER_PRIORITY: usize = 100;

/// Максимальное количество попыток пересылки
const MAX_RETRY_ATTEMPTS: u8 = 3;

/// Задержка между попытками (exponential backoff)
const RETRY_BASE_DELAY: Duration = Duration::from_secs(5);

#[derive(Clone, Debug)]
pub struct QueuedPacket {
    pub packet: Packet,
    /// Количество попыток пересылки
    pub retry_count: u8,
    /// Время последней попытки
    pub last_attempt: Option<Instant>,
    /// Целевой peer (если известен)
    pub target_peer: Option<String>,
}

impl QueuedPacket {
    pub fn new(packet: Packet, target_peer: Option<String>) -> Self {
        Self {
            packet,
            retry_count: 0,
            last_attempt: None,
            target_peer,
        }
    }

    /// Можно ли повторить попытку сейчас?
    pub fn can_retry(&self) -> bool {
        if self.retry_count >= MAX_RETRY_ATTEMPTS {
            return false;
        }

        match self.last_attempt {
            None => true,
            Some(last) => {
                let backoff = RETRY_BASE_DELAY * 2_u32.pow(self.retry_count as u32);
                Instant::now().duration_since(last) >= backoff
            }
        }
    }

    /// Отметить попытку пересылки
    pub fn mark_attempt(&mut self) {
        self.retry_count += 1;
        self.last_attempt = Some(Instant::now());
    }

    /// Проверить, истёк ли TTL пакета
    pub fn is_expired(&self) -> bool {
        !self.packet.can_be_forwarded()
    }
}

/// Менеджер очередей для DTN
pub struct DtnQueue {
    /// Очереди по приоритетам
    queues: HashMap<Priority, VecDeque<QueuedPacket>>,
}

impl DtnQueue {
    pub fn new() -> Self {
        let mut queues = HashMap::new();
        queues.insert(Priority::High, VecDeque::new());
        queues.insert(Priority::Medium, VecDeque::new());
        queues.insert(Priority::Low, VecDeque::new());

        Self { queues }
    }

    /// Добавить пакет в очередь
    pub fn enqueue(&mut self, queued_packet: QueuedPacket) -> Result<(), QueueError> {
        let priority = queued_packet.packet.priority;
        let queue = self.queues.get_mut(&priority).ok_or(QueueError::InvalidPriority)?;

        // Проверяем размер очереди
        if queue.len() >= MAX_QUEUE_SIZE_PER_PRIORITY {
            // Удаляем самый старый пакет из очереди (FIFO для освобождения места)
            queue.pop_front();
        }

        queue.push_back(queued_packet);
        Ok(())
    }

    /// Получить следующий пакет для пересылки (с учётом приоритетов)
    pub fn dequeue_ready(&mut self) -> Option<QueuedPacket> {
        // Проверяем очереди в порядке приоритета
        for priority in [Priority::High, Priority::Medium, Priority::Low] {
            if let Some(queue) = self.queues.get_mut(&priority) {
                // Ищем первый пакет, готовый к retry
                for i in 0..queue.len() {
                    if let Some(pkt) = queue.get(i) {
                        if pkt.can_retry() && !pkt.is_expired() {
                            return queue.remove(i);
                        }
                    }
                }
            }
        }

        None
    }

    /// Очистить истекшие пакеты
    pub fn cleanup_expired(&mut self) -> usize {
        let mut removed = 0;

        for queue in self.queues.values_mut() {
            let before = queue.len();
            queue.retain(|pkt| !pkt.is_expired());
            removed += before - queue.len();
        }

        removed
    }

    /// Получить статистику очередей
    pub fn stats(&self) -> QueueStats {
        QueueStats {
            high_priority_count: self.queues.get(&Priority::High).map(|q| q.len()).unwrap_or(0),
            medium_priority_count: self.queues.get(&Priority::Medium).map(|q| q.len()).unwrap_or(0),
            low_priority_count: self.queues.get(&Priority::Low).map(|q| q.len()).unwrap_or(0),
        }
    }

    /// Получить общее количество пакетов в очередях
    pub fn total_count(&self) -> usize {
        self.queues.values().map(|q| q.len()).sum()
    }
}

#[derive(Clone, Debug, Default)]
pub struct QueueStats {
    pub high_priority_count: usize,
    pub medium_priority_count: usize,
    pub low_priority_count: usize,
}

#[derive(Debug, thiserror::Error)]
pub enum QueueError {
    #[error("Invalid priority")]
    InvalidPriority,

    #[error("Queue full")]
    QueueFull,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::{Message, StatusType, Identity};

    fn create_test_packet(priority: Priority) -> Packet {
        let identity = Identity::new();
        let message = Message::status("test_sender".into(), StatusType::Ok);
        let receiver_key = [0u8; 32];
        let mut packet = Packet::from_message(&message, &identity, &receiver_key).unwrap();
        packet.priority = priority;
        packet
    }

    #[test]
    fn enqueue_dequeue_respects_priority() {
        let mut queue = DtnQueue::new();

        let low_pkt = create_test_packet(Priority::Low);
        let high_pkt = create_test_packet(Priority::High);
        let med_pkt = create_test_packet(Priority::Medium);

        queue.enqueue(QueuedPacket::new(low_pkt, None)).unwrap();
        queue.enqueue(QueuedPacket::new(high_pkt, None)).unwrap();
        queue.enqueue(QueuedPacket::new(med_pkt, None)).unwrap();

        // Первым должен выйти high priority
        let first = queue.dequeue_ready().unwrap();
        assert_eq!(first.packet.priority, Priority::High);

        // Затем medium
        let second = queue.dequeue_ready().unwrap();
        assert_eq!(second.packet.priority, Priority::Medium);

        // Затем low
        let third = queue.dequeue_ready().unwrap();
        assert_eq!(third.packet.priority, Priority::Low);
    }

    #[test]
    fn retry_backoff_works() {
        let packet = create_test_packet(Priority::High);
        let mut queued = QueuedPacket::new(packet, None);

        assert!(queued.can_retry());
        
        queued.mark_attempt();
        assert_eq!(queued.retry_count, 1);
        assert!(!queued.can_retry()); // Сразу после попытки нельзя
    }

    #[test]
    fn cleanup_removes_expired() {
        let mut queue = DtnQueue::new();

        // Добавляем несколько пакетов
        for _ in 0..5 {
            let pkt = create_test_packet(Priority::High);
            queue.enqueue(QueuedPacket::new(pkt, None)).unwrap();
        }

        assert_eq!(queue.total_count(), 5);

        // Cleanup (в тесте пакеты не истекли, так что ничего не удалится)
        let removed = queue.cleanup_expired();
        assert_eq!(removed, 0);
        assert_eq!(queue.total_count(), 5);
    }
}
