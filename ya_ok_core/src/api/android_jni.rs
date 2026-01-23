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
