//! Core модуль - основа системы
//!
//! Включает:
//! - Идентичность (Identity)
//! - Криптографию (Crypto)
//! - Сообщения (Message)
//! - Пакеты (Packet)

pub mod identity;
pub mod identity_store;
pub mod peer_store;
pub mod crypto;
pub mod message;
pub mod packet;
pub mod ack;

#[cfg(test)]
mod crypto_tests;
#[cfg(test)]
mod identity_tests;
#[cfg(test)]
mod message_tests;
#[cfg(test)]
mod packet_tests;
#[cfg(test)]
mod ack_tests;

pub use identity::*;
pub use identity_store::*;
pub use peer_store::*;
pub use crypto::*;
pub use message::*;
pub use packet::*;
pub use ack::*;

use std::sync::{Mutex, OnceLock};
use std::path::Path;

static PEER_STORE: OnceLock<Mutex<peer_store::PeerStore>> = OnceLock::new();

/// Инициализация peer-store: загружает из файла и сохраняет в глобальном контейнере.
pub fn init_peer_store<P: AsRef<Path>>(path: P) -> Result<(), peer_store::PeerStoreError> {
	let store = peer_store::PeerStore::load_from_file(path)?;
	PEER_STORE
		.set(Mutex::new(store))
		.map_err(|_| peer_store::PeerStoreError::Io(std::io::Error::new(std::io::ErrorKind::Other, "PeerStore already initialized")))?;
	Ok(())
}

fn get_store() -> Option<&'static Mutex<peer_store::PeerStore>> {
	PEER_STORE.get()
}

/// Add peer via global store (if initialized). Returns error string if not initialized or on failure.
pub fn add_peer_global(public_key_hex: &str, meta: Option<String>) -> Result<peer_store::Peer, String> {
	let m = get_store().ok_or_else(|| "peer store not initialized".to_string())?;
	let mut guard = m.lock().map_err(|_| "mutex poisoned".to_string())?;
	guard.add_peer(public_key_hex, meta).map_err(|e| format!("peer store error: {:?}", e))
}

/// List peers from global store
pub fn list_peers_global() -> Result<Vec<peer_store::Peer>, String> {
	let m = get_store().ok_or_else(|| "peer store not initialized".to_string())?;
	let guard = m.lock().map_err(|_| "mutex poisoned".to_string())?;
	Ok(guard.list_peers())
}

/// Remove peer by id from global store
pub fn remove_peer_global(id: &str) -> Result<bool, String> {
	let m = get_store().ok_or_else(|| "peer store not initialized".to_string())?;
	let mut guard = m.lock().map_err(|_| "mutex poisoned".to_string())?;
	guard.remove_peer(id).map_err(|e| format!("peer store error: {:?}", e))
}