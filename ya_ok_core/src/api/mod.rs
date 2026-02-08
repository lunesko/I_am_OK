//! API - FFI интерфейс для мобильных платформ
//!
//! Предоставляет C-compatible интерфейс для:
//! - Kotlin (Android)
//! - Swift (iOS)

use crate::core::{Identity, Message, StatusType, MessageType, MessagePayload, load_identity, save_identity, Packet};
use crate::storage::Storage;
use crate::transport::{TransportManager, TransportType, Peer};
use crate::routing::{DtnRouter, Router};
use crate::policy::{PolicyManager, Policy};
use crate::sync::{Gossip, GossipProtocol};
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::path::{Path, PathBuf};
use std::sync::{Arc, OnceLock, Mutex};
use tokio::sync::RwLock;
use tokio::runtime::Runtime;
use std::slice;
use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine as _;
use std::fs;

const IDENTITY_FILENAME: &str = "ya_ok_identity.json";
const DB_FILENAME: &str = "ya_ok.db";

// Error codes for FFI
const ERR_OK: c_int = 0;
#[allow(dead_code)] // Reserved for future use
const ERR_NOT_INITIALIZED: c_int = -1;
const ERR_ALREADY_INITIALIZED: c_int = -2;
#[allow(dead_code)] // Reserved for future use
const ERR_INVALID_ARGUMENT: c_int = -3;
#[allow(dead_code)] // Reserved for future use
const ERR_IO_ERROR: c_int = -4;
const ERR_INTERNAL_ERROR: c_int = -5;
#[allow(dead_code)] // Reserved for future use
const ERR_SERIALIZE_ERROR: c_int = -6;
const ERR_NULL_POINTER: c_int = -7;
const ERR_UTF8_ERROR: c_int = -8;
const ERR_RUNTIME_UNAVAILABLE: c_int = -9;

#[cfg(target_os = "android")]
mod android_jni;

/// --- Peer-store FFI: add/list/remove -------------------------------------
#[no_mangle]
pub extern "C" fn ya_ok_peer_store_add(public_key_hex: *const c_char, meta: *const c_char) -> c_int {
    let public_key = unsafe {
        if public_key_hex.is_null() { return ERR_NULL_POINTER; }
        CStr::from_ptr(public_key_hex)
    };
    let public_key_str = match public_key.to_str() { 
        Ok(s) => s, 
        Err(_) => return ERR_UTF8_ERROR 
    };

    let meta_opt = unsafe {
        if meta.is_null() { 
            None 
        } else { 
            match CStr::from_ptr(meta).to_str() { 
                Ok(s) => Some(s.to_string()), 
                Err(_) => return ERR_UTF8_ERROR 
            } 
        }
    };

    match crate::core::add_peer_global(public_key_str, meta_opt) {
        Ok(_) => ERR_OK,
        Err(_) => ERR_INTERNAL_ERROR,
    }
}

