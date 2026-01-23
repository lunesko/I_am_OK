# 📁 Організація файлів логотипів та асетів

## 🔍 Поточна структура

Всі файли знаходяться в папці `logo/` з розширенням `.crdownload` (ще завантажуються).

---

## 📦 Правильна структура

### **Після завершення завантаження створити:**

```
assets/
├── logo/
│   ├── app-icon/
│   │   ├── logo-appIcon-1024.png
│   │   ├── logo-appIcon-512.png
│   │   ├── logo-appIcon-192.png
│   │   ├── logo-appIcon-180.png
│   │   ├── logo-appIcon-120.png
│   │   ├── logo-appIcon-87.png
│   │   ├── logo-appIcon-80.png
│   │   ├── logo-appIcon-76.png
│   │   ├── logo-appIcon-60.png
│   │   ├── logo-appIcon-58.png
│   │   ├── logo-appIcon-40.png
│   │   ├── logo-appIcon-29.png
│   │   └── logo-appIcon-20.png
│   ├── notification/
│   │   ├── logo-notification-64.png
│   │   ├── logo-notification-48.png
│   │   ├── logo-notification-40.png
│   │   └── logo-notification-24.png
│   └── favicon/
│       ├── logo-favicon-32.png
│       └── logo-favicon-16.png
├── icons/
│   ├── status/
│   │   ├── ok/
│   │   │   ├── icon-status-ok-512.png
│   │   │   ├── icon-status-ok-256.png
│   │   │   ├── icon-status-ok-128.png
│   │   │   └── icon-status-ok-64.png
│   │   ├── busy/
│   │   ├── later/
│   │   └── hug/
│   ├── navigation/
│   │   ├── family/
│   │   ├── settings/
│   │   ├── notifications/
│   │   ├── back/
│   │   └── close/
│   └── action/
│       ├── check/
│       ├── pending/
│       ├── add/
│       └── next/
└── ui-elements/
    ├── status-cards/
    │   ├── ui-status-ok.png
    │   ├── ui-status-busy.png
    │   ├── ui-status-later.png
    │   └── ui-status-hug.png
    ├── buttons/
    │   ├── ui-primary-button.png
    │   ├── ui-success-button.png
    │   ├── ui-secondary-button.png
    │   └── ui-big-button.png
    ├── cards/
    │   ├── ui-contact-card.png
    │   ├── ui-notification-card.png
    │   └── ui-gradient-card.png
    └── inputs/
        ├── ui-text-input.png
        └── ui-search-input.png
```

---

## 🛠️ Скрипт для організації (Windows PowerShell)

### **1. Перейменувати файли (видалити .crdownload):**

```powershell
# Перейти в папку logo
cd "M:\I am OK\logo"

# Перейменувати всі .crdownload файли
Get-ChildItem -Filter "*.crdownload" | ForEach-Object {
    $newName = $_.Name -replace '\.crdownload$', ''
    Rename-Item $_.FullName $newName
}
```

### **2. Організувати файли по папках:**

