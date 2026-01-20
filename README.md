# Я ОК — Документація та правові документи

Цей репозиторій містить правові документи та документацію для додатку "Я ОК" від студії Poruch.

## 📁 Структура

```
docs/
├── index.html          # Головна сторінка документації
├── privacy.html        # Політика конфіденційності
├── terms.html          # Умови використання
├── support.html        # Сторінка підтримки
└── .nojekyll           # Файл для GitHub Pages
```

## 🌐 GitHub Pages

Документи налаштовані для публікації через GitHub Pages.

### Налаштування GitHub Pages:

1. Перейдіть у **Settings** репозиторію
2. У розділі **Pages** оберіть:
   - **Source**: Deploy from a branch
   - **Branch**: `main` (або `master`)
   - **Folder**: `/docs`
3. Збережіть зміни

### URL після публікації:

- Головна: `https://yourusername.github.io/yaok-legal/`
- Privacy: `https://yourusername.github.io/yaok-legal/privacy.html`
- Terms: `https://yourusername.github.io/yaok-legal/terms.html`
- Support: `https://yourusername.github.io/yaok-legal/support.html`

## 📝 Використання в додатку

### Flutter

```dart
import 'package:url_launcher/url_launcher.dart';

// Відкрити політику конфіденційності
TextButton(
  child: Text('Політика конфіденційності'),
  onPressed: () async {
    final url = Uri.parse('https://yourusername.github.io/yaok-legal/privacy.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
),

// Відкрити умови використання
TextButton(
  child: Text('Умови використання'),
  onPressed: () async {
    final url = Uri.parse('https://yourusername.github.io/yaok-legal/terms.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
),

// Відкрити сторінку підтримки
TextButton(
  child: Text('Підтримка'),
  onPressed: () async {
    final url = Uri.parse('https://yourusername.github.io/yaok-legal/support.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
),
```

### Додати залежність в `pubspec.yaml`:

```yaml
dependencies:
  url_launcher: ^6.2.0
```

## 🔗 Посилання для Google Play / App Store

Після публікації на GitHub Pages, використовуйте ці URL в формах:

- **Privacy Policy URL**: `https://yourusername.github.io/yaok-legal/privacy.html`
- **Terms of Use URL**: `https://yourusername.github.io/yaok-legal/terms.html`
- **Support URL**: `https://yourusername.github.io/yaok-legal/support.html`

## 📧 Контакти

- **Email**: poruch.app@gmail.com
- **GitHub**: https://github.com/lunesko
- **Google Play Console**: Poruch_WEB_Studio

## 📄 Ліцензія

© 2026 Poruch. Всі права захищені.

---

**Зроблено в Україні 🇺🇦**
