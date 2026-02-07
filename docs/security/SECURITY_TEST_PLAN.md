# Security Test Plan

**Document ID:** YA-OK-SEC-003  
**Version:** 1.0  
**Date:** 2026-02-06  
**Status:** DRAFT  
**Classification:** CONFIDENTIAL

**Project:** Ya OK - Delay-Tolerant Secure Messenger  
**Standards:** ISO/IEC 29119, OWASP MASTG, NIST SP 800-115

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-02-06 | QA Team | Initial draft |
| 1.0 | 2026-02-06 | Security + QA | Test plan complete |

**Approval:**
- [ ] QA Lead
- [ ] Security Architect
- [ ] Development Lead

---

## 1. Introduction

### 1.1 Purpose

This document defines security testing strategy, test cases, and acceptance criteria for Ya OK messenger. Testing scope covers:

- **Mobile Applications** (Android, iOS)
- **Core Crypto Library** (Rust)
- **Relay Server** (Infrastructure)
- **Network Security** (All transports)

### 1.2 Objectives

1. **Verify** implementation of security requirements (YA-OK-SEC-002)
2. **Validate** effectiveness of security controls
3. **Identify** vulnerabilities before production release
4. **Ensure** compliance with ISO 27001, OWASP MASVS L2
5. **Document** security posture for audit

### 1.3 Testing Levels

| Level | Scope | Responsibility | Timeline |
|-------|-------|---------------|----------|
| **L1: Unit** | Individual security functions | Developers | Continuous (CI) |
| **L2: Integration** | Component interactions | QA Team | Sprint end |
| **L3: System** | End-to-end security | Security Team | Pre-release |
| **L4: Acceptance** | Compliance verification | External auditors | Release |

### 1.4 Test Environment

**Test Devices:**
- Android: Pixel 6 (Android 13), Samsung Galaxy S21 (Android 12)
- iOS: iPhone 13 (iOS 16), iPhone 11 (iOS 15)
- Rooted: Pixel 3a (for tamper testing)

**Test Network:**
- Isolated test network
- Network simulator (NetEm for latency/packet loss)
- Wireshark capture station
- Burp Suite proxy

**Test Relay:**
- Dedicated test server (no production data)
- Instrumented for security logging

---

## 2. Test Strategy

### 2.1 Testing Approach

**Risk-Based Testing:** Focus on high-risk areas identified in Threat Model

**Priority Order:**
1. **P0 (Critical):** Cryptography, key management, authentication
2. **P1 (High):** Data protection, network security, input validation
3. **P2 (Medium):** Metadata protection, platform security
4. **P3 (Low):** Usability, edge cases

**Test Types:**
- White-box: Code review, static analysis
- Black-box: Penetration testing, fuzzing
- Gray-box: Instrumented testing

### 2.2 Testing Tools

| Tool | Purpose | License |
|------|---------|---------|
| **Burp Suite Pro** | Web/API pentesting | Commercial |
| **OWASP ZAP** | Security scanning | Open source |
| **MobSF** | Mobile app analysis | Open source |
| **Frida** | Dynamic instrumentation | Open source |
| **Objection** | Mobile pentesting | Open source |
| **Wireshark** | Network analysis | Open source |
| **AFL++** | Fuzzing | Open source |
| **Clippy** | Rust static analysis | Open source |
| **cargo-audit** | Dependency vulnerabilities | Open source |
| **Android Lint** | Android static analysis | Google |

### 2.3 Entry/Exit Criteria

**Entry Criteria:**
- [ ] Security requirements approved
- [ ] Threat model complete
- [ ] Unit tests passing
- [ ] Test environment configured
- [ ] Test data prepared

**Exit Criteria:**
- [ ] All P0/P1 test cases executed
- [ ] Zero critical vulnerabilities remaining
- [ ] High-severity issues documented with mitigation plan
- [ ] Test coverage ≥80% for security-critical code
- [ ] Security sign-off obtained

---

## 3. Cryptographic Testing

### 3.1 Encryption Algorithm Verification

