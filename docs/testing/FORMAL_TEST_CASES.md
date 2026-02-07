# Formal Test Cases
## Ya OK - Comprehensive Test Suite

**Document ID:** YA-OK-TEST-001  
**Version:** 1.0  
**Date:** 2026-02-06  
**Status:** Draft  
**Classification:** INTERNAL

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-06 | QA Team | Initial version - Complete test suite |

### Approvals

| Role | Name | Signature | Date |
|------|------|-----------|------|
| QA Lead | [TBD] | | |
| Technical Architect | [TBD] | | |
| Product Owner | [TBD] | | |

### Related Documents

- **YA-OK-SRS-001**: Software Requirements Specification
- **YA-OK-AC-001**: Acceptance Criteria
- **YA-OK-SEC-003**: Security Test Plan
- **YA-OK-NFR-001**: Non-Functional Requirements

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Test Strategy](#2-test-strategy)
3. [Test Environment](#3-test-environment)
4. [Functional Test Cases](#4-functional-test-cases)
5. [Security Test Cases](#5-security-test-cases)
6. [Performance Test Cases](#6-performance-test-cases)
7. [Integration Test Cases](#7-integration-test-cases)
8. [Regression Test Suite](#8-regression-test-suite)
9. [Requirements Coverage Matrix](#9-requirements-coverage-matrix)
10. [Test Execution Reports](#10-test-execution-reports)

---

## 1. Introduction

### 1.1 Purpose

This document provides a comprehensive, structured test suite for the Ya OK messaging system. Each test case follows ISO/IEC 29119 standards and includes:
- Unique test case ID
- Clear preconditions
- Detailed execution steps
- Expected results
- Traceability to requirements

### 1.2 Scope

**In Scope:**
- Functional testing (all features)
- Security testing (authentication, encryption, key management)
- Performance testing (latency, throughput, resource usage)
- Integration testing (component interactions)
- Compatibility testing (Android/iOS versions)
- Usability testing (accessibility, user workflows)
- Regression testing (critical paths)

**Out of Scope:**
- Load testing (relay server capacity) - See separate document
- Stress testing (extreme conditions) - Phase 2
- Penetration testing (external security audit) - Pre-release

### 1.3 Test Case Format

```
TC-<CATEGORY>-<NUMBER>: <Test Case Title>

Requirements: <Related requirement IDs>
Priority: P0 (Critical) | P1 (High) | P2 (Medium) | P3 (Low)
Type: Functional | Security | Performance | Integration | Regression
Platform: Android | iOS | Both
Automation: Yes | No | Partial

Preconditions:
- List of conditions that must be met before test execution

Test Steps:
1. Step 1 description
2. Step 2 description
...

Expected Results:
- Expected outcome for each step

Actual Results: [To be filled during execution]
Status: Not Run | Pass | Fail | Blocked
Notes: [Any observations or deviations]
```

### 1.4 Test Levels

| Level | Description | Coverage Target | Automation Target |
|-------|-------------|-----------------|-------------------|
| **Unit Tests** | Individual functions, classes | ≥80% code coverage | 100% |
| **Integration Tests** | Component interactions | All interfaces | ≥80% |
| **System Tests** | End-to-end workflows | All features | ≥60% |
| **Acceptance Tests** | User stories, scenarios | All acceptance criteria | ≥40% |
| **Regression Tests** | Critical paths, bug fixes | All P0/P1 features | 100% |

---

## 2. Test Strategy

### 2.1 Test Approach

**Shift-Left Testing:**
- Unit tests written alongside code (TDD where applicable)
- Integration tests run on every commit (CI/CD)
- Automated regression tests on every PR
- Manual exploratory testing before release

**Risk-Based Prioritization:**
- P0 (Critical): Security, data loss, crashes
- P1 (High): Core messaging, key management
- P2 (Medium): Settings, UI polish
- P3 (Low): Nice-to-have features

### 2.2 Test Environments

| Environment | Purpose | Configuration |
|-------------|---------|---------------|
| **Dev** | Development testing | Latest code, debug builds |
| **Staging** | Pre-release testing | Release candidates, production-like |
| **Production** | Live monitoring | Released builds, real users |

**Device Matrix:**
- Android: 5 devices (API 24, 27, 30, 33, 34)
- iOS: 5 devices (iOS 14, 15, 16, 17, 18)
- Emulators: Android Studio, Xcode Simulator
- Physical devices: Samsung Galaxy S21, Pixel 6, iPhone 12, iPhone 14

### 2.3 Test Tools

| Tool | Purpose | Platform |
|------|---------|----------|
| **JUnit 5** | Unit tests | Android (Kotlin) |
| **Espresso** | UI tests | Android |
| **XCTest** | Unit/UI tests | iOS (Swift) |
| **Rust cargo test** | Unit tests | Rust core |
| **Postman** | API tests | Relay server |
| **GitHub Actions** | CI/CD | All |
| **Firebase Test Lab** | Device testing | Android |
| **AWS Device Farm** | Device testing | iOS |
| **SonarQube** | Code quality | All |
| **OWASP ZAP** | Security scanning | All |

### 2.4 Entry and Exit Criteria

**Entry Criteria:**
- Code complete for feature
- Unit tests pass (≥80% coverage)
- Build successful (no compilation errors)
- Test environment ready
- Test data prepared

**Exit Criteria:**
- All P0/P1 tests pass
- No critical defects open
- Code coverage ≥80% (unit tests)
- Security scan clean (no critical/high vulnerabilities)
- Performance benchmarks met
- Acceptance criteria satisfied

---

## 3. Test Environment

### 3.1 Test Data

**Users:**
- Alice (verified contact, active)
- Bob (verified contact, active)
- Charlie (unverified contact)
- Dave (unknown user, not in contacts)

**Messages:**
- Short text (10 chars)
- Long text (10,000 chars)
- Unicode text (emoji, non-Latin)
- File attachment (1 MB, 10 MB, 50 MB)
- Malformed messages (invalid format, corrupted data)

**Devices:**
- Android 7.0 (API 24) - Minimum supported
- Android 14 (API 34) - Latest
- iOS 14.0 - Minimum supported
- iOS 18.0 - Latest

### 3.2 Test Configuration

**Network Conditions:**
- Online (WiFi, strong signal)
- Online (Cellular 4G, weak signal)
- Offline (Airplane mode)
- Intermittent (toggling network)

**Battery Levels:**
- High (>80%)
- Medium (20-80%)
- Low (<20%)
- Critical (<5%)

**Storage:**
- Plenty of space (>1 GB free)
- Low space (<100 MB free)
- Critical space (<10 MB free)

---

## 4. Functional Test Cases

### 4.1 User Onboarding

#### TC-FUNC-001: First Launch - Identity Generation

**Requirements:** FR-USER-001, US-001  
**Priority:** P0  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- App installed (fresh install, no previous data)
- Device has sufficient storage (>50 MB)
- Keystore/Keychain available

**Test Steps:**
1. Launch Ya OK app
2. Observe onboarding screen
3. Enter display name "Alice"
4. Tap "Create Identity" button
5. Wait for identity generation to complete
6. Observe main screen

**Expected Results:**
1. App launches successfully, shows onboarding screen
2. Onboarding screen displays: title, description, name input, "Create Identity" button
3. Display name field accepts input, shows "Alice"
4. Progress indicator appears during generation
5. Identity generated within 5 seconds
6. Main screen shows: empty chat list, navigation bar, "Add Contact" button

**Pass Criteria:**
- Identity generation completes in <5s
- Keys stored in keystore/keychain (verify via logs)
- Display name persisted correctly
- No crashes or errors

---

#### TC-FUNC-002: Export Identity as QR Code

**Requirements:** FR-USER-002, US-001  
**Priority:** P0  
**Type:** Functional  
**Platform:** Both  
**Automation:** Partial (UI validation manual)

**Preconditions:**
- User has created identity (TC-FUNC-001 passed)
- Camera permission granted (for scanning verification)

**Test Steps:**
1. Navigate to Settings
2. Tap "My QR Code"
3. Observe QR code display
4. Verify fingerprint displayed below QR code
5. Take screenshot (manual step)
6. Use external QR scanner to decode QR code
7. Verify QR code format: `yaok://contact?v=1&d=<base64_data>`

**Expected Results:**
1. Settings screen opens
2. "My QR Code" option visible and tappable
3. QR code displayed, fills screen width
4. Fingerprint displayed (16 groups of 4 hex digits)
5. Screenshot captured successfully
6. QR code scannable by standard scanners
7. Decoded data contains: version, user ID, display name, public keys, signature

**Pass Criteria:**
- QR code generation <100ms
- QR code scannable by 3 different QR apps
- Fingerprint matches BLAKE3(keys)
- No sensitive data exposed (private keys not in QR)

---

#### TC-FUNC-003: Authentication Setup (PIN)

**Requirements:** FR-AUTH-001, US-002  
**Priority:** P0  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- User has created identity
- No PIN set yet

**Test Steps:**
1. Navigate to Settings → Security
2. Tap "Set PIN"
3. Enter PIN: "1234"
4. Tap "Continue"
5. Re-enter PIN: "1234"
6. Tap "Confirm"
7. Observe success message
8. Exit app
9. Relaunch app
10. Observe PIN prompt
11. Enter correct PIN: "1234"
12. Observe app unlocked

**Expected Results:**
1. Security settings screen opens
2. "Set PIN" option visible
3. PIN entry screen shows, accepts input (masked)
4. Transitions to confirmation screen
5. Confirmation screen shows, accepts input
6. PINs match, success message displayed
7. App navigates to main screen
8. App backgrounds successfully
9. App relaunches, shows PIN lock screen
10. PIN lock screen displayed with numeric keypad
11. PIN accepted, authentication successful
12. Main screen displayed

**Pass Criteria:**
- PIN stored securely (hashed, in keystore)
- Authentication succeeds with correct PIN
- Authentication fails with incorrect PIN (tested separately)
- Lockout after 5 failed attempts (tested separately)

---

### 4.2 Contact Management

#### TC-FUNC-010: Add Contact via QR Scan

**Requirements:** FR-CONTACT-001, US-010  
**Priority:** P0  
**Type:** Functional  
**Platform:** Both  
**Automation:** Partial (QR generation automated, scanning manual)

**Preconditions:**
- User (Alice) logged in
- Camera permission granted
- Bob's QR code available (from TC-FUNC-002)

**Test Steps:**
1. Tap "Add Contact" button
2. Grant camera permission (if prompted)
3. Point camera at Bob's QR code
4. Observe QR code scanned
5. Verify contact information displayed
6. Verify fingerprint displayed
7. Tap "Add Contact"
8. Observe contact added to list
9. Open contact details
10. Verify all contact information correct

**Expected Results:**
1. Camera view opens, shows QR scanner overlay
2. Permission dialog shown (first time only), user grants
3. QR code detected within 2 seconds
4. QR code parsed, contact info shown: display name "Bob", fingerprint
5. Contact details screen shows: name, fingerprint, "Add Contact" button
6. Fingerprint matches Bob's exported fingerprint
7. Contact added successfully, returns to contact list
8. Contact list shows "Bob" with unverified status (gray checkmark)
9. Contact details screen opens
10. Display name: "Bob", Public key fingerprint correct, Verified: No, Added date/time correct

**Pass Criteria:**
- QR scanning <2s
- Contact data parsed correctly
- Signature verified successfully
- Duplicate detection works (try adding same contact twice)
- No crashes or errors

---

#### TC-FUNC-011: Verify Contact (Safety Number)

**Requirements:** FR-CONTACT-003, US-031  
**Priority:** P0  
**Type:** Functional  
**Platform:** Both  
**Automation:** No (requires two devices)

**Preconditions:**
- Alice and Bob have added each other (TC-FUNC-010 passed on both devices)
- Both users physically present or on video call

**Test Steps:**
1. Alice opens Bob's contact details
2. Alice taps "Verify Contact"
3. Observe safety number (fingerprint) displayed
4. Alice reads safety number aloud to Bob
5. Bob opens Alice's contact details
6. Bob compares fingerprint with Alice's reading
7. Bob confirms match
8. Bob taps "Mark as Verified"
9. Alice taps "Mark as Verified"
10. Observe verified status on both devices

**Expected Results:**
1. Contact details screen shows Bob's info
2. "Verify Contact" button visible and tappable
3. Verification screen shows: safety number (16 groups of 4 hex), "Mark as Verified" button
4. Alice successfully reads all 64 hex characters
5. Bob's contact details show Alice's fingerprint
6. Bob confirms fingerprints match character-by-character
7. Bob agrees, no mismatch
8. Bob's device updates Alice's verified status to true
9. Alice's device updates Bob's verified status to true
10. Both contact lists show green checkmark next to contact name

**Pass Criteria:**
- Safety number calculation consistent (same input → same output)
- Verified status persisted correctly
- UI updates reflect verified status (green checkmark)
- Mismatch detection works (manually test with different keys)

---

#### TC-FUNC-012: Delete Contact

**Requirements:** FR-CONTACT-006, US-012  
**Priority:** P1  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- User has at least one contact (Bob)
- No pending messages to/from Bob

**Test Steps:**
1. Open Bob's contact details
2. Tap "Delete Contact" button
3. Observe confirmation dialog
4. Tap "Cancel"
5. Observe contact not deleted
6. Tap "Delete Contact" again
7. Tap "Confirm"
8. Observe contact deleted
9. Verify contact list no longer shows Bob
10. Verify messages from Bob also deleted (if any)

**Expected Results:**
1. Contact details screen displays
2. "Delete Contact" button visible at bottom (red text)
3. Confirmation dialog: "Delete Bob? This will also delete all messages."
4. Dialog dismissed, returns to contact details
5. Contact still present in contact list
6. Confirmation dialog shown again
7. User confirms deletion
8. Contact deletion successful, returns to contact list
9. Contact list does not contain "Bob"
10. Chat history with Bob empty/deleted

**Pass Criteria:**
- Confirmation required before deletion
- Contact deleted from database (verify via logs)
- All messages from contact deleted
- No crashes or orphaned data

---

### 4.3 Messaging

#### TC-FUNC-020: Send Text Message (BLE)

**Requirements:** FR-MSG-SEND-001, US-020  
**Priority:** P0  
**Type:** Functional  
**Platform:** Both  
**Automation:** Partial (two-device setup manual)

**Preconditions:**
- Alice and Bob are verified contacts
- Both devices have Bluetooth enabled
- Devices are within BLE range (<10 meters)
- No network connectivity (WiFi/cellular off)

**Test Steps:**
1. Alice opens chat with Bob
2. Alice types message: "Hello, Bob!"
3. Alice taps Send button
4. Observe message status on Alice's device
5. Wait for message transmission
6. Observe message status updated to "Delivered"
7. On Bob's device, observe notification
8. Bob opens app, navigates to chat with Alice
9. Observe message displayed
10. Observe read receipt sent to Alice

**Expected Results:**
1. Chat screen opens, shows Bob's name, empty message history
2. Message input field accepts text, shows "Hello, Bob!"
3. Send button tappable, message sent
4. Message appears in chat, status: "Sending..." (clock icon)
5. BLE transmission occurs (1-2 seconds)
6. Message status: "Delivered" (double checkmark, gray)
7. Notification appears: "New message from Alice"
8. Chat screen shows "Hello, Bob!" with timestamp
9. Message displayed correctly, decryption successful
10. Alice's device shows "Read" status (double checkmark, blue)

**Pass Criteria:**
- Message encryption <5ms
- BLE transmission <2s
- Message decryption successful on Bob's device
- Delivery and read receipts work correctly
- No message loss or corruption

---

#### TC-FUNC-021: Send Text Message (Relay)

**Requirements:** FR-MSG-SEND-002, FR-RELAY-001, US-020  
**Priority:** P0  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- Alice and Bob are verified contacts
- Both devices have internet connectivity
- Relay server enabled in settings
- Devices not in BLE/WiFi range

**Test Steps:**
1. Alice opens chat with Bob
2. Alice types message: "Message via relay"
3. Alice taps Send button
4. Observe message routed to relay
5. Wait for relay server to forward message
6. On Bob's device, observe app polls relay
7. Observe message received via relay
8. Bob opens chat with Alice
9. Observe message displayed

**Expected Results:**
1. Chat screen opens
2. Message typed successfully
3. Message sent, status "Sending..."
4. Network log shows UDP packet to relay server
5. Relay processes message within 100ms
6. Bob's app polls relay (within 30s or immediately if app open)
7. Message downloaded from relay, decrypted
8. Chat opens with Alice
9. Message displayed: "Message via relay"

**Pass Criteria:**
- Relay transmission <500ms (good internet)
- End-to-end encryption maintained (relay cannot read)
- Message queued if Bob offline
- Fallback to relay works automatically

---

#### TC-FUNC-022: Send File Attachment (WiFi Direct)

**Requirements:** FR-MSG-SEND-003, FR-WIFI-001, US-020  
**Priority:** P1  
**Type:** Functional  
**Platform:** Android only  
**Automation:** No

**Preconditions:**
- Alice and Bob are verified contacts (Android devices)
- Both devices have WiFi enabled
- Devices in WiFi Direct range
- File available for sending (5 MB image)

**Test Steps:**
1. Alice opens chat with Bob
2. Alice taps attachment button
3. Alice selects "Photo" from gallery
4. Alice selects 5 MB image file
5. Alice taps Send
6. Observe WiFi Direct negotiation via BLE
7. Observe WiFi Direct group formed
8. Observe file transfer progress
9. Observe file transfer complete
10. On Bob's device, observe file received
11. Bob taps file to open
12. Verify file integrity (image displays correctly)

**Expected Results:**
1. Chat screen opens
2. Attachment picker opens (Photo, File, Camera options)
3. Gallery opens, shows photos
4. Image selected, thumbnail shown in chat
5. Send button tapped, file encryption begins
6. BLE control messages exchanged (<5s)
7. Bob's device creates WiFi group, Alice joins (~10s)
8. Progress bar shows transfer (5 MB at ~8 MB/s = ~1s)
9. Transfer complete, WiFi group terminated
10. Notification: "New file from Alice", file decrypted
11. System file viewer opens
12. Image displayed correctly, no corruption

**Pass Criteria:**
- WiFi Direct setup <15s total
- File transfer speed >5 MB/s
- End-to-end encryption maintained
- File integrity verified (SHA256 hash)
- Graceful fallback to BLE if WiFi fails

---

#### TC-FUNC-023: Receive Message While Offline

**Requirements:** FR-MSG-RECV-002, US-021  
**Priority:** P0  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- Alice and Bob are verified contacts
- Alice's device offline (airplane mode)
- Bob has internet connectivity
- Relay server enabled

**Test Steps:**
1. Alice enables airplane mode
2. Bob sends message to Alice: "Are you there?"
3. Observe message queued on relay server
4. Wait 5 minutes (simulate offline period)
5. Alice disables airplane mode
6. Alice opens Ya OK app
7. Observe app polls relay server
8. Observe message downloaded
9. Observe notification displayed
10. Alice opens chat with Bob
11. Verify message received correctly

**Expected Results:**
1. Alice's device disconnected from all networks
2. Bob's message sent via relay (no direct route available)
3. Relay server queues message for Alice (stored for up to 7 days)
4. Time passes, relay retains message
5. Alice reconnects to WiFi/cellular
6. App launches, automatic relay poll triggered
7. HTTP request to relay server, downloads pending messages
8. Message decrypted successfully
9. Notification: "New message from Bob"
10. Chat screen shows message
11. Message content: "Are you there?", timestamp correct

**Pass Criteria:**
- Message queued correctly on relay
- Message retained for 7 days
- Automatic polling on network reconnection
- Message integrity maintained during queue period

---

#### TC-FUNC-024: Message Retry on Failure

**Requirements:** FR-MSG-SEND-004, US-022  
**Priority:** P1  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- Alice and Bob are contacts
- Network connectivity unstable (simulated)

**Test Steps:**
1. Alice opens chat with Bob
2. Alice types message: "Test retry"
3. Simulate network failure (disconnect WiFi, disable relay)
4. Alice taps Send
5. Observe send failure
6. Observe automatic retry
7. Restore network connectivity
8. Observe automatic retry succeeds
9. Verify message delivered

**Expected Results:**
1. Chat screen opens
2. Message input successful
3. Network unavailable (airplane mode or simulated)
4. Send attempt fails immediately
5. Message status: "Failed" (red exclamation mark)
6. Retry attempt after 2s, 4s, 8s (exponential backoff)
7. Network available again
8. Next retry succeeds, message sent via relay
9. Message status: "Delivered"

**Pass Criteria:**
- Retry policy: 3 attempts with exponential backoff
- Eventual success when network restored
- User can manually retry (tap failed message)
- No message duplication

---

### 4.4 Transport Layer

#### TC-FUNC-030: BLE Peer Discovery

**Requirements:** FR-BLE-001, FR-BLE-002  
**Priority:** P0  
**Type:** Functional  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- Alice and Bob both have Bluetooth enabled
- Devices within BLE range (<10m)
- Bob is in Alice's contact list

**Test Steps:**
1. Alice opens Ya OK app
2. Navigate to "Nearby Devices" (or automatic discovery)
3. Observe BLE scanning starts
4. Bob opens Ya OK app (within range)
5. Observe Bob's device advertising
6. Observe Alice discovers Bob
7. Observe GATT connection established
8. Verify identity exchange
9. Observe routing table updated

**Expected Results:**
1. App launches successfully
2. Discovery screen shows "Scanning..." indicator
3. BLE scan initiated (visible in device Bluetooth settings)
4. Bob's device starts BLE advertisement
5. Alice's device detects Bob's advertisement (<5s)
6. Discovered device shown in list: "Bob (BLE)"
7. GATT connection established (<2s)
8. Identity characteristic read, Bob's identity verified against contacts
9. Routing table: Bob → BLE Direct (preferred route)

**Pass Criteria:**
- Discovery time <5s
- GATT connection reliable
- Identity verification successful
- Unknown devices ignored (privacy)

---

#### TC-FUNC-031: WiFi Direct Group Formation

**Requirements:** FR-WIFI-001, FR-WIFI-002  
**Priority:** P1  
**Type:** Functional  
**Platform:** Android only  
**Automation:** No

**Preconditions:**
- Alice and Bob are contacts (Android devices)
- Both have WiFi enabled
- Devices in range
- BLE connection established (for negotiation)

**Test Steps:**
1. Alice needs to send large file (10 MB)
2. System detects large message
3. Observe WiFi Direct request sent via BLE
4. On Bob's device, observe WiFi Direct prompt
5. Bob accepts
6. Observe Bob creates WiFi Direct group
7. Observe group info sent to Alice via BLE
8. Alice joins WiFi Direct group
9. Observe TCP connection established
10. File transfer begins
11. Transfer completes, group terminated

**Expected Results:**
1. File selected for sending
2. Logic determines WiFi Direct optimal for large file
3. BLE control message: "WIFI_DIRECT_REQUEST"
4. Notification/dialog: "Alice wants to connect via WiFi Direct"
5. Bob taps "Accept"
6. Group creation successful, SSID and passphrase generated
7. BLE message: "WIFI_INFO" with credentials
8. Alice connects to group, obtains IP address
9. TCP socket connection: Alice (client) → Bob (server, port 8765)
10. File transferred at ~8 MB/s
11. Transfer complete, WiFi Direct group removed, normal WiFi restored

**Pass Criteria:**
- Group formation <10s
- Throughput >5 MB/s
- No data loss or corruption
- Normal WiFi restored after transfer

---

#### TC-FUNC-032: Relay Server Registration

**Requirements:** FR-RELAY-001  
**Priority:** P1  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- User logged in
- Internet connectivity available
- Relay server URL configured

**Test Steps:**
1. Navigate to Settings → Relay
2. Toggle "Use Relay Server" on
3. Observe registration packet sent
4. Observe registration success
5. Verify registration status displayed
6. Send heartbeat (wait 60s)
7. Observe heartbeat sent
8. Disable relay
9. Observe unregistration packet sent

**Expected Results:**
1. Relay settings screen opens
2. Toggle switched to ON
3. UDP packet sent to relay.yaok.app:41641
4. Relay responds with REGISTERED + session token
5. Status indicator: "🟢 Connected to relay"
6. Automatic heartbeat after 60s
7. UDP PING sent, PONG received
8. Toggle switched to OFF
9. UNREGISTER packet sent to relay

**Pass Criteria:**
- Registration successful within 1s
- Heartbeat maintains connection
- Automatic re-registration on network change
- Graceful unregistration

---

### 4.5 Settings

#### TC-FUNC-040: Change Display Name

**Requirements:** FR-SETTINGS-001  
**Priority:** P2  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- User logged in
- Current display name: "Alice"

**Test Steps:**
1. Navigate to Settings → Profile
2. Tap "Display Name"
3. Clear existing name
4. Enter new name: "Alice Smith"
5. Tap "Save"
6. Observe confirmation
7. Exit settings
8. Verify display name updated in UI
9. Export QR code
10. Verify QR code contains new name

**Expected Results:**
1. Profile settings screen opens
2. Edit dialog shown, pre-filled with "Alice"
3. Field cleared successfully
4. New name entered, character counter shows 11/64
5. Save button enabled and tapped
6. Success message: "Display name updated"
7. Returns to main screen
8. Navigation drawer/profile shows "Alice Smith"
9. QR code generated with new name
10. Decoded QR contains display_name: "Alice Smith"

**Pass Criteria:**
- Name persisted correctly
- QR code regenerated automatically
- Contacts see updated name on next peer discovery
- Max length enforced (64 characters)

---

#### TC-FUNC-041: Configure Auto-Lock Timeout

**Requirements:** FR-AUTH-003, US-051  
**Priority:** P1  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- User logged in
- PIN authentication enabled

**Test Steps:**
1. Navigate to Settings → Security → Auto-Lock
2. Observe current setting: "Immediate"
3. Select "After 5 minutes"
4. Exit settings
5. Background app
6. Wait 4 minutes
7. Reopen app
8. Verify app NOT locked (still within 5 min window)
9. Background app again
10. Wait 2 more minutes (total 6 minutes)
11. Reopen app
12. Verify app IS locked, PIN prompt shown

**Expected Results:**
1. Auto-Lock settings screen
2. Current selection: "Immediate" (highlighted)
3. New selection: "After 5 minutes"
4. Returns to Security settings
5. App sent to background
6. Time elapsed: 4 minutes
7. App resumes without PIN prompt
8. Main screen displayed immediately
9. App backgrounded again
10. Time elapsed: 6 minutes total (exceeds 5 min threshold)
11. App resumes, shows PIN lock screen
12. PIN prompt displayed, numeric keypad visible

**Pass Criteria:**
- Timeout setting persisted
- Lock enforced at correct time
- Timer resets on user activity
- Background time tracked accurately

---

### 4.6 Error Handling

#### TC-FUNC-050: Handle Decryption Failure

**Requirements:** FR-MSG-RECV-004  
**Priority:** P0  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- Alice logged in
- Bob sends message to Alice
- Message tampered in transit (simulated)

**Test Steps:**
1. Alice's device receives message packet
2. System attempts signature verification
3. Signature passes (not tampered with signing key)
4. System attempts decryption
5. Decryption fails (authentication tag mismatch)
6. Observe security event logged
7. Observe message dropped
8. Observe NO notification to user (first failure)
9. Simulate 3 more decryption failures from Bob (within 24h)
10. Observe security alert shown

**Expected Results:**
1. Encrypted packet received via BLE/WiFi/Relay
2. Signature verification step executed
3. Ed25519 signature valid (sender = Bob)
4. XChaCha20-Poly1305 decryption attempted
5. AEAD authentication fails, Error: DecryptionFailed
6. Security log entry created with timestamp, sender, packet hash
7. Message not stored in database
8. No user notification (silent drop)
9. Additional failures simulated
10. Alert dialog: "Multiple decryption failures from Bob. Verify safety number."

**Pass Criteria:**
- Single failure handled silently
- Multiple failures trigger alert
- Security log created for audit
- No crash or data corruption

---

#### TC-FUNC-051: Handle Network Interruption During Send

**Requirements:** FR-MSG-SEND-004  
**Priority:** P1  
**Type:** Functional  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- Alice logged in
- Bob is contact (out of BLE range)
- Network connectivity available (relay)

**Test Steps:**
1. Alice sends message to Bob
2. Message begins sending via relay
3. Disconnect network mid-transmission
4. Observe send failure
5. Observe message status: "Failed"
6. Observe retry scheduled
7. Restore network connectivity
8. Observe automatic retry
9. Observe message sent successfully
10. Verify Bob receives message

**Expected Results:**
1. Message encrypted and queued
2. UDP packet sent to relay server
3. Network disconnected (simulate via airplane mode)
4. Send error: NetworkUnavailable
5. Message UI shows red exclamation mark
6. Retry timer started (2s delay)
7. Network back online
8. Retry triggered, message sent
9. Status updated: "Delivered"
10. Bob's device receives and decrypts message

**Pass Criteria:**
- Retry policy followed (3 attempts, exponential backoff)
- Message not lost during failure
- Automatic retry on network restoration
- User can manually retry

---

#### TC-FUNC-052: Handle Storage Full

**Requirements:** FR-PERSIST-003  
**Priority:** P1  
**Type:** Functional  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- Device storage nearly full (<10 MB free)
- User has 9,900 messages stored (near 10,000 limit)

**Test Steps:**
1. Receive new message from Bob
2. Observe storage check
3. Observe automatic message pruning triggered
4. Oldest 100 messages deleted
5. New message stored successfully
6. Verify notification shown to user
7. Navigate to settings → Storage
8. Observe storage usage stats
9. Tap "Clear Old Messages"
10. Observe confirmation dialog
11. Confirm deletion
12. Verify oldest messages deleted

**Expected Results:**
1. Message received and decrypted
2. Storage limit check: 9,900 / 10,000 messages
3. Pruning logic activated
4. Oldest 100 messages removed from database
5. New message inserted, total: 9,801 messages
6. Notification: "Storage nearly full. Cleared old messages."
7. Storage settings screen shows: "9,801 messages, 234 MB"
8. "Clear Old Messages" button visible
9. Dialog: "Delete messages older than 30 days?"
10. User confirms
11. Messages older than 30 days deleted
12. Message count reduced accordingly

**Pass Criteria:**
- Automatic pruning prevents storage full errors
- Oldest messages deleted first (FIFO)
- User notified of automatic cleanup
- Manual cleanup option available

---

## 5. Security Test Cases

### 5.1 Authentication

#### TC-SEC-001: PIN Authentication - Correct PIN

**Requirements:** REQ-AUTH-001, REQ-AUTH-002  
**Priority:** P0  
**Type:** Security  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- PIN set: "1234"
- App locked

**Test Steps:**
1. Launch app
2. Observe PIN prompt
3. Enter correct PIN: "1234"
4. Tap "Unlock"
5. Observe authentication successful
6. Verify keystore unlocked
7. Verify app unlocked

**Expected Results:**
1. App launches, shows lock screen
2. PIN entry screen with numeric keypad
3. PIN entered (masked as dots)
4. Unlock button tapped
5. PIN verified: PBKDF2(1234, salt) == stored_hash
6. Keystore accessible, cryptographic operations enabled
7. Main screen displayed

**Pass Criteria:**
- Authentication successful
- Keystore unlocked
- No PIN visible in logs or memory dumps

---

#### TC-SEC-002: PIN Authentication - Incorrect PIN

**Requirements:** REQ-AUTH-002, REQ-AUTH-003  
**Priority:** P0  
**Type:** Security  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- PIN set: "1234"
- App locked
- Failed attempts: 0

**Test Steps:**
1. Launch app
2. Enter incorrect PIN: "9999"
3. Tap "Unlock"
4. Observe authentication failed
5. Observe error message
6. Observe failed attempt counter incremented
7. Verify app remains locked
8. Verify keystore remains locked

**Expected Results:**
1. Lock screen displayed
2. PIN entered
3. Unlock attempted
4. PIN verification failed: hash mismatch
5. Error: "Incorrect PIN. 4 attempts remaining."
6. Failed attempts: 0 → 1
7. Lock screen still displayed
8. Keystore inaccessible

**Pass Criteria:**
- Authentication denied
- Attempt counter incremented
- Error message displayed
- Keystore remains secure

---

#### TC-SEC-003: PIN Authentication - Brute Force Protection

**Requirements:** REQ-AUTH-003  
**Priority:** P0  
**Type:** Security  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- PIN set: "1234"
- App locked

**Test Steps:**
1. Enter incorrect PIN: "0000"
2. Observe error: "4 attempts remaining"
3. Enter incorrect PIN: "1111"
4. Observe error: "3 attempts remaining"
5. Enter incorrect PIN: "2222"
6. Observe error: "2 attempts remaining"
7. Enter incorrect PIN: "3333"
8. Observe error: "1 attempt remaining"
9. Enter incorrect PIN: "4444"
10. Observe lockout triggered
11. Observe countdown timer: 30 seconds
12. Attempt to enter PIN during lockout
13. Verify input disabled
14. Wait 30 seconds
15. Verify input re-enabled
16. Enter correct PIN: "1234"
17. Observe authentication successful

**Expected Results:**
1. Authentication failed
2. Error displayed with remaining attempts
3. Authentication failed again
4. Error updated
5. Authentication failed (attempt 3/5)
6. Error updated
7. Authentication failed (attempt 4/5)
8. Error updated
9. Authentication failed (attempt 5/5)
10. Lockout activated, error: "Too many attempts. Try again in 30 seconds."
11. Countdown displayed: 30, 29, 28, ...
12. PIN entry attempted
13. Keypad disabled, no input accepted
14. Timer reaches 0
15. Keypad re-enabled, attempts reset to 0
16. Correct PIN entered
17. Authentication successful, app unlocked

**Pass Criteria:**
- Lockout after 5 failed attempts
- 30-second lockout duration
- Input disabled during lockout
- Counter resets after successful authentication
- No way to bypass lockout

---

#### TC-SEC-004: Biometric Authentication - Success

**Requirements:** REQ-AUTH-004  
**Priority:** P0  
**Type:** Security  
**Platform:** Both  
**Automation:** Partial (biometric simulation)

**Preconditions:**
- Biometric authentication enabled
- Device has enrolled fingerprint/Face ID
- App locked

**Test Steps:**
1. Launch app
2. Observe biometric prompt
3. Present enrolled fingerprint/face
4. Observe biometric authentication successful
5. Verify app unlocked
6. Verify keystore unlocked

**Expected Results:**
1. Lock screen shows biometric prompt
2. System biometric dialog: "Unlock Ya OK"
3. User presents biometric
4. System validates biometric, returns success
5. App unlocked immediately
6. Keystore accessible via biometric token

**Pass Criteria:**
- Biometric authentication successful
- No PIN required if biometric succeeds
- Keystore unlocked
- Faster than PIN (no typing required)

---

#### TC-SEC-005: Biometric Authentication - Failure, Fallback to PIN

**Requirements:** REQ-AUTH-004  
**Priority:** P0  
**Type:** Security  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- Biometric authentication enabled
- App locked

**Test Steps:**
1. Launch app
2. Observe biometric prompt
3. Present unenrolled fingerprint (or fail face recognition)
4. Observe biometric authentication failed
5. Tap "Use PIN" button
6. Enter correct PIN: "1234"
7. Observe authentication successful

**Expected Results:**
1. Biometric prompt displayed
2. System biometric dialog shown
3. Biometric presented, system rejects
4. Error: "Biometric not recognized"
5. Biometric dialog dismissed, PIN entry shown
6. PIN entered and verified
7. App unlocked via PIN fallback

**Pass Criteria:**
- Biometric failure doesn't lock out app
- PIN fallback available
- Authentication successful via PIN
- User experience smooth (no frustration)

---

### 5.2 Cryptography

#### TC-SEC-010: Message Encryption - Integrity

**Requirements:** REQ-CRYPTO-001, REQ-CRYPTO-002  
**Priority:** P0  
**Type:** Security  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- Alice and Bob are contacts
- Test message: "Secret message"

**Test Steps:**
1. Alice sends message to Bob
2. Intercept encrypted packet (test environment)
3. Verify packet structure
4. Verify nonce uniqueness (collect 100 messages)
5. Verify ciphertext differs from plaintext
6. Attempt to decrypt without key
7. Verify decryption fails
8. Bob receives and decrypts message
9. Verify plaintext matches original

**Expected Results:**
1. Message encrypted successfully
2. Packet captured: nonce (24 bytes), ciphertext, tag (16 bytes)
3. Packet format matches specification
4. All 100 nonces unique (no repeats)
5. Ciphertext looks random, no patterns
6. Decryption without key fails (authentication tag mismatch)
7. Error: DecryptionFailed
8. Bob decrypts with correct key
9. Plaintext: "Secret message"

**Pass Criteria:**
- XChaCha20-Poly1305 AEAD used
- Nonces never repeat (192-bit random nonces)
- Ciphertext is indistinguishable from random
- Decryption without key impossible
- Authentication tag prevents tampering

---

#### TC-SEC-011: Message Signature Verification

**Requirements:** REQ-CRYPTO-003  
**Priority:** P0  
**Type:** Security  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- Alice and Bob are contacts
- Test message: "Signed message"

**Test Steps:**
1. Alice sends message to Bob
2. Extract signature from packet
3. Verify signature format (64 bytes, Ed25519)
4. Verify signature with Alice's verify key
5. Modify message content (flip one bit)
6. Re-verify signature
7. Observe verification fails
8. Replace signature with invalid data
9. Verify signature verification fails

**Expected Results:**
1. Message signed successfully
2. Signature extracted: 64 bytes
3. Signature format valid
4. Ed25519 verification: Success (signature valid for message + Alice's signing key)
5. Message tampered: 1 bit flipped
6. Signature verification attempted
7. Verification fails (signature doesn't match modified message)
8. Signature replaced with random 64 bytes
9. Verification fails (invalid signature)

**Pass Criteria:**
- Ed25519 signatures used
- Signature verification successful for valid messages
- Tampering detected immediately
- Invalid signatures rejected

---

#### TC-SEC-012: Key Exchange - Forward Secrecy

**Requirements:** REQ-KEY-005  
**Priority:** P1  
**Type:** Security  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- Alice and Bob are contacts
- Multiple messages exchanged

**Test Steps:**
1. Alice sends message 1 to Bob
2. Extract shared secret (simulated - in secure environment)
3. Alice sends message 2 to Bob
4. Verify shared secret different from message 1
5. Compromise Alice's long-term private key (simulated)
6. Attempt to decrypt previous messages (1 and 2)
7. Verify decryption fails (no forward secrecy in current implementation)
8. Note: Forward secrecy requires ephemeral keys (future enhancement)

**Expected Results:**
1. Message encrypted with X25519 ECDH shared secret
2. Shared secret derived from Alice's secret key + Bob's public key
3. Message 2 encrypted
4. Shared secret SAME (static ECDH, no ephemeral keys)
5. Private key compromised (test scenario)
6. Decryption successful (no forward secrecy)
7. All messages decryptable with compromised key
8. Future enhancement: Implement Double Ratchet (Signal Protocol)

**Pass Criteria:**
- Current: X25519 ECDH working correctly
- Known limitation: No forward secrecy (documented)
- Future: Implement ephemeral keys, ratcheting

**Note:** This test documents current behavior. Forward secrecy is a P1 enhancement for v1.1.

---

### 5.3 Key Management

#### TC-SEC-020: Key Storage - Hardware-Backed

**Requirements:** REQ-KEY-001, REQ-KEY-002  
**Priority:** P0  
**Type:** Security  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- Device supports hardware keystore (Android Keystore/iOS Keychain)

**Test Steps:**
1. Generate identity keys
2. Verify keys stored in hardware keystore
3. Attempt to export keys programmatically
4. Verify export fails (keys non-exportable)
5. Attempt to access keys without authentication
6. Verify access denied
7. Authenticate (PIN/biometric)
8. Attempt to access keys
9. Verify access granted
10. Use keys for cryptographic operation
11. Verify operation successful

**Expected Results:**
1. Key generation successful
2. Android: Keys in Android Keystore (inspect via `adb shell`), iOS: Keys in Keychain (inspect via Keychain Access on Mac after backup)
3. Key export API called
4. Error: KeyNotExportable
5. Cryptographic operation attempted without auth
6. Error: KeystoreLocked
7. User authenticates via PIN
8. Cryptographic operation attempted
9. Access granted, keys available
10. Sign operation successful
11. Signature generated

**Pass Criteria:**
- Keys stored in hardware-backed keystore
- Keys non-exportable (FLAG_NON_EXPORTABLE on Android, kSecAttrIsExtractable=false on iOS)
- Authentication required for key access
- Keys never in app memory as plaintext

---

#### TC-SEC-021: Key Rotation

**Requirements:** REQ-KEY-006  
**Priority:** P2  
**Type:** Security  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- Alice has identity keys (1 year old)
- Alice has 10 contacts

**Test Steps:**
1. Navigate to Settings → Security → Rotate Keys
2. Observe warning dialog
3. Confirm key rotation
4. Observe new keys generated
5. Observe old keys archived
6. Export new QR code
7. Verify QR code contains new keys
8. Notify all contacts of key change
9. Contacts re-add Alice with new QR
10. Verify messages with new keys work

**Expected Results:**
1. Key rotation option visible
2. Warning: "This will invalidate your current identity. All contacts must re-add you."
3. User confirms
4. New X25519 + Ed25519 keys generated
5. Old keys moved to archive (not deleted yet, for message decryption)
6. QR code regenerated
7. Decoded QR has new public keys
8. Manual notification (Alice sends message or shares QR again)
9. Contacts scan new QR, update Alice's keys
10. Messages encrypted with new keys, decryption successful

**Pass Criteria:**
- Key rotation successful
- Old keys archived (for decrypting old messages)
- New keys used for future messages
- Contacts notified (manual process for now)

---

### 5.4 Data Protection

#### TC-SEC-030: Database Encryption

**Requirements:** REQ-DATA-001  
**Priority:** P0  
**Type:** Security  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- App installed with data
- Messages and contacts stored

**Test Steps:**
1. Close app completely
2. Access device file system (rooted/jailbroken device or emulator)
3. Navigate to app database directory
4. Locate database file (e.g., `yaok.db`)
5. Attempt to open database with SQLite browser
6. Verify database encrypted (cannot read)
7. Extract encryption key attempt (without keystore access)
8. Verify key extraction fails
9. Open database with correct key (from keystore)
10. Verify database readable with key

**Expected Results:**
1. App closed, background process terminated
2. File system accessible (test environment)
3. Database file found at `/data/data/app.yaok/databases/yaok.db` (Android)
4. File size non-zero (has data)
5. SQLite browser reports: "File is encrypted or is not a database"
6. Database unreadable without key
7. Key extraction attempted via keystore API without authentication
8. Error: KeystoreLocked or KeyNotFound
9. Keystore unlocked with PIN, key retrieved, database opened
10. Messages and contacts readable

**Pass Criteria:**
- Database encrypted at rest (SQLCipher AES-256)
- Encryption key stored in hardware keystore
- Database unreadable without key
- Key not extractable without authentication

---

#### TC-SEC-031: Secure Deletion

**Requirements:** REQ-DATA-004  
**Priority:** P1  
**Type:** Security  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- User has 100 messages with Bob
- User decides to delete conversation

**Test Steps:**
1. Open chat with Bob
2. Tap "Delete Conversation"
3. Confirm deletion
4. Observe messages deleted from database
5. Close app
6. Access device file system
7. Run forensic recovery tool (e.g., Recuva, PhotoRec)
8. Scan for deleted SQLite records
9. Verify deleted messages not recoverable
10. Inspect database file with hex editor
11. Verify no message content visible

**Expected Results:**
1. Chat screen displayed
2. Delete option selected
3. User confirms
4. DELETE query executed with PRAGMA secure_delete = ON
5. App closed
6. File system accessed (test environment)
7. Recovery tool scans free space
8. No message content recovered (overwritten with zeros)
9. Deleted data not recoverable
10. Database file examined at binary level
11. No plaintext message fragments found

**Pass Criteria:**
- Secure deletion enabled (`PRAGMA secure_delete = ON`)
- Deleted data overwritten, not just marked as deleted
- Forensic recovery impossible
- No data leakage in temp files or journals

---

#### TC-SEC-032: Memory Scrubbing

**Requirements:** REQ-DATA-005  
**Priority:** P1  
**Type:** Security  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- App running with decrypted message in memory

**Test Steps:**
1. Alice opens chat with Bob
2. Decrypt and display message: "Secret info"
3. Navigate away from chat
4. Trigger memory scrubbing (message leaves screen)
5. Capture memory dump (debug build)
6. Search memory dump for "Secret info"
7. Verify plaintext not found in memory
8. Search for encryption keys
9. Verify keys not found (only in keystore)

**Expected Results:**
1. Chat opened, message loaded
2. Message decrypted, plaintext in memory temporarily
3. User navigates to different screen
4. Rust core zeroizes message memory, Kotlin/Swift clears references
5. Memory dump captured (test environment)
6. Hex search performed
7. No plaintext message content found
8. Key search performed
9. No key material found (keys only in hardware keystore)

**Pass Criteria:**
- Plaintext cleared from memory after use
- Keys never in app memory (only keystore references)
- Rust `zeroize` crate used for sensitive data
- No sensitive data in crash dumps

---

## 6. Performance Test Cases

### 6.1 Latency

#### TC-PERF-001: Message Encryption Latency

**Requirements:** NFR-PERF-001  
**Priority:** P0  
**Type:** Performance  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- App running on device (not emulator)
- Test message sizes: 100 bytes, 1 KB, 10 KB, 100 KB

**Test Steps:**
1. Prepare test messages of varying sizes
2. For each message size:
   a. Start timer
   b. Encrypt message
   c. Stop timer
   d. Record encryption time
3. Repeat 100 times per message size
4. Calculate average, min, max, p95, p99
5. Verify latency targets met

**Expected Results:**
- 100 bytes: avg <2ms, max <5ms
- 1 KB: avg <3ms, max <10ms
- 10 KB: avg <15ms, max <30ms
- 100 KB: avg <50ms, max <100ms

**Pass Criteria:**
- 100 bytes: <5ms (P0 requirement)
- 1 KB: <10ms
- 10 KB: <30ms
- 100 KB: <100ms
- No outliers >2x average (performance consistency)

---

#### TC-PERF-002: Message Send Latency (BLE)

**Requirements:** NFR-PERF-002  
**Priority:** P0  
**Type:** Performance  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- Two devices with BLE connection established
- Message size: 100 bytes (typical text message)

**Test Steps:**
1. Alice sends message to Bob
2. Start timer when Alice taps "Send"
3. Stop timer when Bob receives notification
4. Measure end-to-end latency
5. Repeat 50 times
6. Calculate statistics

**Expected Results:**
- Average latency: <200ms
- p95 latency: <500ms
- Max latency: <1000ms

**Pass Criteria:**
- Average <200ms
- p95 <500ms
- Consistent performance (no outliers >2s)

**Breakdown:**
- Encryption: <5ms
- UI update: <10ms
- BLE transmission: <100ms
- Decryption: <5ms
- Notification: <50ms
- Total: ~170ms typical

---

#### TC-PERF-003: App Startup Time

**Requirements:** NFR-PERF-004  
**Priority:** P1  
**Type:** Performance  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- App not running (cold start)
- Device not under heavy load

**Test Steps:**
1. Kill app completely
2. Clear from recent apps
3. Start timer
4. Tap app icon
5. Stop timer when lock screen displayed (if locked) or main screen (if not locked)
6. Repeat 20 times
7. Calculate statistics

**Expected Results:**
- Cold start (to lock screen): <2s average
- Cold start (unlocked): <2.5s average
- Warm start: <1s

**Pass Criteria:**
- Cold start <2s (P1 requirement)
- Warm start <1s
- No ANR (Application Not Responding) errors

**Breakdown:**
- OS launch: ~500ms
- Rust init: ~300ms
- Database open: ~200ms
- UI render: ~500ms
- Total: ~1.5s typical

---

### 6.2 Throughput

#### TC-PERF-010: BLE Throughput

**Requirements:** NFR-PERF-005  
**Priority:** P1  
**Type:** Performance  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- Two devices with BLE connection
- MTU negotiated to maximum (512 bytes)

**Test Steps:**
1. Prepare 1 MB test message
2. Start transfer timer
3. Send message via BLE
4. Stop timer when transfer complete
5. Calculate throughput (bytes/second)
6. Repeat 10 times
7. Calculate average throughput

**Expected Results:**
- Throughput: 40-60 KB/s average
- Transfer time for 1 MB: 17-25 seconds

**Pass Criteria:**
- Throughput ≥30 KB/s (minimum acceptable)
- No data loss or corruption
- Chunking and reassembly working correctly

---

#### TC-PERF-011: WiFi Direct Throughput

**Requirements:** NFR-PERF-006  
**Priority:** P1  
**Type:** Performance  
**Platform:** Android only  
**Automation:** No

**Preconditions:**
- Two Android devices
- WiFi Direct group established
- TCP connection active

**Test Steps:**
1. Prepare 50 MB test file
2. Start transfer timer
3. Send file via WiFi Direct
4. Stop timer when transfer complete
5. Calculate throughput
6. Verify file integrity (SHA256 hash)
7. Repeat 5 times

**Expected Results:**
- Throughput: 5-10 MB/s average
- Transfer time for 50 MB: 5-10 seconds
- File integrity: 100% match

**Pass Criteria:**
- Throughput ≥5 MB/s (P1 requirement)
- No data corruption
- Faster than BLE by at least 100x

---

### 6.3 Resource Usage

#### TC-PERF-020: Memory Usage

**Requirements:** NFR-PERF-007  
**Priority:** P1  
**Type:** Performance  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- App running with 1,000 messages
- 50 contacts

**Test Steps:**
1. Launch app
2. Measure memory usage (baseline)
3. Open chat with message history
4. Scroll through 100 messages
5. Measure memory usage (peak)
6. Close chat, return to main screen
7. Measure memory usage (after cleanup)
8. Repeat for different chats
9. Calculate average memory usage

**Expected Results:**
- Baseline: <150 MB
- Peak (chat open): <200 MB
- After cleanup: <160 MB (memory released)

**Pass Criteria:**
- Total memory <200 MB
- No memory leaks (memory released after closing chat)
- Memory growth linear, not exponential

---

#### TC-PERF-021: Battery Usage

**Requirements:** NFR-PERF-008  
**Priority:** P1  
**Type:** Performance  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- Device fully charged
- App running in background
- No active message transfers

**Test Steps:**
1. Charge device to 100%
2. Disconnect from charger
3. Enable Ya OK, leave in background
4. Monitor battery drain over 24 hours
5. Record battery percentage every hour
6. Calculate battery drain rate

**Expected Results:**
- Battery drain: <2% per hour (idle)
- Battery drain: <5% per hour (active messaging)
- BLE scanning: adaptive intervals (5s active, 30s idle)

**Pass Criteria:**
- Idle drain <2% per hour
- Active drain <5% per hour
- No battery drain when app killed
- Background polling optimized (15 min intervals on Android, opportunistic on iOS)

---

#### TC-PERF-022: Database Performance

**Requirements:** NFR-PERF-009  
**Priority:** P2  
**Type:** Performance  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- Database with 10,000 messages
- 100 contacts

**Test Steps:**
1. Query: Load last 50 messages for a contact
2. Measure query time
3. Query: Search messages by keyword
4. Measure search time
5. Query: Load all contacts
6. Measure query time
7. Insert: Add new message
8. Measure insert time
9. Repeat 100 times, calculate averages

**Expected Results:**
- Load 50 messages: <20ms
- Search messages: <100ms
- Load 100 contacts: <50ms
- Insert message: <10ms

**Pass Criteria:**
- All queries <100ms (P2 requirement)
- Database indexes used effectively
- No full table scans
- SQLite performance optimized

---

## 7. Integration Test Cases

### 7.1 Component Integration

#### TC-INT-001: FFI Layer - Rust ↔ Android

**Requirements:** FR-USER-001, FR-MSG-SEND-001  
**Priority:** P0  
**Type:** Integration  
**Platform:** Android  
**Automation:** Yes

**Preconditions:**
- App running on Android device/emulator
- Rust core compiled for Android target

**Test Steps:**
1. Android UI calls FFI function: `yaok_generate_identity("Alice")`
2. Verify JNI bridge invoked
3. Verify Rust function executed
4. Verify return value passed back to Android
5. Verify error handling (pass invalid data)
6. Verify callbacks work (async operations)

**Expected Results:**
1. JNI bridge invoked successfully
2. JNI wrapper calls Rust function
3. Rust core generates identity, returns result
4. Return value converted to Kotlin type, received by UI
5. Invalid data rejected, error returned to Android
6. Async callback invoked (e.g., message received)

**Pass Criteria:**
- FFI calls succeed
- Data marshaling correct (strings, byte arrays)
- Error handling robust
- No memory leaks at FFI boundary
- Callbacks work reliably

---

#### TC-INT-002: FFI Layer - Rust ↔ iOS

**Requirements:** FR-USER-001, FR-MSG-SEND-001  
**Priority:** P0  
**Type:** Integration  
**Platform:** iOS  
**Automation:** Yes

**Preconditions:**
- App running on iOS device/simulator
- Rust core compiled for iOS target

**Test Steps:**
1. Swift UI calls FFI function: `yaok_generate_identity("Alice")`
2. Verify Swift/C bridge invoked
3. Verify Rust function executed
4. Verify return value passed back to Swift
5. Verify error handling
6. Verify callbacks work

**Expected Results:**
1. Swift/C interop successful
2. C header (generated by cbindgen) used correctly
3. Rust core executes, returns result
4. Return value converted to Swift type
5. Errors handled gracefully
6. Async callbacks invoked

**Pass Criteria:**
- FFI calls succeed
- Data marshaling correct
- Error handling robust
- No memory issues
- Swift → Rust → Swift round-trip works

---

#### TC-INT-003: Crypto ↔ Storage Integration

**Requirements:** FR-PERSIST-001, REQ-DATA-001  
**Priority:** P0  
**Type:** Integration  
**Platform:** Both  
**Automation:** Yes

**Preconditions:**
- App running
- Database initialized

**Test Steps:**
1. Encrypt message with Crypto module
2. Pass encrypted message to Storage module
3. Storage persists message to database
4. Query database for message
5. Storage retrieves encrypted message
6. Pass to Crypto module for decryption
7. Verify plaintext matches original

**Expected Results:**
1. Encryption successful
2. Encrypted data passed correctly (nonce, ciphertext, tag)
3. INSERT query executed, message stored
4. SELECT query executed
5. Encrypted message retrieved
6. Decryption successful
7. Plaintext: original message content

**Pass Criteria:**
- Encryption and storage work together
- No data loss or corruption
- Decryption retrieves original plaintext
- Database encryption (SQLCipher) compatible with message encryption (XChaCha20)

---

### 7.2 System Integration

#### TC-INT-010: End-to-End Message Flow (BLE)

**Requirements:** All messaging requirements  
**Priority:** P0  
**Type:** Integration  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- Two devices (Alice, Bob)
- BLE connection established

**Test Steps:**
1. Alice types message
2. Verify UI → FFI → Rust core flow
3. Verify encryption
4. Verify routing selects BLE transport
5. Verify BLE transmission
6. Verify Bob's device receives via BLE
7. Verify Rust core → FFI → UI flow on Bob's device
8. Verify decryption
9. Verify message displayed
10. Verify read receipt sent back to Alice

**Expected Results:**
1. Message input accepted
2. FFI call made, Rust core invoked
3. Message encrypted
4. Router selects BLE (best available transport)
5. BLE GATT write successful
6. Bob's device BLE callback triggered
7. FFI callback invoked, UI updated
8. Message decrypted
9. Message displayed in chat
10. Read receipt sent, Alice sees "Read" status

**Pass Criteria:**
- Full end-to-end flow works
- All components integrated correctly
- No data loss or errors
- User experience smooth

---

#### TC-INT-011: Multi-Transport Failover

**Requirements:** FR-MSG-SEND-004, FR-ROUTING-001  
**Priority:** P1  
**Type:** Integration  
**Platform:** Both  
**Automation:** Partial

**Preconditions:**
- Alice and Bob are contacts
- Multiple transports configured (BLE, WiFi, Relay)

**Test Steps:**
1. Alice sends message
2. BLE connection fails
3. Verify automatic fallback to WiFi Direct
4. WiFi Direct unavailable (iOS or not in range)
5. Verify automatic fallback to Relay
6. Relay sends message successfully
7. Bob receives via Relay
8. Verify end-to-end delivery

**Expected Results:**
1. Message sent
2. BLE error: PeerDisconnected
3. Router tries WiFi Direct
4. WiFi Direct error: Unavailable
5. Router tries Relay
6. Relay transmission successful
7. Bob polls relay, receives message
8. Message delivered and displayed

**Pass Criteria:**
- Transport failover automatic
- No user intervention required
- Message delivered despite failures
- User only sees "Delivered" status (failures hidden)

---

## 8. Regression Test Suite

### 8.1 Critical Path Tests

**Priority:** All P0 tests must pass before release

| Test ID | Test Name | Platform | Frequency |
|---------|-----------|----------|-----------|
| TC-FUNC-001 | Identity Generation | Both | Every build |
| TC-FUNC-010 | Add Contact (QR) | Both | Every build |
| TC-FUNC-020 | Send Message (BLE) | Both | Every build |
| TC-SEC-001 | PIN Authentication | Both | Every build |
| TC-SEC-010 | Message Encryption | Both | Every build |
| TC-SEC-020 | Key Storage | Both | Every build |
| TC-SEC-030 | Database Encryption | Both | Every build |
| TC-PERF-001 | Encryption Latency | Both | Every release |
| TC-INT-010 | End-to-End Flow | Both | Every release |

### 8.2 Regression Test Execution

**Schedule:**
- **Every Commit**: Unit tests (automated, CI/CD)
- **Every PR**: Integration tests (automated)
- **Nightly**: Full regression suite (automated)
- **Weekly**: Performance tests (automated + manual verification)
- **Pre-Release**: Complete test suite (manual + automated)

---

## 9. Requirements Coverage Matrix

### 9.1 Functional Requirements Coverage

| Requirement ID | Requirement Name | Test Cases | Coverage |
|----------------|------------------|------------|----------|
| FR-USER-001 | Identity Generation | TC-FUNC-001, TC-INT-001, TC-INT-002 | 100% |
| FR-USER-002 | Export Identity | TC-FUNC-002 | 100% |
| FR-CONTACT-001 | Add Contact | TC-FUNC-010 | 100% |
| FR-CONTACT-003 | Verify Contact | TC-FUNC-011 | 100% |
| FR-CONTACT-006 | Delete Contact | TC-FUNC-012 | 100% |
| FR-MSG-SEND-001 | Send Text Message | TC-FUNC-020, TC-FUNC-021, TC-INT-010 | 100% |
| FR-MSG-SEND-002 | Send via Relay | TC-FUNC-021 | 100% |
| FR-MSG-SEND-003 | Send File | TC-FUNC-022 | 100% |
| FR-MSG-SEND-004 | Retry on Failure | TC-FUNC-024, TC-FUNC-051, TC-INT-011 | 100% |
| FR-MSG-RECV-001 | Receive Message | TC-FUNC-020, TC-FUNC-021 | 100% |
| FR-MSG-RECV-002 | Receive Offline | TC-FUNC-023 | 100% |
| FR-MSG-RECV-004 | Handle Decryption Failure | TC-FUNC-050 | 100% |
| FR-BLE-001 | BLE Peer Discovery | TC-FUNC-030 | 100% |
| FR-BLE-002 | BLE Communication | TC-FUNC-020, TC-PERF-010 | 100% |
| FR-WIFI-001 | WiFi Direct Setup | TC-FUNC-031 | 100% |
| FR-WIFI-002 | WiFi Transfer | TC-FUNC-022, TC-PERF-011 | 100% |
| FR-RELAY-001 | Relay Registration | TC-FUNC-032 | 100% |
| FR-AUTH-001 | PIN Setup | TC-FUNC-003 | 100% |
| FR-AUTH-002 | PIN Auth | TC-SEC-001, TC-SEC-002, TC-SEC-003 | 100% |
| FR-AUTH-003 | Auto-Lock | TC-FUNC-041 | 100% |
| FR-AUTH-004 | Biometric Auth | TC-SEC-004, TC-SEC-005 | 100% |
| FR-SETTINGS-001 | Change Display Name | TC-FUNC-040 | 100% |
| FR-PERSIST-001 | Store Messages | TC-INT-003 | 100% |
| FR-PERSIST-003 | Storage Limits | TC-FUNC-052 | 100% |

**Overall Functional Coverage:** 23/23 requirements = **100%**

### 9.2 Security Requirements Coverage

| Requirement ID | Requirement Name | Test Cases | Coverage |
|----------------|------------------|------------|----------|
| REQ-CRYPTO-001 | AEAD Encryption | TC-SEC-010 | 100% |
| REQ-CRYPTO-002 | Nonce Uniqueness | TC-SEC-010 | 100% |
| REQ-CRYPTO-003 | Message Signatures | TC-SEC-011 | 100% |
| REQ-KEY-001 | Hardware Key Storage | TC-SEC-020 | 100% |
| REQ-KEY-002 | Key Non-Exportable | TC-SEC-020 | 100% |
| REQ-KEY-005 | Forward Secrecy | TC-SEC-012 | 50% (documented limitation) |
| REQ-KEY-006 | Key Rotation | TC-SEC-021 | 100% |
| REQ-AUTH-001 | PIN Setup | TC-FUNC-003 | 100% |
| REQ-AUTH-002 | PIN Verification | TC-SEC-001, TC-SEC-002 | 100% |
| REQ-AUTH-003 | Brute Force Protection | TC-SEC-003 | 100% |
| REQ-AUTH-004 | Biometric Auth | TC-SEC-004, TC-SEC-005 | 100% |
| REQ-DATA-001 | Database Encryption | TC-SEC-030 | 100% |
| REQ-DATA-004 | Secure Deletion | TC-SEC-031 | 100% |
| REQ-DATA-005 | Memory Scrubbing | TC-SEC-032 | 100% |

**Overall Security Coverage:** 14/14 requirements (13 fully tested + 1 documented limitation) = **93%**

### 9.3 Performance Requirements Coverage

| Requirement ID | Requirement Name | Test Cases | Coverage |
|----------------|------------------|------------|----------|
| NFR-PERF-001 | Encryption Latency | TC-PERF-001 | 100% |
| NFR-PERF-002 | Message Latency | TC-PERF-002 | 100% |
| NFR-PERF-004 | App Startup | TC-PERF-003 | 100% |
| NFR-PERF-005 | BLE Throughput | TC-PERF-010 | 100% |
| NFR-PERF-006 | WiFi Throughput | TC-PERF-011 | 100% |
| NFR-PERF-007 | Memory Usage | TC-PERF-020 | 100% |
| NFR-PERF-008 | Battery Usage | TC-PERF-021 | 100% |
| NFR-PERF-009 | Database Performance | TC-PERF-022 | 100% |

**Overall Performance Coverage:** 8/8 requirements = **100%**

### 9.4 Overall Requirements Coverage

| Category | Requirements | Tested | Coverage |
|----------|--------------|--------|----------|
| Functional | 23 | 23 | 100% |
| Security | 14 | 13 | 93% |
| Performance | 8 | 8 | 100% |
| **TOTAL** | **45** | **44** | **98%** |

---

## 10. Test Execution Reports

### 10.1 Test Summary Template

```
Test Execution Report

Date: [Date]
Tester: [Name]
Build: [Version]
Platform: [Android API XX / iOS XX.X]
Device: [Model]

Summary:
- Total Test Cases: XX
- Passed: XX
- Failed: XX
- Blocked: XX
- Not Run: XX

Pass Rate: XX%

Critical Issues:
1. [Issue description]
2. ...

Recommendations:
1. [Recommendation]
2. ...
```

### 10.2 Defect Tracking

**Defect Severity:**
- **Critical (P0)**: App crash, data loss, security vulnerability
- **High (P1)**: Feature broken, workaround exists
- **Medium (P2)**: Minor feature issue, cosmetic
- **Low (P3)**: Enhancement, nice-to-have

**Defect States:**
- New → Assigned → In Progress → Fixed → Verified → Closed

### 10.3 Test Metrics

**Tracked Metrics:**
- Test coverage (% requirements covered)
- Test pass rate (% tests passed)
- Defect density (defects per 1000 LOC)
- Mean time to failure (MTTF)
- Test execution time
- Automation coverage (% tests automated)

**Quality Gates:**
- Unit test coverage ≥80%
- Integration test pass rate ≥95%
- No critical defects open
- All P0/P1 tests passed
- Performance benchmarks met

---

## Appendix A: Test Data

### A.1 Test Users

```json
{
  "users": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "display_name": "Alice",
      "pin": "1234",
      "contacts": ["bob", "charlie"]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "display_name": "Bob",
      "pin": "5678",
      "contacts": ["alice"]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "display_name": "Charlie",
      "pin": "9012",
      "contacts": []
    }
  ]
}
```

### A.2 Test Messages

```json
{
  "messages": [
    {
      "type": "short_text",
      "content": "Hello!",
      "size": 6
    },
    {
      "type": "long_text",
      "content": "Lorem ipsum dolor sit amet... (10,000 chars)",
      "size": 10000
    },
    {
      "type": "unicode",
      "content": "👋 Привіт! 你好! مرحبا!",
      "size": 25
    },
    {
      "type": "file",
      "name": "test_image.jpg",
      "size": 5242880,
      "mime": "image/jpeg"
    }
  ]
}
```

---

**Document Classification:** INTERNAL  
**Distribution:** QA Team, Development Team  
**Review Cycle:** Updated on every release

**End of Formal Test Cases Document**
