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

// Re-exports for convenience
pub use core::*;
pub use api::*;