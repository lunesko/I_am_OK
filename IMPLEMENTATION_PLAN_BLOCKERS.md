# План Исправления Критических Блокеров

**Дата**: 2026-02-07  
**Цель**: Устранить критические блокеры для релиза v1.0  
**Timeline**: 10 рабочих дней

---

## Sprint 1: Критические Блокеры (Дни 1-5)

### День 1-2: БЛОКЕР-1 - SQLCipher

**Задачи**:
1. ✅ Установить SQLCipher для разработки
   - Windows: `vcpkg install sqlcipher:x64-windows`
   - Linux: `sudo apt install libsqlcipher-dev`
   
2. ✅ Обновить зависимости
   ```toml
   rusqlite = { version = "0.32", features = ["bundled-sqlcipher"] }
   ```

3. ✅ Реализовать генерацию уникального ключа
   - Генерировать при первом запуске
   - Сохранять в platform keystore (Android Keystore / iOS Keychain)
   - Fallback: зашифрованный файл с device fingerprint

4. ✅ Добавить тесты шифрования
   - Проверить что БД не читается без ключа
   - Forensic test: hexdump должен показывать encrypted data

**Acceptance Criteria**:
- [ ] `cargo build` успешно с sqlcipher
- [ ] Database encryption работает
- [ ] Уникальный ключ генерируется при установке
- [ ] 3+ теста для encryption проходят

---

### День 3-4: БЛОКЕР-2 - DTLS Transport

**Задачи**:
1. ✅ Реализовать UdpTransport::send_packet()
   - DTLS handshake с tokio-rustls
   - Отправка encrypted пакета
   - Интеграция verify_certificate_pin()

2. ✅ Реализовать UdpTransport::start_listening()
   - DTLS listener
   - Callback для входящих пакетов

3. ✅ Обновить is_available()
   - Проверка доступности интернета
   - Проверка доступности relay сервера

4. ✅ Добавить интеграционные тесты
   - Mock DTLS сервер
   - Тесты send/receive
   - Тест certificate pinning failure

**Acceptance Criteria**:
- [ ] UDP транспорт работает с DTLS
- [ ] Certificate pinning активирован
- [ ] Relay сервер отвечает на запросы
- [ ] 5+ интеграционных тестов проходят

---

### День 5: БЛОКЕР-3 - Hardcoded Key

**Задачи**:
1. ✅ Удалить hardcoded ключ из storage/mod.rs
2. ✅ Реализовать KeyManager
   - Генерация ключа: PBKDF2(random_salt + device_id)
   - Сохранение в secure storage
   - Retrieval при инициализации БД

3. ✅ FFI интерфейсы для platform keystores
   - Android JNI: `getEncryptionKey()`
   - iOS FFI: `get_encryption_key()`
   - Desktop: зашифрованный конфиг

**Acceptance Criteria**:
- [ ] Нет hardcoded ключей в коде
- [ ] Каждая установка имеет уникальный ключ
- [ ] Ключ недоступен без platform authentication

---

## Sprint 2: Транспорты (Дни 6-8)

### День 6-7: Базовый BLE Transport

**Задачи**:
1. ✅ Реализовать BLE advertising (FFI заглушки)
2. ✅ Реализовать BLE scanning
3. ✅ Реализовать send_packet() через BLE GATT
4. ✅ Интеграция с chunking для больших сообщений

**Scope**:
- Только basic send/receive
- Без оптимизаций (connection pooling, etc.)
- Platform-specific код как FFI заглушки

**Acceptance Criteria**:
- [ ] BLE transport компилируется
- [ ] FFI интерфейсы определены
- [ ] Mock тесты для BLE проходят

---

### День 8: WiFi Direct Transport (опционально)

**Задачи**:
1. ✅ Базовая реализация WiFi Direct discovery
2. ✅ Реализовать send_packet()
3. ✅ FFI заглушки для Android WiFi Direct API

**Acceptance Criteria**:
- [ ] WiFi Direct транспорт компилируется
- [ ] FFI интерфейсы определены

---

## Sprint 3: Quality & Testing (Дни 9-10)

### День 9: Test Coverage

**Задачи**:
1. ✅ Добавить тесты для message.rs (15 тестов)
2. ✅ Добавить тесты для packet.rs (20 тестов)
3. ✅ Добавить тесты для ack.rs (10 тестов)
4. ✅ Integration tests для full E2E flow

**Target**: Coverage 58% → 75%+

**Acceptance Criteria**:
- [ ] Test coverage >75%
- [ ] Все критические пути покрыты тестами
- [ ] E2E тесты проходят

---

### День 10: Audit & Polish

**Задачи**:
1. ✅ Аудит логов
   - Убрать логирование private keys
   - Убрать логирование nonces
   - Убрать логирование plaintext сообщений

2. ✅ Security review
   - Code review critical paths
   - Verify zeroize для всех секретов
   - Check for timing attacks

3. ✅ Performance testing
   - Benchmark encryption/decryption
   - Benchmark database queries
   - Check memory leaks

**Acceptance Criteria**:
- [ ] Нет sensitive data в логах
- [ ] Security checklist пройден
- [ ] Performance requirements выполнены

---

## Реализация: Начинаем Сейчас

### Immediate Action: SQLCipher Setup

**Шаг 1**: Попытаться использовать bundled-sqlcipher (более простая интеграция)

```toml
rusqlite = { version = "0.32", features = ["bundled-sqlcipher"] }
```

**Шаг 2**: Реализовать KeyManager для генерации уникальных ключей

**Шаг 3**: Обновить Storage::new() для использования KeyManager

**Начинаем прямо сейчас** ⬇️
