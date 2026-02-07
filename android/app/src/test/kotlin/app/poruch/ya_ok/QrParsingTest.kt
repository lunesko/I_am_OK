package app.poruch.ya_ok

import app.poruch.ya_ok.ui.FamilyFragment
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Unit tests for QR code parsing and contact URL handling
 */
@RunWith(RobolectricTestRunner::class)
class QrParsingTest {
    
    @Test
    fun parseContactQr_fullUrl_allParameters() {
        // Test QR with all parameters: id, name, x25519
        val qrUrl = "yaok://add?id=test123&name=Олексій&x=abc456def"
        val fragment = FamilyFragment()
        
        // Use reflection to access private method
        val method = FamilyFragment::class.java.getDeclaredMethod(
            "parseContactQr",
            String::class.java
        )
        method.isAccessible = true
        val result = method.invoke(fragment, qrUrl)
        
        // Verify all fields parsed correctly
        val idField = result.javaClass.getDeclaredField("id")
        idField.isAccessible = true
        assertEquals("test123", idField.get(result))
        
        val nameField = result.javaClass.getDeclaredField("name")
        nameField.isAccessible = true
        assertEquals("Олексій", nameField.get(result))
        
        val x25519Field = result.javaClass.getDeclaredField("x25519Hex")
        x25519Field.isAccessible = true
        assertEquals("abc456def", x25519Field.get(result))
    }
    
    @Test
    fun parseContactQr_urlEncodedName_decoded() {
        // Test URL encoding/decoding of Ukrainian name
        val encodedName = "Олексій"
        val qrUrl = "yaok://add?id=test123&name=${android.net.Uri.encode(encodedName)}"
        val fragment = FamilyFragment()
        
        val method = FamilyFragment::class.java.getDeclaredMethod(
            "parseContactQr",
            String::class.java
        )
        method.isAccessible = true
        val result = method.invoke(fragment, qrUrl)
        
        val nameField = result.javaClass.getDeclaredField("name")
        nameField.isAccessible = true
        
        // Verify name is decoded
        assertEquals(encodedName, nameField.get(result))
    }
    
    @Test
    fun parseContactQr_minimalUrl_onlyId() {
        // Test minimal QR with only ID
        val qrUrl = "yaok://add?id=minimal123"
        val fragment = FamilyFragment()
        
        val method = FamilyFragment::class.java.getDeclaredMethod(
            "parseContactQr",
            String::class.java
        )
        method.isAccessible = true
        val result = method.invoke(fragment, qrUrl)
        
        val idField = result.javaClass.getDeclaredField("id")
        idField.isAccessible = true
        assertEquals("minimal123", idField.get(result))
        
        val nameField = result.javaClass.getDeclaredField("name")
        nameField.isAccessible = true
        assertNull(nameField.get(result))
        
        val x25519Field = result.javaClass.getDeclaredField("x25519Hex")
        x25519Field.isAccessible = true
        assertNull(x25519Field.get(result))
    }
    
    @Test
    fun parseContactQr_invalidUrl_handlesGracefully() {
        // Test invalid URL format
        val invalidUrl = "not-a-valid-url"
        val fragment = FamilyFragment()
        
        val method = FamilyFragment::class.java.getDeclaredMethod(
            "parseContactQr",
            String::class.java
        )
        method.isAccessible = true
        val result = method.invoke(fragment, invalidUrl)
        
        val idField = result.javaClass.getDeclaredField("id")
        idField.isAccessible = true
        
        // Should fallback to raw string as ID
        assertEquals(invalidUrl, idField.get(result))
    }
    
    @Test
    fun normalizeContactId_yaokUrl_extractsId() {
        // Test ID extraction from yaok:// URL
        val qrUrl = "yaok://add?id=extracted789"
        val fragment = FamilyFragment()
        
        val method = FamilyFragment::class.java.getDeclaredMethod(
            "normalizeContactId",
            String::class.java
        )
        method.isAccessible = true
        val result = method.invoke(fragment, qrUrl) as String
        
        assertEquals("extracted789", result)
    }
}
