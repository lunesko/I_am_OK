# Security Policy

## 🔒 Reporting Security Vulnerabilities

**YA OK** (Я ОК) is an emergency mesh messaging app. Security is our top priority.

### **DO NOT** disclose security issues publicly

If you discover a security vulnerability, please report it privately.

### Reporting Process

1. **Email:** Send details to `security@poruch.app` (encrypted preferred)
2. **Subject:** `[SECURITY] YA OK - <brief description>`
3. **Include:**
   - Vulnerability description
   - Steps to reproduce
   - Potential impact assessment
   - Suggested remediation (if any)

### PGP Key (Optional)
```
-----BEGIN PGP PUBLIC KEY BLOCK-----
[To be added when production email is configured]
-----END PGP PUBLIC KEY BLOCK-----
```

### Response Timeline

- **Initial Response:** Within 48 hours
- **Assessment:** 3-5 business days
- **Fix Timeline:** Based on severity
  - **Critical:** 1-3 days
  - **High:** 1-2 weeks
  - **Medium:** 2-4 weeks
  - **Low:** Next release

### Disclosure Policy

We follow **Coordinated Vulnerability Disclosure**:
- You report privately → We acknowledge → We fix → We coordinate public disclosure
- Public disclosure only after:
  1. Fix is deployed
  2. Users have time to update (typically 30 days)
  3. Coordinated announcement

### Severity Levels

#### 🔴 Critical
- Remote code execution
- Authentication bypass
- Encryption key compromise
- Data breach affecting multiple users

#### 🟠 High
- Privilege escalation
- SQL injection
- Memory corruption
- Man-in-the-middle attacks

#### 🟡 Medium
- Denial of Service (DoS)
- Information disclosure
- Cross-site scripting (XSS) if applicable
- Rate limit bypass

#### 🟢 Low
- Configuration issues
- Non-sensitive information leaks
- Minor logic bugs

## 🛡️ Security Features

### Current Protections
- ✅ **End-to-End Encryption:** XChaCha20-Poly1305 (upgraded from AES-GCM)
- ✅ **Digital Signatures:** Ed25519 (64-byte signatures)
- ✅ **Key Exchange:** X25519 ECDH
- ✅ **Relay IP Pinning:** 213.188.195.83 (production)
- ✅ **Rate Limiting:** 100 packets/sec per peer
- ✅ **Signature Verification:** At `Packet::decrypt()` (line 135)
- ✅ **Memory Protection:** `zeroize` crate for sensitive data
- ✅ **WAL Mode:** SQLite Write-Ahead Logging (crash recovery)
- ✅ **Input Validation:** Rejects control chars, zero-width chars

### Architecture Security
- **No Central Server:** Peer-to-peer mesh with UDP relay
- **Offline Operation:** Messages stored locally with TTL
- **Key Storage:** iOS Keychain, Android Keystore (hardware-backed)
- **Size Limits:** 128KB max packet, 64KB max payload

### Known Limitations
- UDP relay is **not authenticated** (network-level only)
- Certificate pinning **not implemented** for UDP (IP pinning used instead)
- iOS MVC/MVVM architecture needs refactoring (Issue #24)
- Rust `.clone()` proliferation may impact performance (Issue #25)

## 📋 Security Audit

**Last Full Audit:** 2026-02-01  
**Issues Found:** 156 total  
**Fixed:** 29 issues (18.6%)  
- Phase 1 (Critical): 11/11 ✅
- Phase 2 (High Priority): 12/43 ✅
- Medium Priority: 6/54 ✅

**Audit Report:** [FULL_AUDIT_REPORT.md](./FULL_AUDIT_REPORT.md)  
**Progress Tracking:** [FIXES_PROGRESS.md](./FIXES_PROGRESS.md)

## 🔐 Security Best Practices

### For Users
1. **Verify Contacts:** Always verify QR codes in person
2. **Secure Device:** Use device lock (PIN/biometric)
3. **Update Regularly:** Install security patches promptly
4. **Network Security:** Use trusted WiFi when possible

### For Developers
1. **Never commit secrets:** Check `.gitignore` before commits
2. **Review crypto code:** Changes to `ya_ok_core/src/core/crypto.rs` require peer review
3. **Validate all inputs:** Check `message.rs`, `packet.rs` for validation patterns
4. **Run security checks:** `cargo audit` before every release

## 📞 Contact

- **Security Issues:** security@poruch.app
- **General Contact:** support@poruch.app
- **GitHub Issues:** https://github.com/poruch/ya-ok/issues (for non-security bugs)

## 🏆 Hall of Fame

We acknowledge security researchers who help improve YA OK:

| Researcher | Vulnerability | Date | Bounty |
|-----------|--------------|------|--------|
| *Your name here* | *Description* | *Date* | *$Amount* |

*Bounty program to be announced after 1.0 release*

---

**Thank you for helping keep YA OK secure!** 🔒
