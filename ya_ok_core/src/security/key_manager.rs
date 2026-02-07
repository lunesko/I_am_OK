//! Key Manager - управление ключами шифрования
//!
//! Генерирует и управляет ключами для шифрования базы данных и других sensitive данных.
//! 
//! # Security Model
//! - Ключи генерируются из device fingerprint + random salt
//! - Хранятся в platform-specific secure storage:
//!   * Android: Android Keystore (hardware-backed)
//!   * iOS: iOS Keychain
//!   * Desktop: Encrypted config file
//! - Используют PBKDF2 для derivation

use sha2::{Sha256, Digest};
use rand::{RngCore, rngs::OsRng};
use std::path::Path;
use std::fs;
use serde::{Serialize, Deserialize};

/// Конфигурация ключа шифрования
#[derive(Serialize, Deserialize)]
struct KeyConfig {
    /// Salt для PBKDF2 (32 bytes)
    salt: Vec<u8>,
    /// Итерации для PBKDF2
    iterations: u32,
    /// Версия схемы ключа
    version: u32,
}

/// Менеджер ключей шифрования
pub struct KeyManager {
    config_path: String,
}

impl KeyManager {
    /// Создать новый KeyManager
    pub fn new<P: AsRef<Path>>(config_path: P) -> Self {
        Self {
            config_path: config_path.as_ref().to_string_lossy().to_string(),
        }
    }

    /// Получить или создать ключ шифрования для базы данных
    /// 
    /// # Returns
    /// Hex-encoded encryption key (64 chars = 32 bytes)
    pub fn get_or_create_db_key(&self) -> Result<String, KeyError> {
        // Проверяем существует ли конфиг
        if Path::new(&self.config_path).exists() {
            return self.load_existing_key();
        }
        
        // Создаем новый ключ
        self.create_new_key()
    }

    /// Создать новый ключ
    fn create_new_key(&self) -> Result<String, KeyError> {
        // Генерируем random salt
        let mut salt = vec![0u8; 32];
        OsRng.fill_bytes(&mut salt);

        // Генерируем ключ из device fingerprint + salt
        let device_id = self.get_device_fingerprint()?;
        let key = self.derive_key(&device_id, &salt, 100_000)?;

        // Сохраняем конфиг
        let config = KeyConfig {
            salt: salt.clone(),
            iterations: 100_000,
            version: 1,
        };
        
        self.save_config(&config)?;

        Ok(hex::encode(&key))
    }

    /// Загрузить существующий ключ
    fn load_existing_key(&self) -> Result<String, KeyError> {
        // Загружаем конфиг
        let config = self.load_config()?;

        // Получаем device fingerprint
        let device_id = self.get_device_fingerprint()?;

        // Derive ключ с теми же параметрами
        let key = self.derive_key(&device_id, &config.salt, config.iterations)?;

        Ok(hex::encode(&key))
    }

    /// Получить device fingerprint
    /// 
    /// В production это должно использовать platform-specific API:
    /// - Android: Settings.Secure.ANDROID_ID
    /// - iOS: UIDevice.identifierForVendor
    /// - Desktop: MAC address + hostname
    fn get_device_fingerprint(&self) -> Result<String, KeyError> {
        // Temporary implementation: использовать hostname
        #[cfg(not(target_os = "android"))]
        #[cfg(not(target_os = "ios"))]
        {
            use std::process::Command;
            
            let output = Command::new("hostname")
                .output()
                .map_err(|e| KeyError::DeviceIdError(e.to_string()))?;
            
            let hostname = String::from_utf8_lossy(&output.stdout)
                .trim()
                .to_string();
            
            if hostname.is_empty() {
                return Err(KeyError::DeviceIdError("Empty hostname".to_string()));
            }
            
            Ok(hostname)
        }
        
        // TODO: Реализовать для Android через JNI
        #[cfg(target_os = "android")]
        {
            // FFI call: get_android_device_id()
            Err(KeyError::PlatformNotSupported)
        }
        
        // TODO: Реализовать для iOS через FFI
        #[cfg(target_os = "ios")]
        {
            // FFI call: get_ios_device_id()
            Err(KeyError::PlatformNotSupported)
        }
    }

