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

REM ============================================
REM STEP A: Fix WSL2 (most common issue)
REM ============================================
echo [Step 1] Setting up WSL2...

REM Enable required Windows features
echo   Enabling Windows Subsystem for Linux...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >nul 2>&1

echo   Enabling Virtual Machine Platform...
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >nul 2>&1

REM Install/update WSL
echo   Installing/updating WSL...
wsl --install --no-distribution >nul 2>&1
wsl --update >nul 2>&1
wsl --set-default-version 2 >nul 2>&1

REM Download and install WSL2 kernel update (required for older Windows 10)
echo   Installing WSL2 kernel update...
PowerShell -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi' -OutFile '%TEMP%\wsl_update.msi' -UseBasicParsing } catch { Write-Host '  Could not download WSL update (may not be needed)' }"

if exist "%TEMP%\wsl_update.msi" (
    msiexec /i "%TEMP%\wsl_update.msi" /quiet /norestart
    echo   WSL2 kernel update installed.
) else (
    echo   WSL2 kernel update skipped (already up to date or not needed).
)

wsl --set-default-version 2 >nul 2>&1
echo   WSL2 setup complete.
echo.

REM ============================================
REM STEP B: Install Docker if needed
REM ============================================
echo [Step 2] Checking Docker...

REM Check if Docker is already installed and running
docker info >nul 2>&1
if %errorlevel%==0 (
    echo   Docker is already running.
    goto :setup_erpnext
)

REM Check if Docker is installed but not running
if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" (
    echo   Docker is installed but not running.
    echo   Starting Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    goto :wait_docker
)

REM Docker not installed - download and install
echo   Downloading Docker Desktop...
echo   This may take a few minutes depending on your internet...
PowerShell -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe' -OutFile '%TEMP%\DockerInstaller.exe' -UseBasicParsing"

if not exist "%TEMP%\DockerInstaller.exe" (
    echo.
    echo   ERROR: Download failed.
    echo   Please download Docker Desktop manually from:
    echo   https://www.docker.com/products/docker-desktop/
    echo   Install it, restart your PC, then run INSTALL.bat again.
    pause
    exit /b 1
)

echo   Installing Docker Desktop...
echo   This takes a few minutes, please wait...
"%TEMP%\DockerInstaller.exe" install --quiet --accept-license

echo.
echo ============================================
echo   Docker installed! RESTART REQUIRED.
echo ============================================
echo.
echo   After restart:
echo   1. Wait for Docker whale icon in taskbar
echo      (bottom-right corner, may take 1-2 min)
echo   2. Double-click INSTALL.bat again
echo   3. It will finish automatically
echo ============================================
echo.
set /p RESTART="Restart now? (Y/N): "
if /i "%RESTART%"=="Y" shutdown /r /t 5
pause
exit /b 0

:wait_docker
REM Wait for Docker to be ready
echo   Waiting for Docker Desktop to start...
echo   (This can take 1-2 minutes)
set ATTEMPTS=0
:docker_loop
docker info >nul 2>&1
if %errorlevel%==0 goto :setup_erpnext
set /a ATTEMPTS+=1
if %ATTEMPTS% GEQ 60 (
    echo.
    echo   ERROR: Docker did not start after 5 minutes.
    echo.
    echo   Try these steps:
    echo   1. Open Docker Desktop from Start Menu
    echo   2. If it says "WSL update needed":
    echo      - Open PowerShell as Admin
    echo      - Run: wsl --update
    echo      - Restart Docker Desktop
    echo   3. Run INSTALL.bat again
    pause
    exit /b 1
)
echo   Waiting... (%ATTEMPTS%/60)
timeout /t 5 /nobreak >nul
goto :docker_loop

:setup_erpnext
echo.
echo ============================================
echo [Step 3] Setting up ERPNext
echo ============================================
echo.

REM Add hosts entry
findstr /C:"stelvis.local" %WINDIR%\System32\drivers\etc\hosts >nul 2>&1
if %errorlevel% neq 0 (
    echo 127.0.0.1  stelvis.local >> %WINDIR%\System32\drivers\etc\hosts
    echo   Added stelvis.local to hosts file.
)

REM Check if port 80 is in use
netstat -ano | findstr ":80 " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 (
    echo.
    echo   WARNING: Port 80 is already in use by another program.
    echo   ERPNext will also be available on port 8080.
    echo   Use http://localhost:8080 if http://localhost doesn't work.
    echo.
)

REM Pull and start everything
echo   Downloading ERPNext images...
echo   (This takes 10-15 minutes the first time)
docker compose pull

echo.
echo   Starting ERPNext...
echo   The first start takes 5-10 minutes (creating database).
echo   Please be patient...
echo.
docker compose up -d

REM Wait for configurator to finish
echo   Setting up database and site...
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
    echo   ERROR: Setup failed.
    echo   Run this command to see what went wrong:
    echo   docker logs stelvis-configurator
    pause
    exit /b 1
)

REM Wait for web server
echo   Starting web server...
timeout /t 30 /nobreak >nul

REM Verify it actually works
echo   Verifying...
PowerShell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost' -UseBasicParsing -TimeoutSec 10; if ($r.StatusCode -eq 200) { Write-Host '  SUCCESS: ERPNext is responding!' } } catch { try { $r = Invoke-WebRequest -Uri 'http://localhost:8080' -UseBasicParsing -TimeoutSec 10; if ($r.StatusCode -eq 200) { Write-Host '  SUCCESS: ERPNext is responding on port 8080!' } } catch { Write-Host '  WARNING: ERPNext may still be starting. Wait 1-2 minutes.' } }"

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
echo   URL:      http://localhost
echo   Backup:   http://localhost:8080 (if port 80 busy)
echo   Username: Administrator
echo   Password: admin2024
echo.
echo   CHANGE THE PASSWORD AFTER FIRST LOGIN!
echo.
echo   POS: http://localhost/app/point-of-sale
echo ============================================

start http://localhost
pause