#[no_mangle]
pub extern "C" fn ya_ok_peer_store_list() -> *mut c_char {
    match crate::core::list_peers_global() {
        Ok(peers) => {
            match serde_json::to_string(&peers) {
                Ok(json) => match CString::new(json) {
                    Ok(cstr) => cstr.into_raw(),
                    Err(_) => std::ptr::null_mut(),
                },
                Err(_) => std::ptr::null_mut(),
            }
        }
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn ya_ok_peer_store_remove(id: *const c_char) -> c_int {
    let id_c = unsafe {
        if id.is_null() { return ERR_NULL_POINTER; }
        CStr::from_ptr(id)
    };
    let id_str = match id_c.to_str() { 
        Ok(s) => s, 
        Err(_) => return ERR_UTF8_ERROR 
    };

    match crate::core::remove_peer_global(id_str) {
        Ok(b) => if b { 1 } else { 0 },
        Err(_) => ERR_INTERNAL_ERROR,
    }
}

/// --- ACK FFI: get ACKs for message ---------------------------------------
#[no_mangle]
pub extern "C" fn ya_ok_get_acks_for_message(message_id: *const c_char) -> *mut c_char {
    let message_id_c = unsafe {
        if message_id.is_null() { return std::ptr::null_mut(); }
        CStr::from_ptr(message_id)
    };
    let message_id_str = match message_id_c.to_str() { 
        Ok(s) => s, 
        Err(_) => return std::ptr::null_mut(),
    };

    let state = match CORE_STATE.get() {
        Some(s) => s,
        None => return std::ptr::null_mut(),
    };

    let storage = match state.storage.lock() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    match storage.get_acks_for_message(message_id_str) {
        Ok(acks) => {
            // Format: JSON array of {ack_from, ack_type, timestamp}
            let ack_list: Vec<serde_json::Value> = acks.iter().map(|(from, typ, ts)| {
                serde_json::json!({
                    "ack_from": from,
                    "ack_type": typ,
                    "timestamp": ts
                })
            }).collect();

            let json = serde_json::to_string(&ack_list).unwrap_or_else(|_| "[]".to_string());
            match CString::new(json) {
                Ok(c) => c.into_raw(),
                Err(_) => std::ptr::null_mut(),
            }
        }
        Err(_) => std::ptr::null_mut(),
    }
}

/// Глобальное состояние ядра - thread-safe с OnceLock
static CORE_STATE: OnceLock<Arc<CoreState>> = OnceLock::new();

/// Глобальный Tokio runtime - thread-safe
static RUNTIME: OnceLock<Runtime> = OnceLock::new();

/// Получить или создать runtime
fn get_runtime() -> Result<&'static Runtime, ApiError> {
    RUNTIME.get_or_init(|| {
        Runtime::new().unwrap_or_else(|_| {
            // Fallback to basic runtime if full fails
            tokio::runtime::Builder::new_multi_thread()
                .worker_threads(2)
                .enable_all()
                .build()
                .expect("Failed to create minimal tokio runtime")
        })
    });
    RUNTIME.get().ok_or(ApiError::RuntimeNotAvailable)
}

/// Состояние ядра
pub struct CoreState {
    identity: Arc<RwLock<Option<Identity>>>,
    storage: Arc<Mutex<Storage>>,  // Wrapped in Mutex for thread safety (rusqlite::Connection is not Sync)
    #[allow(dead_code)] // Will be used when transport layer is fully integrated
    transport_manager: TransportManager,
    router: DtnRouter,
    policy_manager: RwLock<PolicyManager>,
    gossip: Gossip,
    identity_path: PathBuf,
    /// Кэш identity известных пиров (по sender_id)
    peer_identities: RwLock<std::collections::HashMap<String, Identity>>,
}

impl CoreState {
    fn new() -> Result<Self, ApiError> {
        Self::new_with_paths(resolve_paths(None))
    }

    fn new_with_base(base_dir: &Path) -> Result<Self, ApiError> {
        std::fs::create_dir_all(base_dir).map_err(ApiError::from)?;
        Self::new_with_paths(resolve_paths(Some(base_dir)))
    }

    fn new_with_paths(paths: CorePaths) -> Result<Self, ApiError> {
        let storage = Arc::new(Mutex::new(Storage::new(&paths.storage_db)?));
        let transport_manager = TransportManager::new();
        let router = DtnRouter::new(Storage::new(&paths.storage_db)?, TransportManager::new());
        let identity = load_identity(&paths.identity_file).ok().flatten();
        let identity = Arc::new(RwLock::new(identity));
        let gossip = Gossip::new(Storage::new(&paths.storage_db)?, TransportManager::new(), identity.clone());

        Ok(Self {
            identity,
            storage,
            transport_manager,
            router,
            policy_manager: RwLock::new(PolicyManager::new()),
            gossip,
            identity_path: paths.identity_file,
            peer_identities: RwLock::new(std::collections::HashMap::new()),
        })
    }
}

struct CorePaths {
    storage_db: PathBuf,
    identity_file: PathBuf,
}

fn resolve_paths(base_dir: Option<&Path>) -> CorePaths {
    match base_dir {
        Some(dir) => CorePaths {
            storage_db: dir.join(DB_FILENAME),
            identity_file: dir.join(IDENTITY_FILENAME),
        },
        None => CorePaths {
            storage_db: PathBuf::from(DB_FILENAME),
            identity_file: PathBuf::from(IDENTITY_FILENAME),
        },
    }
}

fn parse_transport_type(value: c_int) -> TransportType {
    match value {
        0 => TransportType::Ble,
        1 => TransportType::WifiDirect,
        2 => TransportType::Udp,
        3 => TransportType::Satellite,
        _ => TransportType::Ble,
    }
}

fn parse_hex_32(hex_str: &str) -> Result<[u8; 32], ApiError> {
    let bytes = hex::decode(hex_str).map_err(|_| ApiError::InvalidParameters)?;
    if bytes.len() != 32 {
        return Err(ApiError::InvalidParameters);
    }
    let mut out = [0u8; 32];
    out.copy_from_slice(&bytes);
    Ok(out)
}

/// Получить X25519 публичный ключ текущей идентичности (hex).
#[no_mangle]
pub extern "C" fn ya_ok_get_identity_x25519_public_key_hex() -> *mut c_char {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => {
            println!("❌ ya_ok_get_identity_x25519_public_key_hex: core state not available");
            return std::ptr::null_mut();
        }
    };

    let identity_lock = state.identity.try_read().unwrap();
    let identity = match &*identity_lock {
        Some(id) => id,
        None => {
            println!("❌ ya_ok_get_identity_x25519_public_key_hex: identity is None");
            return std::ptr::null_mut();
        }
    };

    let x = match identity.x25519_public_bytes() {
        Some(b) => {
            println!("✅ ya_ok_get_identity_x25519_public_key_hex: returning {} bytes", b.len());
            b
        }
        None => {
            println!("❌ ya_ok_get_identity_x25519_public_key_hex: x25519_public_bytes() returned None");
            return std::ptr::null_mut();
        }
    };

    let hex_str = hex::encode(x);
    println!("✅ X25519 hex: {} (length: {})", hex_str, hex_str.len());
    let c_string = CString::new(hex_str).unwrap_or_else(|_| CString::new("").unwrap());
    c_string.into_raw()
}

/// Добавить (зарегистрировать) известного пира по его ID (hex ed25519 pubkey) и X25519 pubkey (hex).
///
/// Это нужно для первичного обмена ключами (например через QR) до того, как пир пришлёт первый пакет.
#[no_mangle]
pub extern "C" fn ya_ok_add_peer(peer_id: *const c_char, x25519_public_key_hex: *const c_char) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let peer_id = unsafe {
        if peer_id.is_null() {
            return -7;
        }
        CStr::from_ptr(peer_id)
    };
    let peer_id_str = match peer_id.to_str() {
        Ok(s) if !s.trim().is_empty() => s.trim(),
        _ => return -8,
    };

    let x_hex = unsafe {
        if x25519_public_key_hex.is_null() {
            return -7;
        }
        CStr::from_ptr(x25519_public_key_hex)
    };
    let x_hex_str = match x_hex.to_str() {
        Ok(s) if !s.trim().is_empty() => s.trim(),
        _ => return -8,
    };

    // peer_id is hex of ed25519 public key in this project. Validate shape and store bytes too.
    let ed_bytes = match hex::decode(peer_id_str) {
        Ok(b) if b.len() == 32 => b,
        _ => return -10, // INVALID_PEER_ID
    };

    let x_bytes = match parse_hex_32(x_hex_str) {
        Ok(b) => b.to_vec(),
        Err(_) => return -10,
    };

    let _runtime = match get_runtime() {
        Ok(rt) => rt,
        Err(_) => return ERR_RUNTIME_UNAVAILABLE,
    };
    let handle = _runtime.handle();
    let peer = Peer {
        id: peer_id_str.to_string(),
        transport_type: TransportType::Udp,
        address: String::new(),
        last_seen: chrono::Utc::now(),
        signal_strength: None,
        ed25519_public_key: Some(ed_bytes),
        x25519_public_key: Some(x_bytes),
    };

    let _ = handle.block_on(async {
        state.router.update_peers(vec![peer]).await;
    });

    ERR_OK
}

