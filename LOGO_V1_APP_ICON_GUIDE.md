# 🎨 Варіант 1: Monobank Style — Гайд для App Icon

## ✅ Обрано: Варіант 1 для App Icon, Notification badge, Favicon

---

## 📦 Створені файли

### **1. SVG файли:**
- `docs/logo-v1-app-icon.svg` — для App Icon (512×512)
- `docs/logo-v1-notification.svg` — для Notification (64×64)
- `docs/logo-v1-favicon.svg` — для Favicon (32×32)

### **2. Flutter Widget:**
- `lib/widgets/logo_app_icon.dart` — готовий компонент

### **3. Документація:**
- `docs/logo-v1-specification.md` — повна специфікація
- `LOGO_V1_APP_ICON_GUIDE.md` — цей файл

---

## 🚀 Швидкий старт

### **У Flutter:**

```dart
import 'package:ya_ok/widgets/logo_app_icon.dart';

// App Icon
LogoAppIconExamples.appIcon(size: 512.0)

// Notification badge
LogoAppIconExamples.notification(size: 48.0)

// Favicon
LogoAppIconExamples.favicon(size: 32.0)

// Splash Screen
LogoAppIconExamples.splash()
```

---

## 📱 Інтеграція в Flutter

### **1. App Icon (Android):**

**Файл:** `android/app/src/main/res/mipmap-*/ic_launcher.png`

```dart
// Генерувати через Flutter
// Використати LogoAppIconExamples.appIcon() для кожного розміру
```

**Розміри:**
- `mipmap-mdpi`: 48×48
- `mipmap-hdpi`: 72×72
- `mipmap-xhdpi`: 96×96
- `mipmap-xxhdpi`: 144×144
- `mipmap-xxxhdpi`: 192×192

### **2. App Icon (iOS):**

**Файл:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**Розміри:**
- 1024×1024 (App Store)
- 180×180 (iPhone)
- 120×120 (iPhone)
- 87×87 (iPhone старі)
- 80×80 (iPhone)
- 76×76 (iPad)
- 60×60 (iPhone старі)
- 58×58 (Settings)
- 40×40 (Spotlight)
- 29×29 (Settings старі)
- 20×20 (Notification)

### **3. Notification Badge:**

```dart
// У notification service
final notificationIcon = LogoAppIconExamples.notification(
  size: 48.0,
);
```

### **4. Favicon (Web):**

**Файл:** `web/favicon.png` та `web/favicon.ico`

```dart
// Генерувати через LogoAppIconExamples.favicon()
```

---

## 🎨 Експорт PNG з SVG

### **Спосіб 1: Figma**

1. **Імпортувати SVG:**
   - Відкрити Figma
   - File → Import → `logo-v1-app-icon.svg`

2. **Експортувати PNG:**
   - Виділити об'єкт
   - Right click → Export
   - Format: PNG
   - Size: 1x, 2x, 3x
   - Export

3. **Для всіх розмірів:**
   - Змінити розмір Frame до потрібного (512, 192, 64, 32, 16)
   - Експортувати кожен розмір окремо

### **Спосіб 2: Illustrator**

1. **Відкрити SVG:**
   - File → Open → `logo-v1-app-icon.svg`

2. **Експортувати PNG:**
   - File → Export → Export As
   - Format: PNG
   - Resolution: 72, 144, 216 (для @1x, @2x, @3x)
   - Export

### **Спосіб 3: Online конвертер**

1. **Відкрити:** https://cloudconvert.com/svg-to-png
2. **Завантажити:** SVG файл
3. **Налаштувати:**
   - Width: 512 (або потрібний розмір)
   - Height: 512
   - DPI: 72, 144, 216
4. **Конвертувати**

---

## 📐 Структура файлів для проекту

### **Android:**

```
android/app/src/main/res/
├── mipmap-mdpi/
│   └── ic_launcher.png (48×48)
├── mipmap-hdpi/
│   └── ic_launcher.png (72×72)
├── mipmap-xhdpi/
│   └── ic_launcher.png (96×96)
├── mipmap-xxhdpi/
│   └── ic_launcher.png (144×144)
└── mipmap-xxxhdpi/
    └── ic_launcher.png (192×192)
```

### **iOS:**

```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── AppIcon-1024.png (1024×1024)
├── AppIcon-180.png (180×180)
├── AppIcon-120.png (120×120)
├── AppIcon-87.png (87×87)
├── AppIcon-80.png (80×80)
├── AppIcon-76.png (76×76)
├── AppIcon-60.png (60×60)
├── AppIcon-58.png (58×58)
├── AppIcon-40.png (40×40)
├── AppIcon-29.png (29×29)
└── AppIcon-20.png (20×20)
```

### **Web:**

```
web/
├── favicon.png (32×32)
├── favicon.ico (multi-size)
└── icons/
    ├── Icon-192.png (192×192)
    └── Icon-512.png (512×512)
```

---

## 🔧 Налаштування в Flutter

### **Android (AndroidManifest.xml):**

```xml
<application
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher"
    ...>
</application>
```

### **iOS (Info.plist):**

```xml
<!-- App Icon автоматично з Assets.xcassets -->
```

### **Web (index.html):**

```html
<link rel="icon" type="image/png" href="favicon.png">
<link rel="apple-touch-icon" href="icons/Icon-192.png">
```

---

## ✅ Чек-лист експорту

### **App Icon:**
- [ ] iOS: 1024×1024 (App Store)
- [ ] iOS: 180×180, 120×120, 87×87, 80×80, 76×76, 60×60, 58×58, 40×40, 29×29, 20×20
- [ ] Android: 512×512, 192×192, 144×144, 96×96, 72×72, 48×48, 36×36
- [ ] Web: 192×192, 512×512

### **Notification:**
- [ ] 64×64 (iOS)
- [ ] 48×48 (Android)
- [ ] 40×40 (iOS старі)
- [ ] 24×24 (Android малий)

### **Favicon:**
- [ ] 32×32 (PNG)
- [ ] 16×16 (PNG)
- [ ] Multi-size ICO

---

## 🎯 Рекомендації

### **Для App Icon:**
- ✅ Використовувати символ 💚 (зелене серце)
- ✅ Border radius = 25% від розміру
- ✅ Градієнт від `#0057B7` до `#4A90E2`
- ✅ Тінь для розмірів >= 64px

### **Для Notification:**
- ✅ Спростити символ для малих розмірів (< 48px)
- ✅ Без тіні
- ✅ Можна використати тільки градієнт

### **Для Favicon:**
- ✅ Мінімальний символ або тільки градієнт
- ✅ Перевірити читабельність на 16×16
- ✅ Без тіні

---

## 📝 Примітки

1. **Символ для малих розмірів:**
   - >= 48px: 💚
   - 32-47px: ✓ (галочка)
   - < 32px: тільки градієнт (без символу)

2. **Тінь:**
   - Тільки для розмірів >= 64px
   - Color: `rgba(0, 87, 183, 0.3)`
   - Blur: 25% від розміру

3. **Градієнт:**
   - Завжди 135deg (діагональ)
   - Light mode: `#0057B7` → `#4A90E2`
   - Dark mode: `#4A90E2` → `#6BA3F0`

---

**Готово!** Використовуй Варіант 1 для App Icon, Notification badge та Favicon. 🎨
