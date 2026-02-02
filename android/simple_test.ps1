# Ya OK Android App - Simple Functional Test

$pkg = "app.poruch.ya_ok"
$activity = "$pkg/.MainActivity"

Write-Host "=== Ya OK App Test ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Installation
Write-Host "[1] Checking installation..." -ForegroundColor Yellow
$inst = adb shell pm list packages | Select-String $pkg
if ($inst) {
    Write-Host "    OK: App installed" -ForegroundColor Green
} else {
    Write-Host "    FAIL: Not installed" -ForegroundColor Red
    exit 1
}

# Test 2: Launch
Write-Host "[2] Launching app..." -ForegroundColor Yellow
adb shell am force-stop $pkg 2>$null
Start-Sleep -Seconds 1
$launch = adb shell am start -W $activity 2>&1
if ($launch -match "Status: ok") {
    Write-Host "    OK: Launched successfully" -ForegroundColor Green
} else {
    Write-Host "    FAIL: Launch failed" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 3

# Test 3: Process check
Write-Host "[3] Checking process..." -ForegroundColor Yellow
$proc = adb shell "ps -A | grep $pkg"
if ($proc) {
    Write-Host "    OK: App is running" -ForegroundColor Green
    $pid = ($proc -split '\s+')[1]
    Write-Host "    PID: $pid" -ForegroundColor Gray
} else {
    Write-Host "    FAIL: App not running" -ForegroundColor Red
    exit 1
}

# Test 4: Crash check
Write-Host "[4] Checking for crashes..." -ForegroundColor Yellow
$crash = adb logcat -d -s AndroidRuntime:E | Select-String "FATAL EXCEPTION"
if ($crash) {
    Write-Host "    FAIL: Crash detected" -ForegroundColor Red
    adb logcat -d -s AndroidRuntime:E | Select-Object -Last 20
    exit 1
} else {
    Write-Host "    OK: No crashes" -ForegroundColor Green
}

# Test 5: Logs
Write-Host "[5] Checking logs..." -ForegroundColor Yellow
adb logcat -c
Start-Sleep -Seconds 2
$logs = adb logcat -d | Select-String "ya_ok|YaOk"
if ($logs) {
    Write-Host "    OK: App is logging" -ForegroundColor Green
    Write-Host ""
    Write-Host "Recent logs:" -ForegroundColor Cyan
    $logs | Select-Object -Last 5 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "    WARN: No logs found" -ForegroundColor Yellow
}

# Test 6: Memory
Write-Host ""
Write-Host "[6] Memory usage..." -ForegroundColor Yellow
$mem = adb shell dumpsys meminfo $pkg | Select-String "TOTAL PSS"
if ($mem) {
    Write-Host "    $mem" -ForegroundColor Gray
}

# Test 7: Screen test
Write-Host ""
Write-Host "[7] UI Test..." -ForegroundColor Yellow
$dump = adb shell uiautomator dump 2>&1
if ($dump -match "UI hierchary dumped") {
    Write-Host "    OK: UI accessible" -ForegroundColor Green
} else {
    Write-Host "    WARN: UI dump failed" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Device: $(adb shell getprop ro.product.model)" -ForegroundColor Gray
Write-Host "Android: $(adb shell getprop ro.build.version.release)" -ForegroundColor Gray
Write-Host "Status: PASS" -ForegroundColor Green
Write-Host ""
Write-Host "App is running on device" -ForegroundColor Cyan
Write-Host ""
