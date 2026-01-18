# 🎨 Гайд з іконок та UI елементів

## 📋 Всі іконки та елементи проекту

---

## 🎯 Інструменти для експорту

### **1. Іконки:**
- **Файл:** `docs/icons-export-tool.html`
- **Що експортує:** Всі емоджі іконки у PNG (64, 128, 256, 512)
- **Категорії:** Status, Navigation, Action, System, UI

### **2. UI Елементи:**
- **Файл:** `docs/ui-elements-export-tool.html`
- **Що експортує:** Status Cards, Buttons, Cards, Inputs

---

## 📦 Структура іконок

### **Status Icons (4):**
- 💚 Я ОК (`statusOk`)
- 💛 Зайнятий (`statusBusy`)
- 💙 Пізніше (`statusLater`)
- 🤍 Обійми (`statusHug`)

### **Navigation Icons (5):**
- 👥 Family (`navFamily`)
- ⚙️ Settings (`navSettings`)
- 🔔 Notifications (`navNotifications`)
- ← Back (`navBack`)
- ✕ Close (`navClose`)

### **Action Icons (4):**
- ✓ Check (`actionCheck`)
- ⏱ Pending (`actionPending`)
- + Add (`actionAdd`)
- → Next (`actionNext`)

### **System Icons (7):**
- 🛡️ Security (`systemSecurity`)
- 📡 Internet (`systemInternet`)
- ⚠️ Warning (`systemWarning`)
- 👥 Contacts (`systemContacts`)
- 🔒 Lock (`systemLock`)
- ⚡ Offline (`systemOffline`)
- 👆 Biometric (`systemBiometric`)

### **UI Elements (2):**
- 🔔 Empty Notifications (`uiEmptyNotifications`)
- 💚 Logo (`uiLogo`)

**Всього: 22 іконки**

---

## 🚀 Використання у Flutter

### **Імпорт:**
```dart
import 'package:ya_ok/widgets/app_icons.dart';
```

### **Status Icons:**
```dart
// Простий спосіб
StatusIcon(status: 'ok', size: 28.0)

// Або напряму
EmojiIcon(emoji: AppIcons.statusOk, size: 28.0)
```

### **Navigation Icons:**
```dart
NavIcon(type: 'family', size: 24.0)
NavIcon(type: 'settings', size: 24.0)
NavIcon(type: 'notifications', size: 24.0)
```

### **System Icons:**
```dart
SystemIcon(type: 'security', size: 24.0)
SystemIcon(type: 'warning', size: 24.0)
```

---

## 📐 Розміри для експорту

### **Іконки:**
- **64×64** — для малих елементів
- **128×128** — для середніх елементів
- **256×256** — для великих елементів
- **512×512** — для дуже великих елементів

### **UI Елементи:**
- **375×80** — Status Card
- **300×60** — Button
- **375×100** — Card

---

## 📁 Структура файлів

```
assets/
├── icons/
│   ├── status/
│   │   ├── ok/
│   │   │   ├── icon-ok-64.png
│   │   │   ├── icon-ok-128.png
│   │   │   ├── icon-ok-256.png
│   │   │   └── icon-ok-512.png
│   │   ├── busy/
│   │   ├── later/
│   │   └── hug/
│   ├── navigation/
│   │   ├── family/
│   │   ├── settings/
│   │   └── ...
│   ├── action/
│   ├── system/
│   └── ui/
└── elements/
    ├── status-cards/
    ├── buttons/
    └── cards/
```

---

## ✅ Чек-лист експорту

### **Іконки:**
- [ ] Відкрити `docs/icons-export-tool.html`
- [ ] Натиснути "📥 Завантажити всі іконки"
- [ ] Перевірити всі файли
- [ ] Організувати у папки

### **UI Елементи:**
- [ ] Відкрити `docs/ui-elements-export-tool.html`
- [ ] Завантажити потрібні елементи
- [ ] Перевірити якість

---

## 🎨 Заміна емоджі на SVG (опціонально)

Якщо потрібні векторні іконки замість емоджі:

1. **Використати Material Icons:**
```dart
Icon(Icons.check, color: AppTheme.successGreen)
Icon(Icons.settings, color: AppTheme.textPrimary)
```

2. **Використати Cupertino Icons:**
```dart
Icon(CupertinoIcons.check_mark, color: AppTheme.successGreen)
```

3. **Створити кастомні SVG:**
- Експортувати з Figma
- Використати `flutter_svg` пакет

---

## 💡 Рекомендації

1. **Для production:** Замінити емоджі на SVG іконки
2. **Для прототипу:** Емоджі працюють добре
3. **Оптимізація:** Використати `flutter_svg` для векторних іконок

---

**Готово!** Використовуй інструменти для експорту всіх іконок та елементів. 🎨