**Test ID:** SEC-CRYPTO-001  
**Requirement:** REQ-CRYPTO-001, REQ-CRYPTO-002  
**Priority:** P0 (Critical)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-001 | Verify XChaCha20-Poly1305 implementation | RustCrypto library used correctly | ⬜ |
| TC-002 | Test encryption with known test vectors | Matches RFC test vectors | ⬜ |
| TC-003 | Verify key length (256-bit) | Keys are exactly 256 bits | ⬜ |
| TC-004 | Test with weak algorithms (negative test) | System rejects weak ciphers | ⬜ |
| TC-005 | Verify AEAD authentication | Tampering detected | ⬜ |

**Test Procedure:**

```rust
#[test]
fn test_xch acha20poly1305_encryption() {
    let key = XChaCha20Poly1305::generate_key(&mut OsRng);
    let nonce = XChaCha20Poly1305::generate_nonce(&mut OsRng);
    let plaintext = b"Test message";
    
    let ciphertext = encrypt(key, nonce, plaintext).unwrap();
    let decrypted = decrypt(key, nonce, &ciphertext).unwrap();
    
    assert_eq!(plaintext, &decrypted[..]);
    assert_ne!(plaintext, &ciphertext[..]); // Encrypted != plaintext
}

#[test]
fn test_authentication_tag() {
    let key = XChaCha20Poly1305::generate_key(&mut OsRng);
    let nonce = XChaCha20Poly1305::generate_nonce(&mut OsRng);
    let plaintext = b"Test message";
    
    let mut ciphertext = encrypt(key, nonce, plaintext).unwrap();
    ciphertext[0] ^= 1; // Tamper with one byte
    
    let result = decrypt(key, nonce, &ciphertext);
    assert!(result.is_err()); // Tampering detected
}
```

### 3.2 Key Exchange Testing

**Test ID:** SEC-CRYPTO-002  
**Requirement:** REQ-CRYPTO-004, REQ-CRYPTO-005  
**Priority:** P0 (Critical)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-010 | Verify X25519 key exchange | Shared secret derived correctly | ⬜ |
| TC-011 | Test with invalid public key | Error handling correct | ⬜ |
| TC-012 | Verify QR code key encoding | Public key correctly embedded | ⬜ |
| TC-013 | Test key verification flow | User can verify fingerprint | ⬜ |
| TC-014 | MITM attack simulation | Attack detected | ⬜ |

### 3.3 Nonce Management Testing

**Test ID:** SEC-CRYPTO-003  
**Requirement:** REQ-CRYPTO-009, REQ-CRYPTO-010  
**Priority:** P0 (Critical)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-020 | Verify nonce uniqueness | No collisions in 1M operations | ⬜ |
| TC-021 | Test nonce reuse detection | System panics/errors on reuse | ⬜ |
| TC-022 | Verify nonce length (192-bit) | Correct size for XChaCha20 | ⬜ |
| TC-023 | Test nonce randomness | Passes NIST entropy tests | ⬜ |

---

## 4. Key Management Testing

### 4.1 Key Storage Security

**Test ID:** SEC-KEY-001  
**Requirement:** REQ-KEY-003, REQ-KEY-004  
**Priority:** P0 (Critical)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-030 | Verify key encryption at rest | Keys stored encrypted (SQLCipher) | ⬜ |
| TC-031 | Test Android Keystore integration | Keys in hardware-backed storage | ⬜ |
| TC-032 | Test iOS Keychain integration | Keys with kSecAttrAccessibleWhenUnlockedThisDeviceOnly | ⬜ |
| TC-033 | Forensic extraction attempt | Keys not extractable without unlock | ⬜ |
| TC-034 | Backup inclusion test | Private keys excluded from backups | ⬜ |

**Test Procedure (Android Forensics):**

```bash
# Device must be unlocked (simulates screen-on attack)
adb root
adb shell "su -c 'cat /data/data/com.yaok.ya_ok_android/databases/ya_ok.db'"
# Verify database is encrypted (SQLCipher)

# Attempt backup extraction
adb backup -noapk com.yaok.ya_ok_android
# Verify private keys NOT in backup

# Attempt key extraction from Keystore
adb shell "su -c 'cat /data/misc/keystore/user_0/*'"
# Verify keys not directly readable
```

