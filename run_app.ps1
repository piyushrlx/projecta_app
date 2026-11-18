Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "   Projeqta Mobile App - Development Runner" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Checking connected ADB devices..." -ForegroundColor Yellow
adb devices
Write-Host ""

Write-Host "[2/4] Configuring device keep-awake (prevents ColorOS HANS freezing)..." -ForegroundColor Yellow
adb shell svc power stayon usb 2>$null
Write-Host "[SUCCESS] Device keep-awake configured (screen stays awake on USB)." -ForegroundColor Green
Write-Host ""

Write-Host "[3/4] Setting up ADB reverse tunnel (tcp:8080 -> tcp:80)..." -ForegroundColor Yellow
adb reverse tcp:8080 tcp:80
$reverseList = adb reverse --list
if ($reverseList) {
    Write-Host "[SUCCESS] Active ADB reverse rules:" -ForegroundColor Green
    Write-Host $reverseList -ForegroundColor Green
} else {
    Write-Host "[WARNING] No reverse rules listed. Please ensure phone is connected with USB debugging." -ForegroundColor Yellow
}
Write-Host ""

Write-Host "[4/4] Launching Flutter app..." -ForegroundColor Yellow
Set-Location $PSScriptRoot
flutter run $args
