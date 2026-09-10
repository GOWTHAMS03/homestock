@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo  HomeStock Git Repair and Auto-Healing Utility
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/4] Checking for and removing stale Git lock files...
if exist ".git\index.lock" (
    echo Removing stale .git\index.lock...
    del /f /q ".git\index.lock" >nul 2>&1
)
if exist ".git\HEAD.lock" (
    echo Removing stale .git\HEAD.lock...
    del /f /q ".git\HEAD.lock" >nul 2>&1
)
del /f /q /s ".git\refs\*.lock" >nul 2>&1

echo [2/4] Inspecting .git\index health...
for %%F in (".git\index") do set size=%%~zF
if "%size%"=="" set size=0

echo Current .git\index size: %size% bytes
if %size% LSS 12 (
    echo [WARNING] .git\index is 0 bytes or corrupted! Rebuilding from HEAD...
    del /f /q ".git\index" >nul 2>&1
    git reset
    echo Index successfully reconstructed.
) else (
    echo Index file size is healthy.
)

echo [3/4] Applying Windows Git performance and anti-corruption settings...
git config core.preloadindex true
git config core.trustctime false
git config core.fscache true
git config core.untrackedCache true

echo [4/4] Verifying Git status...
git status -s

echo.
echo ========================================================
echo  Git repository is healthy and ready!
echo ========================================================
echo.
