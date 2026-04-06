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
start http://localhost

echo.
echo ============================================
echo   ERPNext is running!
echo.
echo   If http://localhost doesn't work, try:
echo   http://localhost:8080
echo.
echo   To stop: double-click stop.bat
echo ============================================
pause
