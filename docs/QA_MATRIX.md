# QA Test Matrix - Ya OK

## Test Coverage Overview

| Category | Android | iOS | Relay | Priority |
|----------|---------|-----|-------|----------|
| **Connectivity** | ✓ | ✓ | ✓ | P0 |
| **Message Delivery** | ✓ | ✓ | ✓ | P0 |
| **DTN Routing** | ✓ | ✓ | ✓ | P0 |
| **ACK/Delivered** | ✓ | ✓ | ✓ | P0 |
| **Security** | ✓ | ✓ | ✓ | P0 |
| **Performance** | ✓ | ✓ | ✓ | P1 |
| **Edge Cases** | ✓ | ✓ | ✓ | P1 |
| **UI/UX** | ✓ | ✓ | N/A | P1 |

## P0 Tests (Blocking Release)

### 1. Connectivity Tests

#### TC-CON-001: BLE Discovery
- **Platform**: Android, iOS
- **Prerequisite**: 2 devices with BLE enabled, app installed
- **Steps**:
  1. Launch app on Device A
  2. Launch app on Device B within 10m
  3. Wait 30 seconds
- **Expected**: Devices discover each other, appear in peer list
- **Priority**: P0

#### TC-CON-002: WiFi Direct Connection
- **Platform**: Android
- **Prerequisite**: 2 Android devices, WiFi enabled
- **Steps**:
  1. Enable WiFi Direct in settings
  2. Trigger connection from Device A to Device B
  3. Accept connection on Device B
- **Expected**: Connection established, data flow confirmed
- **Priority**: P0

#### TC-CON-003: Relay Connection
- **Platform**: Android, iOS, Relay
- **Prerequisite**: Relay server running, devices have internet
- **Steps**:
  1. Configure relay address in app settings
  2. Send message from Device A
  3. Verify relay forwards to Device B
- **Expected**: Message delivered via relay within 5 seconds
- **Priority**: P0

#### TC-CON-004: Relay Health Check
- **Platform**: Relay
- **Steps**:
  1. Start relay server
  2. `curl http://localhost:9090/health`
- **Expected**: `{"status":"healthy","uptime_secs":X,"version":"0.1.0"}`
- **Priority**: P0

### 2. Message Delivery Tests

#### TC-MSG-001: Direct Status Message
- **Platform**: Android, iOS
- **Prerequisite**: 2 devices connected via BLE
- **Steps**:
  1. Send "Я ОК" status from Device A
  2. Verify receipt on Device B within 2 seconds
- **Expected**: Status appears in Device B inbox, ACK received
- **Priority**: P0

#### TC-MSG-002: Text Message (256 bytes)
- **Platform**: Android, iOS
- **Steps**:
  1. Compose 256-character text message on Device A
  2. Send to Device B
- **Expected**: Full text delivered, no truncation
- **Priority**: P0

#### TC-MSG-003: Voice Message (7 seconds)
- **Platform**: Android, iOS
- **Steps**:
  1. Record 7-second voice message on Device A
  2. Send to Device B
- **Expected**: Voice playback successful, duration 7±0.5s
- **Priority**: P0

#### TC-MSG-004: Large Payload Chunking
- **Platform**: Android, iOS
- **Steps**:
  1. Send 10KB message (voice or image) over UDP
  2. Monitor chunking (1200 bytes per chunk)
- **Expected**: All chunks delivered, reassembly successful, CRC32 valid
- **Priority**: P0

### 3. DTN Routing Tests

#### TC-DTN-001: Store & Forward
- **Platform**: Android, iOS
- **Prerequisite**: 3 devices A, B, C
- **Steps**:
  1. Device A in range of B
  2. Device C in range of B, NOT in range of A
  3. Send message from A to C
- **Expected**: Message routes A→B→C, delivered within 30 seconds
- **Priority**: P0

#### TC-DTN-002: Priority Queue
- **Platform**: Android, iOS, Relay
- **Steps**:
  1. Queue 10 Low priority messages
  2. Queue 1 High priority message
  3. Send all when connection available
- **Expected**: High priority message sent first
- **Priority**: P0

#### TC-DTN-003: TTL Expiration
- **Platform**: Android, iOS
- **Steps**:
  1. Send message with TTL=60 seconds
  2. Keep destination offline for 70 seconds
  3. Bring destination online
- **Expected**: Message not delivered, expired notification shown
- **Priority**: P0

#### TC-DTN-004: Deduplication
- **Platform**: Android, iOS
- **Steps**:
  1. Send message from A to B
  2. Network issue causes retry
  3. Message delivered twice to B
- **Expected**: B shows message only once (seen_messages table)
- **Priority**: P0

### 4. ACK & Delivered Tests

