# setup.ps1
# ─────────────────────────────────────────────────────────────────────────────
# One-shot setup script for a fresh Windows LTSC (or any Windows) install.
# Runs entirely from Windows PowerShell 5.1 – no Store, no winget pre-required.
#
# Handles only the parts that need Administrator:
#   - Installing winget (if missing)
#   - Installing system runtimes (VCRedist, .NET, DirectX, DISM…)
#   - Applying system tweaks (registry, power plan)
#   - Optionally enabling the Microsoft Store via  wsreset -i
#
# USAGE – open "Windows PowerShell" as Administrator, then:
#
#   Remote (no clone needed on a bare machine):
#     Set-ExecutionPolicy Bypass -Scope Process -Force
#     irm https://raw.githubusercontent.com/habibimedwassim/windows-scripts/main/setup.ps1 | iex
#
#   Local (from a cloned repo):
#     Set-ExecutionPolicy Bypass -Scope Process -Force
#     .\setup.ps1
#
# ─────────────────────────────────────────────────────────────────────────────

#Requires -RunAsAdministrator
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# Force TLS 1.2 – required for GitHub / raw.githubusercontent.com.
# Windows PowerShell 5.1 on a fresh LTSC defaults to TLS 1.0/1.1 which will
# cause Invoke-WebRequest / irm to fail when contacting GitHub.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ── Banner ───────────────────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "   Windows LTSC / Clean-Install Setup" -ForegroundColor Cyan
Write-Host "   github.com/habibimedwassim/windows-scripts" -ForegroundColor Cyan
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host ""

# ── Admin check (belt-and-suspenders on top of #Requires) ─────────────────────
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "  [X] Please run this script as Administrator." -ForegroundColor Red
    exit 1
}

# ── Execution policy for this session ─────────────────────────────────────────
Set-ExecutionPolicy Bypass -Scope Process -Force

# ── Resolve paths ──────────────────────────────────────────────────────────────
# When run via  irm … | iex  there is no $PSScriptRoot, so we download the
# scripts subdirectory on the fly.  When run from a cloned repo, we use the
# local folder directly.

$runFromWeb = ($PSScriptRoot -eq '' -or $null -eq $PSScriptRoot)
$repoBase   = 'https://raw.githubusercontent.com/habibimedwassim/windows-scripts/main'
$tmpDir     = "$env:TEMP\_win_setup_$(Get-Random)"

function Get-Script {
    param([string]$name)
    if ($runFromWeb) {
        if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory $tmpDir -Force | Out-Null }
        $dest = "$tmpDir\$name"
        Invoke-WebRequest "$repoBase/scripts/$name" -OutFile $dest
        return $dest
    } else {
        return Join-Path $PSScriptRoot "scripts\$name"
    }
}

# ── Optional: enable Microsoft Store  ─────────────────────────────────────────────────
# wsreset -i reinstalls the Store from the Windows Component Store (no ISO needed).
# Needed for apps that are Store-only: Xbox Game Bar, etc.
Write-Host ""
Write-Host "  Enable Microsoft Store?" -ForegroundColor Yellow
Write-Host "  Required for Store-only packages (e.g. some fonts, optional components)." -ForegroundColor DarkGray
Write-Host "  (uses wsreset -i - pulls from the Windows Component Store, no ISO needed)" -ForegroundColor DarkGray
$storeChoice = Read-Host "  Install Store? [y/N]"
if ($storeChoice -match '^[Yy]') {
    Write-Host "`n  >> Registering Microsoft Store via wsreset -i ..." -ForegroundColor Cyan
    # wsreset -i runs asynchronously by default – Start-Process -Wait ensures we
    # block until it finishes before continuing.
    Start-Process wsreset.exe -ArgumentList '-i' -Wait -NoNewWindow
    Write-Host "  [OK] Store registration complete. You may need to reopen the Store once." -ForegroundColor Green
} else {
    Write-Host "  Skipped." -ForegroundColor DarkGray
}

# ── Menu ───────────────────────────────────────────────────────────────────────
Write-Host "  What would you like to set up? (comma-separated, or 0 for everything)`n" -ForegroundColor Yellow
Write-Host "    0  Full setup  (both steps below)"
Write-Host "    1  Runtimes    - VCRedist, .NET, DirectX, WebView2, XNA, .NET Framework 3.5"
Write-Host "    2  Tweaks      - Classic context menu, Explorer defaults, power plan, accessibility"
Write-Host ""
Write-Host "  Note: PS7, Windows Terminal, eza and Starship are installed separately via" -ForegroundColor DarkGray
Write-Host "        Install-Dev.ps1 - run that as your NORMAL USER after this script." -ForegroundColor DarkGray
Write-Host ""
$raw     = Read-Host "  Choice"
$choices = $raw -split ',' | ForEach-Object { $_.Trim() }
$doAll   = $choices -contains '0'

# ── Step 0: Install winget if missing ─────────────────────────────────────────
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "`n  winget not found - installing it first..." -ForegroundColor Yellow
    & (Get-Script 'Install-Winget.ps1')

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "  [X] winget installation failed. Cannot continue." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n  [OK] winget $(winget --version) detected." -ForegroundColor Green
}

# ── Step 1: Runtimes ──────────────────────────────────────────────────────────
if ($doAll -or $choices -contains '1') {
    Write-Host "`n  ════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  [1/2] Installing Runtimes..." -ForegroundColor Magenta
    Write-Host "  ════════════════════════════════════" -ForegroundColor DarkGray
    & (Get-Script 'Install-Runtimes.ps1')
}

# ── Step 2: Tweaks ────────────────────────────────────────────────────────────
if ($doAll -or $choices -contains '2') {
    Write-Host "`n  ════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  [2/2] Applying Tweaks..." -ForegroundColor Magenta
    Write-Host "  ════════════════════════════════════" -ForegroundColor DarkGray
    & (Get-Script 'Set-Tweaks.ps1')
}

# ── Cleanup temp dir ──────────────────────────────────────────────────────────
if ($runFromWeb -and (Test-Path $tmpDir)) {
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "  Admin setup complete!" -ForegroundColor Green
Write-Host "  ════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Next step: open a NORMAL (non-admin) PowerShell window and run:" -ForegroundColor Yellow
Write-Host ""
if ($runFromWeb) {
    Write-Host "    Set-ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor Cyan
    Write-Host "    irm https://raw.githubusercontent.com/habibimedwassim/windows-scripts/main/scripts/Install-Dev.ps1 | iex" -ForegroundColor Cyan
} else {
    Write-Host "    .\scripts\Install-Dev.ps1" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "  This installs PS7 (interactive - opt out of telemetry/WU updates)," -ForegroundColor DarkGray
Write-Host "  Windows Terminal, eza, Starship, and your PowerShell profile." -ForegroundColor DarkGray
Write-Host ""
