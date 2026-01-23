//! Identity store - сохранение и загрузка идентичности
//!
//! Хранит приватный ключ локально для восстановления.

use super::Identity;
use ed25519_dalek::SigningKey;
use x25519_dalek::StaticSecret;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

#[derive(Debug, Serialize, Deserialize)]
struct StoredIdentity {
    signing_key_hex: String,
    x25519_secret_hex: Option<String>, // Опционально для обратной совместимости
}

/// Загрузить идентичность из файла
pub fn load_identity<P: AsRef<Path>>(path: P) -> Result<Option<Identity>, IdentityStoreError> {
    let path = path.as_ref();
    let content = match fs::read_to_string(path) {
        Ok(content) => content,
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(err) => return Err(IdentityStoreError::Io(err)),
    };

    let stored: StoredIdentity =
        serde_json::from_str(&content).map_err(IdentityStoreError::Deserialize)?;
    let key_bytes = hex::decode(stored.signing_key_hex)
        .map_err(IdentityStoreError::InvalidHex)?;

    if key_bytes.len() != 32 {
        return Err(IdentityStoreError::InvalidKeyLength(key_bytes.len()));
    }

    let mut key_array = [0u8; 32];
    key_array.copy_from_slice(&key_bytes);
    let signing_key = SigningKey::from_bytes(&key_array);
    
        // Если есть сохраненный X25519 ключ, используем его, иначе генерируем новый
        let mut identity = Identity::from_signing_key(signing_key);
        
        if let Some(x25519_hex) = stored.x25519_secret_hex {
            let x25519_bytes = hex::decode(x25519_hex)
                .map_err(IdentityStoreError::InvalidHex)?;
            if x25519_bytes.len() != 32 {
                return Err(IdentityStoreError::InvalidKeyLength(x25519_bytes.len()));
            }
            let mut x25519_array = [0u8; 32];
            x25519_array.copy_from_slice(&x25519_bytes);
            let x25519_secret = StaticSecret::from(x25519_array);
            use x25519_dalek::PublicKey as X25519PublicKey;
            let x25519_public = X25519PublicKey::from(&x25519_secret);
            identity.set_x25519_keys(x25519_secret, x25519_public);
        }
        
        Ok(Some(identity))
}

/// Сохранить идентичность в файл
pub fn save_identity<P: AsRef<Path>>(
    path: P,
    identity: &Identity,
) -> Result<(), IdentityStoreError> {
    let signing_key = identity
        .signing_key_bytes()
        .ok_or(IdentityStoreError::MissingPrivateKey)?;
    
    let x25519_secret_hex = identity.x25519_secret()
        .map(|secret| hex::encode(secret.to_bytes()));
    
    let stored = StoredIdentity {
        signing_key_hex: hex::encode(signing_key),
        x25519_secret_hex,
    };
    let content = serde_json::to_string(&stored).map_err(IdentityStoreError::Serialize)?;
    fs::write(path, content).map_err(IdentityStoreError::Io)?;
    Ok(())
}

/// Ошибки хранения идентичности
#[derive(Debug, thiserror::Error)]
pub enum IdentityStoreError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Serialize error: {0}")]
    Serialize(serde_json::Error),
    #[error("Deserialize error: {0}")]
    Deserialize(serde_json::Error),
    #[error("Invalid hex data: {0}")]
    InvalidHex(#[from] hex::FromHexError),
    #[error("Invalid key length: {0}")]
    InvalidKeyLength(usize),
    #[error("Missing private key")]
    MissingPrivateKey,
}
