use criterion::{black_box, criterion_group, criterion_main, Criterion};
use ya_ok_core::storage::Storage;
use ya_ok_core::core::{Message, MessageType, StatusType, MessagePayload};
use tempfile::TempDir;
use chrono::Utc;

fn benchmark_message_store(c: &mut Criterion) {
    c.bench_function("message_store", |b| {
        let temp_dir = TempDir::new().unwrap();
        let db_path = temp_dir.path().join("bench.db");
        let storage = Storage::new(&db_path).unwrap();
        
        let message = Message {
            id: uuid::Uuid::new_v4().to_string(),
            sender_id: "sender123".to_string(),
            recipient_id: Some("recipient456".to_string()),
            timestamp: Utc::now(),
            message_type: MessageType::Text,
            payload: MessagePayload::Text("Benchmark message".to_string()),
        };
        
        b.iter(|| {
            storage.store_message(black_box(&message)).unwrap();
        });
    });
}

fn benchmark_message_query(c: &mut Criterion) {
    let temp_dir = TempDir::new().unwrap();
    let db_path = temp_dir.path().join("bench.db");
    let storage = Storage::new(&db_path).unwrap();
    
    // Populate database
    for i in 0..1000 {
        let message = Message {
            id: format!("msg-{}", i),
            sender_id: "sender123".to_string(),
            recipient_id: Some("recipient456".to_string()),
            timestamp: Utc::now(),
            message_type: MessageType::Text,
            payload: MessagePayload::Text(format!("Message {}", i)),
        };
        storage.store_message(&message).unwrap();
    }
    
    c.bench_function("message_query_pending", |b| {
        b.iter(|| {
            storage.get_pending_messages().unwrap()
        });
    });
}

fn benchmark_nonce_check(c: &mut Criterion) {
    let temp_dir = TempDir::new().unwrap();
    let db_path = temp_dir.path().join("bench.db");
    let storage = Storage::new(&db_path).unwrap();
    
    let nonce = [42u8; 24];
    storage.mark_nonce_used(&nonce, "sender123").unwrap();
    
    c.bench_function("nonce_reuse_check", |b| {
        b.iter(|| {
            storage.is_nonce_used(black_box(&nonce), "sender123").unwrap()
        });
    });
}

criterion_group!(
    benches,
    benchmark_message_store,
    benchmark_message_query,
    benchmark_nonce_check
);

criterion_main!(benches);
