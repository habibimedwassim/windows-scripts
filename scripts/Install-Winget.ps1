# Install-Winget.ps1
# Installs winget (App Installer) on machines that don't have it (e.g. LTSC)
# Downloads UI.Xaml, VCLibs, and the latest winget release from GitHub

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # speeds up Invoke-WebRequest

function Write-Step  { param($msg) Write-Host "  >> $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Fail  { param($msg) Write-Host "  [X] $msg"  -ForegroundColor Red }

# ── Check if winget is already present ──────────────────────────────────────────
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Ok "winget is already installed: $(winget --version)"
    exit 0
}

Write-Host ""
Write-Host "  Installing winget on LTSC / Server / Sandbox..." -ForegroundColor Magenta
Write-Host ""

# ── 1. Microsoft.UI.Xaml (required dependency) ───────────────────────────────────
Write-Step "Downloading & installing Microsoft.UI.Xaml 2.8.7..."
Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.7" -OutFile .\microsoft.ui.xaml.2.8.7.zip
Expand-Archive .\microsoft.ui.xaml.2.8.7.zip
Add-AppxPackage .\microsoft.ui.xaml.2.8.7\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.8.appx

# ── 2. VCLibs (required dependency) ──────────────────────────────────────────────
Write-Step "Installing VCLibs x64 14.00..."
Add-AppxPackage -Path "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"

# ── 3. Install winget from GitHub ────────────────────────────────────────────────
Write-Step "Installing latest winget release..."
Add-AppxPackage -Path "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

# ── Cleanup ───────────────────────────────────────────────────────────────────────
Remove-Item .\microsoft.ui.xaml.2.8.7\ -Recurse -ErrorAction SilentlyContinue
Remove-Item .\microsoft.ui.xaml.2.8.7.zip -ErrorAction SilentlyContinue

# ── Verify ────────────────────────────────────────────────────────────────────────
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Ok "winget is ready: $(winget --version)"
} else {
    Write-Fail "winget was installed but is not yet in PATH. You may need to restart your shell."
}
