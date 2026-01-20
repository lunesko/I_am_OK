//! Core модуль - основа системы
//!
//! Включает:
//! - Идентичность (Identity)
//! - Криптографию (Crypto)
//! - Сообщения (Message)
//! - Пакеты (Packet)

pub mod identity;
pub mod crypto;
pub mod message;
pub mod packet;

pub use identity::*;
pub use crypto::*;
pub use message::*;
pub use packet::*;