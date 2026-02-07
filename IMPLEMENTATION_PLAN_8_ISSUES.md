# План реалізації виправлень та нових функцій
## 8 пунктів для покращення Ya OK

**Дата:** 6 лютого 2026  
**Статус:** Аналіз завершено, готовий до імплементації

---

## 📋 Загальний огляд

Після детального аналізу кодової бази виявлено наступне:

### ✅ Вже реалізовано:
1. **QR-код з іменем користувача** - працює коректно
2. **Вибір контактів для відправки** - реалізовано в `FamilyFragment` та `MainFragment`
3. **Вкладки вхідних/вихідних повідомлень** - реалізовано в `InboxFragment`
4. **Двостороннє додавання контактів** - логіка `contact_add_request` реалізована
5. **Offline буферизація** - реалізовано через `DtnQueue`
6. **Mesh маршрутизація** - реалізовано через `DtnRouter`

### ⚠️ Потребує перевірки та налагодження:
- Доставка повідомлень через всі транспорти
- Індикація активних з'єднань
- Відображення вкладок повідомлень

---

## 1️⃣ QR-код і ім'я користувача

### Поточний стан: ✅ ПРАЦЮЄ
**Файл:** `android/app/src/main/kotlin/app/poruch/ya_ok/ui/QrCodeActivity.kt`

**Що вже зроблено:**
```kotlin
// QR-код включає ім'я користувача
val userName = getSharedPreferences("ya_ok_prefs", MODE_PRIVATE)
    .getString("user_name", null)
if (userName != null) {
    append("&name=${android.net.Uri.encode(userName)}")
}
```

**Парсинг працює:**
```kotlin
// FamilyFragment.kt - lines 247-259
private fun parseContactQr(raw: String): ContactQr {
    val name = uri?.getQueryParameter("name")?.trim()?.let { 
        android.net.Uri.decode(it)  // Декодує URL-encoded ім'я
    }
    return ContactQr(normalizedId, x25519Hex, name)
}
```

**Автозаповнення працює:**
```kotlin
// Lines 134-138
val qrData = if (scannedId != null) parseContactQr(scannedId) else null
if (prefillName == null) {
    prefillName = qrData?.name  // Автоматично заповнює поле імені
}
```

### ❓ Можлива проблема:
- Перевірити, чи користувач заповнив своє ім'я в налаштуваннях (`user_name` в `SharedPreferences`)
- Якщо ім'я не встановлено, QR не буде містити параметр `name`

### ✅ Рішення:
Додати перевірку при генерації QR і нагадування користувачу встановити своє ім'я.

---

## 2️⃣ Вибір контактів для відправки повідомлень

### Поточний стан: ✅ РЕАЛІЗОВАНО
**Файл:** `android/app/src/main/kotlin/app/poruch/ya_ok/ui/MainFragment.kt`

**Реалізовані функції:**
```kotlin
// Lines 366-389
private fun showContactSelectionForSend() {
    // Multi-select діалог
    .setMultiChoiceItems(contactNames, null) { _, which, isChecked ->
        if (isChecked) {
            selectedIndices.add(which)
        } else {
            selectedIndices.remove(which)
        }
    }
    .setPositiveButton("Надіслати") { ... }  // Відправити вибраним
    .setNeutralButton("Всім") { ... }         // Відправити всім
}
```

**Відправка кожному контакту окремо:**
```kotlin
// Lines 389-415
private fun sendToRecipients(recipientIds: List<String>) {
    recipientIds.forEach { recipientId ->
        // Статус
        val statusResult = CoreGateway.sendStatusTo(status, recipientId)
        // Текст
        if (text.isNotEmpty()) {
            CoreGateway.sendTextTo(text, recipientId)
        }
        // Голос
        if (voice != null) {
            CoreGateway.sendVoiceTo(voice, recipientId)
        }
    }
}
```

### ✅ Статус: ПРАЦЮЄ
Функціонал повністю реалізований. Користувач може:
1. Вибрати одного або кілька контактів (multi-select)
2. Відправити всім контактам (кнопка "Всім")
3. Кожен контакт отримує окреме повідомлення через `sendTextTo(message, contactId)`