#### TC-ACK-001: Received ACK
- **Platform**: Android, iOS
- **Steps**:
  1. Send message from A to B
  2. B receives message
  3. Check ACK status on A
- **Expected**: "Received" ACK from B within 5 seconds
- **Priority**: P0

#### TC-ACK-002: Delivered ACK
- **Platform**: Android, iOS
- **Steps**:
  1. Message stored in B's local database
  2. B sends Delivered ACK to A
  3. Check delivered status on A
- **Expected**: Message marked "delivered" on A
- **Priority**: P0

#### TC-ACK-003: Multiple Hops ACK
- **Platform**: Android, iOS
- **Prerequisite**: 3 devices A, B, C
- **Steps**:
  1. Send message A→B→C
  2. Check ACKs from B and C
- **Expected**: Received ACK from B (relay), Delivered ACK from C (destination)
- **Priority**: P0

#### TC-ACK-004: ACK Persistence
- **Platform**: Android, iOS
- **Steps**:
  1. Send message, receive ACK
  2. Restart app
  3. Check message status
- **Expected**: ACK status persists after restart (SQLite acks table)
- **Priority**: P0

### 5. Security Tests

#### TC-SEC-001: Ed25519 Signature Verification
- **Platform**: Android, iOS
- **Steps**:
  1. Send message from A to B
  2. Modify packet signature in transit (MITM simulation)
  3. B receives tampered packet
- **Expected**: Message rejected, signature verification fails
- **Priority**: P0

#### TC-SEC-002: X25519 Encryption
- **Platform**: Android, iOS
- **Steps**:
  1. Establish encrypted channel A↔B
  2. Send message
  3. Inspect network traffic (Wireshark)
- **Expected**: Message content encrypted, plaintext not visible
- **Priority**: P0

#### TC-SEC-003: Peer Key Store Persistence
- **Platform**: Android, iOS
- **Steps**:
  1. Add peer public key to store
  2. Restart app
  3. List peers
- **Expected**: Peer key persists (JSON file)
- **Priority**: P0

#### TC-SEC-004: Rate Limiting (Relay)
- **Platform**: Relay
- **Steps**:
  1. Send 300 packets/sec from single IP
  2. Monitor relay logs
- **Expected**: Packets throttled to 200 PPS, excess dropped
- **Priority**: P0

#### TC-SEC-005: Peer Limit (Relay)
- **Platform**: Relay
- **Steps**:
  1. Simulate 10,001 unique peer connections
  2. Monitor relay memory/stats
- **Expected**: Peer limit enforced at 10,000, new peers dropped
- **Priority**: P0

## P1 Tests (Nice to Have)

### 6. Performance Tests

#### TC-PERF-001: BLE Throughput
- **Platform**: Android, iOS
- **Steps**:
  1. Send 100 status messages in 60 seconds
  2. Measure delivery rate
- **Expected**: >90% delivery rate, <2s latency per message
- **Priority**: P1

#### TC-PERF-002: Relay Throughput
- **Platform**: Relay
- **Steps**:
  1. Load test with 1000 packets/sec
  2. Monitor CPU, memory, forwarding rate
- **Expected**: <50% CPU, <200MB memory, >95% forwarding success
- **Priority**: P1

#### TC-PERF-003: Battery Drain (Android)
- **Platform**: Android
- **Steps**:
  1. Full charge device
  2. Run app for 8 hours with BLE enabled
  3. Measure battery consumption
- **Expected**: <15% battery drain over 8 hours
- **Priority**: P1

#### TC-PERF-004: Database Query Performance
- **Platform**: Android, iOS
- **Steps**:
  1. Store 1000 messages in SQLite
  2. Query recent messages (LIMIT 50)
  3. Measure query time
- **Expected**: <100ms query time with index
- **Priority**: P1

### 7. Edge Cases

#### TC-EDGE-001: Airplane Mode Toggle
- **Platform**: Android, iOS
- **Steps**:
  1. Enable airplane mode mid-transfer
  2. Wait 30 seconds
  3. Disable airplane mode
- **Expected**: App recovers, queued messages sent
- **Priority**: P1

#### TC-EDGE-002: App Backgrounded
- **Platform**: iOS
- **Steps**:
  1. Start message transfer
  2. Press home button (background app)
  3. Wait 60 seconds
- **Expected**: Message delivery continues in background (or queued on wake)
- **Priority**: P1

#### TC-EDGE-003: Network Switch (WiFi→LTE)
- **Platform**: Android, iOS
- **Steps**:
  1. Connected via WiFi
  2. Disable WiFi, enable LTE
  3. Send message
- **Expected**: Transport switches, message delivered via LTE
- **Priority**: P1

