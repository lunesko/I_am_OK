//! API - FFI интерфейс для мобильных платформ
//!
//! Предоставляет C-compatible интерфейс для:
//! - Kotlin (Android)
//! - Swift (iOS)

use crate::core::{Identity, Message, StatusType, MessagePayload};
use crate::storage::Storage;
use crate::transport::TransportManager;
use crate::routing::{DtnRouter, Router};
use crate::policy::{PolicyManager, Policy};
use crate::sync::{Gossip, GossipProtocol};
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::sync::Arc;
use tokio::sync::RwLock;

/// Глобальное состояние ядра
static mut CORE_STATE: Option<Arc<CoreState>> = None;

/// Состояние ядра
pub struct CoreState {
    identity: RwLock<Option<Identity>>,
    storage: Storage,
    transport_manager: TransportManager,
    router: DtnRouter,
    policy_manager: RwLock<PolicyManager>,
    gossip: Gossip,
}

impl CoreState {
    fn new() -> Result<Self, ApiError> {
        let storage = Storage::new("ya_ok.db")?;
        let transport_manager = TransportManager::new();
        let router = DtnRouter::new(storage.clone(), transport_manager.clone());
        let gossip = Gossip::new(storage.clone(), transport_manager.clone());

        Ok(Self {
            identity: RwLock::new(None),
            storage,
            transport_manager,
            router,
            policy_manager: RwLock::new(PolicyManager::new()),
            gossip,
        })
    }
}

/// Инициализация ядра
#[no_mangle]
pub extern "C" fn ya_ok_core_init() -> c_int {
    // Инициализируем tokio runtime если нужно
    // TODO: инициализация async runtime

    match CoreState::new() {
        Ok(state) => {
            unsafe {
                CORE_STATE = Some(Arc::new(state));
            }
            0 // SUCCESS
        }
        Err(_) => -1, // ERROR
    }
}

/// Создать новую идентичность
#[no_mangle]
pub extern "C" fn ya_ok_create_identity() -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    let identity = Identity::new();
    let mut identity_lock = state.identity.try_write().unwrap();
    *identity_lock = Some(identity);

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

    // Сохраняем сообщение
    if let Err(_) = state.storage.store_message(&message) {
        return -5; // STORAGE_ERROR
    }

    // Отправляем через роутер (flooding)
    let packet = match Packet::from_message(&message, identity, &[]) {
        Ok(p) => p,
        Err(_) => return -6, // PACKET_ERROR
    };

    // TODO: асинхронная отправка
    // state.router.flood_packet(packet).await?;

    0 // SUCCESS
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

    // Сохраняем и отправляем аналогично статусу
    if let Err(_) = state.storage.store_message(&message) {
        return -5;
    }

    0 // SUCCESS
}

/// Начать прослушивание входящих сообщений
#[no_mangle]
pub extern "C" fn ya_ok_start_listening() -> c_int {
    let state = match get_core_state() {
        Ok(state) => state,
        Err(_) => return -1,
    };

    // TODO: запустить фоновые задачи для прослушивания
    // state.transport_manager.start_listening(...)

    0 // SUCCESS
}

/// Остановить прослушивание
#[no_mangle]
pub extern "C" fn ya_ok_stop_listening() -> c_int {
    let state = match get_core_state() {
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
    let storage_stats = state.storage.get_stats().unwrap_or_default();
    let routing_stats = state.router.get_stats(); // TODO: async
    let sync_stats = state.gossip.get_sync_stats(); // TODO: async

    let stats = CoreStats {
        storage: storage_stats,
        routing: routing_stats,
        sync: sync_stats,
    };

    let json = serde_json::to_string(&stats).unwrap_or_default();
    let c_string = CString::new(json).unwrap();
    c_string.into_raw()
}

/// Статистика ядра
#[derive(serde::Serialize)]
struct CoreStats {
    storage: crate::storage::StorageStats,
    routing: crate::routing::RoutingStats,
    sync: crate::sync::GossipStats,
}

/// Получить ссылку на состояние ядра
fn get_core_state() -> Result<&'static Arc<CoreState>, ApiError> {
    unsafe {
        CORE_STATE.as_ref().ok_or(ApiError::NotInitialized)
    }
}

/// Ошибки API
#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("Core not initialized")]
    NotInitialized,

    #[error("Storage error: {0}")]
    StorageError(#[from] crate::storage::StorageError),

    #[error("Invalid parameters")]
    InvalidParameters,
}