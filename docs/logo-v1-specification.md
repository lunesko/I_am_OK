# 🎨 Варіант 1: Monobank Style — Специфікація

## 📋 Опис

**Стиль:** Градієнтний квадрат з закругленими кутами (як Monobank)  
**Форма:** Квадрат з border-radius  
**Кольори:** Градієнт від `#0057B7` (синій) до `#4A90E2` (світло-синій)  
**Символ:** 💚 або простий символ всередині

---

## 🎨 Дизайн-специфікація

### **Кольори:**
- **Gradient Start:** `#0057B7` (Primary Blue)
- **Gradient End:** `#4A90E2` (Primary Blue Light)
- **Gradient Direction:** 135deg (діагональ, top-left → bottom-right)

### **Форма:**
- **Shape:** Квадрат
- **Border Radius:** 30px (для 120×120px)
- **Proportional:** border-radius = 25% від розміру

### **Символ:**
- **Emoji:** 💚 (зелене серце)
- **Альтернатива:** Простий символ "ОК" або галочка ✓
- **Розмір символу:** 50% від розміру іконки

### **Тінь (опціонально):**
- **Color:** `rgba(0, 87, 183, 0.3)`
- **Blur:** 30px
- **Offset:** 0, 10px

---

## 📐 Розміри та пропорції

### **Формула:**
```
border-radius = width × 0.25
symbol-size = width × 0.5
```

### **Розміри для різних контекстів:**

| Контекст | Розмір | Border Radius | Symbol Size |
|----------|--------|---------------|-------------|
| App Icon (1024×1024) | 1024px | 256px | 512px |
| App Icon (512×512) | 512px | 128px | 256px |
| App Icon (192×192) | 192px | 48px | 96px |
| Notification (64×64) | 64px | 16px | 32px |
| Notification (48×48) | 48px | 12px | 24px |
| Favicon (32×32) | 32px | 8px | 16px |
| Favicon (16×16) | 16px | 4px | 8px |

---

## 🎯 Варіанти

### **1. Light Mode (для світлого фону)**
```css
background: linear-gradient(135deg, #0057B7, #4A90E2);
border-radius: 25%;
```

### **2. Dark Mode (для темного фону)**
```css
background: linear-gradient(135deg, #4A90E2, #6BA3F0);
border-radius: 25%;
```

### **3. Monochrome (чорно-білий)**
```css
background: #000000; /* для світлого фону */
background: #FFFFFF; /* для темного фону */
```

---

## 📱 Використання

### **App Icon:**
- ✅ **iOS:** 1024×1024, 512×512, 180×180, 120×120, 87×87, 80×80, 76×76, 60×60, 58×58, 40×40, 29×29, 20×20
- ✅ **Android:** 512×512, 192×192, 144×144, 96×96, 72×72, 48×48, 36×36

### **Notification Badge:**
- ✅ **iOS:** 64×64, 48×48, 40×40
- ✅ **Android:** 64×64, 48×48, 24×24

### **Favicon:**
- ✅ **Web:** 32×32, 16×16
- ✅ **PWA:** 192×192, 512×512

---

## 🔧 Технічна реалізація

### **Flutter:**
```dart
import 'package:flutter/material.dart';

Widget logoMonobankStyle({
  double size = 120.0,
  bool isDarkMode = false,
  String? symbol,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkMode
          ? [Color(0xFF4A90E2), Color(0xFF6BA3F0)]
          : [Color(0xFF0057B7), Color(0xFF4A90E2)],
      ),
      borderRadius: BorderRadius.circular(size * 0.25),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF0057B7).withOpacity(0.3),
          blurRadius: size * 0.25,
          offset: Offset(0, size * 0.08),
        ),
      ],
    ),
    child: Center(
      child: Text(
        symbol ?? '💚',
        style: TextStyle(fontSize: size * 0.5),
      ),
    ),
  );
}
```

### **CSS:**
```css
.logo-monobank {
  width: 120px;
  height: 120px;
  border-radius: 30px;
  background: linear-gradient(135deg, #0057B7, #4A90E2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 60px;
  box-shadow: 0 10px 30px rgba(0, 87, 183, 0.3);
}
```

### **SVG:**
```svg
<svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0057B7;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#4A90E2;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="120" height="120" rx="30" fill="url(#gradient)"/>
  <text x="60" y="75" font-size="60" text-anchor="middle">💚</text>
</svg>
```

---

## 📦 Експорт файлів

### **App Icon розміри:**

#### **iOS:**
- `AppIcon-1024.png` (1024×1024)
- `AppIcon-512.png` (512×512)
- `AppIcon-180.png` (180×180)
- `AppIcon-120.png` (120×120)
- `AppIcon-87.png` (87×87)
- `AppIcon-80.png` (80×80)
- `AppIcon-76.png` (76×76)
- `AppIcon-60.png` (60×60)
- `AppIcon-58.png` (58×58)
- `AppIcon-40.png` (40×40)
- `AppIcon-29.png` (29×29)
- `AppIcon-20.png` (20×20)

#### **Android:**
- `ic_launcher-512.png` (512×512)
- `ic_launcher-192.png` (192×192)
- `ic_launcher-144.png` (144×144)
- `ic_launcher-96.png` (96×96)
- `ic_launcher-72.png` (72×72)
- `ic_launcher-48.png` (48×48)
- `ic_launcher-36.png` (36×36)

### **Notification Badge:**
- `notification-64.png` (64×64)
- `notification-48.png` (48×48)
- `notification-40.png` (40×40)
- `notification-24.png` (24×24)

### **Favicon:**
- `favicon-32.png` (32×32)
- `favicon-16.png` (16×16)
- `favicon.ico` (multi-size)

---

## ✅ Переваги цього варіанту

- ✅ **Впізнаваний** (як Monobank)
- ✅ **Масштабується** (працює від 16×16 до 1024×1024)
- ✅ **Сучасний** (градієнтний стиль)
- ✅ **Працює на будь-якому фоні**
- ✅ **Ідеально для App Icon**

---

## 🎯 Рекомендації

### **Для App Icon:**
- Використовувати символ 💚 (зелене серце)
- Або простий символ "ОК"
- Border radius = 25% від розміру

### **Для Notification:**
- Спростити символ (менше деталей)
- Можна використати тільки градієнт без символу

### **Для Favicon:**
- Мінімальний символ або тільки градієнт
- Перевірити читабельність на 16×16

---

**Готово!** Використовуй цей варіант для App Icon, Notification badge та Favicon. 🎨