#### TC-EDGE-004: Low Memory Conditions
- **Platform**: Android, iOS
- **Steps**:
  1. Fill device memory to 95%
  2. Attempt message send
- **Expected**: Graceful degradation, error message shown
- **Priority**: P1

#### TC-EDGE-005: Relay Restart
- **Platform**: Relay
- **Steps**:
  1. Send messages through relay
  2. Kill relay process
  3. Restart relay within 10 seconds
- **Expected**: Clients reconnect, queued messages forwarded
- **Priority**: P1

### 8. UI/UX Tests

#### TC-UI-001: Onboarding Flow
- **Platform**: Android, iOS
- **Steps**:
  1. Install app (fresh install)
  2. Complete onboarding screens
  3. Reach main screen
- **Expected**: <60 seconds to main screen, clear instructions
- **Priority**: P1

#### TC-UI-002: Settings Screen
- **Platform**: Android, iOS
- **Steps**:
  1. Open settings
  2. Change relay address
  3. Toggle BLE/WiFi options
- **Expected**: Settings persist, take effect immediately
- **Priority**: P1

#### TC-UI-003: Debug Screen
- **Platform**: Android, iOS
- **Steps**:
  1. Open debug screen
  2. Verify stats: received, sent, peers, ACKs
- **Expected**: Real-time stats update, accurate counts
- **Priority**: P1

#### TC-UI-004: Inbox Pagination
- **Platform**: Android, iOS
- **Steps**:
  1. Receive 100 messages
  2. Scroll inbox
  3. Load more (pagination)
- **Expected**: Smooth scrolling, lazy loading, no UI freeze
- **Priority**: P1

## Test Execution Plan

### Phase 1: Core Functionality (Week 1)
- TC-CON-001 to TC-CON-004
- TC-MSG-001 to TC-MSG-004
- TC-SEC-001 to TC-SEC-003

### Phase 2: DTN & ACK (Week 2)
- TC-DTN-001 to TC-DTN-004
- TC-ACK-001 to TC-ACK-004
- TC-SEC-004 to TC-SEC-005

### Phase 3: Performance & Edge Cases (Week 3)
- TC-PERF-001 to TC-PERF-004
- TC-EDGE-001 to TC-EDGE-005
- TC-UI-001 to TC-UI-004

## Test Environment

### Hardware
- **Android**: Samsung Galaxy S23 (Android 14), Pixel 8 (Android 15)
- **iOS**: iPhone 14 (iOS 17), iPhone 15 Pro (iOS 18)
- **Relay**: AWS t3.medium (2 vCPU, 4GB RAM, us-east-1)

### Software
- **ya_ok_core**: v0.1.0 (Rust, release build)
- **Android App**: debug + release APK
- **iOS App**: TestFlight build
- **Relay**: Docker container (yaok-relay:latest)

## Test Data

### Test Messages
1. Status: "Я ОК", "Зайнятий", "Пізніше"
2. Text: 10, 50, 100, 256 character strings (Cyrillic, emoji)
3. Voice: 1s, 3s, 7s audio clips (WAV, 16kHz)

### Test Peers
- Peer A: `pk_a1b2c3d4...` (trusted)
- Peer B: `pk_e5f6g7h8...` (trusted)
- Peer C: `pk_i9j0k1l2...` (trusted)
- Peer X: `pk_xxxxxxxx...` (untrusted, for security tests)

## Defect Tracking

### Critical Defects (P0)
- Must be fixed before release
- Block all testing until resolved

### Major Defects (P1)
- Should be fixed before release
- Workaround available

### Minor Defects (P2)
- Can be deferred to next release
- Low impact on user experience

## Sign-Off Criteria

✅ All P0 tests pass (100%)
✅ >90% P1 tests pass
✅ No critical security vulnerabilities
✅ Performance benchmarks met
✅ Code coverage >80%
✅ Documentation complete

## Test Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Test Coverage | 100% P0, 90% P1 | TBD |
| Pass Rate | >95% | TBD |
| Avg Test Duration | <5 min/test | TBD |
| Defect Density | <2 defects/KLOC | TBD |
| Code Coverage | >80% | TBD |

## Notes

1. **Automation**: Consider using Appium for Android/iOS UI tests
2. **CI/CD**: Integrate tests into GitHub Actions pipeline
3. **Regression**: Run full suite before each release
4. **Manual Testing**: Some tests (BLE, voice) require manual execution
5. **Monitoring**: Use relay /metrics endpoint for production monitoring

## References

- [Definition of Done](DEFINITION_OF_DONE_AND_SCENARIOS.md)
- [ACK Implementation](ACK_IMPLEMENTATION.md)
- [Relay Server Guide](RELAY_SERVER_GUIDE.md)