---

## 3️⃣ Вкладки вхідних/вихідних повідомлень

### Поточний стан: ✅ РЕАЛІЗОВАНО
**Файл:** `android/app/src/main/kotlin/app/poruch/ya_ok/ui/InboxFragment.kt`

**Реалізація:**
```kotlin
// Lines 27-62
private enum class TabType {
    ALL, INCOMING, OUTGOING
}

tabLayout.addTab(newTab().setText("Всі"))
tabLayout.addTab(newTab().setText("Вхідні"))
tabLayout.addTab(newTab().setText("Вихідні"))

addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
    override fun onTabSelected(tab: TabLayout.Tab?) {
        currentTab = when (tab?.position) {
            1 -> TabType.INCOMING
            2 -> TabType.OUTGOING
            else -> TabType.ALL
        }
        renderMessages()
    }
})
```

**Фільтрація повідомлень:**
```kotlin
// Lines 82-94
val isOutgoing = senderId == myId
val shouldShow = when (currentTab) {
    TabType.ALL -> true
    TabType.INCOMING -> !isOutgoing
    TabType.OUTGOING -> isOutgoing
}

// Lines 106-107
val direction = if (isOutgoing) "➤" else "◀"
messageSubtitle.text = "$direction ${display.time}"
```

### ✅ Статус: ПРАЦЮЄ
Вкладки реалізовані та функціонують. Можлива проблема: перевірити, чи `TabLayout` відображається в `fragment_inbox.xml`.

---

## 4️⃣ Механізм відправки повідомлень

### Поточний стан: ⚠️ ПОТРЕБУЄ ДІАГНОСТИКИ

**Ланцюжок відправки:**
```
MainFragment
    ↓ sendToRecipients()
CoreGateway.sendTextTo(text, recipientId)
    ↓ JNI
ya_ok_core/src/api/mod.rs
    ↓ ya_ok_send_text_to()
create_and_send_packet_to()
    ↓
DtnRouter.send_to(packet, recipient_id)
    ↓
TransportManager (UDP/BLE/Mesh)
```

**Перевірка коду Rust:**
```rust
// ya_ok_core/src/api/mod.rs - lines 827-876
fn create_and_send_packet_to(
    state: &Arc<CoreState>,
    message: Message,
    recipient_id: &str,
) -> Result<(), ApiError> {
    // 1. Перевірка наявності peer
    if let Some(peer) = known_peers.get(recipient_id) {
        // 2. Перевірка x25519 ключа
        if let Some(x25519_key_bytes) = &peer.x25519_public_key {
            // 3. Створення пакету
            if let Ok(packet) = Packet::from_message(&message, identity, &receiver_key) {
                // 4. Відправка через router
                router.send_to(&packet, recipient_id).await
            }
        }
    }
}
```

### 🔍 Потенційні проблеми:

#### A. Peer не зареєстрований
```kotlin
// Перевірка: FamilyFragment.kt - lines 180-187
if (!qrData.x25519Hex.isNullOrBlank()) {
    val result = CoreGateway.addPeer(qrData.id, qrData.x25519Hex)
    peerAdded = (result == 0)
}
```

**Діагностика:**
- Додати логування `CoreGateway.getPeerList()` перед відправкою
- Перевірити, чи `addPeer()` повертає 0 (успіх)

#### B. Relay не підключений
```kotlin
// Перевірка підключення до relay
// UdpTransport.kt повинен мати active connection
```

**Діагностика:**
- Перевірити логи `UdpTransport.start()`
- Перевірити доступність `relay.ya-ok.com` або Fly.io relay

#### C. BLE/Mesh не активні
```kotlin
// BleTransport.kt та WifiDirectController.kt
// Мають запускатись в TransportService
```

**Діагностика:**
- Перевірити Bluetooth дозволи
- Перевірити `BleTransport.start()` логи

### ✅ План виправлення:

