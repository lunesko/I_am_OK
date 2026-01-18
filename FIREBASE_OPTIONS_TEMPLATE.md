# 🔥 Створення firebase_options.dart

Якщо команда `flutterfire configure` не створила файл автоматично, виконайте наступне:

## Варіант 1: Повторна спроба (рекомендовано)

```bash
cd "M:\I am OK"
flutterfire configure --project=i-am-ok-2f7b9
```

**Під час виконання:**
1. Оберіть платформи: **android, ios**
2. Введіть Android package name: **app.poruch.yaok** (або ваш)
3. Введіть iOS bundle ID: **app.poruch.yaok** (або ваш)

## Варіант 2: Створити вручну

Якщо автоматичне створення не працює, створіть файл `lib/firebase_options.dart` вручну:

1. Перейдіть в Firebase Console → Project Settings
2. Скопіюйте конфігурацію для Android та iOS
3. Створіть файл за шаблоном нижче

---

## Шаблон firebase_options.dart

```dart
// File generated using flutterfire configure.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'i-am-ok-2f7b9',
    storageBucket: 'i-am-ok-2f7b9.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'i-am-ok-2f7b9',
    storageBucket: 'i-am-ok-2f7b9.appspot.com',
    iosBundleId: 'app.poruch.yaok',
  );
}
```

**Де взяти значення:**

1. Firebase Console → **Project Settings** → **Your apps**
2. Для Android: скопіюйте значення з `google-services.json`
3. Для iOS: скопіюйте значення з `GoogleService-Info.plist`

---

## Перевірка

Після створення файлу:

```bash
flutter pub get
flutter analyze
```

Якщо помилок немає — файл створено правильно.

---

**Зроблено в Україні 🇺🇦**
