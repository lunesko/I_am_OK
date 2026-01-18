# 🐳 Збірка Flutter проекту через Docker

## 📋 Передумови

- Docker встановлений та запущений
- Docker Compose (опціонально, для зручності)

---

## 🚀 Швидкий старт

### Варіант 1: Docker Compose (рекомендовано)

```powershell
# Зібрати та запустити
docker-compose up --build

# APK буде в папці build/outputs/app-release.apk
```

### Варіант 2: Docker безпосередньо

```powershell
# Зібрати образ
docker build -t ya-ok-build .

# Запустити контейнер та скопіювати APK
docker run --rm -v "${PWD}/build/outputs:/output" ya-ok-build sh -c "flutter build apk --release && cp build/app/outputs/flutter-apk/app-release.apk /output/app-release.apk"
```

---

## 📁 Структура

```
I am OK/
├── Dockerfile              # Основний Dockerfile
├── docker-compose.yml      # Docker Compose конфігурація
├── .dockerignore          # Файли для ігнорування
└── build/outputs/          # Зібраний APK (створюється автоматично)
    └── app-release.apk
```

---

## 🔧 Налаштування

### Змінити режим збірки:

В `docker-compose.yml`:
```yaml
environment:
  - FLUTTER_BUILD_MODE=debug  # або release
```

### Зібрати debug APK:

```powershell
docker-compose run flutter-build flutter build apk --debug
```

### Зібрати app bundle:

```powershell
docker-compose run flutter-build flutter build appbundle --release
```

---

## 📦 Що включає Dockerfile

1. **Базовий образ:** `cirrusci/flutter:stable`
   - Flutter SDK встановлений
   - Android SDK налаштований
   - Gradle готовий до роботи

2. **Кроки збірки:**
   - Копіювання файлів проекту
   - Встановлення залежностей (`flutter pub get`)
   - Збірка APK (`flutter build apk --release`)
   - Копіювання APK в фінальний образ

3. **Оптимізації:**
   - Кешування залежностей
   - Мінімальний фінальний образ (Alpine Linux)

---

## 🐛 Вирішення проблем

### Проблема: "Cannot find Android SDK"

```dockerfile
# Додати в Dockerfile перед flutter build:
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools
RUN flutter doctor -v
```

### Проблема: "Gradle build failed"

```powershell
# Очистити кеш та перезібрати:
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

### Проблема: "Out of memory"

```yaml
# В docker-compose.yml додати:
services:
  flutter-build:
    mem_limit: 4g
    memswap_limit: 4g
```

---

## 📊 Переваги Docker збірки

✅ **Ізольоване середовище** — не залежить від системних налаштувань  
✅ **Відтворюваність** — однакові результати на різних машинах  
✅ **Швидкість** — кешування залежностей  
✅ **Простота** — не потрібно налаштовувати Java/Gradle локально  

---

## 🔍 Перевірка зібраного APK

```powershell
# Після збірки перевірити APK:
cd build/outputs
file app-release.apk
ls -lh app-release.apk

# Встановити на пристрій:
adb install app-release.apk
```

---

## 📝 Логи збірки

```powershell
# Подивитися логи:
docker-compose logs flutter-build

# Зберегти логи в файл:
docker-compose logs flutter-build > build.log
```

---

## 🎯 Альтернативні варіанти

### Збірка з кешем Gradle:

```dockerfile
# Додати в Dockerfile:
RUN mkdir -p /root/.gradle
VOLUME ["/root/.gradle"]
```

### Збірка з передачею Firebase конфігурації:

```powershell
docker run --rm \
  -v "${PWD}/lib/firebase_options.dart:/app/lib/firebase_options.dart" \
  -v "${PWD}/build/outputs:/output" \
  ya-ok-build
```

---

## ✅ Чек-лист

- [ ] Docker встановлений
- [ ] Docker Compose встановлений (опціонально)
- [ ] Проект клоновано
- [ ] `firebase_options.dart` налаштовано (якщо потрібно)
- [ ] Запущено `docker-compose up --build`
- [ ] APK знайдено в `build/outputs/app-release.apk`

---

**Після успішної збірки APK буде в папці `build/outputs/app-release.apk`!** ✅