### 4.2 Key Lifecycle Testing

**Test ID:** SEC-KEY-002  
**Requirement:** REQ-KEY-006, REQ-KEY-007, REQ-KEY-010  
**Priority:** P1 (High)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-040 | Verify key generation randomness | Keys pass entropy tests | ⬜ |
| TC-041 | Test key never transmitted | Network capture shows no private key | ⬜ |
| TC-042 | Verify memory zeroization | Keys cleared from memory after use | ⬜ |
| TC-043 | Test key deletion | Keys securely wiped on delete | ⬜ |
| TC-044 | Key rotation test (future) | Rotation completes without errors | ⬜ |

---

## 5. Authentication & Access Control Testing

### 5.1 User Authentication

**Test ID:** SEC-AUTH-001  
**Requirement:** REQ-AUTH-001 through REQ-AUTH-005  
**Priority:** P1 (High)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-050 | Test PIN authentication | 6+ digit PIN required | ⬜ |
| TC-051 | Test biometric authentication | Fingerprint/Face ID works | ⬜ |
| TC-052 | Brute force protection | Locked after 5 failed attempts | ⬜ |
| TC-053 | Auto-lock timing | App locks after configured timeout | ⬜ |
| TC-054 | Bypass attempts | Cannot bypass auth via intent/deeplink | ⬜ |

### 5.2 Peer Authentication

**Test ID:** SEC-AUTH-002  
**Requirement:** REQ-AUTH-006, REQ-AUTH-007, REQ-AUTH-008  
**Priority:** P0 (Critical)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-060 | Verify peer signature validation | Invalid signatures rejected | ⬜ |
| TC-061 | Test spoofed peer ID | Spoofing detected and blocked | ⬜ |
| TC-062 | Key fingerprint display | Fingerprint shown for verification | ⬜ |
| TC-063 | Test with revoked peer | Revoked peer messages rejected | ⬜ |

---

## 6. Data Protection Testing

### 6.1 Data at Rest

**Test ID:** SEC-DATA-001  
**Requirement:** REQ-DATA-001 through REQ-DATA-004  
**Priority:** P0 (Critical)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-070 | Database encryption verification | SQLCipher enabled, encrypted | ⬜ |
| TC-071 | Plaintext search in database | No plaintext messages found | ⬜ |
| TC-072 | Backup encryption test | Backups are encrypted | ⬜ |
| TC-073 | File system scan | No sensitive data in /sdcard | ⬜ |
| TC-074 | Screenshot buffer test | Screenshots don't capture sensitive data | ⬜ |

**Test Procedure (Forensic Analysis):**

```bash
# Extract database
adb pull /data/data/com.yaok.ya_ok_android/databases/ya_ok.db

# Attempt to open without key
sqlite3 ya_ok.db
# Should fail with "file is encrypted or is not a database"

# Search for plaintext
strings ya_ok.db | grep -i "test message"
# Should find no plaintext messages
```

### 6.2 Data in Transit

**Test ID:** SEC-DATA-002  
**Requirement:** REQ-DATA-005, REQ-DATA-006, REQ-DATA-007  
**Priority:** P0 (Critical)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-080 | Wireshark capture analysis | No plaintext messages in traffic | ⬜ |
| TC-081 | Bluetooth sniffing test | BLE traffic encrypted at app layer | ⬜ |
| TC-082 | WiFi Direct sniffing | WiFi traffic encrypted at app layer | ⬜ |
| TC-083 | Relay TLS verification | TLS 1.3 used for relay connection | ⬜ |
| TC-084 | Certificate pinning test | Invalid cert rejected | ⬜ |

**Test Procedure (Traffic Analysis):**

```bash
# Capture Bluetooth traffic
sudo hcidump -X -i hci0

# Capture WiFi traffic
sudo tcpdump -i wlan0 -w capture.pcap

# Analyze in Wireshark
wireshark capture.pcap
# Filter: bluetooth || wlan
# Verify: No plaintext in payload

# Test TLS
openssl s_client -connect relay.yaok.app:443 -tls1_3
# Verify TLS 1.3 negotiated
```

---

## 7. Network Security Testing

