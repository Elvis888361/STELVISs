@echo off
REM ============================================
REM Stelvis ERPNext - Stop
REM Double-click this to stop ERPNext
REM ============================================

echo Stopping Stelvis ERPNext...
cd /d "%~dp0"
docker compose down

echo.
echo ERPNext has been stopped.
pause
