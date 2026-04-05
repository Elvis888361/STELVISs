@echo off
REM ============================================
REM Stelvis ERPNext - Start
REM Double-click this to start ERPNext
REM ============================================

echo Starting Stelvis ERPNext...
echo.

cd /d "%~dp0"
docker compose up -d

echo.
echo ERPNext is starting up. Please wait about 30 seconds...
timeout /t 30 /nobreak >nul

echo Opening browser...
start http://stelvis.local

echo.
echo ERPNext is running! You can close this window.
echo To stop ERPNext, double-click stop.bat
pause
