# Contributing to YA OK (Я ОК)

Thank you for your interest in contributing to **YA OK** — an emergency mesh messaging app!

We welcome contributions from the community to make this project better and more secure.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Submitting Changes](#submitting-changes)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Security Contributions](#security-contributions)
- [Documentation](#documentation)
- [Community](#community)

---

## 📜 Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow:

- **Be respectful:** Treat everyone with respect and kindness
- **Be constructive:** Provide helpful feedback and suggestions
- **Be patient:** Remember that everyone is learning
- **Be inclusive:** Welcome diverse perspectives and experiences
- **Be professional:** Avoid harassment, trolling, or inflammatory comments

**Violations:** Report to `conduct@poruch.app`

---

## 🚀 Getting Started

### Prerequisites

- **Rust:** 1.76 or later (`rustup install stable`)
- **Android:**
  - JDK 17+ (`java -version`)
  - Android SDK (API 35)
  - Gradle 8.7.3+
- **iOS:**
  - macOS with Xcode 15+
  - CocoaPods (`sudo gem install cocoapods`)
- **Flutter:** 3.19+ (if working on mobile UI)
- **Git:** Latest version

### Clone the Repository

```bash
git clone https://github.com/poruch/ya-ok.git
cd ya-ok
```

### Explore the Structure

```
ya-ok/
├── ya_ok_core/       # Rust core library (crypto, storage, networking)
├── relay/            # Rust UDP relay server
├── android/          # Android app (Kotlin + JNI)
├── ios/              # iOS app (Swift + FFI)
├── docs/             # Documentation
└── .github/          # CI/CD workflows
```

---

## 🛠️ Development Setup

### Rust Core Library

```bash
cd ya_ok_core
cargo build --release
cargo test --verbose
cargo clippy -- -D warnings
```

### Relay Server

```bash
cd relay
cargo build --release
cargo run  # Runs on 0.0.0.0:40100/udp
```

### Android App

```bash
cd android
./gradlew assembleDebug
./gradlew lint
```

**Install on device:**
```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

### iOS App

```bash
cd ios
pod install  # If using CocoaPods
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator
```

**Or open in Xcode:**
```bash
open ios/Runner.xcodeproj
```

---

## 🔨 Making Changes

### Branch Naming Convention

- **Feature:** `feature/issue-123-short-description`
- **Bugfix:** `fix/issue-456-bug-description`
- **Security:** `security/issue-789-vulnerability-fix`
- **Documentation:** `docs/improve-readme`

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Examples:**
```
feat(crypto): upgrade AES-GCM to XChaCha20-Poly1305

- Migrate from aes-gcm-siv to chacha20poly1305 crate
- Increase nonce size to 192 bits (no reuse risk)
- Update tests to verify new encryption

Closes #1
```

```
fix(relay): prevent memory leak in rate limiter

- Add MAX_PEERS=10K, MAX_RATE_ENTRIES=50K limits
- Implement cleanup_rate_entries() with CLEANUP_INTERVAL=1000
- Remove oldest 10% when limit reached

Fixes #19
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `security`: Security patch
- `docs`: Documentation only
- `style`: Formatting, no code change
- `refactor`: Code restructuring
- `test`: Adding/updating tests
- `chore`: Maintenance (dependencies, build)

---

## 📤 Submitting Changes

### Pull Request Process

1. **Create a branch:**
   ```bash
   git checkout -b feature/issue-123-my-feature
   ```

2. **Make your changes** and commit:
   ```bash
   git add .
   git commit -m "feat(core): add new feature"
   ```

3. **Push to GitHub:**
   ```bash
   git push origin feature/issue-123-my-feature
   ```

4. **Open a Pull Request:**
   - Go to https://github.com/poruch/ya-ok/pulls
   - Click "New Pull Request"
   - Select your branch
   - Fill out the template:
     ```markdown
     ## Description
     Brief description of changes

     ## Related Issue
     Closes #123

     ## Changes Made
     - [ ] Code changes
     - [ ] Tests added/updated
     - [ ] Documentation updated

     ## Testing
     - [ ] cargo test (Rust)
     - [ ] ./gradlew test (Android)
     - [ ] Xcode tests (iOS)
     - [ ] Manual testing completed

     ## Screenshots (if applicable)
     ```

5. **Wait for CI checks:**
   - Rust: cargo fmt, clippy, test, build, audit
   - Android: lint, assembleDebug
   - iOS: Xcode build
   - Security: Trivy scan

6. **Address review feedback:**
   - Make requested changes
   - Push new commits
   - Request re-review

7. **Merge:**
   - Maintainer will merge after approval
   - Branch will be automatically deleted

---

## 🎨 Coding Standards

### Rust

- **Formatting:** `cargo fmt --all`
- **Linting:** `cargo clippy --all-targets --all-features -- -D warnings`
- **Documentation:** Add doc comments for public APIs
  ```rust
  /// Encrypts a message using XChaCha20-Poly1305.
  ///
  /// # Arguments
  /// * `message` - Plain text message
  /// * `recipient_key` - Recipient's X25519 public key
  ///
  /// # Returns
  /// Encrypted message with 192-bit nonce
  pub fn encrypt_message(message: &str, recipient_key: &PublicKey) -> Result<Vec<u8>> {
      // ...
  }
  ```
- **Error handling:** Use `Result<T, E>` instead of `panic!()` in library code
- **No unwrap():** Replace with `?` operator or proper error handling
- **Avoid .clone():** Use `Arc<T>` for shared ownership when possible

### Kotlin (Android)

- **Style:** Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
- **Null safety:** Prefer `?.let` over `!!` (force unwraps)
- **Coroutines:** Use structured concurrency (viewModelScope, lifecycleScope)
- **Lint:** `./gradlew lint` must pass

### Swift (iOS)

- **Style:** Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **Optionals:** Use `if let`, `guard let` instead of force unwraps (`!`)
- **Memory:** Avoid retain cycles with `[weak self]` in closures
- **Lint:** SwiftLint rules must pass

### General

- **No hardcoded secrets:** Use environment variables or config files
- **No magic numbers:** Define constants with descriptive names
- **Keep functions small:** Aim for <50 lines per function
- **Test coverage:** Add tests for new features

---

## ✅ Testing Requirements

### Rust Tests

```bash
cd ya_ok_core
cargo test --release --verbose
```

**Required:**
- Unit tests for all public functions
- Integration tests for crypto operations
- Property-based tests for packet parsing (if using `proptest`)

### Android Tests

```bash
cd android
./gradlew test         # Unit tests
./gradlew connectedAndroidTest  # Instrumented tests
```

### iOS Tests

```bash
cd ios
xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Manual Testing Checklist

- [ ] Message encryption/decryption works
- [ ] Offline message queue persists after restart
- [ ] QR code pairing successful
- [ ] UDP relay connection established
- [ ] Rate limiting prevents spam
- [ ] UI responsive on low-end devices

---

## 🔒 Security Contributions

**IMPORTANT:** Do NOT submit security vulnerabilities via public GitHub issues or pull requests.

### Reporting Security Issues

1. **Email:** `security@poruch.app` (PGP key available)
2. **Include:**
   - Vulnerability description
   - Reproduction steps
   - Potential impact
   - Suggested fix (optional)

### Security Fix Process

1. Report received → acknowledged within 48h
2. Issue verified and assigned severity
3. Fix developed in private branch
4. Patch tested and reviewed
5. Coordinated disclosure (typically 30 days after fix deployed)
6. Public announcement with credit

See [SECURITY.md](./SECURITY.md) for full policy.

---

## 📚 Documentation

### What to Document

- **New features:** Usage examples, API reference
- **Breaking changes:** Migration guide
- **Configuration:** Environment variables, config files
- **Architecture:** Design decisions, trade-offs

### Where to Add Docs

- **Code comments:** For implementation details
- **README.md:** For project overview
- **docs/:** For detailed guides (RELAY_SECURITY.md, SECURE_KEY_STORAGE.md)
- **CHANGELOG.md:** For all notable changes

### Documentation Style

- Use **Markdown** for all docs
- Include code examples
- Add diagrams for complex flows (Mermaid or ASCII art)
- Link to related issues/PRs

---

## 💬 Community

### Communication Channels

- **GitHub Issues:** Bug reports, feature requests
- **GitHub Discussions:** Questions, ideas, general chat
- **Email:** support@poruch.app

### Getting Help

- **Read the docs:** Start with [README.md](./README.md)
- **Search issues:** Your question may already be answered
- **Ask in Discussions:** Community members can help
- **Contact maintainers:** For specific guidance

### Recognition

Contributors will be acknowledged in:
- **CHANGELOG.md:** For specific contributions
- **README.md:** Hall of Fame section (coming soon)
- **Security Hall of Fame:** For vulnerability reports

---

## 🎯 Good First Issues

Look for issues labeled `good first issue` or `help wanted`:

https://github.com/poruch/ya-ok/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22

**Suggested starting points:**
- Documentation improvements
- Test coverage for existing features
- Code cleanup (remove unused imports, dead code)
- UI polish (accessibility labels, animations)

---

## 📝 License

By contributing to YA OK, you agree that your contributions will be licensed under the [MIT License](./LICENSE).

---

**Thank you for contributing to YA OK!** 🚀

Your efforts help make emergency communication more secure and accessible for everyone.