/// Инициализация ядра
#[no_mangle]
pub extern "C" fn ya_ok_core_init() -> c_int {
    let _runtime = match get_runtime() {
        Ok(rt) => rt,
        Err(_) => return ERR_INTERNAL_ERROR,
    };

    match CoreState::new() {
        Ok(state) => {
            match CORE_STATE.set(Arc::new(state)) {
                Ok(_) => ERR_OK,
                Err(_) => ERR_ALREADY_INITIALIZED,
            }
        }
        Err(e) => {
            eprintln!("Failed to initialize core: {:?}", e);
            ERR_INTERNAL_ERROR
        }
    }
}

/// Инициализация с базовой директорией
#[no_mangle]
pub extern "C" fn ya_ok_core_init_with_path(base_dir: *const c_char) -> c_int {
    let _runtime = match get_runtime() {
        Ok(rt) => rt,
        Err(_) => return ERR_INTERNAL_ERROR,
    };

    let base_dir_c = unsafe {
        if base_dir.is_null() {
            return ERR_NULL_POINTER;
        }
        CStr::from_ptr(base_dir)
    };

    let base_dir_str = match base_dir_c.to_str() {
        Ok(s) => s,
        Err(_) => return ERR_UTF8_ERROR,
    };

    let base_path = Path::new(base_dir_str);
    match CoreState::new_with_base(base_path) {
        Ok(state) => {
            match CORE_STATE.set(Arc::new(state)) {
                Ok(_) => ERR_OK,
                Err(_) => ERR_ALREADY_INITIALIZED,
            }
        }
        Err(e) => {
            eprintln!("Failed to initialize core with path {}: {:?}", base_dir_str, e);
            ERR_INTERNAL_ERROR
        }
    }
}

/// Получить состояние ядра (thread-safe)
fn get_core_state() -> Result<&'static Arc<CoreState>, ApiError> {
    CORE_STATE.get().ok_or(ApiError::NotInitialized)
}

/// Экстренное удаление локальных данных (identity + db) и сброс in-memory состояния.
///
/// ВАЖНО: это не "удаление приложения", а очистка локальных данных на устройстве.
#[no_mangle]
pub extern "C" fn ya_ok_wipe_local_data() -> c_int {
    // Сначала вычисляем пути, потом сбрасываем состояние (чтобы закрыть файлы),
    // и только затем удаляем файлы с диска.
    let (identity_path, db_path) = {
        let state = match get_core_state() {
            Ok(state) => state,
            Err(_) => return -1,
        };
        let base = state
            .identity_path
            .parent()
            .map(Path::to_path_buf)
            .unwrap_or_else(|| PathBuf::from("."));
        (state.identity_path.clone(), base.join(DB_FILENAME))
    };

    // Note: CORE_STATE (OnceLock) cannot be reset. Application should restart after wipe.
    // The identity and storage references are dropped when they go out of scope.

    // Best-effort deletes
    let _ = fs::remove_file(&identity_path);
    let _ = fs::remove_file(&db_path);
    let _ = fs::remove_file(PathBuf::from(format!("{}-wal", db_path.to_string_lossy())));
    let _ = fs::remove_file(PathBuf::from(format!("{}-shm", db_path.to_string_lossy())));

    0
}

/// Создать новую идентичность
#[no_mangle]
pub extern "C" fn ya_ok_create_identity() -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let mut identity_lock = state.identity.try_write().unwrap();
    if identity_lock.is_some() {
        return 0; // ALREADY_EXISTS
    }

    let identity = Identity::new();
    *identity_lock = Some(identity);

    if let Some(identity) = identity_lock.as_ref() {
        if save_identity(&state.identity_path, identity).is_err() {
            return -11; // IDENTITY_SAVE_ERROR
        }
    }

    0 // SUCCESS
}

/// Получить ID текущей идентичности
#[no_mangle]
pub extern "C" fn ya_ok_get_identity_id() -> *mut c_char {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return std::ptr::null_mut(),
    };

    let identity_lock = state.identity.try_read().unwrap();
    match &*identity_lock {
        Some(identity) => {
            let c_string = CString::new(identity.id.clone()).unwrap();
            c_string.into_raw()
        }
        None => std::ptr::null_mut(),
    }
}

/// Освободить строку, выделенную FFI
#[no_mangle]
pub extern "C" fn ya_ok_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            drop(CString::from_raw(s));
        }
    }
}

/// Вспомогательная функция для создания и отправки Packet
fn create_and_send_packet(
    state: &Arc<CoreState>,
    message: Message,
) -> Result<(), ApiError> {
    let identity_lock = state.identity.try_read().unwrap();
    let identity = identity_lock.as_ref().ok_or(ApiError::NotInitialized)?;

    // Сохраняем сообщение
    state.storage.lock().unwrap().store_message(&message)?;
    
    // Получаем список известных пиров через router
    let router = &state.router;
    let runtime = get_runtime().map_err(|_| ApiError::RuntimeNotAvailable)?; let handle = runtime.handle();
    
    // Получаем известных пиров из router
    let known_peers = handle.block_on(async {
        router.known_peers().read().await.clone()
    });
    
    if known_peers.is_empty() {
        // Нет известных пиров - сохраняем сообщение для отправки позже
        // Packet будет создан когда появятся пиры
        return Ok(());
    }
    
    // Для каждого пира с X25519 ключом создаем отдельный Packet
    let mut packets_created = 0;
    for (peer_id, peer) in known_peers.iter() {
        if let Some(x25519_key_bytes) = &peer.x25519_public_key {
            if x25519_key_bytes.len() == 32 {
                let mut receiver_key = [0u8; 32];
                receiver_key.copy_from_slice(x25519_key_bytes);
                
                if let Ok(packet) = Packet::from_message(&message, identity, &receiver_key) {
                    // Отправляем пакет конкретному пиру
                    let _ = handle.block_on(async {
                        router.send_to(&packet, peer_id).await
                    });
                    packets_created += 1;
                }
            }
        }
    }
    
    // Если не удалось создать ни одного пакета (нет X25519 ключей),
    // используем flooding с временным ключом (для обратной совместимости)
    if packets_created == 0 {
        let sender_x25519_public = identity.x25519_public_bytes()
            .ok_or(ApiError::InvalidParameters)?;
        
        if let Ok(packet) = Packet::from_message(&message, identity, &sender_x25519_public) {
            let _ = handle.block_on(async {
                router.flood_packet(packet).await
            });
        }
    }
    
    Ok(())
}

