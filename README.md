# Я ОК (Ya OK) — Secure Delay-Tolerant Messaging

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/rust-1.70%2B-orange.svg)](https://www.rust-lang.org/)
[![Android](https://img.shields.io/badge/android-API%2023%2B-green.svg)](https://developer.android.com/)
[![iOS](https://img.shields.io/badge/iOS-14%2B-lightgrey.svg)](https://developer.apple.com/ios/)

Я ОК (Ukrainian for "I'm OK") is a secure, decentralized messaging app designed for emergency situations and low-connectivity environments. Built on Delay-Tolerant Networking (DTN) principles with end-to-end encryption.

## 🌟 Key Features

### Core Capabilities
- ✅ **Delay-Tolerant Networking (DTN)**: Store & Forward routing for intermittent connectivity
- ✅ **Multi-Transport**: BLE, WiFi Direct, UDP/IP, Relay fallback
- ✅ **End-to-End Encryption**: Ed25519 signatures + X25519 key exchange + AES-GCM-256
- ✅ **ACK & Delivery Confirmation**: Honest "received" and "delivered" semantics
- ✅ **Peer Key Store**: Persistent trusted peer management
- ✅ **Priority Queue**: High/Medium/Low message prioritization
- ✅ **Chunking/Reassembly**: 1200-byte UDP chunks with CRC32 integrity checks

### Message Types
- **Status**: "Я ОК" (I'm OK), "Зайнятий" (Busy), "Пізніше" (Later)
- **Text**: Up to 256 bytes (Cyrillic, emoji supported)
- **Voice**: Up to 7 seconds audio

### Security
- **Ed25519 Signatures**: Message authentication
- **X25519 ECDH**: Perfect forward secrecy
- **AES-GCM-256**: Authenticated encryption
- **SQLite WAL**: Secure local storage with deduplication

## 📱 Platforms

| Platform | Status | Build |
|----------|--------|-------|
| **Android** | ✅ Ready | Gradle (API 23+) |
| **iOS** | 🚧 Beta | Swift + Rust FFI |
| **Relay Server** | ✅ Ready | Rust (Tokio) |

## 📁 Project Structure

```
ya_ok/
├── ya_ok_core/          # Rust core library
│   ├── src/
│   │   ├── core/        # Identity, messages, ACK
│   │   ├── crypto/      # Ed25519, X25519, AES-GCM
│   │   ├── storage/     # SQLite persistence
│   │   ├── transport/   # BLE, WiFi, UDP, chunking
│   │   ├── routing/     # DTN router, priority queue
│   │   ├── api/         # FFI/JNI bindings
│   │   └── lib.rs
│   └── Cargo.toml
├── android/             # Android app
│   ├── app/src/main/kotlin/
│   └── build.gradle
├── ios/                 # iOS app
│   ├── Runner/          # Swift sources
│   └── Runner.xcodeproj
├── relay/               # Relay server
│   ├── src/main.rs      # HTTP metrics + UDP relay
│   └── Dockerfile
└── docs/                # Documentation
    ├── QA_MATRIX.md
    ├── ACK_IMPLEMENTATION.md
    └── DEFINITION_OF_DONE_AND_SCENARIOS.md
```

## 🚀 Quick Start

### Build Core Library

```bash
cd ya_ok_core
cargo build --release
cargo test
```

### Run Relay Server

```bash
cd relay
cargo run --release

# Or with Docker
docker build -t yaok-relay .
docker run -p 40100:40100/udp -p 9090:9090 yaok-relay
```

**Relay Monitoring**:
- Health: `http://localhost:9090/health`
- Metrics (Prometheus): `http://localhost:9090/metrics`
- Metrics (JSON): `http://localhost:9090/metrics/json`

### Build Android

```bash
cd android
./gradlew assembleDebug
# Install: adb install app/build/outputs/apk/debug/app-debug.apk
```

### Build iOS

```bash
cd ios
open Runner.xcworkspace
# Build with Xcode (Cmd+B)
```

## 🛠️ Development

### Prerequisites
- **Rust**: 1.70+ (https://rustup.rs)
- **Android Studio**: Arctic Fox+ (for Android)
- **Xcode**: 14+ (for iOS)
- **Java**: 17+ (for Android Gradle)

### Core Library Development

```bash
# Run all tests
cd ya_ok_core
cargo test

# Run specific test module
cargo test storage::tests
cargo test routing::queue

# Check code quality
cargo clippy --all-targets
cargo fmt --check

# Build release
cargo build --release --target x86_64-unknown-linux-gnu
```

### Android Development

```bash
# Debug build
cd android
./gradlew assembleDebug

# Release build (requires keystore)
./gradlew assembleRelease

# Run tests
./gradlew test

# Install on device
adb install app/build/outputs/apk/debug/app-debug.apk
```

## 📊 Testing

See [QA Matrix](docs/QA_MATRIX.md) for comprehensive test coverage (45 test cases).

### Test Summary
- ✅ **Unit Tests**: 13 tests in ya_ok_core (storage, ACK, chunking, queue)
- ✅ **Integration Tests**: DTN routing, multi-hop delivery
- 🚧 **UI Tests**: Pending (Appium for Android/iOS)

### Run Tests

```bash
# Core tests
cd ya_ok_core
cargo test

# Android instrumented tests
cd android
./gradlew connectedAndroidTest

# Relay tests
cd relay
cargo test
```

## 🔒 Security

### Threat Model
- **Adversary**: Passive eavesdropper, active MITM
- **Assumptions**: Trusted peer key exchange (QR codes, NFC)
- **Guarantees**: Message confidentiality, authenticity, integrity

### Cryptography Stack
- **Signatures**: Ed25519 (libsodium-compatible)
- **Key Exchange**: X25519 ECDH
- **Encryption**: AES-GCM-256 (AEAD)
- **Random**: OsRng (getrandom crate)

### Security Considerations
- ⚠️ **Peer Trust**: Manual key verification required (QR/NFC)
- ⚠️ **Replay Attacks**: Mitigated by message IDs and timestamps
- ⚠️ **DoS**: Rate limiting (200 PPS), peer limits (10k)

## 🌐 Deployment

### Relay Server (Fly.io)

**Production**: https://i-am-ok-relay.fly.dev (port 40100)  
**Admin Panel**: https://i-am-ok-relay.fly.dev:9090

```bash
cd relay
fly deploy

# Environment variables
fly secrets set RELAY_PORT=40100
fly secrets set METRICS_PORT=9090
fly secrets set RATE_LIMIT_PPS=200
fly secrets set PEER_TTL_SECS=300
```

**Manage**: https://fly.io/apps/i-am-ok-relay

### Android (Google Play)

1. Generate signed APK: `./gradlew assembleRelease`
2. Upload to [Google Play Console](https://play.google.com/console)
3. Privacy Policy: `https://yourusername.github.io/yaok-legal/privacy.html`

### iOS (App Store)

1. Archive in Xcode: Product → Archive
2. Upload to [App Store Connect](https://appstoreconnect.apple.com/)
3. TestFlight beta testing available

## 📚 Documentation

- [Definition of Done & Scenarios](docs/DEFINITION_OF_DONE_AND_SCENARIOS.md)
- [ACK Implementation](docs/ACK_IMPLEMENTATION.md)
- [QA Test Matrix](docs/QA_MATRIX.md) (45 test cases)
- [Relay Server Guide](docs/RELAY_SERVER_GUIDE.md)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

### Code Style
- **Rust**: `cargo fmt` + `cargo clippy`
- **Kotlin**: Android Studio formatter
- **Swift**: Xcode formatter

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🔗 Links

- **Website**: https://poruch.app
- **Privacy Policy**: https://yourusername.github.io/yaok-legal/privacy.html
- **Terms of Use**: https://yourusername.github.io/yaok-legal/terms.html
- **Support**: https://yourusername.github.io/yaok-legal/support.html

## 📧 Contact

- **Email**: poruch.app@gmail.com
- **GitHub**: https://github.com/lunesko

---

**Build Status**: ✅ All components building successfully
**Test Status**: ✅ 13/13 unit tests passing
**Release**: 🚧 Beta (v0.1.0)


## 📁 Структура

```
docs/
├── index.html          # Головна сторінка документації
├── privacy.html        # Політика конфіденційності
├── terms.html          # Умови використання
├── support.html        # Сторінка підтримки
├── RELAY_SERVER_GUIDE.md # Relay server guide
└── .nojekyll           # Файл для GitHub Pages
```

## 📚 Технічні гайды

- [Relay server guide](docs/RELAY_SERVER_GUIDE.md)

## 🌐 GitHub Pages

Документи налаштовані для публікації через GitHub Pages.

### Налаштування GitHub Pages:

1. Перейдіть у **Settings** репозиторію
2. У розділі **Pages** оберіть:
   - **Source**: Deploy from a branch
   - **Branch**: `main` (або `master`)
   - **Folder**: `/docs`
3. Збережіть зміни

### URL після публікації:

- Головна: `https://yourusername.github.io/yaok-legal/`
- Privacy: `https://yourusername.github.io/yaok-legal/privacy.html`
- Terms: `https://yourusername.github.io/yaok-legal/terms.html`
- Support: `https://yourusername.github.io/yaok-legal/support.html`

## 📝 Використання в додатку

### Flutter

```dart
import 'package:url_launcher/url_launcher.dart';

// Відкрити політику конфіденційності
TextButton(
  child: Text('Політика конфіденційності'),
  onPressed: () async {
    final url = Uri.parse('https://yourusername.github.io/yaok-legal/privacy.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
),

// Відкрити умови використання
TextButton(
  child: Text('Умови використання'),
  onPressed: () async {
    final url = Uri.parse('https://yourusername.github.io/yaok-legal/terms.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
),

// Відкрити сторінку підтримки
TextButton(
  child: Text('Підтримка'),
  onPressed: () async {
    final url = Uri.parse('https://yourusername.github.io/yaok-legal/support.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
),
```

### Додати залежність в `pubspec.yaml`:

```yaml
dependencies:
  url_launcher: ^6.2.0
```

## 🔗 Посилання для Google Play / App Store

Після публікації на GitHub Pages, використовуйте ці URL в формах:

- **Privacy Policy URL**: `https://yourusername.github.io/yaok-legal/privacy.html`
- **Terms of Use URL**: `https://yourusername.github.io/yaok-legal/terms.html`
- **Support URL**: `https://yourusername.github.io/yaok-legal/support.html`

## 📧 Контакти

- **Email**: poruch.app@gmail.com
- **GitHub**: https://github.com/lunesko
- **Google Play Console**: Poruch_WEB_Studio

## 📄 Ліцензія

© 2026 Poruch. Всі права захищені.

---

**Зроблено в Україні 🇺🇦**
