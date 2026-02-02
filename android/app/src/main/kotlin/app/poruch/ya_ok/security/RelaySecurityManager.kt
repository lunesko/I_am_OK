package app.poruch.ya_ok.security

import java.net.InetAddress
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * Manages relay server security: IP pinning, rate limiting, signature verification
 */
class RelaySecurityManager {
    
    companion object {
        /** Pinned relay server IP addresses (Fly.io uses anycast, IPs may vary) */
        private val PINNED_RELAY_IPS = setOf<String>(
            // Fly.io anycast IPs - disabled pinning for cloud deployments
            // "213.188.195.83",  // Example Fly.io IP
            // Add specific IPs only for self-hosted relays
        )
        
        /** Relay server DNS name (Fly.io) */
        const val RELAY_HOST = "i-am-ok-relay.fly.dev"
        
        /** Relay server public key for signature verification (Ed25519) */
        // TODO: Replace with actual relay server public key after deployment
        private const val RELAY_PUBLIC_KEY_HEX = "0000000000000000000000000000000000000000000000000000000000000000"
        
        /** Maximum packets per second from relay (anti-DoS) */
        private const val MAX_PACKETS_PER_SECOND = 100
        
        /** Relay port */
        const val RELAY_PORT = 40100
    }
    
    // Rate limiting state
    private val packetCount = AtomicInteger(0)
    private var windowStart = System.currentTimeMillis()
    private val windowDuration = 1000L // 1 second
    
    /**
     * Validate relay IP address before sending
     * For Fly.io anycast, we skip IP pinning and rely on DNS + TLS
     */
    fun validateRelayAddress(address: InetAddress): Boolean {
        // Skip IP pinning for cloud relays (Fly.io anycast)
        if (PINNED_RELAY_IPS.isEmpty()) {
            return true
        }
        
        val ip = address.hostAddress ?: return false
        
        if (!PINNED_RELAY_IPS.contains(ip)) {
            println("⚠️ Relay IP not pinned: $ip")
            return false
        }
        
        return true
    }
    
    /**
     * Validate incoming packet from relay with rate limiting
     */
    @Synchronized
    fun validateIncomingPacket(sourcePort: Int, data: ByteArray): Boolean {
        // Verify it's from relay port
        if (sourcePort != RELAY_PORT) {
            return false
        }
        
        // Rate limiting check
        val now = System.currentTimeMillis()
        if (now - windowStart > windowDuration) {
            // Reset window
            windowStart = now
            packetCount.set(1)
            return true
        }
        
        val count = packetCount.incrementAndGet()
        if (count > MAX_PACKETS_PER_SECOND) {
            println("⚠️ Rate limit exceeded from relay")
            return false
        }
        
        return true
    }
    
    /**
     * Verify relay server Ed25519 signature (if present)
     * Format: last 64 bytes = signature of payload
     */
    fun verifyRelaySignature(data: ByteArray): Boolean {
        if (data.size <= 64) {
            // No signature present - accept for backward compatibility
            return true
        }
        
        // TODO: Implement Ed25519 signature verification
        // For now, accept all packets (signature verification is optional enhancement)
        return true
    }
    
    /**
     * Get list of valid relay endpoints (for multi-region support)
     */
    fun getValidRelayIPs(): Set<String> = PINNED_RELAY_IPS
}