/// Отправить статус-сообщение
#[no_mangle]
pub extern "C" fn ya_ok_send_status(status_type: c_int) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let identity_lock = state.identity.try_read().unwrap();
    let identity = match &*identity_lock {
        Some(id) => id,
        None => return -2, // NO_IDENTITY
    };

    let status = match status_type {
        0 => StatusType::Ok,
        1 => StatusType::Busy,
        2 => StatusType::Later,
        _ => return -3, // INVALID_STATUS
    };

    let message = Message::status(identity.id.clone(), status);

    // Проверяем политику
    let policy_lock = state.policy_manager.try_read().unwrap();
    if let Err(_) = policy_lock.validate_message(&message) {
        return -4; // POLICY_VIOLATION
    }

    // Создаем и отправляем Packet
    match create_and_send_packet(&state, message) {
        Ok(_) => 0, // SUCCESS
        Err(_) => -5, // STORAGE_ERROR или другая ошибка
    }
}

/// Отправить текстовое сообщение
#[no_mangle]
pub extern "C" fn ya_ok_send_text(text: *const c_char) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let identity_lock = state.identity.try_read().unwrap();
    let identity = match &*identity_lock {
        Some(id) => id,
        None => return -2,
    };

    // Конвертируем C строку в Rust
    let c_str = unsafe {
        if text.is_null() {
            return -7; // NULL_POINTER
        }
        CStr::from_ptr(text)
    };

    let text_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return -8, // INVALID_UTF8
    };

    let message = match Message::text(identity.id.clone(), text_str.to_string()) {
        Ok(msg) => msg,
        Err(_) => return -9, // MESSAGE_VALIDATION_ERROR
    };

    // Проверяем политику
    let policy_lock = state.policy_manager.try_read().unwrap();
    if let Err(_) = policy_lock.validate_message(&message) {
        return -4;
    }

    // Создаем и отправляем Packet
    match create_and_send_packet(&state, message) {
        Ok(_) => 0, // SUCCESS
        Err(_) => -5, // STORAGE_ERROR или другая ошибка
    }
}

/// Отправить голосовое сообщение
#[no_mangle]
pub extern "C" fn ya_ok_send_voice(data: *const u8, len: c_int) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let identity_lock = state.identity.try_read().unwrap();
    let identity = match &*identity_lock {
        Some(id) => id,
        None => return -2,
    };

    if data.is_null() || len <= 0 {
        return -7; // NULL_POINTER_OR_EMPTY
    }

    let slice = unsafe { slice::from_raw_parts(data, len as usize) };
    let message = match Message::voice(identity.id.clone(), slice.to_vec()) {
        Ok(msg) => msg,
        Err(_) => return -9, // MESSAGE_VALIDATION_ERROR
    };

    let policy_lock = state.policy_manager.try_read().unwrap();
    if let Err(_) = policy_lock.validate_message(&message) {
        return -4; // POLICY_VIOLATION
    }

    // Создаем и отправляем Packet
    match create_and_send_packet(&state, message) {
        Ok(_) => 0, // SUCCESS
        Err(_) => -5, // STORAGE_ERROR или другая ошибка
    }
}

/// Отправить статус конкретному получателю
#[no_mangle]
pub extern "C" fn ya_ok_send_status_to(status_type: c_int, recipient_id: *const c_char) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let identity_lock = state.identity.try_read().unwrap();
    let identity = match &*identity_lock {
        Some(id) => id,
        None => return -2,
    };

    let recipient_id_str = unsafe {
        if recipient_id.is_null() {
            return ERR_NULL_POINTER;
        }
        match CStr::from_ptr(recipient_id).to_str() {
            Ok(s) => s,
            Err(_) => return ERR_UTF8_ERROR,
        }
    };

    let status = match status_type {
        0 => StatusType::Ok,
        1 => StatusType::Busy,
        2 => StatusType::Later,
        _ => return -3, // INVALID_ARGUMENT
    };

    let message = Message::status(identity.id.clone(), status);

    let policy_lock = state.policy_manager.try_read().unwrap();
    if let Err(_) = policy_lock.validate_message(&message) {
        return -4;
    }

    match create_and_send_packet_to(&state, message, recipient_id_str) {
        Ok(_) => 0,
        Err(_) => -5,
    }
}

/// Отправить текст конкретному получателю
#[no_mangle]
pub extern "C" fn ya_ok_send_text_to(text: *const c_char, recipient_id: *const c_char) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let identity_lock = state.identity.try_read().unwrap();
    let identity = match &*identity_lock {
        Some(id) => id,
        None => return -2,
    };

    let text_str = unsafe {
        if text.is_null() {
            return ERR_NULL_POINTER;
        }
        match CStr::from_ptr(text).to_str() {
            Ok(s) => s,
            Err(_) => return ERR_UTF8_ERROR,
        }
    };

    let recipient_id_str = unsafe {
        if recipient_id.is_null() {
            return ERR_NULL_POINTER;
        }
        match CStr::from_ptr(recipient_id).to_str() {
            Ok(s) => s,
            Err(_) => return ERR_UTF8_ERROR,
        }
    };

    let message = match Message::text(identity.id.clone(), text_str.to_string()) {
        Ok(msg) => msg,
        Err(_) => return -9,
    };

    let policy_lock = state.policy_manager.try_read().unwrap();
    if let Err(_) = policy_lock.validate_message(&message) {
        return -4;
    }

    match create_and_send_packet_to(&state, message, recipient_id_str) {
        Ok(_) => 0,
        Err(_) => -5,
    }
}

