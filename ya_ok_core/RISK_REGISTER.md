# Risk Register «Я ОК» Core

## 1. ТЕХНИЧЕСКИЕ РИСКИ

### R1: BLE нестабильность на Android

**Вероятность:** Высокая
**Влияние:** Высокое
**Описание:** BLE на Android имеет известные проблемы с надежностью, особенно на старых устройствах.

**Mitigation:**
- Fallback на Wi-Fi Direct при BLE проблемах
- Регулярное тестирование на разнообразных устройствах
- Graceful degradation (BLE недоступен → только локальное хранение)
- User feedback: "BLE временно недоступен"

**Статус:** 🟡 Monitoring

---

### R2: iOS BLE ограничения

**Вероятность:** Высокая
**Влияние:** Среднее
**Описание:** Apple сильно ограничивает BLE в фоне, требует специальных разрешений.

**Mitigation:**
- iOS-first BLE дизайн (Multipeer Connectivity)
- Push wake-up через APNs (ограниченно)
- Четкая коммуникация: "iOS: работает только на переднем плане"
- Альтернативный транспорт: Wi-Fi Direct для iOS-to-iOS

**Статус:** 🟡 Accepted (известное ограничение)

---

### R3: Криптография performance

**Вероятность:** Средняя
**Влияние:** Среднее
**Описание:** X25519 + AES-GCM могут быть тяжелыми на старых устройствах.

**Mitigation:**
- Benchmark на целевых устройствах (API 21+)
- Опциональное упрощение для collapse mode
- Lazy encryption (шифровать только при отправке)
- Hardware acceleration где возможно

**Статус:** 🟢 Mitigated (дизайн учитывает)

---

### R4: SQLite corruption при внезапном выключении

**Вероятность:** Низкая
**Влияние:** Высокое
**Описание:** Android может убить процесс в любой момент.

**Mitigation:**
- WAL mode для SQLite
- Transaction wrapping для critical operations
- Recovery mechanism (rebuild from recent messages)
- Backup strategy (export/restore identity)

**Статус:** 🟢 Mitigated

---

### R5: Memory leaks в FFI

**Вероятность:** Средняя
**Влияние:** Высокое
**Описание:** C strings и объекты могут не освобождаться правильно.

**Mitigation:**
- RAII паттерны для всех FFI объектов
- Valgrind/ASan в CI
- Memory profiling на устройствах
- Clear ownership semantics в API

**Статус:** 🟡 Testing needed

---

## 2. БЕЗОПАСНОСТНЫЕ РИСКИ

### R6: Ключевой материал утечка

**Вероятность:** Низкая
**Влияние:** Критическое
**Описание:** Private keys могут быть извлечены из памяти или storage.

**Mitigation:**
- Keys только в памяти, не persist
- mlock для sensitive memory
- Zero-out после использования
- No key export functionality
- Threat model review

**Статус:** 🟢 Mitigated (дизайн безопасный)

---

### R7: Message replay attacks

**Вероятность:** Низкая
**Влияние:** Среднее
**Описание:** Повторная отправка перехваченных пакетов.

**Mitigation:**
- Nonce в AES-GCM
- Timestamp validation
- Message ID uniqueness
- TTL enforcement

**Статус:** 🟢 Mitigated

---

### R8: Man-in-the-middle BLE

**Вероятность:** Низкая
**Влияние:** Высокое
**Описание:** BLE незащищен от MITM по умолчанию.

**Mitigation:**
- ECDH key exchange для каждого соединения
- Certificate pinning по identity
- Distance bounding где возможно
- User warning о незащищенности BLE

**Статус:** 🟡 Partial mitigation

---

## 3. АРХИТЕКТУРНЫЕ РИСКИ

### R9: Policy complexity

**Вероятность:** Средняя
**Влияние:** Высокое
**Описание:** Сложная логика policy может привести к багам в edge cases.

**Mitigation:**
- Policy как data, не code
- Comprehensive testing всех policy combinations
- Fallback to default policy on errors
- Policy versioning и migration

**Статус:** 🟡 Monitoring

---

### R10: Transport abstraction leaks

**Вероятность:** Средняя
**Влияние:** Среднее
**Описание:** BLE специфика просачивается в общую логику.

**Mitigation:**
- Strong abstraction boundaries
- Transport-agnostic packet format
- Extensive testing разных transport комбинаций
- Protocol versioning

**Статус:** 🟢 Mitigated

---

### R11: Gossip protocol storms

