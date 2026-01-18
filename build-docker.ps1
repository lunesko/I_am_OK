# PowerShell скрипт для збірки через Docker

Write-Host "Збірка Flutter проекту через Docker..." -ForegroundColor Cyan

# Перевірити чи встановлений Docker
try {
    docker --version | Out-Null
    Write-Host "Docker знайдено" -ForegroundColor Green
} catch {
    Write-Host "Docker не встановлений!" -ForegroundColor Red
    Write-Host "Встановіть Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Створити директорію для виводу
if (-not (Test-Path "build\outputs")) {
    New-Item -ItemType Directory -Path "build\outputs" -Force | Out-Null
    Write-Host "Створено директорію build\outputs" -ForegroundColor Green
}

# Перевірити чи запущений Docker
try {
    docker ps | Out-Null
    Write-Host "Docker запущений" -ForegroundColor Green
} catch {
    Write-Host "Docker не запущений!" -ForegroundColor Red
    Write-Host "Запустіть Docker Desktop" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Початок збірки..." -ForegroundColor Cyan

# Зібрати через Docker Compose
try {
    docker-compose up --build
    
    if (Test-Path "build\outputs\app-release.apk") {
        $apkSize = (Get-Item "build\outputs\app-release.apk").Length / 1MB
        Write-Host ""
        Write-Host "APK успішно зібрано!" -ForegroundColor Green
        Write-Host "Файл: build\outputs\app-release.apk" -ForegroundColor Cyan
        Write-Host "Розмір: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "APK не знайдено в build\outputs\" -ForegroundColor Yellow
        Write-Host "Перевірте логи вище" -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host "Помилка збірки!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Готово!" -ForegroundColor Green
