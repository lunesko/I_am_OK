param(
    [string]$DeviceId,
    [string]$AdbPath,
    [ValidateSet("debug", "release")]
    [string]$Variant = "debug",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

function Resolve-AdbPath {
    param([string]$PathOverride)

    if ($PathOverride) {
        if (Test-Path $PathOverride) {
            return $PathOverride
        }
        throw "adb not found at: $PathOverride"
    }

    $candidates = @(
        $env:ADB_PATH,
        (Join-Path $env:ANDROID_SDK_ROOT "platform-tools\adb.exe"),
        (Join-Path $env:ANDROID_HOME "platform-tools\adb.exe"),
        (Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe")
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Path
    }

    throw "adb not found. Set -AdbPath or ANDROID_SDK_ROOT/ANDROID_HOME/ADB_PATH."
}

$androidDir = $PSScriptRoot
$adb = Resolve-AdbPath $AdbPath

& "$adb" start-server | Out-Null

if (-not $SkipBuild) {
    $gradle = Join-Path $androidDir "gradlew.bat"
    if (-not (Test-Path $gradle)) {
        throw "Gradle wrapper not found: $gradle"
    }

    $task = "assemble" + ($Variant.Substring(0, 1).ToUpper() + $Variant.Substring(1))
    Push-Location $androidDir
    & "$gradle" $task
    Pop-Location
}

$apk = Join-Path $androidDir ("app\build\outputs\apk\" + $Variant + "\app-" + $Variant + ".apk")
if (-not (Test-Path $apk)) {
    throw "APK not found: $apk"
}

$adbArgs = @()
if ($DeviceId) {
    $adbArgs += @("-s", $DeviceId)
} else {
    $deviceLines = & "$adb" devices | Select-String -Pattern "\sdevice$"
    $devices = @()
    foreach ($line in $deviceLines) {
        $devices += ($line -split "\s+")[0]
    }

    if ($devices.Count -eq 0) {
        throw "No devices found. Connect a device or pass -DeviceId."
    }
    if ($devices.Count -gt 1) {
        throw "Multiple devices detected. Re-run with -DeviceId: $($devices -join ", ")"
    }
}

& "$adb" @adbArgs install -r "$apk"
& "$adb" @adbArgs shell am start -n "app.poruch.ya_ok/.MainActivity"

Write-Host "Installed and launched on device."
