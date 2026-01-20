//! Crypto - криптографические операции
//!
//! - Ed25519 для идентичности и подписей
//! - X25519 для обмена ключами
//! - AES-GCM для шифрования payload

use aes_gcm::{Aes256Gcm, Key, Nonce};
use aes_gcm::aead::{Aead, NewAead};
use rand::rngs::OsRng;
use rand::RngCore;
use x25519_dalek::{PublicKey, StaticSecret};
use serde::{Deserialize, Serialize};

/// Зашифрованный payload
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct EncryptedPayload {
    /// Зашифрованные данные
    pub ciphertext: Vec<u8>,
    /// Nonce для AES-GCM
    pub nonce: Vec<u8>,
    /// Публичный ключ отправителя (для X25519)
    pub sender_public_key: Vec<u8>,
}

/// Результат симметричного шифрования
pub struct SymmetricEncryption {
    pub ciphertext: Vec<u8>,
    pub nonce: [u8; 12],
}

/// Ключ для симметричного шифрования (AES-256)
pub type SymmetricKey = [u8; 32];

/// Криптографические операции
pub struct Crypto;

impl Crypto {
    /// Генерировать новый X25519 ключ для ECDH
    pub fn generate_ephemeral_keypair() -> (StaticSecret, PublicKey) {
        let secret = StaticSecret::new(OsRng);
        let public = PublicKey::from(&secret);
        (secret, public)
    }

    /// Вычислить общий секрет через ECDH
    pub fn compute_shared_secret(
        private_key: &StaticSecret,
        public_key: &PublicKey,
    ) -> SymmetricKey {
        private_key.diffie_hellman(public_key).to_bytes()
    }

    /// Зашифровать данные симметрично (AES-GCM)
    pub fn encrypt_symmetric(
        key: &SymmetricKey,
        plaintext: &[u8],
    ) -> Result<SymmetricEncryption, CryptoError> {
        let cipher = Aes256Gcm::new(Key::from_slice(key));
        let mut nonce_bytes = [0u8; 12];
        OsRng.fill_bytes(&mut nonce_bytes);
        let nonce = Nonce::from_slice(&nonce_bytes);

        let ciphertext = cipher
            .encrypt(nonce, plaintext)
            .map_err(|_| CryptoError::EncryptionFailed)?;

        Ok(SymmetricEncryption {
            ciphertext,
            nonce: nonce_bytes,
        })
    }

    /// Расшифровать данные симметрично (AES-GCM)
    pub fn decrypt_symmetric(
        key: &SymmetricKey,
        ciphertext: &[u8],
        nonce: &[u8; 12],
    ) -> Result<Vec<u8>, CryptoError> {
        let cipher = Aes256Gcm::new(Key::from_slice(key));
        let nonce = Nonce::from_slice(nonce);

        cipher
            .decrypt(nonce, ciphertext)
            .map_err(|_| CryptoError::DecryptionFailed)
    }

    /// Зашифровать payload для получателя
    pub fn encrypt_payload(
        sender_private_key: &StaticSecret,
        sender_public_key: &PublicKey,
        receiver_public_key: &PublicKey,
        plaintext: &[u8],
    ) -> Result<EncryptedPayload, CryptoError> {
        // Вычисляем общий секрет
        let shared_secret = Self::compute_shared_secret(sender_private_key, receiver_public_key);

        // Шифруем payload
        let encryption = Self::encrypt_symmetric(&shared_secret, plaintext)?;

        Ok(EncryptedPayload {
            ciphertext: encryption.ciphertext,
            nonce: encryption.nonce.to_vec(),
            sender_public_key: sender_public_key.to_bytes().to_vec(),
        })
    }

    /// Расшифровать payload
    pub fn decrypt_payload(
        receiver_private_key: &StaticSecret,
        sender_public_key: &PublicKey,
        encrypted: &EncryptedPayload,
    ) -> Result<Vec<u8>, CryptoError> {
        // Вычисляем общий секрет
        let shared_secret = Self::compute_shared_secret(receiver_private_key, sender_public_key);

        // Расшифровываем
        let nonce = encrypted.nonce.as_slice().try_into()
            .map_err(|_| CryptoError::InvalidNonce)?;

        Self::decrypt_symmetric(&shared_secret, &encrypted.ciphertext, &nonce)
    }
}

/// Ошибки криптографии
#[derive(Debug, thiserror::Error)]
pub enum CryptoError {
    #[error("Encryption failed")]
    EncryptionFailed,

    #[error("Decryption failed")]
    DecryptionFailed,

    #[error("Invalid nonce")]
    InvalidNonce,
}