### 7.1 Transport Layer Security

**Test ID:** SEC-NET-001  
**Requirement:** REQ-NET-001, REQ-NET-002, REQ-NET-003  
**Priority:** P1 (High)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-090 | TLS version test | TLS 1.3 enforced | ⬜ |
| TC-091 | Certificate pinning | Pin validation works | ⬜ |
| TC-092 | Self-signed cert test | Self-signed certs rejected | ⬜ |
| TC-093 | Expired cert test | Expired certs rejected | ⬜ |
| TC-094 | MITM proxy test | MITM attack detected | ⬜ |

**Test Procedure (Certificate Pinning):**

```bash
# Install Burp Suite CA on device
adb push burp-ca.crt /sdcard/
# Install via Settings > Security > Install from storage

# Configure Burp as proxy
adb shell settings put global http_proxy 192.168.1.100:8080

# Launch app, attempt relay connection
# Expected: Connection fails due to pin mismatch

# Check logs
adb logcat | grep -i "certificate\|ssl\|tls"
```

### 7.2 Replay Attack Protection

**Test ID:** SEC-NET-002  
**Requirement:** REQ-NET-006  
**Priority:** P0 (Critical)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-100 | Capture and replay packet | Replay rejected | ⬜ |
| TC-101 | Nonce deduplication test | Duplicate nonce rejected | ⬜ |
| TC-102 | Timestamp validation | Old packets rejected | ⬜ |
| TC-103 | Sequence number test | Out-of-order detection | ⬜ |

**Test Procedure:**

```python
# Capture packet with Scapy
from scapy.all import *

packets = sniff(count=100, filter="udp")
target_packet = packets[50]  # Select a message packet

# Replay packet after 10 seconds
time.sleep(10)
send(target_packet)

# Expected: Relay/client rejects duplicate
```

### 7.3 Denial of Service Resistance

**Test ID:** SEC-NET-003  
**Requirement:** REQ-NET-007, REQ-NET-008  
**Priority:** P1 (High)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-110 | Message flood attack | Rate limiting activates | ⬜ |
| TC-111 | Connection flood | Connection throttling works | ⬜ |
| TC-112 | Large message attack | Size limits enforced | ⬜ |
| TC-113 | Malformed packet attack | Graceful error handling | ⬜ |
| TC-114 | CPU exhaustion attack | CPU throttling activates | ⬜ |

**Test Procedure:**

```python
# Flood test script
import socket
import time

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
relay_addr = ("relay.yaok.app", 8080)

# Send 1000 messages/second
for i in range(10000):
    payload = b"X" * 1024  # 1KB packet
    sock.sendto(payload, relay_addr)
    if i % 1000 == 0:
        time.sleep(0.001)  # Brief pause

# Monitor app performance
# Expected: Rate limiting prevents resource exhaustion
```

---

## 8. Application Security Testing

### 8.1 Input Validation

**Test ID:** SEC-APP-001  
**Requirement:** REQ-APP-004, REQ-APP-005, REQ-APP-006  
**Priority:** P0 (Critical)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-120 | Oversized packet test | Rejected with error | ⬜ |
| TC-121 | Malformed packet test | Parsed safely, no crash | ⬜ |
| TC-122 | Special characters in messages | Sanitized correctly | ⬜ |
| TC-123 | SQL injection test (contact names) | No injection possible | ⬜ |
| TC-124 | Path traversal test | File access restricted | ⬜ |

**Test Procedure (Fuzzing):**

```bash
# AFL++ fuzzing setup
cargo install afl

# Build with AFL instrumentation
cargo afl build --release

# Create test corpus
mkdir in out
echo "valid_packet_data" > in/seed1

# Fuzz packet parser
cargo afl fuzz -i in -o out target/release/packet_parser

# Run for 24 hours, check for crashes
```

### 8.2 Platform Security

**Test ID:** SEC-APP-002  
**Requirement:** REQ-APP-007, REQ-APP-008, REQ-APP-009, REQ-APP-010  
**Priority:** P2 (Medium)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-130 | Root detection test | Warning shown on rooted device | ⬜ |
| TC-131 | Jailbreak detection (iOS) | Warning shown on jailbroken device | ⬜ |
| TC-132 | APK tampering test | Modified APK rejected | ⬜ |
| TC-133 | Debugger detection | Debugger attachment detected | ⬜ |
| TC-134 | Frida detection | Frida injection detected | ⬜ |

