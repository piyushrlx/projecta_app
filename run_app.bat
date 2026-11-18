@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo   Projeqta Mobile App - Development Runner
echo ===================================================
echo.

echo [1/4] Checking connected ADB devices...
adb devices
echo.

echo [2/4] Configuring device keep-awake (prevents ColorOS HANS freezing)...
adb shell svc power stayon usb >nul 2>&1
echo [SUCCESS] Device keep-awake configured (screen stays awake on USB).
echo.

echo [3/4] Setting up ADB reverse tunnel (tcp:8080 -^> tcp:80)...
adb reverse tcp:8080 tcp:80
if %errorlevel% neq 0 (
    echo [WARNING] Failed to set adb reverse. Please ensure your device is connected via USB with USB debugging enabled.
) else (
    echo [SUCCESS] ADB reverse tunnel active:
    adb reverse --list
)
echo.

echo [4/4] Launching Flutter app...
cd /d "%~dp0"
flutter run %*

echo.
echo ===================================================
echo App session ended.
echo ===================================================
