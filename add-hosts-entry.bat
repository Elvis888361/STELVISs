@echo off
REM ============================================
REM Stelvis ERPNext - Add hosts entry
REM RUN THIS AS ADMINISTRATOR (right-click > Run as administrator)
REM Only needs to run ONCE
REM ============================================

echo Adding stelvis.local to hosts file...
echo This requires Administrator privileges.
echo.

findstr /C:"stelvis.local" %WINDIR%\System32\drivers\etc\hosts >nul 2>&1
if %errorlevel%==0 (
    echo stelvis.local already exists in hosts file. No changes needed.
) else (
    echo 127.0.0.1  stelvis.local >> %WINDIR%\System32\drivers\etc\hosts
    echo Entry added successfully!
)

echo.
echo Done! You can now access ERPNext at http://stelvis.local
pause