**Test Procedure:**

```bash
# Test on rooted device
adb shell su -c "id"
# Expected: App shows root warning

# Tamper with APK
apktool d app-release.apk
# Modify AndroidManifest.xml
apktool b app-release -o modified.apk
jarsigner -keystore test.keystore modified.apk
adb install modified.apk
# Expected: Signature verification fails OR app detects tampering

# Test with Frida
frida -U -f com.yaok.ya_ok_android -l hook.js
# Expected: App detects Frida and exits/warns
```

### 8.3 Logging Security

**Test ID:** SEC-APP-003  
**Requirement:** REQ-APP-011, REQ-APP-012  
**Priority:** P0 (Critical)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-140 | Log audit (debug build) | No sensitive data in logs | ⬜ |
| TC-141 | Log audit (release build) | Debug logs disabled | ⬜ |
| TC-142 | Crash log analysis | Crash logs sanitized | ⬜ |
| TC-143 | Logcat monitoring | No keys/messages in logcat | ⬜ |

**Test Procedure:**

```bash
# Clear logs
adb logcat -c

# Perform sensitive operations
# - Send message with "SECRET_MESSAGE"
# - Add contact with private key
# - Authenticate with PIN

# Capture logs
adb logcat -d > app_logs.txt

# Audit logs
grep -i "SECRET_MESSAGE\|private_key\|pin\|password" app_logs.txt
# Expected: No matches

# Check for sensitive patterns
grep -E "[0-9a-f]{64}|[A-Za-z0-9+/=]{44}" app_logs.txt
# Expected: No hex keys or base64 keys
```

---

## 9. Server Security Testing

### 9.1 Server Hardening

**Test ID:** SEC-SRV-001  
**Requirement:** REQ-SRV-001 through REQ-SRV-004  
**Priority:** P1 (High)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-150 | Service enumeration | Only UDP port + health check open | ⬜ |
| TC-151 | Privilege escalation test | Non-root user, minimal permissions | ⬜ |
| TC-152 | Vulnerability scan | No known CVEs | ⬜ |
| TC-153 | Patch level check | All security patches applied | ⬜ |
| TC-154 | Firewall rule test | Firewall configured correctly | ⬜ |

**Test Procedure:**

```bash
# Port scan
nmap -sV -p- relay.yaok.app
# Expected: Only 443 (TLS), 8080 (UDP), 80 (health) open

# Service identification
nmap -sC -sV relay.yaok.app
# Check versions for known vulnerabilities

# Vulnerability scan
nessus --scan relay.yaok.app
# OR
nikto -h https://relay.yaok.app
```

### 9.2 Server Access Control

**Test ID:** SEC-SRV-002  
**Requirement:** REQ-SRV-005, REQ-SRV-006, REQ-SRV-007  
**Priority:** P1 (High)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-160 | SSH password auth test | Password auth disabled | ⬜ |
| TC-161 | SSH key strength test | ED25519 or RSA 4096+ required | ⬜ |
| TC-162 | fail2ban test | Brute force blocked after 3 attempts | ⬜ |
| TC-163 | Admin action logging | All sudo commands logged | ⬜ |

### 9.3 Data Handling

**Test ID:** SEC-SRV-003  
**Requirement:** REQ-SRV-008, REQ-SRV-009, REQ-SRV-010  
**Priority:** P1 (High)

**Test Cases:**

| ID | Test Case | Expected Result | Status |
|----|-----------|-----------------|--------|
| TC-170 | Stored packet encryption | Packets encrypted at rest | ⬜ |
| TC-171 | Metadata logging audit | Minimal metadata in logs | ⬜ |
| TC-172 | Log rotation test | Logs rotated and archived | ⬜ |
| TC-173 | Abuse detection test | Anomalies detected | ⬜ |
| TC-174 | DDoS mitigation test | Rate limiting effective | ⬜ |

---

## 10. Penetration Testing

