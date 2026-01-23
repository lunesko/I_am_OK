import Foundation

@_silgen_name("ya_ok_core_init") private func ya_ok_core_init() -> Int32
@_silgen_name("ya_ok_core_init_with_path") private func ya_ok_core_init_with_path(_ baseDir: UnsafePointer<CChar>) -> Int32
@_silgen_name("ya_ok_create_identity") private func ya_ok_create_identity() -> Int32
@_silgen_name("ya_ok_get_identity_id") private func ya_ok_get_identity_id() -> UnsafeMutablePointer<CChar>?
@_silgen_name("ya_ok_free_string") private func ya_ok_free_string(_ ptr: UnsafeMutablePointer<CChar>?)
@_silgen_name("ya_ok_send_status") private func ya_ok_send_status(_ status: Int32) -> Int32
@_silgen_name("ya_ok_send_text") private func ya_ok_send_text(_ text: UnsafePointer<CChar>) -> Int32
@_silgen_name("ya_ok_send_voice") private func ya_ok_send_voice(_ data: UnsafePointer<UInt8>?, _ len: Int32) -> Int32
@_silgen_name("ya_ok_get_recent_messages") private func ya_ok_get_recent_messages(_ limit: Int32) -> UnsafeMutablePointer<CChar>?
@_silgen_name("ya_ok_get_recent_messages_full") private func ya_ok_get_recent_messages_full(_ limit: Int32) -> UnsafeMutablePointer<CChar>?
@_silgen_name("ya_ok_export_pending_packets") private func ya_ok_export_pending_packets(_ limit: Int32) -> UnsafeMutablePointer<CChar>?
@_silgen_name("ya_ok_export_pending_messages") private func ya_ok_export_pending_messages(_ limit: Int32) -> UnsafeMutablePointer<CChar>?
@_silgen_name("ya_ok_import_packets") private func ya_ok_import_packets(_ json: UnsafePointer<CChar>) -> Int32
@_silgen_name("ya_ok_import_packets_with_peer") private func ya_ok_import_packets_with_peer(_ json: UnsafePointer<CChar>, _ transport: Int32, _ address: UnsafePointer<CChar>) -> Int32
@_silgen_name("ya_ok_import_messages") private func ya_ok_import_messages(_ json: UnsafePointer<CChar>) -> Int32
@_silgen_name("ya_ok_mark_delivered") private func ya_ok_mark_delivered(_ messageId: UnsafePointer<CChar>) -> Int32

final class CoreBridge {
    static let shared = CoreBridge()
    private init() {}

    @discardableResult
    func initialize() -> Int32 {
        if let baseUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let _ = try? FileManager.default.createDirectory(at: baseUrl, withIntermediateDirectories: true)
            return baseUrl.path.withCString { cString in
                ya_ok_core_init_with_path(cString)
            }
        }
        return ya_ok_core_init()
    }

    func getIdentityId() -> String? {
        guard let ptr = ya_ok_get_identity_id() else { return nil }
        let id = String(cString: ptr)
        ya_ok_free_string(ptr)
        return id
    }

    func ensureIdentity() -> Bool {
        if getIdentityId() != nil { return true }
        return ya_ok_create_identity() == 0
    }

    func sendStatus(_ status: Int32) -> Int32 {
        ya_ok_send_status(status)
    }

    func sendText(_ text: String) -> Int32 {
        return text.withCString { cString in
            ya_ok_send_text(cString)
        }
    }

    func sendVoice(_ data: Data) -> Int32 {
        return data.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return -7
            }
            return ya_ok_send_voice(base, Int32(buffer.count))
        }
    }

    func getRecentMessages(limit: Int = 50) -> [MessageSummary] {
        guard let ptr = ya_ok_get_recent_messages(Int32(limit)) else { return [] }
        let json = String(cString: ptr)
        ya_ok_free_string(ptr)
        guard let data = json.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return raw.compactMap { MessageSummary.from(dict: $0) }
    }

    func getRecentMessagesFull(limit: Int = 50) -> [MessageSummary] {
        guard let ptr = ya_ok_get_recent_messages_full(Int32(limit)) else { return [] }
        let json = String(cString: ptr)
        ya_ok_free_string(ptr)
        guard let data = json.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return raw.compactMap { MessageSummary.from(dict: $0) }
    }

    func exportPendingMessages(limit: Int = 50) -> String {
        guard let ptr = ya_ok_export_pending_messages(Int32(limit)) else { return "[]" }
        let json = String(cString: ptr)
        ya_ok_free_string(ptr)
        return json
    }

    func exportPendingPackets(limit: Int = 50) -> String {
        guard let ptr = ya_ok_export_pending_packets(Int32(limit)) else { return "" }
        let data = String(cString: ptr)
        ya_ok_free_string(ptr)
        return data
    }

    func importPackets(packets: String) -> Int32 {
        return packets.withCString { cString in
            ya_ok_import_packets(cString)
        }
    }

    func importPacketsWithPeer(packets: String, transportType: Int32, address: String) -> Int32 {
        return packets.withCString { packetsCString in
            address.withCString { addrCString in
                ya_ok_import_packets_with_peer(packetsCString, transportType, addrCString)
            }
        }
    }

    func importMessages(json: String) -> Int32 {
        return json.withCString { cString in
            ya_ok_import_messages(cString)
        }
    }

    func markDelivered(messageId: String) -> Int32 {
        return messageId.withCString { cString in
            ya_ok_mark_delivered(cString)
        }
    }
}

struct MessageSummary {
    let id: String
    let senderId: String
    let timestamp: String
    let messageType: String
    let status: String?
    let text: String?
    let hasVoice: Bool
    let voiceBase64: String?

    static func from(dict: [String: Any]) -> MessageSummary? {
        guard let id = dict["id"] as? String,
              let senderId = dict["sender_id"] as? String,
              let timestamp = dict["timestamp"] as? String,
              let messageType = dict["message_type"] as? String else {
            return nil
        }
        let status = dict["status"] as? String
        let text = dict["text"] as? String
        let hasVoice = dict["has_voice"] as? Bool ?? false
        let voiceBase64 = dict["voice_base64"] as? String
        return MessageSummary(
            id: id,
            senderId: senderId,
            timestamp: timestamp,
            messageType: messageType,
            status: status,
            text: text,
            hasVoice: hasVoice,
            voiceBase64: voiceBase64
        )
    }

    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "sender_id": senderId,
            "timestamp": timestamp,
            "message_type": messageType,
            "has_voice": hasVoice
        ]
        if let status = status { dict["status"] = status }
        if let text = text { dict["text"] = text }
        if let voiceBase64 = voiceBase64 { dict["voice_base64"] = voiceBase64 }
        return dict
    }
}
