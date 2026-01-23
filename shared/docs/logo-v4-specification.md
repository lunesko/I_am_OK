# 🎨 Варіант 4: Text Only — Специфікація

## 📋 Опис

**Стиль:** Мінімалістичний текстовий логотип з градієнтом  
**Текст:** "Я ОК"  
**Кольори:** Градієнт від `#0057B7` (синій) до `#34C759` (зелений)

---

## 🎨 Дизайн-специфікація

### **Кольори:**
- **Gradient Start:** `#0057B7` (Primary Blue)
- **Gradient End:** `#34C759` (Success Green)
- **Gradient Direction:** 135deg (діагональ)

### **Типографіка:**
- **Шрифт:** SF Pro Display (iOS) / Roboto (Android)
- **Вага:** 700 (Bold)
- **Letter Spacing:** -1px (для компактності)
- **Line Height:** 1.0 (single line)

### **Розміри:**
- **Великий:** 48px
- **Середній:** 36px
- **Малий:** 24px
- **Дуже малий:** 20px

---

## 📐 Варіанти

### **1. Light Mode (для світлого фону)**
```css
background: linear-gradient(135deg, #0057B7, #34C759);
-webkit-background-clip: text;
-webkit-text-fill-color: transparent;
```

### **2. Dark Mode (для темного фону)**
```css
background: linear-gradient(135deg, #4A90E2, #30D158);
-webkit-background-clip: text;
-webkit-text-fill-color: transparent;
```

### **3. Monochrome (чорно-білий)**
```css
color: #000000; /* для світлого фону */
color: #FFFFFF; /* для темного фону */
```

---

## 📱 Використання

### **Де використовувати:**
- ✅ **Splash Screen** (великий розмір)
- ✅ **Header** (середній розмір)
- ✅ **Onboarding** (великий розмір)
- ✅ **Settings** (малий розмір)
- ✅ **Marketing materials** (будь-який розмір)

### **Де НЕ використовувати:**
- ❌ **App Icon** (потрібен символ)
- ❌ **Notification icon** (занадто малий)
- ❌ **Favicon** (не читабельний)

---

## 🔧 Технічна реалізація

### **Flutter:**
```dart
import 'package:flutter/material.dart';

Widget logoTextOnly({
  double fontSize = 48.0,
  bool isDarkMode = false,
}) {
  return ShaderMask(
    shaderCallback: (bounds) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkMode
          ? [Color(0xFF4A90E2), Color(0xFF30D158)]
          : [Color(0xFF0057B7), Color(0xFF34C759)],
      ).createShader(bounds);
    },
    child: Text(
      'Я ОК',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: Colors.white, // Будь-який колір, shaderMask перезапише
      ),
    ),
  );
}
```

### **CSS:**
```css
.logo-text-only {
  font-size: 48px;
  font-weight: 700;
  letter-spacing: -1px;
  background: linear-gradient(135deg, #0057B7, #34C759);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
```

### **SVG:**
```svg
<svg width="200" height="80" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0057B7;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#34C759;stop-opacity:1" />
    </linearGradient>
  </defs>
  <text x="10" y="60" font-family="SF Pro Display, Roboto, sans-serif" 
        font-size="48" font-weight="700" letter-spacing="-1" 
        fill="url(#gradient)">Я ОК</text>
</svg>
```

---

## 📦 Експорт файлів

### **Розміри для експорту:**

| Розмір | Використання | Формат |
|--------|--------------|--------|
| 512×200 | Splash Screen | PNG @1x, @2x, @3x |
| 256×100 | Header | PNG @1x, @2x |
| 128×50 | Settings | PNG @1x, @2x |
| 64×25 | Compact | PNG @1x |
| SVG | Vector | SVG |

---

## ✅ Переваги цього варіанту

- ✅ **Максимально мінімалістичний**
- ✅ **Легко читабельний**
- ✅ **Працює на будь-якому фоні** (з градієнтом)
- ✅ **Масштабується** (SVG)
- ✅ **Впізнаваний**
- ✅ **Не потребує додаткових елементів**

---

## ⚠️ Обмеження

- ⚠️ **Не працює як app icon** (потрібен символ)
- ⚠️ **Може бути нечитабельним** на дуже малих розмірах (< 20px)
- ⚠️ **Градієнт може не працювати** в деяких контекстах (потрібен fallback)

---

## 🎯 Рекомендації

### **Коли використовувати:**
1. **Splash Screen** — ідеально підходить
2. **Onboarding screens** — відмінно виглядає
3. **Header** — якщо достатньо місця
4. **Marketing** — для презентацій, сайту

### **Коли НЕ використовувати:**
1. **App Icon** — потрібен символ
2. **Notification badge** — занадто малий
3. **Favicon** — не читабельний

---

**Готово!** Використовуй цей варіант для текстових контекстів. 🎨
