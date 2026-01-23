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
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio::runtime::Runtime;
use std::slice;
use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine as _;
use once_cell::sync::Lazy;

const IDENTITY_FILENAME: &str = "ya_ok_identity.json";
const DB_FILENAME: &str = "ya_ok.db";

#[cfg(target_os = "android")]
mod android_jni;

/// Глобальное состояние ядра
static mut CORE_STATE: Option<Arc<CoreState>> = None;

/// Глобальный Tokio runtime
static RUNTIME: Lazy<Runtime> = Lazy::new(|| {
    Runtime::new().expect("Failed to create tokio runtime")
});

/// Состояние ядра
pub struct CoreState {
    identity: Arc<RwLock<Option<Identity>>>,
    storage: Storage,
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
        let storage = Storage::new(&paths.storage_db)?;
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

/// Инициализация ядра
#[no_mangle]
pub extern "C" fn ya_ok_core_init() -> c_int {
    // Tokio runtime уже инициализирован через Lazy
    // Просто убеждаемся, что он доступен
    let _handle = RUNTIME.handle();

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

/// Инициализация ядра с указанием директории данных
#[no_mangle]
pub extern "C" fn ya_ok_core_init_with_path(base_dir: *const c_char) -> c_int {
    let c_str = unsafe {
        if base_dir.is_null() {
            return -7; // NULL_POINTER
        }
        CStr::from_ptr(base_dir)
    };

    let base = match c_str.to_str() {
        Ok(s) if !s.is_empty() => s,
        _ => return -8, // INVALID_UTF8_OR_EMPTY
    };

    let base_path = Path::new(base);
    match CoreState::new_with_base(base_path) {
        Ok(state) => {
            unsafe {
                CORE_STATE = Some(Arc::new(state));
            }
            0
        }
        Err(_) => -1,
    }
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
    state.storage.store_message(&message)?;
    
    // Получаем список известных пиров через router
    let router = &state.router;
    let handle = RUNTIME.handle();
    
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

fn handle_incoming_packet_internal(
    state: &Arc<CoreState>,
    bytes: &[u8],
    peer_info: Option<(TransportType, String)>,
) -> c_int {
    // Десериализуем Packet из CBOR
    let packet = match Packet::from_bytes(bytes) {
        Ok(p) => p,
        Err(_) => return -9, // DESERIALIZATION_ERROR
    };

    // Получаем identity получателя
    let identity_lock = state.identity.try_read().unwrap();
    let receiver_identity = match &*identity_lock {
        Some(id) => id,
        None => return -2, // NO_IDENTITY
    };

    let handle = RUNTIME.handle();

    // Если есть информация о пиру, обновляем known_peers
    if let Some((transport_type, address)) = peer_info {
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
    }

    // Пытаемся расшифровать
    let message_result = packet.decrypt(receiver_identity);

    // Обрабатываем пакет через router
    let routing_result = handle.block_on(async { state.router.handle_packet(packet.clone()).await });

    match routing_result {
        Ok(_) => {
            // Если удалось расшифровать, обрабатываем сообщение
            if let Ok(message) = message_result {
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
                    let _ = state.storage.store_message(&message);
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
    let storage_stats = state.storage.get_stats().unwrap_or_default();
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
    let pending = match state.storage.get_pending_messages() {
        Ok(messages) => messages,
        Err(_) => Vec::new(),
    };

    let identity_lock = state.identity.try_read().unwrap();
    let identity = match &*identity_lock {
        Some(id) => id,
        None => return std::ptr::null_mut(),
    };

    // Создаем пакеты для каждого сообщения
    let mut packets = Vec::new();
    for stored in pending.into_iter().take(limit) {
        if let Ok(message) = serde_json::from_slice::<Message>(&stored.message_data) {
            // Для каждого известного пира создаем отдельный Packet
            // Пока что используем свой ключ (временное решение)
            if let Some(receiver_key) = identity.x25519_public_bytes() {
                if let Ok(packet) = Packet::from_message(&message, identity, &receiver_key) {
                    if let Ok(packet_bytes) = packet.to_bytes() {
                        packets.push(packet_bytes);
                    }
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
    let pending = match state.storage.get_pending_messages() {
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
            if state.storage.store_message_with_delivered(&message, true).is_ok() {
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

    match state.storage.mark_delivered(id) {
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
    let messages = match state.storage.get_recent_messages(limit) {
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
    let messages = match state.storage.get_recent_messages(limit) {
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

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Invalid parameters")]
    InvalidParameters,

    #[error("Packet error: {0}")]
    PacketError(#[from] crate::core::PacketError),
}