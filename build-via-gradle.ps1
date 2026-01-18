# Скрипт для збірки через Gradle напряму
# Використання: .\build-via-gradle.ps1

Write-Host "🔨 Збірка APK через Gradle..." -ForegroundColor Cyan

# Перейти в папку android
Set-Location "M:\I am OK\android"

# Налаштувати Java
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio2\jbr"
Write-Host "Java: $env:JAVA_HOME" -ForegroundColor Green

# Очистити попередні збірки
Write-Host "🧹 Очищення..." -ForegroundColor Yellow
.\gradlew.bat clean

# Зібрати debug APK
Write-Host "📦 Збірка debug APK..." -ForegroundColor Cyan
.\gradlew.bat assembleDebug

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Збірка успішна!" -ForegroundColor Green
    Write-Host "APK знаходиться в: app\build\outputs\apk\debug\app-debug.apk" -ForegroundColor Green
} else {
    Write-Host "❌ Помилка збірки!" -ForegroundColor Red
}

# Повернутися назад
Set-Location "M:\I am OK"
