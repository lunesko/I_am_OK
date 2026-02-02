//
//  DebugViewController.swift
//  Ya OK
//
//  Debug screen showing real-time diagnostics
//

import UIKit

class DebugViewController: UIViewController {
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private var updateTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Debug Info"
        view.backgroundColor = .systemBackground
        
        // Setup UI
        view.addSubview(scrollView)
        scrollView.addSubview(statsLabel)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            statsLabel.topAnchor.constraint(equalTo: scrollView.topAnchor),
            statsLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            statsLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            statsLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            statsLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Start periodic updates
        updateStats()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateStats() {
        var stats = ""
        
        // Header
        stats += "=== Ya OK Debug Info ===\n\n"
        
        // Core Status
        stats += "CORE:\n"
        if let identityId = ya_ok_get_identity_id() {
            let idString = String(cString: identityId)
            let shortId = String(idString.prefix(16))
            stats += "  Identity: \\(shortId)...\n"
            ya_ok_free_string(identityId)
        }
        stats += "  iOS: \\(UIDevice.current.systemVersion)\n"
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            stats += "  Build: \\(appVersion)\n"
        }
        stats += "\n"
        
        // Message Stats
        stats += "MESSAGES:\n"
        if let recentPtr = ya_ok_get_recent_messages(100) {
            let recentJson = String(cString: recentPtr)
            ya_ok_free_string(recentPtr)
            
            if let data = recentJson.data(using: .utf8),
               let messages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                stats += "  Recent: \\(messages.count)\n"
                
                // Count by type
                let statusCount = messages.filter { ($0["type"] as? String) == "status" }.count
                let textCount = messages.filter { ($0["type"] as? String) == "text" }.count
                let voiceCount = messages.filter { ($0["type"] as? String) == "voice" }.count
                
                stats += "  Status: \\(statusCount)\n"
                stats += "  Text: \\(textCount)\n"
                stats += "  Voice: \\(voiceCount)\n"
            }
        }
        stats += "\n"
        
        // Peer Stats
        stats += "PEERS:\n"
        if let peersPtr = ya_ok_peer_store_list() {
            let peersJson = String(cString: peersPtr)
            ya_ok_free_string(peersPtr)
            
            if let data = peersJson.data(using: .utf8),
               let peers = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                stats += "  Active: \\(peers.count)\n"
                
                for (i, peer) in peers.prefix(5).enumerated() {
                    if let pk = peer["public_key"] as? String,
                       let meta = peer["meta"] as? String {
                        let pkShort = String(pk.prefix(16))
                        stats += "  - \\(pkShort)... (\\(meta))\n"
                    }
                }
                
                if peers.count > 5 {
                    stats += "  ... and \\(peers.count - 5) more\n"
                }
            }
        }
        stats += "\n"
        
        // ACK Stats
        stats += "ACK STATUS (last message):\n"
        if let recentPtr = ya_ok_get_recent_messages(1) {
            let recentJson = String(cString: recentPtr)
            ya_ok_free_string(recentPtr)
            
            if let data = recentJson.data(using: .utf8),
               let messages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstMsg = messages.first,
               let messageId = firstMsg["id"] as? String {
                
                let msgIdShort = String(messageId.prefix(16))
                stats += "  Message: \\(msgIdShort)...\n"
                
                // Get ACKs for this message
                if let messageIdCStr = messageId.cString(using: .utf8) {
                    if let acksPtr = ya_ok_get_acks_for_message(messageIdCStr) {
                        let acksJson = String(cString: acksPtr)
                        ya_ok_free_string(acksPtr)
                        
                        if let ackData = acksJson.data(using: .utf8),
                           let acks = try? JSONSerialization.jsonObject(with: ackData) as? [[String: Any]] {
                            stats += "  ACKs: \\(acks.count)\n"
                            
                            let receivedCount = acks.filter { ($0["ack_type"] as? String) == "Received" }.count
                            let deliveredCount = acks.filter { ($0["ack_type"] as? String) == "Delivered" }.count
                            
                            stats += "  Received: \\(receivedCount)\n"
                            stats += "  Delivered: \\(deliveredCount)\n"
                        }
                    }
                }
            } else {
                stats += "  No messages\n"
            }
        }
        stats += "\n"
        
        // Transport Stats
        stats += "TRANSPORT:\n"
        stats += "  Bluetooth: \\(isBluetoothEnabled() ? "ON" : "OFF")\n"
        stats += "  WiFi: \\(isWifiEnabled() ? "ON" : "OFF")\n"
        stats += "  Internet: \\(hasInternetConnection() ? "CONNECTED" : "OFFLINE")\n"
        stats += "\n"
        
        // Memory Stats
        stats += "MEMORY:\n"
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = info.resident_size / 1024 / 1024
            stats += "  Used: \\(usedMB)MB\n"
        }
        stats += "\n"
        
        // Footer
        stats += "======================\n"
        let timestamp = Date().timeIntervalSince1970
        stats += "Last update: \\(Int(timestamp))"
        
        statsLabel.text = stats
    }
    
    // MARK: - Helper Methods
    
    private func isBluetoothEnabled() -> Bool {
        // Would need to check CBCentralManager state
        return true // Placeholder
    }
    
    private func isWifiEnabled() -> Bool {
        // Check network reachability
        return true // Placeholder
    }
    
    private func hasInternetConnection() -> Bool {
        // Check internet connectivity
        return true // Placeholder
    }
}

// MARK: - FFI Declarations

@_silgen_name("ya_ok_get_identity_id")
func ya_ok_get_identity_id() -> UnsafePointer<CChar>?

@_silgen_name("ya_ok_get_recent_messages")
func ya_ok_get_recent_messages(_: Int32) -> UnsafePointer<CChar>?

@_silgen_name("ya_ok_peer_store_list")
func ya_ok_peer_store_list() -> UnsafePointer<CChar>?

@_silgen_name("ya_ok_get_acks_for_message")
func ya_ok_get_acks_for_message(_: UnsafePointer<CChar>) -> UnsafePointer<CChar>?

@_silgen_name("ya_ok_free_string")
func ya_ok_free_string(_: UnsafePointer<CChar>)
