//! Identity - идентичность пользователя
//!
//! Каждый пользователь имеет уникальную идентичность на основе Ed25519 ключей.
//! Идентичность создается один раз и хранится локально.

use ed25519_dalek::{SigningKey, VerifyingKey, Signature, Signer, Verifier};
use rand::rngs::OsRng;
use serde::{Deserialize, Serialize};
use std::fmt;

/// Уникальная идентичность пользователя
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Identity {
    /// Публичный ключ для верификации (Ed25519)
    pub public_key: VerifyingKey,
    /// Приватный ключ для подписи (хранится в зашифрованном виде)
    #[serde(skip_serializing)]
    signing_key: Option<SigningKey>,
    /// Открытый идентификатор (hash от публичного ключа)
    pub id: String,
}

impl Identity {
    /// Создать новую идентичность
    pub fn new() -> Self {
        let mut rng = OsRng;
        let signing_key = SigningKey::generate(&mut rng);
        let public_key = signing_key.verifying_key();

        // Создаем ID как hex от публичного ключа
        let id = hex::encode(public_key.to_bytes());

        Self {
            public_key,
            signing_key: Some(signing_key),
            id,
        }
    }

    /// Создать идентичность из существующего публичного ключа
    /// (для валидации чужих сообщений)
    pub fn from_public_key(public_key: VerifyingKey) -> Self {
        let id = hex::encode(public_key.to_bytes());
        Self {
            public_key,
            signing_key: None,
            id,
        }
    }

    /// Подписать данные
    pub fn sign(&self, data: &[u8]) -> Result<Signature, IdentityError> {
        match &self.signing_key {
            Some(key) => Ok(key.sign(data)),
            None => Err(IdentityError::NoPrivateKey),
        }
    }

    /// Проверить подпись
    pub fn verify(&self, data: &[u8], signature: &Signature) -> Result<(), IdentityError> {
        self.public_key
            .verify(data, signature)
            .map_err(|_| IdentityError::InvalidSignature)
    }

    /// Получить публичный ключ как байты
    pub fn public_key_bytes(&self) -> [u8; 32] {
        self.public_key.to_bytes()
    }

    /// Восстановить из байтов (для загрузки из хранилища)
    pub fn from_bytes(bytes: &[u8]) -> Result<Self, IdentityError> {
        if bytes.len() != 32 {
            return Err(IdentityError::InvalidKeyLength);
        }

        let mut key_bytes = [0u8; 32];
        key_bytes.copy_from_slice(bytes);
        let public_key = VerifyingKey::from_bytes(&key_bytes)
            .map_err(|_| IdentityError::InvalidPublicKey)?;

        Ok(Self::from_public_key(public_key))
    }
}

impl fmt::Display for Identity {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Identity({})", &self.id[..8])
    }
}

/// Ошибки идентичности
#[derive(Debug, thiserror::Error)]
pub enum IdentityError {
    #[error("No private key available")]
    NoPrivateKey,

    #[error("Invalid signature")]
    InvalidSignature,

    #[error("Invalid key length")]
    InvalidKeyLength,

    #[error("Invalid public key")]
    InvalidPublicKey,
}