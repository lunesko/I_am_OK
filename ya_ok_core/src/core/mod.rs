//! Core модуль - основа системы
//!
//! Включает:
//! - Идентичность (Identity)
//! - Криптографию (Crypto)
//! - Сообщения (Message)
//! - Пакеты (Packet)

pub mod identity;
pub mod identity_store;
pub mod crypto;
pub mod message;
pub mod packet;

pub use identity::*;
pub use identity_store::*;
pub use crypto::*;
pub use message::*;
pub use packet::*;