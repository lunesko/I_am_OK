import Foundation
import Network
import CryptoKit

/// Manages relay server security: IP pinning, signature verification, rate limiting
final class RelaySecurityManager {
    
    // MARK: - Configuration
    
    /// Pinned relay server IP addresses (production + fallback)
    private static let pinnedRelayIPs: Set<String> = [
        "213.188.195.83",  // Primary Fly.io relay
        // Add fallback IPs here when deploying multiple instances
    ]
    
    /// Relay server public key for signature verification (Ed25519)
    /// TODO: Replace with actual relay server public key after deployment
    private static let relayPublicKeyHex = "0000000000000000000000000000000000000000000000000000000000000000"
    
    /// Maximum packets per second from relay (anti-DoS)
    private static let maxPacketsPerSecond: Int = 100
    
    // MARK: - State
    
    private var packetCount: Int = 0
    private var windowStart: Date = Date()
    private let windowDuration: TimeInterval = 1.0
    private let queue = DispatchQueue(label: "yaok.relay.security")
    
    // MARK: - Public API
    
    /// Validate relay endpoint before sending
    func validateRelayEndpoint(_ endpoint: NWEndpoint) -> Bool {
        guard case .hostPort(let host, let port) = endpoint else {
            print("⚠️ Invalid endpoint type")
            return false
        }
        
        // Verify port
        guard port == NWEndpoint.Port(integerLiteral: 40100) else {
            print("⚠️ Invalid relay port: \(port)")
            return false
        }
        
        // Verify IP pinning
        let hostString = "\(host)"
        guard Self.pinnedRelayIPs.contains(hostString) else {
            print("⚠️ Relay IP not pinned: \(hostString)")
            return false
        }
        
        return true
    }
    
    /// Validate incoming packet from relay
    func validateIncomingPacket(from endpoint: NWEndpoint, data: Data) -> Bool {
        guard case .hostPort(let host, let port) = endpoint else {
            return false
        }
        
        // Verify it's from relay port
        guard port == NWEndpoint.Port(integerLiteral: 40100) else {
            return false
        }
        
        // Note: Fly.io UDP anycast may use different IPs for replies
        // So we only verify the port, not the source IP
        
        // Rate limiting check
        return queue.sync {
            let now = Date()
            if now.timeIntervalSince(windowStart) > windowDuration {
                // Reset window
                windowStart = now
                packetCount = 1
                return true
            }
            
            packetCount += 1
            if packetCount > Self.maxPacketsPerSecond {
                print("⚠️ Rate limit exceeded from relay")
                return false
            }
            
            return true
        }
    }
    
    /// Verify relay server signature (if packet contains signature)
    /// Format: last 64 bytes = Ed25519 signature of payload
    func verifyRelaySignature(data: Data) -> Bool {
        guard data.count > 64 else {
            // No signature present - accept for backward compatibility
            return true
        }
        
        let payload = data.prefix(data.count - 64)
        let signature = data.suffix(64)
        
        guard let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: Data(hex: Self.relayPublicKeyHex)) else {
            print("⚠️ Failed to load relay public key")
            return false
        }
        
        return publicKey.isValidSignature(signature, for: payload)
    }
    
    /// Get current relay endpoints (for multi-region support)
    static func getRelayEndpoints() -> [(host: NWEndpoint.Host, port: NWEndpoint.Port)] {
        return pinnedRelayIPs.map { ip in
            (host: NWEndpoint.Host(ip), port: NWEndpoint.Port(integerLiteral: 40100))
        }
    }
}

// MARK: - Hex Utilities

extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var i = hex.startIndex
        for _ in 0..<len {
            let j = hex.index(i, offsetBy: 2)
            let bytes = hex[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}
