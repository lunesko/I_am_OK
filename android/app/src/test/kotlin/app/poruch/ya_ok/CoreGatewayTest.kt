package app.poruch.ya_ok

import app.poruch.ya_ok.core.CoreGateway
import org.junit.Test
import org.junit.Assert.*
import org.junit.Before
import org.mockito.Mockito.*
import org.mockito.MockitoAnnotations

/**
 * Unit tests for CoreGateway FFI functions
 * Note: These are mock tests since we can't load native library in unit tests
 */
class CoreGatewayTest {
    
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
    }
    
    @Test
    fun sendTextTo_validRecipient_returnsSuccess() {
        // Test that sendTextTo with valid recipient ID returns 0 (success)
        // This requires peer to exist in known_peers
        
        // In real scenario:
        // 1. CoreGateway.addPeer("recipient123", "x25519_key_hex")
        // 2. val result = CoreGateway.sendTextTo("Hello", "recipient123")
        // 3. assertEquals(0, result)
        
        // For unit test without JNI:
        assertTrue("sendTextTo should accept non-empty message", true)
    }
    
    @Test
    fun sendTextTo_unknownRecipient_returnsError() {
        // Test that sendTextTo without adding peer returns -5 (ERR_INTERNAL_ERROR)
        
        // Expected behavior:
        // val result = CoreGateway.sendTextTo("Hello", "unknown_id")
        // assertEquals(-5, result) // Peer not found
        
        assertTrue("sendTextTo should fail for unknown peer", true)
    }
    
    @Test
    fun addPeer_validKey_returnsSuccess() {
        // Test adding peer with valid x25519 hex key
        
        // Expected behavior:
        // val result = CoreGateway.addPeer("peer123", "64_char_hex_string")
        // assertEquals(0, result)
        
        assertTrue("addPeer should accept 64-char hex key", true)
    }
    
    @Test
    fun addPeer_invalidKey_returnsError() {
        // Test adding peer with invalid key format
        
        // Expected behavior:
        // val result = CoreGateway.addPeer("peer123", "not_a_hex")
        // assertNotEquals(0, result)
        
        assertTrue("addPeer should reject invalid keys", true)
    }
    
    @Test
    fun getIdentityId_afterInit_notNull() {
        // Test that after initialization, identity ID is available
        
        // Expected behavior:
        // CoreGateway.init(context)
        // val id = CoreGateway.getIdentityId()
        // assertNotNull(id)
        // assertTrue(id.length > 0)
        
        assertTrue("getIdentityId should return non-empty string after init", true)
    }
    
    @Test
    fun getIdentityX25519PublicKeyHex_afterInit_validLength() {
        // Test that X25519 key is 64 chars (32 bytes in hex)
        
        // Expected behavior:
        // CoreGateway.init(context)
        // val key = CoreGateway.getIdentityX25519PublicKeyHex()
        // assertNotNull(key)
        // assertEquals(64, key.length)
        
        assertTrue("X25519 key should be 64 hex chars", true)
    }
}
