//! Identity - идентичность пользователя
//!
//! Каждый пользователь имеет уникальную идентичность на основе Ed25519 ключей.
//! Идентичность создается один раз и хранится локально.

use ed25519_dalek::{SigningKey, VerifyingKey, Signature, Signer, Verifier};
use x25519_dalek::{StaticSecret, PublicKey as X25519PublicKey};
use rand::rngs::OsRng;
use rand::RngCore;
use std::fmt;

/// Уникальная идентичность пользователя
#[derive(Clone)]
pub struct Identity {
    /// Публичный ключ для верификации (Ed25519)
    pub public_key: VerifyingKey,
    /// Приватный ключ для подписи (хранится в зашифрованном виде)
    signing_key: Option<SigningKey>,
    /// X25519 приватный ключ для ECDH (для шифрования)
    pub(crate) x25519_secret: Option<StaticSecret>,
    /// X25519 публичный ключ для ECDH
    pub(crate) x25519_public: Option<X25519PublicKey>,
    /// Открытый идентификатор (hash от публичного ключа)
    pub id: String,
}

impl std::fmt::Debug for Identity {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Identity")
            .field("public_key", &"<hidden>")
            .field("id", &self.id)
            .field("has_signing_key", &self.signing_key.is_some())
            .field("has_x25519_secret", &self.x25519_secret.is_some())
            .finish()
    }
}

impl Identity {
    /// Создать новую идентичность
    pub fn new() -> Self {
        let mut rng = OsRng;
        let mut secret_key = [0u8; 32];
        rng.fill_bytes(&mut secret_key);
        let signing_key = SigningKey::from_bytes(&secret_key);
        let public_key = signing_key.verifying_key();

        // Генерируем X25519 ключи для ECDH
        let x25519_secret = StaticSecret::random_from_rng(OsRng);
        let x25519_public = X25519PublicKey::from(&x25519_secret);

        // Создаем ID как hex от публичного ключа
        let id = hex::encode(public_key.to_bytes());

        Self {
            public_key,
            signing_key: Some(signing_key),
            x25519_secret: Some(x25519_secret),
            x25519_public: Some(x25519_public),
            id,
        }
    }

    /// Создать идентичность из приватного ключа (для восстановления)
    pub fn from_signing_key(signing_key: SigningKey) -> Self {
        let public_key = signing_key.verifying_key();
        let id = hex::encode(public_key.to_bytes());
        
        // Генерируем X25519 ключи для ECDH
        let x25519_secret = StaticSecret::random_from_rng(OsRng);
        let x25519_public = X25519PublicKey::from(&x25519_secret);
        
        Self {
            public_key,
            signing_key: Some(signing_key),
            x25519_secret: Some(x25519_secret),
            x25519_public: Some(x25519_public),
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
            x25519_secret: None,
            x25519_public: None,
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

    /// Получить приватный ключ (если доступен)
    pub fn signing_key_bytes(&self) -> Option<[u8; 32]> {
        self.signing_key.as_ref().map(|key| key.to_bytes())
    }

    /// Получить X25519 приватный ключ для ECDH
    pub fn x25519_secret(&self) -> Option<&StaticSecret> {
        self.x25519_secret.as_ref()
    }

    /// Получить X25519 публичный ключ для ECDH
    pub fn x25519_public(&self) -> Option<&X25519PublicKey> {
        self.x25519_public.as_ref()
    }

    /// Получить X25519 публичный ключ как байты
    pub fn x25519_public_bytes(&self) -> Option<[u8; 32]> {
        self.x25519_public.as_ref().map(|key| key.to_bytes())
    }

    /// Установить X25519 ключи (для восстановления из хранилища)
    pub fn set_x25519_keys(&mut self, secret: StaticSecret, public: X25519PublicKey) {
        self.x25519_secret = Some(secret);
        self.x25519_public = Some(public);
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