/// Secure key storage guidelines for iOS and Android platforms.
///
/// **CRITICAL SECURITY REQUIREMENT:**
///
/// Private keys (Ed25519 SigningKey, X25519 StaticSecret) MUST be stored in
/// platform-specific secure storage, NOT in files or databases.
///
/// ## iOS Implementation (Keychain)
///
/// Use iOS Keychain Services API to store/retrieve private keys:
///
/// ```swift
/// // Store private key
/// func storePrivateKey(_ keyData: Data, identifier: String) -> Bool {
///     let query: [String: Any] = [
///         kSecClass as String: kSecClassKey,
///         kSecAttrApplicationLabel as String: identifier,
///         kSecValueData as String: keyData,
///         kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
///     ]
///     
///     SecItemDelete(query as CFDictionary) // Remove existing
///     let status = SecItemAdd(query as CFDictionary, nil)
///     return status == errSecSuccess
/// }
///
/// // Retrieve private key
/// func retrievePrivateKey(identifier: String) -> Data? {
///     let query: [String: Any] = [
///         kSecClass as String: kSecClassKey,
///         kSecAttrApplicationLabel as String: identifier,
///         kSecReturnData as String: true
///     ]
///     
///     var result: AnyObject?
///     let status = SecItemCopyMatching(query as CFDictionary, &result)
///     
///     if status == errSecSuccess {
///         return result as? Data
///     }
///     return nil
/// }
/// ```
///
/// ## Android Implementation (Keystore)
///
/// Use Android Keystore System (hardware-backed when available):
///
/// ```kotlin
/// import java.security.KeyStore
/// import javax.crypto.Cipher
/// import javax.crypto.KeyGenerator
/// import javax.crypto.spec.GCMParameterSpec
/// import android.security.keystore.KeyGenParameterSpec
/// import android.security.keystore.KeyProperties
///
/// // Store private key (encrypted with Keystore key)
/// fun storePrivateKey(keyData: ByteArray, identifier: String) {
///     val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
///     
///     // Generate AES key in Keystore
///     if (!keyStore.containsAlias(identifier)) {
///         val keyGenerator = KeyGenerator.getInstance(
///             KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore"
///         )
///         keyGenerator.init(
///             KeyGenParameterSpec.Builder(
///                 identifier,
///                 KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
///             )
///             .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
///             .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
///             .setUserAuthenticationRequired(false)
///             .build()
///         )
///         keyGenerator.generateKey()
///     }
///     
///     // Encrypt private key with Keystore key
///     val secretKey = keyStore.getKey(identifier, null) as javax.crypto.SecretKey
///     val cipher = Cipher.getInstance("AES/GCM/NoPadding")
///     cipher.init(Cipher.ENCRYPT_MODE, secretKey)
///     
///     val encryptedData = cipher.doFinal(keyData)
///     val iv = cipher.iv
///     
///     // Store encrypted data + IV in SharedPreferences
///     val prefs = context.getSharedPreferences("ya_ok_keys", Context.MODE_PRIVATE)
///     prefs.edit()
///         .putString("${identifier}_encrypted", Base64.encodeToString(encryptedData, Base64.DEFAULT))
///         .putString("${identifier}_iv", Base64.encodeToString(iv, Base64.DEFAULT))
///         .apply()
/// }
///
/// // Retrieve private key (decrypt with Keystore key)
/// fun retrievePrivateKey(identifier: String): ByteArray? {
///     val prefs = context.getSharedPreferences("ya_ok_keys", Context.MODE_PRIVATE)
///     val encryptedData = prefs.getString("${identifier}_encrypted", null) ?: return null
///     val iv = prefs.getString("${identifier}_iv", null) ?: return null
///     
///     val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
///     val secretKey = keyStore.getKey(identifier, null) as javax.crypto.SecretKey
///     
///     val cipher = Cipher.getInstance("AES/GCM/NoPadding")
///     cipher.init(Cipher.DECRYPT_MODE, secretKey, GCMParameterSpec(128, Base64.decode(iv, Base64.DEFAULT)))
///     
///     return cipher.doFinal(Base64.decode(encryptedData, Base64.DEFAULT))
/// }
/// ```
///
/// ## Key Lifecycle
///
/// 1. **Generation:** Generate keys in Rust core (ya_ok_core_identity_new)
/// 2. **Storage:** Immediately store in platform secure storage (never persist raw keys)
/// 3. **Retrieval:** Load from secure storage only when needed for crypto operations
/// 4. **Cleanup:** Keys in memory are auto-zeroed via zeroize crate on drop
///
/// ## Security Checklist
///
/// - [ ] iOS: Use kSecAttrAccessibleWhenUnlockedThisDeviceOnly
/// - [ ] Android: Use AndroidKeyStore with hardware backing (when available)
/// - [ ] Never log private keys (even in debug mode)
/// - [ ] Never transmit private keys over network (even encrypted)
/// - [ ] Delete keys from secure storage when user logs out
/// - [ ] Verify secure storage availability before key generation
///
/// ## Testing
///
/// - **iOS Simulator:** Keychain works but isn't hardware-backed
/// - **Android Emulator (API 23+):** Software-backed Keystore available
/// - **Real Devices:** Hardware-backed Keystore (Secure Element/TEE) on modern devices
///
/// ## References
///
/// - iOS Keychain Services: https://developer.apple.com/documentation/security/keychain_services
/// - Android Keystore System: https://developer.android.com/training/articles/keystore
/// - OWASP Mobile Top 10 - M2: Insecure Data Storage
