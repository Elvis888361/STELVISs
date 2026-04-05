# ============================================
# Stelvis ERPNext - STEP 2: Setup ERPNext
# Run this AFTER restart and Docker Desktop is running
# Right-click PowerShell > Run as Administrator
# Then: Set-ExecutionPolicy Bypass -Scope Process -Force; .\install-step2.ps1
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Stelvis ERPNext - Step 2 of 2" -ForegroundColor Cyan
Write-Host "  Setting up ERPNext..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell > Run as Administrator" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Configuration
$SITE_NAME = "stelvis.local"
$ADMIN_PASSWORD = "admin2024"
$DB_ROOT_PASSWORD = "stelvis2024"

# ---- Check Docker is running ----
Write-Host "[1/6] Checking Docker Desktop..." -ForegroundColor Yellow

$dockerRunning = $false
$retries = 0
$maxRetries = 30

while (-not $dockerRunning -and $retries -lt $maxRetries) {
    try {
        $result = docker info 2>&1
        if ($LASTEXITCODE -eq 0) {
            $dockerRunning = $true
        }
    } catch {}

    if (-not $dockerRunning) {
        $retries++
        if ($retries -eq 1) {
            Write-Host "  Waiting for Docker Desktop to start..." -ForegroundColor Gray
            Write-Host "  (Make sure Docker Desktop is open)" -ForegroundColor Gray
            # Try to start Docker Desktop
            $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
            if (Test-Path $dockerPath) {
                Start-Process $dockerPath
            }
        }
        Write-Host "  Attempt $retries/$maxRetries - waiting 10 seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}

if (-not $dockerRunning) {
    Write-Host "  ERROR: Docker Desktop is not running!" -ForegroundColor Red
    Write-Host "  Please open Docker Desktop and wait for it to fully start." -ForegroundColor Yellow
    Write-Host "  Then run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  Docker is running." -ForegroundColor Green

# ---- Navigate to project folder ----
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# ---- Pull images ----
Write-Host "[2/6] Downloading ERPNext images (this may take 10-15 minutes)..." -ForegroundColor Yellow
docker compose pull
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to pull images. Check your internet connection." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  Images downloaded." -ForegroundColor Green

# ---- Start containers ----
Write-Host "[3/6] Starting ERPNext containers..." -ForegroundColor Yellow
docker compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to start containers." -ForegroundColor Red
    Write-Host "  Try running: docker compose down" -ForegroundColor Yellow
    Write-Host "  Then run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  Containers started." -ForegroundColor Green

# ---- Wait for MariaDB ----
Write-Host "[4/6] Waiting for database to be ready..." -ForegroundColor Yellow
$dbReady = $false
$dbRetries = 0
$dbMaxRetries = 30

while (-not $dbReady -and $dbRetries -lt $dbMaxRetries) {
    $healthCheck = docker inspect --format='{{.State.Health.Status}}' stelvis-mariadb 2>&1
    if ($healthCheck -eq "healthy") {
        $dbReady = $true
    } else {
        $dbRetries++
        Write-Host "  Waiting for database... ($dbRetries/$dbMaxRetries)" -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

if (-not $dbReady) {
    Write-Host "  WARNING: Database health check timed out, proceeding anyway..." -ForegroundColor Yellow
} else {
    Write-Host "  Database is ready." -ForegroundColor Green
}

# Extra wait for ERPNext to be fully ready
Write-Host "  Waiting for ERPNext to initialize (30 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# ---- Create site ----
Write-Host "[5/6] Creating ERPNext site (this takes 5-10 minutes)..." -ForegroundColor Yellow
Write-Host "  Please be patient, this is the longest step." -ForegroundColor Gray

docker exec stelvis-erpnext bench new-site $SITE_NAME `
    --mariadb-root-password $DB_ROOT_PASSWORD `
    --admin-password $ADMIN_PASSWORD `
    --install-app erpnext `
    --set-default

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to create site." -ForegroundColor Red
    Write-Host "  Check logs with: docker logs stelvis-erpnext" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  Site created." -ForegroundColor Green

# ---- Configure ----
Write-Host "[6/6] Configuring ERPNext..." -ForegroundColor Yellow
docker exec stelvis-erpnext bench --site $SITE_NAME set-config developer_mode 0
docker exec stelvis-erpnext bench --site $SITE_NAME set-config server_script_enabled 1
docker exec stelvis-erpnext bench use $SITE_NAME
docker exec stelvis-erpnext bench build
Write-Host "  Configuration complete." -ForegroundColor Green

# ---- Configure Docker Desktop to auto-start ----
Write-Host ""
Write-Host "Configuring Docker Desktop to start on login..." -ForegroundColor Yellow
$dockerAutoStart = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerPath) {
    Set-ItemProperty -Path $dockerAutoStart -Name "DockerDesktop" -Value "`"$dockerPath`"" -ErrorAction SilentlyContinue
}

# ---- Create desktop shortcuts ----
Write-Host "Creating desktop shortcuts..." -ForegroundColor Yellow
$desktop = [System.Environment]::GetFolderPath("Desktop")

# Start shortcut
$WshShell = New-Object -ComObject WScript.Shell
$startShortcut = $WshShell.CreateShortcut("$desktop\Stelvis ERPNext - Start.lnk")
$startShortcut.TargetPath = "$scriptDir\start.bat"
$startShortcut.WorkingDirectory = $scriptDir
$startShortcut.Description = "Start Stelvis ERPNext"
$startShortcut.Save()

# Browser shortcut
$browserShortcut = $WshShell.CreateShortcut("$desktop\Stelvis POS.lnk")
$browserShortcut.TargetPath = "http://stelvis.local"
$browserShortcut.Description = "Open Stelvis ERPNext POS"
$browserShortcut.Save()

# Backup shortcut
$backupShortcut = $WshShell.CreateShortcut("$desktop\Stelvis Backup.lnk")
$backupShortcut.TargetPath = "$scriptDir\backup.bat"
$backupShortcut.WorkingDirectory = $scriptDir
$backupShortcut.Description = "Backup Stelvis ERPNext"
$backupShortcut.Save()

Write-Host "  Desktop shortcuts created." -ForegroundColor Green

# ---- Open browser ----
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Your ERPNext is ready at:" -ForegroundColor White
Write-Host "  http://stelvis.local" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Login:" -ForegroundColor White
Write-Host "  Username: Administrator" -ForegroundColor White
Write-Host "  Password: $ADMIN_PASSWORD" -ForegroundColor White
Write-Host ""
Write-Host "  IMPORTANT: Change the password after first login!" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Desktop shortcuts created:" -ForegroundColor White
Write-Host "  - Stelvis ERPNext - Start" -ForegroundColor Gray
Write-Host "  - Stelvis POS (browser)" -ForegroundColor Gray
Write-Host "  - Stelvis Backup" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "  1. Complete the Setup Wizard" -ForegroundColor White
Write-Host "  2. Create a POS Profile" -ForegroundColor White
Write-Host "  3. Start selling!" -ForegroundColor White
Write-Host ""
Write-Host "============================================" -ForegroundColor Green

Start-Process "http://stelvis.local"
Read-Host "Press Enter to exit"
