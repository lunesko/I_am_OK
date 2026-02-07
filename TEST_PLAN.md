# План тестування Ya OK v0.1.0
**Дата:** 3 лютого 2026  
**Стандарт:** ISO/IEC/IEEE 29119 (Software Testing)

---

## 📋 ЗМІСТ

1. [Unit тестування](#unit-тестування)
2. [Інтеграційне тестування](#інтеграційне-тестування)
3. [Системне тестування](#системне-тестування)
4. [Тести безпеки](#тести-безпеки)
5. [Тести продуктивності](#тести-продуктивності)
6. [Acceptance тести](#acceptance-тести)

---

## 1️⃣ UNIT ТЕСТУВАННЯ

### 1.1 Rust Core Tests

#### Test Suite: ya_ok_core
**Локація:** `ya_ok_core/src/`

| Модуль | Тести | Статус |
|--------|-------|--------|
| `transport/chunking.rs` | 4 тести | ⏳ |
| `storage/tests.rs` | 3 тести | ⏳ |
| `routing/queue.rs` | 3 тести | ⏳ |

**Команда запуску:**
```bash
cd ya_ok_core
cargo test
```

**Очікуваний результат:**
```
test result: ok. 10 passed; 0 failed
```

---

### 1.2 Android Unit Tests

#### Test Suite: CoreGateway
**Локація:** `android/app/src/test/kotlin/app/poruch/ya_ok/`

**Тести для створення:**

| Функція | Тест кейс | Пріоритет |
|---------|-----------|-----------|
| `CoreGateway.init()` | Ініціалізація з валідним шляхом | 🔴 HIGH |
| `CoreGateway.getIdentityId()` | Повернення ID після створення | 🔴 HIGH |
| `CoreGateway.addPeer()` | Додавання peer з x25519 ключем | 🔴 HIGH |
| `CoreGateway.sendTextTo()` | Відправка до існуючого peer | 🟡 MEDIUM |
| `CoreGateway.sendTextTo()` | Помилка при неіснуючому peer | 🟡 MEDIUM |
| `parseContactQr()` | Парсинг yaok:// URL з усіма параметрами | 🔴 HIGH |
| `parseContactQr()` | URL decode імені | 🔴 HIGH |
| `ContactStore.addContact()` | Збереження контакту в SQLite | 🟡 MEDIUM |

---

## 2️⃣ ІНТЕГРАЦІЙНЕ ТЕСТУВАННЯ

### 2.1 Kotlin ↔ Rust FFI Integration

| Тест | Опис | Статус |
|------|------|--------|
| JNI Bridge Init | Виклик `ya_ok_init_with_path()` через JNI | ⏳ |
| Identity Creation | `createIdentity()` → перевірка файлу | ⏳ |
| X25519 Key Retrieval | `getIdentityX25519PublicKeyHex()` → не NULL | ⏳ |
| Peer Addition | `addPeer()` → повернення 0 (success) | ⏳ |
| Message Sending | `sendTextTo()` → пакет в storage | ⏳ |
| Packet Handling | `handle_incoming_packet()` → декриптування | ⏳ |

**Команда запуску:**
```bash
cd android
./gradlew test
```

---

### 2.2 Transport Integration Tests

| Транспорт | Тест | Статус |
|-----------|------|--------|
| Bluetooth | BLE scan → знайдено пристрій | ⏳ |
| Bluetooth | BLE advertise → видимість | ⏳ |
| WiFi Direct | P2P connection → обмін пакетами | ⏳ |
| Internet/Relay | UDP → relay → доставка | ⏳ |

---

### 2.3 Database Integration

| Операція | Тест | Статус |
|----------|------|--------|
| ContactStore | CRUD операції | ⏳ |
| Message Storage | Збереження/читання повідомлень | ⏳ |
| Peer Storage | Збереження x25519 ключів | ⏳ |

---

## 3️⃣ СИСТЕМНЕ ТЕСТУВАННЯ

### 3.1 End-to-End Scenarios

#### Сценарій A: QR обмін + bidirectional add
```
Device 1                          Device 2
   │                                 │
   ├─► Generate QR                  │
   │   (id, name, x25519)            │
   │                                 │
   │                            ◄────┤ Scan QR
   │                                 ├─► Parse URL
   │                                 ├─► addPeer(d1_id, d1_x25519)
   │                                 ├─► sendTextTo(contact_add_request, d1_id)
   │                                 │
   ◄──┤ Receive contact_add_request  │
   ├─► Auto-add Device 2             │
   ├─► addPeer(d2_id, d2_x25519)     │
   │                                 │
   ✅ Bidirectional connection       ✅
```

**Критерії успіху:**
- ✅ Device 2 бачить "Device 1" в контактах
- ✅ Device 1 бачить "Device 2" в контактах (auto-add)
- ✅ `Known peers count >= 1` на обох
- ✅ Можливість відправити повідомлення в обидві сторони

---

#### Сценарій B: Bluetooth message delivery
```
Device 1                          Device 2
   │                                 │
   ├─► BLE Advertise                 │
   │   (UUID, service data)           │
   │                                 │
   │                            ◄────┤ BLE Scan
   │                                 ├─► Connect to Device 1
   │                                 │
   ├─► sendTextTo("Привіт", d2_id)   │
   ├─► Encrypt with d2_x25519        │
   ├─► Send via BLE                  │
   │                                 │
   │                            ◄────┤ Receive encrypted packet
   │                                 ├─► Decrypt with d1_x25519
   │                                 ├─► Store message
   │                                 │
   │                                 ✅ Message delivered
```

**Критерії успіху:**
- ✅ BLE з'єднання встановлено
- ✅ Пакет зашифровано
- ✅ Пакет доставлено через BLE
- ✅ Device 2 декриптував повідомлення
- ✅ Повідомлення відображається в Inbox

---

#### Сценарій C: Offline queue + relay sync
```
Device 1 (offline)                Device 2 (online)
   │                                 │
   ├─► sendTextTo("Допомога!", d2_id)│
   ├─► Queue packet (no connection)  │
   │   └─ Store in SQLite            │
   │                                 │
   ├─► Connect to Internet           │
   ├─► syncOutgoing()                │
   ├─► Send queued packet → Relay    │
   │                                 │
   │                            ◄────┤ Relay forwards packet
   │                                 ├─► Decrypt
   │                                 ├─► Notify user
   │                                 │
   │                                 ✅ Offline message delivered
```

---

### 3.2 UI Tests (Espresso)

| Screen | Тест | Статус |
|--------|------|--------|
| MainActivity | Навігація між вкладками | ⏳ |
| FamilyFragment | Додавання контакту | ⏳ |
| FamilyFragment | QR генерація | ⏳ |
| InboxFragment | Відображення повідомлень | ⏳ |
| InboxFragment | Фільтрація по вкладках | ⏳ |
| MainFragment | Multi-select контактів | ⏳ |

---

## 4️⃣ ТЕСТИ БЕЗПЕКИ

### 4.1 Encryption Tests

| Тест | Опис | Статус |
|------|------|--------|
| E2E Encryption | X25519 key exchange → AES-256-GCM | ⏳ |
| Key Storage | Android Keystore integration | ⏳ |
| Packet Tampering | Відхилення змінених пакетів | ⏳ |
| Replay Attack | Захист від повторної відправки | ⏳ |

### 4.2 Relay Security Tests

| Тест | Опис | Статус |
|------|------|--------|
| Rate Limiting | 200 pps limit | ⏳ |
| Packet Size | Max 64KB enforcement | ⏳ |
| IP Validation | DNS vs pinned IPs | ⏳ |

---

## 5️⃣ ТЕСТИ ПРОДУКТИВНОСТІ

### 5.1 Performance Benchmarks

| Метрика | Ціль | Поточне | Статус |
|---------|------|---------|--------|
| App Cold Start | <3s | ? | ⏳ |
| QR Generation | <500ms | ? | ⏳ |
| Message Encrypt | <50ms | ? | ⏳ |
| BLE Discovery | <5s | ? | ⏳ |
| Relay RTT | <100ms | 32ms | ✅ |
| Database Query | <10ms | ? | ⏳ |

### 5.2 Load Tests

| Тест | Сценарій | Статус |
|------|----------|--------|
| Message Queue | 1000 повідомлень в черзі | ⏳ |
| Contact List | 100+ контактів | ⏳ |
| Peer Discovery | 10+ пристроїв поряд | ⏳ |

---

## 6️⃣ ACCEPTANCE ТЕСТИ

### 6.1 User Stories Validation

| Story | Acceptance Criteria | Статус |
|-------|---------------------|--------|
| US-1: Швидке повідомлення | Відправка за <10 секунд | ⏳ |
| US-2: Offline робота | Черга + sync при підключенні | ⏳ |
| US-3: Приватність | E2E шифрування | ⏳ |
| US-4: Простота | Додавання контакту за 1 кліком | ⏳ |

---

## 📊 ТЕСТОВЕ ПОКРИТТЯ

### Ціль покриття:
- **Rust Core:** ≥80% line coverage
- **Android Kotlin:** ≥70% line coverage
- **Critical paths:** 100% coverage

### Інструменти:
- Rust: `cargo-tarpaulin`
- Android: JaCoCo
- E2E: Espresso + UIAutomator

---

## 🔄 CI/CD INTEGRATION

### GitHub Actions Workflow
```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  rust-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Rust tests
        run: cd ya_ok_core && cargo test
  
  android-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Android unit tests
        run: cd android && ./gradlew test
      
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run integration tests
        run: cd android && ./gradlew connectedAndroidTest
```

---

## 📝 ТЕСТОВА ДОКУМЕНТАЦІЯ

### Документи для створення:
1. ✅ `TEST_PLAN.md` (цей файл)
2. ⏳ `UNIT_TEST_REPORT.md`
3. ⏳ `INTEGRATION_TEST_REPORT.md`
4. ⏳ `E2E_TEST_SCENARIOS.md`
5. ⏳ `SECURITY_TEST_REPORT.md`
6. ⏳ `PERFORMANCE_TEST_RESULTS.md`

---

## ✅ NEXT STEPS

### Пріоритети:
1. 🔴 **Запустити існуючі Rust тести** (`cargo test`)
2. 🔴 **Створити Android unit tests** (CoreGateway, ContactStore)
3. 🔴 **Виконати E2E Scenario A** (QR exchange)
4. 🟡 **Додати Espresso UI tests**
5. 🟡 **Security audit** (encryption validation)
6. 🟢 **Performance profiling**

---

**Статус:** 🟡 В ПРОЦЕСІ  
**Покриття:** 0% → Ціль 75%+  
**Дата оновлення:** 2026-02-03 22:15
