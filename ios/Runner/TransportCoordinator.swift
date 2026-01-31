import Foundation

final class TransportCoordinator {
    static let shared = TransportCoordinator()
    private let peerService = PeerService()
    private let udpService = UdpService()
    private var timer: Timer?

    private init() {}

    func start() {
        NotificationManager.shared.requestPermission()
        peerService.onData = { [weak self] data, peerId in
            self?.handleIncoming(data: data, transportType: 0, address: peerId)
        }
        udpService.onMessage = { [weak self] data, address in
            self?.handleIncoming(data: data, transportType: 2, address: address)
        }
        peerService.start()
        udpService.start()
        scheduleSync()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        peerService.stop()
        udpService.stop()
    }

    private func scheduleSync() {
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.syncOutgoing()
        }
    }

    private func syncOutgoing() {
        let packets = CoreBridge.shared.exportPendingPackets(limit: 50)
        guard let data = packets.data(using: .utf8), !packets.isEmpty else { return }
        peerService.send(data: data)
        udpService.send(data: data)
    }

    private func handleIncoming(data: Data, transportType: Int32, address: String) {
        guard let payload = String(data: data, encoding: .utf8) else { return }
        let importedPackets = CoreBridge.shared.importPacketsWithPeer(packets: payload, transportType: transportType, address: address)
        if importedPackets > 0 {
            let recent = CoreBridge.shared.getRecentMessages(limit: 20)
            if let jsonData = try? JSONSerialization.data(withJSONObject: recent.map { $0.toDict() }),
               let json = String(data: jsonData, encoding: .utf8) {
                updateContacts(json: json)
                NotificationManager.shared.showIncoming(title: "Я ОК", body: buildNotificationBody(json: json))
            }
            return
        }

        // Fallback для старых клиентов (JSON)
        let imported = CoreBridge.shared.importMessages(json: payload)
        if imported > 0 {
            updateContacts(json: payload)
            NotificationManager.shared.showIncoming(title: "Я ОК", body: buildNotificationBody(json: payload))
        }
    }

    private func buildNotificationBody(json: String) -> String {
        guard let data = json.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let first = array.first else {
            return "Нове повідомлення"
        }
        let type = first["message_type"] as? String ?? ""
        let status = first["status"] as? String ?? ""
        let text = first["text"] as? String ?? ""
        if type == "status" && status == "ok" { return "💚 Я ОК" }
        if type == "status" && status == "busy" { return "💛 Все нормально, зайнятий" }
        if type == "status" && status == "later" { return "💙 Зателефоную пізніше" }
        if type == "voice" { return "🎙️ Голос" }
        if type == "text" && !text.isEmpty { return "💬 \(text)" }
        return "Нове повідомлення"
    }

    private func updateContacts(json: String) {
        guard let data = json.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return
        }
        var contacts = ContactStore.shared.getContacts()
        let now = Date().timeIntervalSince1970
        for item in array {
            guard let senderId = item["sender_id"] as? String else { continue }
            if let index = contacts.firstIndex(where: { $0.id == senderId }) {
                contacts[index].lastCheckin = now
            }
        }
        ContactStore.shared.saveContacts(contacts)
    }

    private func markDelivered(json: String) {
        guard let data = json.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return
        }
        array.forEach { item in
            if let id = item["id"] as? String {
                _ = CoreBridge.shared.markDelivered(messageId: id)
            }
        }
    }
}
