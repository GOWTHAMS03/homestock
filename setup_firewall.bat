@echo off
title HomeStock - Windows Defender Firewall Setup
echo ========================================================
echo   HomeStock - Open Windows Firewall Ports for Mobile App
echo ========================================================
echo.

:: Check for administrative rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [NOTE] Administrator privileges required to configure Windows Firewall.
    echo Requesting elevation...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

echo [1/2] Adding Inbound Rule for HomeStock Spring Boot API (TCP Port 8080)...
netsh advfirewall firewall delete rule name="HomeStock Backend (Port 8080)" >nul 2>&1
netsh advfirewall firewall add rule name="HomeStock Backend (Port 8080)" dir=in action=allow protocol=TCP localport=8080 profile=any >nul 2>&1

echo [2/2] Adding Inbound Rule for HomeStock Auto-Discovery (UDP Port 8888)...
netsh advfirewall firewall delete rule name="HomeStock Discovery (Port 8888)" >nul 2>&1
netsh advfirewall firewall add rule name="HomeStock Discovery (Port 8888)" dir=in action=allow protocol=UDP localport=8888 profile=any >nul 2>&1

echo.
echo ========================================================
echo   [SUCCESS] Firewall configured successfully!
echo   Mobile phones on your Wi-Fi network can now connect
echo   to the HomeStock Spring Boot backend on port 8080.
echo ========================================================
echo.
pause
