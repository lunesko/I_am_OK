# 🔧 Альтернативні способи збірки проекту "Я ОК"

## 📋 Варіанти збірки:

### **1. Через Android Studio (найпростіший)**

#### Кроки:
1. Відкрити Android Studio
2. File → Open → вибрати папку `android/`
3. Дозволити синхронізацію Gradle
4. Build → Build Bundle(s) / APK(s) → Build APK(s)
5. APK буде в `android/app/build/outputs/apk/debug/`

#### Переваги:
- ✅ Android Studio автоматично налаштує Java/Gradle
- ✅ Візуальний інтерфейс
- ✅ Легко дебажити

---

### **2. Через Gradle Wrapper напряму**

#### Команди:
```powershell
cd "M:\I am OK\android"
.\gradlew.bat assembleDebug
```

#### Для release:
```powershell
.\gradlew.bat assembleRelease
```

#### Переваги:
- ✅ Обходить Flutter CLI
- ✅ Прямий доступ до Gradle
- ✅ Швидше

---

### **3. Через Flutter з іншою Java**

#### Варіант A: Використати Java 11 (Microsoft JDK)
```powershell
flutter config --jdk-dir="C:\Program Files\Microsoft\jdk-11.0.16.101-hotspot"
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-11.0.16.101-hotspot"
flutter build apk --debug
```

#### Варіант B: Завантажити Java 17
1. Завантажити Java 17 з [Adoptium](https://adoptium.net/)
2. Встановити в `C:\Program Files\Java\jdk-17`
3. Налаштувати:
```powershell
flutter config --jdk-dir="C:\Program Files\Java\jdk-17"
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
flutter build apk --debug
```

---

### **4. Через Docker (ізольоване середовище)**

#### Створити Dockerfile:
```dockerfile
FROM ubuntu:22.04

# Встановити Java 17 та Flutter
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    wget \
    unzip

# Встановити Flutter
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
RUN tar xf flutter_linux_3.24.5-stable.tar.xz
ENV PATH="/flutter/bin:${PATH}"

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build apk --debug
```

#### Запуск:
```powershell
docker build -t ya-ok-build .
docker run -v ${PWD}/build:/app/build ya-ok-build
```

---

### **5. Через GitHub Actions (CI/CD)**

#### Створити `.github/workflows/build.yml`:
```yaml
name: Build APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.5'
    
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '17'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build APK
      run: flutter build apk --debug
    
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-debug
        path: build/app/outputs/flutter-apk/app-debug.apk
```

---

### **6. Через VS Code з розширенням Flutter**

#### Кроки:
1. Встановити розширення "Flutter" в VS Code
2. Відкрити проект
3. Ctrl+Shift+P → "Flutter: Build APK"
4. Вибрати debug/release

---

### **7. Змінити compileSdk на 33 (замість 34)**

#### В `android/app/build.gradle`:
```gradle
compileSdk = 33  // замість 34
```

#### Може допомогти уникнути проблем з Android SDK 35

---

### **8. Використати Flutter Web (без Java)**

#### Для тестування UI:
```powershell
flutter build web
flutter run -d chrome
```

#### Переваги:
- ✅ Не потребує Java/Android SDK
- ✅ Швидко
- ✅ Легко тестувати UI

---

## 🎯 Рекомендації:

### **Найшвидший спосіб (зараз):**
```powershell
cd "M:\I am OK\android"
.\gradlew.bat assembleDebug
```

### **Найнадійніший (довгостроково):**
1. Завантажити Java 17
2. Налаштувати через `flutter config`
3. Використовувати `flutter build`

### **Для production:**
- Використати Android Studio
- Або налаштувати CI/CD через GitHub Actions

---

## 📝 Швидкий чек-лист:

- [ ] Спробувати Android Studio
- [ ] Спробувати `gradlew.bat` напряму
- [ ] Завантажити Java 17
- [ ] Змінити compileSdk на 33
- [ ] Налаштувати CI/CD

---

**Який спосіб спробуємо першим?** 🚀
