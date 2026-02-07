//! # Я ОК Core
//!
//! Автономное ядро для системы "Я ОК" - минимальной системы передачи сигналов присутствия.
//!
//! ## Архитектура
//!
//! ```text
//! [ UI ]          (Kotlin/Swift)
//!    |
//! [ FFI API ]     (JNI/Swift FFI)
//!    |
//! [ Rust Core ]   (этот crate)
//!    ├── core/      # идентичность, крипта, сообщения
//!    ├── transport/ # каналы (BLE, Wi-Fi, IP)
//!    ├── routing/   # DTN Store & Forward
//!    ├── storage/   # локальное хранение
//!    ├── sync/      # gossip protocol
//!    ├── policy/    # ограничения среды
//!    └── api/       # FFI интерфейс
//! ```

pub mod core;
pub mod transport;
pub mod routing;
pub mod storage;
pub mod sync;
pub mod policy;
pub mod api;
pub mod security;

// Re-exports for convenience
pub use core::*;
pub use api::*;

use std::path::Path;

/// Инициализация core: загрузка локальной идентичности и peer-store (если пути предоставлены)
pub fn init<I: AsRef<Path>, P: AsRef<Path>>(identity_path: I, peers_path: Option<P>) -> Result<(), String> {
	// Загрузка идентичности (необязательно)
	match crate::core::load_identity(identity_path) {
		Ok(Some(_)) => (),
		Ok(None) => (),
		Err(e) => return Err(format!("Failed to load identity: {}", e)),
	}

	if let Some(p) = peers_path {
		if let Err(e) = crate::core::init_peer_store(p) {
			return Err(format!("Failed to init peer store: {:?}", e));
		}
	}

	Ok(())
}