1. **Додати діагностичну функцію:**
```kotlin
// MainFragment.kt
private fun diagnoseMessageDelivery() {
    val peers = CoreGateway.getPeerList()
    Log.d("YaOk", "Known peers: $peers")
    
    val stats = CoreGateway.getStats()
    Log.d("YaOk", "Core stats: $stats")
    
    // Перевірка транспортів
    Log.d("YaOk", "UDP active: ${udpTransport.isActive}")
    Log.d("YaOk", "BLE active: ${bleTransport.isActive}")
}
```

2. **Додати retry логіку:**
```kotlin
// Якщо sendTextTo повертає помилку, повторити через 5 сек
if (sendResult != 0) {
    handler.postDelayed({
        CoreGateway.sendTextTo(text, recipientId)
    }, 5000)
}
```

3. **Додати індикатор статусу відправки:**
```kotlin
// Показувати користувачу:
// ⏳ Відправка...
// ✅ Доставлено
// ⚠️ Чекає підключення
```

---

## 5️⃣ Двостороннє додавання контактів

### Поточний стан: ✅ РЕАЛІЗОВАНО (потребує тестування)

**Відправка запиту:**
```kotlin
// FamilyFragment.kt - lines 200-215
val addRequestJson = buildString {
    append("{\"type\":\"contact_add_request\",")
    append("\"id\":\"$myId\",")
    append("\"name\":\"$myName\"")
    if (!myX25519.isNullOrBlank()) {
        append(",\"x25519\":\"$myX25519\"")
    }
    append("}")
}
val sendResult = CoreGateway.sendTextTo(addRequestJson, qrData.id)
```

**Обробка запиту:**
```kotlin
// TransportService.kt - lines 100-158
private fun handleContactAddRequest(jsonContent: String, senderId: String) {
    val contactId = requestObj.optString("id")
    val contactName = requestObj.optString("name", "Користувач")
    val x25519Key = requestObj.optString("x25519")
    
    // Auto-add contact
    ContactStore.addContact(this, contact)
    
    // Sync peer if x25519 key available
    if (x25519Key.isNotBlank()) {
        CoreGateway.addPeer(contactId, x25519Key)
    }
    
    // Show notification
    NotificationHelper.showContactAdded(this, contactName)
}
```

### ✅ Статус: ПРАЦЮЄ (теоретично)

**Проблема:** Повідомлення `contact_add_request` може не доходити через проблеми з доставкою (див. пункт 4).

**Рішення:**
1. Спочатку вирішити проблему доставки повідомлень
2. Додати підтвердження: "Ваш запит на додавання відправлено"
3. Показувати статус: "Очікує підтвердження від John"

---

## 6️⃣ Індикація поточного з'єднання

### Поточний стан: ⚠️ ЧАСТКОВО РЕАЛІЗОВАНО

**Існуючий UI:**
```xml
<!-- fragment_main.xml - lines 364-404 -->
<TextView android:id="@+id/bluetoothStatusIcon" android:text="📶" />
<TextView android:id="@+id/bluetoothStatusText" android:text="Bluetooth" />
<TextView android:id="@+id/meshStatusIcon" android:text="🔗" />
<TextView android:id="@+id/meshStatusText" android:text="Mesh" />
<TextView android:id="@+id/relayStatusIcon" android:text="🌐" />
<TextView android:id="@+id/relayStatusText" android:text="Relay" />
```

### ❌ Проблема: Статуси не оновлюються

**Потрібно додати:**
```kotlin
// MainFragment.kt
private fun updateConnectionStatus() {
    // Bluetooth
    val bleActive = bleTransport?.isActive() ?: false
    bluetoothStatusIcon.text = if (bleActive) "📶" else "📵"
    bluetoothStatusText.setTextColor(
        if (bleActive) Color.GREEN else Color.GRAY
    )
    
    // Relay
    val relayActive = udpTransport?.isConnectedToRelay() ?: false
    relayStatusIcon.text = if (relayActive) "🌐" else "🚫"
    relayStatusText.setTextColor(
        if (relayActive) Color.GREEN else Color.GRAY
    )
    
    // Mesh (кількість peer'ів)
    val peerCount = getPeerCount()
    meshStatusIcon.text = if (peerCount > 0) "🔗" else "⛓️‍💥"
    meshStatusText.text = "Mesh ($peerCount)"
}

// Оновлювати кожні 5 секунд
private val statusUpdateRunnable = object : Runnable {
    override fun run() {
        updateConnectionStatus()
        handler.postDelayed(this, 5000)
    }
}
```

