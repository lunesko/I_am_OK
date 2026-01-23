# PowerShell скрипт для організації файлів
# Запустити: .\organize-files.ps1
# Якщо помилка ExecutionPolicy: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Перевірка ExecutionPolicy
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Host "⚠️  ExecutionPolicy обмежений. Запусти:" -ForegroundColor Yellow
    Write-Host "   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Cyan
    exit
}

Write-Host "📁 Організація файлів логотипів та асетів..." -ForegroundColor Cyan

# Перейти в поточну папку
$currentDir = Get-Location
Write-Host "Поточна папка: $currentDir" -ForegroundColor Yellow

# Крок 1: Перейменувати файли (видалити .crdownload)
Write-Host "`nКрок 1: Перейменування файлів..." -ForegroundColor Green
$crdownloadFiles = Get-ChildItem -Filter "*.crdownload" -ErrorAction SilentlyContinue

if ($crdownloadFiles.Count -gt 0) {
    Write-Host "Знайдено $($crdownloadFiles.Count) файлів з .crdownload" -ForegroundColor Yellow
    Write-Host "⚠️  УВАГА: Файли ще завантажуються! Дочекайся завершення." -ForegroundColor Red
    $continue = Read-Host "Продовжити? (y/n)"
    if ($continue -ne "y") {
        Write-Host "Скасовано." -ForegroundColor Red
        exit
    }
    
    foreach ($file in $crdownloadFiles) {
        $newName = $file.Name -replace '\.crdownload$', ''
        try {
            Rename-Item $file.FullName $newName -ErrorAction Stop
            Write-Host "  ✓ $($file.Name) -> $newName" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Помилка: $($file.Name)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ✓ Немає файлів з .crdownload" -ForegroundColor Green
}

# Крок 2: Створити структуру папок
Write-Host "`nКрок 2: Створення структури папок..." -ForegroundColor Green
$basePath = Join-Path $currentDir ".." "assets"

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
    $fullPath = Join-Path $basePath $folder
    try {
        New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
        Write-Host "  ✓ Створено: $folder" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Помилка створення: $folder" -ForegroundColor Red
    }
}

# Крок 3: Перемістити файли
Write-Host "`nКрок 3: Переміщення файлів..." -ForegroundColor Green

# Logo files
$logoMoves = @{
    "logo-appIcon-*.png" = "logo\app-icon"
    "logo-notification-*.png" = "logo\notification"
    "logo-favicon-*.png" = "logo\favicon"
}

# Icon files
$iconMoves = @{
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
}

# UI Elements
$uiMoves = @{
    "ui-status-*.png" = "ui-elements\status-cards"
    "ui-*-button.png" = "ui-elements\buttons"
    "ui-*-card.png" = "ui-elements\cards"
    "ui-*-input.png" = "ui-elements\inputs"
}

# Об'єднати всі переміщення
$allMoves = $logoMoves + $iconMoves + $uiMoves

$movedCount = 0
foreach ($pattern in $allMoves.Keys) {
    $files = Get-ChildItem -Filter $pattern -ErrorAction SilentlyContinue
    $targetFolder = Join-Path $basePath $allMoves[$pattern]
    
    foreach ($file in $files) {
        try {
            Move-Item $file.FullName $targetFolder -ErrorAction Stop
            Write-Host "  ✓ Переміщено: $($file.Name) -> $($allMoves[$pattern])" -ForegroundColor Green
            $movedCount++
        } catch {
            Write-Host "  ✗ Помилка: $($file.Name)" -ForegroundColor Red
        }
    }
}

Write-Host "`n✅ Готово! Переміщено $movedCount файлів." -ForegroundColor Cyan
Write-Host "📁 Структура створена в: $basePath" -ForegroundColor Yellow
