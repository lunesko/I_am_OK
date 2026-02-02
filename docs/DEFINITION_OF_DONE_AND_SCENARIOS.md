# Definition of Done (DoD) и Matrix сценариев

## Definition of Done (DoD)

- **Core:** Все модули в `ya_ok_core` собраны без ошибок, unit-тесты для crypto/packet/storage проходят.
- **Transport:** BLE/WiFi/UDP реализаций достаточно для локального теста; UDP chunking/reassembly стабильны.
- **Interop:** JNI (Android) и Swift (iOS) FFI работают и загружают core при инициализации.
- **Storage:** Peer key store персистентен, доступен через API `list`/`remove`, автозагрузка при init.
- **DTN:** Store-&-forward A→B→C с очередями и дедупликацией, без silent failures.
- **Delivery Semantics:** ACK реализованы, статус `delivered` корректно выставляется при подтверждении.
- **Security:** Ed25519/X25519/AES-GCM используются везде, тесты верифицируют подписи и шифрование.
- **iOS Hardening:** Multipeer ошибки корректно обрабатываются, consent/validation реализованы, background-expectations документированы.
- **Relay Hardening:** Мониторинг, health checks и опциональный fallback/второй регион настроены.
- **Docs & QA:** QA-матрица, debug screen и релизная документация подготовлены.

## Сценарии приёмки (Scenario Matrix)

Краткая матрица сценариев для Android / iOS / relay — основные сценарии и критерии приёмки.

- **S1 — Local status exchange (BLE)**
  - Участники: 3x Android (BLE)
  - Ожидаемое: `Я ОК` от A → B → C получены и отображены, RTT < 5s, все сообщения `delivered`.
  - Acceptance: 10/10 успешных сообщений за 5 подряд попыток.

- **S2 — Cross-platform text (Android ↔ iOS via BLE/WiFi)**
  - Участники: Android + iOS
  - Ожидаемое: Текст ≤256 байт доставлен, подпись валидна, дедупликация работает.
  - Acceptance: корректная десериализация и проверка подписи на принимающей стороне.

- **S3 — UDP forwarding with chunking (relay optional)**
  - Участники: Android (UDP) → relay → Android
  - Ожидаемое: большие payloadы разбиваются/собираются корректно; нет silent failures при потере пакетов (ре-try/timeout).
  - Acceptance: целостность payload (checksum) подтверждена, повторная сборка в пределах timeout.

- **S4 — DTN multi-hop A→B→C**
  - Участники: 3 устройства, любой транспорт
  - Ожидаемое: Store-&-forward, hops и TTL соблюдаются, дедупликация предотвращает дубли.
  - Acceptance: сообщение доставлено конечному получателю до истечения TTL, без дубликатов.

- **S5 — ACK semantics & delivered**
  - Участники: любой
  - Ожидаемое: отправитель получает ACK; delivered помечается только после подтверждения всеми требуемыми хопами/получателями.
  - Acceptance: сценарий с искусственной потере пакета показывает повторную отправку и корректный ACK.

- **S6 — iOS background & Multipeer errors**
  - Участники: iOS устройства в фоне
  - Ожидаемое: graceful degradation при ограничениях background; ошибки Multipeer логируются и показывают рекомендации пользователю.
  - Acceptance: приложение не крашится в фоне, пользователь получает понятный feedback.

- **S7 — Relay resilience & monitoring**
  - Участники: relay (single/multi-region)
  - Ожидаемое: health checks, метрики, fallback на 2-й регион при ошибках.
  - Acceptance: симуляция отказа primary региона вызывает переключение и непрерывность сервиса.

## Следующие шаги (текущее приоритетное направление)

- Имплементация `peer key store` (persist) + API `list`/`remove` + автозагрузка при init — owner: core-team, ETA: 3 дня.
- Реализовать UDP chunking/reassembly и убрать silent failures — owner: transport-team, ETA: 5 дней.
- DTN A→B→C правила очередей/forward и интеграция sync — owner: routing-team, ETA: 7 дней.
