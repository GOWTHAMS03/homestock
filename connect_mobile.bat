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

echo [1/3] Detecting PC Wi-Fi IP Address...
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi*').IPAddress"`) do set WIFI_IP=%%i

echo   Current Wi-Fi IP: %WIFI_IP%
echo.

echo [2/3] Checking connected Android devices via ADB...
%ADB_PATH% devices
echo.

echo [3/3] Setting up USB port reverse tunnel (phone:8080 -^> PC:8080)...
%ADB_PATH% reverse tcp:8080 tcp:8080

if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================================
    echo   [SUCCESS] USB Tunnel is ACTIVE!
    echo.
    echo   Choose either connection method in HomeStock:
    echo.
    echo   OPTION 1: USB Cable [Recommended - zero setup]
    echo     Server URL: http://127.0.0.1:8080/api/v1
    echo.
    echo   OPTION 2: Same Wi-Fi Network
    echo     Server URL: http://%WIFI_IP%:8080/api/v1
    echo.
    echo   Tip: Tap "Auto-Detect" in the HomeStock app to connect
    echo        automatically without typing!
    echo ========================================================
) else (
    echo.
    echo [NOTE] USB device not found or adb reverse failed.
    echo If connecting over Wi-Fi without USB:
    echo   Set Server URL in HomeStock app to:
    echo     http://%WIFI_IP%:8080/api/v1
    echo.
    echo If using USB cable:
    echo   1. Connect phone via USB cable
    echo   2. Enable USB Debugging in Developer Options on your phone
    echo   3. Run this script again
)
echo.
pause
