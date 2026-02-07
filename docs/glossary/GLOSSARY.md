# Ya OK Glossary & Terminology
## Comprehensive Reference for Technical Terms

**Document ID:** YA-OK-GLOSS-001  
**Version:** 1.0  
**Date:** 2026-02-07  
**Classification:** PUBLIC

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-07 | Documentation Team | Initial glossary for ISO/IEC 12207 compliance |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [General Terms](#2-general-terms)
3. [Cryptography & Security](#3-cryptography--security)
4. [Networking & Communication](#4-networking--communication)
5. [Software Architecture](#5-software-architecture)
6. [Mobile Development](#6-mobile-development)
7. [Business & Metrics](#7-business--metrics)
8. [Standards & Compliance](#8-standards--compliance)
9. [Acronyms & Abbreviations](#9-acronyms--abbreviations)
10. [References](#10-references)

---

## 1. Introduction

### 1.1 Purpose

This glossary provides comprehensive definitions for technical terms, acronyms, and concepts used throughout the Ya OK secure messaging platform documentation. It serves as a reference for:

- Developers
- QA engineers
- Documentation writers
- Security auditors
- Stakeholders
- End users (simplified definitions)

### 1.2 Scope

The glossary covers terms from:

- Cryptography and security
- Networking and communication protocols
- Software architecture and design
- Mobile development (Android, iOS)
- Business metrics and KPIs
- Industry standards and compliance frameworks

### 1.3 Document Conventions

**Term Formatting:**
- **Bold** for primary term
- *Italics* for alternative names or related terms
- `Code` for technical identifiers

**Cross-References:**
- → See also
- ≈ Similar to
- ⊂ Subset of

---

## 2. General Terms

### A

**ACID**  
*Atomicity, Consistency, Isolation, Durability*  
Properties that guarantee database transactions are processed reliably:
- **Atomicity**: Transaction is all-or-nothing
- **Consistency**: Database remains in valid state
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed data persists after crashes

**API** *(Application Programming Interface)*  
Set of functions, protocols, and tools for building software applications. In Ya OK, refers to:
- FFI interface (Rust ↔ mobile apps)
- Relay server UDP protocol
- HTTP endpoints for health/metrics

**Asynchronous**  
Operations that don't block execution. Used in Ya OK for:
- Network I/O (Tokio async runtime)
- Message encryption (background threads)
- File transfers (non-blocking)

### B

**Background Service**  
Service that runs when app is not in foreground. Ya OK uses:
- Android: WorkManager for message checking
- iOS: BGTaskScheduler for background refresh

**Binary Protocol**  
Protocol that uses binary format (not text). Ya OK relay uses binary UDP packets for efficiency.

**Biometric Authentication**  
Authentication using biological characteristics (fingerprint, face). Ya OK supports:
- Android: BiometricPrompt API
- iOS: LocalAuthentication framework (Touch ID/Face ID)

**Blockchain**  
*Not used in Ya OK.* Distributed ledger technology. Mentioned here because Ya OK is sometimes mistakenly described as blockchain-based (it is not).

**Build System**  
Tools for compiling and packaging applications:
- Android: Gradle
- iOS: Xcode Build System
- Rust: Cargo

### C

**Cache**  
Temporary storage for frequently accessed data. Ya OK caches:
- Message list (in-memory)
- Contact list (in-memory)
- Images (disk cache, LRU)

**Certificate Pinning**  
Security technique that associates a service with its cryptographic certificate. Ya OK pins relay server TLS certificate to prevent MITM attacks.

**CI/CD** *(Continuous Integration/Continuous Deployment)*  
Automated pipeline for building, testing, and deploying code. Ya OK uses GitHub Actions.

**Client-Server Architecture**  
Architecture where clients request services from central server. Ya OK uses hybrid:
- Peer-to-peer (BLE, WiFi Direct)
- Client-server (relay server for remote messages)

**Cold Start**  
App launch when process is not in memory. Ya OK targets < 3 seconds.

**Concurrency**  
Multiple operations happening simultaneously. Ya OK handles:
- Multiple transports (BLE + WiFi + Relay)
- Concurrent message encryption
- Parallel database operations

**Container** *(Architecture)*  
Deployable unit (app, database, server). In C4 model:
- Android app
- iOS app
- Rust core library
- Relay server
- SQLite database

**CRUD** *(Create, Read, Update, Delete)*  
Basic database operations. Ya OK implements CRUD for:
- Messages
- Contacts
- User identity

### D

**Database Migration**  
Process of updating database schema. Ya OK uses:
- Android: Room migrations
- iOS: Core Data migrations
- Rust: Rusqlite migrations

**Dead Letter Queue**  
Queue for messages that couldn't be delivered. Ya OK queues failed messages locally for retry.

**Dependency Injection**  
Design pattern for providing dependencies. Used in Android app via Hilt.

**Dockerfile**  
Script for building Docker container images. Ya OK relay server uses Dockerfile for Fly.io deployment.

**DTN** *(Delay-Tolerant Networking)*  
Networking approach for intermittent connectivity. Ya OK implements DTN via:
- Store-and-forward (messages queue when offline)
- Opportunistic routing (forward via intermediate peers)

### E

**E2EE** *(End-to-End Encryption)*  
Encryption where only sender and recipient can decrypt messages. Ya OK implements E2EE with XChaCha20-Poly1305.

**Encryption at Rest**  
Encrypting data when stored on disk. Ya OK uses SQLCipher for database encryption.

**Encryption in Transit**  
Encrypting data during transmission. Ya OK encrypts:
- Messages (E2EE)
- Relay server connection (TLS 1.3)

**Endpoint**  
Network address for service. Ya OK relay endpoints:
- `relay.yaok.app:41641` (UDP)
- `relay.yaok.app/health` (HTTP)

**Error Handling**  
Managing errors gracefully. Ya OK uses:
- Rust: Result<T, E> types
- Android: try-catch + error dialogs
- iOS: do-catch + error alerts

**Event Loop**  
Programming construct for async event processing. Tokio uses event loop for Ya OK relay server.

### F

**Fallback**  
Alternative when primary method fails. Ya OK transport fallback:
- BLE (primary) → WiFi Direct → Relay (fallback)

**FFI** *(Foreign Function Interface)*  
Mechanism for calling code in another language. Ya OK uses FFI for Rust ↔ Android/iOS.

**Fingerprint** *(Security)*  
Unique identifier derived from public key. Ya OK safety number is SHA-256 fingerprint.

**Firewall**  
Network security system. Ya OK relay server protected by Fly.io firewall.

**Forward Secrecy** *(Perfect Forward Secrecy, PFS)*  
Property where past session keys can't be compromised even if long-term key is leaked. Planned for future Ya OK version using Signal Protocol.

### G

**GATT** *(Generic Attribute Profile)*  
Bluetooth LE protocol for data exchange. Ya OK uses GATT for BLE messaging.

**Git**  
Version control system. Ya OK source code hosted on GitHub.

**gRPC**  
*Not used in Ya OK.* RPC framework. Mentioned for comparison (Ya OK uses simpler UDP protocol).

### H

**Handshake**  
Protocol initialization exchange. Ya OK relay handshake:
1. Client sends REGISTER packet
2. Server responds with REGISTERED packet
3. Client authenticated via Ed25519 signature

**Hash Function**  
Function that maps data to fixed-size value. Ya OK uses:
- SHA-256 for fingerprints
- Blake2b for message IDs

**Health Check**  
Monitoring endpoint to verify service health. Ya OK relay `/health` endpoint returns status.

**HTTPS** *(HTTP Secure)*  
HTTP over TLS. Ya OK relay HTTP endpoints use HTTPS.

**Hot Start**  
App launch when process is in memory. Ya OK targets < 1 second.

### I

**Idempotent**  
Operation that produces same result when repeated. Ya OK message delivery is idempotent (duplicate messages ignored).

**Infrastructure as Code** *(IaC)*  
Managing infrastructure via configuration files. Ya OK uses `fly.toml` for relay deployment.

**Integration Test**  
Test verifying multiple components work together. Ya OK has 161 integration tests.

**Internationalization** *(i18n)*  
Designing software for multiple languages. Ya OK supports 10+ languages.

**IPC** *(Inter-Process Communication)*  
Communication between processes. Android uses Binder IPC; Ya OK uses it for JNI calls.

### J

**JNI** *(Java Native Interface)*  
Java API for calling native code. Ya OK Android app uses JNI to call Rust core.

**JSON** *(JavaScript Object Notation)*  
Text format for data exchange. Ya OK uses JSON for:
- Message content (plaintext structure)
- Logs (structured logging)
- Configuration (future)

**JWT** *(JSON Web Token)*  
*Not used in Ya OK.* Token format for authentication. Mentioned for comparison (Ya OK uses custom session tokens).

### K

**Keychain** *(iOS)*  
Secure storage for sensitive data. Ya OK stores identity keys in iOS Keychain.

**Keystore** *(Android)*  
Secure storage for cryptographic keys. Ya OK uses Android Keystore for identity keys.

**KPI** *(Key Performance Indicator)*  
Metric for measuring success. Ya OK KPIs:
- Daily Active Users (DAU)
- Message delivery success rate
- Crash-free rate

### L

**Latency**  
Delay between action and response. Ya OK targets:
- < 300ms for BLE/WiFi (p95)
- < 1s for relay (p95)

**Load Balancer**  
Distributes traffic across servers. Fly.io provides load balancing for Ya OK relay.

**Localization** *(l10n)*  
Adapting software for specific locale. Ya OK provides translations for 10+ languages.

**Logging**  
Recording events for debugging/monitoring. Ya OK uses structured JSON logging.

**LRU** *(Least Recently Used)*  
Cache eviction strategy. Ya OK image cache uses LRU.

### M

**MAC** *(Message Authentication Code)*  
Cryptographic checksum for verifying message integrity. Ya OK uses Poly1305 MAC.

**Mesh Network**  
Network where nodes connect to each other without central coordinator. Ya OK uses mesh for opportunistic forwarding.

**Metadata**  
Data about data. Ya OK minimizes metadata:
- Relay server sees: User IDs (random UUIDs), timestamps, sizes
- Relay server doesn't see: Names, content, social graph

**Migration** *(Database)*  
Updating database schema. See **Database Migration**.

**MITM** *(Man-in-the-Middle Attack)*  
Attack where attacker intercepts communication. Ya OK prevents via:
- E2EE (attacker can't read messages)
- Safety number verification (detect impersonation)
- Certificate pinning (prevent server impersonation)

**MVP** *(Minimum Viable Product)*  
Product with minimum features for early adopters. Ya OK MVP: 1-on-1 messaging with E2EE.

### N

**Native App**  
App built with platform-specific technologies. Ya OK uses:
- Android: Kotlin
- iOS: Swift

**Network Socket**  
Endpoint for network communication. Ya OK uses UDP sockets for relay.

**Nonce** *(Number used Once)*  
Random value used once. Ya OK uses 192-bit nonces for encryption to prevent replay attacks.

**Notification**  
Alert shown to user. Ya OK uses:
- Android: NotificationManager
- iOS: UNUserNotificationCenter

### O

**Obfuscation**  
Making code hard to understand. Ya OK uses ProGuard (Android) to prevent reverse engineering.

**Offline-First**  
Design prioritizing offline functionality. Ya OK works offline via BLE/WiFi Direct.

**Onboarding**  
Process of introducing new users to app. Ya OK onboarding:
1. Create identity
2. Backup identity
3. Add first contact

**Open Source**  
Software with publicly available source code. Ya OK is open source (MIT license).

**Opportunistic Routing**  
Forwarding messages via intermediate nodes. Ya OK forwards messages between offline users.

### P

**Packet**  
Unit of data transmitted over network. Ya OK relay uses binary UDP packets.

**Pagination**  
Loading data in chunks. Ya OK paginates message history.

**Peer-to-Peer** *(P2P)*  
Direct communication between devices without server. Ya OK uses P2P for BLE/WiFi Direct.

**Penetration Testing** *(Pentest)*  
Security testing by simulating attacks. Ya OK undergoes annual pentests.

**Persistent Storage**  
Storage that survives app/device restarts. Ya OK uses SQLite for persistent storage.

**PKI** *(Public Key Infrastructure)*  
*Not used in Ya OK.* System for managing digital certificates. Ya OK uses simpler trust-on-first-use (TOFU) model.

**Plaintext**  
Unencrypted data. Ya OK never stores message plaintext on relay server.

**Polling**  
Repeatedly checking for updates. Ya OK clients poll relay server every 30 seconds for new messages.

**Protocol**  
Rules for communication. Ya OK protocols:
- BLE GATT protocol
- WiFi Direct NSD protocol
- Custom UDP relay protocol

**Push Notification**  
Notification delivered via server. Ya OK uses Firebase Cloud Messaging (FCM) for push notifications.

### Q

**QR Code** *(Quick Response Code)*  
2D barcode for storing data. Ya OK uses QR codes for:
- Sharing identity (contains public keys)
- Adding contacts

**Queue**  
Data structure for first-in-first-out (FIFO) processing. Ya OK queues:
- Outgoing messages (when offline)
- Incoming messages (on relay server)

### R

**Rate Limiting**  
Restricting request frequency. Ya OK relay limits:
- 100 messages per user per minute
- 60 polls per user per minute

**Relay Server**  
Server that forwards messages between clients. Ya OK relay enables remote messaging.

**Replay Attack**  
Reusing captured message to impersonate sender. Ya OK prevents via nonces.

**REST** *(Representational State Transfer)*  
Architectural style for web services. Ya OK relay HTTP endpoints are RESTful.

**Retry Logic**  
Automatically retrying failed operations. Ya OK retries:
- Failed message sends (exponential backoff)
- Failed relay connections (reconnect)

**RPC** *(Remote Procedure Call)*  
Protocol for executing function on remote server. Ya OK relay protocol is RPC-like.

**RTO** *(Recovery Time Objective)*  
Maximum acceptable downtime. Ya OK target: 30 minutes.

**RPO** *(Recovery Point Objective)*  
Maximum acceptable data loss. Ya OK target: 1 hour.

### S

**Salt** *(Cryptographic)*  
Random data added to input before hashing. Ya OK uses salts for key derivation.

**SDK** *(Software Development Kit)*  
Tools for developing software. Ya OK uses:
- Android SDK
- iOS SDK
- Rust standard library

**Semantic Versioning**  
Versioning scheme (MAJOR.MINOR.PATCH). Ya OK uses semantic versioning.

**Session**  
Period of user activity. Ya OK session:
- Starts when app opens
- Ends when app closes or times out

**Sideloading**  
Installing app outside official store. Ya OK supports sideloading for testing.

**SLA** *(Service Level Agreement)*  
Commitment to service availability. Ya OK relay target: 99.9% uptime.

**SLI** *(Service Level Indicator)*  
Metric for measuring service performance. Ya OK SLIs:
- Availability (uptime)
- Latency (response time)
- Error rate

**SLO** *(Service Level Objective)*  
Target value for SLI. Ya OK SLOs:
- 99.9% availability
- < 1s latency (p95)
- < 0.1% error rate

**SOLID Principles**  
Software design principles:
- Single Responsibility
- Open/Closed
- Liskov Substitution
- Interface Segregation
- Dependency Inversion

**Store-and-Forward**  
Storing messages until recipient available. Ya OK relay queues messages.

**STRIDE** *(Threat Model)*  
Framework for threat modeling:
- **S**poofing
- **T**ampering
- **R**epudiation
- **I**nformation disclosure
- **D**enial of service
- **E**levation of privilege

### T

**TLS** *(Transport Layer Security)*  
Protocol for secure communication. Ya OK relay HTTPS uses TLS 1.3.

**Token**  
Credential for authentication. Ya OK relay session tokens (16-byte random).

**TOFU** *(Trust On First Use)*  
Security model trusting first encounter. Ya OK uses TOFU for contact keys.

**Transport**  
Mechanism for sending messages. Ya OK supports 3 transports:
- BLE (Bluetooth Low Energy)
- WiFi Direct
- Relay (internet)

**TTL** *(Time To Live)*  
Duration before data expires. Ya OK message TTL on relay: 7 days.

### U

**UDP** *(User Datagram Protocol)*  
Connectionless transport protocol. Ya OK relay uses UDP for low latency.

**UI/UX**  
User Interface / User Experience. Ya OK focuses on intuitive UI/UX.

**Unit Test**  
Test for individual function/class. Ya OK has 345 unit tests.

**UUID** *(Universally Unique Identifier)*  
128-bit identifier. Ya OK uses UUIDs for:
- User IDs (random v4)
- Message IDs (random v4)

### V

**Verification**  
Confirming something is correct. Ya OK verifications:
- Safety number verification (contact authenticity)
- Message signature verification (message authenticity)

**Version Control**  
System for tracking code changes. Ya OK uses Git.

**VPN** *(Virtual Private Network)*  
*Compatible with Ya OK.* Ya OK works over VPN connections.

### W

**WAL** *(Write-Ahead Logging)*  
SQLite journaling mode for better concurrency. Ya OK uses WAL mode.

**WebSocket**  
*Not used in Ya OK.* Protocol for bidirectional communication. Ya OK uses UDP instead for lower overhead.

**WiFi Direct**  
Peer-to-peer WiFi standard. Ya OK uses for local messaging without internet.

### X

**XSS** *(Cross-Site Scripting)*  
*Not applicable to Ya OK.* Web vulnerability. Mentioned because native apps aren't vulnerable to XSS.

### Z

**Zero-Knowledge**  
System where server doesn't know user data. Ya OK is zero-knowledge:
- Server never sees message content
- Server doesn't store user names
- Server doesn't know social graph

---

## 3. Cryptography & Security

### AEAD *(Authenticated Encryption with Associated Data)*  
Encryption mode providing confidentiality and authenticity. Ya OK uses XChaCha20-Poly1305 AEAD.

### AES *(Advanced Encryption Standard)*  
*Not used in Ya OK.* Symmetric encryption algorithm. Ya OK uses XChaCha20 instead (faster, no timing attacks).

### Algorithm Agility  
Ability to change cryptographic algorithms. Ya OK designed for algorithm agility (future migration to quantum-resistant crypto).

### Attack Vector  
Method of exploiting vulnerability. Ya OK defends against vectors:
- MITM (via E2EE, safety numbers)
- Replay (via nonces)
- Brute force (via 256-bit keys)
- Side-channel (via constant-time crypto)

### Authenticated Encryption  
See **AEAD**.

### Blake2b  
Fast cryptographic hash function. Ya OK uses for message IDs (collision-resistant, faster than SHA-256).

### Brute Force Attack  
Trying all possible keys. Infeasible for Ya OK's 256-bit keys (2^256 attempts).

### Certificate  
Digital document binding public key to identity. Ya OK relay uses Let's Encrypt TLS certificate.

### Cipher  
Algorithm for encryption. Ya OK uses XChaCha20 cipher.

### Ciphertext  
Encrypted data. Ya OK transmits ciphertext over network.

### Constant-Time Operations  
Operations taking same time regardless of input. Ya OK crypto uses constant-time to prevent timing attacks.

### Cryptanalysis  
Study of breaking cryptographic systems. Ya OK uses algorithms resistant to known cryptanalysis.

### Cryptographic Primitive  
Basic cryptographic building block:
- Hash (SHA-256, Blake2b)
- Cipher (XChaCha20)
- MAC (Poly1305)
- Signature (Ed25519)
- Key exchange (X25519)

### CRYSTALS-Kyber  
Post-quantum key exchange algorithm. Planned for future Ya OK version.

### CSPRNG *(Cryptographically Secure Pseudo-Random Number Generator)*  
RNG suitable for cryptography. Ya OK uses `ring::rand` CSPRNG.

### Curve25519  
Elliptic curve for cryptography. Ya OK uses:
- X25519 for key exchange (ECDH)
- Ed25519 for signatures

### DH *(Diffie-Hellman)*  
Key exchange protocol. Ya OK uses Elliptic Curve DH (X25519).

### Digital Signature  
Cryptographic proof of authenticity. Ya OK uses Ed25519 signatures on all messages.

### ECDH *(Elliptic Curve Diffie-Hellman)*  
Key exchange using elliptic curves. Ya OK uses X25519 ECDH.

### ECDSA *(Elliptic Curve Digital Signature Algorithm)*  
*Not used in Ya OK.* Signature algorithm. Ya OK uses Ed25519 instead (faster, deterministic).

### Ed25519  
EdDSA signature scheme using Curve25519. Ya OK uses for:
- User identity keys
- Message signatures
- Relay authentication

### EdDSA *(Edwards-curve Digital Signature Algorithm)*  
Signature scheme family. Ya OK uses Ed25519 variant.

### Entropy  
Randomness. Ya OK uses OS entropy sources for cryptographic randomness.

### Forward Secrecy  
See **Forward Secrecy** in General Terms.

### Hash Function  
Function mapping data to fixed-size digest. Ya OK uses:
- SHA-256 for safety numbers
- Blake2b for message IDs

### HKDF *(HMAC-based Key Derivation Function)*  
Function for deriving keys. Planned for future Ya OK version (perfect forward secrecy).

### HMAC *(Hash-based Message Authentication Code)*  
MAC using hash function. Ya OK uses Poly1305 instead (faster).

### HSM *(Hardware Security Module)*  
*Not used in Ya OK.* Specialized hardware for crypto. Ya OK uses software crypto with hardware-backed key storage.

### IV *(Initialization Vector)*  
Random value for encryption. XChaCha20 uses 192-bit nonces (similar to IV).

### Key Derivation  
Generating keys from master key. Planned for Ya OK perfect forward secrecy.

### Key Exchange  
Establishing shared secret. Ya OK uses X25519 ECDH.

### Key Rotation  
Periodically changing keys. Planned for future Ya OK version.

### Keystream  
Pseudo-random stream for stream cipher. XChaCha20 generates keystream.

### MAC *(Message Authentication Code)*  
See **MAC** in General Terms.

### NaCl *(Networking and Cryptography Library)*  
Crypto library by Daniel J. Bernstein. Ya OK algorithms based on NaCl/libsodium.

### Nonce  
See **Nonce** in General Terms.

### PBKDF2 *(Password-Based Key Derivation Function 2)*  
Deriving keys from passwords. Not currently used in Ya OK (no password-based encryption).

### PGP *(Pretty Good Privacy)*  
*Not used in Ya OK.* Encryption program. Ya OK uses custom E2EE protocol.

### Poly1305  
Fast MAC algorithm. Part of XChaCha20-Poly1305 AEAD used by Ya OK.

### Post-Quantum Cryptography  
Algorithms resistant to quantum computers. Planned for future Ya OK version.

### Private Key  
Secret key in asymmetric cryptography. Ya OK identity includes:
- X25519 private key (key exchange)
- Ed25519 private key (signatures)

### Public Key  
Public key in asymmetric cryptography. Ya OK identity includes:
- X25519 public key (shared with contacts)
- Ed25519 public key (shared for signature verification)

### Public Key Cryptography  
Cryptography using key pairs. Ya OK uses X25519 and Ed25519.

### Quantum Resistance  
Resistance to attacks using quantum computers. Current Ya OK algorithms not quantum-resistant; planned upgrade to CRYSTALS-Kyber.

### Rainbow Table  
*Not applicable to Ya OK.* Precomputed hash table. Ya OK doesn't use passwords.

### Ring (Rust Crypto Library)  
Cryptography library used by Ya OK Rust core.

### RSA *(Rivest-Shamir-Adleman)*  
*Not used in Ya OK.* Public key algorithm. Ya OK uses Curve25519 instead (faster, smaller keys).

### RustCrypto  
Rust cryptography libraries. Ya OK uses RustCrypto for some algorithms.

### Safety Number  
SHA-256 fingerprint of public keys. Users verify safety numbers to detect MITM.

### Salt  
See **Salt** in General Terms.

### Scrypt  
*Not used in Ya OK.* Password hashing. Ya OK doesn't use passwords.

### Secure Element  
Hardware for secure key storage. Ya OK uses:
- Android: Hardware-backed Keystore
- iOS: Secure Enclave

### Session Key  
Temporary key for session. Planned for Ya OK perfect forward secrecy.

### SHA-256 *(Secure Hash Algorithm 256-bit)*  
Cryptographic hash function. Ya OK uses for safety number fingerprints.

### SHA-3  
*Not used in Ya OK.* Hash function. Ya OK uses SHA-256 and Blake2b.

### Side-Channel Attack  
Attack exploiting implementation details (timing, power). Ya OK mitigates via constant-time crypto.

### Signal Protocol  
E2EE protocol with perfect forward secrecy. Planned for future Ya OK version.

### Signature  
See **Digital Signature**.

### SQLCipher  
Encrypted SQLite database. Ya OK uses SQLCipher for database encryption at rest.

### Stream Cipher  
Cipher encrypting continuous stream. XChaCha20 is stream cipher.

### Symmetric Encryption  
Encryption using same key for encrypt/decrypt. Ya OK uses XChaCha20-Poly1305.

### Threat Model  
Analysis of potential threats. Ya OK uses STRIDE threat model.

### TLS *(Transport Layer Security)*  
See **TLS** in General Terms.

### Timing Attack  
Attack using execution time. Ya OK uses constant-time crypto to prevent.

### Trust On First Use** *(TOFU)*  
See **TOFU** in General Terms.

### X25519  
ECDH key exchange using Curve25519. Ya OK uses for establishing shared encryption keys.

### XChaCha20-Poly1305  
AEAD cipher. Ya OK's primary encryption:
- XChaCha20: Stream cipher (256-bit key, 192-bit nonce)
- Poly1305: MAC (128-bit authentication tag)

### Zero-Knowledge Proof  
*Not used in Ya OK.* Cryptographic proof revealing no information except validity. Ya OK is zero-knowledge server (but doesn't use ZK proofs).

### Zeroize  
Overwriting memory with zeros. Ya OK uses `zeroize` crate to clear sensitive data.

---

## 4. Networking & Communication

### 802.11  
WiFi standards family:
- 802.11n (WiFi 4)
- 802.11ac (WiFi 5)
- 802.11ax (WiFi 6)

Ya OK WiFi Direct works with all.

### Anycast  
Routing to nearest server. Fly.io uses anycast for Ya OK relay.

### API Gateway  
*Not used in Ya OK.* Entry point for APIs. Ya OK relay is simple UDP server.

### Bandwidth  
Data transfer rate. Ya OK optimizes for low bandwidth (< 10 KB/message overhead).

### BLE *(Bluetooth Low Energy)*  
Low-power Bluetooth for short-range communication. Ya OK uses BLE for:
- Device discovery
- Local messaging (<30m range)
- Offline communication

### Bluetooth  
Short-range wireless. Ya OK uses Bluetooth LE (BLE) variant.

### Broadcast  
Sending to all devices. Ya OK uses BLE advertising for device discovery.

### CDN *(Content Delivery Network)*  
*Not used in Ya OK.* Network of servers for content delivery. Ya OK relay is lightweight (no CDN needed).

### Circuit Switching  
*Not used in Ya OK.* Dedicated communication path. Ya OK uses packet switching.

### Client  
Device initiating connection. Ya OK mobile apps are clients.

### Connection Pooling  
Reusing connections. Ya OK relay maintains connection pools.

### DHCP *(Dynamic Host Configuration Protocol)*  
Automatic IP address assignment. Ya OK works over DHCP-configured networks.

### DNS *(Domain Name System)*  
Resolves domain names to IP addresses. Ya OK relay domains:
- relay.yaok.app
- relay-ams.yaok.app
- relay-iad.yaok.app
- relay-sin.yaok.app

### DNS-SD *(DNS Service Discovery)*  
Protocol for discovering services. Ya OK uses DNS-SD for WiFi Direct peer discovery.

### DTN *(Delay-Tolerant Networking)*  
See **DTN** in General Terms.

### Epidemic Routing  
DTN routing flooding messages. Ya OK uses controlled epidemic routing.

### Firewall  
See **Firewall** in General Terms.

### GATT *(Generic Attribute Profile)*  
See **GATT** in General Terms.

### Handshake  
See **Handshake** in General Terms.

### Header  
Metadata preceding data. Ya OK relay packet header:
- Version (1 byte)
- Type (1 byte)
- Reserved (2 bytes)
- Length (4 bytes)

### HTTP *(Hypertext Transfer Protocol)*  
Web protocol. Ya OK relay HTTP endpoints:
- `/health` (health check)
- `/metrics` (Prometheus metrics)

### HTTPS *(HTTP Secure)*  
See **HTTPS** in General Terms.

### ICMP *(Internet Control Message Protocol)*  
Network diagnostic protocol (ping). Ya OK relay responds to ICMP for monitoring.

### IP Address *(Internet Protocol Address)*  
Network device identifier. Ya OK relay has IPv4 and IPv6 addresses.

### IPv4  
32-bit IP addresses. Ya OK relay supports IPv4.

### IPv6  
128-bit IP addresses. Ya OK relay supports IPv6 (dual-stack).

### Latency  
See **Latency** in General Terms.

### Load Balancer  
See **Load Balancer** in General Terms.

### mDNS *(Multicast DNS)*  
Local network service discovery. Ya OK uses for WiFi Direct peer discovery.

### MTU *(Maximum Transmission Unit)*  
Maximum packet size. Ya OK relay packets sized for 1500-byte Ethernet MTU.

### Multicast  
Sending to group. Ya OK uses for local device discovery.

### NAT *(Network Address Translation)*  
Mapping private IPs to public. Ya OK relay works behind NAT.

### NSD *(Network Service Discovery)*  
Android API for mDNS. Ya OK uses for WiFi Direct discovery.

### Packet  
See **Packet** in General Terms.

### Packet Loss  
Packets not reaching destination. Ya OK handles via retries.

### Payload  
Actual data in packet (excluding header). Ya OK message payload is encrypted.

### Peer  
Device in P2P network. Ya OK peers communicate directly via BLE/WiFi.

### Ping  
Network diagnostic (ICMP Echo). Ya OK relay responds to pings for health checks.

### Port  
Endpoint identifier in transport protocol. Ya OK relay ports:
- 41641 (UDP)
- 8080 (HTTP)
- 9090 (metrics, internal)

### Protocol  
See **Protocol** in General Terms.

### Proxy  
Intermediary for requests. Ya OK relay is not a proxy (stores messages).

### QoS *(Quality of Service)*  
Network performance guarantees. Ya OK prioritizes message delivery over other traffic.

### Relay  
Server forwarding messages. Ya OK relay server forwards messages between remote users.

### Round-Trip Time** *(RTT)*  
Time for packet to reach destination and return. Ya OK measures RTT for latency monitoring.

### Router  
Device forwarding packets. Ya OK includes message router component.

### Server  
Device providing service. Ya OK relay server serves mobile clients.

### Socket  
See **Network Socket** in General Terms.

### Store-and-Forward  
See **Store-and-Forward** in General Terms.

### TCP *(Transmission Control Protocol)*  
*Not used for Ya OK relay.* Reliable transport protocol. Ya OK uses UDP for lower latency.

### Throughput  
Amount of data transferred. Ya OK targets:
- BLE: 1+ MB/s
- WiFi Direct: 10+ MB/s
- Relay: depends on internet speed

### TLS *(Transport Layer Security)*  
See **TLS** in General Terms.

### TTL *(Time To Live)*  
See **TTL** in General Terms.

### UDP *(User Datagram Protocol)*  
See **UDP** in General Terms.

### Unicast  
Sending to single recipient. Ya OK messages are unicast.

### Uptime  
Percentage of time service is available. Ya OK relay target: 99.9%.

### VPN *(Virtual Private Network)*  
See **VPN** in General Terms.

### WebRTC *(Web Real-Time Communication)*  
*Planned for future Ya OK.* P2P audio/video. Planned for voice/video calls.

### WebSocket  
See **WebSocket** in General Terms.

### WiFi Direct  
See **WiFi Direct** in General Terms.

---

## 5. Software Architecture

### API *(Application Programming Interface)*  
See **API** in General Terms.

### Architecture  
High-level design of system. Ya OK uses:
- C4 model for documentation
- Layered architecture (UI, business logic, data)
- Component-based design

### C4 Model  
Architecture visualization method:
- Context (system boundaries)
- Container (deployable units)
- Component (internal structure)
- Code (classes, functions)

### Clean Architecture  
Architecture separating concerns. Ya OK follows clean architecture principles.

### Component  
Self-contained module. Ya OK components:
- Identity Manager
- Message Manager
- Crypto Engine
- Transport Router
- etc.

### Coupling  
Degree of interdependence. Ya OK minimizes coupling via interfaces.

### Dependency Injection  
See **Dependency Injection** in General Terms.

### Design Pattern  
Reusable solution to common problem. Ya OK uses patterns:
- Repository (data access)
- Factory (object creation)
- Observer (event handling)
- Strategy (transport selection)

### Domain-Driven Design** *(DDD)*  
Design focused on domain model. Ya OK domains:
- Identity
- Messaging
- Transport
- Cryptography

### Event-Driven Architecture  
Architecture based on events. Ya OK uses events for:
- Message received
- Transport connected
- Contact added

### Facade  
Simplified interface to complex subsystem. Ya OK FFI is facade for Rust core.

### Hexagonal Architecture  
Architecture with ports and adapters. Ya OK architecture is hexagonal-like (Rust core with multiple adapters: Android, iOS, relay).

### Layered Architecture  
Architecture with distinct layers:
1. Presentation (UI)
2. Business Logic (Rust core)
3. Data Access (storage, network)

### Microservices  
*Not used in Ya OK.* Architecture with many small services. Ya OK has monolithic mobile apps + single relay server.

### Module  
See **Module** in general context.

### Monolith  
Single deployable unit. Ya OK mobile apps are monolithic.

### MVC *(Model-View-Controller)*  
UI architecture pattern. Ya OK Android uses MVVM variant.

### MVVM *(Model-View-ViewModel)*  
UI architecture pattern. Ya OK Android uses MVVM:
- Model: Data classes
- View: Fragments/Activities
- ViewModel: LiveData/StateFlow

### Observer Pattern  
Pattern for subscribing to events. Ya OK uses for:
- Message updates (LiveData)
- Transport status (StateFlow)

### Port and Adapter  
See **Hexagonal Architecture**.

### Repository Pattern  
Pattern for data access abstraction. Ya OK repositories:
- MessageRepository
- ContactRepository
- IdentityRepository

### REST *(Representational State Transfer)*  
See **REST** in General Terms.

### Separation of Concerns  
Design principle dividing functionality. Ya OK separates:
- UI (Android/iOS)
- Business logic (Rust core)
- Storage (SQLite)
- Network (transports)

### Service-Oriented Architecture** *(SOA)*  
*Not used in Ya OK.* Architecture with service composition. Ya OK is simpler.

### SOLID Principles  
See **SOLID Principles** in General Terms.

### State Machine  
Model of states and transitions. Ya OK uses for:
- Message delivery states (sending → sent → delivered → read)
- Transport states (disconnected → connecting → connected)

### Strategy Pattern  
Pattern for interchangeable algorithms. Ya OK uses for transport selection.

---

## 6. Mobile Development

### Activity *(Android)*  
Screen in Android app. Ya OK activities:
- OnboardingActivity
- MainActivity
- etc.

### Android SDK  
Tools for Android development. Ya OK uses Android SDK 24+.

### ANR *(Application Not Responding)*  
Android error when UI thread blocked. Ya OK avoids ANRs via background threads.

### APK *(Android Package Kit)*  
Android app package format. Ya OK builds APK for distribution.

### App Store *(iOS)*  
Apple's app distribution platform. Ya OK distributed via App Store.

### Background Mode  
Running when app not visible. Ya OK uses for:
- Message delivery
- BLE scanning

### BiometricPrompt *(Android)*  
API for biometric authentication. Ya OK uses for app lock.

### CocoaPods  
iOS dependency manager. Ya OK uses CocoaPods for iOS dependencies.

### Core Data *(iOS)*  
*Not used in Ya OK.* iOS persistence framework. Ya OK uses SQLite directly.

### Deep Link  
URL opening specific app screen. Ya OK uses for contact QR codes: `yaok://contact?...`

### Doze Mode *(Android)*  
Power-saving mode. Ya OK optimized for Doze (uses WorkManager).

### Espresso *(Android)*  
UI testing framework. Ya OK uses Espresso for Android UI tests.

### FCM *(Firebase Cloud Messaging)*  
Push notification service. Ya OK uses FCM for notifications.

### Fragment *(Android)*  
Reusable UI component. Ya OK fragments:
- ConversationListFragment
- ChatFragment
- ContactListFragment

### Gradle  
Build system for Android. Ya OK uses Gradle 8.x.

### Hilt *(Android)*  
Dependency injection framework. Ya OK uses Hilt.

### iOS SDK  
Tools for iOS development. Ya OK uses iOS SDK 14+.

### JNI *(Java Native Interface)*  
See **JNI** in General Terms.

### JUnit  
Testing framework for Java. Ya OK uses JUnit for Android tests.

### Keychain *(iOS)*  
See **Keychain** in General Terms.

### Keystore *(Android)*  
See **Keystore** in General Terms.

### Kotlin  
Programming language for Android. Ya OK Android app written in Kotlin.

### Launch Screen *(iOS)*  
Screen shown while app loads. Ya OK has branded launch screen.

### LiveData *(Android)*  
Observable data holder. Ya OK uses LiveData for UI updates.

### LocalAuthentication *(iOS)*  
Framework for biometric auth. Ya OK uses for Face ID/Touch ID.

### NDK *(Native Development Kit)*  
Tools for native code on Android. Ya OK uses NDK for JNI.

### Notification Channel *(Android)*  
Category for notifications. Ya OK channels:
- Messages (high priority)
- System (default priority)

### ProGuard  
Code obfuscation tool for Android. Ya OK uses ProGuard for release builds.

### Room *(Android)*  
*Not used in Ya OK.* Android database library. Ya OK uses SQLite directly via Rust core.

### Splash Screen  
Initial screen while loading. Ya OK shows logo during startup.

### StateFlow *(Kotlin)*  
State holder flow. Ya OK uses StateFlow for state management.

### StoryBoard *(iOS)*  
*Minimal use in Ya OK.* UI layout tool. Ya OK mostly uses programmatic UI.

### Swift  
Programming language for iOS. Ya OK iOS app written in Swift.

### SwiftUI  
*Not used in Ya OK.* Declarative iOS UI framework. Ya OK uses UIKit.

### UIKit *(iOS)*  
iOS UI framework. Ya OK uses UIKit.

### ViewController *(iOS)*  
Screen controller in iOS. Ya OK view controllers:
- OnboardingViewController
- MainTabBarController
- ChatViewController

### WorkManager *(Android)*  
Background task scheduler. Ya OK uses for message checking.

### Xcode  
iOS development IDE. Ya OK built with Xcode 14+.

### XCTest *(iOS)*  
Testing framework for iOS. Ya OK uses XCTest.

### XCUITest *(iOS)*  
UI testing framework for iOS. Ya OK uses for iOS UI tests.

---

## 7. Business & Metrics

### A/B Testing  
Comparing two variants. Ya OK plans A/B testing for UI changes.

### Adoption Rate  
Percentage of target users using app. Ya OK tracks adoption.

### Analytics  
Data about app usage. Ya OK uses local analytics (privacy-preserving).

### Burn Rate  
Rate of spending money. Ya OK tracks operational costs.

### CAC *(Customer Acquisition Cost)*  
Cost to acquire user. Ya OK tracks CAC for marketing efficiency.

### Churn Rate  
Percentage of users leaving. Ya OK monitors churn.

### Conversion Rate  
Percentage completing desired action (e.g., signup). Ya OK tracks conversions.

### Crash-Free Rate  
Percentage of sessions without crashes. Ya OK target: > 99.5%.

### DAU *(Daily Active Users)*  
Users active in last 24 hours. Key Ya OK metric.

### Engagement  
User interaction level. Ya OK tracks message frequency.

### Funnel  
User journey steps. Ya OK onboarding funnel:
1. Install
2. Create identity
3. Add contact
4. Send message

### Growth Rate  
Rate of user increase. Ya OK tracks monthly growth.

### KPI *(Key Performance Indicator)*  
See **KPI** in General Terms.

### Lifetime Value** *(LTV)*  
*Not applicable to Ya OK.* Total revenue from user. Ya OK is free (no revenue per user).

### MAU *(Monthly Active Users)*  
Users active in last 30 days. Key Ya OK metric.

### NPS *(Net Promoter Score)*  
User recommendation likelihood. Ya OK conducts NPS surveys.

### Retention Rate  
Percentage of users returning. Ya OK tracks:
- Day 1 retention
- Day 7 retention
- Day 30 retention

### Session Duration  
Time spent in app. Ya OK tracks average session duration.

### Telemetry  
Automated data collection. Ya OK uses privacy-preserving telemetry.

### WAU *(Weekly Active Users)*  
Users active in last 7 days. Ya OK tracks WAU.

---

## 8. Standards & Compliance

### CCPA *(California Consumer Privacy Act)*  
California privacy law. Ya OK complies with CCPA:
- Right to know data collected (none)
- Right to delete (local deletion)
- Right to opt-out (no tracking)

### COPPA *(Children's Online Privacy Protection Act)*  
US law protecting children's privacy. Ya OK not targeted at children (13+ age requirement).

### GDPR *(General Data Protection Regulation)*  
EU privacy law. Ya OK complies with GDPR:
- Article 15: Right to access (data export)
- Article 17: Right to erasure (data deletion)
- Article 33: Breach notification (incident response plan)

### HIPAA *(Health Insurance Portability and Accountability Act)*  
*Not applicable to Ya OK.* US healthcare privacy law. Ya OK not HIPAA-compliant (not designed for healthcare).

### IEC *(International Electrotechnical Commission)*  
Standards organization. Ya OK follows ISO/IEC standards.

### IEEE *(Institute of Electrical and Electronics Engineers)*  
Standards organization. Ya OK follows IEEE standards:
- IEEE 802.11 (WiFi)
- IEEE 802.15 (Bluetooth)

### ISO *(International Organization for Standardization)*  
Standards organization. Ya OK follows ISO standards:
- ISO/IEC 12207 (software lifecycle)
- ISO/IEC 25010 (quality model)
- ISO 27001 (information security)

### ISO/IEC 12207  
Software lifecycle standard. Ya OK documentation structured per 12207.

### ISO/IEC 25010  
Software quality model. Ya OK defines NFRs per 25010:
- Performance efficiency
- Reliability
- Security
- Usability
- Compatibility
- Maintainability
- Portability

### ISO/IEC 27001  
Information security standard. Ya OK security requirements mapped to 27001.

### ISO/IEC 27035  
Security incident management. Ya OK incident response plan follows 27035.

### ISO/IEC 29119  
Software testing standard. Ya OK test cases structured per 29119.

### ISO/IEC 29148  
Requirements engineering standard. Ya OK SRS follows 29148.

### ITIL *(Information Technology Infrastructure Library)*  
IT service management framework. Ya OK operations follow ITIL 4:
- Service Value System
- Service Value Chain
- Service Management Practices

### NIST *(National Institute of Standards and Technology)*  
US standards body. Ya OK follows NIST guidelines:
- NIST SP 800-61 (incident response)
- NIST Cybersecurity Framework

### OWASP *(Open Web Application Security Project)*  
Security organization. Ya OK follows OWASP Mobile Security:
- MASVS (Mobile Application Security Verification Standard) L2
- MSTG (Mobile Security Testing Guide)

### PCI DSS *(Payment Card Industry Data Security Standard)*  
*Not applicable to Ya OK.* Payment security standard. Ya OK doesn't handle payments.

### SOC 2 *(Service Organization Control 2)*  
*Not pursued by Ya OK.* Audit for service providers. Ya OK too small for SOC 2.

### WCAG *(Web Content Accessibility Guidelines)*  
Accessibility standard. Ya OK follows WCAG 2.1 AA for accessibility.

---

## 9. Acronyms & Abbreviations

### Technical Acronyms

| Acronym | Full Form | Category |
|---------|-----------|----------|
| AEAD | Authenticated Encryption with Associated Data | Cryptography |
| AES | Advanced Encryption Standard | Cryptography |
| ANR | Application Not Responding | Mobile Dev |
| API | Application Programming Interface | Software |
| APK | Android Package Kit | Mobile Dev |
| BLE | Bluetooth Low Energy | Networking |
| CAC | Customer Acquisition Cost | Business |
| CCPA | California Consumer Privacy Act | Compliance |
| CDN | Content Delivery Network | Networking |
| CI/CD | Continuous Integration/Continuous Deployment | Software |
| COPPA | Children's Online Privacy Protection Act | Compliance |
| CPU | Central Processing Unit | Hardware |
| CRUD | Create, Read, Update, Delete | Software |
| CSPRNG | Cryptographically Secure PRNG | Cryptography |
| DAU | Daily Active Users | Business |
| DDoS | Distributed Denial of Service | Security |
| DHCP | Dynamic Host Configuration Protocol | Networking |
| DNS | Domain Name System | Networking |
| DNS-SD | DNS Service Discovery | Networking |
| DTN | Delay-Tolerant Networking | Networking |
| E2EE | End-to-End Encryption | Cryptography |
| ECDH | Elliptic Curve Diffie-Hellman | Cryptography |
| ECDSA | Elliptic Curve Digital Signature Algorithm | Cryptography |
| EdDSA | Edwards-curve Digital Signature Algorithm | Cryptography |
| FCM | Firebase Cloud Messaging | Mobile Dev |
| FFI | Foreign Function Interface | Software |
| FIFO | First In First Out | Software |
| FTS | Full-Text Search | Database |
| GATT | Generic Attribute Profile | Networking |
| GDPR | General Data Protection Regulation | Compliance |
| HA | High Availability | Software |
| HKDF | HMAC-based Key Derivation Function | Cryptography |
| HMAC | Hash-based Message Authentication Code | Cryptography |
| HSM | Hardware Security Module | Security |
| HTTP | Hypertext Transfer Protocol | Networking |
| HTTPS | HTTP Secure | Networking |
| IaC | Infrastructure as Code | Operations |
| ICMP | Internet Control Message Protocol | Networking |
| IDE | Integrated Development Environment | Software |
| IEC | International Electrotechnical Commission | Standards |
| IEEE | Institute of Electrical and Electronics Engineers | Standards |
| IME | Input Method Editor | Mobile Dev |
| IoC | Inversion of Control | Software |
| IP | Internet Protocol | Networking |
| IPC | Inter-Process Communication | Software |
| IRP | Incident Response Plan | Security |
| ISO | International Organization for Standardization | Standards |
| ITIL | Information Technology Infrastructure Library | Operations |
| IV | Initialization Vector | Cryptography |
| JNI | Java Native Interface | Mobile Dev |
| JSON | JavaScript Object Notation | Software |
| JWT | JSON Web Token | Security |
| KPI | Key Performance Indicator | Business |
| LRU | Least Recently Used | Software |
| LTV | Lifetime Value | Business |
| MAC | Message Authentication Code | Cryptography |
| MAU | Monthly Active Users | Business |
| mDNS | Multicast DNS | Networking |
| MITM | Man-in-the-Middle | Security |
| MTBF | Mean Time Between Failures | Reliability |
| MTTR | Mean Time To Recovery | Reliability |
| MTU | Maximum Transmission Unit | Networking |
| MVC | Model-View-Controller | Software |
| MVVM | Model-View-ViewModel | Software |
| NAT | Network Address Translation | Networking |
| NDK | Native Development Kit | Mobile Dev |
| NFR | Non-Functional Requirement | Software |
| NIST | National Institute of Standards and Technology | Standards |
| NPS | Net Promoter Score | Business |
| NSD | Network Service Discovery | Networking |
| OS | Operating System | Software |
| OWASP | Open Web Application Security Project | Security |
| P2P | Peer-to-Peer | Networking |
| PBKDF2 | Password-Based Key Derivation Function 2 | Cryptography |
| PCI DSS | Payment Card Industry Data Security Standard | Compliance |
| PFS | Perfect Forward Secrecy | Cryptography |
| PGP | Pretty Good Privacy | Cryptography |
| PKI | Public Key Infrastructure | Cryptography |
| PR | Pull Request | Software |
| PRNG | Pseudo-Random Number Generator | Cryptography |
| QoS | Quality of Service | Networking |
| QR | Quick Response | Technology |
| RAM | Random Access Memory | Hardware |
| REST | Representational State Transfer | Software |
| RFC | Request for Comments | Standards |
| RNG | Random Number Generator | Cryptography |
| ROM | Read-Only Memory | Hardware |
| RPC | Remote Procedure Call | Software |
| RPO | Recovery Point Objective | Operations |
| RSA | Rivest-Shamir-Adleman | Cryptography |
| RTO | Recovery Time Objective | Operations |
| RTT | Round-Trip Time | Networking |
| RTM | Requirements Traceability Matrix | Software |
| SDK | Software Development Kit | Software |
| SHA | Secure Hash Algorithm | Cryptography |
| SLA | Service Level Agreement | Operations |
| SLI | Service Level Indicator | Operations |
| SLO | Service Level Objective | Operations |
| SMS | Short Message Service | Telecommunications |
| SOA | Service-Oriented Architecture | Software |
| SOC | Service Organization Control | Compliance |
| SOLID | Single/Open/Liskov/Interface/Dependency | Software |
| SOP | Standard Operating Procedure | Operations |
| SQL | Structured Query Language | Database |
| SRE | Site Reliability Engineering | Operations |
| SRS | Software Requirements Specification | Software |
| SSH | Secure Shell | Networking |
| SSL | Secure Sockets Layer | Networking |
| STRIDE | Spoofing/Tampering/Repudiation/Info/DoS/Elevation | Security |
| TCP | Transmission Control Protocol | Networking |
| TDD | Test-Driven Development | Software |
| TLS | Transport Layer Security | Networking |
| TOFU | Trust On First Use | Security |
| TTL | Time To Live | Networking |
| UAT | User Acceptance Testing | Software |
| UDP | User Datagram Protocol | Networking |
| UI | User Interface | Software |
| URI | Uniform Resource Identifier | Software |
| URL | Uniform Resource Locator | Software |
| UTF | Unicode Transformation Format | Software |
| UUID | Universally Unique Identifier | Software |
| UX | User Experience | Software |
| VM | Virtual Machine | Software |
| VPN | Virtual Private Network | Networking |
| WAL | Write-Ahead Logging | Database |
| WAU | Weekly Active Users | Business |
| WCAG | Web Content Accessibility Guidelines | Compliance |
| WiFi | Wireless Fidelity | Networking |
| XSS | Cross-Site Scripting | Security |
| YAML | YAML Ain't Markup Language | Software |

---

## 10. References

### Cryptography References

- **NaCl**: Networking and Cryptography library — https://nacl.cr.yp.to/
- **libsodium**: Portable NaCl fork — https://libsodium.org/
- **Ring**: Safe Rust crypto library — https://github.com/briansmith/ring
- **RustCrypto**: Rust cryptography libraries — https://github.com/RustCrypto
- **RFC 7748**: Elliptic Curves for Security (X25519) — https://tools.ietf.org/html/rfc7748
- **RFC 8032**: Edwards-Curve Digital Signatures (Ed25519) — https://tools.ietf.org/html/rfc8032
- **RFC 8439**: ChaCha20 and Poly1305 — https://tools.ietf.org/html/rfc8439

### Networking References

- **RFC 768**: UDP — https://tools.ietf.org/html/rfc768
- **RFC 793**: TCP — https://tools.ietf.org/html/rfc793
- **RFC 6762**: mDNS — https://tools.ietf.org/html/rfc6762
- **RFC 6763**: DNS-SD — https://tools.ietf.org/html/rfc6763
- **Bluetooth Core Specification v5.4** — https://www.bluetooth.com/specifications/
- **WiFi Direct Specification** — https://www.wi-fi.org/discover-wi-fi/wi-fi-direct

### Standards References

- **ISO/IEC 12207**: Systems and software engineering — https://www.iso.org/standard/63712.html
- **ISO/IEC 25010**: Software quality model — https://www.iso.org/standard/35733.html
- **ISO/IEC 27001**: Information security management — https://www.iso.org/standard/54534.html
- **ISO/IEC 27035**: Security incident management — https://www.iso.org/standard/60803.html
- **NIST SP 800-61**: Computer Security Incident Handling Guide — https://csrc.nist.gov/publications/
- **OWASP MASVS**: Mobile Application Security Verification Standard — https://github.com/OWASP/owasp-masvs
- **GDPR**: General Data Protection Regulation — https://gdpr.eu/
- **CCPA**: California Consumer Privacy Act — https://oag.ca.gov/privacy/ccpa

### Technology References

- **Android Developers**: https://developer.android.com/
- **iOS Developer**: https://developer.apple.com/
- **Rust Programming Language**: https://www.rust-lang.org/
- **Tokio (async runtime)**: https://tokio.rs/
- **SQLCipher**: https://www.zetetic.net/sqlcipher/
- **Fly.io**: https://fly.io/

### Ya OK Project References

- **Website**: https://yaok.app
- **GitHub**: https://github.com/yaok
- **Documentation**: https://docs.yaok.app
- **Security Policy**: https://yaok.app/security
- **Privacy Policy**: https://yaok.app/privacy

---

## Appendix: Quick Reference Tables

### Cryptographic Algorithms Used

| Purpose | Algorithm | Key Size | Notes |
|---------|-----------|----------|-------|
| Symmetric Encryption | XChaCha20 | 256-bit | Stream cipher |
| Message Authentication | Poly1305 | 128-bit tag | MAC |
| Key Exchange | X25519 (ECDH) | 256-bit | Curve25519 |
| Digital Signatures | Ed25519 | 256-bit | EdDSA on Curve25519 |
| Hashing (fingerprints) | SHA-256 | 256-bit output | For safety numbers |
| Hashing (message IDs) | Blake2b | 256-bit output | Faster than SHA-256 |
| Random Number Gen | ring::rand | CSPRNG | OS entropy source |

### Network Protocols Used

| Protocol | Layer | Port | Purpose |
|----------|-------|------|---------|
| UDP | Transport | 41641 | Relay protocol |
| HTTP | Application | 8080 | Health/metrics |
| HTTPS (TLS 1.3) | Application | 443 | Secure HTTP |
| BLE GATT | Application | - | Local messaging |
| WiFi Direct (NSD) | Application | - | Local messaging |
| mDNS | Application | 5353 | Service discovery |

### Mobile Platform Versions

| Platform | Minimum | Target | Latest Tested |
|----------|---------|--------|---------------|
| Android | 7.0 (API 24) | 14.0 (API 34) | 15.0 (API 35) |
| iOS | 14.0 | 17.0 | 18.0 |
| Rust | 1.70 | 1.76 | 1.76 |

### Database Schema Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| users | User identity | user_id, display_name, public_key_x25519, public_key_ed25519 |
| contacts | Contact list | contact_id, user_id, verified, last_seen |
| messages | Message history | message_id, sender_id, recipient_id, content, timestamp, status |
| routing_table | Message routing | destination_id, next_hop_id, last_seen |

---

**Document Classification:** PUBLIC  
**Distribution:** All team members, partners, open source community  
**Review Cycle:** Quarterly or when new terms introduced

**End of Glossary**