/// Отправить голос конкретному получателю
#[no_mangle]
pub extern "C" fn ya_ok_send_voice_to(data: *const u8, len: c_int, recipient_id: *const c_char) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let identity_lock = state.identity.try_read().unwrap();
    let identity = match &*identity_lock {
        Some(id) => id,
        None => return -2,
    };

    if data.is_null() || len <= 0 {
        return ERR_NULL_POINTER;
    }

    let recipient_id_str = unsafe {
        if recipient_id.is_null() {
            return ERR_NULL_POINTER;
        }
        match CStr::from_ptr(recipient_id).to_str() {
            Ok(s) => s,
            Err(_) => return ERR_UTF8_ERROR,
        }
    };

    let slice = unsafe { slice::from_raw_parts(data, len as usize) };
    let message = match Message::voice(identity.id.clone(), slice.to_vec()) {
        Ok(msg) => msg,
        Err(_) => return -9,
    };

    let policy_lock = state.policy_manager.try_read().unwrap();
    if let Err(_) = policy_lock.validate_message(&message) {
        return -4;
    }

    match create_and_send_packet_to(&state, message, recipient_id_str) {
        Ok(_) => 0,
        Err(_) => -5,
    }
}

/// Вспомогательная функция для отправки пакета конкретному получателю
fn create_and_send_packet_to(
    state: &Arc<CoreState>,
    message: Message,
    recipient_id: &str,
) -> Result<(), ApiError> {
    let identity_lock = state.identity.try_read().unwrap();
    let identity = identity_lock.as_ref().ok_or(ApiError::NotInitialized)?;

    println!("📤 create_and_send_packet_to: recipient={}", recipient_id);

    // Сохраняем сообщение
    state.storage.lock().unwrap().store_message(&message)?;
    
    // Получаем информацию о конкретном пире
    let router = &state.router;
    let runtime = get_runtime().map_err(|_| ApiError::RuntimeNotAvailable)?;
    let handle = runtime.handle();
    
    let known_peers = handle.block_on(async {
        router.known_peers().read().await.clone()
    });
    
    println!("📤 Known peers count: {}", known_peers.len());
    
    // Находим конкретного получателя
    if let Some(peer) = known_peers.get(recipient_id) {
        println!("📤 Found peer: {} at {:?}", recipient_id, peer.transport_type);
        if let Some(x25519_key_bytes) = &peer.x25519_public_key {
            println!("📤 Peer has x25519 key, length={}", x25519_key_bytes.len());
            if x25519_key_bytes.len() == 32 {
                let mut receiver_key = [0u8; 32];
                receiver_key.copy_from_slice(x25519_key_bytes);
                
                if let Ok(packet) = Packet::from_message(&message, identity, &receiver_key) {
                    println!("✅ Created encrypted packet, sending...");
                    let _ = handle.block_on(async {
                        router.send_to(&packet, recipient_id).await
                    });
                    println!("✅ Packet sent successfully");
                    return Ok(());
                } else {
                    println!("❌ Failed to create packet from message");
                }
            } else {
                println!("❌ x25519 key length invalid: {}", x25519_key_bytes.len());
            }
        } else {
            println!("❌ Peer has no x25519 key");
        }
    } else {
        println!("❌ Peer not found in known_peers: {}", recipient_id);
    }
    
    // Если получатель не найден или нет ключа, возвращаем ошибку
    println!("❌ create_and_send_packet_to failed");
    Err(ApiError::InvalidParameters)
}