**Вероятность:** Низкая
**Влияние:** Высокое
**Описание:** Gossip может создать broadcast storms в dense networks.

**Mitigation:**
- Rate limiting gossip messages
- Bloom filters для seen messages
- Adaptive gossip intervals
- Circuit breaker pattern

**Статус:** 🟡 Future consideration

---

## 4. ПРОДУКТОВЫЕ РИСКИ

### R12: User expectations mismatch

**Вероятность:** Высокая
**Влияние:** Высокое
**Описание:** Пользователи ожидают "как Telegram", но получают DTN систему.

**Mitigation:**
- Clear communication philosophy
- "Works when everything else doesn't"
- No delivery guarantees messaging
- Education через UI/FAQ

**Статус:** 🟡 Accepted (philosophy choice)

---

### R13: No recovery story

**Вероятность:** Средняя
**Влияние:** Среднее
**Описание:** Потеря устройства = потеря всей истории и контактов.

**Mitigation:**
- Philosophy: "New identity, continue living"
- Optional encrypted backup (external)
- Clear communication of limitations
- "Data minimalism" as feature

**Статус:** 🟢 Accepted (by design)

---

### R14: Battery drain

**Вероятность:** Высокая
**Влияние:** Высокое
**Описание:** BLE scanning + crypto может быстро сажать батарею.

**Mitigation:**
- Adaptive scanning intervals
- Policy-based transport selection
- Background task optimization
- Battery-aware scheduling
- User controls для power management

**Статус:** 🟡 Mitigating (policy system helps)

---

## 5. РИСКИ МАСШТАБИРОВАНИЯ

### R15: Multi-peer complexity

**Вероятность:** Средняя
**Влияние:** Высокое
**Описание:** 3+ устройств создают complex routing scenarios.

**Mitigation:**
- Extensive multi-device testing
- Chaos engineering подход
- "Flooding is simple, works" principle
- Monitoring и telemetry для production

**Статус:** 🟡 Testing needed

---

### R16: Storage growth

**Вероятность:** Низкая
**Влияние:** Среднее
**Описание:** TTL cleanup может не сработать, storage растет.

**Mitigation:**
- Robust cleanup implementation
- Storage quotas per policy
- User-visible storage management
- Automatic oldest-first cleanup

**Статус:** 🟢 Mitigated

---

## 6. РИСКИ РАЗРАБОТКИ

### R17: Rust learning curve

**Вероятность:** Средняя
**Влияние:** Среднее
**Описание:** Команда не имеет опыта с Rust.

**Mitigation:**
- Rust training и mentorship
- Incremental adoption (core first)
- Strong typing reduces bugs
- Comprehensive testing strategy

**Статус:** 🟡 Mitigating

---

### R18: Cross-platform FFI complexity

**Вероятность:** Высокая
**Влияние:** Высокое
**Описание:** JNI + Swift FFI одновременно сложны.

**Mitigation:**
- Android-first подход
- Shared FFI abstractions
- Extensive testing каждой платформы
- Code generation для FFI

**Статус:** 🟡 Accepted (complexity acknowledged)

---

### R19: Async Rust complexity

**Вероятность:** Высокая
**Влияние:** Среднее
**Описание:** Async runtimes + FFI = complex concurrency.

**Mitigation:**
- Simple async patterns
- Avoid complex futures composition
- Tokio runtime в FFI layer
- Threading model documentation

**Статус:** 🟡 Mitigating

---

## SUMMARY ПО РИСКАМ

### 🟢 GREEN (Mitigated)
- R3, R4, R6, R7, R10, R13, R16

### 🟡 YELLOW (Monitoring/Mitigating)
- R1, R2, R5, R8, R9, R11, R12, R14, R15, R17, R18, R19

### 🔴 RED (High Risk)
- Нет критических рисков

### КЛЮЧЕВЫЕ ИНСАЙТЫ

1. **BLE reliability** - основной технический риск
2. **User expectations** - основной продуктовый риск
3. **Policy system** - ключевой mitigation инструмент
4. **Simple architecture** выигрывает над complex solutions

### РЕКОМЕНДАЦИИ

1. **Start with Android BLE MVP** - prove core concept
2. **Heavy testing на разнообразных устройствах**
3. **Clear "philosophy communication"** пользователям
4. **Policy system как first-class citizen**
5. **Chaos testing для multi-peer scenarios**

---

*Последнее обновление: 2024-01-20*
*Next review: Phase 2 completion*