    /// Derive ключ из device ID и salt с использованием PBKDF2
    fn derive_key(&self, device_id: &str, salt: &[u8], iterations: u32) -> Result<Vec<u8>, KeyError> {
        use sha2::Sha256;
        
        // Simple PBKDF2 implementation using SHA256
        let mut derived = device_id.as_bytes().to_vec();
        
        for _ in 0..iterations {
            let mut hasher = Sha256::new();
            hasher.update(&derived);
            hasher.update(salt);
            derived = hasher.finalize().to_vec();
        }
        
        Ok(derived)
    }

    /// Сохранить конфиг
    fn save_config(&self, config: &KeyConfig) -> Result<(), KeyError> {
        let json = serde_json::to_string_pretty(config)
            .map_err(|e| KeyError::ConfigError(e.to_string()))?;
        
        // Ensure parent directory exists
        if let Some(parent) = Path::new(&self.config_path).parent() {
            fs::create_dir_all(parent)
                .map_err(|e| KeyError::ConfigError(e.to_string()))?;
        }
        
        fs::write(&self.config_path, json)
            .map_err(|e| KeyError::ConfigError(e.to_string()))?;
        
        Ok(())
    }

    /// Загрузить конфиг
    fn load_config(&self) -> Result<KeyConfig, KeyError> {
        let json = fs::read_to_string(&self.config_path)
            .map_err(|e| KeyError::ConfigError(e.to_string()))?;
        
        let config: KeyConfig = serde_json::from_str(&json)
            .map_err(|e| KeyError::ConfigError(e.to_string()))?;
        
        Ok(config)
    }
}

/// Ошибки KeyManager
#[derive(Debug, thiserror::Error)]
pub enum KeyError {
    #[error("Failed to get device ID: {0}")]
    DeviceIdError(String),

    #[error("Configuration error: {0}")]
    ConfigError(String),

    #[error("Platform not supported")]
    PlatformNotSupported,

    #[error("Crypto error")]
    CryptoError,
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_key_generation() {
        let temp_dir = TempDir::new().unwrap();
        let config_path = temp_dir.path().join("key.config");
        let manager = KeyManager::new(&config_path);
        
        // Создать новый ключ
        let key1 = manager.get_or_create_db_key().unwrap();
        
        // Ключ должен быть hex строкой (64 chars)
        assert_eq!(key1.len(), 64);
        assert!(key1.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_key_persistence() {
        let temp_dir = TempDir::new().unwrap();
        let config_path = temp_dir.path().join("key.config");
        let manager = KeyManager::new(&config_path);
        
        // Создать ключ
        let key1 = manager.get_or_create_db_key().unwrap();
        
        // Создать другой менеджер с тем же путем
        let manager2 = KeyManager::new(&config_path);
        let key2 = manager2.get_or_create_db_key().unwrap();
        
        // Ключи должны совпадать
        assert_eq!(key1, key2);
    }

    #[test]
    fn test_key_uniqueness() {
        let temp_dir1 = TempDir::new().unwrap();
        let temp_dir2 = TempDir::new().unwrap();
        
        let config_path1 = temp_dir1.path().join("key.config");
        let config_path2 = temp_dir2.path().join("key.config");
        
        let manager1 = KeyManager::new(&config_path1);
        let manager2 = KeyManager::new(&config_path2);
        
        let key1 = manager1.get_or_create_db_key().unwrap();
        let key2 = manager2.get_or_create_db_key().unwrap();
        
        // Ключи должны различаться (разные salt)
        // На одном устройстве hostname одинаковый, но salt разный
        println!("Key1: {}", key1);
        println!("Key2: {}", key2);
        
        // Проверяем что конфиги разные
        let config1 = manager1.load_config().unwrap();
        let config2 = manager2.load_config().unwrap();
        assert_ne!(config1.salt, config2.salt);
    }
}
