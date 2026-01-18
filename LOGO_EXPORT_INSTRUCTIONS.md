# 📥 Інструкція з експорту логотипів

## 🎯 Швидкий експорт через браузер

### **Крок 1: Відкрити інструмент**
1. Відкрити `docs/logo-export-tool.html` у браузері
2. Натиснути **"🎨 Генерувати всі розміри"**
3. Перевірити прев'ю всіх розмірів

### **Крок 2: Завантажити файли**
1. Натиснути **"📥 Завантажити всі"** для автоматичного експорту
2. Або завантажити окремі файли через кнопки під кожним прев'ю

### **Крок 3: Організувати файли**
Файли будуть завантажені у форматі:
- `logo-appIcon-1024.png`
- `logo-appIcon-512.png`
- `logo-notification-64.png`
- `logo-favicon-32.png`
- і т.д.

---

## 📁 Структура папок для проекту

### **Після завантаження створити структуру:**

```
assets/logo/
├── app-icon/
│   ├── ios/
│   │   ├── AppIcon-1024.png
│   │   ├── AppIcon-512.png
│   │   ├── AppIcon-180.png
│   │   ├── AppIcon-120.png
│   │   └── ... (всі iOS розміри)
│   └── android/
│       ├── ic_launcher-512.png
│       ├── ic_launcher-192.png
│       └── ... (всі Android розміри)
├── notification/
│   ├── notification-64.png
│   ├── notification-48.png
│   ├── notification-40.png
│   └── notification-24.png
└── favicon/
    ├── favicon-32.png
    ├── favicon-16.png
    └── favicon.ico
```

---

## 🔧 Інтеграція в Flutter проект

### **Android:**

1. **Скопіювати файли:**
```bash
# Створити папки
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

# Скопіювати файли
cp logo-appIcon-48.png android/app/src/main/res/mipmap-mdpi/ic_launcher.png
cp logo-appIcon-72.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png
cp logo-appIcon-96.png android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
cp logo-appIcon-144.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
cp logo-appIcon-192.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

2. **Перевірити AndroidManifest.xml:**
```xml
<application
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher"
    ...>
</application>
```

### **iOS:**

1. **Відкрити Xcode:**
```bash
open ios/Runner.xcworkspace
```

2. **Додати іконки:**
   - Відкрити `Assets.xcassets` → `AppIcon`
   - Перетягнути PNG файли у відповідні слоти
   - Або використати [AppIcon Generator](https://www.appicon.co/)

3. **Альтернатива через Flutter:**
```bash
flutter pub add flutter_launcher_icons
```

Створити `flutter_launcher_icons.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/logo/app-icon/ios/AppIcon-1024.png"
  adaptive_icon_background: "#0057B7"
  adaptive_icon_foreground: "assets/logo/app-icon/ios/AppIcon-1024.png"
```

Запустити:
```bash
flutter pub run flutter_launcher_icons
```

### **Web:**

1. **Скопіювати файли:**
```bash
cp logo-favicon-32.png web/favicon.png
cp logo-favicon-16.png web/favicon-16.png
cp logo-appIcon-192.png web/icons/Icon-192.png
cp logo-appIcon-512.png web/icons/Icon-512.png
```

2. **Оновити index.html:**
```html
<link rel="icon" type="image/png" href="favicon.png">
<link rel="apple-touch-icon" href="icons/Icon-192.png">
```

---

## ✅ Чек-лист після експорту

### **App Icon:**
- [ ] iOS: 1024×1024 (App Store)
- [ ] iOS: всі розміри (180, 120, 87, 80, 76, 60, 58, 40, 29, 20)
- [ ] Android: 512, 192, 144, 96, 72, 48, 36
- [ ] Файли скопійовані у правильні папки

### **Notification:**
- [ ] 64×64, 48×48, 40×40, 24×24
- [ ] Інтегровано в notification service

### **Favicon:**
- [ ] 32×32, 16×16
- [ ] Додано у web/index.html

---

## 🎨 Альтернативні способи експорту

### **Спосіб 1: Figma**
1. Імпортувати SVG
2. Експортувати PNG у потрібних розмірах

### **Спосіб 2: Illustrator**
1. Відкрити SVG
2. File → Export → Export As → PNG
3. Встановити розмір та DPI

### **Спосіб 3: Online конвертер**
1. https://cloudconvert.com/svg-to-png
2. Завантажити SVG
3. Встановити розміри
4. Конвертувати

---

## 🚀 Автоматизація (опціонально)

### **Node.js скрипт:**

```javascript
const sharp = require('sharp');
const fs = require('fs');

const sizes = [1024, 512, 192, 180, 120, 87, 80, 76, 60, 58, 40, 29, 20];

async function exportAll() {
  const svg = fs.readFileSync('docs/logo-v1-app-icon.svg');
  
  for (const size of sizes) {
    await sharp(svg)
      .resize(size, size)
      .png()
      .toFile(`logo-appIcon-${size}.png`);
    
    console.log(`✅ Експортовано: ${size}×${size}`);
  }
}

exportAll();
```

---

**Готово!** Використовуй `logo-export-tool.html` для швидкого експорту всіх розмірів. 🎨
