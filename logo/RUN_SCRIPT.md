# 🚀 Як запустити скрипт організації

## ⚠️ Якщо помилка ExecutionPolicy

### **Проблема:**
```
cannot be loaded because running scripts is disabled on this system
```

### **Рішення:**

#### **Варіант 1: Для поточного сеансу (рекомендовано)**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

#### **Варіант 2: Для поточного користувача**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### **Варіант 3: Запустити без зміни політики**
```powershell
powershell -ExecutionPolicy Bypass -File .\organize-files.ps1
```

---

## ✅ Правильний спосіб запуску

### **Крок 1: Відкрити PowerShell**
- Натисни `Win + X`
- Вибери "Windows PowerShell" або "Terminal"

### **Крок 2: Перейти в папку**
```powershell
cd "M:\I am OK\logo"
```

### **Крок 3: Запустити скрипт**
```powershell
.\organize-files.ps1
```

---

## 🔧 Альтернативний спосіб (якщо скрипт не працює)

### **Вручну через PowerShell:**

```powershell
# 1. Перейти в папку
cd "M:\I am OK\logo"

# 2. Перейменувати файли
Get-ChildItem -Filter "*.crdownload" | ForEach-Object {
    $newName = $_.Name -replace '\.crdownload$', ''
    Rename-Item $_.FullName $newName
}

# 3. Створити структуру
$basePath = "M:\I am OK\assets"
New-Item -ItemType Directory -Force -Path "$basePath\logo\app-icon"
New-Item -ItemType Directory -Force -Path "$basePath\logo\notification"
New-Item -ItemType Directory -Force -Path "$basePath\logo\favicon"
# ... (інші папки)

# 4. Перемістити файли
Move-Item "logo-appIcon-*.png" "$basePath\logo\app-icon\"
Move-Item "logo-notification-*.png" "$basePath\logo\notification\"
# ... (інші файли)
```

---

## 📝 Нотатки

1. **ExecutionPolicy** — це захист Windows від небезпечних скриптів
2. **RemoteSigned** — дозволяє запускати локальні скрипти
3. **Bypass** — тимчасово вимикає перевірку (тільки для поточного сеансу)

---

**Готово!** Використай один з способів вище. 🚀
