# Я ОК Core

Автономное ядро системы "Я ОК" - минимальной системы передачи сигналов присутствия в условиях нестабильной связи.

## Архитектура

```
[ UI ]          (Kotlin/Swift)
   |
[ FFI API ]     (JNI/Swift FFI)
   |
[ Rust Core ]   (этот crate)
   ├── core/      # идентичность, крипта, сообщения
   ├── transport/ # каналы (BLE, Wi-Fi, IP)
   ├── routing/   # DTN Store & Forward
   ├── storage/   # локальное хранение
   ├── sync/      # gossip protocol
   ├── policy/    # ограничения среды
   └── api/       # FFI интерфейс
```

## Принципы

1. **Один продукт** - нет версий, нет режимов
2. **Адаптивная система** - сама выбирает транспорт
3. **Автономность** - работает без сервера
4. **Безопасность по умолчанию** - минимум данных, максимум защиты

## Типы сообщений

- **Status**: "Я ОК", "Зайнятий", "Пізніше"
- **Text**: до 256 байт
- **Voice**: до 7 секунд

## Транспорты

- BLE (всегда доступен)
- Wi-Fi Direct (локальная сеть)
- UDP/IP (интернет)
- Satellite (специальные условия)

## FFI API

### Инициализация

```c
int ya_ok_core_init();
```

### Работа с идентичностью

```c
int ya_ok_create_identity();
char* ya_ok_get_identity_id();
```

### Отправка сообщений

```c
int ya_ok_send_status(int status_type);  // 0=OK, 1=Busy, 2=Later
int ya_ok_send_text(const char* text);
```

### Управление

```c
int ya_ok_start_listening();
int ya_ok_stop_listening();
int ya_ok_set_policy(int policy_type);  // 0=Default, 1=Military, 2=Collapse, 3=Offline
```

## Сборка

```bash
cargo build --release
```

Для Android:

```bash
cargo build --target aarch64-linux-android --release
```

Для iOS:

```bash
cargo build --target aarch64-apple-ios --release
```

## Policy (ограничения среды)

| Политика | Текст | Голос | Транспорты | TTL |
|----------|-------|-------|------------|-----|
| Default  | 256b  | 7s    | Все        | 1h  |
| Military | 128b  | 3s    | BLE+SAT    | 30m |
| Collapse | 64b   | 0s    | BLE        | 15m |
| Offline  | 256b  | 7s    | BLE+WiFi   | 1h  |

## Безопасность

- **Ed25519** для идентичности и подписей
- **X25519** для обмена ключами
- **AES-GCM** для шифрования payload
- **CBOR** для сериализации
- **TTL + Hops** для предотвращения зацикливания

## DTN Routing

- Store & Forward
- Flooding с дедупликацией
- Приоритеты: Status > Text > Voice
- Gossip protocol для синхронизации

## Хранение

- SQLite для метаданных
- Автоудаление по TTL
- Дедупликация по message_id
- Локально, без облака

## Примеры использования

### Android (Kotlin)

```kotlin
// Инициализация
val result = YaOkCore.init()
if (result != 0) {
    // Обработка ошибки
}

// Создание идентичности
YaOkCore.createIdentity()

// Отправка статуса
YaOkCore.sendStatus(0) // OK

// Получение ID
val id = YaOkCore.getIdentityId()
```

### iOS (Swift)

```swift
// Аналогично через Swift FFI
```

## Разработка

### Добавление нового транспорта

1. Реализовать trait `Transport`
2. Добавить в `TransportManager`
3. Обновить `Policy` если нужно

### Добавление нового типа сообщений

1. Расширить `MessageType`
2. Добавить валидацию в `Policy`
3. Обновить FFI API

## Тестирование

```bash
cargo test
```

## Производительность

- Минимум аллокаций
- Zero-copy где возможно
- Async/await для I/O
- SQLite с индексами

## Распространение

Ядро может быть скомпилировано для:

- Android (JNI)
- iOS (Swift FFI)
- Desktop (CLI)
- Embedded (no_std)
- WebAssembly (браузер)

## Лицензия

[Добавить лицензию]

## Контрибьютинг

[Добавить правила]