```powershell
# Створити структуру папок
New-Item -ItemType Directory -Force -Path "..\assets\logo\app-icon"
New-Item -ItemType Directory -Force -Path "..\assets\logo\notification"
New-Item -ItemType Directory -Force -Path "..\assets\logo\favicon"
New-Item -ItemType Directory -Force -Path "..\assets\icons\status\ok"
New-Item -ItemType Directory -Force -Path "..\assets\icons\status\busy"
New-Item -ItemType Directory -Force -Path "..\assets\icons\status\later"
New-Item -ItemType Directory -Force -Path "..\assets\icons\status\hug"
New-Item -ItemType Directory -Force -Path "..\assets\icons\navigation\family"
New-Item -ItemType Directory -Force -Path "..\assets\icons\navigation\settings"
New-Item -ItemType Directory -Force -Path "..\assets\icons\navigation\notifications"
New-Item -ItemType Directory -Force -Path "..\assets\icons\navigation\back"
New-Item -ItemType Directory -Force -Path "..\assets\icons\navigation\close"
New-Item -ItemType Directory -Force -Path "..\assets\icons\action\check"
New-Item -ItemType Directory -Force -Path "..\assets\icons\action\pending"
New-Item -ItemType Directory -Force -Path "..\assets\icons\action\add"
New-Item -ItemType Directory -Force -Path "..\assets\icons\action\next"
New-Item -ItemType Directory -Force -Path "..\assets\ui-elements\status-cards"
New-Item -ItemType Directory -Force -Path "..\assets\ui-elements\buttons"
New-Item -ItemType Directory -Force -Path "..\assets\ui-elements\cards"
New-Item -ItemType Directory -Force -Path "..\assets\ui-elements\inputs"

# Перемістити файли
# Logo
Move-Item "logo-appIcon-*.png" "..\assets\logo\app-icon\" -ErrorAction SilentlyContinue
Move-Item "logo-notification-*.png" "..\assets\logo\notification\" -ErrorAction SilentlyContinue
Move-Item "logo-favicon-*.png" "..\assets\logo\favicon\" -ErrorAction SilentlyContinue

# Icons - Status
Move-Item "icon-status-ok-*.png" "..\assets\icons\status\ok\" -ErrorAction SilentlyContinue
Move-Item "icon-status-busy-*.png" "..\assets\icons\status\busy\" -ErrorAction SilentlyContinue
Move-Item "icon-status-later-*.png" "..\assets\icons\status\later\" -ErrorAction SilentlyContinue
Move-Item "icon-status-hug-*.png" "..\assets\icons\status\hug\" -ErrorAction SilentlyContinue

# Icons - Navigation
Move-Item "icon-navigation-family-*.png" "..\assets\icons\navigation\family\" -ErrorAction SilentlyContinue
Move-Item "icon-navigation-settings-*.png" "..\assets\icons\navigation\settings\" -ErrorAction SilentlyContinue
Move-Item "icon-navigation-notifications-*.png" "..\assets\icons\navigation\notifications\" -ErrorAction SilentlyContinue
Move-Item "icon-navigation-back-*.png" "..\assets\icons\navigation\back\" -ErrorAction SilentlyContinue
Move-Item "icon-navigation-close-*.png" "..\assets\icons\navigation\close\" -ErrorAction SilentlyContinue

# Icons - Action
Move-Item "icon-action-check-*.png" "..\assets\icons\action\check\" -ErrorAction SilentlyContinue
Move-Item "icon-action-pending-*.png" "..\assets\icons\action\pending\" -ErrorAction SilentlyContinue
Move-Item "icon-action-add-*.png" "..\assets\icons\action\add\" -ErrorAction SilentlyContinue
Move-Item "icon-action-next-*.png" "..\assets\icons\action\next\" -ErrorAction SilentlyContinue

# UI Elements
Move-Item "ui-status-*.png" "..\assets\ui-elements\status-cards\" -ErrorAction SilentlyContinue
Move-Item "ui-*-button.png" "..\assets\ui-elements\buttons\" -ErrorAction SilentlyContinue
Move-Item "ui-*-card.png" "..\assets\ui-elements\cards\" -ErrorAction SilentlyContinue
Move-Item "ui-*-input.png" "..\assets\ui-elements\inputs\" -ErrorAction SilentlyContinue
```

---

## ✅ Чек-лист

### **Крок 1: Дочекатися завантаження**
- [ ] Всі файли мають завершити завантаження (без .crdownload)

### **Крок 2: Перейменувати файли**
- [ ] Видалити розширення .crdownload з усіх файлів

### **Крок 3: Організувати структуру**
- [ ] Створити папки assets/logo, assets/icons, assets/ui-elements
- [ ] Перемістити файли у правильні папки

### **Крок 4: Перевірити**
- [ ] Всі файли на місці
- [ ] Правильні назви
- [ ] Правильна структура

---

## 📝 Нотатки

1. **Файли з .crdownload** — це файли, які ще завантажуються
2. **Дочекатися завершення** перед організацією
3. **Backup** — зберегти оригінальні файли перед переміщенням

---

**Готово!** Використай скрипт для автоматичної організації файлів. 🚀
