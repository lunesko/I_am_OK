//! JNI wrappers for Android.

use super::*;
use jni::objects::{JByteArray, JClass, JString};
use jni::sys::{jint, jstring};
use jni::JNIEnv;
use std::ffi::{CStr, CString};

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_init(
    _env: JNIEnv,
    _class: JClass,
) -> jint {
    ya_ok_core_init() as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_initWithPath(
    mut env: JNIEnv,
    _class: JClass,
    base_dir: JString,
) -> jint {
    let base_dir: String = match env.get_string(&base_dir) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };
    let c_base = match CString::new(base_dir) {
        Ok(s) => s,
        Err(_) => return -8,
    };
    ya_ok_core_init_with_path(c_base.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_createIdentity(
    _env: JNIEnv,
    _class: JClass,
) -> jint {
    ya_ok_create_identity() as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_getIdentityId(
    env: JNIEnv,
    _class: JClass,
) -> jstring {
    let ptr = ya_ok_get_identity_id();
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let java_str = match env.new_string(c_str.to_string_lossy().as_ref()) {
        Ok(s) => s,
        Err(_) => {
            ya_ok_free_string(ptr);
            return std::ptr::null_mut();
        }
    };

    ya_ok_free_string(ptr);
    java_str.into_raw()
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_sendStatus(
    _env: JNIEnv,
    _class: JClass,
    status_type: jint,
) -> jint {
    ya_ok_send_status(status_type as i32) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_sendText(
    mut env: JNIEnv,
    _class: JClass,
    text: JString,
) -> jint {
    let text: String = match env.get_string(&text) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };

    let c_text = match CString::new(text) {
        Ok(s) => s,
        Err(_) => return -8,
    };

    ya_ok_send_text(c_text.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_sendVoice(
    env: JNIEnv,
    _class: JClass,
    data: JByteArray,
) -> jint {
    let bytes = match env.convert_byte_array(data) {
        Ok(b) => b,
        Err(_) => return -8,
    };

    ya_ok_send_voice(bytes.as_ptr(), bytes.len() as i32) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_sendStatusTo(
    mut env: JNIEnv,
    _class: JClass,
    status_type: jint,
    recipient_id: JString,
) -> jint {
    let recipient: String = match env.get_string(&recipient_id) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };

    let c_recipient = match CString::new(recipient) {
        Ok(s) => s,
        Err(_) => return -8,
    };

    ya_ok_send_status_to(status_type as i32, c_recipient.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_sendTextTo(
    mut env: JNIEnv,
    _class: JClass,
    text: JString,
    recipient_id: JString,
) -> jint {
    let text: String = match env.get_string(&text) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };
    let recipient: String = match env.get_string(&recipient_id) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };

    let c_text = match CString::new(text) {
        Ok(s) => s,
        Err(_) => return -8,
    };
    let c_recipient = match CString::new(recipient) {
        Ok(s) => s,
        Err(_) => return -8,
    };

    ya_ok_send_text_to(c_text.as_ptr(), c_recipient.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_sendVoiceTo(
    mut env: JNIEnv,
    _class: JClass,
    data: JByteArray,
    recipient_id: JString,
) -> jint {
    let bytes = match env.convert_byte_array(data) {
        Ok(b) => b,
        Err(_) => return -8,
    };
    let recipient: String = match env.get_string(&recipient_id) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };

    let c_recipient = match CString::new(recipient) {
        Ok(s) => s,
        Err(_) => return -8,
    };

    ya_ok_send_voice_to(bytes.as_ptr(), bytes.len() as i32, c_recipient.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_startListening(
    _env: JNIEnv,
    _class: JClass,
) -> jint {
    ya_ok_start_listening() as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_stopListening(
    _env: JNIEnv,
    _class: JClass,
) -> jint {
    ya_ok_stop_listening() as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_setPolicy(
    _env: JNIEnv,
    _class: JClass,
    policy_type: jint,
) -> jint {
    ya_ok_set_policy(policy_type as i32) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_getStats(
    env: JNIEnv,
    _class: JClass,
) -> jstring {
    let ptr = ya_ok_get_stats();
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let java_str = match env.new_string(c_str.to_string_lossy().as_ref()) {
        Ok(s) => s,
        Err(_) => {
            ya_ok_free_string(ptr);
            return std::ptr::null_mut();
        }
    };

    ya_ok_free_string(ptr);
    java_str.into_raw()
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_getPeerList(
    env: JNIEnv,
    _class: JClass,
) -> jstring {
    let ptr = ya_ok_peer_store_list();
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let java_str = match env.new_string(c_str.to_string_lossy().as_ref()) {
        Ok(s) => s,
        Err(_) => {
            ya_ok_free_string(ptr);
            return std::ptr::null_mut();
        }
    };

    ya_ok_free_string(ptr);
    java_str.into_raw()
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_getIdentityX25519PublicKeyHex(
    env: JNIEnv,
    _class: JClass,
) -> jstring {
    let ptr = ya_ok_get_identity_x25519_public_key_hex();
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let java_str = match env.new_string(c_str.to_string_lossy().as_ref()) {
        Ok(s) => s,
        Err(_) => {
            ya_ok_free_string(ptr);
            return std::ptr::null_mut();
        }
    };

    ya_ok_free_string(ptr);
    java_str.into_raw()
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_addPeer(
    mut env: JNIEnv,
    _class: JClass,
    peer_id: JString,
    x25519_public_key_hex: JString,
) -> jint {
    let peer_id: String = match env.get_string(&peer_id) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };
    let x_hex: String = match env.get_string(&x25519_public_key_hex) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };

    let c_peer_id = match CString::new(peer_id) {
        Ok(s) => s,
        Err(_) => return -8,
    };
    let c_x = match CString::new(x_hex) {
        Ok(s) => s,
        Err(_) => return -8,
    };

    ya_ok_add_peer(c_peer_id.as_ptr(), c_x.as_ptr()) as jint
}

// JNI wrappers for peer-store FFI
#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_peerStoreAdd(
    mut env: JNIEnv,
    _class: JClass,
    public_key_hex: JString,
    meta: JString,
) -> jint {
    let pk: String = match env.get_string(&public_key_hex) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };
    let meta_str: String = match env.get_string(&meta) {
        Ok(s) => s.into(),
        Err(_) => String::new(),
    };

    let c_pk = match CString::new(pk) { Ok(s) => s, Err(_) => return -8 };
    let c_meta = match CString::new(meta_str) { Ok(s) => s, Err(_) => return -8 };

    ya_ok_peer_store_add(c_pk.as_ptr(), c_meta.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_peerStoreList(
    env: JNIEnv,
    _class: JClass,
) -> jstring {
    let ptr = ya_ok_peer_store_list();
    if ptr.is_null() { return std::ptr::null_mut(); }
    let c_str = unsafe { CStr::from_ptr(ptr) };
    let java_str = match env.new_string(c_str.to_string_lossy().as_ref()) {
        Ok(s) => s,
        Err(_) => { ya_ok_free_string(ptr); return std::ptr::null_mut(); }
    };
    ya_ok_free_string(ptr);
    java_str.into_raw()
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_peerStoreRemove(
    mut env: JNIEnv,
    _class: JClass,
    id: JString,
) -> jint {
    let id: String = match env.get_string(&id) { Ok(s) => s.into(), Err(_) => return -8 };
    let c_id = match CString::new(id) { Ok(s) => s, Err(_) => return -8 };
    ya_ok_peer_store_remove(c_id.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_getAcksForMessage(
    mut env: JNIEnv,
    _class: JClass,
    message_id: JString,
) -> jstring {
    let msg_id: String = match env.get_string(&message_id) { 
        Ok(s) => s.into(), 
        Err(_) => return std::ptr::null_mut() 
    };
    let c_msg_id = match CString::new(msg_id) { 
        Ok(s) => s, 
        Err(_) => return std::ptr::null_mut() 
    };

    let ptr = ya_ok_get_acks_for_message(c_msg_id.as_ptr());
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let java_str = match env.new_string(c_str.to_string_lossy().as_ref()) {
        Ok(s) => s,
        Err(_) => {
            ya_ok_free_string(ptr);
            return std::ptr::null_mut();
        }
    };

    ya_ok_free_string(ptr);
    java_str.into_raw()
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_getRecentMessages(
    env: JNIEnv,
    _class: JClass,
    limit: jint,
) -> jstring {
    let ptr = ya_ok_get_recent_messages(limit as i32);
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let java_str = match env.new_string(c_str.to_string_lossy().as_ref()) {
        Ok(s) => s,
        Err(_) => {
            ya_ok_free_string(ptr);
            return std::ptr::null_mut();
        }
    };

    ya_ok_free_string(ptr);
    java_str.into_raw()
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_getRecentMessagesFull(
    env: JNIEnv,
    _class: JClass,
    limit: jint,
) -> jstring {
    let ptr = ya_ok_get_recent_messages_full(limit as i32);
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let java_str = match env.new_string(c_str.to_string_lossy().as_ref()) {
        Ok(s) => s,
        Err(_) => {
            ya_ok_free_string(ptr);
            return std::ptr::null_mut();
        }
    };

    ya_ok_free_string(ptr);
    java_str.into_raw()
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_exportPendingMessages(
    env: JNIEnv,
    _class: JClass,
    limit: jint,
) -> jstring {
    let ptr = ya_ok_export_pending_messages(limit as i32);
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let java_str = match env.new_string(c_str.to_string_lossy().as_ref()) {
        Ok(s) => s,
        Err(_) => {
            ya_ok_free_string(ptr);
            return std::ptr::null_mut();
        }
    };

    ya_ok_free_string(ptr);
    java_str.into_raw()
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_exportPendingPackets(
    env: JNIEnv,
    _class: JClass,
    limit: jint,
) -> jstring {
    let ptr = ya_ok_export_pending_packets(limit as i32);
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let java_str = match env.new_string(c_str.to_string_lossy().as_ref()) {
        Ok(s) => s,
        Err(_) => {
            ya_ok_free_string(ptr);
            return std::ptr::null_mut();
        }
    };

    ya_ok_free_string(ptr);
    java_str.into_raw()
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_importMessages(
    mut env: JNIEnv,
    _class: JClass,
    json: JString,
) -> jint {
    let json_str: String = match env.get_string(&json) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };

    let c_text = match CString::new(json_str) {
        Ok(s) => s,
        Err(_) => return -8,
    };

    ya_ok_import_messages(c_text.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_importPackets(
    mut env: JNIEnv,
    _class: JClass,
    packets_base64: JString,
) -> jint {
    let packets_str: String = match env.get_string(&packets_base64) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };

    let c_text = match CString::new(packets_str) {
        Ok(s) => s,
        Err(_) => return -8,
    };

    ya_ok_import_packets(c_text.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_importPacketsWithPeer(
    mut env: JNIEnv,
    _class: JClass,
    packets_base64: JString,
    transport_type: jint,
    address: JString,
) -> jint {
    let packets_str: String = match env.get_string(&packets_base64) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };
    let addr: String = match env.get_string(&address) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };

    let c_packets = match CString::new(packets_str) {
        Ok(s) => s,
        Err(_) => return -8,
    };
    let c_addr = match CString::new(addr) {
        Ok(s) => s,
        Err(_) => return -8,
    };

    ya_ok_import_packets_with_peer(c_packets.as_ptr(), transport_type as i32, c_addr.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_markDelivered(
    mut env: JNIEnv,
    _class: JClass,
    message_id: JString,
) -> jint {
    let id: String = match env.get_string(&message_id) {
        Ok(s) => s.into(),
        Err(_) => return -8,
    };

    let c_id = match CString::new(id) {
        Ok(s) => s,
        Err(_) => return -8,
    };

    ya_ok_mark_delivered(c_id.as_ptr()) as jint
}

#[no_mangle]
pub extern "system" fn Java_app_poruch_ya_1ok_YaOkCore_wipeLocalData(
    _env: JNIEnv,
    _class: JClass,
) -> jint {
    ya_ok_wipe_local_data() as jint
}