### 10.1 Mobile App Penetration Test

**Test ID:** SEC-PEN-001  
**Scope:** Android/iOS applications  
**Duration:** 5 days  
**Team:** External pentesting firm

**Test Scope:**

1. **Static Analysis**
   - Decompilation and code review
   - Hardcoded secrets search
   - Insecure API usage
   - Cryptographic misuse

2. **Dynamic Analysis**
   - Runtime tampering (Frida)
   - API interception (Burp)
   - File system inspection
   - Memory dump analysis

3. **Authentication**
   - Bypass attempts
   - Brute force resistance
   - Biometric bypass

4. **Data Storage**
   - Sensitive data exposure
   - Backup analysis
   - Forensic extraction

5. **Network Communication**
   - TLS implementation
   - Certificate validation
   - MITM attacks

6. **Platform Abuse**
   - Intent redirection (Android)
   - URL scheme hijacking (iOS)
   - WebView exploitation

**Deliverables:**
- [ ] Penetration test report
- [ ] Prioritized vulnerability list
- [ ] Proof-of-concept exploits
- [ ] Remediation recommendations

### 10.2 Server Penetration Test

**Test ID:** SEC-PEN-002  
**Scope:** Relay server infrastructure  
**Duration:** 3 days  
**Team:** External pentesting firm

**Test Scope:**

1. **Information Gathering**
   - DNS enumeration
   - Subdomain discovery
   - Service fingerprinting

2. **Vulnerability Assessment**
   - Known CVE exploitation
   - Configuration errors
   - Default credentials

3. **Exploitation**
   - Remote code execution attempts
   - Privilege escalation
   - Lateral movement

4. **DoS Testing**
   - Resource exhaustion
   - Application-layer attacks

5. **Data Extraction**
   - Stored packet access
   - Log file analysis
   - Database exposure

**Deliverables:**
- [ ] Server pentest report
- [ ] Network diagram
- [ ] Attack tree
- [ ] Hardening checklist

---

## 11. Compliance Testing

### 11.1 OWASP MASVS L2 Verification

**Test ID:** SEC-COMP-001  
**Standard:** OWASP Mobile Application Security Verification Standard v2.0 Level 2

**Verification Checklist:**

| MASVS ID | Requirement | Verification Method | Status |
|----------|-------------|-------------------|--------|
| **MSTG-STORAGE-1** | Sensitive data stored securely | Forensic analysis | ⬜ |
| **MSTG-STORAGE-2** | No sensitive data in logs | Log audit | ⬜ |
| **MSTG-STORAGE-3** | No sensitive data in IPC | IPC analysis | ⬜ |
| **MSTG-STORAGE-12** | User education on storage | Documentation review | ⬜ |
| **MSTG-CRYPTO-1** | Strong crypto algorithms | Code review | ⬜ |
| **MSTG-CRYPTO-2** | Crypto key management | Penetration testing | ⬜ |
| **MSTG-CRYPTO-5** | No insecure crypto | Static analysis | ⬜ |
| **MSTG-CRYPTO-6** | Secure RNG | Code review + testing | ⬜ |
| **MSTG-AUTH-1** | Authentication enforced | Functional testing | ⬜ |
| **MSTG-AUTH-2** | Remote authentication secure | Penetration testing | ⬜ |
| **MSTG-AUTH-8** | Biometric auth secure | Device testing | ⬜ |
| **MSTG-NETWORK-1** | TLS for all network | Traffic analysis | ⬜ |
| **MSTG-NETWORK-2** | TLS settings secure | Configuration review | ⬜ |
| **MSTG-NETWORK-3** | Certificate validation | Testing with invalid certs | ⬜ |
| **MSTG-PLATFORM-1** | IPC secure | Intent analysis (Android) | ⬜ |
| **MSTG-PLATFORM-2** | WebView secure (if used) | N/A | ⬜ |
| **MSTG-PLATFORM-3** | Sensitive UI protected | Screenshot testing | ⬜ |
| **MSTG-CODE-4** | Debugging disabled (release) | APK analysis | ⬜ |
| **MSTG-RESILIENCE-1** | Root detection | Rooted device testing | ⬜ |
| **MSTG-RESILIENCE-2** | Tamper detection | Modified APK testing | ⬜ |

