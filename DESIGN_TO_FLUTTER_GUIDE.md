# 🎨 Design to Flutter — Гайд для розробників

## 📐 Конвертація з Figma макету в Flutter код

Цей гайд допоможе швидко конвертувати дизайн з `figma-design-mockup.html` у Flutter-код.

---

## 🎨 Кольори

### Використання в коді:

```dart
import 'package:ya_ok/theme/app_theme.dart';

// Primary
Container(color: AppTheme.primaryBlue) // #0057B7

// Success
Container(color: AppTheme.successGreen) // #34C759

// Background
Scaffold(backgroundColor: AppTheme.backgroundGray) // #F5F5F7
```

### Всі кольори:

| Назва | Hex | Flutter |
|-------|-----|---------|
| Primary Blue | `#0057B7` | `AppTheme.primaryBlue` |
| Success Green | `#34C759` | `AppTheme.successGreen` |
| Warning Yellow | `#FFCC00` | `AppTheme.warningYellow` |
| Alert Orange | `#FF9500` | `AppTheme.alertOrange` |
| Background | `#F5F5F7` | `AppTheme.backgroundGray` |
| Card White | `#FFFFFF` | `AppTheme.cardWhite` |
| Text Primary | `#3C3C43` | `AppTheme.textPrimary` |
| Text Secondary | `#8E8E93` | `AppTheme.textSecondary` |

---

## 📏 Spacing System (8px grid)

### Використання:

```dart
Padding(
  padding: EdgeInsets.all(AppTheme.spacing20), // 20px
  child: Text('Content'),
)

SizedBox(height: AppTheme.spacing12) // 12px gap
```

### Всі значення:

| Значення | Flutter |
|----------|---------|
| 4px | `AppTheme.spacing4` |
| 8px | `AppTheme.spacing8` |
| 12px | `AppTheme.spacing12` |
| 16px | `AppTheme.spacing16` |
| 20px | `AppTheme.spacing20` |
| 24px | `AppTheme.spacing24` |
| 30px | `AppTheme.spacing30` |
| 40px | `AppTheme.spacing40` |

---

## 🔤 Типографіка

### Використання:

```dart
Text('Я ОК', style: AppTheme.h1) // Screen Title
Text('Зворотній зв\'язок', style: AppTheme.h2) // Card Title
Text('Текст', style: AppTheme.body) // Regular
Text('Підпис', style: AppTheme.caption) // Secondary
```

### Всі стилі:

| Стиль | Розмір | Weight | Flutter |
|-------|--------|--------|---------|
| H1 | 28px | 700 | `AppTheme.h1` |
| H2 | 20px | 600 | `AppTheme.h2` |
| Body | 17px | 400 | `AppTheme.body` |
| Caption | 14px | 400 | `AppTheme.caption` |
| Button | 17px | 600 | `AppTheme.button` |

---

## 🔲 Border Radius

