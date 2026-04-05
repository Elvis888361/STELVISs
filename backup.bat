@echo off
REM ============================================
REM Stelvis ERPNext - Backup
REM Double-click this to create a backup
REM ============================================

echo Creating backup of Stelvis ERPNext...
cd /d "%~dp0"

docker exec stelvis-erpnext bench --site stelvis.local backup --with-files

echo.
echo Backup created! Files are stored inside the Docker volume.
echo To copy backups to this folder:
docker cp stelvis-erpnext:/home/frappe/frappe-bench/sites/stelvis.local/private/backups ./backups

echo.
echo Backups saved to: %~dp0backups\
pause