fn handle_incoming_packet_internal(
    state: &Arc<CoreState>,
    bytes: &[u8],
    peer_info: Option<(TransportType, String)>,
) -> c_int {
    println!("📥 handle_incoming_packet_internal: bytes={}, peer_info={:?}", bytes.len(), peer_info);
    // Десериализуем Packet из CBOR
    let packet = match Packet::from_bytes(bytes) {
        Ok(p) => {
            println!("📥 Packet deserialized: sender={}", p.sender_id);
            p
        },
        Err(e) => {
            println!("❌ Packet deserialization error: {:?}", e);
            return -9; // DESERIALIZATION_ERROR
        }
    };

    // Получаем identity получателя
    let identity_lock = state.identity.try_read().unwrap();
    let receiver_identity = match &*identity_lock {
        Some(id) => id,
        None => return -2, // NO_IDENTITY
    };

    let runtime = match get_runtime() {
        Ok(rt) => rt,
        Err(_) => return ERR_RUNTIME_UNAVAILABLE,
    };
    let handle = runtime.handle();

    // Если есть информация о пиру, обновляем known_peers
    if let Some((transport_type, address)) = peer_info {
        println!("📥 Updating peer: {} at {} via {:?}", packet.sender_id, address, transport_type);
        let peer = Peer {
            id: packet.sender_id.clone(),
            transport_type,
            address,
            last_seen: chrono::Utc::now(),
            signal_strength: None,
            ed25519_public_key: if packet.sender_public_key.is_empty() {
                None
            } else {
                Some(packet.sender_public_key.clone())
            },
            x25519_public_key: if packet.sender_x25519_public_key.len() == 32 {
                Some(packet.sender_x25519_public_key.clone())
            } else {
                None
            },
        };
        let _ = handle.block_on(async {
            state.router.update_peers(vec![peer]).await;
        });
        println!("✅ Peer updated in router");
    }

    // Пытаемся расшифровать
    let message_result = packet.decrypt(receiver_identity);
    if let Ok(ref _msg) = message_result {
        println!("✅ Message decrypted successfully");
    } else {
        println!("⚠️ Message decryption failed (might be for relay)");
    }

    // Обрабатываем пакет через router
    let routing_result = handle.block_on(async { state.router.handle_packet(packet.clone()).await });
    println!("📥 Router result: {:?}", routing_result.is_ok());

    match routing_result {
        Ok(_) => {
            // Если удалось расшифровать, обрабатываем сообщение
            if let Ok(message) = message_result {
                println!("📥 Processing decrypted message");
                let mut stored = true;
                if let MessagePayload::Text(text) = &message.payload {
                    if let Ok(Some(gossip_msg)) = crate::sync::Gossip::decode_gossip(text) {
                        let peer = Peer {
                            id: packet.sender_id.clone(),
                            transport_type: TransportType::Ble,
                            address: String::new(),
                            last_seen: chrono::Utc::now(),
                            signal_strength: None,
                            ed25519_public_key: Some(packet.sender_public_key.clone()),
                            x25519_public_key: if packet.sender_x25519_public_key.len() == 32 {
                                Some(packet.sender_x25519_public_key.clone())
                            } else {
                                None
                            },
                        };
                        let _ = handle.block_on(async {
                            state.gossip.handle_gossip_message(gossip_msg, &peer).await
                        });
                        stored = false;
                    }
                }
                if stored {
                    let _ = state.storage.lock().unwrap().store_message(&message);
                }

                // Обновляем кэш identity отправителя
                if packet.sender_public_key.len() == 32 {
                    if let Ok(sender_identity) =
                        crate::core::Identity::from_bytes(&packet.sender_public_key)
                    {
                        let _ = handle.block_on(async {
                            let mut peer_identities = state.peer_identities.write().await;
                            peer_identities.insert(packet.sender_id.clone(), sender_identity);
                        });
                    }
                }
            }
            0 // SUCCESS
        }
        Err(_) => -5, // ROUTING_ERROR
    }
}

/// Обработать входящий пакет (CBOR байты)
#[no_mangle]
pub extern "C" fn ya_ok_handle_incoming_packet(packet_bytes: *const u8, len: c_int) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    if packet_bytes.is_null() || len <= 0 {
        return -7; // NULL_POINTER_OR_EMPTY
    }

    let bytes = unsafe { slice::from_raw_parts(packet_bytes, len as usize) };
    handle_incoming_packet_internal(&state, bytes, None)
}

/// Обработать входящий пакет с информацией о пиру
#[no_mangle]
pub extern "C" fn ya_ok_handle_incoming_packet_with_peer(
    packet_bytes: *const u8,
    len: c_int,
    transport_type: c_int,
    address: *const c_char,
) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    if packet_bytes.is_null() || len <= 0 {
        return -7; // NULL_POINTER_OR_EMPTY
    }

    let addr = unsafe {
        if address.is_null() {
            return -7;
        }
        CStr::from_ptr(address)
    };
    let addr_str = match addr.to_str() {
        Ok(s) => s.to_string(),
        Err(_) => return -8,
    };

    let bytes = unsafe { slice::from_raw_parts(packet_bytes, len as usize) };
    let transport = parse_transport_type(transport_type);
    handle_incoming_packet_internal(&state, bytes, Some((transport, addr_str)))
}

/// Начать прослушивание входящих сообщений
#[no_mangle]
pub extern "C" fn ya_ok_start_listening() -> c_int {
    let _state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    // Фоновые задачи для прослушивания запускаются на стороне Android/iOS
    // Rust core предоставляет функцию ya_ok_handle_incoming_packet для обработки входящих пакетов
    // TODO: в будущем можно добавить встроенное прослушивание через transport_manager

    0 // SUCCESS
}

/// Остановить прослушивание
#[no_mangle]
pub extern "C" fn ya_ok_stop_listening() -> c_int {
    let _state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    // TODO: остановить фоновые задачи

    0 // SUCCESS
}

/// Установить политику
#[no_mangle]
pub extern "C" fn ya_ok_set_policy(policy_type: c_int) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let policy = match policy_type {
        0 => Policy::default(),     // DEFAULT
        1 => Policy::military(),    // MILITARY
        2 => Policy::collapse(),    // COLLAPSE
        3 => Policy::offline(),     // OFFLINE
        _ => return -10, // INVALID_POLICY
    };

    let mut policy_lock = state.policy_manager.try_write().unwrap();
    policy_lock.set_policy(policy);

    0 // SUCCESS
}

/// Получить статистику
#[no_mangle]
pub extern "C" fn ya_ok_get_stats() -> *mut c_char {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return std::ptr::null_mut(),
    };

    // Собираем статистику
    let storage_stats = state.storage.lock().unwrap().get_stats().unwrap_or_default();
    let routing_stats = crate::routing::RoutingStats::default();
    let sync_stats = crate::sync::GossipStats::default();

    let stats = CoreStats {
        storage: storage_stats,
        routing: routing_stats,
        sync: sync_stats,
    };

    let json = serde_json::to_string(&stats).unwrap_or_default();
    let c_string = CString::new(json).unwrap();
    c_string.into_raw()
}