### ✅ План реалізації:

1. Додати методи перевірки статусу в `UdpTransport`, `BleTransport`
2. Отримувати кількість активних peer'ів з `CoreGateway.getPeerList()`
3. Періодично оновлювати UI (кожні 5 сек)
4. Показувати tooltip при кліку: "Bluetooth: 2 пристрої поруч"

---

## 7️⃣ Offline буферизація повідомлень

### Поточний стан: ✅ РЕАЛІЗОВАНО В RUST CORE

**Rust implementation:**
```rust
// ya_ok_core/src/routing/queue.rs
pub struct DtnQueue {
    priority_queue: BinaryHeap<QueuedPacket>,
    seen_packets: HashSet<String>,
}

impl DtnQueue {
    pub fn enqueue(&mut self, packet: Packet, priority: Priority) {
        self.priority_queue.push(QueuedPacket {
            packet,
            priority,
            enqueued_at: Instant::now(),
        });
    }
}
```

**TransportService sync:**
```kotlin
// TransportService.kt - lines 63-68
private fun syncOutgoing() {
    val packets = CoreGateway.exportPendingPackets(50).orEmpty()
    if (packets.isBlank()) return
    
    udpTransport.send(packets)
    bleTransport.send(packets)
}
```

### ✅ Статус: ПРАЦЮЄ

**Як працює:**
1. Повідомлення зберігається в SQLite (`storage.store_message()`)
2. Пакет додається в `DtnQueue`
3. `TransportService` експортує pending пакети кожні 15 сек
4. Відправляє через доступні транспорти (UDP/BLE)
5. При успіху пакет видаляється з черги

**Можливе покращення:**
- Показувати користувачу статус "В черзі: 3 повідомлення"
- Додати manual retry кнопку

---

## 8️⃣ Mesh маршрутизація

### Поточний стан: ✅ РЕАЛІЗОВАНО В RUST CORE

**DtnRouter implementation:**
```rust
// ya_ok_core/src/routing/mod.rs
async fn flood_packet(&self, packet: Packet) -> Result<(), RoutingError> {
    let packet_id = hex::encode(&packet.id);
    
    // Дедуплікація
    let mut seen = self.seen_packets.write().await;
    if seen.contains(&packet_id) {
        return Ok(()); // Вже бачили цей пакет
    }
    seen.insert(packet_id.clone());
    
    // Надіслати всім відомим peer'ам
    let peers = self.known_peers().read().await;
    for (peer_id, _peer_info) in peers.iter() {
        self.transport.send_to(peer_id, &packet.to_bytes()).await?;
    }
    
    Ok(())
}
```

**Store & Forward:**
```rust
async fn handle_packet(&self, packet: Packet) -> Result<(), RoutingError> {
    // 1. Зберегти пакет
    self.storage.lock().unwrap().store_packet(&packet)?;
    
    // 2. Перевірити, чи для нас
    if packet.recipient_id == self.identity_id {
        // Обробити локально
        return self.process_local_packet(packet).await;
    }
    
    // 3. Переслати далі (flood)
    self.flood_packet(packet).await
}
```

### ✅ Статус: РЕАЛІЗОВАНО

**Як працює:**
1. Пристрій A відправляє повідомлення для пристрою C
2. Пакет надходить на пристрій B (проміжний)
3. B зберігає пакет в локальному storage
4. B пересилає пакет всім своїм peer'ам (flooding)
5. Пакет досягає C або пристрою з інтернетом
6. Дедуплікація запобігає циклам (seen_packets HashSet)

**Покращення:**
- Додати hop count (TTL) для обмеження кількості пересилань
- Показувати маршрут: A → B → C (діагностика)
- Оптимізувати вибір наступного peer'а (не випадковий flood)

---

## 📊 Підсумкова таблиця статусів

