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

if "%WIFI_IP%"=="" (
    for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.*' }).IPAddress | Select-Object -First 1"`) do set WIFI_IP=%%i
)

echo   Current Wi-Fi IP: %WIFI_IP%
echo.

echo [2/3] Checking Windows Defender Firewall...
netsh advfirewall firewall show rule name="HomeStock Backend (Port 8080)" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [NOTICE] Firewall rule for port 8080 is not active.
    echo   Launching setup_firewall.bat to open port 8080 and 8888...
    start "" cmd /c "%~dp0setup_firewall.bat"
) else (
    echo   [OK] Windows Firewall allows port 8080.
)
echo.

echo [3/3] Checking connected Android devices via ADB...
%ADB_PATH% devices
echo.

echo Setting up USB port reverse tunnel (phone:8080 -> PC:8080)...
%ADB_PATH% reverse tcp:8080 tcp:8080

if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================================
    echo   [SUCCESS] USB Tunnel is ACTIVE!
    echo.
    echo   Choose either connection method in HomeStock:
    echo.
    echo   OPTION 1: USB Cable [Fastest - zero Wi-Fi needed]
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
    echo ========================================================
    echo   [NOTE] USB device not connected or adb reverse failed.
    echo.
    echo   Connecting over Wi-Fi without USB cable:
    echo     Set Server URL in HomeStock app to:
    echo       http://%WIFI_IP%:8080/api/v1
    echo.
    echo     Or tap "Auto-Detect" in the HomeStock server settings!
    echo.
    echo   If using USB cable:
    echo     1. Connect phone via USB cable
    echo     2. Enable USB Debugging in Developer Options on your phone
    echo     3. Run this script again
    echo ========================================================
)
echo.
pause
