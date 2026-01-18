# 📐 Figma Export Guide — Як експортувати дизайн

## 🎯 Мета

Цей гайд допоможе експортувати дизайн з `figma-design-mockup.html` у Figma та підготувати для розробки.

---

## 📥 Варіант 1: Імпорт скріншотів (швидкий)

### Крок 1: Зробити скріншоти

1. Відкрити `docs/figma-design-mockup.html` у браузері
2. Натиснути F11 (повноекранний режим)
3. Зробити скріншоти кожного екрану:
   - `01-auth.png`
   - `02-main.png`
   - `03-success.png`
   - `04-family.png`
   - `05-settings.png`

### Крок 2: Імпорт у Figma

1. Відкрити Figma → Create new file
2. Drag & Drop скріншоти на canvas
3. Обрізати до розміру екрану (375×812)
4. Використовувати як референс

---

## 🎨 Варіант 2: Створити з нуля (професійний)

### Крок 1: Налаштування файлу

1. **Створити новий файл** у Figma
2. **Створити Frame:**
   - Назва: "iPhone 13"
   - Розмір: `375 × 812`
   - Background: `#F5F5F7`

3. **Налаштувати Grid:**
   - Layout Grid → Columns: 20px
   - Layout Grid → Rows: 8px
   - Opacity: 20%

### Крок 2: Створити Color Styles

1. **Перейти у Design → Styles**
2. **Створити Color Styles:**

```
Primary Blue: #0057B7
Success Green: #34C759
Warning Yellow: #FFCC00
Alert Orange: #FF9500
Background: #F5F5F7
Card White: #FFFFFF
Text Primary: #3C3C43
Text Secondary: #8E8E93
```

### Крок 3: Створити Text Styles

1. **Перейти у Design → Text Styles**
2. **Створити стилі:**

```
H1 - Screen Title
- Font: SF Pro Display / Roboto
- Size: 28px
- Weight: 700
- Color: Text Primary

H2 - Card Title
- Font: SF Pro Display / Roboto
- Size: 20px
- Weight: 600
- Color: Text Primary

Body - Regular
- Font: SF Pro Display / Roboto
- Size: 17px
- Weight: 400
- Color: Text Primary
- Line Height: 1.4

Caption - Secondary
- Font: SF Pro Display / Roboto
- Size: 14px
- Weight: 400
- Color: Text Secondary
- Line Height: 1.3

Button - Action
- Font: SF Pro Display / Roboto
- Size: 17px
- Weight: 600
- Color: White
```

### Крок 4: Створити компоненти

#### 1. Status Card Component

```
Frame: Status Card
- Width: 335px (375 - 20*2)
- Height: Auto
- Padding: 16px
- Background: Card White
- Border Radius: 20px
- Shadow: 0px 2px 10px rgba(0,0,0,0.05)

Content:
- Emoji: 28px
- Text: Body style
- Check icon: 24px, Primary Blue
```

#### 2. Big Button Component

```
Frame: Big Button
- Width: 335px
- Height: Auto
- Padding: 30px
- Background: Gradient (Green)
- Border Radius: 30px
- Shadow: 0px 10px 30px rgba(52,199,89,0.3)

Text:
- Style: Button
- Color: White
- Align: Center
```

#### 3. Contact Item Component

```
Frame: Contact Item
- Width: 335px
- Height: Auto
- Padding: 16px
- Background: Card White
- Border Radius: 16px

Content:
- Avatar: 48×48px, Gradient Green, Radius 12px
- Name: Body, Weight 600
- Time: Caption
- Status icon: 20px, Success Green
```

### Крок 5: Створити екрани

#### Екран 1: Auth Screen

```
Frame: Auth Screen (375×812)
- Background: #F5F5F7

Content:
- Logo: 120×120px, Gradient Blue, Radius 30px
- Title: "Я ОК", H1
- Subtitle: "Один дотик — спокій для близьких", Caption
- Button 1: "Увійти через Дія", Dark, 300px width
- Button 2: "Увійти через BankID", White, 300px width
- Footer: "Без реєстрації...", Caption, centered
```

