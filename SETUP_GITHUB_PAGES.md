# Налаштування GitHub Pages для "Я ОК"

## Крок 1: Створення репозиторію

1. Перейдіть на [GitHub](https://github.com) та створіть новий репозиторій
2. Назва: `yaok-legal` (або будь-яка інша)
3. Оберіть **Public** (для безкоштовного GitHub Pages)
4. Не додавайте README, .gitignore або ліцензію (ми вже їх створили)

## Крок 2: Завантаження файлів

### Варіант 1: Через Git (рекомендовано)

```bash
# Ініціалізуйте репозиторій
git init

# Додайте файли
git add .

# Створіть перший коміт
git commit -m "Add legal documents for Ya OK app"

# Додайте remote репозиторій (замініть YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/yaok-legal.git

# Завантажте файли
git branch -M main
git push -u origin main
```

### Варіант 2: Через веб-інтерфейс GitHub

1. Перейдіть у ваш репозиторій на GitHub
2. Натисніть **"Add file" → "Upload files"**
3. Перетягніть всю папку `docs/` та файл `README.md`
4. Натисніть **"Commit changes"**

## Крок 3: Налаштування GitHub Pages

1. Перейдіть у **Settings** вашого репозиторію
2. У лівому меню знайдіть **Pages**
3. У розділі **Source**:
   - Оберіть **Deploy from a branch**
   - **Branch**: `main` (або `master`)
   - **Folder**: `/docs`
4. Натисніть **Save**

## Крок 4: Очікування публікації

- GitHub Pages зазвичай публікує сайт протягом 1-2 хвилин
- Після публікації ваш сайт буде доступний за адресою:
  ```
  https://YOUR_USERNAME.github.io/yaok-legal/
  ```

## Крок 5: Оновлення URL в коді

Після отримання URL, оновіть посилання в Flutter-коді:

### У файлі `lib/screens/settings_screen.dart`:

```dart
// Замініть YOUR_USERNAME на ваш GitHub username
static const String privacyUrl = 'https://YOUR_USERNAME.github.io/yaok-legal/privacy.html';
static const String termsUrl = 'https://YOUR_USERNAME.github.io/yaok-legal/terms.html';
static const String supportUrl = 'https://YOUR_USERNAME.github.io/yaok-legal/support.html';
```

## Крок 6: Використання в Google Play / App Store

### Google Play Console:

1. Перейдіть у **Store presence → Store listing**
2. У розділі **Privacy Policy** вставте:
   ```
   https://YOUR_USERNAME.github.io/yaok-legal/privacy.html
   ```

### App Store Connect:

1. Перейдіть у **App Information**
2. У полі **Privacy Policy URL** вставте:
   ```
   https://YOUR_USERNAME.github.io/yaok-legal/privacy.html
   ```

## Перевірка

Перевірте, що всі сторінки працюють:

- ✅ `https://YOUR_USERNAME.github.io/yaok-legal/` (головна)
- ✅ `https://YOUR_USERNAME.github.io/yaok-legal/privacy.html`
- ✅ `https://YOUR_USERNAME.github.io/yaok-legal/terms.html`
- ✅ `https://YOUR_USERNAME.github.io/yaok-legal/support.html`

## Оновлення документів

Коли потрібно оновити документи:

```bash
# Внесіть зміни у файли
# ...

# Додайте зміни
git add .

# Створіть коміт
git commit -m "Update privacy policy"

# Завантажте зміни
git push
```

GitHub Pages автоматично оновить сайт протягом кількох хвилин.

## Альтернативні варіанти хостингу

Якщо не хочете використовувати GitHub Pages:

### Netlify (безкоштовно)
1. Зареєструйтесь на [netlify.com](https://netlify.com)
2. Перетягніть папку `docs/` у Netlify
3. Отримаєте URL: `https://yaok-legal.netlify.app`

### Vercel (безкоштовно)
1. Зареєструйтесь на [vercel.com](https://vercel.com)
2. Підключіть GitHub репозиторій
3. Вкажіть папку `docs/` як root
4. Отримаєте URL: `https://yaok-legal.vercel.app`

### Власний домен (рекомендовано для продакшену)
1. Купіть домен (наприклад, `poruch.app`)
2. Налаштуйте DNS для GitHub Pages або Netlify
3. Використовуйте: `https://poruch.app/privacy.html`

---

**Готово!** Тепер ваші документи доступні онлайн та готові для використання в додатку та сторов. 🚀
