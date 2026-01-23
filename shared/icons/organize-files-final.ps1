# Фінальний скрипт для організації файлів
# Запустити: powershell -ExecutionPolicy Bypass -File .\organize-files-final.ps1

param(
    [switch]$Force
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📁 Організація файлів логотипів та асетів" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Поточна папка
$logoDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
Write-Host "📂 Папка з файлами: $logoDir" -ForegroundColor Yellow

# Базова папка для assets
$assetsDir = Join-Path (Split-Path $logoDir -Parent) "assets"
$assetsDir = [System.IO.Path]::GetFullPath($assetsDir)
Write-Host "📦 Assets буде створено в: $assetsDir" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# КРОК 1: Перейменувати .crdownload файли
# ============================================================
Write-Host "Крок 1: Перейменування файлів..." -ForegroundColor Green
$crdownloadFiles = Get-ChildItem -Path $logoDir -Filter "*.crdownload" -ErrorAction SilentlyContinue

if ($crdownloadFiles -and $crdownloadFiles.Count -gt 0) {
    Write-Host "  ⚠️  Знайдено $($crdownloadFiles.Count) файлів з .crdownload" -ForegroundColor Yellow
    Write-Host "  ⚠️  УВАГА: Файли ще завантажуються!" -ForegroundColor Red
    
    if (-not $Force) {
        $continue = Read-Host "  Продовжити? (y/n)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-Host "  ❌ Скасовано." -ForegroundColor Red
            exit
        }
    }
    
    $renamedCount = 0
    foreach ($file in $crdownloadFiles) {
        $newName = $file.Name -replace '\.crdownload$', ''
        try {
            Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
            Write-Host "    ✓ $newName" -ForegroundColor Green
            $renamedCount++
        } catch {
            Write-Host "    ✗ Помилка: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host "  ✅ Перейменовано: $renamedCount файлів" -ForegroundColor Cyan
} else {
    Write-Host "  ✅ Немає файлів з .crdownload" -ForegroundColor Green
}

Write-Host ""

# ============================================================
# КРОК 2: Створити структуру папок
# ============================================================
Write-Host "Крок 2: Створення структури папок..." -ForegroundColor Green

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

$createdCount = 0
foreach ($folder in $folders) {
    $fullPath = Join-Path $assetsDir $folder
    try {
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
            Write-Host "    ✓ Створено: $folder" -ForegroundColor Green
            $createdCount++
        } else {
            Write-Host "    ⊙ Вже існує: $folder" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    ✗ Помилка: $folder - $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Host "  ✅ Створено/перевірено: $createdCount папок" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# КРОК 3: Перемістити файли
# ============================================================
Write-Host "Крок 3: Переміщення файлів..." -ForegroundColor Green

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
$errorCount = 0

foreach ($pattern in $moves.Keys) {
    $files = Get-ChildItem -Path $logoDir -Filter $pattern -ErrorAction SilentlyContinue
    $targetFolder = Join-Path $assetsDir $moves[$pattern]
    
    if ($files) {
        Write-Host "  📦 $pattern -> $($moves[$pattern])" -ForegroundColor Cyan
    }
    
    foreach ($file in $files) {
        try {
            $destination = Join-Path $targetFolder $file.Name
            if (Test-Path $destination) {
                Write-Host "    ⊙ Пропущено (вже існує): $($file.Name)" -ForegroundColor Gray
            } else {
                Move-Item -Path $file.FullName -Destination $targetFolder -ErrorAction Stop
                Write-Host "    ✓ $($file.Name)" -ForegroundColor Green
                $movedCount++
            }
        } catch {
            Write-Host "    ✗ Помилка: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ ГОТОВО!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 Статистика:" -ForegroundColor Yellow
Write-Host "   • Переміщено файлів: $movedCount" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "   • Помилок: $errorCount" -ForegroundColor Red
}
Write-Host "   • Структура: $assetsDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 Наступний крок: Запустити 'flutter pub get'" -ForegroundColor Cyan
Write-Host ""