#### Екран 2: Main Screen

```
Frame: Main Screen (375×812)
- Background: #F5F5F7

Header:
- Title: "Я ОК", H1
- Icons: People, Settings (40×40px)

Content:
- Status Cards (4 штуки)
- Big Button: "Відправити"
- Last checkin: Caption, centered

Footer:
- Warning: "🛡️ Геолокація вимкнена...", Caption
```

---

## 📤 Експорт для розробників

### Крок 1: Експорт скріншотів

1. **Виділити Frame** з екраном
2. **Right Click → Export**
3. **Налаштування:**
   - Format: PNG
   - Size: 2x (750×1624)
   - Include "id" in export names: ON

4. **Експортувати:**
   - `01-auth@2x.png`
   - `02-main@2x.png`
   - `03-success@2x.png`
   - `04-family@2x.png`
   - `05-settings@2x.png`

### Крок 2: Експорт іконок

1. **Виділити іконку**
2. **Right Click → Export**
3. **Налаштування:**
   - Format: SVG
   - Include "id": ON

### Крок 3: Експорт assets

1. **Перейти у Assets panel**
2. **Виділити всі компоненти**
3. **Right Click → Export Selection**
4. **Format:** SVG або PNG @2x

---

## 🔗 Створення прототипу

### Крок 1: З'єднати екрани

1. **Перейти у Prototype mode** (▶️)
2. **Виділити елемент** (наприклад, кнопку)
3. **Перетягнути стрілку** до цільового екрану
4. **Налаштувати анімацію:**
   - Interaction: On Click
   - Animation: Smart Animate
   - Duration: 300ms
   - Easing: Ease Out

### Крок 2: Зв'язки між екранами

```
Auth Screen
  └─ Button "Увійти через Дія" → Main Screen

Main Screen
  ├─ Icon "People" → Family Screen
  ├─ Icon "Settings" → Settings Screen
  └─ Button "Відправити" → Success Screen

Success Screen
  └─ Auto return → Main Screen (через 3 сек)

Family Screen
  └─ Back button → Main Screen

Settings Screen
  └─ Back button → Main Screen
```

### Крок 3: Презентація

1. **Натиснути Present (▶️)**
2. **Share → Copy link**
3. **Відправити розробникам**

---

## 📋 Design Specs для розробників

### Створити Design Specs:

1. **Виділити елемент**
2. **Right Panel → Inspect**
3. **Показати:**
   - Розміри
   - Кольори
   - Відступи
   - Шрифти
   - Тіні

### Експорт CSS (для веб) або Flutter:

Figma автоматично генерує CSS/Flutter код у Inspect panel.

---

## 🎨 Додаткові поради

### 1. Auto Layout

Використовуй **Auto Layout** для всіх компонентів:
- Відступи автоматично адаптуються
- Легко змінювати розміри
- Краще для responsive design

### 2. Variants

Створи **Variants** для компонентів:
- Status Card: selected / unselected
- Button: normal / pressed / disabled
- Contact Item: read / unread

### 3. Constraints

Налаштуй **Constraints** для адаптивності:
- Left & Right для горизонтального центрування
- Top & Bottom для вертикального центрування

### 4. Components Library

Створи **Components Library**:
- Використовуй у всіх екранах
- Оновлення автоматично застосуються
- Легше підтримувати

---

## ✅ Чек-лист перед експортом

- [ ] Всі кольори створені як Styles
- [ ] Всі тексти створені як Text Styles
- [ ] Всі компоненти створені як Components
- [ ] Всі екрани мають правильні розміри (375×812)
- [ ] Прототип з'єднаний та працює
- [ ] Скріншоти експортовані @2x
- [ ] Іконки експортовані у SVG
- [ ] Design Specs доступні для розробників

---

## 🚀 Готово!

Тепер дизайн готовий для:
- ✅ Презентації стейкхолдерам
- ✅ Передачі розробникам
- ✅ Імпорту в Flutter
- ✅ Створення інтерактивного прототипу

---

**Порада:** Використовуй `DESIGN_TO_FLUTTER_GUIDE.md` для конвертації дизайну в Flutter-код.
