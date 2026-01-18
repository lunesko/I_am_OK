# 🎬 Імпорт анімацій з HTML прототипу в Figma

## 📋 Як перенести анімації з `animated-prototype.html` у Figma Prototype

---

## 🎯 Крок 1: Створити Frames

1. **Відкрити Figma**
2. **Створити Frames для кожного екрану:**
   - Auth Screen
   - Main Screen
   - Success Screen
   - Family Screen
   - Settings Screen

3. **Розмір:** 375 × 812 (iPhone 13)

---

## 🔗 Крок 2: Налаштувати Prototype Connections

### Connection 1: Auth → Main

```
From: Auth Screen → Button "Увійти через Дія"
To: Main Screen
Trigger: On Click
Animation: Smart Animate
Duration: 400ms
Easing: Ease Out
```

### Connection 2: Main → Success

```
From: Main Screen → Button "Відправити"
To: Success Screen
Trigger: On Click
Animation: Smart Animate
Duration: 400ms
Easing: Ease Out
```

### Connection 3: Main → Family

```
From: Main Screen → Icon "👥"
To: Family Screen
Trigger: On Click
Animation: Smart Animate
Duration: 400ms
Easing: Ease Out
```

### Connection 4: Main → Settings

```
From: Main Screen → Icon "⚙️"
To: Settings Screen
Trigger: On Click
Animation: Smart Animate
Duration: 400ms
Easing: Ease Out
```

### Connection 5: Back Navigation

```
From: Family/Settings → Back Button "←"
To: Main Screen
Trigger: On Click
Animation: Smart Animate
Duration: 400ms
Easing: Ease In
Direction: Reverse
```

---

## 🎨 Крок 3: Налаштувати Smart Animate

### Для Screen Transitions:

1. **Виділити обидва Frames** (поточний та цільовий)
2. **Переконатися, що елементи мають однакові назви:**
   - "Header" → "Header"
   - "Content" → "Content"
   - "Button" → "Button"

3. **Figma автоматично анімує:**
   - Position changes
   - Size changes
   - Opacity changes
   - Color changes

### Приклад:

```
Main Screen:
- Frame "Status Card 1" (x: 20, y: 100)

Success Screen:
- Frame "Status Card 1" (x: 20, y: 200)

Figma автоматично анімує переміщення!
```

---

## ⚡ Крок 4: Додати Interaction States

### Button States:

1. **Створити Variants для кнопки:**
   - Default
   - Pressed (scale: 0.95)
   - Disabled (opacity: 0.5)

2. **Налаштувати Interaction:**
   ```
   On Click → Change to → Pressed
   After delay 200ms → Change to → Default
   ```

### Status Card States:

1. **Створити Variants:**
   - Unselected
   - Selected (border: 2px blue)

2. **Налаштувати Interaction:**
   ```
   On Click → Change to → Selected
   ```

---

## 🎬 Крок 5: Складні анімації

### Success Check Bounce:

1. **Створити 3 Frames:**
   - Frame 1: Scale 0
   - Frame 2: Scale 1.2
   - Frame 3: Scale 1.0

2. **Налаштувати Connections:**
   ```
   Frame 1 → Frame 2 (200ms, Ease Out)
   Frame 2 → Frame 3 (400ms, Ease Out)
   ```

### Staggered List:

1. **Створити окремі Frames для кожного елемента:**
   - Recipient 1 (opacity: 0, x: -20)
   - Recipient 2 (opacity: 0, x: -20)
   - Recipient 3 (opacity: 0, x: -20)

2. **Налаштувати затримки:**
   ```
   Success Screen → Recipient 1 (delay: 100ms)
   Success Screen → Recipient 2 (delay: 200ms)
   Success Screen → Recipient 3 (delay: 300ms)
   ```

---

## 📐 Крок 6: Timing Values

### З HTML прототипу:

| Анімація | Duration | Easing |
|----------|----------|--------|
| Screen Transition | 400ms | Ease Out |
| Button Press | 200ms | Ease Out |
| Check Bounce | 600ms | Ease Out |
| Fade In | 500ms | Ease Out |
| Stagger Delay | 100ms | - |

### У Figma:

1. **Перейти у Prototype mode**
2. **Виділити Connection**
3. **Налаштувати:**
   - Duration: 400ms
   - Easing: Ease Out (cubic-bezier(0.4, 0.0, 0.2, 1))

---

## 🎨 Крок 7: Dark Mode

### Варіант 1: Окремі Frames

1. **Створити дублікати всіх екранів:**
   - Auth Screen Dark
   - Main Screen Dark
   - Success Screen Dark
   - ...

2. **Змінити кольори:**
   - Background: #000000
   - Cards: #1C1C1E
   - Text: #FFFFFF

3. **Налаштувати перемикач:**
   ```
   Settings → Toggle "Dark Mode" → Change to → Dark Theme Frames
   ```

### Варіант 2: Variants (краще)

1. **Створити Variants для кожного компонента:**
   - Theme: Light / Dark

2. **Використовувати Property:**
   ```
   Component: Status Card
   Property: Theme
   Values: Light, Dark
   ```

---

## 📤 Крок 8: Експорт прототипу

1. **Натиснути Present (▶️)**
2. **Share → Copy link**
3. **Відправити розробникам**

**URL формат:**
```
https://www.figma.com/proto/[FILE_ID]/[PROTOTYPE_ID]
```

---

## ✅ Чек-лист

- [ ] Всі екрани створені
- [ ] Всі connections налаштовані
- [ ] Timing відповідає HTML прототипу
- [ ] Smart Animate працює
- [ ] Button states створені
- [ ] Dark Mode налаштовано
- [ ] Прототип протестовано
- [ ] Посилання поділено з командою

---

## 🎯 Поради

1. **Використовуй Auto Layout** для адаптивності
2. **Назви елементів важливі** для Smart Animate
3. **Тестуй на різних пристроях** через Figma Mirror
4. **Експортуй анімації** у Lottie для Flutter

---

**Готово!** Тепер прототип у Figma має такі ж анімації, як HTML версія. 🎬
