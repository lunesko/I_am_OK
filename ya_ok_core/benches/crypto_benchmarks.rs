use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId};
use ya_ok_core::core::{Crypto, SymmetricKey};
use x25519_dalek::{PublicKey, StaticSecret};

fn benchmark_keypair_generation(c: &mut Criterion) {
    c.bench_function("keypair_generation", |b| {
        b.iter(|| {
            Crypto::generate_ephemeral_keypair()
        });
    });
}

fn benchmark_shared_secret(c: &mut Criterion) {
    let (alice_secret, _) = Crypto::generate_ephemeral_keypair();
    let (_, bob_public) = Crypto::generate_ephemeral_keypair();
    
    c.bench_function("shared_secret_computation", |b| {
        b.iter(|| {
            Crypto::compute_shared_secret(&alice_secret, &bob_public)
        });
    });
}

fn benchmark_symmetric_encryption(c: &mut Criterion) {
    let key = SymmetricKey::from([42u8; 32]);
    
    let mut group = c.benchmark_group("symmetric_encryption");
    
    for size in [64, 256, 1024, 4096, 10240].iter() {
        let data = vec![0u8; *size];
        
        group.bench_with_input(BenchmarkId::from_parameter(size), size, |b, _| {
            b.iter(|| {
                Crypto::encrypt_symmetric(&key, black_box(&data))
            });
        });
    }
    
    group.finish();
}

fn benchmark_symmetric_decryption(c: &mut Criterion) {
    let key = SymmetricKey::from([42u8; 32]);
    
    let mut group = c.benchmark_group("symmetric_decryption");
    
    for size in [64, 256, 1024, 4096, 10240].iter() {
        let data = vec![0u8; *size];
        let encrypted = Crypto::encrypt_symmetric(&key, &data).unwrap();
        
        group.bench_with_input(BenchmarkId::from_parameter(size), size, |b, _| {
            b.iter(|| {
                Crypto::decrypt_symmetric(&key, black_box(&encrypted.ciphertext), &encrypted.nonce)
            });
        });
    }
    
    group.finish();
}

fn benchmark_e2e_encryption(c: &mut Criterion) {
    let (alice_secret, alice_public) = Crypto::generate_ephemeral_keypair();
    let (_, bob_public) = Crypto::generate_ephemeral_keypair();
    let plaintext = vec![0u8; 1024];
    
    c.bench_function("e2e_encryption", |b| {
        b.iter(|| {
            Crypto::encrypt_payload(
                &alice_secret,
                &alice_public,
                &bob_public,
                black_box(&plaintext)
            )
        });
    });
}

criterion_group!(
    benches,
    benchmark_keypair_generation,
    benchmark_shared_secret,
    benchmark_symmetric_encryption,
    benchmark_symmetric_decryption,
    benchmark_e2e_encryption
);

criterion_main!(benches);
