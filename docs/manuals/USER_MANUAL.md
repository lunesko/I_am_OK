# Ya OK User Manual
## Secure, Private Messaging — Your Way

**Version:** 1.0  
**Date:** 2026-02-06  
**Platform:** Android & iOS

---

## Welcome to Ya OK! 👋

Ya OK is a secure, privacy-focused messaging app that lets you communicate without relying on the internet. Whether you're next to someone or across the world, Ya OK adapts to work for you.

**What makes Ya OK special:**
- **No phone number required** — Your privacy comes first
- **Works offline** — Bluetooth and WiFi Direct for local messaging
- **End-to-end encrypted** — Only you and your contacts can read messages
- **No data collection** — We can't read your messages, and we don't want to
- **Open source** — Community audited for security

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [Creating Your Identity](#2-creating-your-identity)
3. [Adding Contacts](#3-adding-contacts)
4. [Sending Messages](#4-sending-messages)
5. [Understanding Message Delivery](#5-understanding-message-delivery)
6. [Privacy & Security](#6-privacy--security)
7. [Settings](#7-settings)
8. [Troubleshooting](#8-troubleshooting)
9. [FAQ](#9-faq)

---

## 1. Getting Started

### System Requirements

**Android:**
- Android 7.0 (API 24) or newer
- Bluetooth 4.0+ (for BLE messaging)
- WiFi (for WiFi Direct and Relay)
- 100 MB free storage

**iOS:**
- iOS 14.0 or newer
- Bluetooth 4.0+
- WiFi
- 100 MB free storage

### Installation

**Android (Google Play):**
1. Open Google Play Store
2. Search for "Ya OK"
3. Tap **Install**
4. Open the app

**iOS (App Store):**
1. Open App Store
2. Search for "Ya OK"
3. Tap **Get**
4. Authenticate with Face ID/Touch ID
5. Open the app

### First Launch

When you first open Ya OK:
1. Read and accept the **Terms of Service**
2. Grant required permissions:
   - **Bluetooth** (for BLE messaging)
   - **Location** (required by Android for Bluetooth scanning)
   - **WiFi** (for WiFi Direct and Relay)
   - **Notifications** (to receive messages)
3. You'll be taken to the **Setup** screen

---

## 2. Creating Your Identity

### What is an Identity?

Your identity is a unique cryptographic key pair that:
- Identifies you to your contacts
- Encrypts and signs your messages
- **Cannot be recovered if lost** — Back it up!

### Setup Steps

1. **Enter Your Name**
   - This is your display name (e.g., "Alice")
   - Visible to contacts you add
   - Can be changed later in Settings

2. **Generate Identity**
   - Tap **Generate Identity**
   - The app creates your encryption keys
   - This takes a few seconds

3. **Backup Your Identity**
   - Tap **Export Identity**
   - Choose backup method:
     - **Save QR Code** (screenshot and store securely)
     - **Cloud Backup** (encrypted, stored in your device's cloud)
   - **IMPORTANT:** Without this backup, you cannot restore your identity if you lose your device!

4. **Done!**
   - You're ready to add contacts and start messaging

### Identity Fingerprint

Your **Safety Number** (or fingerprint) is a unique identifier:
- Example: `A3F2 8B91 C4D5 E6F7...`
- Used to verify contacts (prevents impersonation)
- Found in Settings → My Identity

---

## 3. Adding Contacts

### Why Scan QR Codes?

Ya OK uses QR codes to exchange public keys securely. This ensures:
- No central server has your contact list
- No one can impersonate your contacts
- You control who you communicate with

### Adding a Contact (In-Person)

**Step 1: Both people open Ya OK**

**Step 2: One person shares their QR code**
- Tap **☰ Menu** → **My Identity**
- Tap **Share QR Code**
- Show your QR code to the other person

**Step 3: Other person scans**
- Tap **+ Add Contact**
- Tap **Scan QR Code**
- Point camera at the QR code
- Wait for the green checkmark

**Step 4: Repeat in reverse**
- Now the other person shares their QR code
- You scan it

**Step 5: Done!**
- You can now message each other
- The contact appears in your **Contacts** list

### Adding a Contact (Remotely)

If you can't meet in person:

1. **Screenshot QR Code**
   - Go to **My Identity** → **Share QR Code**
   - Take a screenshot
   - Send via another secure channel (Signal, WhatsApp)

2. **They Import QR Code**
   - Save your screenshot
   - In Ya OK: **Add Contact** → **Import from Image**
   - Select the screenshot

⚠️ **Security Note:** Sending QR codes over unencrypted channels (SMS, email) is less secure. Verify safety numbers afterward!

### Verifying Contacts

After adding a contact, verify their identity:

1. **Open Contact**
   - Tap the contact in your list
   - Tap **ⓘ Info**

2. **Compare Safety Numbers**
   - You'll see two safety numbers:
     - **Your Safety Number**
     - **Their Safety Number**
   - Compare these numbers in person or via video call
   - They should match exactly

3. **Mark as Verified**
   - If they match, tap **Mark as Verified** ✓
   - Verified contacts show a blue checkmark
   - Messages from verified contacts are trustworthy

---

## 4. Sending Messages

### Sending a Text Message

1. **Open a conversation**
   - Tap a contact in your list
   - Or tap **New Message** and select a contact

2. **Type your message**
   - Use the text field at the bottom
   - Emoji supported 😊

3. **Send**
   - Tap the **Send** button (paper airplane icon)
   - Message appears in the conversation

### Sending a File (Photo, Document)

1. **Tap the attachment icon** (📎)

2. **Choose file type:**
   - **Photo/Video** — From gallery or take new
   - **File** — From device storage

3. **Select file** (max 100 MB)

4. **Send**
   - File encrypts and sends
   - Progress bar shows upload status

### Message Status Indicators

Messages show different status icons:

| Icon | Status | Meaning |
|------|--------|---------|
| **🕐** | Sending | Message being encrypted |
| **✓** | Sent | Message left your device |
| **✓✓** | Delivered | Message reached recipient |
| **✓✓ (blue)** | Read | Recipient opened message |
| **⚠️** | Failed | Send failed, tap to retry |

### Deleting Messages

**Delete for yourself only:**
1. Long-press message
2. Tap **Delete**
3. Message removed from your device only

**Delete for everyone:** (Not yet available)
- Currently not supported
- Planned for future update

---

## 5. Understanding Message Delivery

Ya OK uses three methods to deliver messages:

### 🔵 Bluetooth (BLE)

**When it works:**
- Recipient within ~30 meters
- Both devices have Bluetooth on
- Works offline

**How to use:**
- Bluetooth is automatically used when nearby
- No configuration needed
- Look for **BLE** indicator in message status

**Pros:**
- Works without internet
- Ultra-private (direct device-to-device)
- Free

**Cons:**
- Limited range (~30m)
- Both users must be nearby

### 📶 WiFi Direct

**When it works:**
- Recipient within ~100 meters
- Both on same WiFi network
- Works offline (no internet needed)

**How to use:**
- Automatically used when on same WiFi
- No configuration needed
- Look for **WiFi** indicator

**Pros:**
- Better range than Bluetooth
- Faster than Bluetooth
- Works offline

**Cons:**
- Both must be on same network
- Limited range

### 🌐 Relay Server (Internet)

**When it works:**
- Both devices have internet
- Can be anywhere in the world
- Recipient doesn't need to be online

**How to use:**
- Automatically used when:
  - Recipient not nearby (no BLE/WiFi)
  - Both have internet connection
- Look for **Relay** indicator

**How it works:**
1. Your message is encrypted on your device
2. Sent to relay server (encrypted)
3. Relay server stores until recipient connects
4. Recipient downloads and decrypts

**Pros:**
- Works globally
- Recipient doesn't need to be online
- Messages queued until delivered

**Cons:**
- Requires internet
- Small data usage (~1-2 KB per message)

### Message Priority

Ya OK automatically chooses the best method:

```
1. BLE (if nearby) → Fastest, most private
2. WiFi Direct (if same network) → Fast, private
3. Relay (if internet) → Works anywhere
4. Queue locally (if offline) → Sends when online
```

You don't need to choose — it just works!

---

## 6. Privacy & Security

### What Ya OK Knows About You

**We know:**
- Nothing. Seriously.

**We don't collect:**
- Your name
- Your phone number
- Your email
- Your messages
- Your contact list
- Your location
- Your IP address (not stored)

### What the Relay Server Sees

When using the relay server:

**It sees:**
- Encrypted message (unreadable)
- Your user ID (random UUID, not linked to you)
- Recipient's user ID
- Timestamp
- Message size

**It does NOT see:**
- Message content (encrypted)
- Your name or identity
- Who you're talking to (only UUIDs)
- Your location

### How Encryption Works

**End-to-End Encryption:**
1. You type a message
2. Ya OK encrypts it on your device
3. Message travels encrypted (via BLE/WiFi/Relay)
4. Recipient decrypts on their device
5. Only you and recipient can read it

**Nobody else can decrypt:**
- Not us (Ya OK developers)
- Not the relay server
- Not your ISP
- Not hackers
- Not governments

**Encryption Details:**
- Algorithm: XChaCha20-Poly1305 (AEAD)
- Key Exchange: X25519 (ECDH)
- Signatures: Ed25519
- Key Size: 256-bit

### Best Practices

**✅ Do:**
- Verify safety numbers for important contacts
- Back up your identity regularly
- Use a strong device passcode
- Keep Ya OK updated

**❌ Don't:**
- Share QR codes publicly
- Screenshot private messages
- Add unknown contacts
- Disable device encryption

### Privacy Settings

**Settings → Privacy:**

- **Read Receipts** (Default: On)
  - Let contacts know when you read messages
  - Turn off for more privacy

- **Typing Indicators** (Default: On)
  - Show when you're typing
  - Turn off to stay more private

- **Disappearing Messages** (Coming soon)
  - Auto-delete messages after time
  - Planned for future update

---

## 7. Settings

Access settings: **☰ Menu** → **Settings**

### Profile Settings

**Display Name**
- Your name shown to contacts
- Change anytime
- Contacts see new name immediately

**Profile Photo** (Coming soon)
- Currently not available
- Planned for future update

### Connection Settings

**Bluetooth**
- Enable/disable Bluetooth messaging
- Recommended: Keep enabled

**WiFi Direct**
- Enable/disable WiFi Direct
- Recommended: Keep enabled

**Relay Server**
- Enable/disable internet relay
- Choose relay region (Auto, Europe, US, Asia)
- Recommended: Keep enabled

### Notification Settings

**Message Notifications**
- Enable/disable new message notifications
- Sound, vibration, LED

**Show Message Preview**
- Show message text in notifications
- Turn off for more privacy

**Do Not Disturb**
- Mute all notifications
- Customize hours

### Storage Settings

**Cache Management**
- Clear message cache
- Delete old media files
- View storage usage

**Auto-Download Media**
- Download photos automatically
- Download videos automatically
- Download files automatically
- Customize per connection type (WiFi/Cellular)

### Security Settings

**Screen Lock**
- Require PIN/Biometric to open Ya OK
- Auto-lock timer (1min, 5min, 30min)

**Incognito Keyboard** (Android)
- Disable keyboard learning for Ya OK
- More private typing

**Screen Security** (Android)
- Block screenshots in Ya OK
- Block screen recording

### Backup & Restore

**Backup Identity**
- Export QR code
- Cloud backup (encrypted)

**Restore Identity**
- Import QR code
- Restore from cloud

**Messages** (Coming soon)
- Backup message history
- Restore messages

### About

**App Version**
- Current version number
- Check for updates

**Privacy Policy**
- View full privacy policy

**Terms of Service**
- View terms

**Open Source Licenses**
- View third-party licenses

**Support**
- Email: support@yaok.app
- Website: yaok.app

---

## 8. Troubleshooting

### Messages Not Sending

**Check:**
1. **Connection Status**
   - Look at top of screen for connection indicators
   - BLE: Bluetooth icon
   - WiFi: WiFi icon
   - Relay: Cloud icon

2. **Recipient Availability**
   - For BLE/WiFi: Are they nearby and have the app open?
   - For Relay: Do you both have internet?

3. **Permissions**
   - Android: Settings → Apps → Ya OK → Permissions
   - iOS: Settings → Ya OK
   - Ensure Bluetooth, Location, WiFi allowed

**Try:**
- Force close and reopen app
- Turn Bluetooth off and on
- Reconnect to WiFi
- Check airplane mode is off

### Can't Add Contact

**Issue: QR code won't scan**

**Solutions:**
1. **Lighting**
   - Ensure good lighting
   - Avoid glare on screen

2. **Distance**
   - Hold phone 15-30 cm from QR code
   - Not too close, not too far

3. **Camera Permission**
   - Grant camera permission in system settings

4. **Alternative**
   - Take screenshot of QR code
   - Use "Import from Image" instead

**Issue: "Invalid QR code" error**

**Causes:**
- QR code from old version (update app)
- Corrupted screenshot
- Wrong QR code (not a Ya OK contact code)

**Solutions:**
- Ask contact to re-share QR code
- Ensure both users have latest Ya OK version

### App Crashes or Freezes

**Quick Fixes:**
1. **Force Close**
   - Android: Recent apps → Swipe away Ya OK
   - iOS: Double-click home → Swipe up

2. **Clear Cache**
   - Settings → Storage → Clear Cache

3. **Restart Device**

4. **Update App**
   - Check Google Play / App Store for updates

**Still not working?**
- Report bug: support@yaok.app
- Include: Device model, OS version, app version

### Battery Drain

Ya OK is designed to be battery-efficient, but if you notice drain:

**Check:**
1. **Background Activity**
   - Settings → Connection Settings
   - Reduce background scanning frequency

2. **Many Contacts**
   - More contacts = more background activity
   - Consider archiving inactive conversations

3. **Relay vs Local**
   - Relay uses more battery than BLE
   - If mostly offline, disable relay

**Battery Optimization (Android):**
- Settings → Battery → Ya OK
- Set to "Optimized" (not "Not optimized")

### Lost Device / Restore Identity

**If you backed up your identity:**

1. **Install Ya OK on new device**
2. **Open app**
3. **Tap "Restore Identity"**
4. **Choose backup method:**
   - **QR Code**: Import saved screenshot
   - **Cloud Backup**: Sign in to restore

**If you did NOT back up:**
- ⚠️ **Identity is lost permanently**
- You'll need to:
  - Generate new identity
  - Re-add all contacts (exchange QR codes again)
  - Previous messages cannot be recovered

**Prevention:**
- Back up identity regularly!
- Store QR code screenshot in secure location
- Enable cloud backup

---

## 9. FAQ

### General Questions

**Q: Do I need a phone number?**  
A: No! Ya OK does not require phone numbers, email, or any personal information.

**Q: Can I use Ya OK without internet?**  
A: Yes! BLE and WiFi Direct work offline. Relay requires internet.

**Q: Is Ya OK really free?**  
A: Yes, completely free. No ads, no premium features, no hidden costs.

**Q: Is it really private?**  
A: Yes. End-to-end encrypted. We can't read your messages even if we wanted to.

**Q: Can I use Ya OK on multiple devices?**  
A: Not yet. Currently one identity per device. Multi-device support coming in future update.

**Q: Can I use Ya OK on a tablet?**  
A: Yes, if it has Bluetooth and WiFi (Android tablets, iPads).

**Q: Does Ya OK work on Desktop?**  
A: Not yet. Mobile only for now. Desktop app planned for future.

### Security Questions

**Q: How secure is Ya OK?**  
A: Very secure:
- End-to-end encryption (XChaCha20-Poly1305)
- Perfect forward secrecy (future update)
- Open source (auditable code)
- No data collection

**Q: Can police/government read my messages?**  
A: No. Messages are end-to-end encrypted. We cannot decrypt them, and neither can governments.

**Q: What if someone steals my phone?**  
A: 
- Use device PIN/biometric lock
- Enable "Screen Lock" in Ya OK settings
- Your messages are encrypted on device (SQLCipher)
- Without device PIN, messages are unreadable

**Q: Can Ya OK employees read my messages?**  
A: No. Messages are encrypted on your device. We never see plaintext.

**Q: What if the relay server is hacked?**  
A: Hackers only get encrypted messages (unreadable). Your identity keys are on your device, not the server.

**Q: Should I verify safety numbers?**  
A: Yes, for important contacts (family, colleagues). This prevents impersonation attacks.

### Technical Questions

**Q: How much data does Ya OK use?**  
A: Minimal:
- Text message: ~1-2 KB
- Photo: ~500 KB - 5 MB (depends on size)
- Video: ~5-50 MB (depends on length)

**Q: How much storage does Ya OK use?**  
A:
- App: ~30 MB
- Messages: Depends on history (~1 MB per 1000 text messages)
- Media: Depends on photos/videos received

**Q: Does Ya OK drain battery?**  
A: No. Ya OK is optimized for battery life:
- Background activity is minimal
- BLE scanning is efficient
- Location permission only used for Bluetooth (Android requirement)

**Q: Why does Ya OK need Location permission (Android)?**  
A: Android requires location permission for Bluetooth scanning. Ya OK does NOT track your location.

**Q: What happens if I'm offline?**  
A: Messages queue locally and send when you're online again.

**Q: Can I recover deleted messages?**  
A: No. Deleted messages are permanently deleted.

**Q: Is group chat supported?**  
A: Not yet. Currently only 1-on-1 messaging. Group chats planned for future update.

**Q: Can I call people?**  
A: Not yet. Voice/video calls planned for future update.

### Troubleshooting Questions

**Q: Why can't I see my contact online?**  
A: Ya OK doesn't show online status for privacy. Send a message; it'll deliver when they're available.

**Q: Why is message delivery slow?**  
A:
- BLE/WiFi: Should be instant if nearby
- Relay: 1-5 seconds depending on internet speed
- If offline, messages queue until online

**Q: Can I change my display name?**  
A: Yes. Settings → Profile → Display Name.

**Q: Can I change my identity?**  
A: No. Each identity is permanent. You'd need to create a new one and re-add contacts.

**Q: I lost my phone. Can I restore messages on new phone?**  
A: If you backed up your identity, you can restore it. Messages themselves are currently not backed up (coming in future update).

---

## Need More Help?

**Support:**
- Email: support@yaok.app
- Website: https://yaok.app/support
- Community: https://community.yaok.app

**Report a Bug:**
- Email: bugs@yaok.app
- Include: Device model, OS version, app version, steps to reproduce

**Security Issues:**
- Email: security@yaok.app
- PGP key available on website

**Follow Us:**
- Twitter: @yaokapp
- Mastodon: @yaok@fosstodon.org
- GitHub: github.com/yaok

---

**Thank you for using Ya OK!**

*Your privacy matters. We're committed to keeping your conversations secure and private.*

**End of User Manual**
