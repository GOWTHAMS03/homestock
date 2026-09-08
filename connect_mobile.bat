@echo off
echo ========================================================
echo   HomeStock - Mobile Phone to Spring Boot Connector
echo ========================================================
echo.

set ADB_PATH="C:\Users\GowthamSekar\AppData\Local\Android\Sdk\platform-tools\adb.exe"

if not exist %ADB_PATH% (
    echo [ERROR] ADB not found at %ADB_PATH%
    pause
    exit /b 1
)

echo [1/2] Checking connected devices...
%ADB_PATH% devices
echo.

echo [2/2] Forwarding port 8080 over USB tunnel...
%ADB_PATH% reverse tcp:8080 tcp:8080

if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================================
    echo   SUCCESS! Mobile phone connected via USB tunnel.
    echo   In your HomeStock app, set Server URL to:
    echo     http://127.0.0.1:8080/api/v1
    echo   Or if using Wi-Fi Hotspot, use:
    echo     http://172.20.10.2:8080/api/v1
    echo ========================================================
) else (
    echo.
    echo [FAILED] Make sure your phone is connected via USB and USB Debugging is ON.
)
echo.
pause