### Використання:

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppTheme.radiusLarge), // 20px
  ),
)
```

### Всі значення:

| Значення | Flutter |
|----------|---------|
| 12px | `AppTheme.radiusSmall` |
| 16px | `AppTheme.radiusMedium` |
| 20px | `AppTheme.radiusLarge` |
| 30px | `AppTheme.radiusXLarge` |
| 50px | `AppTheme.radiusRound` |

---

## 🎭 Компоненти

### 1. Status Card

```dart
Container(
  decoration: BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
    boxShadow: AppTheme.cardShadow,
  ),
  padding: EdgeInsets.all(AppTheme.spacing16),
  child: Row(
    children: [
      Text('💚', style: TextStyle(fontSize: 28)),
      SizedBox(width: AppTheme.spacing12),
      Expanded(
        child: Text('Я ОК', style: AppTheme.body),
      ),
      Icon(Icons.check, color: AppTheme.primaryBlue),
    ],
  ),
)
```

### 2. Big Button (Primary)

```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.successGradient,
    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
    boxShadow: AppTheme.buttonShadow,
  ),
  padding: EdgeInsets.symmetric(
    horizontal: AppTheme.spacing30,
    vertical: AppTheme.spacing30,
  ),
  child: Text(
    'Відправити',
    style: AppTheme.button,
    textAlign: TextAlign.center,
  ),
)
```

### 3. Contact Item

```dart
Container(
  decoration: BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
  ),
  padding: EdgeInsets.all(AppTheme.spacing16),
  child: Row(
    children: [
      // Avatar
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppTheme.successGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Center(
          child: Text('М', style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          )),
        ),
      ),
      SizedBox(width: AppTheme.spacing16),
      // Info
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Мама', style: AppTheme.body.copyWith(
              fontWeight: FontWeight.w600,
            )),
            Text('2 год тому', style: AppTheme.caption),
          ],
        ),
      ),
      // Status
      Icon(Icons.check, color: AppTheme.successGreen),
    ],
  ),
)
```

### 4. Gradient Card

```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.primaryGradient,
    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
  ),
  padding: EdgeInsets.all(AppTheme.spacing24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('❤️', style: TextStyle(fontSize: 32)),
      SizedBox(height: AppTheme.spacing10),
      Text('Зворотній зв\'язок', style: AppTheme.h2.copyWith(
        color: Colors.white,
      )),
      SizedBox(height: AppTheme.spacing10),
      Text(
        'Твої близькі теж можуть надіслати тобі швидке повідомлення',
        style: AppTheme.body.copyWith(
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      SizedBox(height: AppTheme.spacing20),
      // White Button
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        padding: EdgeInsets.all(AppTheme.spacing14),
        child: Text(
          'Надіслати "Вдома все добре"',
          style: AppTheme.button.copyWith(
            color: AppTheme.primaryBlue,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  ),
)
```

---

## 📱 Екрани — Розміри та структура

### Загальна структура екрану:

```dart
Scaffold(
  backgroundColor: AppTheme.backgroundGray,
  appBar: AppBar(
    title: Text('Я ОК', style: AppTheme.h1),
    actions: [
      IconButton(icon: Icon(Icons.people), onPressed: () {}),
      IconButton(icon: Icon(Icons.settings), onPressed: () {}),
    ],
  ),
  body: Padding(
    padding: EdgeInsets.all(AppTheme.spacing20),
    child: Column(
      children: [
        // Content
      ],
    ),
  ),
  bottomNavigationBar: Container(
    padding: EdgeInsets.all(AppTheme.spacing20),
    decoration: BoxDecoration(
      color: AppTheme.cardWhite,
      border: Border(
        top: BorderSide(color: AppTheme.borderLight),
      ),
    ),
    child: Text(
      '🛡️ Геолокація вимкнена. Не використовуй біля позицій.',
      style: AppTheme.caption,
      textAlign: TextAlign.center,
    ),
  ),
)
```

---

## 🎬 Анімації

### Використання:

```dart
AnimatedContainer(
  duration: AppTheme.animationDuration,
  curve: AppTheme.animationCurve,
  // properties
)
```

### Значення:

- **Duration:** 300ms
- **Curve:** `Curves.easeOut`

---

## 🎨 Градієнти

### Використання:

```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.primaryGradient, // Blue
    // або
    gradient: AppTheme.successGradient, // Green
    // або
    gradient: AppTheme.donateGradient, // Blue to Yellow
  ),
)
```

---

## 📐 Responsive Design

### Breakpoints:

```dart
// Маленькі екрани (< 375px)
if (MediaQuery.of(context).size.width < 375) {
  // Зменшити padding
  padding = AppTheme.spacing16;
}

// Великі екрани (> 414px)
if (MediaQuery.of(context).size.width > 414) {
  // Збільшити max-width контенту
  maxWidth = 500;
}
```

---

## 🧩 Готові Widget-и

### 1. StatusCard Widget

```dart
class StatusCard extends StatelessWidget {
  final String status;
  final bool isSelected;
  final VoidCallback onTap;
  
  const StatusCard({
    required this.status,
    this.isSelected = false,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
          border: isSelected 
            ? Border.all(color: AppTheme.primaryBlue, width: 2)
            : null,
        ),
        padding: EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            Text(
              AppTheme.getStatusEmoji(status),
              style: TextStyle(fontSize: 28),
            ),
            SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Text(
                AppTheme.getStatusText(status),
                style: AppTheme.body,
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: AppTheme.primaryBlue),
          ],
        ),
      ),
    );
  }
}
```

### 2. BigButton Widget

```dart
class BigButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;
  
  const BigButton({
    required this.text,
    required this.onPressed,
    this.gradient,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient ?? AppTheme.successGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: AppTheme.buttonShadow,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing30,
          vertical: AppTheme.spacing30,
        ),
        child: Text(
          text,
          style: AppTheme.button,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
```

---

## ✅ Чек-лист конвертації

- [ ] Всі кольори використовують `AppTheme`
- [ ] Всі відступи використовують spacing константи
- [ ] Всі border radius використовують radius константи
- [ ] Всі тексти використовують text styles
- [ ] Тіні використовують shadow константи
- [ ] Градієнти використовують gradient константи
- [ ] Анімації використовують duration/curve константи

---

## 🚀 Швидкий старт

1. **Імпортувати theme:**
   ```dart
   import 'package:ya_ok/theme/app_theme.dart';
   ```

2. **Використовувати в MaterialApp:**
   ```dart
   MaterialApp(
     theme: AppTheme.lightTheme,
     // ...
   )
   ```

3. **Використовувати компоненти:**
   ```dart
   StatusCard(
     status: 'ok',
     isSelected: true,
     onTap: () {},
   )
   ```

---

**Готово!** Тепер дизайн з Figma легко конвертується в Flutter-код. 🎨