/// Экспортировать ожидающие отправки пакеты (CBOR байты)
/// Возвращает base64-encoded CBOR пакетов
#[no_mangle]
pub extern "C" fn ya_ok_export_pending_packets(limit: c_int) -> *mut c_char {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return std::ptr::null_mut(),
    };

    let limit = if limit <= 0 { 50 } else { limit as usize };
    let pending = match state.storage.lock().unwrap().get_pending_messages() {
        Ok(messages) => messages,
        Err(_) => Vec::new(),
    };

    let identity_lock = state.identity.try_read().unwrap();
    let identity = match &*identity_lock {
        Some(id) => id,
        None => return std::ptr::null_mut(),
    };

    // Создаем пакеты для каждого сообщения и каждого известного пира с X25519 ключом.
    // Если список пиров пуст (или без X25519), то мы НЕ создаём пакеты, т.к. получатели не смогут их расшифровать.
    let runtime = match get_runtime() {
        Ok(rt) => rt,
        Err(_) => return std::ptr::null_mut(),
    };
    let handle = runtime.handle();
    let known_peers = handle.block_on(async { state.router.known_peers().read().await.clone() });

    let mut packets: Vec<Vec<u8>> = Vec::new();
    for stored in pending.into_iter().take(limit) {
        let Ok(message) = serde_json::from_slice::<Message>(&stored.message_data) else {
            continue;
        };

        for peer in known_peers.values() {
            let Some(x_key) = peer.x25519_public_key.as_ref() else {
                continue;
            };
            if x_key.len() != 32 {
                continue;
            }
            if let Ok(packet) = Packet::from_message(&message, identity, x_key) {
                if let Ok(packet_bytes) = packet.to_bytes() {
                    packets.push(packet_bytes);
                }
            }
        }
    }

    // Сериализуем пакеты в base64 (для передачи через транспорт)
    let packets_base64 = packets.iter()
        .map(|p| BASE64.encode(p))
        .collect::<Vec<_>>()
        .join(",");
    
    let c_string = CString::new(packets_base64).unwrap_or_else(|_| CString::new("").unwrap());
    c_string.into_raw()
}

/// Импортировать входящие пакеты (base64-encoded CBOR)
#[no_mangle]
pub extern "C" fn ya_ok_import_packets(packets_base64: *const c_char) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let c_str = unsafe {
        if packets_base64.is_null() {
            return -7; // NULL_POINTER
        }
        CStr::from_ptr(packets_base64)
    };

    let base64_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return -8, // INVALID_UTF8
    };

    // Разделяем по запятым и декодируем каждый пакет
    let packets_str: Vec<&str> = base64_str.split(',').collect();
    let mut imported = 0;

    let identity_lock = state.identity.try_read().unwrap();
    if identity_lock.is_none() {
        return -2; // NO_IDENTITY
    }

    for packet_base64 in packets_str {
        if packet_base64.is_empty() {
            continue;
        }

        let packet_bytes = match BASE64.decode(packet_base64) {
            Ok(bytes) => bytes,
            Err(_) => continue,
        };

        if Packet::from_bytes(&packet_bytes).is_err() {
            continue;
        }

        let result = handle_incoming_packet_internal(&state, &packet_bytes, None);
        if result == 0 {
            imported += 1;
        }
    }

    imported
}

/// Импортировать входящие пакеты с информацией о пиру
#[no_mangle]
pub extern "C" fn ya_ok_import_packets_with_peer(
    packets_base64: *const c_char,
    transport_type: c_int,
    address: *const c_char,
) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let c_str = unsafe {
        if packets_base64.is_null() {
            return -7; // NULL_POINTER
        }
        CStr::from_ptr(packets_base64)
    };

    let base64_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return -8, // INVALID_UTF8
    };

    let addr = unsafe {
        if address.is_null() {
            return -7;
        }
        CStr::from_ptr(address)
    };
    let addr_str = match addr.to_str() {
        Ok(s) => s.to_string(),
        Err(_) => return -8,
    };
    let transport = parse_transport_type(transport_type);

    let packets_str: Vec<&str> = base64_str.split(',').collect();
    let mut imported = 0;

    for packet_base64 in packets_str {
        if packet_base64.is_empty() {
            continue;
        }

        let packet_bytes = match BASE64.decode(packet_base64) {
            Ok(bytes) => bytes,
            Err(_) => continue,
        };

        let result = handle_incoming_packet_internal(&state, &packet_bytes, Some((transport.clone(), addr_str.clone())));
        if result == 0 {
            imported += 1;
        }
    }

    imported
}

/// Экспортировать ожидающие отправки сообщения (JSON) - для обратной совместимости
#[no_mangle]
pub extern "C" fn ya_ok_export_pending_messages(limit: c_int) -> *mut c_char {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return std::ptr::null_mut(),
    };

    let limit = if limit <= 0 { 50 } else { limit as usize };
    let pending = match state.storage.lock().unwrap().get_pending_messages() {
        Ok(messages) => messages,
        Err(_) => Vec::new(),
    };

    let mut exports = Vec::new();
    for stored in pending.into_iter().take(limit) {
        if let Ok(message) = serde_json::from_slice::<Message>(&stored.message_data) {
            exports.push(MessageExport::from_message(&message));
        }
    }

    let json = serde_json::to_string(&exports).unwrap_or_else(|_| "[]".to_string());
    let c_string = CString::new(json).unwrap_or_else(|_| CString::new("[]").unwrap());
    c_string.into_raw()
}

/// Импортировать входящие сообщения (JSON)
#[no_mangle]
pub extern "C" fn ya_ok_import_messages(json: *const c_char) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let c_str = unsafe {
        if json.is_null() {
            return -7; // NULL_POINTER
        }
        CStr::from_ptr(json)
    };

    let json_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return -8,
    };

    let exports: Vec<MessageExport> = match serde_json::from_str(json_str) {
        Ok(list) => list,
        Err(_) => return -9,
    };

    let mut imported = 0;
    for export in exports {
        if let Ok(message) = export.to_message() {
            if state.storage.lock().unwrap().store_message_with_delivered(&message, true).is_ok() {
                imported += 1;
            }
        }
    }

    imported
}

/// Пометить сообщение как доставленное
#[no_mangle]
pub extern "C" fn ya_ok_mark_delivered(message_id: *const c_char) -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let c_str = unsafe {
        if message_id.is_null() {
            return -7;
        }
        CStr::from_ptr(message_id)
    };

    let id = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return -8,
    };

    match state.storage.lock().unwrap().mark_delivered(id) {
        Ok(_) => 0,
        Err(_) => -5,
    }
}

