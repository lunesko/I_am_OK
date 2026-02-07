# Software Requirements Specification (SRS)
## Ya OK - Delay-Tolerant Secure Messenger

**Document ID:** YA-OK-SRS-001  
**Version:** 1.0  
**Date:** 2026-02-06  
**Status:** APPROVED  
**Classification:** INTERNAL

**Standards Compliance:**
- ISO/IEC/IEEE 29148:2018 - Systems and software engineering — Life cycle processes — Requirements engineering
- IEEE 830-1998 - Recommended Practice for Software Requirements Specifications
- ISO/IEC 25010:2011 - System and software quality models

---

## Document Control

| Version | Date | Author | Changes | Approver |
|---------|------|--------|---------|----------|
| 0.1 | 2025-12-01 | Requirements Team | Initial draft | - |
| 0.5 | 2026-01-15 | Requirements Team | Feature complete | Product Owner |
| 1.0 | 2026-02-06 | Requirements Team | Security requirements integrated | CTO |

**Approval Signatures:**
- [ ] Product Owner
- [ ] Technical Lead
- [ ] Security Architect
- [ ] QA Lead

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [System Features](#3-system-features)
4. [External Interface Requirements](#4-external-interface-requirements)
5. [System Constraints](#5-system-constraints)
6. [Non-Functional Requirements](#6-non-functional-requirements)
7. [Appendices](#7-appendices)

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) describes the functional and non-functional requirements for **Ya OK**, a delay-tolerant, end-to-end encrypted messaging application designed for environments with limited or no internet connectivity.

**Intended Audience:**
- Development team (implementation reference)
- QA team (test case development)
- Product management (feature validation)
- Security team (security review)
- Stakeholders (project oversight)

### 1.2 Scope

**Product Name:** Ya OK (Я ОК)

**Product Description:**  
Ya OK is a mobile messaging application (Android, iOS) that enables secure communication in infrastructure-limited environments. The system uses opportunistic networking, leveraging multiple transport layers (Bluetooth LE, WiFi Direct, Mesh Networking, UDP Relay) to deliver messages even when traditional internet connectivity is unavailable.

**Key Objectives:**
1. **Security:** End-to-end encryption using modern cryptography (XChaCha20-Poly1305, X25519)
2. **Resilience:** Message delivery without requiring internet infrastructure
3. **Privacy:** Minimal metadata, no phone numbers, no central user database
4. **Usability:** Simple interface for non-technical users
5. **Reliability:** Store-and-forward architecture with persistent message queue

**In Scope:**
- Mobile applications (Android API 24+, iOS 14+)
- Peer-to-peer messaging via multiple transports
- End-to-end encryption
- Contact management via QR codes
- Message persistence and delivery tracking
- Optional relay server for internet-connected peers

**Out of Scope:**
- Voice/video calls
- Group chat (v1.0; planned for v2.0)
- File attachments >1MB
- Desktop applications
- Web interface
- Message synchronization across multiple devices per user

### 1.3 Definitions, Acronyms, and Abbreviations

| Term | Definition |
|------|------------|
| **DTN** | Delay-Tolerant Network - networking architecture for challenged networks |
| **E2EE** | End-to-End Encryption - messages encrypted from sender to recipient |
| **BLE** | Bluetooth Low Energy - wireless PAN protocol |
| **AEAD** | Authenticated Encryption with Associated Data |
| **Peer** | Another Ya OK user with whom the current user can exchange messages |
| **Contact** | A peer whose public key has been verified and stored locally |
| **Transport** | Communication channel (Bluetooth, WiFi Direct, Mesh, Relay) |
| **Relay** | Optional server for message forwarding when peers not co-located |
| **Store-and-forward** | Intermediate storage of messages for deferred delivery |
| **Nonce** | Number used once - unique value for each encryption operation |
| **STRIDE** | Threat modeling methodology (Spoofing, Tampering, Repudiation, etc.) |

### 1.4 References

| Document | Description |
|----------|-------------|
| YA-OK-SEC-001 | Threat Model |
| YA-OK-SEC-002 | Security Requirements Specification |
| YA-OK-SEC-003 | Security Test Plan |
| RFC 8439 | ChaCha20 and Poly1305 for IETF Protocols |
| RFC 7748 | Elliptic Curves for Security (X25519) |
| ISO/IEC 27001:2013 | Information Security Management |
| OWASP MASVS v2.0 | Mobile Application Security Verification Standard |

### 1.5 Overview

This document is organized as follows:
- **Section 2:** System context, user characteristics, constraints
- **Section 3:** Detailed functional requirements organized by feature
- **Section 4:** External interfaces (UI, hardware, network)
- **Section 5:** System constraints and assumptions
- **Section 6:** Non-functional requirements (performance, security, reliability)
- **Section 7:** Appendices with supplementary information

---

## 2. Overall Description

### 2.1 Product Perspective

Ya OK is a **standalone mobile application** with optional relay server infrastructure. It exists in the mobile security and offline communication domain, similar to Briar, Bridgefy, and FireChat, but with stronger cryptographic guarantees.

**System Context Diagram:**

```
┌─────────────────────────────────────────────────────────────┐
│                         Ya OK System                        │
│                                                             │
│  ┌──────────────┐           ┌──────────────┐              │
│  │   Android    │           │     iOS      │              │
│  │     App      │◄─────────►│     App      │              │
│  └──────┬───────┘           └──────┬───────┘              │
│         │                          │                       │
│         │  ┌────────────────────┐  │                      │
│         └─►│   Rust Core Lib    │◄─┘                      │
│            │  (ya_ok_core)      │                         │
│            └────────┬───────────┘                         │
│                     │                                      │
│         ┌───────────┴───────────┬──────────┬───────────┐ │
│         │                       │          │           │ │
│    ┌────▼────┐          ┌──────▼──┐  ┌────▼────┐ ┌────▼───┐
│    │Bluetooth│          │WiFi Dir.│  │  Mesh   │ │ Relay  │
│    │   LE    │          │         │  │  Net    │ │ (UDP)  │
│    └─────────┘          └─────────┘  └─────────┘ └────┬───┘
│                                                         │    │
└─────────────────────────────────────────────────────────┼────┘
                                                          │
                                    ┌─────────────────────▼────┐
                                    │   Relay Server (Rust)    │
                                    │   - Message forwarding   │
                                    │   - No decryption        │
                                    │   - TLS 1.3              │
                                    └──────────────────────────┘
```

**Key Interfaces:**
- **User Interface:** Native mobile UI (Kotlin/Swift)
- **Crypto Engine:** Rust FFI (Foreign Function Interface)
- **Transport Layers:** Bluetooth API, WiFi Direct API, UDP sockets
- **Persistence:** SQLite database (encrypted via SQLCipher)
- **Platform Security:** Android Keystore, iOS Keychain

### 2.2 Product Functions

**High-Level Features:**

1. **User Management**
   - First-time setup and key generation
   - User profile management (display name, avatar)
   - Authentication (PIN, biometric)

2. **Contact Management**
   - Add contacts via QR code scan
   - Verify contact fingerprints
   - Edit/delete contacts
   - View contact connection status

3. **Messaging**
   - Send text messages (up to 10KB)
   - Receive messages from contacts
   - View message history
   - Message delivery status tracking
   - Retry failed messages

4. **Multi-Transport Networking**
   - Automatic transport selection
   - Bluetooth LE peer discovery and messaging
   - WiFi Direct peer discovery and messaging
   - Mesh networking for multi-hop delivery
   - Optional relay server for internet-connected peers

5. **Security**
   - End-to-end encryption (XChaCha20-Poly1305)
   - Key exchange (X25519)
   - Encrypted local storage (SQLCipher)
   - Secure key management (platform keystores)
   - Authentication and session management

6. **Diagnostics**
   - Connection status indicators
   - Network diagnostics
   - Message queue inspection
   - Transport layer testing

### 2.3 User Characteristics

**Primary User Personas:**

| Persona | Description | Technical Skill | Use Cases |
|---------|-------------|----------------|-----------|
| **Activist** | Organizer in regions with surveillance or internet shutdowns | Medium | Coordinate protests, share information securely |
| **Emergency Responder** | First responder in disaster zones | Low-Medium | Coordinate rescue, share status updates |
| **Traveler** | International traveler in areas without data roaming | Low | Communicate with family, find local contacts |
| **Privacy Enthusiast** | User seeking metadata-free communication | High | Personal communication without surveillance |
| **Rural User** | User in area with poor cellular coverage | Low | Communicate with neighbors, coordinate community |

**User Skill Levels:**
- **Low:** Can use basic smartphone features (messaging, camera)
- **Medium:** Understands VPNs, encryption concepts
- **High:** Understands public key cryptography, threat modeling

**User Environment:**
- Mobile device with Android 7+ or iOS 14+
- May have limited battery power
- May have limited or no internet connectivity
- May be in hostile environment (surveillance, censorship)

### 2.4 Constraints

**Technical Constraints:**

1. **Platform:**
   - Android API 24+ (Nougat 7.0, released 2016)
   - iOS 14+ (released 2020)
   - Minimum 2GB RAM, 100MB storage

2. **Bluetooth:**
   - BLE range: ~10-50 meters
   - Data rate: ~1 Mbps theoretical, ~100 Kbps practical
   - Limited concurrent connections: 7-10 devices

3. **WiFi Direct:**
   - Range: ~100-200 meters
   - Requires Android 4.0+ (API 14) or iOS 13+
   - Group owner negotiation adds latency

4. **Message Size:**
   - Maximum single message: 10KB plaintext
   - Binary attachments: Not supported in v1.0
   - Database size limit: 500MB (enforced by app)

5. **Cryptography:**
   - Must use RustCrypto crate (audited libraries)
   - No custom crypto implementations
   - Key size: 256-bit minimum

**Regulatory Constraints:**

1. **Data Protection:**
   - GDPR compliance (EU users)
   - CCPA compliance (California users)
   - No collection of personal data without consent

2. **Export Control:**
   - May be restricted in some jurisdictions (strong encryption)
   - App store compliance required

3. **Open Source License:**
   - GPL v3 - all modifications must be open source

**Business Constraints:**

1. **Budget:** Limited resources for relay infrastructure
2. **Timeline:** v1.0 release target Q1 2026
3. **Team:** Small team (2 developers, 1 QA, 1 designer)

### 2.5 Assumptions and Dependencies

**Assumptions:**

1. Users have physical access to each other for initial key exchange (QR code scan)
2. Devices have functioning Bluetooth and/or WiFi hardware
3. Users understand basic concept of "adding a contact"
4. App installed from trusted source (Google Play, Apple App Store)
5. Users can dedicate 100MB+ storage for message database

**Dependencies:**

1. **External Libraries:**
   - RustCrypto (cryptography)
   - SQLCipher (database encryption)
   - AndroidX (Android compatibility)
   - ZXing (QR code scanning)

2. **Platform APIs:**
   - Android Bluetooth API
   - iOS CoreBluetooth
   - Android WiFi Direct API
   - iOS MultipeerConnectivity
   - Android Keystore, iOS Keychain

3. **Infrastructure:**
   - Optional relay server (self-hosted or managed)
   - GitHub for code hosting
   - Google Play / App Store for distribution

4. **Development Tools:**
   - Android Studio, Xcode
   - Rust toolchain
   - Git version control

---

## 3. System Features

### 3.1 User Registration and Setup

**Feature ID:** FR-USER-001  
**Priority:** P0 (Critical)  
**Risk:** High

#### 3.1.1 Description

First-time user onboarding including key generation, profile creation, and authentication setup.

#### 3.1.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-USER-001-01 | On first launch, system SHALL generate a unique keypair (X25519) | P0 | ✅ Implemented |
| FR-USER-001-02 | System SHALL derive user ID from public key using SHA-256 | P0 | ✅ Implemented |
| FR-USER-001-03 | System SHALL store private key in platform keystore (Android Keystore, iOS Keychain) | P0 | ✅ Implemented |
| FR-USER-001-04 | System SHALL prompt user to set display name (2-50 characters) | P1 | ✅ Implemented |
| FR-USER-001-05 | System SHALL generate QR code containing user's public key and display name | P1 | ✅ Implemented |
| FR-USER-001-06 | User SHALL be able to set authentication method: PIN (6+ digits) or biometric | P1 | ✅ Implemented |
| FR-USER-001-07 | System SHALL enforce PIN minimum length of 6 digits | P1 | ✅ Implemented |
| FR-USER-001-08 | System SHALL support biometric authentication where platform supports it | P2 | ✅ Implemented |
| FR-USER-001-09 | User SHALL be able to skip authentication setup (not recommended) | P3 | ❌ Not implemented |
| FR-USER-001-10 | System SHALL display tutorial/onboarding flow explaining key concepts | P2 | ⬜ Partial |

#### 3.1.3 Input/Output

**Inputs:**
- User display name (text, 2-50 characters)
- PIN (6+ digits) or biometric enrollment
- User avatar (optional, image <500KB)

**Outputs:**
- Keypair generated and stored
- User profile created
- QR code displayed
- Success confirmation

#### 3.1.4 Business Rules

- BR-USER-001: Private key MUST NEVER leave device unencrypted
- BR-USER-002: User ID MUST be deterministic (derived from public key)
- BR-USER-003: Display name MAY be changed, but user ID remains constant
- BR-USER-004: Biometric auth MUST fall back to PIN if biometric fails

#### 3.1.5 Acceptance Criteria

- [ ] New user can complete setup in <2 minutes
- [ ] Private key stored in hardware-backed keystore (if available)
- [ ] QR code is scannable from another device
- [ ] Authentication locks app after 3 failed attempts

---

### 3.2 Contact Management

**Feature ID:** FR-CONTACT-001  
**Priority:** P0 (Critical)  
**Risk:** Medium

#### 3.2.1 Description

Adding, verifying, managing, and deleting contacts. Contacts are stored locally with their public keys.

#### 3.2.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-CONTACT-001-01 | User SHALL be able to add contact by scanning their QR code | P0 | ✅ Implemented |
| FR-CONTACT-001-02 | System SHALL extract public key and display name from scanned QR code | P0 | ✅ Implemented |
| FR-CONTACT-001-03 | System SHALL validate public key format (32 bytes, valid X25519 point) | P0 | ✅ Implemented |
| FR-CONTACT-001-04 | System SHALL prevent adding duplicate contacts (same public key) | P1 | ✅ Implemented |
| FR-CONTACT-001-05 | System SHALL display key fingerprint (first 6 hex chars) for verification | P1 | ✅ Implemented |
| FR-CONTACT-001-06 | User SHALL be able to edit contact display name locally | P2 | ✅ Implemented |
| FR-CONTACT-001-07 | User SHALL be able to delete contact | P1 | ✅ Implemented |
| FR-CONTACT-001-08 | System SHALL show contact connection status (online, last seen, never connected) | P2 | ✅ Implemented |
| FR-CONTACT-001-09 | System SHALL display full key fingerprint for manual verification | P1 | ⬜ Partial |
| FR-CONTACT-001-10 | User SHALL be able to share their own QR code via system share sheet | P2 | ✅ Implemented |
| FR-CONTACT-001-11 | System SHALL allow manual key entry (for advanced users) | P3 | ❌ Not implemented |
| FR-CONTACT-001-12 | System SHALL support exporting/importing contacts (encrypted backup) | P3 | ❌ Not implemented |

#### 3.2.3 Input/Output

**Inputs:**
- QR code image (from camera)
- Contact display name (text, optional edit)
- Delete confirmation

**Outputs:**
- Contact added to local database
- Contact list updated
- Success/error message

#### 3.2.4 Business Rules

- BR-CONTACT-001: Each contact MUST have unique public key
- BR-CONTACT-002: Contact database MUST be encrypted at rest
- BR-CONTACT-003: Deleting contact MUST preserve message history (configurable)
- BR-CONTACT-004: QR code MUST contain only public information (public key, display name)

#### 3.2.5 Acceptance Criteria

- [ ] User can add contact via QR scan in <30 seconds
- [ ] Invalid QR codes rejected with clear error message
- [ ] Contact list displays immediately after adding
- [ ] Deleting contact removes them from list but preserves messages (default)

---

### 3.3 Message Sending

**Feature ID:** FR-MSG-SEND-001  
**Priority:** P0 (Critical)  
**Risk:** High

#### 3.3.1 Description

Composing and sending encrypted text messages to contacts via available transport layers.

#### 3.3.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-MSG-SEND-001-01 | User SHALL be able to compose text message up to 10KB | P0 | ✅ Implemented |
| FR-MSG-SEND-001-02 | System SHALL encrypt message with recipient's public key (X25519 + XChaCha20-Poly1305) | P0 | ✅ Implemented |
| FR-MSG-SEND-001-03 | System SHALL generate unique message ID (UUIDv4) | P0 | ✅ Implemented |
| FR-MSG-SEND-001-04 | System SHALL add timestamp to message | P0 | ✅ Implemented |
| FR-MSG-SEND-001-05 | System SHALL attempt delivery via all available transports (Bluetooth, WiFi, Mesh, Relay) | P0 | ✅ Implemented |
| FR-MSG-SEND-001-06 | System SHALL store message in outbox with status: pending/sent/delivered/failed | P1 | ✅ Implemented |
| FR-MSG-SEND-001-07 | System SHALL retry failed messages automatically (exponential backoff) | P1 | ✅ Implemented |
| FR-MSG-SEND-001-08 | System SHALL mark message as "sent" when successfully transmitted to any transport | P1 | ✅ Implemented |
| FR-MSG-SEND-001-09 | System SHALL update to "delivered" when acknowledgment received from recipient | P2 | ⬜ Partial |
| FR-MSG-SEND-001-10 | User SHALL be able to manually retry failed messages | P2 | ✅ Implemented |
| FR-MSG-SEND-001-11 | System SHALL show character count during composition | P3 | ❌ Not implemented |
| FR-MSG-SEND-001-12 | System SHALL prevent sending empty messages | P2 | ✅ Implemented |
| FR-MSG-SEND-001-13 | System SHALL support sending to multiple recipients (broadcast) | P2 | ✅ Implemented |
| FR-MSG-SEND-001-14 | System SHALL indicate which transport(s) used for delivery | P3 | ⬜ Partial |

#### 3.3.3 Input/Output

**Inputs:**
- Message text (string, 1-10KB UTF-8)
- Recipient contact ID
- Optional: delivery priority

**Outputs:**
- Encrypted packet
- Message added to outbox
- Delivery status updates
- Success/error notification

#### 3.3.4 Business Rules

- BR-MSG-SEND-001: Messages MUST be encrypted before leaving device
- BR-MSG-SEND-002: Plaintext message MUST be stored encrypted in database
- BR-MSG-SEND-003: Each message MUST use unique nonce (never reuse)
- BR-MSG-SEND-004: System MUST NOT send message if recipient's public key unavailable
- BR-MSG-SEND-005: Message timestamps MUST use UTC timezone
- BR-MSG-SEND-006: Retry attempts MUST have exponential backoff (1min, 5min, 15min, 1hr, 6hr)

#### 3.3.5 Acceptance Criteria

- [ ] Message encrypts and stores in <200ms (typical)
- [ ] Message attempts delivery via all available transports
- [ ] Failed messages retry automatically
- [ ] User sees clear delivery status (pending/sent/delivered/failed)
- [ ] No plaintext messages in database (verified via forensics)

---

### 3.4 Message Receiving

**Feature ID:** FR-MSG-RECV-001  
**Priority:** P0 (Critical)  
**Risk:** High

#### 3.4.1 Description

Receiving, decrypting, verifying, and displaying messages from contacts.

#### 3.4.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-MSG-RECV-001-01 | System SHALL listen for incoming messages on all enabled transports | P0 | ✅ Implemented |
| FR-MSG-RECV-001-02 | System SHALL validate message signature (verify sender's public key) | P0 | ✅ Implemented |
| FR-MSG-RECV-001-03 | System SHALL decrypt message using user's private key | P0 | ✅ Implemented |
| FR-MSG-RECV-001-04 | System SHALL reject messages from unknown senders (not in contacts) | P1 | ✅ Implemented |
| FR-MSG-RECV-001-05 | System SHALL detect and reject duplicate messages (same message ID) | P1 | ✅ Implemented |
| FR-MSG-RECV-001-06 | System SHALL detect replay attacks (nonce reuse) | P0 | ⬜ Partial |
| FR-MSG-RECV-001-07 | System SHALL store decrypted message in inbox (encrypted database) | P0 | ✅ Implemented |
| FR-MSG-RECV-001-08 | System SHALL send acknowledgment to sender when message received | P2 | ⬜ Partial |
| FR-MSG-RECV-001-09 | System SHALL show notification for new messages (if app in background) | P1 | ✅ Implemented |
| FR-MSG-RECV-001-10 | User SHALL be able to mark messages as read/unread | P2 | ✅ Implemented |
| FR-MSG-RECV-001-11 | System SHALL display sender's display name and timestamp | P1 | ✅ Implemented |
| FR-MSG-RECV-001-12 | System SHALL handle out-of-order message delivery gracefully | P1 | ✅ Implemented |
| FR-MSG-RECV-001-13 | System SHALL reject messages with invalid authentication tag | P0 | ✅ Implemented |
| FR-MSG-RECV-001-14 | System SHALL log security events (tampered messages, invalid signatures) | P1 | ⬜ Partial |

#### 3.4.3 Input/Output

**Inputs:**
- Encrypted packet from transport layer
- Sender's public key (from contact database)

**Outputs:**
- Decrypted message
- Message added to inbox
- Notification displayed
- Acknowledgment sent

#### 3.4.4 Business Rules

- BR-MSG-RECV-001: Messages from non-contacts MUST be rejected
- BR-MSG-RECV-002: Authentication failures MUST be logged for security audit
- BR-MSG-RECV-003: Duplicate messages (same ID) MUST be silently dropped
- BR-MSG-RECV-004: Decryption failures MUST NOT crash app
- BR-MSG-RECV-005: Notifications MUST NOT display message content on lock screen (default)

#### 3.4.5 Acceptance Criteria

- [ ] Message decrypts and displays in <500ms (typical)
- [ ] Tampered messages rejected with security log entry
- [ ] Messages from unknown senders rejected
- [ ] Notifications appear within 5 seconds of receipt
- [ ] No decrypted messages in system logs

---

### 3.5 Bluetooth LE Transport

**Feature ID:** FR-BLE-001  
**Priority:** P0 (Critical)  
**Risk:** High

#### 3.5.1 Description

Peer discovery and message transmission via Bluetooth Low Energy.

#### 3.5.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-BLE-001-01 | System SHALL broadcast BLE advertisement with service UUID | P0 | ✅ Implemented |
| FR-BLE-001-02 | System SHALL scan for other Ya OK peers via BLE | P0 | ✅ Implemented |
| FR-BLE-001-03 | System SHALL establish GATT connection with discovered peers | P0 | ✅ Implemented |
| FR-BLE-001-04 | System SHALL exchange peer IDs over BLE | P0 | ✅ Implemented |
| FR-BLE-001-05 | System SHALL check if peer is in contact list before sending messages | P0 | ✅ Implemented |
| FR-BLE-001-06 | System SHALL chunk large messages (>512 bytes) for BLE MTU | P1 | ✅ Implemented |
| FR-BLE-001-07 | System SHALL reassemble chunked messages at receiver | P1 | ✅ Implemented |
| FR-BLE-001-08 | System SHALL handle BLE disconnections gracefully | P1 | ✅ Implemented |
| FR-BLE-001-09 | System SHALL request Bluetooth permissions from user (Android 12+) | P0 | ✅ Implemented |
| FR-BLE-001-10 | User SHALL be able to disable Bluetooth transport in settings | P2 | ✅ Implemented |
| FR-BLE-001-11 | System SHALL indicate Bluetooth connection status in UI | P2 | ✅ Implemented |
| FR-BLE-001-12 | System SHALL use random MAC address (where platform supports) | P1 | ⬜ Partial |

#### 3.5.3 Input/Output

**Inputs:**
- Bluetooth enabled status
- BLE scan results
- Incoming GATT connections

**Outputs:**
- BLE advertisements
- GATT connections established
- Messages transmitted over BLE
- Connection status updates

#### 3.5.4 Business Rules

- BR-BLE-001: BLE communication MUST be encrypted at application layer (transport not trusted)
- BR-BLE-002: Peer discovery MUST respect user's privacy settings
- BR-BLE-003: BLE MUST NOT be used if user disables Bluetooth permission
- BR-BLE-004: Battery usage MUST be minimized (use BLE advertising intervals)

#### 3.5.5 Acceptance Criteria

- [ ] Peers discover each other within 30 seconds at <10m range
- [ ] Messages successfully transmitted via BLE
- [ ] Chunking/reassembly works for 10KB messages
- [ ] Graceful degradation if Bluetooth disabled

---

### 3.6 WiFi Direct Transport

**Feature ID:** FR-WIFI-001  
**Priority:** P1 (High)  
**Risk:** Medium

#### 3.6.1 Description

Peer discovery and message transmission via WiFi Direct (Android) and MultipeerConnectivity (iOS).

#### 3.6.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-WIFI-001-01 | System SHALL discover peers via WiFi Direct service discovery | P1 | ✅ Implemented |
| FR-WIFI-001-02 | System SHALL negotiate group owner for WiFi Direct connection | P1 | ✅ Implemented |
| FR-WIFI-001-03 | System SHALL establish socket connection over WiFi Direct | P1 | ✅ Implemented |
| FR-WIFI-001-04 | System SHALL transmit messages over WiFi Direct sockets | P1 | ✅ Implemented |
| FR-WIFI-001-05 | System SHALL use MultipeerConnectivity framework on iOS | P1 | ✅ Implemented |
| FR-WIFI-001-06 | System SHALL handle WiFi Direct disconnections with reconnection attempts | P1 | ✅ Implemented |
| FR-WIFI-001-07 | User SHALL be able to disable WiFi Direct transport in settings | P2 | ✅ Implemented |
| FR-WIFI-001-08 | System SHALL request location permission (Android requirement for WiFi Direct) | P0 | ✅ Implemented |
| FR-WIFI-001-09 | System SHALL indicate WiFi Direct connection status in UI | P2 | ✅ Implemented |
| FR-WIFI-001-10 | System SHALL prefer WiFi Direct over BLE for large messages (>1KB) | P2 | ⬜ Partial |

#### 3.6.3 Business Rules

- BR-WIFI-001: WiFi Direct MUST maintain application-layer encryption
- BR-WIFI-002: Group owner negotiation MUST complete within 30 seconds
- BR-WIFI-003: Socket timeouts MUST be configured (10s connection, 60s read)

#### 3.6.4 Acceptance Criteria

- [ ] Peers discover each other via WiFi Direct within 60 seconds
- [ ] Messages transmitted successfully at ~1-10 Mbps
- [ ] Automatic reconnection after WiFi Direct group teardown

---

### 3.7 Relay Server Transport

**Feature ID:** FR-RELAY-001  
**Priority:** P1 (High)  
**Risk:** Medium

#### 3.7.1 Description

Message forwarding via optional UDP relay server for internet-connected peers.

#### 3.7.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-RELAY-001-01 | System SHALL connect to relay server via UDP over TLS (DTLS) | P1 | ⬜ Partial |
| FR-RELAY-001-02 | System SHALL register with relay using user ID | P1 | ✅ Implemented |
| FR-RELAY-001-03 | System SHALL send messages to relay for offline recipients | P1 | ✅ Implemented |
| FR-RELAY-001-04 | System SHALL poll relay for pending messages | P1 | ✅ Implemented |
| FR-RELAY-001-05 | System SHALL verify relay TLS certificate (certificate pinning) | P0 | ⬜ Partial |
| FR-RELAY-001-06 | System SHALL implement rate limiting (100 messages/hour to relay) | P1 | ✅ Implemented |
| FR-RELAY-001-07 | Relay server SHALL NOT decrypt messages (E2EE preserved) | P0 | ✅ Implemented |
| FR-RELAY-001-08 | Relay server SHALL delete delivered messages within 7 days | P1 | ✅ Implemented |
| FR-RELAY-001-09 | User SHALL be able to disable relay transport in settings | P2 | ✅ Implemented |
| FR-RELAY-001-10 | User SHALL be able to configure custom relay server URL | P2 | ⬜ Partial |
| FR-RELAY-001-11 | System SHALL fall back to direct transports if relay unavailable | P1 | ✅ Implemented |
| FR-RELAY-001-12 | System SHALL authenticate to relay using signed challenge | P1 | ⬜ Partial |

#### 3.7.3 Business Rules

- BR-RELAY-001: Relay MUST use TLS 1.3 for transport security
- BR-RELAY-002: Relay MUST NOT log message contents
- BR-RELAY-003: Relay MUST implement DoS protection (rate limiting, IP blocking)
- BR-RELAY-004: Messages on relay MUST expire after 7 days

#### 3.7.4 Acceptance Criteria

- [ ] Messages delivered via relay when peers not co-located
- [ ] Certificate pinning prevents MITM attacks
- [ ] Relay does not have access to plaintext (verified via server code audit)
- [ ] Rate limiting prevents abuse

---

### 3.8 Message Persistence

**Feature ID:** FR-PERSIST-001  
**Priority:** P0 (Critical)  
**Risk:** Medium

#### 3.8.1 Description

Local storage of messages, contacts, and application state in encrypted database.

#### 3.8.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PERSIST-001-01 | System SHALL use SQLCipher for database encryption | P0 | ✅ Implemented |
| FR-PERSIST-001-02 | System SHALL generate database encryption key on first launch | P0 | ✅ Implemented |
| FR-PERSIST-001-03 | System SHALL store database key in platform keystore | P0 | ✅ Implemented |
| FR-PERSIST-001-04 | System SHALL store messages with: ID, sender/recipient, timestamp, ciphertext, status | P0 | ✅ Implemented |
| FR-PERSIST-001-05 | System SHALL store contacts with: ID, public key, display name, last seen | P0 | ✅ Implemented |
| FR-PERSIST-001-06 | System SHALL implement message retention policy (default: unlimited, max 500MB) | P1 | ✅ Implemented |
| FR-PERSIST-001-07 | User SHALL be able to delete individual messages | P2 | ✅ Implemented |
| FR-PERSIST-001-08 | User SHALL be able to delete entire conversation | P2 | ✅ Implemented |
| FR-PERSIST-001-09 | System SHALL vacuum database periodically to reclaim space | P2 | ⬜ Partial |
| FR-PERSIST-001-10 | System SHALL exclude database from device backups (or encrypt backup) | P0 | ✅ Implemented |
| FR-PERSIST-001-11 | System SHALL support exporting messages (encrypted, for archival) | P3 | ❌ Not implemented |
| FR-PERSIST-001-12 | System SHALL migrate database schema safely during app updates | P1 | ✅ Implemented |

#### 3.8.3 Business Rules

- BR-PERSIST-001: Database MUST remain encrypted at rest
- BR-PERSIST-002: Database key MUST NOT be stored in application code
- BR-PERSIST-003: Deleted messages MUST be securely wiped (VACUUM)
- BR-PERSIST-004: Database MUST be closed/locked when app enters background

#### 3.8.4 Acceptance Criteria

- [ ] Database remains encrypted (verified via filesystem inspection)
- [ ] Database key stored in hardware-backed keystore
- [ ] Message queries complete in <50ms for typical conversations (<1000 messages)
- [ ] Database excluded from Android/iOS backups

---

### 3.9 Authentication

**Feature ID:** FR-AUTH-001  
**Priority:** P1 (High)  
**Risk:** Medium

#### 3.9.1 Description

User authentication to unlock app and access messages.

#### 3.9.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AUTH-001-01 | System SHALL require authentication when app launched | P1 | ✅ Implemented |
| FR-AUTH-001-02 | System SHALL support PIN authentication (6+ digits) | P1 | ✅ Implemented |
| FR-AUTH-001-03 | System SHALL support biometric authentication (fingerprint, Face ID) | P1 | ✅ Implemented |
| FR-AUTH-001-04 | System SHALL lock after 3 failed PIN attempts (30 second delay) | P1 | ✅ Implemented |
| FR-AUTH-001-05 | System SHALL lock after 5 failed biometric attempts (fallback to PIN) | P1 | ✅ Implemented |
| FR-AUTH-001-06 | System SHALL auto-lock after configurable timeout (default: 5 minutes) | P1 | ✅ Implemented |
| FR-AUTH-001-07 | System SHALL lock immediately when app enters background | P2 | ✅ Implemented |
| FR-AUTH-001-08 | User SHALL be able to change PIN in settings | P2 | ✅ Implemented |
| FR-AUTH-001-09 | User SHALL be able to enable/disable biometric auth in settings | P2 | ✅ Implemented |
| FR-AUTH-001-10 | System SHALL use platform-secure biometric API (BiometricPrompt, LAContext) | P1 | ✅ Implemented |
| FR-AUTH-001-11 | System SHALL NOT display sensitive data on recent apps screen | P2 | ✅ Implemented |

#### 3.9.3 Business Rules

- BR-AUTH-001: Biometric authentication MUST fall back to PIN
- BR-AUTH-002: Failed authentication attempts MUST be rate-limited
- BR-AUTH-003: PIN MUST NOT be stored in plaintext
- BR-AUTH-004: Authentication state MUST NOT persist across app restarts

#### 3.9.4 Acceptance Criteria

- [ ] User cannot access messages without authentication
- [ ] Biometric auth works on supported devices
- [ ] App locks after timeout
- [ ] Rate limiting prevents brute force attacks

---

### 3.10 Settings and Configuration

**Feature ID:** FR-SETTINGS-001  
**Priority:** P2 (Medium)  
**Risk:** Low

#### 3.10.1 Description

User-configurable application settings.

#### 3.10.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-SETTINGS-001-01 | User SHALL be able to change display name | P2 | ✅ Implemented |
| FR-SETTINGS-001-02 | User SHALL be able to regenerate QR code (after name change) | P2 | ✅ Implemented |
| FR-SETTINGS-001-03 | User SHALL be able to enable/disable transports (BLE, WiFi, Relay) | P2 | ✅ Implemented |
| FR-SETTINGS-001-04 | User SHALL be able to configure relay server URL | P2 | ⬜ Partial |
| FR-SETTINGS-001-05 | User SHALL be able to configure auto-lock timeout | P2 | ✅ Implemented |
| FR-SETTINGS-001-06 | User SHALL be able to enable/disable notifications | P2 | ✅ Implemented |
| FR-SETTINGS-001-07 | User SHALL be able to configure notification privacy (hide content) | P2 | ✅ Implemented |
| FR-SETTINGS-001-08 | User SHALL be able to view app version and build info | P3 | ✅ Implemented |
| FR-SETTINGS-001-09 | User SHALL be able to export debug logs (for troubleshooting) | P3 | ⬜ Partial |
| FR-SETTINGS-001-10 | User SHALL be able to reset app (delete all data) | P3 | ✅ Implemented |

#### 3.10.3 Acceptance Criteria

- [ ] Settings persist across app restarts
- [ ] Disabling transport stops that transport's operation
- [ ] Reset deletes all data and returns to setup screen

---

### 3.11 Diagnostics and Monitoring

**Feature ID:** FR-DIAG-001  
**Priority:** P2 (Medium)  
**Risk:** Low

#### 3.11.1 Description

Tools for users and developers to diagnose connectivity and delivery issues.

#### 3.11.2 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-DIAG-001-01 | System SHALL display connection status for each transport | P2 | ✅ Implemented |
| FR-DIAG-001-02 | System SHALL show peer count for each transport | P2 | ✅ Implemented |
| FR-DIAG-001-03 | System SHALL display pending message queue size | P2 | ✅ Implemented |
| FR-DIAG-001-04 | System SHALL show last successful delivery time per contact | P2 | ✅ Implemented |
| FR-DIAG-001-05 | System SHALL provide network diagnostics screen | P2 | ✅ Implemented |
| FR-DIAG-001-06 | User SHALL be able to manually trigger connection test | P3 | ⬜ Partial |
| FR-DIAG-001-07 | System SHALL log connection events (debug mode) | P3 | ⬜ Partial |
| FR-DIAG-001-08 | User SHALL be able to view message delivery path (which transport) | P3 | ❌ Not implemented |

#### 3.11.3 Acceptance Criteria

- [ ] Connection status updates in real-time
- [ ] Diagnostic screen helps user troubleshoot connectivity issues
- [ ] Debug logs contain sufficient info for developer troubleshooting

---

## 4. External Interface Requirements

### 4.1 User Interfaces

#### 4.1.1 General UI Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| UI-001 | Interface SHALL follow platform design guidelines (Material Design, Human Interface Guidelines) | P1 |
| UI-002 | Interface SHALL support light and dark themes | P2 |
| UI-003 | Interface SHALL support accessibility features (screen readers, large text) | P2 |
| UI-004 | Interface SHALL support internationalization (English, Ukrainian, Russian initially) | P2 |
| UI-005 | Interface SHALL be responsive to different screen sizes (phones, tablets) | P2 |

#### 4.1.2 Key Screens

**Setup Screen:**
- Display name input
- Authentication setup (PIN/biometric)
- Permissions requests (Bluetooth, Location, Camera)
- QR code display

**Contacts Screen:**
- Contact list with search/filter
- Add contact button (opens camera for QR scan)
- Contact detail view (name, fingerprint, last seen, message button)

**Conversation Screen:**
- Message list (chronological, sender bubbles left, recipient bubbles right)
- Message composition input
- Send button
- Delivery status indicators

**Settings Screen:**
- User profile section (name, QR code)
- Authentication settings
- Transport enable/disable toggles
- Notification settings
- About/version info

**Diagnostics Screen:**
- Connection status indicators (Bluetooth, WiFi, Relay)
- Peer count per transport
- Pending message count
- Last delivery timestamps

### 4.2 Hardware Interfaces

| Interface | Description | Requirements |
|-----------|-------------|--------------|
| **Bluetooth Radio** | BLE 4.0+ for peer discovery | Must support GATT server + client roles |
| **WiFi Radio** | WiFi Direct (Android), MultipeerConnectivity (iOS) | 2.4GHz or 5GHz |
| **Camera** | QR code scanning | Standard rear camera, autofocus |
| **Secure Element** | Hardware-backed keystore | Android: TEE/StrongBox; iOS: Secure Enclave |
| **Network Interface** | UDP socket for relay | Standard IP networking |

### 4.3 Software Interfaces

#### 4.3.1 Operating System APIs

**Android:**
- Bluetooth API (android.bluetooth)
- WiFi Direct API (android.net.wifi.p2p)
- Keystore API (android.security.keystore)
- Camera2 API (android.hardware.camera2)
- Biometric API (androidx.biometric)

**iOS:**
- CoreBluetooth framework
- MultipeerConnectivity framework
- Keychain Services
- AVFoundation (camera)
- LocalAuthentication (biometric)

#### 4.3.2 External Libraries

| Library | Purpose | License |
|---------|---------|---------|
| **RustCrypto** | Cryptographic primitives | Apache 2.0 / MIT |
| **SQLCipher** | Encrypted database | BSD-3-Clause |
| **ZXing** | QR code scanning | Apache 2.0 |
| **AndroidX** | Android compatibility | Apache 2.0 |
| **Actix-web** | Relay server framework | Apache 2.0 / MIT |

#### 4.3.3 Rust Core FFI

The Rust core library (`ya_ok_core`) exposes C-compatible FFI for use from Kotlin/Swift:

```rust
// Example FFI functions
pub extern "C" fn core_init() -> *mut CoreContext;
pub extern "C" fn core_generate_keypair() -> KeypairResult;
pub extern "C" fn core_encrypt_message(plaintext: *const u8, len: usize, recipient_key: *const u8) -> EncryptedMessage;
pub extern "C" fn core_decrypt_message(ciphertext: *const u8, len: usize, sender_key: *const u8) -> DecryptedMessage;
pub extern "C" fn core_send_to_transport(message: *const u8, transport: TransportType) -> SendResult;
```

### 4.4 Communication Interfaces

#### 4.4.1 Bluetooth LE Protocol

**Service UUID:** `00001101-0000-1000-8000-00805F9B34FB` (custom Ya OK service)

**Characteristics:**
- **Peer ID Characteristic:** Read (UUID: `00001102-...`)
- **Message TX Characteristic:** Write (UUID: `00001103-...`)
- **Message RX Characteristic:** Notify (UUID: `00001104-...`)

**Message Format:**
```
[Version:1][MessageID:16][Sender:32][Recipient:32][Nonce:24][Ciphertext:N][Tag:16]
```

#### 4.4.2 WiFi Direct Protocol

**Service Name:** `_yaok._tcp`  
**Port:** Dynamic (negotiated)  
**Protocol:** TCP sockets with TLV framing

**Frame Format:**
```
[Type:1][Length:2][Value:N]
```

#### 4.4.3 Relay Server Protocol

**Endpoint:** `wss://relay.yaok.app:8080` (WebSocket over TLS)  
**Authentication:** HMAC-SHA256 signed challenge

**Message Types:**
- `REGISTER` - Client registers with relay
- `SEND` - Client sends message to relay for forwarding
- `POLL` - Client polls for pending messages
- `ACK` - Acknowledgment of delivery
- `HEARTBEAT` - Keep-alive

**Packet Format:**
```json
{
  "type": "SEND",
  "message_id": "uuid",
  "sender_id": "hex",
  "recipient_id": "hex",
  "ciphertext": "base64",
  "timestamp": "iso8601"
}
```

---

## 5. System Constraints

### 5.1 Technical Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| **Platform Versions** | Android 7+ (API 24), iOS 14+ | Limits available platform features |
| **Bluetooth Range** | ~10-50 meters typical | Messages only delivered to nearby peers |
| **Message Size** | Max 10KB per message | Large messages must be split by user |
| **Database Size** | Max 500MB enforced | Old messages must be deleted after limit |
| **Concurrent Connections** | Max 10 BLE connections | Limited peer connections |
| **Battery Usage** | Must minimize background operations | Affects polling frequency |
| **Cryptographic Algorithms** | Only use audited libraries (RustCrypto) | No custom crypto implementations |

### 5.2 Regulatory Constraints

| Regulation | Requirement | Compliance |
|------------|-------------|------------|
| **GDPR** | Data minimization, user consent, right to deletion | ✅ No PII collected, local storage only |
| **CCPA** | Privacy policy, data access, deletion | ✅ Covered by GDPR compliance |
| **Export Control** | Strong encryption may be restricted in some countries | ⚠️ App store availability limited |
| **Google Play Policy** | Encryption, privacy policy, permissions justification | ✅ In compliance |
| **App Store Review** | Privacy manifest, permission usage descriptions | ✅ In compliance |

### 5.3 Design Constraints

| Constraint | Rationale |
|------------|-----------|
| **No central server for user data** | Privacy requirement - no user database |
| **QR code for key exchange** | Prevents MITM, requires physical proximity |
| **No phone numbers** | Privacy - phone numbers are PII |
| **No cloud sync** | Security - increases attack surface |
| **Open source (GPL v3)** | Transparency for security audit |
| **Rust for crypto** | Memory safety prevents common crypto bugs |

### 5.4 Assumptions

1. Users trust the device they install the app on (no anti-malware in scope)
2. Users understand basic messaging app UX patterns
3. QR code key exchange is acceptable UX (no online key directory)
4. Store-and-forward delays are acceptable (not real-time chat)
5. Relay server is optional (app works offline)

---

## 6. Non-Functional Requirements

### 6.1 Performance Requirements

| ID | Requirement | Target | Measurement |
|----|-------------|--------|-------------|
| NFR-PERF-001 | Message encryption time | <100ms | Unit test |
| NFR-PERF-002 | Message decryption time | <100ms | Unit test |
| NFR-PERF-003 | Database query time (message list) | <50ms | Integration test |
| NFR-PERF-004 | App cold start time | <3s | User testing |
| NFR-PERF-005 | BLE peer discovery time | <30s | Integration test |
| NFR-PERF-006 | WiFi Direct connection time | <60s | Integration test |
| NFR-PERF-007 | Message delivery latency (co-located) | <5s | E2E test |
| NFR-PERF-008 | UI responsiveness (frame rate) | ≥30fps | Performance profiling |
| NFR-PERF-009 | Memory usage (typical) | <150MB RAM | Profiling |
| NFR-PERF-010 | Battery drain (background) | <5%/hour | Battery testing |

### 6.2 Security Requirements

See **YA-OK-SEC-002** (Security Requirements Specification) for comprehensive security requirements. Key highlights:

| ID | Category | Requirement |
|----|----------|-------------|
| NFR-SEC-001 | Cryptography | XChaCha20-Poly1305 AEAD for encryption |
| NFR-SEC-002 | Key Exchange | X25519 elliptic curve Diffie-Hellman |
| NFR-SEC-003 | Key Storage | Platform keystore (hardware-backed where available) |
| NFR-SEC-004 | Data at Rest | SQLCipher for database encryption |
| NFR-SEC-005 | Data in Transit | TLS 1.3 for relay, app-layer encryption for all transports |
| NFR-SEC-006 | Authentication | PIN 6+ digits or biometric |
| NFR-SEC-007 | Nonce Uniqueness | Cryptographic RNG, never reuse nonces |
| NFR-SEC-008 | Code Security | No hardcoded secrets, secure coding practices |
| NFR-SEC-009 | Logging | No sensitive data in logs |
| NFR-SEC-010 | Compliance | OWASP MASVS L2, ISO 27001 controls |

### 6.3 Reliability Requirements

| ID | Requirement | Target | Priority |
|----|-------------|--------|----------|
| NFR-REL-001 | App crash rate | <1% sessions | P0 |
| NFR-REL-002 | Message delivery success (co-located) | >95% | P0 |
| NFR-REL-003 | Database corruption rate | <0.01% users | P0 |
| NFR-REL-004 | Transport auto-recovery after failure | Within 60s | P1 |
| NFR-REL-005 | Message retry on failure | Up to 6 attempts | P1 |
| NFR-REL-006 | Graceful degradation (transport failure) | Switch to alternative transport | P1 |

### 6.4 Availability Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-AVAIL-001 | App uptime (not crashed) | >99.9% |
| NFR-AVAIL-002 | Relay server uptime | >99.5% |
| NFR-AVAIL-003 | Offline functionality | 100% (core messaging works offline) |

### 6.5 Maintainability Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-MAINT-001 | Code coverage (unit tests) | >80% |
| NFR-MAINT-002 | Code documentation | All public APIs documented |
| NFR-MAINT-003 | Architecture documentation | Up-to-date C4 diagrams |
| NFR-MAINT-004 | Dependency updates | Monthly security patch check |
| NFR-MAINT-005 | Code review | 100% of changes reviewed before merge |

### 6.6 Portability Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| NFR-PORT-001 | Android platform support | ✅ API 24+ |
| NFR-PORT-002 | iOS platform support | ✅ iOS 14+ |
| NFR-PORT-003 | Database schema portability | ✅ SQLite (cross-platform) |
| NFR-PORT-004 | Rust core portability | ✅ Compiles for Android, iOS |
| NFR-PORT-005 | Message format portability | ✅ Binary format, endian-safe |

### 6.7 Usability Requirements

| ID | Requirement | Target | Priority |
|----|-------------|--------|----------|
| NFR-USE-001 | First-time setup completion rate | >90% | P1 |
| NFR-USE-002 | Add contact success rate (QR scan) | >95% | P1 |
| NFR-USE-003 | User comprehension of E2EE | >70% (survey) | P2 |
| NFR-USE-004 | User satisfaction (NPS score) | >40 | P2 |
| NFR-USE-005 | Accessibility (WCAG 2.1 AA) | Partial compliance | P2 |

### 6.8 Scalability Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-SCALE-001 | Max contacts per user | 500 |
| NFR-SCALE-002 | Max messages in database | 50,000 |
| NFR-SCALE-003 | Relay server capacity | 10,000 concurrent users |
| NFR-SCALE-004 | Message throughput (per device) | 100 messages/hour |

---

## 7. Appendices

### Appendix A: Feature Priority Matrix

| Feature | Business Value | Technical Risk | Dependencies | Priority |
|---------|---------------|----------------|--------------|----------|
| User Registration | Critical | Low | None | P0 |
| Contact Management | Critical | Low | User Registration | P0 |
| Message Send/Receive | Critical | High | Contacts, Encryption | P0 |
| Encryption/Decryption | Critical | High | None | P0 |
| Bluetooth Transport | Critical | High | Platform APIs | P0 |
| Message Persistence | Critical | Medium | Database, Encryption | P0 |
| Authentication | High | Low | Platform APIs | P1 |
| WiFi Direct Transport | High | Medium | Platform APIs | P1 |
| Relay Transport | High | Medium | Server Infrastructure | P1 |
| Diagnostics | Medium | Low | Transports | P2 |
| Settings | Medium | Low | None | P2 |
| Mesh Networking | Low | High | Multiple transports | P3 (future) |
| Group Chat | Medium | High | Message format changes | P3 (future) |

### Appendix B: Use Case Diagrams

```
┌─────────────────────────────────────────────────────────┐
│                     Ya OK Use Cases                      │
│                                                          │
│   ┌────────┐                                            │
│   │  User  │                                            │
│   └───┬────┘                                            │
│       │                                                  │
│       ├──────► Setup Account                            │
│       │                                                  │
│       ├──────► Add Contact (QR Scan)                    │
│       │                                                  │
│       ├──────► Send Message ────► Select Transport      │
│       │                                                  │
│       ├──────► Receive Message ◄─── Decrypt Message     │
│       │                                                  │
│       ├──────► View Conversation                        │
│       │                                                  │
│       ├──────► Authenticate (PIN/Biometric)             │
│       │                                                  │
│       ├──────► Configure Settings                       │
│       │                                                  │
│       └──────► View Diagnostics                         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Appendix C: Data Model (Simplified)

**Users Table:**
```sql
CREATE TABLE users (
    user_id TEXT PRIMARY KEY,
    private_key_ref TEXT NOT NULL,  -- Reference to keystore
    public_key BLOB NOT NULL,
    display_name TEXT NOT NULL,
    created_at INTEGER NOT NULL
);
```

**Contacts Table:**
```sql
CREATE TABLE contacts (
    contact_id TEXT PRIMARY KEY,
    public_key BLOB NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    fingerprint TEXT NOT NULL,
    added_at INTEGER NOT NULL,
    last_seen INTEGER
);
```

**Messages Table:**
```sql
CREATE TABLE messages (
    message_id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    sender_id TEXT NOT NULL,
    recipient_id TEXT NOT NULL,
    ciphertext BLOB NOT NULL,
    nonce BLOB NOT NULL,
    timestamp INTEGER NOT NULL,
    status TEXT NOT NULL,  -- pending, sent, delivered, failed
    transport TEXT,  -- ble, wifi, relay
    created_at INTEGER NOT NULL,
    FOREIGN KEY (sender_id) REFERENCES contacts(contact_id),
    FOREIGN KEY (recipient_id) REFERENCES contacts(contact_id)
);
```

### Appendix D: Traceability Matrix (Sample)

| Requirement ID | Test Case ID | Design Document | Code Module |
|----------------|--------------|-----------------|-------------|
| FR-USER-001-01 | TC-USER-001 | ARCH-001 § 3.1 | KeyManager.kt |
| FR-CRYPTO-001 | TC-CRYPTO-001 | SEC-002 REQ-CRYPTO-001 | crypto.rs |
| FR-MSG-SEND-001-02 | TC-MSG-001 | SEC-002 REQ-CRYPTO-002 | encryption.rs |
| FR-BLE-001-01 | TC-BLE-001 | NET-001 § 2.1 | BluetoothManager.kt |

*(Full traceability matrix in separate document: Requirements Traceability Matrix)*

### Appendix E: Change Log

| Version | Date | Changes |
|---------|------|---------|
| 0.1 | 2025-12-01 | Initial draft based on product vision |
| 0.3 | 2026-01-05 | Added security requirements from threat model |
| 0.5 | 2026-01-15 | Feature freeze - all v1.0 requirements documented |
| 0.8 | 2026-01-28 | Integrated feedback from security review |
| 1.0 | 2026-02-06 | Final approval - baseline for v1.0 development |

### Appendix F: Glossary

| Term | Definition |
|------|------------|
| **AEAD** | Authenticated Encryption with Associated Data - encryption that also authenticates |
| **BLE** | Bluetooth Low Energy - low-power wireless protocol |
| **Contact** | A verified peer with stored public key |
| **DTN** | Delay-Tolerant Network - network design for intermittent connectivity |
| **E2EE** | End-to-End Encryption - only sender and recipient can read messages |
| **Fingerprint** | Short hash of public key for verification |
| **GATT** | Generic Attribute Profile - BLE communication protocol |
| **Nonce** | Number used once - unique per encryption operation |
| **Peer** | Another Ya OK user |
| **Relay** | Server that forwards messages (cannot decrypt) |
| **SQLCipher** | Encrypted SQLite database |
| **Store-and-forward** | Holding messages for later delivery |
| **Transport** | Communication channel (BLE, WiFi, Relay) |
| **XChaCha20-Poly1305** | Authenticated encryption algorithm |
| **X25519** | Elliptic curve key exchange algorithm |

---

**Document Status:** APPROVED  
**Baseline Version:** 1.0  
**Effective Date:** 2026-02-06  
**Next Review:** 2026-05-06 (quarterly)

**Approval Signatures:**

- **Product Owner:** __________________ Date: __________
- **Technical Lead:** __________________ Date: __________
- **Security Architect:** __________________ Date: __________
- **QA Lead:** __________________ Date: __________

---

**Classification:** INTERNAL  
**Distribution:** Development team, QA team, Product management, Security team  
**Storage:** Project repository `/docs/SRS.md`

---

*This document is the authoritative source for Ya OK v1.0 requirements. All development, testing, and validation activities must be traceable to requirements documented herein.*
