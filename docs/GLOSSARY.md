# Ya OK Glossary & Terminology
## Comprehensive Technical Reference

**Document ID:** YA-OK-GLOSS-001  
**Version:** 1.0  
**Date:** 2026-02-06  
**Classification:** PUBLIC

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-06 | Documentation Team | Initial glossary |

---

## Table of Contents

1. [Cryptography Terms](#1-cryptography-terms)
2. [Networking & Transport](#2-networking--transport)
3. [Protocols & Standards](#3-protocols--standards)
4. [Architecture & Design](#4-architecture--design)
5. [Platform & Technology](#5-platform--technology)
6. [Security & Privacy](#6-security--privacy)
7. [Quality Attributes](#7-quality-attributes)
8. [Business & Metrics](#8-business--metrics)
9. [Development & Testing](#9-development--testing)
10. [Acronyms & Abbreviations](#10-acronyms--abbreviations)

---

## 1. Cryptography Terms

### AEAD (Authenticated Encryption with Associated Data)
**Definition:** A cryptographic scheme that provides both confidentiality (encryption) and authenticity (authentication) in a single operation. AEAD ciphers protect both the plaintext and additional associated data (AAD) that remains unencrypted.

**Ya OK Usage:** XChaCha20-Poly1305 AEAD cipher encrypts message content and authenticates message metadata (sender ID, timestamp, message ID).

**Example:** When sending a message, AEAD ensures the content is encrypted and the sender/timestamp cannot be tampered with.

**Standards:** RFC 5116, NIST SP 800-38D

**Related Terms:** XChaCha20-Poly1305, Authenticated Encryption, MAC

---

### ChaCha20
**Definition:** A stream cipher designed by Daniel J. Bernstein as a variant of Salsa20. ChaCha20 is faster than AES on platforms without hardware acceleration and resistant to timing attacks.

**Ya OK Usage:** XChaCha20 (extended-nonce variant) is used for message encryption, providing 256-bit security.

**Key Size:** 256 bits  
**Nonce Size:** 192 bits (XChaCha20) vs 96 bits (ChaCha20)  
**Performance:** ~3-4 cycles/byte on modern CPUs

**Standards:** RFC 8439

**Related Terms:** XChaCha20, Poly1305, Stream Cipher

---

### CSPRNG (Cryptographically Secure Pseudorandom Number Generator)
**Definition:** A pseudorandom number generator (PRNG) with properties that make it suitable for cryptographic applications, such as unpredictability and resistance to analysis.

**Ya OK Usage:** Used for generating encryption keys, nonces, session tokens, and message IDs via `ring::rand::SystemRandom`.

**Requirements:**
- Unpredictable output
- Uniform distribution
- Sufficient entropy

**Implementation:** `/dev/urandom` (Linux), `BCryptGenRandom` (Windows), `SecRandomCopyBytes` (iOS)

**Related Terms:** Entropy, Nonce, RNG

---

### ECDH (Elliptic Curve Diffie-Hellman)
**Definition:** A key agreement protocol that allows two parties to establish a shared secret over an insecure channel using elliptic curve cryptography.

**Ya OK Usage:** X25519 ECDH is used to derive shared secrets between contacts for encryption keys.

**Algorithm:** X25519 (Curve25519 for ECDH)  
**Key Size:** 256 bits  
**Security:** ~128-bit security level

**Process:**
1. Alice generates key pair (private_a, public_a)
2. Bob generates key pair (private_b, public_b)
3. Alice computes shared_secret = ECDH(private_a, public_b)
4. Bob computes shared_secret = ECDH(private_b, public_a)
5. shared_secret is identical for both

**Standards:** RFC 7748

**Related Terms:** X25519, Key Exchange, Diffie-Hellman

---

### Ed25519
**Definition:** An elliptic curve digital signature algorithm using the Edwards curve Curve25519. Provides fast signature generation and verification with high security.

**Ya OK Usage:** Used for identity keys, message signing, and authentication.

**Key Size:** 256 bits (32 bytes)  
**Signature Size:** 512 bits (64 bytes)  
**Performance:** ~60,000 signatures/sec, ~16,000 verifications/sec

**Properties:**
- Deterministic (same message + key = same signature)
- Collision-resistant
- Non-malleable

**Standards:** RFC 8032

**Related Terms:** Curve25519, Digital Signature, Public Key Cryptography

---

### HKDF (HMAC-based Key Derivation Function)
**Definition:** A key derivation function that extracts pseudorandom key material from input keying material using HMAC.

**Ya OK Usage:** (Planned for v1.5) Derive encryption keys from ECDH shared secrets.

**Steps:**
1. **Extract:** HKDF-Extract(salt, IKM) → PRK
2. **Expand:** HKDF-Expand(PRK, info, L) → OKM

**Example:**
```
shared_secret = ECDH(my_private, their_public)
encryption_key = HKDF(shared_secret, salt="yaok-encryption", info="v1", length=32)
```

**Standards:** RFC 5869

**Related Terms:** KDF, HMAC, Key Derivation

---

### HMAC (Hash-based Message Authentication Code)
**Definition:** A message authentication code (MAC) calculated using a cryptographic hash function (e.g., SHA-256) combined with a secret key.

**Ya OK Usage:** (Currently using Poly1305 MAC; HMAC planned for future key derivation)

**Security:** Depends on underlying hash function (SHA-256 → 128-bit security)

**Standards:** RFC 2104, FIPS 198-1

**Related Terms:** MAC, Authentication, Hash Function

---

### KDF (Key Derivation Function)
**Definition:** A cryptographic algorithm that derives one or more secret keys from a secret value (e.g., password, shared secret).

**Purpose:**
- Strengthen weak keys
- Derive multiple keys from single secret
- Add salt to prevent rainbow table attacks

**Examples:** PBKDF2, HKDF, Argon2, scrypt

**Ya OK Usage:** HKDF (planned) for deriving encryption keys from ECDH shared secrets.

**Related Terms:** HKDF, PBKDF2, Key Stretching

---

### MAC (Message Authentication Code)
**Definition:** A short piece of information used to verify the authenticity and integrity of a message. Generated using a secret key and the message.

**Types:**
- **HMAC:** Hash-based MAC (SHA-256, SHA-3)
- **CMAC:** Cipher-based MAC (AES)
- **Poly1305:** One-time MAC (used with ChaCha20)

**Ya OK Usage:** Poly1305 MAC in XChaCha20-Poly1305 AEAD provides message authentication.

**Security:** Prevents tampering, forgery, and replay attacks.

**Related Terms:** HMAC, Poly1305, Authentication

---

### Nonce (Number Used Once)
**Definition:** An arbitrary number used only once in cryptographic communication. Prevents replay attacks and ensures each encryption is unique.

**Ya OK Usage:** 192-bit nonces in XChaCha20-Poly1305. Generated using CSPRNG for each message.

**Requirements:**
- Unique per message
- Unpredictable
- Never reused with same key

**Nonce Reuse Attack:** Reusing a nonce with the same key can reveal plaintext or allow forgery.

**Related Terms:** IV, Salt, Randomness

---

### PBKDF2 (Password-Based Key Derivation Function 2)
**Definition:** A key derivation function that applies a pseudorandom function (e.g., HMAC-SHA-256) to the input password along with a salt, repeating the process many times to increase computation time.

**Ya OK Usage:** (Planned for future password-protected backups)

**Parameters:**
- **Password:** User input
- **Salt:** Random value (≥128 bits)
- **Iterations:** 100,000+ (NIST recommendation as of 2023)
- **Key Length:** Desired output length (e.g., 256 bits)

**Standards:** RFC 8018, NIST SP 800-132

**Related Terms:** KDF, Password Hashing, Key Stretching

---

### Perfect Forward Secrecy (PFS)
**Definition:** A property of cryptographic protocols where compromise of long-term keys does not compromise past session keys.

**Ya OK Status:** Planned for v1.5 (Signal Protocol integration)

**Mechanism:** Generate ephemeral key pairs for each session. Even if long-term identity keys are compromised, past messages remain secure.

**Implementation:** Ratcheting keys (e.g., Double Ratchet algorithm in Signal Protocol)

**Related Terms:** Signal Protocol, Ratcheting, Ephemeral Keys

---

### Poly1305
**Definition:** A one-time authentication code (MAC) designed by Daniel J. Bernstein. Used with ChaCha20 in the ChaCha20-Poly1305 AEAD construction.

**Ya OK Usage:** Authenticates messages in XChaCha20-Poly1305 AEAD.

**Properties:**
- Fast (constant-time)
- 128-bit security
- Requires unique key per message (derived from ChaCha20 keystream)

**Output Size:** 128 bits (16 bytes)

**Standards:** RFC 8439

**Related Terms:** MAC, ChaCha20, Authentication

---

### Public Key Cryptography (Asymmetric Cryptography)
**Definition:** Cryptographic system using pairs of keys: public keys (shared openly) and private keys (kept secret). Anyone can encrypt with public key, but only private key owner can decrypt.

**Ya OK Usage:**
- **X25519:** Key exchange (ECDH)
- **Ed25519:** Digital signatures

**Advantages:**
- No need to share secret keys
- Non-repudiation (digital signatures)
- Scalable (n users = n key pairs, not n² shared keys)

**Disadvantages:**
- Slower than symmetric crypto
- Larger key sizes

**Related Terms:** X25519, Ed25519, ECDH, Digital Signature

---

### SHA-256 (Secure Hash Algorithm 256-bit)
**Definition:** A cryptographic hash function that produces a 256-bit (32-byte) hash value. Part of SHA-2 family designed by NSA.

**Ya OK Usage:** Safety number generation (identity fingerprint), integrity checks, hash chains.

**Properties:**
- Deterministic (same input → same output)
- One-way (cannot reverse)
- Collision-resistant
- Avalanche effect (small input change → completely different output)

**Output:** 64 hexadecimal characters (e.g., `a3f2...`)

**Standards:** FIPS 180-4

**Related Terms:** Hash Function, Fingerprint, Checksum

---

### SQLCipher
**Definition:** An open-source extension to SQLite that provides transparent 256-bit AES encryption of database files.

**Ya OK Usage:** Encrypts local databases on Android and iOS, protecting messages, contacts, and keys at rest.

**Features:**
- Page-level encryption (each 4KB page encrypted separately)
- Key derivation (PBKDF2)
- HMAC for page integrity
- Transparent (same API as SQLite)

**Performance:** ~5-15% overhead vs unencrypted SQLite

**Configuration:**
```sql
PRAGMA key = 'your-encryption-key';
PRAGMA cipher_page_size = 4096;
PRAGMA kdf_iter = 256000;
```

**Related Terms:** SQLite, Database Encryption, AES

---

### Symmetric Encryption
**Definition:** Cryptographic system where the same key is used for both encryption and decryption.

**Ya OK Usage:** XChaCha20 symmetric cipher encrypts message content.

**Advantages:**
- Fast (1000× faster than public key crypto)
- Small keys (256 bits)
- Efficient for bulk data

**Disadvantages:**
- Key distribution problem (must securely share key)
- No non-repudiation

**Algorithms:** AES, ChaCha20, Salsa20, Serpent

**Related Terms:** ChaCha20, XChaCha20, AEAD

---

### X25519
**Definition:** An elliptic curve Diffie-Hellman (ECDH) key exchange protocol using Curve25519. Designed for high performance and security.

**Ya OK Usage:** Generates shared secrets between contacts for message encryption.

**Key Size:** 256 bits (32 bytes)  
**Security:** ~128-bit security level  
**Performance:** ~60,000 operations/sec

**Properties:**
- Constant-time (no timing attacks)
- Secure by default (no invalid inputs)
- Misuse-resistant

**Standards:** RFC 7748

**Related Terms:** ECDH, Curve25519, Key Exchange

---

### XChaCha20-Poly1305
**Definition:** An AEAD cipher combining XChaCha20 stream cipher with Poly1305 MAC. Extends ChaCha20's nonce from 96 to 192 bits.

**Ya OK Usage:** Primary encryption algorithm for all messages.

**Advantages:**
- Extended nonce (192 bits → negligible collision probability)
- Fast on all platforms (no hardware acceleration needed)
- Constant-time (resistant to timing attacks)
- Patent-free

**Performance:** 3-4 cycles/byte (vs 10+ for AES without AES-NI)

**Format:**
```
[192-bit nonce][ciphertext][128-bit MAC tag]
```

**Standards:** RFC 8439 (ChaCha20-Poly1305), draft-irtf-cfrg-xchacha

**Related Terms:** AEAD, ChaCha20, Poly1305

---

## 2. Networking & Transport

### BLE (Bluetooth Low Energy)
**Definition:** A wireless personal area network technology designed for low power consumption and short-range communication.

**Ya OK Usage:** Primary transport for nearby messaging (< 30 meters).

**Specifications:**
- **Standard:** Bluetooth 4.0+ (2010)
- **Frequency:** 2.4 GHz ISM band
- **Range:** ~10-30 meters (Class 2)
- **Data Rate:** 1 Mbps (BLE 4.2), 2 Mbps (BLE 5.0 with 2M PHY)
- **Power:** ~10-50 mW (vs ~100 mW for classic Bluetooth)

**Ya OK Configuration:**
- **Service UUID:** Custom GATT service
- **Characteristic:** Read/write for message exchange
- **Advertising:** Periodic advertising for peer discovery
- **Connection Interval:** 50-100 ms

**Advantages:**
- Ultra-low power (months on coin cell)
- Works offline
- No internet required

**Related Terms:** GATT, Advertising, Central, Peripheral

---

### GATT (Generic Attribute Profile)
**Definition:** A Bluetooth protocol that defines how BLE devices discover, read, and write attributes (data) over a BLE connection.

**Structure:**
- **Service:** Collection of related characteristics (e.g., "Ya OK Messaging Service")
- **Characteristic:** Individual data value (e.g., "Message" characteristic)
- **Descriptor:** Metadata about characteristic (e.g., "Client Characteristic Configuration")

**Ya OK GATT Service:**
```
Service: Ya OK Messaging (UUID: custom)
├── Characteristic: Message Out (write)
├── Characteristic: Message In (read, notify)
└── Characteristic: Identity (read)
```

**Operations:**
- **Read:** Get characteristic value
- **Write:** Set characteristic value
- **Notify:** Server pushes updates to client

**Related Terms:** BLE, Service, Characteristic, UUID

---

### mDNS (Multicast DNS)
**Definition:** A protocol that resolves hostnames to IP addresses on small networks without a DNS server. Uses multicast address 224.0.0.251 (IPv4) or ff02::fb (IPv6).

**Ya OK Usage:** WiFi Direct peer discovery via DNS-SD (DNS Service Discovery).

**Example:**
```
Query: _yaok._tcp.local
Response: alice-phone._yaok._tcp.local → 192.168.49.2:41641
```

**Advantages:**
- Zero configuration
- Works without internet
- Fast (local network only)

**Related Terms:** DNS-SD, Bonjour, Zeroconf

---

### DNS-SD (DNS Service Discovery)
**Definition:** A protocol for discovering services on a network using standard DNS queries. Often combined with mDNS for zero-configuration networking.

**Ya OK Usage:** Discover Ya OK peers on local WiFi networks.

**Service Format:**
```
<service>.<protocol>.<domain>
Example: _yaok._tcp.local
```

**TXT Record:** Contains service metadata (e.g., version, capabilities)

**Related Terms:** mDNS, Bonjour, Service Discovery

---

### NSD (Network Service Discovery)
**Definition:** Android API for discovering services on local networks using DNS-SD and mDNS.

**Ya OK Usage:** Android app uses NSD API to find Ya OK peers on WiFi Direct networks.

**Example Code:**
```kotlin
val serviceInfo = NsdServiceInfo().apply {
    serviceName = "Alice's Ya OK"
    serviceType = "_yaok._tcp"
    port = 41641
}
nsdManager.registerService(serviceInfo, NsdManager.PROTOCOL_DNS_SD, registrationListener)
```

**iOS Equivalent:** Bonjour (NSNetService)

**Related Terms:** DNS-SD, mDNS, Service Discovery

---

### P2P (Peer-to-Peer)
**Definition:** A decentralized network architecture where each node (peer) can act as both client and server, sharing resources directly without central coordination.

**Ya OK Usage:** Direct messaging between devices via BLE and WiFi Direct, without relay server.

**Advantages:**
- No central point of failure
- Privacy (no server sees messages)
- Works offline
- Scalable (no server load)

**Disadvantages:**
- Complex (NAT traversal, discovery, routing)
- Limited range (physical proximity)
- Intermittent connectivity

**Related Terms:** Decentralized, Mesh Network, DTN

---

### Relay Server
**Definition:** An intermediary server that forwards messages between clients when direct peer-to-peer communication is not possible.

**Ya OK Usage:** UDP-based relay server (Rust) forwards encrypted messages globally when BLE/WiFi Direct unavailable.

**Protocol:** Custom UDP protocol (port 41641)

**Operations:**
- **REGISTER:** Client announces presence
- **MESSAGE:** Client sends message to server for relay
- **POLL:** Client requests queued messages
- **ACK:** Server confirms receipt

**Privacy:** Server sees encrypted messages, sender/recipient IDs (UUIDs), timestamps, but cannot decrypt content.

**Related Terms:** UDP, Message Queue, Store-and-Forward

---

### UDP (User Datagram Protocol)
**Definition:** A connectionless transport layer protocol that sends datagrams without establishing a connection. No guaranteed delivery, ordering, or error checking.

**Ya OK Usage:** Relay server uses UDP for low-latency message relay.

**Characteristics:**
- **Connectionless:** No handshake
- **Unreliable:** No delivery guarantee
- **Fast:** Low overhead (8-byte header vs 20+ for TCP)
- **Order:** No ordering guarantee
- **No congestion control**

**Use Cases:** Real-time (VoIP, gaming, video streaming), DNS, NTP

**Ya OK Approach:** Application-level reliability (ACKs, retries, sequence numbers)

**Related Terms:** TCP, Datagram, Packet

---

### WiFi Direct (Wi-Fi P2P)
**Definition:** A WiFi standard allowing devices to connect directly to each other without a wireless access point (router).

**Ya OK Usage:** Local messaging within ~100 meters, faster than BLE.

**Specifications:**
- **Standard:** Wi-Fi Alliance (2010)
- **Range:** ~100 meters
- **Speed:** Up to 250 Mbps (802.11n)
- **Frequency:** 2.4 GHz and/or 5 GHz

**Connection:**
1. **Discovery:** Scan for nearby peers
2. **Negotiation:** Determine Group Owner (GO) via GO Negotiation
3. **Connection:** Client connects to GO's access point
4. **Communication:** Standard IP networking

**Android:** WifiP2pManager API  
**iOS:** Multipeer Connectivity Framework

**Related Terms:** P2P, WiFi, Group Owner

---

### DTN (Delay-Tolerant Networking)
**Definition:** A networking architecture designed for environments with intermittent connectivity, high delays, and frequent disruptions.

**Ya OK Usage:** Store-and-forward routing for offline messaging. Messages queue locally and forward when connectivity available.

**Principles:**
- **Store-and-Forward:** Intermediate nodes store messages until next hop available
- **Custody Transfer:** Next hop takes responsibility for delivery
- **Bundle Protocol:** Messages as "bundles" (self-contained units)

**Use Cases:** Space networks, military, disaster areas, rural regions

**Ya OK Implementation:** Simplified DTN with local message queuing and opportunistic forwarding.

**Related Terms:** Store-and-Forward, Opportunistic Networking, Mesh Network

---

### NAT (Network Address Translation)
**Definition:** A method of mapping private IP addresses (e.g., 192.168.x.x) to public IP addresses, allowing multiple devices to share a single public IP.

**Challenge for P2P:** NAT prevents direct connections between peers on different networks (NAT traversal problem).

**Solutions:**
- **STUN:** Discover public IP and port
- **TURN:** Relay traffic through server
- **ICE:** Combination of STUN and TURN
- **UPnP/NAT-PMP:** Automatic port forwarding

**Ya OK Approach:** Relay server for global connectivity (bypasses NAT)

**Related Terms:** NAT Traversal, STUN, TURN, ICE

---

## 3. Protocols & Standards

### RFC (Request for Comments)
**Definition:** A publication series by the Internet Engineering Task Force (IETF) describing methods, behaviors, research, or innovations for the Internet.

**Notable RFCs for Ya OK:**
- **RFC 8439:** ChaCha20-Poly1305 AEAD
- **RFC 7748:** Elliptic Curves for Security (X25519, Ed25519)
- **RFC 8032:** Ed25519 Signature Algorithm
- **RFC 5869:** HKDF (Key Derivation)
- **RFC 6762:** mDNS (Multicast DNS)
- **RFC 6763:** DNS-SD (Service Discovery)

**Format:** Informal to formal technical specifications

**Status:** Proposed Standard, Draft Standard, Internet Standard, Informational, Experimental, Best Current Practice

**Related Terms:** IETF, Internet Standards, Specifications

---

### ISO/IEC 12207
**Definition:** International standard for software lifecycle processes, covering acquisition, development, operation, and maintenance.

**Ya OK Compliance:** This documentation suite follows ISO/IEC 12207 structure and requirements.

**Lifecycle Processes:**
- **Primary:** Acquisition, Supply, Development, Operation, Maintenance
- **Supporting:** Documentation, Configuration Management, Quality Assurance, Verification, Validation
- **Organizational:** Management, Infrastructure, Training

**Benefits:** Standardized development process, quality assurance, audit compliance

**Related Terms:** Software Lifecycle, SDLC, ISO Standards

---

### ISO/IEC 25010
**Definition:** International standard defining a quality model for software product quality and quality in use.

**Ya OK NFRs:** Structured according to ISO/IEC 25010 quality characteristics.

**Quality Characteristics:**
1. **Functional Suitability:** Completeness, correctness, appropriateness
2. **Performance Efficiency:** Time behavior, resource utilization, capacity
3. **Compatibility:** Co-existence, interoperability
4. **Usability:** Recognizability, learnability, operability, accessibility
5. **Reliability:** Maturity, availability, fault tolerance, recoverability
6. **Security:** Confidentiality, integrity, non-repudiation, accountability, authenticity
7. **Maintainability:** Modularity, reusability, analyzability, modifiability, testability
8. **Portability:** Adaptability, installability, replaceability

**Related Terms:** Quality Attributes, NFRs, Software Quality

---

### ISO/IEC 27001
**Definition:** International standard for Information Security Management Systems (ISMS).

**Ya OK Security:** Security requirements mapped to ISO 27001 controls (Annex A).

**Control Categories:**
- **A.5:** Organizational security
- **A.8:** Asset management
- **A.9:** Access control
- **A.10:** Cryptography
- **A.12:** Operations security
- **A.14:** System development security
- **A.16:** Incident management
- **A.18:** Compliance

**Certification:** Not currently certified (planned for v2.0)

**Related Terms:** ISMS, Security Controls, Information Security

---

### ISO/IEC 27035
**Definition:** International standard for information security incident management.

**Ya OK IRP:** Incident Response Plan follows ISO/IEC 27035 structure.

**Phases:**
1. **Prepare and plan:** Establish capability
2. **Detection and reporting:** Identify incidents
3. **Assessment and decision:** Triage and classify
4. **Responses:** Contain, eradicate, recover
5. **Lessons learned:** Post-incident review

**Related Terms:** Incident Response, ISMS, ISO 27001

---

### NIST SP 800-61
**Definition:** NIST Special Publication 800-61 Rev 2: Computer Security Incident Handling Guide.

**Ya OK IRP:** Incident response lifecycle based on NIST SP 800-61.

**Phases:**
1. **Preparation:** Establish capabilities, tools, procedures
2. **Detection and Analysis:** Identify and analyze incidents
3. **Containment, Eradication, and Recovery:** Limit damage, remove threat, restore
4. **Post-Incident Activity:** Lessons learned, evidence retention

**Related Terms:** Incident Response, Incident Handling, NIST

---

### OWASP (Open Web Application Security Project)
**Definition:** Nonprofit foundation focused on improving software security through open-source projects, tools, and documentation.

**Ya OK Security Testing:** Follows OWASP Mobile Application Security Verification Standard (MASVS) Level 2.

**Notable OWASP Projects:**
- **MASVS:** Mobile security requirements
- **MSTG:** Mobile Security Testing Guide
- **Top 10:** Annual list of critical security risks
- **ASVS:** Application Security Verification Standard

**Related Terms:** Security Testing, MASVS, Vulnerability

---

### MASVS (Mobile Application Security Verification Standard)
**Definition:** OWASP standard defining security requirements for mobile apps at three levels (L1, L2, L3).

**Ya OK Target:** MASVS Level 2 (Standard Security)

**Levels:**
- **L1:** Basic security for all mobile apps
- **L2:** Apps handling sensitive data (e.g., banking, healthcare, messaging)
- **L3:** Maximum security for critical apps (defense, critical infrastructure)

**Requirements Categories:**
- **V1:** Architecture, Design, and Threat Modeling
- **V2:** Data Storage and Privacy
- **V3:** Cryptography
- **V4:** Authentication and Session Management
- **V5:** Network Communication
- **V6:** Platform Interaction
- **V7:** Code Quality and Build Settings
- **V8:** Resilience Against Reverse Engineering

**Related Terms:** OWASP, Security Testing, Mobile Security

---

### GDPR (General Data Protection Regulation)
**Definition:** European Union regulation on data protection and privacy, effective May 2018.

**Ya OK Compliance:**
- No personal data collection (no phone numbers, email, names)
- Right to access (data export)
- Right to erasure (account deletion)
- Data portability (JSON export)
- Privacy by design (E2EE, local storage)
- Breach notification (72 hours)

**Key Principles:**
- Lawfulness, fairness, transparency
- Purpose limitation
- Data minimization
- Accuracy
- Storage limitation
- Integrity and confidentiality

**Related Terms:** Privacy, Data Protection, Compliance

---

### CCPA (California Consumer Privacy Act)
**Definition:** California state law on consumer privacy rights, effective January 2020.

**Ya OK Compliance:**
- No sale of personal information (we don't collect any)
- Right to know (transparency about data practices)
- Right to delete (account deletion)
- Right to opt-out (not applicable, no data collection)

**Covered Businesses:** Annual revenue >$25M OR 50,000+ consumers OR 50%+ revenue from data sales

**Related Terms:** Privacy, Consumer Rights, Compliance

---

### ITIL 4
**Definition:** Information Technology Infrastructure Library version 4, a framework for IT service management (ITSM).

**Ya OK Operations:** Operational procedures follow ITIL 4 best practices.

**Service Value System:**
- **Guiding Principles:** Focus on value, start where you are, progress iteratively, etc.
- **Governance:** Oversight and direction
- **Service Value Chain:** Plan → Improve → Engage → Design → Obtain → Deliver
- **Practices:** 34 management practices (incident, change, release, etc.)
- **Continual Improvement:** Ongoing optimization

**Related Terms:** ITSM, Service Management, Operations

---

## 4. Architecture & Design

### C4 Model
**Definition:** A hierarchical set of architecture diagrams for visualizing software architecture at different levels of abstraction.

**Ya OK Architecture:** Documented using C4 model (4 levels).

**Levels:**
1. **Context:** System boundaries, users, external systems
2. **Container:** High-level technology choices (apps, databases, servers)
3. **Component:** Internal structure of containers (modules, packages)
4. **Code:** Class diagrams, ERDs (optional, detailed)

**Diagram Types:**
- **System Context:** Who uses the system, what external systems it integrates with
- **Container:** Applications, data stores, microservices
- **Component:** Modules within containers
- **Code:** Classes, functions, database schemas

**Benefits:** Clear abstraction levels, understandable by technical and non-technical stakeholders

**Related Terms:** Architecture Diagram, Abstraction, Software Design

---

### Component
**Definition:** A modular, encapsulated unit of software with a well-defined interface. Components can be independently developed, tested, and deployed.

**Ya OK Components:** Identity Manager, Crypto Engine, Message Manager, Transport Router, etc.

**Characteristics:**
- **Encapsulation:** Internal implementation hidden
- **Interface:** Well-defined API
- **Reusability:** Can be used in multiple contexts
- **Independence:** Minimal dependencies

**Related Terms:** Module, Package, Service

---

### Microservices
**Definition:** An architectural style where an application is composed of small, independent services communicating via APIs.

**Ya OK Architecture:** Monolithic Rust core (not microservices), but relay server is separate service.

**Characteristics:**
- **Small, focused services:** Single responsibility
- **Independent deployment:** Each service deployable separately
- **Decentralized data:** Each service owns its data
- **API communication:** REST, gRPC, messaging

**Trade-offs:**
- **Pros:** Scalability, flexibility, fault isolation
- **Cons:** Complexity, network overhead, distributed debugging

**Related Terms:** Service-Oriented Architecture, Distributed Systems

---

### Monorepo
**Definition:** A software development strategy where code for multiple projects is stored in a single repository.

**Ya OK Repository:** Single repo containing Rust core, Android app, iOS app, relay server, and documentation.

**Advantages:**
- Unified versioning
- Simplified dependency management
- Atomic cross-project changes
- Shared tooling

**Disadvantages:**
- Large repository size
- Complex CI/CD
- Access control challenges

**Related Terms:** Repository, Version Control, Git

---

### FFI (Foreign Function Interface)
**Definition:** A mechanism that allows code written in one programming language to call code written in another language.

**Ya OK Usage:** Rust core exposes C-compatible FFI for Android (Kotlin/JNI) and iOS (Swift/Objective-C) to call.

**Example:**
```rust
#[no_mangle]
pub extern "C" fn yaok_send_message(
    recipient: *const c_char,
    message: *const c_char
) -> i32 {
    // Implementation
}
```

**Challenges:**
- Manual memory management
- Type conversions
- Error handling
- Safety (crossing safety boundary)

**Related Terms:** JNI, Interop, Native Code

---

### ADR (Architecture Decision Record)
**Definition:** A document capturing an important architectural decision, its context, and consequences.

**Ya OK ADRs:** 5 ADRs documented in C4 Architecture document.

**Structure:**
- **Title:** Short descriptive name
- **Status:** Proposed, Accepted, Deprecated, Superseded
- **Context:** Problem, constraints, alternatives considered
- **Decision:** Chosen solution
- **Consequences:** Positive and negative outcomes

**Examples:**
- ADR-001: Use Rust for core library
- ADR-002: XChaCha20-Poly1305 for encryption
- ADR-003: UDP for relay protocol

**Related Terms:** Design Decision, Technical Debt, Documentation

---

## 5. Platform & Technology

### Android
**Definition:** Open-source mobile operating system based on Linux kernel, developed by Google.

**Ya OK Platform:** Native Android app (Kotlin) wraps Rust core via JNI.

**Key Technologies:**
- **Language:** Kotlin (modern, null-safe, coroutines)
- **UI:** Jetpack Compose (declarative UI, modern)
- **Background:** WorkManager (reliable background tasks)
- **Storage:** Room (SQLite wrapper) + SQLCipher
- **Network:** OkHttp, Retrofit
- **DI:** Dagger Hilt (dependency injection)

**Minimum Version:** Android 7.0 (API 24)  
**Target Version:** Android 14 (API 34)

**Related Terms:** Kotlin, JNI, Jetpack

---

### iOS
**Definition:** Mobile operating system created by Apple for iPhone and iPad.

**Ya OK Platform:** Native iOS app (Swift) wraps Rust core via C FFI.

**Key Technologies:**
- **Language:** Swift (modern, safe, performant)
- **UI:** SwiftUI (declarative UI)
- **Background:** Background Tasks framework
- **Storage:** Core Data + SQLCipher
- **Network:** URLSession, Alamofire
- **DI:** No formal DI (lightweight protocol-based)

**Minimum Version:** iOS 14.0  
**Target Version:** iOS 17.0

**Related Terms:** Swift, Objective-C, Xcode

---

### Rust
**Definition:** Systems programming language focused on safety, concurrency, and performance without garbage collection.

**Ya OK Core:** Entire cryptography, messaging, and transport logic implemented in Rust.

**Key Features:**
- **Memory Safety:** Ownership, borrowing, lifetimes (no garbage collector)
- **Concurrency:** Fearless concurrency (data races prevented at compile time)
- **Performance:** Zero-cost abstractions, no runtime overhead
- **Ecosystem:** Cargo (package manager), crates.io (package registry)

**Ya OK Dependencies:**
- **ring:** Cryptography (X25519, Ed25519, ChaCha20-Poly1305)
- **tokio:** Async runtime (relay server)
- **sqlx:** Database queries
- **serde:** Serialization/deserialization

**Related Terms:** Systems Programming, Memory Safety, Cargo

---

### Kotlin
**Definition:** Statically-typed programming language developed by JetBrains, fully interoperable with Java, official language for Android.

**Ya OK Android:** UI and platform integration in Kotlin.

**Key Features:**
- **Null Safety:** Compile-time null checking
- **Coroutines:** Structured concurrency (async/await)
- **Extension Functions:** Add methods to existing classes
- **Data Classes:** Immutable data holders with auto-generated methods
- **DSLs:** Domain-specific languages (e.g., Jetpack Compose UI)

**Interop:** Calls Rust via JNI (Java Native Interface)

**Related Terms:** Android, JVM, Coroutines

---

### Swift
**Definition:** General-purpose programming language developed by Apple for iOS, macOS, watchOS, and tvOS.

**Ya OK iOS:** UI and platform integration in Swift.

**Key Features:**
- **Safety:** Optionals, type safety, memory management (ARC)
- **Performance:** Compiled to native code
- **Modern:** Closures, generics, protocols, functional programming
- **Interop:** Seamless Objective-C interoperability

**Interop:** Calls Rust via C FFI (bridging header)

**Related Terms:** iOS, Xcode, ARC

---

### JNI (Java Native Interface)
**Definition:** Framework that enables Java/Kotlin code running in JVM to call and be called by native code (C/C++/Rust).

**Ya OK Usage:** Android Kotlin code calls Rust functions via JNI.

**Example (Kotlin):**
```kotlin
external fun yaokSendMessage(recipient: String, message: String): Int

companion object {
    init {
        System.loadLibrary("yaok_core")
    }
}
```

**Example (Rust):**
```rust
#[no_mangle]
pub extern "C" fn Java_app_yaok_YaOkNative_yaokSendMessage(
    env: JNIEnv,
    _class: JClass,
    recipient: JString,
    message: JString
) -> jint {
    // Implementation
}
```

**Related Terms:** FFI, Native Code, Interop

---

### Cargo
**Definition:** Rust's package manager and build system.

**Ya OK Usage:** Manages Rust dependencies, builds ya_ok_core library, runs tests.

**Commands:**
- `cargo build`: Compile project
- `cargo test`: Run tests
- `cargo clippy`: Lint code
- `cargo fmt`: Format code
- `cargo audit`: Check for vulnerabilities
- `cargo outdated`: Check for dependency updates

**Configuration:** `Cargo.toml` (dependencies, metadata, build settings)

**Related Terms:** Rust, Package Manager, Build Tool

---

### Gradle
**Definition:** Build automation tool primarily used for Java/Kotlin projects, including Android.

**Ya OK Usage:** Builds Android app, manages dependencies, runs tests.

**Configuration:** `build.gradle` (Groovy) or `build.gradle.kts` (Kotlin DSL)

**Key Concepts:**
- **Projects:** Multi-module builds
- **Tasks:** Build steps (compile, test, assemble)
- **Dependencies:** External libraries
- **Plugins:** Extend functionality (Android, Kotlin, ProGuard)

**Related Terms:** Android, Build Tool, Dependency Management

---

### CocoaPods
**Definition:** Dependency manager for Swift and Objective-C projects.

**Ya OK Usage:** Manages iOS dependencies (SQLCipher, Alamofire, etc.)

**Configuration:** `Podfile`

**Commands:**
- `pod install`: Install dependencies
- `pod update`: Update dependencies
- `pod outdated`: Check for updates

**Alternative:** Swift Package Manager (SPM)

**Related Terms:** iOS, Dependency Management, Swift

---

## 6. Security & Privacy

### End-to-End Encryption (E2EE)
**Definition:** Communication system where only the communicating users can read the messages. No third party (including service provider) can access cryptographic keys.

**Ya OK E2EE:** All messages encrypted on sender device, decrypted only on recipient device. Relay server cannot decrypt.

**Characteristics:**
- Keys generated on device (never leave device)
- Encryption/decryption on endpoints only
- Server sees only encrypted ciphertext

**Contrast:** Server-side encryption (keys on server, server can decrypt)

**Related Terms:** Encryption, Privacy, Confidentiality

---

### Zero-Knowledge
**Definition:** A system where the service provider has zero knowledge of user data.

**Ya OK Zero-Knowledge:**
- No account creation (no email, phone, name)
- No message storage on server (or encrypted if stored)
- No user tracking (no analytics, no IPs stored)
- No metadata collection

**Benefits:** Maximum privacy, no data breach risk (no data to breach)

**Related Terms:** Privacy, Data Minimization, E2EE

---

### Threat Model
**Definition:** Structured representation of threats to a system, including threat actors, attack vectors, assets, and mitigations.

**Ya OK Threat Model:** STRIDE methodology (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege).

**Components:**
- **Assets:** User messages, identity keys, contacts
- **Threat Actors:** Passive observers, active attackers, malicious users, nation-states
- **Attack Vectors:** Network sniffing, MITM, malware, social engineering
- **Mitigations:** Encryption, authentication, code signing, secure storage

**Related Terms:** STRIDE, Risk Assessment, Security

---

### Attack Surface
**Definition:** The sum of all points where an unauthorized user can try to enter or extract data from a system.

**Ya OK Attack Surface:**
- **Network:** BLE, WiFi Direct, UDP relay
- **Storage:** Local database (encrypted)
- **UI:** Input validation, XSS prevention
- **Platform:** OS vulnerabilities, rooting/jailbreaking
- **Code:** Memory safety (Rust helps), third-party dependencies

**Reduction Strategies:**
- Minimize exposed APIs
- Input validation
- Principle of least privilege
- Regular security audits

**Related Terms:** Vulnerability, Threat Surface, Security

---

### Penetration Testing (Pentest)
**Definition:** Authorized simulated cyberattack on a system to evaluate security.

**Ya OK Pentesting:** OWASP MASVS L2 compliance testing (planned Q2 2026).

**Types:**
- **Black Box:** No prior knowledge (external attacker perspective)
- **White Box:** Full knowledge (source code, architecture)
- **Gray Box:** Partial knowledge (typical insider)

**Common Tests:**
- Network traffic interception
- Authentication bypass
- Encryption weaknesses
- Injection attacks
- Social engineering

**Related Terms:** Security Testing, Vulnerability Assessment, Red Team

---

### Vulnerability
**Definition:** A weakness in a system that can be exploited by a threat actor.

**Examples:**
- **Software Bug:** Buffer overflow, SQL injection, XSS
- **Misconfiguration:** Default credentials, open ports
- **Design Flaw:** Weak encryption, broken authentication

**Ya OK Vulnerability Management:**
- Automated scanning (Dependabot, cargo audit)
- Patch within 7 days (critical), 30 days (non-critical)
- Security advisories (GitHub Security Advisories)

**Related Terms:** Exploit, CVE, Patch

---

### CVE (Common Vulnerabilities and Exposures)
**Definition:** A system for identifying and cataloging publicly disclosed cybersecurity vulnerabilities.

**Format:** CVE-YYYY-NNNNN (e.g., CVE-2024-12345)

**Ya OK Process:**
1. Dependabot detects CVE in dependency
2. GitHub Security Advisory created
3. Engineering team triages (severity, exploitability)
4. Patch applied within SLA (critical: 7 days)
5. Release + notification to users

**Database:** NIST National Vulnerability Database (NVD), MITRE

**Related Terms:** Vulnerability, Security Advisory, Patch

---

### Security Audit
**Definition:** Comprehensive assessment of a system's security, including code review, configuration review, and compliance verification.

**Ya OK Audit Schedule:**
- **Internal:** Quarterly (Q1, Q2, Q3, Q4)
- **External:** Annual (third-party security firm)
- **Penetration Test:** Annual (OWASP MASVS L2)

**Audit Scope:**
- Cryptography implementation
- Authentication mechanisms
- Data storage security
- Network protocol security
- Compliance (GDPR, CCPA, ISO 27001)

**Related Terms:** Compliance, Security Testing, Risk Assessment

---

## 7. Quality Attributes

### ACID (Atomicity, Consistency, Isolation, Durability)
**Definition:** A set of properties that guarantee database transactions are processed reliably.

**ACID Properties:**
- **Atomicity:** Transaction is all-or-nothing
- **Consistency:** Database remains in valid state before/after transaction
- **Isolation:** Concurrent transactions don't interfere
- **Durability:** Committed transactions persist even after system failure

**Ya OK Usage:** SQLite provides ACID guarantees for message storage.

**Example:** Sending a message and updating status happens atomically (both succeed or both fail).

**Related Terms:** Transaction, Database, Reliability

---

### CAP Theorem
**Definition:** Theorem stating a distributed system can provide at most two of: Consistency, Availability, Partition tolerance.

**Trade-offs:**
- **CA:** Consistent and Available (no partition tolerance) — single-node systems
- **CP:** Consistent and Partition-tolerant — may become unavailable
- **AP:** Available and Partition-tolerant — eventual consistency

**Ya OK:** Primarily CP (consistency + partition tolerance). Relay server prioritizes consistency; clients queue messages during network partitions.

**Related Terms:** Distributed Systems, Consistency, Availability

---

### Eventual Consistency
**Definition:** A consistency model where, given enough time without updates, all replicas of data converge to the same value.

**Ya OK Usage:** Message synchronization across devices (future multi-device support) will use eventual consistency.

**Trade-off:** Accepts temporary inconsistency for availability and partition tolerance.

**Example:** Message read receipts may take seconds to propagate between devices.

**Related Terms:** Distributed Systems, CAP Theorem, Consistency

---

### Idempotency
**Definition:** A property where an operation produces the same result regardless of how many times it's executed.

**Ya OK Usage:** Relay server message delivery is idempotent (duplicate MESSAGE packets ignored via message ID deduplication).

**Example:**
```
Send message with ID "abc123" → Success
Send message with ID "abc123" again → Ignored (already received)
```

**Benefits:**
- Safe retries (network failures)
- Duplicate prevention
- Simplified error handling

**Related Terms:** Retry Logic, Reliability, Distributed Systems

---

### Latency
**Definition:** The time delay between cause and effect, typically measured as round-trip time (RTT) or one-way delay.

**Ya OK Latency Targets:**
- **BLE/WiFi:** < 300ms (p95)
- **Relay:** < 1s (p95)
- **UI Response:** < 100ms

**Measurement:** p50 (median), p95 (95th percentile), p99 (99th percentile)

**Optimization:**
- Async I/O (Tokio for Rust relay server)
- Connection pooling
- Caching
- Prefetching

**Related Terms:** Performance, Response Time, Throughput

---

### Throughput
**Definition:** The amount of work completed per unit time.

**Ya OK Throughput:**
- **Encryption:** > 100 MB/s (XChaCha20-Poly1305)
- **BLE:** ~1 MB/s (2M PHY)
- **WiFi:** ~10 MB/s
- **Relay:** ~10K messages/sec per server

**Trade-off:** Latency vs throughput (optimize for one may degrade the other)

**Related Terms:** Performance, Bandwidth, Capacity

---

### Scalability
**Definition:** The ability of a system to handle increased load by adding resources.

**Types:**
- **Vertical (Scale Up):** Add more resources to single node (CPU, RAM)
- **Horizontal (Scale Out):** Add more nodes to system

**Ya OK Scalability:**
- **Horizontal:** Add relay server instances (Fly.io)
- **Vertical:** Increase VM size (shared-cpu-1x → dedicated-cpu-1x)
- **Geographic:** Multi-region deployment (ams, iad, sin)

**Limitations:** Database (SQLite) not horizontally scalable (single-node only)

**Related Terms:** Performance, Load Balancing, Capacity Planning

---

## 8. Business & Metrics

### DAU (Daily Active Users)
**Definition:** The number of unique users who interact with an application in a 24-hour period.

**Ya OK Tracking:** Local-only analytics (no server-side tracking).

**Calculation:** Count unique user IDs who send/receive messages per day.

**Use Case:** Engagement metric, growth tracking, feature adoption.

**Related Terms:** WAU, MAU, Active Users, Engagement

---

### WAU (Weekly Active Users)
**Definition:** The number of unique users who interact with an application in a 7-day period.

**Ya OK Tracking:** Local-only analytics.

**Calculation:** Count unique user IDs who send/receive messages per week.

**Related Terms:** DAU, MAU, Active Users

---

### MAU (Monthly Active Users)
**Definition:** The number of unique users who interact with an application in a 30-day period.

**Ya OK Tracking:** Local-only analytics.

**Use Case:** Long-term growth, retention trends, churn analysis.

**Related Terms:** DAU, WAU, Active Users

---

### Retention Rate
**Definition:** The percentage of users who return to an app after their first visit.

**Calculation:**
```
Retention Rate = (Users who returned / Total users) × 100%
```

**Types:**
- **D1 Retention:** Return after 1 day
- **D7 Retention:** Return after 7 days
- **D30 Retention:** Return after 30 days

**Ya OK Target:** D7 > 50%, D30 > 30%

**Related Terms:** Churn, Active Users, Engagement

---

### Churn Rate
**Definition:** The percentage of users who stop using an app over a given period.

**Calculation:**
```
Churn Rate = (Users who left / Total users at start) × 100%
```

**Ya OK Definition:** User hasn't sent/received message in 30 days.

**Target:** < 5% monthly churn

**Related Terms:** Retention, Active Users, Attrition

---

### Crash-Free Rate
**Definition:** The percentage of app sessions that do not result in a crash.

**Calculation:**
```
Crash-Free Rate = ((Total sessions - Crashed sessions) / Total sessions) × 100%
```

**Ya OK Target:** > 99.5%

**Tracking:** Firebase Crashlytics, Sentry

**Related Terms:** Stability, Reliability, Error Rate

---

### Error Rate
**Definition:** The percentage of operations that result in an error.

**Ya OK Tracking:**
- **Message Send Error Rate:** < 1% (online)
- **Database Error Rate:** < 0.1%
- **Network Error Rate:** Varies by transport

**Calculation:**
```
Error Rate = (Failed operations / Total operations) × 100%
```

**Related Terms:** Reliability, Failure Rate, Success Rate

---

### SLA (Service Level Agreement)
**Definition:** A commitment between a service provider and customer defining the level of service expected.

**Ya OK SLA (Relay Server):**
- **Uptime:** 99.9% (< 43 minutes downtime per month)
- **Latency:** < 1s (p95)
- **Error Rate:** < 1%

**Related Terms:** SLO, SLI, Uptime

---

### SLO (Service Level Objective)
**Definition:** A target value or range for a service level measured by an SLI.

**Ya OK SLOs:**
- **Availability:** 99.9% uptime
- **Latency:** p95 < 1s (relay), p95 < 300ms (BLE/WiFi)
- **Error Rate:** < 1%
- **Crash-Free Rate:** > 99.5%

**Related Terms:** SLA, SLI, Performance

---

### SLI (Service Level Indicator)
**Definition:** A quantitative measure of a service level.

**Ya OK SLIs:**
- **Availability:** % of successful health checks
- **Latency:** p50, p95, p99 response time
- **Error Rate:** % of failed requests
- **Throughput:** Messages/second

**Measurement:** Prometheus metrics, Grafana dashboards

**Related Terms:** SLO, SLA, Metrics

---

## 9. Development & Testing

### CI/CD (Continuous Integration / Continuous Deployment)
**Definition:** A software development practice where code changes are automatically built, tested, and deployed.

**Ya OK CI/CD:** GitHub Actions

**Continuous Integration:**
- Trigger: Push to `main` branch or PR
- Build: Compile Rust, Android, iOS
- Test: Run unit tests, integration tests, security tests
- Lint: Clippy (Rust), ktlint (Kotlin), SwiftLint (iOS)
- Coverage: Generate coverage report (> 75% required)

**Continuous Deployment:**
- Deploy relay server to Fly.io (staging → production)
- Build Android APK/AAB (Google Play)
- Build iOS IPA (TestFlight → App Store)

**Related Terms:** DevOps, Automation, GitHub Actions

---

### Unit Test
**Definition:** A test that validates a single unit of code (function, method, class) in isolation.

**Ya OK Unit Tests:** 345 unit tests in Rust core, Android, iOS.

**Characteristics:**
- **Isolation:** No external dependencies (mocked)
- **Fast:** Milliseconds per test
- **Deterministic:** Same input → same output
- **Automated:** Run in CI/CD

**Example (Rust):**
```rust
#[test]
fn test_encrypt_decrypt() {
    let key = generate_key();
    let plaintext = b"Hello, world!";
    let ciphertext = encrypt(&key, plaintext);
    let decrypted = decrypt(&key, &ciphertext).unwrap();
    assert_eq!(plaintext, decrypted.as_slice());
}
```

**Related Terms:** Testing, TDD, Test Coverage

---

### Integration Test
**Definition:** A test that validates the interaction between multiple components or systems.

**Ya OK Integration Tests:** 161 integration tests validating end-to-end flows.

**Examples:**
- Send message via BLE (Android → Android)
- Register with relay server + send message
- Identity export → import flow
- Database transactions (write → read → verify)

**Characteristics:**
- **Realistic:** Uses real components (not mocks)
- **Slower:** Seconds to minutes per test
- **End-to-End:** Validates entire flow

**Related Terms:** Testing, E2E Testing, System Testing

---

### Test Coverage
**Definition:** A metric measuring the percentage of code executed by tests.

**Ya OK Coverage:** 79% code coverage (target: 85%)

**Types:**
- **Line Coverage:** % of lines executed
- **Branch Coverage:** % of branches (if/else) executed
- **Function Coverage:** % of functions called

**Tools:**
- **Rust:** cargo-tarpaulin
- **Android:** JaCoCo
- **iOS:** XCTest Coverage

**Formula:**
```
Coverage = (Lines executed / Total lines) × 100%
```

**Related Terms:** Testing, Quality Assurance, Metrics

---

### Mock
**Definition:** A simulated object that mimics the behavior of real objects in controlled ways, used in testing.

**Ya OK Mocking:** Mock BLE transport, relay server, database for unit tests.

**Example (Rust):**
```rust
struct MockTransport;
impl Transport for MockTransport {
    fn send(&self, message: &[u8]) -> Result<()> {
        // Simulate successful send
        Ok(())
    }
}
```

**Benefits:**
- Isolate unit under test
- Control behavior (simulate errors, delays)
- Fast (no real I/O)

**Related Terms:** Unit Testing, Stub, Test Double

---

### TDD (Test-Driven Development)
**Definition:** A software development process where tests are written before code.

**TDD Cycle:**
1. **Red:** Write failing test
2. **Green:** Write minimal code to pass test
3. **Refactor:** Improve code while keeping tests passing

**Ya OK Approach:** Partial TDD (critical components like crypto use TDD)

**Benefits:**
- Better design (testable code)
- Fewer bugs
- Living documentation (tests as specs)

**Related Terms:** Testing, Agile, Development Process

---

### Code Review
**Definition:** A systematic examination of source code by peers to find bugs, improve quality, and share knowledge.

**Ya OK Process:**
- All code changes via Pull Request (PR)
- At least 1 reviewer (security-sensitive: 2 reviewers)
- Automated checks (CI/CD, linting, tests)
- Review criteria: correctness, performance, security, style

**Best Practices:**
- Small PRs (< 400 lines)
- Clear description and context
- Test coverage included
- No merge without approval

**Related Terms:** Pull Request, Peer Review, Quality Assurance

---

### Static Analysis
**Definition:** Analysis of code without executing it, used to detect bugs, vulnerabilities, and style violations.

**Ya OK Tools:**
- **Rust:** Clippy (linter), rustfmt (formatter), cargo audit (vulnerabilities)
- **Kotlin:** ktlint (linter), detekt (static analysis)
- **Swift:** SwiftLint (linter), SwiftFormat (formatter)

**Benefits:**
- Early bug detection
- Enforce code style
- Security vulnerability detection
- Zero runtime overhead

**Related Terms:** Linting, Code Quality, SAST

---

### Refactoring
**Definition:** The process of restructuring existing code without changing its external behavior.

**Goals:**
- Improve readability
- Reduce complexity
- Eliminate duplication
- Improve maintainability

**Ya OK Refactoring:**
- Quarterly refactoring sprints
- Technical debt tracked in GitHub Issues
- Refactoring guided by code smells (long functions, duplication, etc.)

**Best Practices:**
- Small, incremental changes
- Test coverage before refactoring
- Review diffs carefully

**Related Terms:** Code Quality, Technical Debt, Maintainability

---

## 10. Acronyms & Abbreviations

### A-C

- **AAD:** Associated Authenticated Data
- **AEAD:** Authenticated Encryption with Associated Data
- **AES:** Advanced Encryption Standard
- **API:** Application Programming Interface
- **APK:** Android Package Kit (Android app file)
- **BLE:** Bluetooth Low Energy
- **CA:** Certificate Authority
- **CAP:** Consistency, Availability, Partition tolerance
- **CCPA:** California Consumer Privacy Act
- **CI/CD:** Continuous Integration / Continuous Deployment
- **CPU:** Central Processing Unit
- **CSPRNG:** Cryptographically Secure Pseudorandom Number Generator
- **CVE:** Common Vulnerabilities and Exposures

### D-F

- **DAU:** Daily Active Users
- **DB:** Database
- **DDoS:** Distributed Denial of Service
- **DNS:** Domain Name System
- **DoS:** Denial of Service
- **DR:** Disaster Recovery
- **DTN:** Delay-Tolerant Networking
- **E2EE:** End-to-End Encryption
- **ECDH:** Elliptic Curve Diffie-Hellman
- **FFI:** Foreign Function Interface
- **FPS:** Frames Per Second
- **FR:** Functional Requirement
- **FTS:** Full-Text Search

### G-I

- **GATT:** Generic Attribute Profile (Bluetooth)
- **GDPR:** General Data Protection Regulation
- **HA:** High Availability
- **HKDF:** HMAC-based Key Derivation Function
- **HMAC:** Hash-based Message Authentication Code
- **HTTP:** Hypertext Transfer Protocol
- **HTTPS:** HTTP Secure
- **IaC:** Infrastructure as Code
- **IC:** Incident Commander
- **ID:** Identifier
- **IDE:** Integrated Development Environment
- **IETF:** Internet Engineering Task Force
- **IoT:** Internet of Things
- **IP:** Internet Protocol
- **IPA:** iOS App Archive
- **IRP:** Incident Response Plan
- **ISMS:** Information Security Management System
- **ISO:** International Organization for Standardization
- **ITIL:** Information Technology Infrastructure Library
- **ITSM:** IT Service Management
- **IV:** Initialization Vector

### J-L

- **JNI:** Java Native Interface
- **JSON:** JavaScript Object Notation
- **JVM:** Java Virtual Machine
- **KDF:** Key Derivation Function
- **LOC:** Lines of Code
- **LTS:** Long-Term Support

### M-O

- **MAC:** Message Authentication Code
- **MAU:** Monthly Active Users
- **MASVS:** Mobile Application Security Verification Standard
- **mDNS:** Multicast DNS
- **MITM:** Man-in-the-Middle
- **MTBF:** Mean Time Between Failures
- **MTTR:** Mean Time To Recovery
- **NAT:** Network Address Translation
- **NFR:** Non-Functional Requirement
- **NIST:** National Institute of Standards and Technology
- **NSD:** Network Service Discovery (Android)
- **OWASP:** Open Web Application Security Project

### P-R

- **P2P:** Peer-to-Peer
- **PBKDF2:** Password-Based Key Derivation Function 2
- **PFS:** Perfect Forward Secrecy
- **PII:** Personally Identifiable Information
- **PKI:** Public Key Infrastructure
- **PR:** Pull Request
- **PRNG:** Pseudorandom Number Generator
- **QA:** Quality Assurance
- **QR:** Quick Response (QR code)
- **RAM:** Random Access Memory
- **REST:** Representational State Transfer
- **RFC:** Request for Comments
- **RNG:** Random Number Generator
- **RPO:** Recovery Point Objective
- **RTM:** Requirements Traceability Matrix
- **RTO:** Recovery Time Objective
- **RTT:** Round-Trip Time

### S-U

- **SDLC:** Software Development Lifecycle
- **SHA:** Secure Hash Algorithm
- **SLA:** Service Level Agreement
- **SLI:** Service Level Indicator
- **SLO:** Service Level Objective
- **SMS:** Short Message Service
- **SOP:** Standard Operating Procedure
- **SQL:** Structured Query Language
- **SR:** Security Requirement
- **SRE:** Site Reliability Engineer
- **SRS:** Software Requirements Specification
- **SSH:** Secure Shell
- **SSL:** Secure Sockets Layer
- **STRIDE:** Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege
- **TDD:** Test-Driven Development
- **TLS:** Transport Layer Security
- **TOML:** Tom's Obvious, Minimal Language
- **TTL:** Time To Live
- **UDP:** User Datagram Protocol
- **UI:** User Interface
- **URI:** Uniform Resource Identifier
- **URL:** Uniform Resource Locator
- **USB:** Universal Serial Bus
- **UTC:** Coordinated Universal Time
- **UTF-8:** Unicode Transformation Format - 8-bit
- **UUID:** Universally Unique Identifier
- **UX:** User Experience

### V-Z

- **VM:** Virtual Machine
- **VPN:** Virtual Private Network
- **WAU:** Weekly Active Users
- **WCAG:** Web Content Accessibility Guidelines
- **WiFi:** Wireless Fidelity
- **WLAN:** Wireless Local Area Network
- **XSS:** Cross-Site Scripting
- **YAML:** YAML Ain't Markup Language

---

## Appendix: Quick Reference Tables

### Encryption Algorithms

| Algorithm | Type | Key Size | Nonce Size | Security | Ya OK Usage |
|-----------|------|----------|------------|----------|-------------|
| XChaCha20 | Stream Cipher | 256 bits | 192 bits | 256-bit | Message encryption |
| Poly1305 | MAC | 256 bits | N/A | 128-bit | Message authentication |
| X25519 | ECDH | 256 bits | N/A | 128-bit | Key exchange |
| Ed25519 | Digital Signature | 256 bits | N/A | 128-bit | Message signing, identity |
| SHA-256 | Hash | N/A | N/A | 128-bit | Fingerprints, integrity |

### Transport Comparison

| Transport | Range | Speed | Offline | Latency | Power | Use Case |
|-----------|-------|-------|---------|---------|-------|----------|
| BLE | ~30m | ~1 MB/s | ✅ Yes | < 300ms | Ultra-low | Nearby messaging |
| WiFi Direct | ~100m | ~10 MB/s | ✅ Yes | < 300ms | Low | Local network |
| Relay (UDP) | Global | Varies | ❌ No | < 1s | Medium | Internet messaging |

### Quality Attribute Targets

| Attribute | Metric | Target | Current | Status |
|-----------|--------|--------|---------|--------|
| Performance | Startup Time | < 2s | 1.8s | ✅ Met |
| Performance | Message Latency (p95) | < 300ms | 280ms | ✅ Met |
| Reliability | Crash-Free Rate | > 99.5% | 99.7% | ✅ Met |
| Security | Encryption Strength | 256-bit | 256-bit | ✅ Met |
| Usability | Learning Curve | < 5 min | ~4 min | ✅ Met |
| Maintainability | Test Coverage | > 80% | 79% | ⚠️ Close |

### Standards Compliance

| Standard | Name | Status | Certification |
|----------|------|--------|---------------|
| ISO/IEC 12207 | Software Lifecycle | ✅ Compliant | Self-assessed |
| ISO/IEC 25010 | Quality Model | ✅ Compliant | Self-assessed |
| ISO/IEC 27001 | Security Management | ⏳ Partial | Planned v2.0 |
| OWASP MASVS L2 | Mobile Security | ⏳ In Progress | Q2 2026 |
| GDPR | Data Protection | ✅ Compliant | Self-assessed |
| CCPA | Consumer Privacy | ✅ Compliant | Self-assessed |

---

**Document Classification:** PUBLIC  
**Distribution:** All team members, external contributors, users  
**Review Cycle:** Semi-annually or when new terminology introduced

**End of Glossary**