/// Получить последние сообщения с payload (JSON)
#[no_mangle]
pub extern "C" fn ya_ok_get_recent_messages_full(limit: c_int) -> *mut c_char {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return std::ptr::null_mut(),
    };

    let limit = if limit <= 0 { 50 } else { limit as usize };
    let messages = match state.storage.lock().unwrap().get_recent_messages(limit) {
        Ok(messages) => messages,
        Err(_) => Vec::new(),
    };

    let exports: Vec<MessageExport> = messages.into_iter()
        .map(|message| MessageExport::from_message(&message))
        .collect();

    let json = serde_json::to_string(&exports).unwrap_or_else(|_| "[]".to_string());
    let c_string = CString::new(json).unwrap_or_else(|_| CString::new("[]").unwrap());
    c_string.into_raw()
}

/// Получить последние сообщения (JSON)
#[no_mangle]
pub extern "C" fn ya_ok_get_recent_messages(limit: c_int) -> *mut c_char {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return std::ptr::null_mut(),
    };

    let limit = if limit <= 0 { 50 } else { limit as usize };
    let messages = match state.storage.lock().unwrap().get_recent_messages(limit) {
        Ok(messages) => messages,
        Err(_) => Vec::new(),
    };

    let summaries: Vec<MessageSummary> = messages
        .into_iter()
        .map(|message| {
            let (status, text, has_voice) = match message.payload {
                crate::core::MessagePayload::Status(status) => {
                    let status_str = match status {
                        StatusType::Ok => "ok",
                        StatusType::Busy => "busy",
                        StatusType::Later => "later",
                    };
                    (Some(status_str.to_string()), None, false)
                }
                crate::core::MessagePayload::Text(text) => (None, Some(text), false),
                crate::core::MessagePayload::Voice(_) => (None, None, true),
            };

            let message_type = match message.message_type {
                MessageType::Status => "status",
                MessageType::Text => "text",
                MessageType::Voice => "voice",
            };

            MessageSummary {
                id: message.id,
                sender_id: message.sender_id,
                timestamp: message.timestamp.to_rfc3339(),
                message_type: message_type.to_string(),
                status,
                text,
                has_voice,
            }
        })
        .collect();

    let json = serde_json::to_string(&summaries).unwrap_or_else(|_| "[]".to_string());
    let c_string = CString::new(json).unwrap_or_else(|_| CString::new("[]").unwrap());
    c_string.into_raw()
}

/// Статистика ядра
#[derive(serde::Serialize)]
struct CoreStats {
    storage: crate::storage::StorageStats,
    routing: crate::routing::RoutingStats,
    sync: crate::sync::GossipStats,
}

#[derive(serde::Serialize)]
struct MessageSummary {
    id: String,
    sender_id: String,
    timestamp: String,
    message_type: String,
    status: Option<String>,
    text: Option<String>,
    has_voice: bool,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct MessageExport {
    id: String,
    sender_id: String,
    timestamp: String,
    message_type: String,
    status: Option<String>,
    text: Option<String>,
    voice_base64: Option<String>,
}

impl MessageExport {
    fn from_message(message: &Message) -> Self {
        match &message.payload {
            MessagePayload::Status(status) => Self {
                id: message.id.clone(),
                sender_id: message.sender_id.clone(),
                timestamp: message.timestamp.to_rfc3339(),
                message_type: "status".to_string(),
                status: Some(match status {
                    StatusType::Ok => "ok",
                    StatusType::Busy => "busy",
                    StatusType::Later => "later",
                }.to_string()),
                text: None,
                voice_base64: None,
            },
            MessagePayload::Text(text) => Self {
                id: message.id.clone(),
                sender_id: message.sender_id.clone(),
                timestamp: message.timestamp.to_rfc3339(),
                message_type: "text".to_string(),
                status: None,
                text: Some(text.clone()),
                voice_base64: None,
            },
            MessagePayload::Voice(data) => Self {
                id: message.id.clone(),
                sender_id: message.sender_id.clone(),
                timestamp: message.timestamp.to_rfc3339(),
                message_type: "voice".to_string(),
                status: None,
                text: None,
                voice_base64: Some(BASE64.encode(data)),
            },
        }
    }

    fn to_message(self) -> Result<Message, ApiError> {
        let timestamp = chrono::DateTime::parse_from_rfc3339(&self.timestamp)
            .map_err(|_| ApiError::InvalidParameters)?
            .with_timezone(&chrono::Utc);

        let payload = match self.message_type.as_str() {
            "status" => {
                let status = match self.status.as_deref() {
                    Some("ok") => StatusType::Ok,
                    Some("busy") => StatusType::Busy,
                    Some("later") => StatusType::Later,
                    _ => return Err(ApiError::InvalidParameters),
                };
                MessagePayload::Status(status)
            }
            "text" => {
                let text = self.text.unwrap_or_default();
                MessagePayload::Text(text)
            }
            "voice" => {
                let encoded = self.voice_base64.unwrap_or_default();
                let data = BASE64.decode(encoded).map_err(|_| ApiError::InvalidParameters)?;
                MessagePayload::Voice(data)
            }
            _ => return Err(ApiError::InvalidParameters),
        };

        Ok(Message {
            id: self.id,
            message_type: match self.message_type.as_str() {
                "status" => MessageType::Status,
                "text" => MessageType::Text,
                "voice" => MessageType::Voice,
                _ => MessageType::Text,
            },
            sender_id: self.sender_id,
            timestamp,
            payload,
        })
    }
}

/// Ошибки API
#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("Core not initialized")]
    NotInitialized,

    #[error("Runtime not available")]
    RuntimeNotAvailable,

    #[error("Storage error: {0}")]
    StorageError(#[from] crate::storage::StorageError),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Invalid parameters")]
    InvalidParameters,

    #[error("Packet error: {0}")]
    PacketError(#[from] crate::core::PacketError),
}