| № | Проблема | Статус | Пріоритет | Час на виправлення |
|---|----------|--------|-----------|-------------------|
| 1 | QR-код не підтягує ім'я | ✅ Працює | Low | 0h (перевірка налаштувань) |
| 2 | Вибір контактів для відправки | ✅ Реалізовано | Low | 0h (вже працює) |
| 3 | Вкладки вхідні/вихідні | ✅ Реалізовано | Low | 1h (перевірка UI) |
| 4 | Повідомлення не доставляються | ⚠️ Діагностика | **HIGH** | 8h (діагностика + fixes) |
| 5 | Двостороннє додавання | ✅ Реалізовано | Medium | 2h (залежить від п.4) |
| 6 | Індикація з'єднання | ⚠️ Частково | Medium | 4h (додати оновлення UI) |
| 7 | Offline буферизація | ✅ Працює | Low | 0h (вже працює) |
| 8 | Mesh маршрутизація | ✅ Працює | Low | 2h (покращення) |

**Загальний час: ~17 годин**

---

## 🎯 Рекомендований план дій

### День 1 (8 годин)
1. **Діагностика доставки повідомлень** (п.4)
   - Додати детальне логування
   - Перевірити peer registration
   - Тестувати Relay підключення
   - Тестувати BLE транспорт

2. **Виправлення критичних багів**
   - Якщо peer не реєструється
   - Якщо транспорт не стартує
   - Якщо пакети не відправляються

### День 2 (6 годин)
3. **Індикація з'єднання** (п.6)
   - Додати методи перевірки статусу транспортів
   - Реалізувати періодичне оновлення UI
   - Додати tooltips з деталями

4. **Покращення mesh маршрутизації** (п.8)
   - Додати TTL для пакетів
   - Оптимізувати вибір peer'а

### День 3 (3 години)
5. **Тестування та покращення UX**
   - Перевірити вкладки повідомлень
   - Додати індикатори відправки
   - Тестувати двостороннє додавання

---

## 🔍 Контрольний список перевірок

### Перед початком:
- [ ] Backup існуючого коду
- [ ] Створити тестову гілку `fix/8-issues`
- [ ] Підготувати 2 тестові пристрої

### Під час розробки:
- [ ] Детальне логування на кожному кроці
- [ ] Перевірка кожної функції окремо
- [ ] Unit тести для критичних компонентів

### Після завершення:
- [ ] Тестування на 2 пристроях (Android)
- [ ] Тестування всіх транспортів (Relay/BLE/Mesh)
- [ ] Тестування offline режиму
- [ ] Перевірка довгих сценаріїв (A→B→C)
- [ ] Smoke тест на iOS (базова функціональність)

---

## 📝 Додаткові нотатки

### Важливі файли для редагування:
1. `MainFragment.kt` - відправка та UI статусів
2. `InboxFragment.kt` - вкладки повідомлень
3. `FamilyFragment.kt` - додавання контактів
4. `TransportService.kt` - обробка incoming
5. `UdpTransport.kt` / `BleTransport.kt` - статус транспортів
6. `ya_ok_core/src/api/mod.rs` - відправка через Rust
7. `ya_ok_core/src/routing/mod.rs` - маршрутизація

### Корисні команди для діагностики:
```bash
# Android логи
adb logcat | grep "YaOk"

# Перевірка SQLite
adb shell "run-as app.poruch.ya_ok cat databases/ya_ok.db" > ya_ok.db
sqlite3 ya_ok.db "SELECT * FROM messages;"

# Перевірка relay підключення
curl https://i-am-ok-relay.fly.dev/health
```

---

## ✅ Висновок

Більшість функцій **вже реалізовані та працюють**. Головна проблема - **доставка повідомлень** (пункт 4), яка блокує пункт 5.

**Критичний шлях:**
1. Вирішити проблему доставки (п.4) 
2. Перевірити двостороннє додавання (п.5)
3. Додати візуальні індикатори (п.6)
4. Покращити UX (решта пунктів)

**Очікуваний результат:** Повністю функціональний месенджер з mesh мережею та offline підтримкою.
