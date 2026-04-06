@echo off
REM ============================================
REM Stelvis ERPNext - ONE CLICK INSTALLER
REM Just double-click this file!
REM ============================================

REM Auto-elevate to administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator access...
    PowerShell -Command "Start-Process '%~f0' -Verb RunAs -ArgumentList '%~dp0'"
    exit /b
)

REM Set working directory to script location
cd /d "%~dp0"

echo.
echo ============================================
echo   STELVIS ERPNext - Installer
echo ============================================
echo.

REM Check if Docker is already installed and running
docker info >nul 2>&1
if %errorlevel%==0 (
    echo Docker is already installed and running.
    echo Skipping to ERPNext setup...
    goto :setup_erpnext
)

REM Check if Docker is installed but not running
if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" (
    echo Docker is installed but not running.
    echo Starting Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo Waiting for Docker to start...
    goto :wait_docker
)

REM Docker not installed - install everything
echo Step 1: Enabling WSL2...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >nul 2>&1
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >nul 2>&1
wsl --set-default-version 2 >nul 2>&1
wsl --update >nul 2>&1
echo   Done.

echo.
echo Step 2: Downloading Docker Desktop...
echo   This may take a few minutes...
PowerShell -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe' -OutFile '%TEMP%\DockerInstaller.exe' -UseBasicParsing"

if not exist "%TEMP%\DockerInstaller.exe" (
    echo   ERROR: Download failed. Check internet connection.
    pause
    exit /b 1
)
echo   Done.

echo.
echo Step 3: Installing Docker Desktop (this takes a few minutes)...
"%TEMP%\DockerInstaller.exe" install --quiet --accept-license
echo   Done.

echo.
echo ============================================
echo   Docker installed! Restart required.
echo ============================================
echo.
echo   After restart:
echo   1. Wait for Docker whale icon in taskbar
echo   2. Double-click INSTALL.bat again
echo   3. It will finish the setup automatically
echo ============================================
echo.
set /p RESTART="Restart now? (Y/N): "
if /i "%RESTART%"=="Y" shutdown /r /t 5
pause
exit /b 0

:wait_docker
REM Wait for Docker to be ready
set ATTEMPTS=0
:docker_loop
docker info >nul 2>&1
if %errorlevel%==0 goto :setup_erpnext
set /a ATTEMPTS+=1
if %ATTEMPTS% GEQ 60 (
    echo ERROR: Docker did not start after 5 minutes.
    echo Please open Docker Desktop manually, wait for it to load,
    echo then run this installer again.
    pause
    exit /b 1
)
echo   Waiting for Docker... (%ATTEMPTS%/60)
timeout /t 5 /nobreak >nul
goto :docker_loop

:setup_erpnext
echo.
echo ============================================
echo   Setting up ERPNext (one-time setup)
echo ============================================
echo.

REM Add hosts entry
findstr /C:"stelvis.local" %WINDIR%\System32\drivers\etc\hosts >nul 2>&1
if %errorlevel% neq 0 (
    echo 127.0.0.1  stelvis.local >> %WINDIR%\System32\drivers\etc\hosts
    echo   Added stelvis.local to hosts file.
)

REM Navigate to script directory
cd /d "%~dp0"

REM Pull and start everything (configurator auto-creates the site)
echo.
echo   Downloading ERPNext images (10-15 min first time)...
docker compose pull

echo.
echo   Starting ERPNext...
echo   The first start takes 5-10 minutes (creating database).
echo   Please wait...
echo.
docker compose up -d

REM Wait for configurator to finish
echo   Waiting for setup to complete...
:config_loop
docker inspect --format="{{.State.Status}}" stelvis-configurator 2>nul | findstr "exited" >nul
if %errorlevel% neq 0 (
    timeout /t 10 /nobreak >nul
    echo   Still setting up...
    goto :config_loop
)

REM Check configurator exit code
for /f %%i in ('docker inspect --format="{{.State.ExitCode}}" stelvis-configurator 2^>nul') do set EXIT_CODE=%%i
if "%EXIT_CODE%" neq "0" (
    echo.
    echo   ERROR: Setup failed. Check logs with:
    echo   docker logs stelvis-configurator
    pause
    exit /b 1
)

REM Wait for nginx/erpnext to be ready
echo   Almost done, starting web server...
timeout /t 30 /nobreak >nul

REM Create desktop shortcuts
echo   Creating desktop shortcuts...
PowerShell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Stelvis POS.lnk'); $s.TargetPath = 'http://localhost'; $s.Save()"
PowerShell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Stelvis Start.lnk'); $s.TargetPath = '%~dp0start.bat'; $s.WorkingDirectory = '%~dp0'; $s.Save()"
PowerShell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Stelvis Backup.lnk'); $s.TargetPath = '%~dp0backup.bat'; $s.WorkingDirectory = '%~dp0'; $s.Save()"

echo.
echo ============================================
echo   INSTALLATION COMPLETE!
echo ============================================
echo.
echo   Opening browser now...
echo.
echo   URL:      http://localhost
echo   Backup:   http://localhost:8080 (if port 80 is busy)
echo   Username: Administrator
echo   Password: admin2024
echo.
echo   CHANGE THE PASSWORD AFTER FIRST LOGIN!
echo.
echo   POS: http://localhost/app/point-of-sale
echo ============================================

start http://localhost
pause
