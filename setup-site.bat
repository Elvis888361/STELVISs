@echo off
REM ============================================
REM Stelvis ERPNext - First Time Site Setup
REM Run this ONCE after docker compose up
REM ============================================

set SITE_NAME=stelvis.local
set ADMIN_PASSWORD=admin2024
set DB_ROOT_PASSWORD=stelvis2024

echo ============================================
echo   Stelvis ERPNext - Setting up site...
echo ============================================
echo.

echo [1/5] Waiting for services to be ready...
timeout /t 15 /nobreak >nul

echo [2/5] Creating site: %SITE_NAME%
docker exec stelvis-erpnext bench new-site %SITE_NAME% --mariadb-root-password %DB_ROOT_PASSWORD% --admin-password %ADMIN_PASSWORD% --install-app erpnext --set-default

echo [3/5] Configuring site...
docker exec stelvis-erpnext bench --site %SITE_NAME% set-config developer_mode 0
docker exec stelvis-erpnext bench --site %SITE_NAME% set-config server_script_enabled 1

echo [4/5] Building assets...
docker exec stelvis-erpnext bench build

echo [5/5] Finalizing...
docker exec stelvis-erpnext bench use %SITE_NAME%

echo.
echo ============================================
echo   Setup Complete!
echo.
echo   Open your browser and go to:
echo   http://stelvis.local
echo.
echo   Login with:
echo   Username: Administrator
echo   Password: %ADMIN_PASSWORD%
echo.
echo   To enable POS:
echo   1. Complete the Setup Wizard
echo   2. Create a POS Profile
echo   3. Open POS from sidebar
echo ============================================
pause
