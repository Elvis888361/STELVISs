@echo off
REM ============================================
REM Stelvis ERPNext - Step 2 Setup
REM Run this AFTER restart when Docker is running
REM Right-click > Run as administrator
REM ============================================

echo ============================================
echo   Stelvis ERPNext - Setup (Step 2)
echo ============================================
echo.

REM Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Please right-click this file and select
    echo "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Make sure Docker Desktop is running (whale icon in taskbar).
echo.
set /p CONFIRM="Docker Desktop is running? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Please start Docker Desktop first, then run this again.
    pause
    exit /b 0
)

PowerShell -ExecutionPolicy Bypass -File "%~dp0install-step2.ps1"
