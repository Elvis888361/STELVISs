# ============================================
# Stelvis ERPNext - STEP 1: Install Prerequisites
# Run this as Administrator in PowerShell
# Right-click PowerShell > Run as Administrator
# Then: Set-ExecutionPolicy Bypass -Scope Process -Force; .\install-step1.ps1
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Stelvis ERPNext - Step 1 of 2" -ForegroundColor Cyan
Write-Host "  Installing Prerequisites..." -ForegroundColor Cyan
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

# ---- Step 1: Enable WSL2 ----
Write-Host "[1/5] Enabling WSL2..." -ForegroundColor Yellow

$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($wslFeature.State -ne "Enabled") {
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    Write-Host "  WSL enabled." -ForegroundColor Green
} else {
    Write-Host "  WSL already enabled." -ForegroundColor Green
}

# ---- Step 2: Enable Virtual Machine Platform ----
Write-Host "[2/5] Enabling Virtual Machine Platform..." -ForegroundColor Yellow

$vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
if ($vmFeature.State -ne "Enabled") {
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    Write-Host "  Virtual Machine Platform enabled." -ForegroundColor Green
} else {
    Write-Host "  Virtual Machine Platform already enabled." -ForegroundColor Green
}

# ---- Step 3: Set WSL2 as default ----
Write-Host "[3/5] Setting WSL2 as default version..." -ForegroundColor Yellow
wsl --set-default-version 2 2>$null
wsl --update 2>$null
Write-Host "  WSL2 set as default." -ForegroundColor Green

# ---- Step 4: Download Docker Desktop ----
Write-Host "[4/5] Downloading Docker Desktop..." -ForegroundColor Yellow

$dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
$dockerInstalled = Test-Path "C:\Program Files\Docker\Docker\Docker Desktop.exe"

if ($dockerInstalled) {
    Write-Host "  Docker Desktop already installed." -ForegroundColor Green
} else {
    if (-not (Test-Path $dockerInstaller)) {
        Write-Host "  Downloading... (this may take a few minutes)" -ForegroundColor Gray
        $ProgressPreference = 'SilentlyContinue'
        try {
            Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile $dockerInstaller -UseBasicParsing
            Write-Host "  Download complete." -ForegroundColor Green
        } catch {
            Write-Host "  ERROR: Failed to download Docker Desktop." -ForegroundColor Red
            Write-Host "  Please download manually from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
            Write-Host "  After installing Docker, run install-step2.ps1" -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit 1
        }
    }

    # ---- Step 5: Install Docker Desktop ----
    Write-Host "[5/5] Installing Docker Desktop (silent install)..." -ForegroundColor Yellow
    Write-Host "  This may take several minutes..." -ForegroundColor Gray
    Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet", "--accept-license" -Wait
    Write-Host "  Docker Desktop installed." -ForegroundColor Green
}

# ---- Add hosts entry ----
Write-Host ""
Write-Host "Adding stelvis.local to hosts file..." -ForegroundColor Yellow
$hostsFile = "$env:WINDIR\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsFile -Raw
if ($hostsContent -notmatch "stelvis\.local") {
    Add-Content -Path $hostsFile -Value "`n127.0.0.1  stelvis.local"
    Write-Host "  stelvis.local added to hosts file." -ForegroundColor Green
} else {
    Write-Host "  stelvis.local already in hosts file." -ForegroundColor Green
}

# ---- Save install directory path for step 2 ----
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir | Out-File "$env:USERPROFILE\.stelvis-install-path" -Encoding UTF8

# ---- Done ----
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Step 1 Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  IMPORTANT: You must RESTART your computer now." -ForegroundColor Yellow
Write-Host ""
Write-Host "  After restart:" -ForegroundColor White
Write-Host "  1. Wait for Docker Desktop to start" -ForegroundColor White
Write-Host "     (whale icon in system tray)" -ForegroundColor Gray
Write-Host "  2. Open PowerShell as Administrator" -ForegroundColor White
Write-Host "  3. Navigate to this folder and run:" -ForegroundColor White
Write-Host "     .\install-step2.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================" -ForegroundColor Green

$restart = Read-Host "Restart now? (Y/N)"
if ($restart -eq "Y" -or $restart -eq "y") {
    Restart-Computer -Force
} else {
    Write-Host "Please restart manually before running Step 2." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
}
