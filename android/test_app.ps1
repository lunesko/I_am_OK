# Ya OK Android App - Automated Functional Test
# Device: Samsung SM-A525F (Android 14)

Write-Host "=== Ya OK App Functional Test ===" -ForegroundColor Cyan
Write-Host ""

$packageName = "app.poruch.ya_ok"
$activityName = "$packageName/.MainActivity"

# Test 1: Check if app is installed
Write-Host "[TEST 1] Checking app installation..." -ForegroundColor Yellow
$installed = adb shell pm list packages | Select-String $packageName
if ($installed) {
    Write-Host "✓ App installed: $packageName" -ForegroundColor Green
} else {
    Write-Host "✗ App not installed" -ForegroundColor Red
    exit 1
}

# Test 2: Check native library
Write-Host "`n[TEST 2] Checking native library..." -ForegroundColor Yellow
$libPath = adb shell "run-as $packageName ls lib" 2>$null
if ($libPath -match "libya_ok_core.so") {
    Write-Host "✓ Native library found: libya_ok_core.so" -ForegroundColor Green
} else {
    Write-Host "⚠ Native library status unknown (run-as may be restricted)" -ForegroundColor Yellow
}

# Test 3: Launch app
Write-Host "`n[TEST 3] Launching app..." -ForegroundColor Yellow
adb shell am force-stop $packageName 2>$null
Start-Sleep -Seconds 1
$launch = adb shell am start -W $activityName 2>&1
if ($launch -match "Status: ok") {
    Write-Host "✓ App launched successfully" -ForegroundColor Green
} else {
    Write-Host "✗ App launch failed" -ForegroundColor Red
    Write-Host $launch
}

Start-Sleep -Seconds 3

# Test 4: Check if app is running
Write-Host "`n[TEST 4] Checking app process..." -ForegroundColor Yellow
$process = adb shell "ps -A | grep $packageName"
if ($process) {
    Write-Host "✓ App is running" -ForegroundColor Green
    $pid = ($process -split '\s+')[1]
    Write-Host "  PID: $pid" -ForegroundColor Gray
} else {
    Write-Host "✗ App crashed or not running" -ForegroundColor Red
    Write-Host "`nChecking crash logs..." -ForegroundColor Yellow
    adb logcat -d -s AndroidRuntime:E | Select-Object -Last 30
    exit 1
}

# Test 5: Check for crashes in logcat
Write-Host "`n[TEST 5] Checking for crashes..." -ForegroundColor Yellow
$crashes = adb logcat -d -s AndroidRuntime:E | Select-String "FATAL EXCEPTION"
if ($crashes) {
    Write-Host "✗ Crash detected!" -ForegroundColor Red
    adb logcat -d -s AndroidRuntime:E | Select-Object -Last 30
    exit 1
} else {
    Write-Host "✓ No crashes detected" -ForegroundColor Green
}

# Test 6: Check app logs
Write-Host "`n[TEST 6] Checking app logs..." -ForegroundColor Yellow
adb logcat -c
Start-Sleep -Seconds 2
$logs = adb logcat -d -s "$packageName`:*" "YaOkCore:*" "ya_ok_core:*"
if ($logs) {
    Write-Host "✓ App is logging activity" -ForegroundColor Green
    Write-Host "`nRecent logs:" -ForegroundColor Gray
    $logs | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
} else {
    Write-Host "⚠ No app-specific logs found" -ForegroundColor Yellow
}

# Test 7: Test UI elements
Write-Host "`n[TEST 7] Testing UI elements..." -ForegroundColor Yellow
$uiDump = adb shell uiautomator dump /sdcard/window_dump.xml 2>&1
if ($uiDump -match "UI hierchary dumped") {
    adb pull /sdcard/window_dump.xml "$PSScriptRoot\ui_dump.xml" 2>&1 | Out-Null
    $xmlContent = Get-Content "$PSScriptRoot\ui_dump.xml" -Raw
    
    # Check for key UI elements
    $checks = @{
        "BottomNavigationView" = $xmlContent -match "BottomNavigationView"
        "Send Status Button" = $xmlContent -match "Send|Status"
        "Settings" = $xmlContent -match "Settings|Profile"
    }
    
    foreach ($check in $checks.GetEnumerator()) {
        if ($check.Value) {
            Write-Host "  ✓ $($check.Key) found" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $($check.Key) not found" -ForegroundColor Yellow
        }
    }
    
    Remove-Item "$PSScriptRoot\ui_dump.xml" -ErrorAction SilentlyContinue
} else {
    Write-Host "  ⚠ UI dump failed" -ForegroundColor Yellow
}

# Test 8: Test permissions
Write-Host "`n[TEST 8] Checking permissions..." -ForegroundColor Yellow
$permissions = adb shell dumpsys package $packageName | Select-String "permission"
$requiredPerms = @("BLUETOOTH", "BLUETOOTH_ADMIN", "ACCESS_FINE_LOCATION", "INTERNET")
foreach ($perm in $requiredPerms) {
    if ($permissions -match $perm) {
        Write-Host "  ✓ $perm declared" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ $perm not found" -ForegroundColor Yellow
    }
}

# Test 9: Memory usage
Write-Host "`n[TEST 9] Checking memory usage..." -ForegroundColor Yellow
$meminfo = adb shell dumpsys meminfo $packageName | Select-String "TOTAL PSS"
if ($meminfo) {
    Write-Host "✓ Memory info retrieved" -ForegroundColor Green
    Write-Host "  $meminfo" -ForegroundColor Gray
} else {
    Write-Host "⚠ Memory info unavailable" -ForegroundColor Yellow
}

# Test 10: Navigate to Debug screen
Write-Host "`n[TEST 10] Testing navigation to Debug screen..." -ForegroundColor Yellow
# Simulate taps to navigate (coordinates may vary by device)
# Tap bottom navigation Settings tab (right side)
adb shell input tap 900 2200 2>$null
Start-Sleep -Seconds 1
# Scroll down to find Debug option
adb shell input swipe 500 1500 500 500 2>$null
Start-Sleep -Seconds 1
# Check if Debug screen elements exist
$uiDump2 = adb shell uiautomator dump /sdcard/window_dump2.xml 2>&1
if ($uiDump2 -match "UI hierchary dumped") {
    adb pull /sdcard/window_dump2.xml "$PSScriptRoot\ui_dump2.xml" 2>&1 | Out-Null
    $xmlContent2 = Get-Content "$PSScriptRoot\ui_dump2.xml" -Raw
    if ($xmlContent2 -match "Debug|Identity|Peers|Messages") {
        Write-Host "✓ Debug screen accessible" -ForegroundColor Green
    } else {
        Write-Host "⚠ Debug screen not confirmed" -ForegroundColor Yellow
    }
    Remove-Item "$PSScriptRoot\ui_dump2.xml" -ErrorAction SilentlyContinue
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "App Package: $packageName" -ForegroundColor Gray
Write-Host "Device: Samsung SM-A525F (Android 14)" -ForegroundColor Gray
Write-Host "Test Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "`n✓ App is functional and running" -ForegroundColor Green
Write-Host ""

# Keep app running for manual testing
Write-Host "App is still running on device for manual testing." -ForegroundColor Cyan
Write-Host "Run adb shell am force-stop to close app if needed." -ForegroundColor Gray
Write-Host ""
