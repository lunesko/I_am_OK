# Changelog

All notable changes to **YA OK** (Я ОК) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **GitHub Actions CI/CD pipeline** (Issue #31)
  - Rust core: cargo fmt, clippy, test, build, cargo audit
  - Relay server: clippy, build release, Docker build test
  - Android: Gradle lint, assembleDebug, assembleRelease, APK artifacts
  - iOS: Xcode build on macOS runner
  - Security scan: Trivy vulnerability scanner (SARIF → GitHub Security)
  - Code quality: cargo-complexity, cargo-outdated
- **SECURITY.md** with responsible disclosure process (Issue #33)
- **Enhanced .gitignore** for secrets protection (Issue #34)
  - Environment variables (.env, .env.local)
  - Secrets directories (secrets/, private/)
  - Keystore files (*.keystore, *.jks)
  - Private keys (*.pem, *.key, *.p12, id_rsa)
  - Database files (*.db, *.sqlite)
  - CI/CD secrets (.github/secrets/)

### Changed
- **Crypto upgrade:** AES-GCM-SIV → XChaCha20-Poly1305 (Issue #1)
  - 192-bit nonce (no reuse risk)
  - `chacha20poly1305 = "0.10"` dependency
  - Removed `aes-gcm-siv` dependency
- **SQLite WAL mode** for better concurrency and crash recovery (Issue #28)
  - `PRAGMA journal_mode=WAL`
  - `PRAGMA auto_vacuum=INCREMENTAL`
  - `PRAGMA page_size=4096`
  - Incremental vacuum after `cleanup_expired()`
- **Enhanced input validation** in Message (Issue #29)
  - Reject control characters (U+0000-U+001F, U+007F-U+009F)
  - Block zero-width characters (steganography protection)
  - Support Cyrillic (U+0400-U+04FF) and Emoji (U+1F300-U+1F9FF)
- **Packet deserialization size limits** (Issue #30)
  - MAX_PACKET_SIZE=128 KB
  - MAX_ENCRYPTED_PAYLOAD=64 KB
  - Validate signature≤64, keys=32 bytes
  - New error: `PacketError::PacketTooLarge(usize)`
- **Relay configuration externalized** (Issue #22)
  - iOS: Config.plist with RelayConfiguration dictionary
  - Android: res/raw/relay_config.properties
  - UdpService.swift reads from Bundle.main
  - UdpTransport.kt reads via lazy property
- **Docker healthcheck enhanced** (Issue #32)
  - `pgrep -f yaok-relay` + `nc -uzv` UDP socket check
  - Added netcat-openbsd, procps packages
  - start-period=10s, retries=3

### Fixed
- **Android build signing** (Issue #2)
  - Created production keystore: android/app/debug.keystore
  - Configured signingConfigs in build.gradle
  - Safe keystore.properties loading
- **Relay memory exhaustion** (Issue #3)
  - MAX_PEERS=10K, MAX_RATE_ENTRIES=50K
  - CLEANUP_INTERVAL=1000 packets
  - Forced cleanup when limit reached (oldest 10%)
  - Added `dropped_peer_limit` metric
- **Race conditions in FFI** (Issue #4, #5, #6, #7)
  - Added `tokio::sync::Mutex` in relay main.rs
  - Protected `UdpTransport::send_to_relay` in transport_manager.rs
  - Protected peer_map and rate_map in relay
  - Removed unsafe raw pointers (FfiCallback → safe wrapper)
- **Private keys zeroize** (Issue #8)
  - Added `zeroize = { version = "1.9.0", features = ["derive"] }` dependency
  - Implemented `#[derive(Zeroize, ZeroizeOnDrop)]` for Identity, MessageEncryption
  - Memory auto-cleared on drop
- **Storage thread safety** (Issue #9)
  - Added `Arc<Mutex<rusqlite::Connection>>` in storage/mod.rs
  - Thread-safe message storage
- **Relay security** (Issue #10)
  - IP Pinning: whitelist 213.188.195.83
  - Rate Limiting: max 100 packets/sec per peer
  - Port Validation: only 40100
  - Created RelaySecurityManager (iOS + Android)
- **License added** (Issue #11): MIT License (LICENSE file)
- **Rust dependencies updated** (Issue #12)
  - tokio 1.42, rusqlite 0.32, chacha20poly1305 0.10
  - Outdated crates upgraded
- **Android dependencies updated** (Issue #13)
  - AGP 8.2.2 → 8.7.3
  - Kotlin 1.8.22 → 2.1.0
  - androidx.core 1.12.0 → 1.15.0
  - compileSdk 34 → 35 (Android 15 stable)
- **SQL injection prevented** (Issue #14)
  - UUID validation before SQL queries in storage/mod.rs
  - Regex check: `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`
- **Key security guide** (Issue #17)
  - Created SECURE_KEY_STORAGE.md
  - iOS: Keychain Services (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
  - Android: Keystore System (hardware-backed encryption)
- **Signature verification documented** (Issue #18)
  - Architecture: Packet::decrypt() verifies at line 135
  - Network → decrypt → [SIGNATURE VERIFIED] → store_message
- **TOCTOU race condition** (Issue #20)
  - Created atomic `can_be_forwarded()` method in packet.rs
  - Single timestamp for TTL and hops check
- **Force unwraps removed** (Issue #23)
  - FamilyViewController.swift: safe optional unwrapping
  - Replaced `id!` with `if let id = id, !id.isEmpty { ... }`
- **Android API Level clarified** (Issue #26)
  - Android 15 (API 35) stable since October 2024
  - androidx.core 1.15.0 REQUIRES compileSdk 35
  - Current configuration is correct ✅

### Security
- **Rate limiter memory leak** fixed (Issue #19) - cleanup old entries
- **Certificate pinning** documented (Issue #21) - IP pinning as alternative for UDP
- **Hardcoded relay IP** moved to config files (Issue #22)
- **Force unwraps** removed from Swift code (Issue #23)
- **Database growth** controlled with WAL + incremental vacuum (Issue #28)
- **Input validation** hardened against steganography, homographs (Issue #29)
- **Deserialization** protected from memory exhaustion (Issue #30)

## [0.1.0] - UNRELEASED (Alpha)

### Initial Release
- **Emergency mesh messaging app** for offline P2P communication
- **E2E encryption:** XChaCha20-Poly1305
- **Digital signatures:** Ed25519 (64-byte signatures)
- **Key exchange:** X25519 ECDH
- **UDP relay server:** Rust-based relay on Fly.io
- **Mobile apps:** Flutter (iOS + Android)
- **Core library:** Rust (`ya_ok_core`) with FFI bindings
- **Offline storage:** SQLite with TTL
- **QR code pairing:** In-person contact verification

[Unreleased]: https://github.com/poruch/ya-ok/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/poruch/ya-ok/releases/tag/v0.1.0
