# Спрощений скрипт для організації файлів
# Запустити: powershell -ExecutionPolicy Bypass -File .\organize-files-simple.ps1

$ErrorActionPreference = "Continue"

Write-Host "📁 Організація файлів..." -ForegroundColor Cyan

# Поточна папка
$logoDir = $PSScriptRoot
if (-not $logoDir) {
    $logoDir = Get-Location
}

Write-Host "Папка: $logoDir" -ForegroundColor Yellow

# Базова папка для assets
$assetsDir = Join-Path $logoDir ".." "assets"
$assetsDir = [System.IO.Path]::GetFullPath($assetsDir)

Write-Host "Assets буде створено в: $assetsDir" -ForegroundColor Yellow

# Крок 1: Перейменувати .crdownload файли
Write-Host "`nКрок 1: Перейменування файлів..." -ForegroundColor Green
$crdownloadFiles = Get-ChildItem -Path $logoDir -Filter "*.crdownload" -ErrorAction SilentlyContinue

if ($crdownloadFiles) {
    Write-Host "Знайдено $($crdownloadFiles.Count) файлів з .crdownload" -ForegroundColor Yellow
    Write-Host "⚠️  УВАГА: Файли ще завантажуються!" -ForegroundColor Red
    $continue = Read-Host "Продовжити? (y/n)"
    if ($continue -ne "y") {
        Write-Host "Скасовано." -ForegroundColor Red
        exit
    }
    
    foreach ($file in $crdownloadFiles) {
        $newName = $file.Name -replace '\.crdownload$', ''
        try {
            Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
            Write-Host "  ✓ $newName" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Помилка: $($file.Name)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ✓ Немає файлів з .crdownload" -ForegroundColor Green
}

# Крок 2: Створити папки
Write-Host "`nКрок 2: Створення папок..." -ForegroundColor Green

$folders = @(
    "logo\app-icon",
    "logo\notification",
    "logo\favicon",
    "icons\status\ok",
    "icons\status\busy",
    "icons\status\later",
    "icons\status\hug",
    "icons\navigation\family",
    "icons\navigation\settings",
    "icons\navigation\notifications",
    "icons\navigation\back",
    "icons\navigation\close",
    "icons\action\check",
    "icons\action\pending",
    "icons\action\add",
    "icons\action\next",
    "ui-elements\status-cards",
    "ui-elements\buttons",
    "ui-elements\cards",
    "ui-elements\inputs"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path $assetsDir $folder
    try {
        New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
        Write-Host "  ✓ $folder" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ $folder" -ForegroundColor Red
    }
}

# Крок 3: Перемістити файли
Write-Host "`nКрок 3: Переміщення файлів..." -ForegroundColor Green

$moves = @{
    "logo-appIcon-*.png" = "logo\app-icon"
    "logo-notification-*.png" = "logo\notification"
    "logo-favicon-*.png" = "logo\favicon"
    "icon-status-ok-*.png" = "icons\status\ok"
    "icon-status-busy-*.png" = "icons\status\busy"
    "icon-status-later-*.png" = "icons\status\later"
    "icon-status-hug-*.png" = "icons\status\hug"
    "icon-navigation-family-*.png" = "icons\navigation\family"
    "icon-navigation-settings-*.png" = "icons\navigation\settings"
    "icon-navigation-notifications-*.png" = "icons\navigation\notifications"
    "icon-navigation-back-*.png" = "icons\navigation\back"
    "icon-navigation-close-*.png" = "icons\navigation\close"
    "icon-action-check-*.png" = "icons\action\check"
    "icon-action-pending-*.png" = "icons\action\pending"
    "icon-action-add-*.png" = "icons\action\add"
    "icon-action-next-*.png" = "icons\action\next"
    "ui-status-*.png" = "ui-elements\status-cards"
    "ui-*-button.png" = "ui-elements\buttons"
    "ui-*-card.png" = "ui-elements\cards"
    "ui-*-input.png" = "ui-elements\inputs"
}

$movedCount = 0
foreach ($pattern in $moves.Keys) {
    $files = Get-ChildItem -Path $logoDir -Filter $pattern -ErrorAction SilentlyContinue
    $targetFolder = Join-Path $assetsDir $moves[$pattern]
    
    foreach ($file in $files) {
        try {
            Move-Item -Path $file.FullName -Destination $targetFolder -ErrorAction Stop
            Write-Host "  ✓ $($file.Name)" -ForegroundColor Green
            $movedCount++
        } catch {
            Write-Host "  ✗ $($file.Name)" -ForegroundColor Red
        }
    }
}

Write-Host "`n✅ Готово! Переміщено $movedCount файлів." -ForegroundColor Cyan
Write-Host "📁 Структура: $assetsDir" -ForegroundColor Yellow
