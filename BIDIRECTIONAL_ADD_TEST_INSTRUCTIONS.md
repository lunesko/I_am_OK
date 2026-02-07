# Інструкція: Тестування Bidirectional Contact Add
**Версія:** v0.1.0 (з виправленням Issue #5)  
**Дата:** 3 лютого 2026, 21:43

---

## 🎯 МЕТА ТЕСТУ

Перевірити що **обидва пристрої автоматично бачать один одного** після обміну QR кодами.

---

## 📱 ПРИСТРОЇ

- **Device 1:** Samsung SM-A525F (RZ8T11LV55F) - Олексій
- **Device 2:** Medium Phone AVD (emulator-5554) - Марія

---

## 🔧 ЩО ВИПРАВЛЕНО

### Проблема (ДО):
```
Device 1: Додає контакт "Марія"
          ❌ НЕ викликає addPeer() → нема x25519 ключа в Rust
          ❌ sendTextTo() повертає -5 (peer not found)
Device 2: ❌ Не отримує запит
          ❌ Не бачить "Олексій" в контактах
```

### Рішення (ПІСЛЯ):
```kotlin
// FamilyFragment.kt - Line 179
if (!qrData.x25519Hex.isNullOrBlank()) {
    val result = CoreGateway.addPeer(qrData.id, qrData.x25519Hex)
    println("✅ Added peer key for ${qrData.id}: result=$result")
    peerAdded = (result == 0)
}

// ТІЛЬКИ якщо peerAdded == true:
if (peerAdded) {
    val sendResult = CoreGateway.sendTextTo(addRequestJson, qrData.id)
    // Тепер sendResult = 0 (успіх), а не -5
}
```

---

## 📋 КРОКИ ТЕСТУВАННЯ

### Етап 1: Підготовка (очистка старих даних)

**Device 1:**
```powershell
adb -s RZ8T11LV55F shell pm clear app.poruch.ya_ok
adb -s RZ8T11LV55F shell am start -n app.poruch.ya_ok/.MainActivity
```

**Device 2:**
```powershell
adb -s emulator-5554 shell pm clear app.poruch.ya_ok
adb -s emulator-5554 shell am start -n app.poruch.ya_ok/.MainActivity
```

### Етап 2: Device 1 показує QR

**Device 1 (Samsung):**
1. Відкрити додаток Ya OK
2. Натиснути вкладку **Family** (внизу)
3. Натиснути іконку **QR** (вгорі справа)
4. На екрані з'явиться QR код з даними:
   ```
   yaok://add?id=<device1_id>&name=Олексій&x=<x25519_hex>
   ```

**Збережіть дані вручну або сфотографуйте!**

### Етап 3: Device 2 сканує QR Device 1

**Device 2 (Emulator):**
1. Відкрити Ya OK
2. Family → **+ Add Contact** (вгорі справа)
3. В поле "ID" вставити повний URL з QR:
   ```
   yaok://add?id=<device1_id>&name=Олексій&x=<x25519_hex>
   ```
4. В поле "Name" залишити "Олексій" (автозаповниться)
5. Натиснути **Додати**

**Очікувані логи Device 2:**
```bash
adb -s emulator-5554 logcat -s "System.out:I" | Select-String "Added peer|SendTextTo"
```
```
✅ Added peer key for <device1_id>: result=0
🔵 Sending contact_add_request: id=<device2_id>, name=Марія, to=<device1_id>
🔵 SendTextTo result: 0 (to <device1_id>)
```

**Результат:**
- ✅ Toast: "Контакт додано і синхронізовано"
- ✅ "Олексій" з'явився в списку контактів

### Етап 4: Device 1 отримує auto-add запит

**Device 1 логи:**
```bash
adb -s RZ8T11LV55F logcat -s "System.out:I" | Select-String "contact_add_request|Adding new contact"
```
```
📥 handle_incoming_packet_internal: bytes=256
🔵 Message content: {"type":"contact_add_request","id":"<device2_id>","name":"Марія","x25519":"..."}
🔵 Found contact_add_request, processing...
✅ Adding new contact: Марія
🔵 addPeer result: 0
```

**Перевірка Device 1:**
1. Відкрити Family
2. В списку має з'явитися **"Марія"** ✅

### Етап 5: Device 2 показує QR

**Device 2 (Emulator):**
1. Family → QR іконка
2. На екрані QR код Device 2:
   ```
   yaok://add?id=<device2_id>&name=Марія&x=<x25519_hex>
   ```

### Етап 6: Device 1 сканує QR Device 2

**Device 1 (Samsung):**
1. Family → + Add Contact
2. Вставити URL з QR Device 2
3. Додати

**Device 1 логи:**
```
✅ Added peer key for <device2_id>: result=0
🔵 Sending contact_add_request: id=<device1_id>, name=Олексій, to=<device2_id>
🔵 SendTextTo result: 0
```

### Етап 7: Перевірка двостороннього зв'язку

**Device 1 → Device 2:**
```bash
adb -s RZ8T11LV55F shell input tap 250 600  # Main tab
adb -s RZ8T11LV55F shell input tap 250 730  # Send button
```

**Логи Device 1:**
```
📤 create_and_send_packet_to: recipient=<device2_id>
📤 Known peers count: 1
📤 Found peer: <device2_id> at Ble (або Udp/Internet)
✅ Packet sent successfully
```

**Device 2 отримання:**
```
📥 handle_incoming_packet_internal: bytes=128
📥 Packet from: <device1_id>
✅ Message decrypted successfully
```

**Device 2 → Device 1:**
```bash
adb -s emulator-5554 shell input tap 250 600  # Main
adb -s emulator-5554 shell input tap 250 730  # Send
```

Аналогічні логи в зворотному напрямку.

---

## ✅ КРИТЕРІЇ УСПІХУ

| Тест | Очікуваний результат | Статус |
|------|---------------------|--------|
| Device 2 додає Device 1 через QR | `addPeer result: 0` | ⬜ |
| Device 2 → Device 1: contact_add_request | `SendTextTo result: 0` | ⬜ |
| Device 1 автоматично додає Device 2 | "Марія" в Family | ⬜ |
| Device 1 додає Device 2 через QR | `addPeer result: 0` | ⬜ |
| Device 1 → Device 2: contact_add_request | `SendTextTo result: 0` | ⬜ |
| Device 2 бачить "Олексій" оновленим | Toast про оновлення | ⬜ |
| Device 1 → Device 2: тестове повідомлення | `Known peers: 1+` | ⬜ |
| Device 2 → Device 1: тестове повідомлення | Отримано в Inbox | ⬜ |

**Тест вважається PASS тільки якщо всі 8 пунктів ✅**

---

## 🔍 ДІАГНОСТИКА ПОМИЛОК

### Помилка 1: `addPeer result: -7` (NULL_POINTER)
**Причина:** QR код не містить параметр `x=...`  
**Рішення:** Перевірити генерацію QR в QrCodeActivity.kt

### Помилка 2: `SendTextTo result: -5` (ERR_INTERNAL_ERROR)
**Причина:** Peer не знайдено (addPeer не викликався)  
**Рішення:** Перевірити `peerAdded == true` перед sendTextTo

### Помилка 3: Device 2 не отримує запит
**Причина:** Транспорти не активні або пристрої не в мережі  
**Рішення:** 
```bash
# Перевірити Bluetooth
adb shell settings get global bluetooth_on  # має бути 1

# Перевірити Internet
adb shell ping -c 1 8.8.8.8  # має працювати
```

### Помилка 4: `Known peers count: 0`
**Причина:** `addPeer()` не викликався або повернув помилку  
**Рішення:** Перевірити логи `Added peer key` перед `SendTextTo`

---

## 📊 ОЧІКУВАНІ МЕТРИКИ

### Успішний тест:
- ⏱️ Час обміну QR: ~30 секунд (ручне введення)
- ⏱️ Час доставки contact_add_request: 1-3 секунди
- ⏱️ Час автоматичного додавання: <1 секунди
- 📤 Кількість peers після обміну: 1 (на кожному)
- ✅ Успішність доставки: 100% (0% втрат)

### Файли для збереження результатів:
- `test_device1_contacts_screenshot.png` - Family список Device 1
- `test_device2_contacts_screenshot.png` - Family список Device 2
- `test_device1_logs.txt` - Логи Device 1
- `test_device2_logs.txt` - Логи Device 2

---

## 🎓 ПОЯСНЕННЯ ЛОГІКИ

### Чому потрібен подвійний QR обмін?

**DTN (Delay-Tolerant Networking) вимагає симетричного шифрування:**

1. **Device 1 знає Device 2:**
   - Має `device2_id` (з контакту)
   - Має `device2_x25519_public_key` (з QR)
   - Може шифрувати для Device 2 ✅

2. **Device 2 знає Device 1:**
   - Має `device1_id` (з contact_add_request)
   - Має `device1_x25519_public_key` (з contact_add_request)
   - Може шифрувати для Device 1 ✅

**Без QR обміну:**
- Device 1 НЕ знає `device2_x25519` → не може шифрувати
- `create_and_send_packet_to()` повертає `-5` (peer not found)

**З QR обміном:**
- Обидва мають x25519 ключі
- `known_peers.len() >= 1`
- Пакети шифруються і доставляються ✅

---

## 📝 КОМАНДИ МОНІТОРИНГУ

### Device 1 (Samsung):
```powershell
# Всі логи
adb -s RZ8T11LV55F logcat -s "System.out:I"

# Тільки peer операції
adb -s RZ8T11LV55F logcat -s "System.out:I" | Select-String "peer|addPeer|Known peers"

# Тільки відправка/прийом
adb -s RZ8T11LV55F logcat -s "System.out:I" | Select-String "📤|📥|SendTextTo"
```

### Device 2 (Emulator):
```powershell
# Всі логи
adb -s emulator-5554 logcat -s "System.out:I"

# Contact add request
adb -s emulator-5554 logcat -s "System.out:I" | Select-String "contact_add_request|Adding new contact"

# Packet обробка
adb -s emulator-5554 logcat -s "System.out:I" | Select-String "handle_incoming|Decrypted"
```

---

**Статус:** 🟢 Готово до тестування  
**Пріоритет:** 🔴 КРИТИЧНИЙ (Issue #5)  
**Очікуваний час:** 5-10 хвилин  
**Дата:** 2026-02-03 21:44