### 11.2 ISO 27001 Controls Testing

**Test ID:** SEC-COMP-002  
**Standard:** ISO/IEC 27001:2013

**Control Verification:**

| Control | Description | Verification Method | Status |
|---------|-------------|-------------------|--------|
| **A.9.4.1** | Information access restriction | Access control testing | ⬜ |
| **A.10.1.1** | Cryptographic controls | Crypto testing | ⬜ |
| **A.10.1.2** | Key management | Key lifecycle testing | ⬜ |
| **A.12.3.1** | Information backup | Backup security testing | ⬜ |
| **A.12.6.1** | Vulnerability management | Vuln scanning | ⬜ |
| **A.14.2.1** | Secure development policy | Documentation review | ⬜ |
| **A.14.2.5** | Secure system engineering | Architecture review | ⬜ |
| **A.14.2.8** | System security testing | This test plan execution | ⬜ |

---

## 12. Test Execution Schedule

### Week 1-2: Automated Testing

| Day | Activity | Responsibility |
|-----|----------|---------------|
| Mon-Tue | Unit test execution (L1) | Developers |
| Wed | Integration testing (L2) | QA Team |
| Thu | Static analysis (Clippy, Lint) | DevOps |
| Fri | Dependency vulnerability scan | Security Team |

### Week 3-4: Manual & Penetration Testing

| Day | Activity | Responsibility |
|-----|----------|---------------|
| Mon-Wed | Mobile app penetration test | External firm |
| Thu | Server penetration test | External firm |
| Fri | Pentest report review | Security Team |

### Week 5: Remediation & Retesting

| Day | Activity | Responsibility |
|-----|----------|---------------|
| Mon-Wed | Fix critical/high vulnerabilities | Developers |
| Thu | Regression testing | QA Team |
| Fri | Final security sign-off | Security Architect |

---

## 13. Defect Management

### 13.1 Severity Classification

| Severity | Definition | Response Time | Examples |
|----------|------------|---------------|----------|
| **P0 - Critical** | Breaks security guarantee | Immediate fix | Plaintext messages, key exposure |
| **P1 - High** | Significant security risk | 1 week | Missing encryption, weak auth |
| **P2 - Medium** | Moderate security risk | 1 month | Metadata leakage, missing logging |
| **P3 - Low** | Minor security concern | Next release | Hardening improvements |

### 13.2 Acceptance Criteria

**P0 Vulnerabilities:** ZERO before release  
**P1 Vulnerabilities:** ZERO or documented mitigation plan  
**P2 Vulnerabilities:** ≤5 with documented workarounds  
**P3 Vulnerabilities:** No limit, tracked in backlog

### 13.3 Retesting Policy

All fixed vulnerabilities must be:
1. Code-reviewed by security team
2. Retested by original tester
3. Regression tested in CI/CD
4. Documented in release notes (if customer-facing)

---

## 14. Test Deliverables

### 14.1 Test Reports

- [ ] **Unit Test Report** - Coverage, pass/fail, performance
- [ ] **Integration Test Report** - Component interactions, API testing
- [ ] **Security Test Report** - All test cases, results, evidence
- [ ] **Penetration Test Report** - External assessment, vulnerabilities
- [ ] **Compliance Report** - MASVS, ISO 27001 verification
- [ ] **Executive Summary** - High-level overview for stakeholders

### 14.2 Artifacts

- [ ] Test cases with results
- [ ] Network captures (Wireshark)
- [ ] Screenshots/videos of tests
- [ ] Exploit proof-of-concepts (for fixes)
- [ ] Forensic analysis reports
- [ ] Fuzzing campaign results
- [ ] Code coverage reports

### 14.3 Sign-off

**Security Sign-off Checklist:**

- [ ] All P0 test cases executed
- [ ] All P1 test cases executed
- [ ] Zero critical vulnerabilities
- [ ] High vulnerabilities mitigated
- [ ] Penetration test complete
- [ ] Compliance verification done
- [ ] Test reports reviewed
- [ ] Remediation plan for remaining issues

