# 🔥 Налаштування Firebase для "Я ОК"

**Час виконання:** 30-45 хвилин  
**Складність:** Середня

---

## 📋 Передумови

- Flutter SDK 3.0+
- Node.js 18+ (для Cloud Functions)
- Google Account
- Firebase CLI встановлений

---

## Крок 1: Встановлення Firebase CLI

```bash
# Встановити Firebase CLI
npm install -g firebase-tools

# Увійти в Firebase
firebase login
```

---

## Крок 2: Створення Firebase проекту

### 2.1. Через Firebase Console

1. Перейдіть на [Firebase Console](https://console.firebase.google.com/)
2. Натисніть **"Add project"**
3. Назва: `ya-ok` (або ваша назва)
4. Увімкніть Google Analytics (опціонально)
5. Створіть проєкт

### 2.2. Ініціалізація в проєкті

```bash
cd "M:\I am OK"
firebase init
```

**Виберіть:**
- ✅ Firestore
- ✅ Functions
- ✅ (Опціонально) Hosting

---

## Крок 3: Налаштування FlutterFire

### 3.1. Встановити FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 3.2. Налаштувати Firebase для Flutter

```bash
flutterfire configure
```

**Що робить команда:**
- Показує список ваших Firebase проектів
- Дозволяє вибрати проект
- Створює `lib/firebase_options.dart` автоматично
- Налаштовує Android/iOS конфігурацію

### 3.3. Перевірити створення файлу

```bash
# Перевірити, що файл створено
ls lib/firebase_options.dart
```

---

## Крок 4: Налаштування Firebase сервісів

### 4.1. Authentication

1. Firebase Console → **Authentication** → **Get started**
2. Увімкніть **Email/Password**
3. (Опціонально) Увімкніть **Google Sign-In**

### 4.2. Firestore Database

1. Firebase Console → **Firestore Database** → **Create database**
2. Оберіть **Start in test mode** (потім оновимо правила)
3. Оберіть регіон: **europe-west** (ближче до України)

**Застосувати правила безпеки:**

```bash
firebase deploy --only firestore:rules
```

**Застосувати індекси:**

```bash
firebase deploy --only firestore:indexes
```

### 4.3. Cloud Messaging

1. Firebase Console → **Cloud Messaging** → **Get started**
2. Для iOS: завантажте APNs certificates (опціонально)

---

## Крок 5: Налаштування Android

### 5.1. Додати додаток в Firebase

1. Firebase Console → **Project Settings** → **Add app** → **Android**
2. Package name: `app.poruch.yaok` (або ваш)
3. Завантажте `google-services.json` в `android/app/`

### 5.2. Отримати SHA-1 ключ

```bash
cd android
./gradlew signingReport
```

**Скопіюйте SHA-1** з виводу та додайте в Firebase Console:
- Firebase Console → **Project Settings** → **Your apps** → **Android app** → **Add fingerprint**

### 5.3. Оновити AndroidManifest.xml

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
  
  <application>
    <!-- Додати service для FCM -->
    <service
      android:name="com.google.firebase.messaging.FirebaseMessagingService"
      android:exported="false">
      <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
      </intent-filter>
    </service>
  </application>
</manifest>
```

---

## Крок 6: Налаштування iOS

### 6.1. Додати додаток в Firebase

1. Firebase Console → **Project Settings** → **Add app** → **iOS**
2. Bundle ID: `app.poruch.yaok` (або ваш)
3. Завантажте `GoogleService-Info.plist` в `ios/Runner/`

### 6.2. Оновити Info.plist

```xml
<!-- ios/Runner/Info.plist -->
<dict>
  <key>NSFaceIDUsageDescription</key>
  <string>Для безпечного входу в додаток</string>
  <key>NSCameraUsageDescription</key>
  <string>Для використання Face ID</string>
  <key>UIBackgroundModes</key>
  <array>
    <string>fetch</string>
    <string>remote-notification</string>
  </array>
</dict>
```

### 6.3. Налаштувати APNs (для push-сповіщень)

1. Apple Developer → **Certificates, Identifiers & Profiles**
2. Створіть APNs Key
3. Завантажте в Firebase Console → **Cloud Messaging** → **Apple app configuration**

---

## Крок 7: Розгортання Cloud Functions

### 7.1. Встановити залежності

```bash
cd functions
npm install
```

### 7.2. Розгорнути функції

```bash
firebase deploy --only functions
```

**Що розгортається:**
- `sendCheckinNotification` — автоматична відправка push при створенні чекіну
- `checkMissingCheckins` — перевірка відсутності зв'язку (щодня)
- `healthCheck` — тестова функція

### 7.3. Перевірити розгортання

```bash
# Перевірити статус
firebase functions:list

# Перевірити логи
firebase functions:log
```

---

## Крок 8: Оновити main.dart

### 8.1. Розкоментувати Firebase ініціалізацію

```dart
// lib/main.dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ... решта коду
}
```

### 8.2. Перевірити компіляцію

```bash
flutter pub get
flutter analyze
flutter run
```

---

## Крок 9: Тестування

### 9.1. Тест автентифікації

```dart
// В додатку
final authService = AuthService();
await authService.signInWithDiaID('test@example.com', 'Test User');
```

### 9.2. Тест Firestore

```dart
// Створити тестовий чекін
final checkin = CheckinModel(
  id: 'test_${DateTime.now().millisecondsSinceEpoch}',
  userId: 'test_user',
  status: 'ok',
  timestamp: DateTime.now(),
  recipientIds: ['user_2'],
);

await FirestoreService().saveCheckin(checkin);
```

### 9.3. Тест Push-сповіщень

1. Отримати FCM токен з логів
2. Відправити тестове сповіщення через Firebase Console → **Cloud Messaging** → **Send test message**

---

## ✅ Чек-лист налаштування

- [ ] Firebase проект створено
- [ ] FlutterFire CLI встановлено
- [ ] `firebase_options.dart` створено
- [ ] Authentication увімкнено
- [ ] Firestore Database створено
- [ ] Firestore Rules застосовано
- [ ] Firestore Indexes застосовано
- [ ] Cloud Messaging увімкнено
- [ ] Android додаток додано
- [ ] iOS додаток додано (якщо потрібно)
- [ ] Cloud Functions розгорнуто
- [ ] `main.dart` оновлено
- [ ] Додаток компілюється
- [ ] Тести пройдені

---

## 🐛 Вирішення проблем

### Помилка: "Firebase not initialized"

**Рішення:**
```dart
// Перевірити, що firebase_options.dart імпортовано
import 'firebase_options.dart';

// Перевірити ініціалізацію
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Помилка: "Missing SHA-1"

**Рішення:**
```bash
cd android
./gradlew signingReport
# Скопіювати SHA-1 та додати в Firebase Console
```

### Помилка: "Firestore permission denied"

**Рішення:**
```bash
# Перевірити правила
firebase deploy --only firestore:rules
```

### Помилка: "Cloud Functions not deployed"

**Рішення:**
```bash
cd functions
npm install
firebase deploy --only functions
```

---

## 📚 Додаткові ресурси

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Cloud Functions Documentation](https://firebase.google.com/docs/functions)

---

**Готово!** 🎉 Firebase налаштовано та готовий до використання.

---

**Зроблено в Україні 🇺🇦**
