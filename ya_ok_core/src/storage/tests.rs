use super::*;
use tempfile::tempdir;
use crate::core::message::{Message, MessageType, MessagePayload, StatusType};

fn create_test_message() -> Message {
    Message::new(
        "sender-abc".to_string(),
        MessageType::Status,
        MessagePayload::Status(StatusType::Ok),
    )
}

#[test]
fn test_ack_storage() {
    let dir = tempdir().unwrap();
    let db_path = dir.path().join("test.db");
    let storage = Storage::new(db_path.to_str().unwrap()).unwrap();

    let message = create_test_message();
    storage.store_message(&message).unwrap();

    // Store Received ACK
    storage.store_ack(&message.id, "peer1", "Received").unwrap();

    // Verify ACK stored
    let acks = storage.get_acks_for_message(&message.id).unwrap();
    assert_eq!(acks.len(), 1);
    assert_eq!(acks[0].0, "peer1");
    assert_eq!(acks[0].1, "Received");

    // Store Delivered ACK
    storage.store_ack(&message.id, "peer1", "Delivered").unwrap();

    // Verify Delivered ACK stored and message marked delivered
    let acks = storage.get_acks_for_message(&message.id).unwrap();
    assert_eq!(acks.len(), 2);

    // Check message marked as delivered
    let msg = storage.get_message_by_id(&message.id).unwrap();
    assert!(msg.is_some());

    // Get pending messages - should be empty since message is delivered
    let pending = storage.get_pending_messages().unwrap();
    assert_eq!(pending.len(), 0, "Delivered message should not be in pending");
}

#[test]
fn test_multiple_acks() {
    let dir = tempdir().unwrap();
    let db_path = dir.path().join("test.db");
    let storage = Storage::new(db_path.to_str().unwrap()).unwrap();

    let message = create_test_message();
    storage.store_message(&message).unwrap();

    // Multiple peers ACK
    storage.store_ack(&message.id, "peer1", "Received").unwrap();
    storage.store_ack(&message.id, "peer2", "Received").unwrap();
    storage.store_ack(&message.id, "peer3", "Received").unwrap();

    let acks = storage.get_acks_for_message(&message.id).unwrap();
    assert_eq!(acks.len(), 3);
}

#[test]
fn test_ack_replace() {
    let dir = tempdir().unwrap();
    let db_path = dir.path().join("test.db");
    let storage = Storage::new(db_path.to_str().unwrap()).unwrap();

    let message = create_test_message();
    storage.store_message(&message).unwrap();

    // Store Received ACK
    storage.store_ack(&message.id, "peer1", "Received").unwrap();

    // Replace with Delivered ACK from same peer
    storage.store_ack(&message.id, "peer1", "Delivered").unwrap();

    // Should have both ACKs (INSERT OR REPLACE keeps both types)
    let acks = storage.get_acks_for_message(&message.id).unwrap();
    assert_eq!(acks.len(), 2);
}