**Signatures:**

- [ ] QA Lead: __________________ Date: __________
- [ ] Security Architect: __________________ Date: __________
- [ ] Development Lead: __________________ Date: __________
- [ ] Product Owner: __________________ Date: __________

---

## 15. Continuous Security Testing

### 15.1 CI/CD Integration

**Automated Security Gates:**

```yaml
# .github/workflows/security.yml
name: Security Testing

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Rust security audit
        run: cargo audit
      
      - name: Clippy linting
        run: cargo clippy -- -D warnings
      
      - name: Android Lint
        run: cd android && ./gradlew lint
      
      - name: Dependency check
        run: ./scripts/dependency-check.sh
      
      - name: SAST (Static Analysis)
        run: semgrep --config=auto .
      
      - name: Secret scanning
        uses: trufflesecurity/trufflehog@main
```

### 15.2 Monthly Security Tasks

- [ ] Dependency vulnerability scan (cargo-audit, OWASP)
- [ ] Server vulnerability scan (Nessus)
- [ ] Log audit (check for sensitive data)
- [ ] Certificate expiration check
- [ ] Threat model review

### 15.3 Quarterly Security Review

- [ ] Full penetration test
- [ ] Compliance verification (MASVS, ISO 27001)
- [ ] Security requirements review
- [ ] Incident response drill
- [ ] Security training update

---

## Appendix A: Test Data

### A.1 Test Messages

```
MSG_PLAIN_001: "Hello, World!"
MSG_PLAIN_002: "Test message with émojis 🔒🔐"
MSG_LONG_001: "A" * 10000  # 10KB message
MSG_OVERSIZED_001: "X" * 200000  # 200KB (should fail)
MSG_SPECIAL_001: "<script>alert('XSS')</script>"  # XSS attempt
MSG_SQL_001: "'; DROP TABLE messages; --"  # SQL injection
```

### A.2 Test Keys

```
# DO NOT use in production!
TEST_PRIVATE_KEY_1: "70076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"
TEST_PUBLIC_KEY_1: "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a"

TEST_PRIVATE_KEY_2: "a0c42a9c406a5af9848f4b8c7b9d03f7ce4fe8dc4f7a42f0e25e4e8ab7e6a123"
TEST_PUBLIC_KEY_2: "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"
```

### A.3 Test Peers

```json
{
  "test_peer_1": {
    "id": "test-peer-001",
    "name": "Alice Test",
    "public_key": "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a"
  },
  "test_peer_2": {
    "id": "test-peer-002",
    "name": "Bob Test",
    "public_key": "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"
  }
}
```

---

## Appendix B: Testing Tools Setup

### B.1 Burp Suite Configuration

```
Proxy:
  Listen on: 127.0.0.1:8080
  Intercept: ON
  TLS Pass Through: *.yaok.app (if pinning enabled)

Intruder:
  Threads: 10
  Timeout: 30s

Scanner (Pro):
  Scan speed: Normal
  Scan accuracy: Maximum
```

### B.2 Frida Script Example

```javascript
// hook_crypto.js
Java.perform(function() {
    var CoreGateway = Java.use("app.poruch.ya_ok.core.CoreGateway");
    
    CoreGateway.sendTextTo.implementation = function(text, recipientId) {
        console.log("[*] sendTextTo called:");
        console.log("    Text: " + text);
        console.log("    Recipient: " + recipientId);
        return this.sendTextTo(text, recipientId);
    };
    
    console.log("[*] Crypto hooks installed");
});
```

### B.3 Wireshark Display Filters

```
# Bluetooth LE
bluetooth.addr == XX:XX:XX:XX:XX:XX

# UDP Relay traffic
udp.port == 8080

# TLS handshake
ssl.handshake.type

# Identify plaintext
frame contains "password" || frame contains "secret"
```

---

**Document Classification:** CONFIDENTIAL  
**Review Cycle:** Quarterly  
**Next Review:** 2026-05-06  
**Owner:** QA + Security Team

---

**Test Plan Status:** READY FOR EXECUTION  
**Estimated Effort:** 120 hours (3 weeks, 2-person team)  
**Target Completion:** 2026-03-06
