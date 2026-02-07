# Acceptance Criteria
## Ya OK - Delay-Tolerant Secure Messenger

**Document ID:** YA-OK-AC-001  
**Version:** 1.0  
**Date:** 2026-02-06  
**Status:** APPROVED  
**Classification:** INTERNAL

**Standards Compliance:**
- ISO/IEC 29148:2018 - Requirements engineering
- IEEE 29148-2018 - Systems and software engineering
- Agile Alliance - User Story Format

---

## Document Control

| Version | Date | Author | Changes | Approver |
|---------|------|--------|---------|----------|
| 0.1 | 2026-01-20 | Product + QA | Initial user stories | - |
| 0.5 | 2026-01-30 | QA Team | Acceptance criteria complete | Product Owner |
| 1.0 | 2026-02-06 | QA Team | Final review, test scenarios | CTO |

**Approval Signatures:**
- [ ] Product Owner
- [ ] QA Lead
- [ ] Technical Lead
- [ ] UX Designer

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Epic 1: User Onboarding](#2-epic-1-user-onboarding)
3. [Epic 2: Contact Management](#3-epic-2-contact-management)
4. [Epic 3: Messaging](#4-epic-3-messaging)
5. [Epic 4: Security & Privacy](#5-epic-4-security--privacy)
6. [Epic 5: Multi-Transport Networking](#6-epic-5-multi-transport-networking)
7. [Epic 6: Settings & Configuration](#7-epic-6-settings--configuration)
8. [Epic 7: Diagnostics & Monitoring](#8-epic-7-diagnostics--monitoring)
9. [Success Metrics](#9-success-metrics)
10. [Test Coverage Matrix](#10-test-coverage-matrix)

---

## 1. Introduction

### 1.1 Purpose

This document defines **acceptance criteria** for all user-facing features in Ya OK v1.0. Acceptance criteria are testable conditions that must be met for a feature to be considered complete and ready for release.

**Format:** User stories written in **Given-When-Then** (Gherkin) format for clarity and testability.

**Target Audience:**
- QA team (test case development)
- Product owner (feature acceptance)
- Developers (definition of done)
- Stakeholders (progress tracking)

### 1.2 User Story Format

Each user story follows this structure:

```
**User Story:** [ID] - [Title]
As a [user persona],
I want to [action/feature],
So that [benefit/value].

**Acceptance Criteria:**
Given [precondition/context],
When [action/event],
Then [expected outcome].

**Priority:** P0/P1/P2/P3
**Effort:** [Story points]
**Status:** ✅ Done / ⬜ In Progress / ❌ To Do
**Related Requirements:** [SRS references]
```

### 1.3 Test Scenarios

Each user story includes:
- **Happy path** - Expected normal flow
- **Edge cases** - Boundary conditions
- **Error cases** - Failure scenarios
- **Performance** - Non-functional aspects

### 1.4 Definition of Done

A user story is considered **DONE** when:
- [ ] All acceptance criteria met
- [ ] Unit tests written and passing
- [ ] Integration tests passing (if applicable)
- [ ] E2E test passing (if applicable)
- [ ] Code reviewed and approved
- [ ] Security review complete (for security features)
- [ ] Documentation updated
- [ ] Product owner acceptance
- [ ] No critical bugs

---

## 2. Epic 1: User Onboarding

### 2.1 User Story: US-001 - First Launch Setup

**As a** new user,  
**I want to** set up my account on first launch,  
**So that** I can start using Ya OK to send secure messages.

#### Acceptance Criteria

**AC-001-01: Key Generation**
```gherkin
Given I launch Ya OK for the first time
When the app initializes
Then a unique X25519 keypair is generated automatically
And the private key is stored in the platform keystore (Android Keystore / iOS Keychain)
And a user ID is derived from my public key
And I see a welcome screen
```

**AC-001-02: Display Name Setup**
```gherkin
Given I am on the welcome screen
When I enter my display name "Alice"
And I tap "Next"
Then my display name is saved to my profile
And I proceed to authentication setup
```

**AC-001-03: Display Name Validation**
```gherkin
Given I am on the display name screen
When I enter a name with <2 characters OR >50 characters
And I tap "Next"
Then I see an error message "Name must be 2-50 characters"
And I cannot proceed until I enter a valid name
```

**AC-001-04: QR Code Generation**
```gherkin
Given I have completed setup
When I view my profile
Then I see a QR code containing my public key and display name
And the QR code is scannable by another Ya OK app
```

**Priority:** P0 (Critical)  
**Effort:** 8 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-USER-001-01 through FR-USER-001-05

#### Test Scenarios

**Happy Path:**
1. Launch app → See welcome screen
2. Enter name "Alice" → Tap Next
3. Set up PIN → Tap Done
4. See main screen with empty contact list

**Edge Cases:**
- Enter 1-character name → Error shown
- Enter 51-character name → Error shown
- Enter name with emojis → Accepted
- Rotate device during setup → State preserved

**Error Cases:**
- Keystore unavailable → Show error, retry option
- No storage space → Show error with guidance
- Crash during setup → Resume from last step on restart

**Performance:**
- Key generation completes in <500ms
- Total setup time <2 minutes (90% of users)

---

### 2.2 User Story: US-002 - Authentication Setup

**As a** new user,  
**I want to** set up authentication (PIN or biometric),  
**So that** my messages are protected if someone else accesses my phone.

#### Acceptance Criteria

**AC-002-01: PIN Setup**
```gherkin
Given I am on the authentication setup screen
When I choose "PIN" as my authentication method
And I enter a 6-digit PIN "123456"
And I confirm the PIN "123456"
Then my PIN is saved securely (hashed, not plaintext)
And I am authenticated
And I proceed to the main screen
```

**AC-002-02: PIN Validation**
```gherkin
Given I am setting up a PIN
When I enter a PIN with <6 digits
Then I see an error "PIN must be at least 6 digits"
And I cannot proceed until I enter a valid PIN
```

**AC-002-03: PIN Confirmation Mismatch**
```gherkin
Given I am confirming my PIN
When my confirmation PIN "654321" does not match my original PIN "123456"
Then I see an error "PINs do not match"
And I am prompted to re-enter my PIN
```

**AC-002-04: Biometric Setup**
```gherkin
Given I am on the authentication setup screen
And my device supports biometric authentication (fingerprint/Face ID)
When I choose "Biometric" as my authentication method
Then the system prompts me to authenticate with biometric
And if successful, biometric auth is enabled
And I proceed to the main screen
```

**AC-002-05: Skip Authentication (Optional)**
```gherkin
Given I am on the authentication setup screen
When I tap "Skip" (if feature implemented)
Then I see a warning "Your messages will not be protected"
And if I confirm, I proceed without authentication
```

**Priority:** P1 (High)  
**Effort:** 5 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-USER-001-06 through FR-USER-001-08, NFR-SEC-040

#### Test Scenarios

**Happy Path:**
1. Choose PIN → Enter "123456" → Confirm "123456" → Success
2. Choose Biometric → Scan fingerprint → Success

**Edge Cases:**
- Device has no biometric hardware → Biometric option hidden
- Biometric not enrolled → Prompt to enroll or use PIN
- PIN with only zeros "000000" → Accepted (with warning)

**Error Cases:**
- Biometric enrollment fails → Fallback to PIN
- PIN stored incorrectly → Re-setup required

**Performance:**
- PIN validation instant (<100ms)
- Biometric prompt appears in <500ms

---

## 3. Epic 2: Contact Management

### 3.1 User Story: US-010 - Add Contact via QR Scan

**As a** user,  
**I want to** add a contact by scanning their QR code,  
**So that** I can send them encrypted messages.

#### Acceptance Criteria

**AC-010-01: QR Code Scan**
```gherkin
Given I am on the Contacts screen
When I tap the "Add Contact" button
And I point my camera at another user's QR code
And the QR code is recognized
Then I see a preview of the contact's name and key fingerprint
And I can tap "Add" to confirm
```

**AC-010-02: Contact Added Successfully**
```gherkin
Given I have scanned a valid QR code for "Bob"
When I tap "Add Contact"
Then Bob is added to my contact list
And I see Bob in my Contacts screen
And I can start a conversation with Bob
And Bob's public key is stored encrypted in my database
```

**AC-010-03: Duplicate Contact Prevention**
```gherkin
Given I already have "Bob" in my contacts
When I scan Bob's QR code again
Then I see a message "Bob is already in your contacts"
And Bob is not added twice
```

**AC-010-04: Invalid QR Code Handling**
```gherkin
Given I am scanning a QR code
When the QR code is not a valid Ya OK contact (wrong format, corrupted data)
Then I see an error "Invalid Ya OK QR code"
And I can retry scanning
```

**AC-010-05: Camera Permission**
```gherkin
Given I have not granted camera permission
When I tap "Add Contact"
Then I see a system prompt requesting camera permission
And if I grant permission, the camera opens
And if I deny permission, I see an error with instructions to enable it in settings
```

**Priority:** P0 (Critical)  
**Effort:** 5 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-CONTACT-001-01 through FR-CONTACT-001-05

#### Test Scenarios

**Happy Path:**
1. Tap Add Contact → Grant camera permission → Scan Bob's QR → Confirm → Bob added

**Edge Cases:**
- Poor lighting → Scanning takes longer but succeeds
- QR code at extreme angle → Prompt to center QR code
- Distance too far → Prompt to move closer
- Multiple QR codes in frame → Focus on closest one

**Error Cases:**
- Camera unavailable → Show error with troubleshooting
- QR code damaged → Error shown, retry option
- Network QR code (not Ya OK) → Rejected with clear message

**Performance:**
- QR detection <2 seconds (typical)
- Contact added to database <100ms

---

### 3.2 User Story: US-011 - View Contact Details

**As a** user,  
**I want to** view a contact's details,  
**So that** I can verify their identity and see connection status.

#### Acceptance Criteria

**AC-011-01: Open Contact Details**
```gherkin
Given I have "Bob" in my contacts
When I tap on Bob in the Contacts screen
Then I see Bob's detail screen with:
  - Display name
  - Key fingerprint (first 6 hex characters)
  - Connection status (Online/Last seen/Never connected)
  - Options: Message, Edit, Delete, View Full Fingerprint
```

**AC-011-02: View Full Fingerprint**
```gherkin
Given I am viewing Bob's contact details
When I tap "View Full Fingerprint"
Then I see Bob's complete key fingerprint (64 hex characters, formatted)
And I can manually verify this with Bob (out-of-band)
```

**AC-011-03: Connection Status**
```gherkin
Given I am viewing Bob's contact details
When Bob is currently connected via Bluetooth
Then I see "Status: Online (Bluetooth)"
And the status indicator is green
```

**Priority:** P2 (Medium)  
**Effort:** 3 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-CONTACT-001-05, FR-CONTACT-001-08, FR-CONTACT-001-09

---

### 3.3 User Story: US-012 - Delete Contact

**As a** user,  
**I want to** delete a contact,  
**So that** I can remove people I no longer communicate with.

#### Acceptance Criteria

**AC-012-01: Delete Contact Confirmation**
```gherkin
Given I am viewing Bob's contact details
When I tap "Delete Contact"
Then I see a confirmation dialog: "Delete Bob? Your messages will be preserved."
And I can choose "Delete" or "Cancel"
```

**AC-012-02: Contact Deleted**
```gherkin
Given I confirmed deletion of Bob
When the deletion completes
Then Bob is removed from my Contacts screen
And Bob's public key is deleted from my database
But my message history with Bob is preserved (default setting)
And I cannot send new messages to Bob
```

**AC-012-03: Messages Preserved Option**
```gherkin
Given I am deleting a contact
When I choose "Delete contact and messages"
Then both the contact AND all messages are deleted
And I see a final confirmation warning
```

**Priority:** P1 (High)  
**Effort:** 2 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-CONTACT-001-07

#### Test Scenarios

**Happy Path:**
1. View Bob's details → Delete Contact → Confirm → Bob removed

**Edge Cases:**
- Delete contact with no messages → Success
- Delete contact with 1000+ messages → Success (may take 1-2s)

**Error Cases:**
- Database locked → Retry after delay
- Contact currently being messaged → Warning shown

---

## 4. Epic 3: Messaging

### 4.1 User Story: US-020 - Send Text Message

**As a** user,  
**I want to** send a text message to a contact,  
**So that** I can communicate securely with them.

#### Acceptance Criteria

**AC-020-01: Compose Message**
```gherkin
Given I am viewing my conversation with Bob
When I type "Hello, Bob!" in the message input field
And I tap the Send button
Then my message is encrypted with Bob's public key
And my message appears in the conversation with a "Sending..." status
And the message is added to my outbox
```

**AC-020-02: Message Sent**
```gherkin
Given I sent a message to Bob
When the message is successfully transmitted via any transport (BLE/WiFi/Relay)
Then the message status changes to "Sent"
And I see a single checkmark (✓) next to the message
And the message timestamp is displayed
```

**AC-020-03: Message Delivered**
```gherkin
Given Bob has received my message
When Bob's device sends an acknowledgment
Then the message status changes to "Delivered"
And I see a double checkmark (✓✓) next to the message
```

**AC-020-04: Message Size Limit**
```gherkin
Given I am composing a message
When I type more than 10KB of text
Then the Send button is disabled
And I see a warning "Message too large (max 10KB)"
```

**AC-020-05: Empty Message Prevention**
```gherkin
Given I am composing a message
When the message field is empty or only whitespace
Then the Send button is disabled
```

**Priority:** P0 (Critical)  
**Effort:** 8 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-MSG-SEND-001-01 through FR-MSG-SEND-001-13

#### Test Scenarios

**Happy Path:**
1. Open conversation → Type "Hi" → Send → Message encrypts → Sent via BLE → Delivered

**Edge Cases:**
- Send 10KB message → Success
- Send emoji message "🔒🔐" → Success
- Send message with newlines → Formatting preserved
- Send during poor connectivity → Queued, retried later

**Error Cases:**
- No transports available → Message queued, "Will send when connected"
- Recipient not in contacts → Error (should not reach this state)
- Encryption failure → Error logged, message not sent

**Performance:**
- Encryption <100ms
- UI feedback immediate (<50ms)
- Message appears in conversation instantly
- Delivery via BLE <5s (co-located)

---

### 4.2 User Story: US-021 - Receive Text Message

**As a** user,  
**I want to** receive text messages from my contacts,  
**So that** I can read their secure communications.

#### Acceptance Criteria

**AC-021-01: Message Received**
```gherkin
Given Bob sends me a message "Hello, Alice!"
When my device receives the encrypted packet
And the sender is verified as Bob (signature check)
And the message is decrypted with my private key
Then I see Bob's message in our conversation
And the message is marked as unread
And I receive a notification (if app in background)
```

**AC-021-02: Notification**
```gherkin
Given the app is in the background
When I receive a new message from Bob
Then I see a system notification: "Bob: New message"
And if I tap the notification, the app opens to Bob's conversation
And the notification does NOT show message content (privacy default)
```

**AC-021-03: Reject Unknown Sender**
```gherkin
Given I receive a message from an unknown sender (not in my contacts)
When my device processes the message
Then the message is rejected
And I do not see the message
And the security event is logged
```

**AC-021-04: Reject Tampered Message**
```gherkin
Given I receive a message with an invalid authentication tag
When my device attempts to decrypt the message
Then decryption fails
And I do not see the message
And the security event is logged (potential tampering)
```

**AC-021-05: Duplicate Message Detection**
```gherkin
Given I receive a message with ID "msg-123" from Bob
When I receive the same message again (same ID)
Then the duplicate is silently discarded
And I only see the message once in my conversation
```

**Priority:** P0 (Critical)  
**Effort:** 8 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-MSG-RECV-001-01 through FR-MSG-RECV-001-14

#### Test Scenarios

**Happy Path:**
1. Bob sends message → Encrypted packet received → Signature verified → Decrypted → Displayed → Notification shown

**Edge Cases:**
- Receive message while app closed → Processed on next launch, notification shown
- Receive 10 messages in 1 second → All processed, displayed in order
- Receive out-of-order messages → Sorted by timestamp

**Error Cases:**
- Unknown sender → Rejected, logged
- Tampered message → Rejected, security alert
- Decryption failure → Rejected, error logged

**Performance:**
- Decryption <100ms
- Message displayed <500ms after receipt
- Notification appears <5s

---

### 4.3 User Story: US-022 - Retry Failed Message

**As a** user,  
**I want to** retry sending a failed message,  
**So that** I can ensure my message is delivered.

#### Acceptance Criteria

**AC-022-01: Automatic Retry**
```gherkin
Given I sent a message to Bob
When the message fails to send (no transports available)
Then the message status shows "Failed"
And the system automatically retries after 1 minute
And if it fails again, retries after 5 minutes, then 15 minutes, then 1 hour
```

**AC-022-02: Manual Retry**
```gherkin
Given I have a failed message
When I tap on the failed message
And I select "Retry"
Then the message is immediately re-queued for sending
And the status changes to "Sending..."
```

**AC-022-03: Retry Success**
```gherkin
Given a failed message is being retried
When a transport becomes available (e.g., Bob comes in BLE range)
Then the message is successfully sent
And the status changes to "Sent"
```

**Priority:** P1 (High)  
**Effort:** 3 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-MSG-SEND-001-07, FR-MSG-SEND-001-10

#### Test Scenarios

**Happy Path:**
1. Send message when offline → Failed → Wait → WiFi enabled → Auto-retry → Sent

**Edge Cases:**
- Manual retry before auto-retry → Manual takes precedence
- Multiple failed messages → All retried in order

---

### 4.4 User Story: US-023 - View Message History

**As a** user,  
**I want to** view my message history with a contact,  
**So that** I can review our past conversations.

#### Acceptance Criteria

**AC-023-01: Open Conversation**
```gherkin
Given I have exchanged messages with Bob
When I tap on Bob in my Contacts or Conversations list
Then I see our complete message history in chronological order
And my messages are aligned to the right (sender bubbles)
And Bob's messages are aligned to the left (recipient bubbles)
And each message shows a timestamp
```

**AC-023-02: Scroll History**
```gherkin
Given I am viewing my conversation with Bob
When I scroll up to view older messages
Then older messages load smoothly
And scrolling is smooth (≥30fps)
```

**AC-023-03: Message Status Indicators**
```gherkin
Given I am viewing my sent messages
Then I see delivery status for each message:
  - Clock icon: Pending
  - Single check (✓): Sent
  - Double check (✓✓): Delivered
  - Red exclamation (!): Failed
```

**Priority:** P0 (Critical)  
**Effort:** 5 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-PERSIST-001-04, SRS § 3.4

#### Test Scenarios

**Happy Path:**
1. Open conversation → See last 100 messages → Scroll up → Load more

**Edge Cases:**
- Conversation with 10,000 messages → Pagination works, no lag
- Messages from multiple days → Date separators shown
- Very long message (10KB) → Rendered correctly

**Performance:**
- Initial load <50ms (100 messages)
- Scrolling smooth ≥30fps
- No memory leaks during long scrolling

---

## 5. Epic 4: Security & Privacy

### 5.1 User Story: US-030 - App Authentication

**As a** user,  
**I want to** authenticate when opening the app,  
**So that** no one else can read my messages if they access my phone.

#### Acceptance Criteria

**AC-030-01: PIN Authentication**
```gherkin
Given I have set up a PIN "123456"
And the app is locked
When I open the app
Then I see the authentication screen
And I enter my PIN "123456"
And I tap "Unlock"
Then I am authenticated
And I see the main screen
```

**AC-030-02: PIN Authentication Failed**
```gherkin
Given I am entering my PIN
When I enter the wrong PIN "000000"
Then I see an error "Incorrect PIN"
And the PIN field is cleared
And I can try again
```

**AC-030-03: Brute Force Protection**
```gherkin
Given I have failed PIN authentication 3 times
When I attempt to authenticate again
Then I am locked out for 30 seconds
And I see "Too many attempts. Try again in 30 seconds."
```

**AC-030-04: Biometric Authentication**
```gherkin
Given I have enabled biometric authentication
And the app is locked
When I open the app
Then I see a biometric prompt (fingerprint/Face ID)
And I authenticate with my biometric
Then I am authenticated
And I see the main screen
```

**AC-030-05: Biometric Fallback to PIN**
```gherkin
Given I am using biometric authentication
When biometric authentication fails 3 times
Then I see an option "Use PIN instead"
And if I tap it, I can enter my PIN
```

**AC-030-06: Auto-Lock**
```gherkin
Given I am using the app (authenticated)
And my auto-lock timeout is set to 5 minutes
When I leave the app idle for 5 minutes
Then the app automatically locks
And I must re-authenticate to access it
```

**AC-030-07: Background Lock**
```gherkin
Given I am using the app (authenticated)
When I press the home button (app goes to background)
Then the app immediately locks
And I must re-authenticate when I return
```

**Priority:** P1 (High)  
**Effort:** 8 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-AUTH-001-01 through FR-AUTH-001-11, NFR-SEC-040

#### Test Scenarios

**Happy Path:**
1. Open app → Enter PIN → Unlocked
2. Open app → Scan fingerprint → Unlocked

**Edge Cases:**
- Biometric hardware changes (new fingerprint enrolled) → Re-authentication required
- Device reboots → Re-authentication required
- PIN forgotten → App reset required (data loss warning)

**Error Cases:**
- Biometric sensor malfunction → Fallback to PIN
- Keystore unavailable → Error, app unusable (critical)

**Performance:**
- PIN validation <100ms
- Biometric prompt appears <500ms
- Auto-lock triggers within 1s of timeout

---

### 5.2 User Story: US-031 - Verify Contact Identity

**As a** user,  
**I want to** verify a contact's key fingerprint,  
**So that** I can confirm I'm communicating with the real person (not an imposter).

#### Acceptance Criteria

**AC-031-01: View Fingerprint**
```gherkin
Given I am viewing Bob's contact details
When I tap "View Full Fingerprint"
Then I see Bob's 64-character key fingerprint displayed in a readable format:
  Example: "A1B2 C3D4 E5F6 ... (16 groups of 4)"
And I can read this to Bob over a phone call or in person
```

**AC-031-02: Compare Fingerprints**
```gherkin
Given I am viewing Bob's fingerprint
And Bob tells me his fingerprint over the phone
When the fingerprints match
Then I have verified Bob's identity
And I can mark Bob as "Verified" (manual process)
```

**AC-031-03: Fingerprint Mismatch Warning**
```gherkin
Given I am viewing Bob's fingerprint
When Bob tells me a different fingerprint
Then I know there is a man-in-the-middle attack or setup error
And I should NOT communicate with this contact until resolved
```

**Priority:** P1 (High)  
**Effort:** 2 story points  
**Status:** ⬜ Partial (display implemented, verification marking not implemented)  
**Related Requirements:** FR-CONTACT-001-05, FR-CONTACT-001-09, REQ-AUTH-008

#### Test Scenarios

**Happy Path:**
1. View Bob's fingerprint → Read to Bob → Bob confirms match → Verified

**Edge Cases:**
- Fingerprint displayed in different formats (hex, base64) → Consistent

**Security:**
- Fingerprint derived deterministically from public key
- Fingerprint collision probability negligible (SHA-256)

---

## 6. Epic 5: Multi-Transport Networking

### 6.1 User Story: US-040 - Bluetooth LE Messaging

**As a** user,  
**I want to** send messages via Bluetooth when no internet is available,  
**So that** I can communicate with nearby contacts.

#### Acceptance Criteria

**AC-040-01: BLE Peer Discovery**
```gherkin
Given Bluetooth is enabled on my device
And Bob is nearby (<10 meters) with Ya OK open
When I open the app
Then Bob is discovered via BLE within 30 seconds
And I see Bob's status as "Online (Bluetooth)" in his contact details
```

**AC-040-02: Send Message via BLE**
```gherkin
Given Bob is connected via Bluetooth
When I send Bob a message "Hi via BLE"
Then the message is transmitted over Bluetooth LE
And Bob receives the message within 5 seconds
And I see "Sent" status
```

**AC-040-03: BLE Permission**
```gherkin
Given I have not granted Bluetooth permission
When the app attempts BLE operations
Then I see a system prompt requesting Bluetooth permission
And if I grant it, BLE operations proceed
And if I deny it, I see guidance to enable it manually
```

**AC-040-04: BLE Disconnection**
```gherkin
Given Bob is connected via BLE
When Bob moves out of range (>50 meters)
Then Bob's status changes to "Offline"
And pending messages are queued for retry
```

**Priority:** P0 (Critical)  
**Effort:** 13 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-BLE-001-01 through FR-BLE-001-12, NFR-PERF-020, NFR-PERF-023

#### Test Scenarios

**Happy Path:**
1. Enable BLE → Bob nearby → Discovered → Send message → Delivered via BLE

**Edge Cases:**
- Multiple peers nearby → All discovered
- BLE interference → Slower discovery, but successful
- Large message (10KB) → Chunked and reassembled correctly

**Error Cases:**
- Bluetooth off → Prompt to enable
- Bluetooth permission denied → Error with instructions
- BLE hardware malfunction → Error, fallback to other transports

**Performance:**
- Discovery <30s at <10m range
- Message delivery <5s (co-located)
- Battery drain <8%/hr during active BLE

---

### 6.2 User Story: US-041 - WiFi Direct Messaging

**As a** user,  
**I want to** send messages via WiFi Direct,  
**So that** I can achieve faster message delivery for larger messages.

#### Acceptance Criteria

**AC-041-01: WiFi Direct Discovery**
```gherkin
Given WiFi Direct is enabled on my device
And Bob is nearby with WiFi Direct enabled
When I open the app
Then Bob is discovered via WiFi Direct within 60 seconds
And I see Bob's status includes "WiFi"
```

**AC-041-02: Send Message via WiFi Direct**
```gherkin
Given Bob is connected via WiFi Direct
When I send Bob a large message (5KB)
Then the message is transmitted over WiFi Direct
And Bob receives the message within 2 seconds
And I see "Sent" status
```

**AC-041-03: WiFi Direct Permission (Android)**
```gherkin
Given I am on Android
And I have not granted Location permission (required for WiFi Direct)
When the app attempts WiFi Direct operations
Then I see a prompt explaining why location is needed
And I can grant or deny permission
```

**Priority:** P1 (High)  
**Effort:** 13 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-WIFI-001-01 through FR-WIFI-001-10, NFR-PERF-021

#### Test Scenarios

**Happy Path:**
1. Enable WiFi → Bob nearby → Discovered → Send 5KB message → Delivered via WiFi Direct in <2s

**Edge Cases:**
- WiFi Direct group owner negotiation → Completes in <30s
- Multiple WiFi Direct groups nearby → Correct group joined

**Error Cases:**
- WiFi Direct not supported → Feature disabled gracefully
- Location permission denied (Android) → WiFi Direct unavailable, use BLE

**Performance:**
- Discovery <60s
- Connection establishment <30s
- Bandwidth ≥1 MB/s

---

### 6.3 User Story: US-042 - Relay Server Messaging

**As a** user,  
**I want to** send messages via relay server when recipients are not nearby,  
**So that** I can communicate with contacts anywhere with internet.

#### Acceptance Criteria

**AC-042-01: Relay Connection**
```gherkin
Given I have internet connectivity
And relay is enabled in settings
When the app starts
Then the app connects to the relay server via TLS
And I see "Relay: Connected" in diagnostics
```

**AC-042-02: Send Message via Relay**
```gherkin
Given Bob is not nearby (no BLE/WiFi connection)
And I am connected to the relay
When I send Bob a message "Hello via relay"
Then the message is encrypted and sent to the relay
And the relay forwards it to Bob (when Bob is online)
And I see "Sent" status
```

**AC-042-03: Receive Message from Relay**
```gherkin
Given I am connected to the relay
When Alice sends me a message via the relay
Then I receive the encrypted message from the relay
And I decrypt and display Alice's message
```

**AC-042-04: Relay Rate Limiting**
```gherkin
Given I am sending many messages via relay
When I exceed 100 messages per hour
Then I see a warning "Rate limit reached. Try again in X minutes."
And my message is queued for later
```

**AC-042-05: Relay Fallback**
```gherkin
Given the relay server is unavailable
When I send a message
Then the app attempts other transports (BLE, WiFi)
And if no transports available, the message is queued
And I see "Will send when connected"
```

**Priority:** P1 (High)  
**Effort:** 13 story points  
**Status:** ⬜ Partial (basic implementation, TLS verification pending)  
**Related Requirements:** FR-RELAY-001-01 through FR-RELAY-001-12, NFR-PERF-022, NFR-PERF-024

#### Test Scenarios

**Happy Path:**
1. Connect to internet → Relay connected → Send message to distant Bob → Delivered via relay

**Edge Cases:**
- Relay offline → Fallback to other transports
- Intermittent internet → Automatic reconnection

**Error Cases:**
- TLS certificate invalid → Connection refused, error shown
- Rate limit exceeded → Clear message with retry time

**Performance:**
- Connection <5s
- Message delivery <10s (90th percentile)
- Data overhead <5KB per message

---

## 7. Epic 6: Settings & Configuration

### 7.1 User Story: US-050 - Configure Transports

**As a** user,  
**I want to** enable/disable transports (Bluetooth, WiFi, Relay),  
**So that** I can control how my messages are sent (e.g., disable relay for privacy).

#### Acceptance Criteria

**AC-050-01: Disable Bluetooth**
```gherkin
Given Bluetooth transport is enabled
When I go to Settings > Transports
And I toggle Bluetooth OFF
Then Bluetooth operations stop immediately
And I see "Bluetooth: Disabled" in diagnostics
And messages will not be sent via Bluetooth
```

**AC-050-02: Re-enable Bluetooth**
```gherkin
Given Bluetooth transport is disabled
When I toggle Bluetooth ON in settings
Then Bluetooth operations resume
And peer discovery starts
```

**AC-050-03: Disable Relay**
```gherkin
Given Relay transport is enabled
When I toggle Relay OFF in settings
Then the app disconnects from the relay server
And messages will not be sent via relay
And messages are only sent via BLE/WiFi
```

**Priority:** P2 (Medium)  
**Effort:** 3 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-BLE-001-10, FR-WIFI-001-07, FR-RELAY-001-09

#### Test Scenarios

**Happy Path:**
1. Settings → Transports → Disable Relay → Relay disconnected

**Edge Cases:**
- Disable all transports → Warning shown "No transports enabled"
- Disable transport during active message send → Message queued for other transports

---

### 7.2 User Story: US-051 - Configure Auto-Lock

**As a** user,  
**I want to** configure auto-lock timeout,  
**So that** I can balance security with convenience.

#### Acceptance Criteria

**AC-051-01: Change Auto-Lock Timeout**
```gherkin
Given I am in Settings > Security
When I tap "Auto-lock timeout"
And I select "10 minutes"
Then the auto-lock timeout is set to 10 minutes
And the app will lock after 10 minutes of inactivity
```

**AC-051-02: Disable Auto-Lock**
```gherkin
Given I am configuring auto-lock
When I select "Never" (if option available)
Then I see a security warning "App will not auto-lock. Anyone with access to your phone can read your messages."
And if I confirm, auto-lock is disabled
```

**Priority:** P2 (Medium)  
**Effort:** 2 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-AUTH-001-06, NFR-SEC-040

---

## 8. Epic 7: Diagnostics & Monitoring

### 8.1 User Story: US-060 - View Connection Status

**As a** user,  
**I want to** view my connection status for each transport,  
**So that** I can troubleshoot delivery issues.

#### Acceptance Criteria

**AC-060-01: View Diagnostics Screen**
```gherkin
Given I am in the app
When I navigate to Settings > Diagnostics
Then I see connection status for each transport:
  - Bluetooth: Enabled/Disabled, Peers discovered: X
  - WiFi Direct: Enabled/Disabled, Connected: Yes/No
  - Relay: Connected/Disconnected, Last sync: timestamp
  - Internet: Available/Unavailable
```

**AC-060-02: Bluetooth Status Details**
```gherkin
Given I am viewing diagnostics
When Bluetooth is enabled
Then I see:
  - Bluetooth: Enabled
  - Peers discovered: 2 (Alice, Charlie)
  - Last discovery: 5 seconds ago
```

**AC-060-03: Pending Message Queue**
```gherkin
Given I am viewing diagnostics
When I have pending messages
Then I see "Pending messages: 3"
And I can tap to view details (recipients, retry status)
```

**Priority:** P2 (Medium)  
**Effort:** 5 story points  
**Status:** ✅ Done  
**Related Requirements:** FR-DIAG-001-01 through FR-DIAG-001-05

#### Test Scenarios

**Happy Path:**
1. Settings → Diagnostics → See all transports status

**Edge Cases:**
- All transports offline → Clear status shown
- Rapidly changing status → UI updates in real-time

**Performance:**
- Status updates in real-time (<1s delay)
- No performance impact on main app

---

## 9. Success Metrics

### 9.1 Adoption & Engagement

| Metric | Target | Measurement Method | Priority |
|--------|--------|-------------------|----------|
| **Setup Completion Rate** | ≥90% | Analytics: users who complete setup / total installs | P1 |
| **First Message Sent** | ≥80% (within 1 week) | Analytics: users who send ≥1 message / setup completed | P1 |
| **Daily Active Users (DAU)** | ≥30% of MAU | Analytics: DAU / MAU | P2 |
| **Retention (D7)** | ≥60% | Analytics: users active on day 7 / installs | P1 |
| **Retention (D30)** | ≥40% | Analytics: users active on day 30 / installs | P2 |

### 9.2 Feature Usage

| Feature | Target | Measurement |
|---------|--------|-------------|
| **QR Code Scan** | ≥95% success rate | Scans successful / total scans | P0 |
| **Message Send Success** | ≥95% (co-located) | Delivered / sent | P0 |
| **BLE Messaging** | ≥70% of messages (offline users) | BLE messages / total | P1 |
| **Relay Messaging** | ≤30% of messages | Relay messages / total | P2 |
| **Biometric Auth** | ≥60% adoption (capable devices) | Users with biometric / capable devices | P2 |

### 9.3 Performance & Quality

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Crash-Free Rate** | ≥99% | Sessions without crash / total sessions | P0 |
| **App Store Rating** | ≥4.0 / 5.0 | App store reviews | P1 |
| **Net Promoter Score (NPS)** | ≥40 (good) | In-app survey (optional) | P2 |
| **Message Delivery Latency** | <5s (co-located, 90th percentile) | Timestamp analysis | P0 |
| **Setup Time** | <5 minutes (90th percentile) | Analytics: setup start to complete | P1 |

### 9.4 Security & Privacy

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Security Incidents** | 0 critical | Incident reports | P0 |
| **Plaintext Data Leaks** | 0 | Security audits | P0 |
| **Failed Auth Attempts** | <5% of logins | Analytics: failed / total logins | P2 |
| **Key Verification Rate** | ≥30% of contacts | Users who verify fingerprints | P2 |

---

## 10. Test Coverage Matrix

### 10.1 Feature vs. Test Type

| Feature | Unit | Integration | E2E | Security | Performance | Manual |
|---------|------|-------------|-----|----------|-------------|--------|
| **User Onboarding** | ✅ | ✅ | ✅ | ✅ | ⬜ | ✅ |
| **Contact Management** | ✅ | ✅ | ✅ | ⬜ | ⬜ | ✅ |
| **Message Send** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Message Receive** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Bluetooth Transport** | ✅ | ✅ | ✅ | ⬜ | ✅ | ✅ |
| **WiFi Direct** | ✅ | ✅ | ✅ | ⬜ | ✅ | ⬜ |
| **Relay Transport** | ✅ | ✅ | ✅ | ✅ | ✅ | ⬜ |
| **Authentication** | ✅ | ⬜ | ✅ | ✅ | ⬜ | ✅ |
| **Encryption/Decryption** | ✅ | ✅ | ⬜ | ✅ | ✅ | ⬜ |
| **Database** | ✅ | ✅ | ⬜ | ✅ | ✅ | ⬜ |
| **Settings** | ✅ | ⬜ | ✅ | ⬜ | ⬜ | ✅ |
| **Diagnostics** | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ✅ |

**Legend:**
- ✅ - Tests exist and passing
- ⬜ - Tests planned but not implemented
- ❌ - Tests needed but not planned

**Coverage Targets:**
- Unit tests: ≥80% (Rust), ≥70% (Android/iOS)
- Integration tests: All critical paths
- E2E tests: All major user journeys
- Security tests: 100% of security requirements (P0/P1)

### 10.2 Requirements Traceability

| Epic | User Stories | SRS Requirements | Test Cases | Coverage |
|------|-------------|-----------------|------------|----------|
| **User Onboarding** | US-001, US-002 | FR-USER-001-01 to 10 | TC-USER-001 to 020 | 90% |
| **Contact Management** | US-010 to 012 | FR-CONTACT-001-01 to 12 | TC-CONTACT-001 to 030 | 85% |
| **Messaging** | US-020 to 023 | FR-MSG-SEND-001, FR-MSG-RECV-001 | TC-MSG-001 to 050 | 95% |
| **Security** | US-030, US-031 | FR-AUTH-001, FR-CRYPTO-001 | TC-SEC-001 to 180 | 88% |
| **Networking** | US-040 to 042 | FR-BLE-001, FR-WIFI-001, FR-RELAY-001 | TC-NET-001 to 080 | 80% |
| **Settings** | US-050, US-051 | FR-SETTINGS-001 | TC-SETTINGS-001 to 020 | 75% |
| **Diagnostics** | US-060 | FR-DIAG-001 | TC-DIAG-001 to 010 | 70% |

**Overall Traceability:** 85% (Good, but needs improvement to 95% for v1.0)

---

## Appendix A: User Personas

### Persona 1: Activist Anna
- **Age:** 28
- **Tech Skill:** Medium
- **Device:** Android (mid-range)
- **Context:** Organizing protests in surveillance environment
- **Needs:** Secure offline communication, minimal metadata
- **Pain Points:** Internet shutdowns, surveillance

### Persona 2: Emergency Responder Eric
- **Age:** 35
- **Tech Skill:** Low-Medium
- **Device:** iOS (work-issued)
- **Context:** Disaster response, poor/no cellular coverage
- **Needs:** Reliable messaging, simple interface
- **Pain Points:** Network congestion, time pressure

### Persona 3: Privacy-Conscious Pat
- **Age:** 42
- **Tech Skill:** High
- **Device:** Android (flagship)
- **Context:** Personal communication without surveillance
- **Needs:** Strong encryption, verifiable security
- **Pain Points:** Metadata collection, corporate surveillance

### Persona 4: Rural User Rita
- **Age:** 52
- **Tech Skill:** Low
- **Device:** Android (budget)
- **Context:** Area with poor cellular coverage
- **Needs:** Communication with neighbors, simple UI
- **Pain Points:** Limited data, poor signal

---

## Appendix B: Test Scenarios (Detailed)

### Scenario 1: First-Time User Journey

**Actors:** New user (Alice)

**Preconditions:** App installed, never opened before

**Steps:**
1. Launch app
2. See welcome screen
3. Tap "Get Started"
4. Enter display name "Alice"
5. Tap "Next"
6. Choose "PIN" authentication
7. Enter PIN "123456"
8. Confirm PIN "123456"
9. Tap "Done"
10. See main screen (empty contact list)
11. Tap profile icon
12. See QR code with name "Alice"

**Expected Outcome:**
- Setup completes in <2 minutes
- All data stored encrypted
- Private key in hardware keystore
- User reaches main screen successfully

**Variations:**
- Choose biometric instead of PIN
- Enter invalid name (too short) → Error → Correct → Continue
- Rotate device during setup → State preserved

---

### Scenario 2: Add Contact and Send First Message

**Actors:** Alice (existing user), Bob (new contact)

**Preconditions:**
- Alice has Ya OK set up
- Bob has Ya OK set up
- Both devices physically co-located

**Steps:**
1. Alice: Open Ya OK → Authenticate
2. Alice: Tap "Contacts" → "Add Contact"
3. Alice: Grant camera permission
4. Alice: Point camera at Bob's QR code
5. Alice: See preview "Bob" → Tap "Add"
6. Alice: See "Bob added to contacts"
7. Alice: Tap Bob in contacts
8. Alice: Type "Hello, Bob!" → Tap Send
9. Bob: Receive notification "Alice: New message"
10. Bob: Open notification → See "Hello, Bob!"
11. Bob: Reply "Hi, Alice!" → Send
12. Alice: Receive Bob's reply

**Expected Outcome:**
- QR scan succeeds in <10 seconds
- Contact added successfully
- Message encrypted, sent via BLE in <5s
- Bidirectional communication works

**Variations:**
- Poor lighting → Scanning slower but succeeds
- BLE disabled → Prompt to enable
- Devices out of range → Message queued, delivered when in range

---

## Appendix C: Definition of Done Checklist

For each user story to be marked as **DONE**:

**Development:**
- [ ] Code written and compiles without errors
- [ ] Code follows style guide (Kotlin/Swift/Rust)
- [ ] All acceptance criteria implemented
- [ ] Unit tests written and passing (≥80% coverage for new code)
- [ ] Integration tests passing (if applicable)
- [ ] No new compiler warnings introduced

**Testing:**
- [ ] Manual testing complete (happy path, edge cases, error cases)
- [ ] E2E test written and passing (if applicable)
- [ ] Performance tested (meets NFR targets)
- [ ] Security tested (if security-related feature)
- [ ] Regression tests passing

**Code Quality:**
- [ ] Code reviewed by at least 1 peer
- [ ] Security review complete (for crypto/auth features)
- [ ] Static analysis passing (Clippy, Lint)
- [ ] No critical or high-severity bugs

**Documentation:**
- [ ] Code documented (public APIs, complex logic)
- [ ] User-facing documentation updated (if needed)
- [ ] Changelog updated

**Product:**
- [ ] Product owner acceptance
- [ ] Meets design specifications
- [ ] Accessibility considerations addressed
- [ ] Localization ready (if applicable)

---

**Document Status:** APPROVED  
**Baseline Version:** 1.0  
**Effective Date:** 2026-02-06  
**Next Review:** Sprint retrospectives

**Product Owner:** __________________ Date: __________  
**QA Lead:** __________________ Date: __________

---

**Classification:** INTERNAL  
**Distribution:** Engineering, QA, Product  
**Storage:** `/docs/ACCEPTANCE_CRITERIA.md`

---

*These acceptance criteria define the standard of "DONE" for Ya OK v1.0. All features must meet these criteria before release.*
