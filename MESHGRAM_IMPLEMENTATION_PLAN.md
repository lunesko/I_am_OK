# 📡 MeshGram — План впровадження

**Базується на:** MESHGRAM_SPEC.md  
**Інтеграція з:** існуючий "Я ОК" (Firebase, Hive, Provider)

---

## ✅ Phase 0: Фундамент (поточний крок)

- [x] MESHGRAM_SPEC.md, MESHGRAM_IMPLEMENTATION_PLAN.md
- [ ] `lib/models/` — enums: CheckinStatus, TransportType, MeshConnectionType, VoiceMessageStatus
- [ ] `lib/models/checkin_model.dart` — опціональні поля: transport, hopCount, routePath, textMessage, voiceMessageId
- [ ] `lib/models/voice_message.dart` — VoiceMessage, VoicePacket
- [ ] `lib/models/mesh_node.dart` — MeshNode
- [ ] `lib/models/mesh_packet.dart` — MeshPacket
- [ ] `lib/services/transport/transport_router.dart` — TransportRouter
- [ ] `lib/services/transport/firebase_transport.dart` — обгортка над FirestoreService
- [ ] `lib/services/transport/mesh_gram_transport.dart` — stub (store for later)
- [ ] `lib/screens/main_screen.dart` — індикатор транспорту (🌐/📡), використання TransportRouter
- [ ] `pubspec.yaml` — uuid (для MeshPacket id)

**Зворотна сумісність:** старі чекіни без `transport` вважаються FIREBASE; `status` лишається String, enum — для нового коду.

---

## Phase 2: MeshGram Core (після фундаменту)

- Wi-Fi Direct (Android Nearby Connections / `wifi_direct` / `flutter_nearby_connections`)
- Bluetooth LE (`flutter_blue_plus` або аналог)
- Store & Forward: збереження MeshPacket у Hive, черга на відправку/ретрансляцію
- Multi-hop: routePath, maxHops, TTL
- EncryptionService (AES-256-GCM, Ed25519, DH) — stub → реальна реалізація

---

## Phase 3: Голосові

- Opus (`opus_dart` або FFI) — 8 kbps, 16 kHz
- Розбиття на пакети 256 байт, checksum SHA-256
- VoiceOverMesh: sendVoiceMessage, onVoicePacketReceived, assembleAndPlay
- UI: кнопка «Голосове», екран запису/відтворення

---

## Phase 4: Оптимізація

- BatteryOptimizer (інтервал скану, shouldRelay)
- Settings: MeshGram (режим доставки, Wi‑Fi/BT/LoRa, ретрансляція, статистика)
- UI/UX поліпшення, тести

---

## Залежності (додати по фазах)

| Пакет | Фаза | Призначення |
|-------|------|-------------|
| `uuid` | 0 | MeshPacket id |
| `cryptography` або `pointycastle` | 2 | AES-256-GCM, Ed25519 |
| `flutter_nearby_connections` / `wifi_direct` | 2 | Wi-Fi Direct |
| `flutter_blue_plus` | 2 | BLE |
| `opus_dart` або FFI | 3 | Opus codec |
| `battery_plus` | 4 | BatteryOptimizer |

---

## Файлова структура (після Phase 0)

```
lib/
├── models/
│   ├── checkin_model.dart      # + transport, hopCount, routePath, textMessage, voiceMessageId
│   ├── meshgram_enums.dart     # CheckinStatus, TransportType, MeshConnectionType, VoiceMessageStatus
│   ├── mesh_packet.dart
│   ├── mesh_node.dart
│   ├── voice_message.dart      # VoiceMessage, VoicePacket
│   └── ...
├── services/
│   ├── transport/
│   │   ├── transport_router.dart
│   │   ├── firebase_transport.dart
│   │   └── mesh_gram_transport.dart
│   ├── firestore_service.dart
│   └── ...
└── ...
```
