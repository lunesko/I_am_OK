# 🎬 Гайд з анімацій — HTML → Flutter

## 📋 Конвертація анімацій з HTML прототипу в Flutter

Цей гайд показує, як конвертувати всі анімації з `animated-prototype.html` у Flutter-код.

---

## 🎯 Основні анімації

### 1. Screen Transitions (400ms, ease-out)

**HTML:**
```css
transition: all 0.4s cubic-bezier(0.4, 0.0, 0.2, 1);
transform: translateX(100%);
```

**Flutter:**
```dart
import 'package:ya_ok/widgets/screen_transitions.dart';

// Вперед (зліва направо)
Navigator.of(context).pushSlideFromRight(
  MainScreen(),
);

// Назад (справа наліво)
Navigator.of(context).pushSlideFromLeft(
  SettingsScreen(),
);
```

---

### 2. Button Press Animation (scale 0.95)

**HTML:**
```css
.big-btn:active {
    transform: scale(0.95);
}
```

**Flutter:**
```dart
import 'package:ya_ok/widgets/animations.dart';

AppAnimations.animatedButton(
  onPressed: () {
    // Дія
  },
  child: Container(
    // Кнопка
  ),
)
```

---

### 3. Check Bounce Animation (600ms)

**HTML:**
```css
@keyframes checkBounce {
    0% { transform: scale(0); }
    50% { transform: scale(1.2); }
    100% { transform: scale(1); }
}
```

**Flutter:**
```dart
AppAnimations.checkBounceAnimation(
  child: Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      color: AppTheme.successGreen,
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.check, color: Colors.white, size: 60),
  ),
)
```

---

### 4. Staggered List Animation

**HTML:**
```css
.recipient-item:nth-child(1) { animation-delay: 0.1s; }
.recipient-item:nth-child(2) { animation-delay: 0.2s; }
.recipient-item:nth-child(3) { animation-delay: 0.3s; }
```

**Flutter:**
```dart
AppAnimations.staggeredList(
  parentAnimation: _animationController,
  children: [
    RecipientItem(name: 'Мама'),
    RecipientItem(name: 'Оля'),
    RecipientItem(name: 'Сашко'),
  ],
)
```

---

### 5. Pulse Animation (2s infinite)

**HTML:**
```css
@keyframes pulse {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.05); }
}
```

**Flutter:**
```dart
AppAnimations.pulseAnimation(
  child: Container(
    width: 120,
    height: 120,
    decoration: BoxDecoration(
      gradient: AppTheme.primaryGradient,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text('💚', style: TextStyle(fontSize: 56)),
  ),
)
```

---

### 6. Card Hover Animation (slide right 5px)

**HTML:**
```css
.status-card:hover {
    transform: translateX(5px);
}
```

**Flutter:**
```dart
AppAnimations.animatedCard(
  onTap: () {
    // Дія
  },
  child: StatusCard(...),
)
```

---

## 📱 Приклад використання в екрані

### Main Screen з анімаціями:

```dart
class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _selectedStatus = 'ok';
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fadeIn,
      vsync: this,
    )..forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _sendCheckin() {
    // Показати loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: AppAnimations.loadingSpinner(),
      ),
    );
    
    // Після затримки перейти на Success
    Future.delayed(Duration(seconds: 1), () {
      Navigator.of(context).pop(); // Закрити loading
      Navigator.of(context).pushSlideFromRight(
        SuccessScreen(),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Я ОК', style: AppTheme.h1),
        actions: [
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () {
              Navigator.of(context).pushSlideFromRight(
                FamilyScreen(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushSlideFromRight(
                SettingsScreen(),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _controller,
        child: Column(
          children: [
            // Status Cards з анімацією
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(AppTheme.spacing20),
                children: [
                  AppAnimations.animatedCard(
                    onTap: () => setState(() => _selectedStatus = 'ok'),
                    child: StatusCard(
                      status: 'ok',
                      isSelected: _selectedStatus == 'ok',
                    ),
                  ),
                  // ... інші статуси
                ],
              ),
            ),
            
            // Big Button з анімацією
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing20),
              child: AppAnimations.animatedButton(
                onPressed: _sendCheckin,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.successGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  padding: EdgeInsets.all(AppTheme.spacing30),
                  child: Text(
                    'Відправити',
                    style: AppTheme.button,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## ✅ Success Screen з анімаціями:

```dart
class SuccessScreen extends StatefulWidget {
  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fadeIn,
      vsync: this,
    )..forward();
    
    // Автоматичний повернення через 3 секунди
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Я ОК', style: AppTheme.h1),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Check icon з bounce анімацією
            AppAnimations.checkBounceAnimation(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.spacing30),
            
            Text(
              'Відправлено',
              style: AppTheme.h1,
            ),
            
            SizedBox(height: AppTheme.spacing20),
            
            // Staggered list отримувачів
            Container(
              width: 300,
              padding: EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: AppAnimations.staggeredList(
                parentAnimation: _controller,
                children: [
                  RecipientItem(name: 'Мама', hasRead: true),
                  RecipientItem(name: 'Оля', hasRead: true),
                  RecipientItem(name: 'Сашко', hasRead: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎨 Dark Mode перемикач

```dart
class ThemeToggle extends StatefulWidget {
  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle> {
  bool _isDarkMode = false;
  
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    
    // Зберегти в SharedPreferences
    // Застосувати тему через ThemeMode
  }
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
      onPressed: _toggleTheme,
    );
  }
}
```

---

## 📊 Порівняння таймінгу

| Анімація | HTML | Flutter |
|----------|------|---------|
| Screen Transition | 400ms | `AppAnimations.screenTransition` |
| Button Press | 200ms | `AppAnimations.buttonPress` |
| Check Bounce | 600ms | `AppAnimations.checkBounce` |
| Fade In | 500ms | `AppAnimations.fadeIn` |
| Stagger Delay | 100ms | `AppAnimations.staggerDelay` |

---

## 🎯 Performance Tips

### 1. Використовуй `RepaintBoundary`

```dart
RepaintBoundary(
  child: AppAnimations.pulseAnimation(
    child: Logo(),
  ),
)
```

### 2. Обмеж кількість одночасних анімацій

Не запускай більше 3-4 анімацій одночасно.

### 3. Використовуй `AnimatedBuilder` замість `setState`

```dart
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Transform.scale(
      scale: _controller.value,
      child: child,
    );
  },
  child: Button(),
)
```

---

## ✅ Чек-лист імплементації

- [ ] Screen transitions працюють
- [ ] Button press анімації працюють
- [ ] Success check bounce працює
- [ ] Staggered list працює
- [ ] Pulse animation працює
- [ ] Card hover працює
- [ ] Dark Mode перемикається
- [ ] Performance оптимізовано

---

**Готово!** Тепер всі анімації з HTML прототипу доступні у Flutter. 🎬
