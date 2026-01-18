# 🚀 Інструкція з розгортання "Я ОК"

## 📋 Передумови

- Flutter SDK (3.0+)
- Node.js (18+)
- Firebase CLI
- Google Account для Firebase
- Android Studio / Xcode

---

## Крок 1: Налаштування Firebase

### 1.1. Створення Firebase проєкту

1. Перейдіть на [Firebase Console](https://console.firebase.google.com/)
2. Натисніть **"Add project"**
3. Назва: `ya-ok` (або будь-яка інша)
4. Увімкніть Google Analytics (опціонально)
5. Створіть проєкт

### 1.2. Додавання додатків

**Android:**
1. Натисніть **"Add app"** → **Android**
2. Package name: `app.poruch.yaok` (або ваш)
3. Завантажте `google-services.json` в `android/app/`

**iOS:**
1. Натисніть **"Add app"** → **iOS**
2. Bundle ID: `app.poruch.yaok` (або ваш)
3. Завантажте `GoogleService-Info.plist` в `ios/Runner/`

### 1.3. Встановлення FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Це створить файл `lib/firebase_options.dart` автоматично.

---

## Крок 2: Налаштування Firebase сервісів

### 2.1. Authentication

1. Firebase Console → **Authentication** → **Get started**
2. Увімкніть **Email/Password**
3. (Опціонально) Увімкніть **Google Sign-In**

### 2.2. Firestore Database

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

### 2.3. Cloud Messaging

1. Firebase Console → **Cloud Messaging**
2. Увімкніть сервіс
3. Для iOS: завантажте APNs certificates

---

## Крок 3: Налаштування Cloud Functions

### 3.1. Встановлення залежностей

```bash
cd functions
npm install
```

### 3.2. Локальне тестування (опціонально)

```bash
# Запустити емулятор
firebase emulators:start --only functions

# В іншому терміналі
npm run serve
```

### 3.3. Розгортання

```bash
# З папки functions
firebase deploy --only functions

# Або з кореня проєкту
firebase deploy --only functions
```

**Перевірка:**
- Перейдіть у Firebase Console → Functions
- Має з'явитися `sendCheckinNotification` та `checkMissingCheckins`

---

## Крок 4: Налаштування Android

### 4.1. AndroidManifest.xml

**android/app/src/main/AndroidManifest.xml:**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <application
        android:label="Я ОК"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Firebase Messaging Service -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
        
        <!-- Notification Channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="yaok_channel" />
    </application>
</manifest>
```

### 4.2. Отримання SHA-1 ключа

```bash
cd android
./gradlew signingReport
```

Скопіюйте SHA-1 з виводу та додайте в:
- Firebase Console → Project Settings → Your apps → Android app → Add fingerprint

### 4.3. build.gradle

**android/app/build.gradle:**

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "app.poruch.yaok"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

---

## Крок 5: Налаштування iOS

### 5.1. Info.plist

**ios/Runner/Info.plist:**

```xml
<key>NSFaceIDUsageDescription</key>
<string>Для безпечного входу в додаток</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### 5.2. Capabilities

1. Xcode → Runner → Signing & Capabilities
2. Додати **Push Notifications**
3. Додати **Background Modes** → **Remote notifications**

### 5.3. APNs Certificates

1. Apple Developer → Certificates → Create new
2. Створити **Apple Push Notification service SSL**
3. Завантажити в Firebase Console → Project Settings → Cloud Messaging → iOS

---

## Крок 6: Створення структури проєкту

### 6.1. Структура папок

```
lib/
├── main.dart
├── models/
│   ├── user_model.dart
│   ├── checkin_model.dart
│   └── contact_model.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── notification_service.dart
│   └── local_storage_service.dart
├── screens/
│   ├── auth_screen.dart
│   ├── biometric_screen.dart
│   ├── main_screen.dart
│   ├── family_screen.dart
│   └── settings_screen.dart
└── widgets/
    └── custom_widgets.dart
```

### 6.2. Копіювання коду

Скопіюйте код з `docs/flutter-complete-code.dart` у відповідні файли.

---

## Крок 7: Встановлення залежностей

```bash
flutter pub get
```

---

## Крок 8: Тестування

### 8.1. Локальне тестування

```bash
# Android
flutter run

# iOS
flutter run -d ios
```

### 8.2. Тестування на пристрої

1. Підключіть Android/iOS пристрій
2. Увімкніть режим розробника
3. Запустіть: `flutter run`

---

## Крок 9: Білд для продакшену

### Android (APK)

```bash
flutter build apk --release
```

APK буде в: `build/app/outputs/flutter-apk/app-release.apk`

### Android (App Bundle для Google Play)

```bash
flutter build appbundle --release
```

AAB буде в: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

Потім відкрийте Xcode та створіть архів для App Store.

---

## Крок 10: Моніторинг та логування

### Firebase Console

- **Analytics** — статистика використання
- **Crashlytics** — звіти про збої (потрібно додати)
- **Performance** — продуктивність

### Cloud Functions Logs

```bash
firebase functions:log
```

---

## ⚠️ Важливі зауваження

1. **Безпека:**
   - Ніколи не комітьте `firebase_options.dart` у публічний репозиторій
   - Використовуйте `.gitignore`
   - Оновіть Firestore rules перед продакшеном

2. **Квоти Firebase:**
   - Free tier має обмеження
   - Моніторьте використання в Console

3. **Тестування:**
   - Тестуйте на реальних пристроях
   - Перевірте оффлайн-режим
   - Перевірте push-сповіщення

---

## 🆘 Troubleshooting

### Проблема: Push-сповіщення не приходять

1. Перевірте, чи дозволені сповіщення в налаштуваннях пристрою
2. Перевірте токен у Firebase Console
3. Перевірте логи Cloud Functions: `firebase functions:log`

### Проблема: Оффлайн-режим не працює

1. Перевірте, чи ініціалізовано Hive
2. Перевірте дозволи на зберігання
3. Перевірте логи: `flutter logs`

### Проблема: Firebase не підключається

1. Перевірте `google-services.json` / `GoogleService-Info.plist`
2. Перевірте `firebase_options.dart`
3. Перевірте інтернет-з'єднання

---

## ✅ Чек-лист перед публікацією

- [ ] Firebase налаштовано
- [ ] Cloud Functions розгорнуто
- [ ] Firestore rules застосовано
- [ ] Тестування пройдено
- [ ] Оффлайн-режим працює
- [ ] Push-сповіщення працюють
- [ ] Біометрія працює
- [ ] Privacy Policy додано
- [ ] Іконки та splash screen готові
- [ ] Версія оновлена в `pubspec.yaml`

---

**Готово! 🎉** Ваш додаток готовий до публікації в Google Play та App Store.
