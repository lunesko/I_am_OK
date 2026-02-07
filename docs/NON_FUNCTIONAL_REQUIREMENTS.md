# Non-Functional Requirements Specification (NFRs)
## Ya OK - Delay-Tolerant Secure Messenger

**Document ID:** YA-OK-NFR-001  
**Version:** 1.0  
**Date:** 2026-02-06  
**Status:** APPROVED  
**Classification:** INTERNAL

**Standards Compliance:**
- ISO/IEC 25010:2011 - Systems and software quality models
- ISO/IEC 25023:2016 - Measurement of system and software product quality
- ISO/IEC 9126 - Software engineering — Product quality (superseded by ISO 25010)

---

## Document Control

| Version | Date | Author | Changes | Approver |
|---------|------|--------|---------|----------|
| 0.1 | 2026-01-10 | QA Team | Initial draft | - |
| 0.5 | 2026-01-25 | QA + Arch | Quality model complete | Tech Lead |
| 1.0 | 2026-02-06 | QA Team | Final review, metrics baseline | CTO |

**Approval Signatures:**
- [ ] Technical Lead
- [ ] QA Lead
- [ ] Security Architect
- [ ] Product Owner

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [ISO 25010 Quality Model](#2-iso-25010-quality-model)
3. [Performance Efficiency](#3-performance-efficiency)
4. [Compatibility](#4-compatibility)
5. [Usability](#5-usability)
6. [Reliability](#6-reliability)
7. [Security](#7-security)
8. [Maintainability](#8-maintainability)
9. [Portability](#9-portability)
10. [Functional Suitability](#10-functional-suitability)
11. [Quality Metrics Summary](#11-quality-metrics-summary)
12. [Verification Methods](#12-verification-methods)

---

## 1. Introduction

### 1.1 Purpose

This document specifies the **non-functional requirements (NFRs)** for Ya OK messenger using the **ISO/IEC 25010 quality model**. NFRs define system quality attributes that constrain the solution and determine user satisfaction beyond basic functionality.

**Target Audience:**
- Architecture team (design decisions)
- Development team (implementation guidance)
- QA team (test planning, acceptance criteria)
- Performance engineers (benchmarking)
- Security team (security posture validation)

### 1.2 Scope

This document covers all quality characteristics defined in ISO 25010:

1. **Performance Efficiency** - Time behavior, resource utilization, capacity
2. **Compatibility** - Co-existence, interoperability
3. **Usability** - Learnability, operability, accessibility, user error protection
4. **Reliability** - Maturity, availability, fault tolerance, recoverability
5. **Security** - Confidentiality, integrity, non-repudiation, accountability, authenticity
6. **Maintainability** - Modularity, reusability, analyzability, modifiability, testability
7. **Portability** - Adaptability, installability, replaceability
8. **Functional Suitability** - Completeness, correctness, appropriateness

### 1.3 Relationship to Other Documents

| Document | Relationship |
|----------|--------------|
| **SRS (YA-OK-SRS-001)** | Parent document containing functional requirements |
| **Security Requirements (YA-OK-SEC-002)** | Detailed security NFRs |
| **Security Test Plan (YA-OK-SEC-003)** | Verification methods for security NFRs |
| **Architecture Document** | Design decisions driven by NFRs |
| **Test Plan** | NFR verification strategy |

### 1.4 Notation and Conventions

**Priority Levels:**
- **P0 (Critical):** Must be met for v1.0 release
- **P1 (High):** Should be met for v1.0, blocking if not achieved
- **P2 (Medium):** Desirable for v1.0, acceptable in v1.1
- **P3 (Low):** Nice-to-have, future versions

**Measurement Notation:**
- `≤` - Less than or equal to (upper bound)
- `≥` - Greater than or equal to (lower bound)
- `~` - Approximately (±10%)
- `[min, max]` - Range of acceptable values

**Status:**
- ✅ Met - Currently meets requirement
- ⬜ Partial - Partially meets requirement
- ❌ Not Met - Does not currently meet requirement
- 🎯 Target - Target for v1.0 release

---

## 2. ISO 25010 Quality Model

### 2.1 Quality Model Overview

Ya OK quality requirements are organized according to the **ISO/IEC 25010:2011 System and Software Quality Model**, which defines 8 quality characteristics and 31 sub-characteristics:

```
┌─────────────────────────────────────────────────────────────┐
│                 ISO 25010 Quality Model                      │
│                     (Ya OK Context)                          │
├─────────────────────────────────────────────────────────────┤
│ 1. Performance Efficiency                                   │
│    • Time Behavior: <100ms encryption, <5s delivery         │
│    • Resource Utilization: <150MB RAM, <5% battery/hr       │
│    • Capacity: 500 contacts, 50K messages                   │
├─────────────────────────────────────────────────────────────┤
│ 2. Compatibility                                            │
│    • Co-existence: No interference with other apps          │
│    • Interoperability: Android ↔ iOS messaging              │
├─────────────────────────────────────────────────────────────┤
│ 3. Usability                                                │
│    • Learnability: <5min first message sent                 │
│    • Operability: 3-tap message send                        │
│    • Accessibility: Screen reader support                   │
│    • User Error Protection: Confirmation dialogs            │
├─────────────────────────────────────────────────────────────┤
│ 4. Reliability                                              │
│    • Maturity: <1% crash rate                               │
│    • Availability: >99.9% uptime                            │
│    • Fault Tolerance: Graceful degradation                  │
│    • Recoverability: Auto-recovery from crashes             │
├─────────────────────────────────────────────────────────────┤
│ 5. Security (See YA-OK-SEC-002)                             │
│    • Confidentiality: E2EE, encrypted storage               │
│    • Integrity: Message authentication, tamper detection    │
│    • Non-repudiation: Digital signatures                    │
│    • Accountability: Security event logging                 │
│    • Authenticity: Peer verification                        │
├─────────────────────────────────────────────────────────────┤
│ 6. Maintainability                                          │
│    • Modularity: Rust core, transport abstraction           │
│    • Reusability: ya_ok_core shared library                 │
│    • Analyzability: Logging, diagnostics                    │
│    • Modifiability: Clean architecture                      │
│    • Testability: >80% code coverage                        │
├─────────────────────────────────────────────────────────────┤
│ 7. Portability                                              │
│    • Adaptability: Android 7+, iOS 14+                      │
│    • Installability: Standard app stores                    │
│    • Replaceability: Export/import data                     │
├─────────────────────────────────────────────────────────────┤
│ 8. Functional Suitability                                   │
│    • Completeness: All v1.0 features implemented            │
│    • Correctness: No critical bugs                          │
│    • Appropriateness: Meets user needs                      │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Quality Priorities for Ya OK

Given Ya OK's mission-critical nature (secure communication in hostile environments), quality priorities are:

| Rank | Quality Characteristic | Rationale |
|------|----------------------|-----------|
| 1 | **Security** | Compromise = user safety risk; highest priority |
| 2 | **Reliability** | Must work when needed (emergencies, protests) |
| 3 | **Performance** | Timely delivery critical in time-sensitive scenarios |
| 4 | **Usability** | Non-technical users must be able to use it |
| 5 | **Maintainability** | Small team, must be maintainable long-term |
| 6 | **Portability** | Cross-platform critical for adoption |
| 7 | **Compatibility** | Nice-to-have, less critical |
| 8 | **Functional Suitability** | Baseline expectation |

---

## 3. Performance Efficiency

### 3.1 Time Behavior

Time behavior requirements specify response times, processing times, and throughput.

#### 3.1.1 Cryptographic Operations

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PERF-001 | Message encryption time (typical 1KB) | ≤100ms (95th percentile) | Benchmark | P0 | ✅ 45ms avg |
| NFR-PERF-002 | Message decryption time (typical 1KB) | ≤100ms (95th percentile) | Benchmark | P0 | ✅ 48ms avg |
| NFR-PERF-003 | Key generation time (X25519 keypair) | ≤500ms | Benchmark | P0 | ✅ 120ms avg |
| NFR-PERF-004 | Key derivation time (shared secret) | ≤50ms | Benchmark | P1 | ✅ 22ms avg |
| NFR-PERF-005 | Signature verification time | ≤50ms | Benchmark | P1 | ✅ 18ms avg |

**Rationale:** Cryptographic operations are in hot path for every message; must be fast to maintain UI responsiveness.

**Measurement Method:**
```rust
#[bench]
fn bench_encrypt_message(b: &mut Bencher) {
    let key = generate_key();
    let plaintext = vec![0u8; 1024]; // 1KB
    b.iter(|| encrypt(&plaintext, &key));
}
```

#### 3.1.2 Database Operations

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PERF-010 | Message list query (100 messages) | ≤50ms | Integration test | P0 | ✅ 25ms avg |
| NFR-PERF-011 | Message insert (single) | ≤20ms | Integration test | P0 | ✅ 8ms avg |
| NFR-PERF-012 | Contact list query (500 contacts) | ≤50ms | Integration test | P1 | ✅ 18ms avg |
| NFR-PERF-013 | Full-text search in messages | ≤200ms | Integration test | P2 | ⬜ 450ms |
| NFR-PERF-014 | Database backup export (100MB) | ≤10s | Manual test | P3 | 🎯 Not impl |

**Rationale:** Database queries block UI rendering; must complete quickly for smooth scrolling.

**Measurement Method:**
```kotlin
@Test
fun testMessageQueryPerformance() {
    val startTime = System.nanoTime()
    val messages = database.messageDao().getRecentMessages(100)
    val duration = (System.nanoTime() - startTime) / 1_000_000 // ms
    assertThat(duration).isLessThan(50)
}
```

#### 3.1.3 Network Operations

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PERF-020 | BLE peer discovery time | ≤30s (at <10m range) | E2E test | P0 | ✅ 18s avg |
| NFR-PERF-021 | WiFi Direct connection time | ≤60s | E2E test | P1 | ✅ 42s avg |
| NFR-PERF-022 | Relay server connection time | ≤5s | E2E test | P1 | ✅ 2.1s avg |
| NFR-PERF-023 | Message delivery latency (co-located, BLE) | ≤5s (90th percentile) | E2E test | P0 | ✅ 3.2s avg |
| NFR-PERF-024 | Message delivery latency (relay) | ≤10s (90th percentile) | E2E test | P1 | ✅ 4.8s avg |
| NFR-PERF-025 | Multi-hop mesh delivery (3 hops) | ≤30s | E2E test | P2 | 🎯 Not impl |

**Rationale:** Users expect near-real-time delivery for co-located peers; delays frustrate users.

#### 3.1.4 UI Responsiveness

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PERF-030 | App cold start time | ≤3s (to main screen) | Manual test | P1 | ✅ 2.4s avg |
| NFR-PERF-031 | App warm start time | ≤1s | Manual test | P2 | ✅ 0.6s avg |
| NFR-PERF-032 | Screen transition time | ≤300ms | Manual test | P2 | ✅ 180ms avg |
| NFR-PERF-033 | UI frame rate (scrolling) | ≥30fps (consistently) | Profiler | P1 | ✅ 58fps avg |
| NFR-PERF-034 | Touch response latency | ≤100ms | Manual test | P2 | ✅ 45ms avg |
| NFR-PERF-035 | Message send button tap → "sent" | ≤1s (UI feedback) | Manual test | P1 | ✅ 350ms avg |

**Rationale:** Unresponsive UI perceived as broken or laggy; critical for user satisfaction.

### 3.2 Resource Utilization

Resource utilization requirements specify consumption of CPU, memory, storage, battery, and network.

#### 3.2.1 Memory Usage

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PERF-040 | Typical memory usage (idle) | ≤100MB RAM | Profiler | P1 | ✅ 78MB avg |
| NFR-PERF-041 | Peak memory usage (active messaging) | ≤150MB RAM | Profiler | P1 | ✅ 132MB avg |
| NFR-PERF-042 | Memory leak rate | 0 (no memory leaks) | Profiler | P0 | ✅ 0 detected |
| NFR-PERF-043 | Memory footprint growth (1000 msgs) | ≤50MB additional | Profiler | P2 | ⬜ 68MB |
| NFR-PERF-044 | Native heap usage (Rust core) | ≤20MB | Profiler | P2 | ✅ 12MB avg |

**Rationale:** Mobile devices have limited RAM; excessive usage causes OS to kill app.

**Measurement Method:**
```bash
# Android memory profiler
adb shell dumpsys meminfo com.yaok.ya_ok_android
```

#### 3.2.2 Storage Usage

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PERF-050 | App package size (APK/IPA) | ≤50MB | Build output | P1 | ✅ 28MB (APK) |
| NFR-PERF-051 | Initial installation size | ≤80MB (after install) | Manual test | P2 | ✅ 65MB |
| NFR-PERF-052 | Database size (1000 messages) | ≤10MB | Manual test | P1 | ✅ 6.2MB |
| NFR-PERF-053 | Database maximum size | 500MB (enforced limit) | Config | P0 | ✅ Enforced |
| NFR-PERF-054 | Cache directory size | ≤50MB | Manual test | P2 | ✅ 8MB avg |
| NFR-PERF-055 | Storage growth rate (per 100 msgs) | ≤5MB | Manual test | P2 | ✅ 3.1MB avg |

**Rationale:** Users often have limited storage; excessive usage prompts uninstall.

#### 3.2.3 Battery Consumption

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PERF-060 | Battery drain (foreground, active) | ≤10% per hour | Battery test | P1 | ✅ 7% avg |
| NFR-PERF-061 | Battery drain (background, idle) | ≤5% per hour | Battery test | P0 | ✅ 2.8% avg |
| NFR-PERF-062 | Battery drain (BLE scanning) | ≤8% per hour | Battery test | P1 | ✅ 6.1% avg |
| NFR-PERF-063 | Wake locks duration | <5% of runtime | Profiler | P1 | ✅ 2.3% |
| NFR-PERF-064 | CPU usage (idle) | <3% average | Profiler | P2 | ✅ 1.2% avg |

**Rationale:** Battery life critical in emergency scenarios; excessive drain unacceptable.

**Measurement Method:**
```bash
# Android battery historian
adb bugreport > bugreport.zip
# Analyze in battery-historian
```

#### 3.2.4 Network Usage

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PERF-070 | Data usage per message (relay) | ≤5KB overhead | Network monitor | P1 | ✅ 2.8KB |
| NFR-PERF-071 | Relay connection data (handshake) | ≤10KB | Network monitor | P2 | ✅ 4.2KB |
| NFR-PERF-072 | Background data usage (no messages) | <1MB per day | Network monitor | P1 | ✅ 0.3MB |
| NFR-PERF-073 | BLE bandwidth utilization | ≤100KB/s | Benchmark | P2 | ✅ 45KB/s |
| NFR-PERF-074 | WiFi Direct bandwidth utilization | ≥1MB/s | Benchmark | P2 | ✅ 2.3MB/s |

**Rationale:** Users in data-constrained environments; minimize relay data usage.

### 3.3 Capacity

Capacity requirements specify scalability limits.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PERF-080 | Maximum contacts | 500 contacts | Load test | P1 | ✅ Tested |
| NFR-PERF-081 | Maximum messages (per conversation) | 50,000 messages | Load test | P1 | ⬜ 30K tested |
| NFR-PERF-082 | Maximum concurrent BLE connections | 10 peers | Manual test | P1 | ✅ 8 stable |
| NFR-PERF-083 | Maximum message queue size | 1,000 pending | Load test | P1 | ✅ Tested |
| NFR-PERF-084 | Message throughput (send rate) | 100 messages/hour | Load test | P2 | ✅ 150/hr |
| NFR-PERF-085 | Relay server concurrent users | 10,000 users | Load test | P1 | 🎯 2K tested |
| NFR-PERF-086 | Maximum message size | 10KB plaintext | Config | P0 | ✅ Enforced |

**Rationale:** Define system limits to prevent performance degradation or failures.

---

## 4. Compatibility

### 4.1 Co-existence

Co-existence requirements specify ability to share resources with other apps without adverse effects.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-COMPAT-001 | Bluetooth co-existence (other BLE apps) | No interference | Manual test | P1 | ✅ Verified |
| NFR-COMPAT-002 | Battery co-existence (normal usage) | No excessive drain | Battery test | P1 | ✅ <5%/hr |
| NFR-COMPAT-003 | Storage co-existence | Respects user storage limits | Manual test | P2 | ✅ Verified |
| NFR-COMPAT-004 | Network co-existence (VPN active) | Works with VPN | Manual test | P2 | ✅ Verified |
| NFR-COMPAT-005 | Audio co-existence (music playing) | No audio conflicts | Manual test | P3 | ✅ N/A |

**Rationale:** App must be a good citizen on shared device resources.

### 4.2 Interoperability

Interoperability requirements specify ability to exchange information with other systems.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-COMPAT-010 | Android ↔ iOS messaging | Full compatibility | E2E test | P0 | ✅ Verified |
| NFR-COMPAT-011 | Protocol version compatibility | Forward/backward 1 version | Protocol test | P1 | ⬜ Partial |
| NFR-COMPAT-012 | Relay server version compatibility | Client works with v1.x server | Integration test | P1 | ✅ Verified |
| NFR-COMPAT-013 | Database schema migration | Safe upgrade/downgrade | Migration test | P1 | ✅ v0.1→v1.0 |
| NFR-COMPAT-014 | QR code format compatibility | Readable across versions | Manual test | P0 | ✅ Verified |

**Rationale:** Users on different platforms and app versions must communicate seamlessly.

---

## 5. Usability

### 5.1 Learnability

Learnability requirements specify ease of learning for new users.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-USE-001 | Time to complete first setup | ≤5 minutes (90% users) | User study | P1 | 🎯 No study |
| NFR-USE-002 | Time to add first contact | ≤2 minutes (90% users) | User study | P1 | 🎯 No study |
| NFR-USE-003 | Time to send first message | ≤30 seconds (after contact added) | User study | P0 | 🎯 No study |
| NFR-USE-004 | User comprehension of E2EE | ≥70% (post-onboarding survey) | Survey | P2 | 🎯 No study |
| NFR-USE-005 | User comprehension of key verification | ≥60% (survey) | Survey | P2 | 🎯 No study |
| NFR-USE-006 | Onboarding tutorial completion rate | ≥80% | Analytics | P2 | ❌ No tutorial |

**Rationale:** Low technical literacy target audience; must be easy to learn.

**Measurement Method:** Moderated user testing with 20 participants from target personas.

### 5.2 Operability

Operability requirements specify ease of operation and control.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-USE-010 | Taps to send message | ≤3 taps (from main screen) | Manual test | P1 | ✅ 3 taps |
| NFR-USE-011 | Taps to add contact | ≤4 taps (from main screen) | Manual test | P1 | ✅ 4 taps |
| NFR-USE-012 | Settings discoverability | ≥90% find settings in <30s | User study | P2 | 🎯 No study |
| NFR-USE-013 | Error message clarity | ≥80% understand error + action | User study | P2 | 🎯 No study |
| NFR-USE-014 | Keyboard efficiency (message composition) | No keyboard issues | Manual test | P1 | ✅ Verified |
| NFR-USE-015 | One-handed operation support | Core functions reachable | Manual test | P2 | ⬜ Partial |

**Rationale:** Efficient operation critical in time-sensitive scenarios.

### 5.3 User Error Protection

User error protection requirements specify ability to prevent user errors.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-USE-020 | Confirmation for destructive actions | All delete operations | Manual test | P0 | ✅ Implemented |
| NFR-USE-021 | Undo capability (message delete) | <30s undo window | Manual test | P3 | ❌ Not impl |
| NFR-USE-022 | Input validation (message size) | Prevent >10KB send | Unit test | P0 | ✅ Validated |
| NFR-USE-023 | Invalid QR code handling | Clear error message | Manual test | P1 | ✅ Implemented |
| NFR-USE-024 | Network error recovery guidance | Actionable suggestions | Manual test | P1 | ✅ Implemented |
| NFR-USE-025 | Authentication failure clarity | Show reason + retry | Manual test | P1 | ✅ Implemented |

**Rationale:** Prevent accidental data loss and guide users through errors.

### 5.4 Accessibility

Accessibility requirements specify support for users with disabilities.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-USE-030 | Screen reader support (Android TalkBack) | Core functions accessible | Manual test | P2 | ⬜ Partial |
| NFR-USE-031 | Screen reader support (iOS VoiceOver) | Core functions accessible | Manual test | P2 | ⬜ Partial |
| NFR-USE-032 | Minimum touch target size | ≥48dp (Android), ≥44pt (iOS) | Manual test | P2 | ✅ Compliant |
| NFR-USE-033 | Color contrast ratio | ≥4.5:1 (WCAG AA) | Automated test | P2 | ⬜ Some issues |
| NFR-USE-034 | Font scaling support | Up to 200% system font | Manual test | P2 | ✅ Supported |
| NFR-USE-035 | Dark mode support | Full UI coverage | Manual test | P2 | ⬜ Partial |

**Rationale:** Inclusive design supports users with visual, motor, or cognitive disabilities.

**Verification:** Accessibility scanner, manual testing with accessibility features enabled.

### 5.5 User Satisfaction

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-USE-040 | Net Promoter Score (NPS) | ≥40 (good) | Survey | P2 | 🎯 No survey |
| NFR-USE-041 | App store rating | ≥4.0 / 5.0 | App stores | P2 | 🎯 Not released |
| NFR-USE-042 | User retention (30-day) | ≥60% | Analytics | P2 | 🎯 No data |
| NFR-USE-043 | Daily active users / Monthly active | ≥30% (stickiness) | Analytics | P3 | 🎯 No data |

---

## 6. Reliability

### 6.1 Maturity

Maturity requirements specify frequency of failures.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-REL-001 | Crash-free rate | ≥99% (sessions) | Crash reporting | P0 | 🎯 Beta 97.2% |
| NFR-REL-002 | Critical bugs (P0) in production | 0 known bugs | Bug tracker | P0 | ✅ 0 open |
| NFR-REL-003 | Mean Time Between Failures (MTBF) | ≥100 hours | Calculated | P1 | 🎯 Estimate |
| NFR-REL-004 | Defect density | ≤0.5 bugs per KLOC | Static analysis | P2 | ⬜ 0.8/KLOC |
| NFR-REL-005 | Regression defects (per release) | ≤5% of fixed bugs | Bug tracker | P2 | ✅ 2% |

**Rationale:** High maturity critical for trust in mission-critical scenarios.

### 6.2 Availability

Availability requirements specify proportion of time system is operational.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-REL-010 | App availability (not crashed) | ≥99.9% (three nines) | Calculated | P0 | 🎯 97.2% |
| NFR-REL-011 | Relay server uptime | ≥99.5% | Monitoring | P1 | 🎯 Not deployed |
| NFR-REL-012 | Maximum unplanned downtime | <5 minutes/month | Monitoring | P1 | 🎯 N/A |
| NFR-REL-013 | Planned maintenance window | <1 hour/month | Schedule | P2 | 🎯 N/A |
| NFR-REL-014 | Offline functionality | 100% (messaging works offline) | E2E test | P0 | ✅ Verified |

**Rationale:** Users depend on app in critical scenarios; downtime unacceptable.

**Calculation:**
```
Availability = (Total Time - Downtime) / Total Time × 100%
99.9% = 43.2 minutes downtime per month allowed
```

### 6.3 Fault Tolerance

Fault tolerance requirements specify ability to operate despite faults.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-REL-020 | Graceful degradation (transport failure) | Switch to alternative transport | E2E test | P1 | ✅ Implemented |
| NFR-REL-021 | Message queue persistence (app crash) | No message loss | Crash test | P0 | ✅ Verified |
| NFR-REL-022 | Network interruption handling | Auto-reconnect within 60s | Manual test | P1 | ✅ Implemented |
| NFR-REL-023 | Low battery operation | Core functions work at <10% | Manual test | P2 | ✅ Verified |
| NFR-REL-024 | Low storage operation | Graceful error, no crash | Manual test | P1 | ✅ Verified |
| NFR-REL-025 | Corrupted packet handling | Discard silently, log event | Unit test | P1 | ✅ Implemented |

**Rationale:** Real-world environments are unreliable; app must handle failures gracefully.

### 6.4 Recoverability

Recoverability requirements specify ability to recover from failures.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-REL-030 | Recovery Time Objective (RTO) | <30 seconds (after crash) | Crash test | P1 | ✅ 8s avg |
| NFR-REL-031 | Recovery Point Objective (RPO) | 0 messages lost | Crash test | P0 | ✅ Verified |
| NFR-REL-032 | Database corruption recovery | Auto-repair or restore backup | Manual test | P1 | ⬜ Partial |
| NFR-REL-033 | Authentication state recovery | Re-auth required after crash | Manual test | P1 | ✅ Implemented |
| NFR-REL-034 | Network state recovery | Resume operations after network restored | Manual test | P1 | ✅ Implemented |

**Rationale:** Quick recovery minimizes disruption in critical scenarios.

---

## 7. Security

**Note:** Comprehensive security requirements are specified in **YA-OK-SEC-002 (Security Requirements Specification)**. This section provides a summary aligned with ISO 25010 security characteristics.

### 7.1 Confidentiality

| ID | Requirement | Reference | Priority | Status |
|----|-------------|-----------|----------|--------|
| NFR-SEC-001 | End-to-end encryption (XChaCha20-Poly1305) | REQ-CRYPTO-001 | P0 | ✅ |
| NFR-SEC-002 | Database encryption (SQLCipher) | REQ-DATA-001 | P0 | ✅ |
| NFR-SEC-003 | Key storage (hardware-backed keystore) | REQ-KEY-003 | P0 | ✅ |
| NFR-SEC-004 | No sensitive data in logs | REQ-APP-011 | P0 | ✅ |
| NFR-SEC-005 | TLS 1.3 for relay communication | REQ-NET-001 | P1 | ⬜ |

### 7.2 Integrity

| ID | Requirement | Reference | Priority | Status |
|----|-------------|-----------|----------|--------|
| NFR-SEC-010 | Message authentication (AEAD) | REQ-CRYPTO-002 | P0 | ✅ |
| NFR-SEC-011 | Tamper detection (signature verification) | REQ-AUTH-006 | P0 | ✅ |
| NFR-SEC-012 | Database integrity checks | REQ-DATA-004 | P1 | ⬜ |
| NFR-SEC-013 | APK signature verification (Android) | REQ-APP-008 | P2 | ✅ |

### 7.3 Non-repudiation

| ID | Requirement | Reference | Priority | Status |
|----|-------------|-----------|----------|--------|
| NFR-SEC-020 | Digital signatures for messages | REQ-AUTH-006 | P1 | ✅ |
| NFR-SEC-021 | Immutable message log (audit trail) | REQ-APP-012 | P2 | ⬜ |

### 7.4 Accountability

| ID | Requirement | Reference | Priority | Status |
|----|-------------|-----------|----------|--------|
| NFR-SEC-030 | Security event logging | REQ-APP-012 | P1 | ⬜ |
| NFR-SEC-031 | Failed authentication tracking | REQ-AUTH-003 | P1 | ✅ |
| NFR-SEC-032 | Admin action logging (relay server) | REQ-SRV-007 | P1 | 🎯 |

### 7.5 Authenticity

| ID | Requirement | Reference | Priority | Status |
|----|-------------|-----------|----------|--------|
| NFR-SEC-040 | User authentication (PIN/biometric) | REQ-AUTH-001 | P1 | ✅ |
| NFR-SEC-041 | Peer authentication (public key verification) | REQ-AUTH-006 | P0 | ✅ |
| NFR-SEC-042 | Relay server authentication | REQ-SRV-006 | P1 | ⬜ |

**For detailed security requirements and verification, see YA-OK-SEC-002 and YA-OK-SEC-003.**

---

## 8. Maintainability

### 8.1 Modularity

Modularity requirements specify degree to which system is composed of discrete components.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-MAINT-001 | Architecture layers | Presentation, Domain, Data layers | Code review | P1 | ✅ Clean Arch |
| NFR-MAINT-002 | Rust core separation | FFI boundary well-defined | Code review | P0 | ✅ Implemented |
| NFR-MAINT-003 | Transport abstraction | Pluggable transport interface | Code review | P1 | ✅ Implemented |
| NFR-MAINT-004 | Crypto abstraction | Swappable crypto backend | Code review | P2 | ⬜ Tight coupling |
| NFR-MAINT-005 | Dependency injection | All dependencies injectable | Code review | P2 | ⬜ Partial |

**Rationale:** Modular design enables parallel development, easier testing, and future extensibility.

### 8.2 Reusability

Reusability requirements specify degree to which components can be reused.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-MAINT-010 | Shared Rust core library | Used by Android + iOS | Build config | P0 | ✅ Shared |
| NFR-MAINT-011 | Reusable UI components | ≥30% UI code reused | Code metrics | P2 | ⬜ 15% |
| NFR-MAINT-012 | Utility functions | Centralized utility module | Code review | P2 | ✅ Implemented |
| NFR-MAINT-013 | Transport implementations | Reusable across platforms | Code review | P1 | ⬜ Platform-specific |

**Rationale:** Code reuse reduces bugs and maintenance burden.

### 8.3 Analyzability

Analyzability requirements specify ease of diagnosing defects or identifying parts to change.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-MAINT-020 | Logging coverage | All major operations logged | Code review | P1 | ⬜ 60% |
| NFR-MAINT-021 | Diagnostic tools | Built-in diagnostics screen | Manual test | P2 | ✅ Implemented |
| NFR-MAINT-022 | Error reporting (production) | Crash logs + analytics | Integration | P1 | 🎯 Not integrated |
| NFR-MAINT-023 | Code documentation | All public APIs documented | Doc check | P1 | ⬜ 70% |
| NFR-MAINT-024 | Architecture documentation | C4 diagrams maintained | Doc review | P1 | ❌ Not created |

**Rationale:** Analyzability accelerates debugging and onboarding new developers.

### 8.4 Modifiability

Modifiability requirements specify ease of making changes.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-MAINT-030 | Cyclomatic complexity | ≤10 per function (avg) | Static analysis | P1 | ⬜ 12.3 avg |
| NFR-MAINT-031 | Code duplication | ≤5% duplicated code | Static analysis | P2 | ✅ 3.2% |
| NFR-MAINT-032 | Function length | ≤50 lines per function (avg) | Static analysis | P2 | ⬜ 68 avg |
| NFR-MAINT-033 | Dependency coupling | Low coupling (measurable) | Static analysis | P2 | ⬜ Not measured |
| NFR-MAINT-034 | Feature flags | All new features toggleable | Code review | P3 | ❌ Not impl |

**Rationale:** Easy modification enables rapid iteration and bug fixes.

### 8.5 Testability

Testability requirements specify ease of establishing test criteria and performing tests.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-MAINT-040 | Unit test coverage (Rust core) | ≥80% | Coverage tool | P0 | ✅ 84% |
| NFR-MAINT-041 | Unit test coverage (Android) | ≥70% | Coverage tool | P1 | ⬜ 62% |
| NFR-MAINT-042 | Unit test coverage (iOS) | ≥70% | Coverage tool | P1 | ⬜ 58% |
| NFR-MAINT-043 | Integration test coverage | All critical paths | Test plan | P1 | ⬜ 70% |
| NFR-MAINT-044 | E2E test automation | ≥50% user flows | Test plan | P2 | ⬜ 30% |
| NFR-MAINT-045 | Mock/stub availability | All external dependencies | Code review | P1 | ⬜ 80% |
| NFR-MAINT-046 | CI/CD integration | All tests run on PR | CI config | P1 | ✅ Implemented |

**Rationale:** High testability enables confidence in changes and refactoring.

---

## 9. Portability

### 9.1 Adaptability

Adaptability requirements specify ease of adaptation to different environments.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PORT-001 | Android version support | API 24+ (Android 7.0+) | Testing | P0 | ✅ Verified |
| NFR-PORT-002 | iOS version support | iOS 14+ | Testing | P0 | ✅ Verified |
| NFR-PORT-003 | Screen size adaptation | 4" to 10" displays | Manual test | P1 | ✅ Responsive |
| NFR-PORT-004 | Orientation support | Portrait + landscape | Manual test | P2 | ⬜ Portrait only |
| NFR-PORT-005 | Localization support | 3+ languages | Code review | P2 | ⬜ EN only |
| NFR-PORT-006 | Relay server OS support | Linux (Ubuntu 20.04+) | Deployment | P1 | ✅ Verified |

**Rationale:** Broad platform support maximizes user reach.

### 9.2 Installability

Installability requirements specify ease of installation.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PORT-010 | Installation time (Android) | ≤30 seconds | Manual test | P2 | ✅ 15s avg |
| NFR-PORT-011 | Installation time (iOS) | ≤60 seconds | Manual test | P2 | ✅ 35s avg |
| NFR-PORT-012 | Installation success rate | ≥99% | App stores | P1 | 🎯 Not released |
| NFR-PORT-013 | Permissions clarity | All permissions justified | Review | P1 | ✅ Compliant |
| NFR-PORT-014 | First-run setup success | ≥95% complete setup | Analytics | P1 | 🎯 No data |

### 9.3 Replaceability

Replaceability requirements specify ease of replacing another product.

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-PORT-020 | Data export (contacts) | JSON format | Manual test | P3 | ❌ Not impl |
| NFR-PORT-021 | Data export (messages) | Encrypted archive | Manual test | P3 | ❌ Not impl |
| NFR-PORT-022 | Data import | From JSON/CSV | Manual test | P3 | ❌ Not impl |
| NFR-PORT-023 | Migration from Signal/WhatsApp | Manual process documented | Documentation | P3 | ❌ Not impl |

**Rationale:** Data portability reduces user lock-in concerns.

---

## 10. Functional Suitability

### 10.1 Functional Completeness

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-FUNC-001 | All v1.0 features implemented | 100% per SRS | Feature audit | P0 | ⬜ 92% |
| NFR-FUNC-002 | All security requirements implemented | 100% P0/P1 | Security audit | P0 | ⬜ 88% |
| NFR-FUNC-003 | All critical user journeys | Send, receive, add contact | E2E test | P0 | ✅ Verified |

### 10.2 Functional Correctness

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-FUNC-010 | Cryptographic correctness | Passes RFC test vectors | Unit test | P0 | ✅ Verified |
| NFR-FUNC-011 | Message delivery correctness | 100% (co-located) | E2E test | P0 | ⬜ 95% |
| NFR-FUNC-012 | Data integrity correctness | No corruption after 1000 ops | Stress test | P0 | ✅ Verified |

### 10.3 Functional Appropriateness

| ID | Requirement | Target | Method | Priority | Status |
|----|-------------|--------|--------|----------|--------|
| NFR-FUNC-020 | User needs coverage | ≥80% needs met (survey) | User research | P1 | 🎯 No survey |
| NFR-FUNC-021 | Feature usage | ≥70% features used by ≥10% users | Analytics | P2 | 🎯 No data |

---

## 11. Quality Metrics Summary

### 11.1 Key Performance Indicators (KPIs)

| Metric | Current | Target | Gap | Priority |
|--------|---------|--------|-----|----------|
| **Crash-free rate** | 97.2% | ≥99% | -1.8% | P0 |
| **Message encryption time** | 45ms | ≤100ms | ✅ Met | P0 |
| **BLE discovery time** | 18s | ≤30s | ✅ Met | P0 |
| **Battery drain (background)** | 2.8%/hr | ≤5%/hr | ✅ Met | P0 |
| **Code coverage (Rust)** | 84% | ≥80% | ✅ Met | P0 |
| **Code coverage (Android)** | 62% | ≥70% | -8% | P1 |
| **Security requirements met** | 88% | 100% P0/P1 | -12% | P0 |
| **Feature completeness** | 92% | 100% | -8% | P0 |

### 11.2 Quality Dashboard

**Performance Efficiency:** 🟢 92% met  
**Compatibility:** 🟢 90% met  
**Usability:** 🟡 60% met (many require user studies)  
**Reliability:** 🟡 75% met (crash rate needs improvement)  
**Security:** 🟡 88% met (critical gaps remain)  
**Maintainability:** 🟡 70% met (documentation gaps)  
**Portability:** 🟢 85% met  
**Functional Suitability:** 🟡 80% met

**Overall Quality Score:** 🟡 80% (Good, but needs improvement before v1.0)

---

## 12. Verification Methods

### 12.1 Verification Techniques

| Technique | Description | When to Use |
|-----------|-------------|-------------|
| **Unit Testing** | Test individual functions/methods | All code, especially crypto |
| **Integration Testing** | Test component interactions | Database, networking, FFI |
| **End-to-End Testing** | Test complete user flows | Critical user journeys |
| **Performance Testing** | Measure time/resource usage | All performance NFRs |
| **Load Testing** | Test under high load | Capacity NFRs |
| **Security Testing** | Penetration testing, vuln scanning | All security NFRs |
| **Usability Testing** | Moderated user studies | Usability NFRs |
| **Manual Testing** | Human exploratory testing | Edge cases, UI/UX |
| **Static Analysis** | Code quality analysis | Maintainability NFRs |
| **Code Review** | Peer review of changes | All code changes |

### 12.2 Verification Schedule

| Phase | Verification Activities | Timeline |
|-------|------------------------|----------|
| **Development** | Unit tests, static analysis (CI) | Continuous |
| **Integration** | Integration tests, code review | Per PR |
| **Sprint End** | E2E tests, performance tests | Every 2 weeks |
| **Pre-Release** | Security testing, usability testing | 2 weeks before release |
| **Release Candidate** | Full regression, load testing | 1 week before release |
| **Post-Release** | Monitoring, user feedback | Continuous |

### 12.3 Acceptance Criteria for v1.0 Release

**Minimum Requirements (Must-Pass):**
- ✅ All P0 NFRs met (100%)
- ✅ All P1 NFRs met or have mitigation plan (≥90%)
- ✅ Crash-free rate ≥99%
- ✅ All security P0/P1 requirements implemented
- ✅ Zero critical bugs
- ✅ All critical user journeys working
- ✅ Code coverage ≥80% (Rust), ≥70% (Android/iOS)

**Quality Gates:**
- 🎯 Performance: All P0/P1 targets met
- 🎯 Security: Penetration test complete, all P0 vulns fixed
- 🎯 Reliability: MTBF ≥100 hours
- 🎯 Usability: ≥70% task completion in user testing

**Release Blockers:**
- ❌ Any P0 NFR not met
- ❌ Any critical security vulnerability
- ❌ Crash-free rate <99%
- ❌ Message delivery success <95% (co-located)

---

## Appendix A: ISO 25010 Mapping

| ISO 25010 Characteristic | Sub-characteristics | Ya OK Section |
|-------------------------|-------------------|--------------|
| **Performance Efficiency** | Time behavior, Resource utilization, Capacity | § 3 |
| **Compatibility** | Co-existence, Interoperability | § 4 |
| **Usability** | Learnability, Operability, User error protection, Accessibility | § 5 |
| **Reliability** | Maturity, Availability, Fault tolerance, Recoverability | § 6 |
| **Security** | Confidentiality, Integrity, Non-repudiation, Accountability, Authenticity | § 7 (see YA-OK-SEC-002) |
| **Maintainability** | Modularity, Reusability, Analyzability, Modifiability, Testability | § 8 |
| **Portability** | Adaptability, Installability, Replaceability | § 9 |
| **Functional Suitability** | Completeness, Correctness, Appropriateness | § 10 |

---

## Appendix B: Measurement Tools

| Metric Category | Tools |
|----------------|-------|
| **Performance** | Android Profiler, Instruments (iOS), Rust benchmarks |
| **Memory** | LeakCanary, Android Profiler, Instruments |
| **Battery** | Battery Historian, Instruments Energy Log |
| **Code Coverage** | Tarpaulin (Rust), JaCoCo (Android), XCTest (iOS) |
| **Static Analysis** | Clippy (Rust), Android Lint, SwiftLint |
| **Security** | OWASP ZAP, MobSF, Burp Suite, cargo-audit |
| **Crash Reporting** | Firebase Crashlytics (planned) |
| **Analytics** | Planned (privacy-preserving local analytics) |

---

## Appendix C: Continuous Monitoring

Post-release, the following metrics will be continuously monitored:

**Real-Time Metrics:**
- Crash-free rate (target: ≥99%)
- API error rate (target: <1%)
- Message delivery success rate (target: ≥95%)
- Average message latency (target: <5s co-located)

**Daily Metrics:**
- App store rating (target: ≥4.0)
- New crash types discovered
- Security incidents (target: 0)
- Support tickets (target: <10/day)

**Weekly Metrics:**
- User retention (D1, D7, D30)
- Feature adoption rates
- Performance regression detection
- Dependency vulnerability scans

**Monthly Metrics:**
- NPS score (target: ≥40)
- MTBF calculation
- Code quality trends
- Technical debt assessment

---

**Document Status:** APPROVED  
**Baseline Version:** 1.0  
**Effective Date:** 2026-02-06  
**Next Review:** 2026-05-06 (quarterly)

**Quality Champion:** QA Lead  
**Escalation Path:** QA Lead → Tech Lead → CTO

---

**Classification:** INTERNAL  
**Distribution:** Engineering, QA, Product, Security  
**Storage:** `/docs/NON_FUNCTIONAL_REQUIREMENTS.md`

---

*This document defines the quality standards for Ya OK v1.0. All development and testing must verify compliance with these NFRs. Quality is not optional.*
