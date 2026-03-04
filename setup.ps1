# setup.ps1
# ─────────────────────────────────────────────────────────────────────────────
# One-shot setup script for a fresh Windows LTSC (or any Windows) install.
# Runs entirely from Windows PowerShell 5.1 – no Store, no winget pre-required.
#
# Automatically detects whether it is running elevated (Administrator) or not:
#
#   Administrator  →  installs winget, runtimes, and applies system tweaks
#   Normal user    →  installs PS7, Windows Terminal, eza, Starship, profile
#
# USAGE
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

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# Force TLS 1.2 – required for GitHub / raw.githubusercontent.com.
# Windows PowerShell 5.1 on a fresh LTSC defaults to TLS 1.0/1.1 which will
# cause Invoke-WebRequest / irm to fail when contacting GitHub.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ── Banner ───────────────────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "   Windows LTSC / Clean-Install Setup" -ForegroundColor Cyan
Write-Host "   github.com/habibimedwassim/windows-scripts" -ForegroundColor Cyan
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host ""

if ($isAdmin) {
    Write-Host "  Running as Administrator - admin setup" -ForegroundColor Green
} else {
    Write-Host "  Running as Normal User - dev/shell setup" -ForegroundColor Green
}
Write-Host ""

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

function Get-ProfileFile {
    param([string]$name)
    if ($runFromWeb) {
        if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory $tmpDir -Force | Out-Null }
        $dest = "$tmpDir\$name"
        Invoke-WebRequest "$repoBase/profile/$name" -OutFile $dest
        return $dest
    } else {
        return Join-Path $PSScriptRoot "profile\$name"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  ADMIN PATH  –  winget, runtimes, tweaks
# ══════════════════════════════════════════════════════════════════════════════
if ($isAdmin) {

    # ── Show what will be done ────────────────────────────────────────────────
    Write-Host "  The following will be installed and applied:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Runtimes:" -ForegroundColor Magenta
    Write-Host "    - VC++ Redistributables (2005-2022)"
    Write-Host "    - .NET Desktop Runtimes"
    Write-Host "    - Windows App Runtime"
    Write-Host "    - Edge WebView2 Runtime"
    Write-Host "    - DirectX End-User Runtime"
    Write-Host "    - OpenAL"
    Write-Host "    - XNA Framework 4.0"
    Write-Host "    - 7-Zip"
    Write-Host "    - K-Lite Codec Pack"
    Write-Host ""
    Write-Host "  Tweaks:" -ForegroundColor Magenta
    Write-Host "    - Classic right-click menu"
    Write-Host "    - Show file extensions"
    Write-Host "    - Show hidden files"
    Write-Host "    - Disable accessibility hotkeys"
    Write-Host "    - Disable mouse acceleration"
    Write-Host "    - Restore Windows Photo Viewer (optional, prompted)"
    Write-Host ""

    $confirm = Read-Host "  Proceed? (Y/N)"
    if ($confirm -notin @('Y','y')) {
        Write-Host "`n  Aborted." -ForegroundColor Red
        exit 0
    }

    # ── Install winget if missing ─────────────────────────────────────────────
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

    # ── Step 1: Runtimes ──────────────────────────────────────────────────────
    Write-Host "`n  ════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  [1/2] Installing Runtimes..." -ForegroundColor Magenta
    Write-Host "  ════════════════════════════════════" -ForegroundColor DarkGray
    & (Get-Script 'Install-Runtimes.ps1')

    # ── Step 2: Tweaks ────────────────────────────────────────────────────────
    Write-Host "`n  ════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  [2/2] Applying Tweaks..." -ForegroundColor Magenta
    Write-Host "  ════════════════════════════════════" -ForegroundColor DarkGray
    # Pre-download .reg files so Set-Tweaks.ps1 can find them in $tmpDir / $PSScriptRoot
    Get-ProfileFile 'windows_photo_viewer.reg'     | Out-Null
    Get-ProfileFile 'windows_photo_viewer_undo.reg' | Out-Null

    & (Get-Script 'Set-Tweaks.ps1')

    # ── Done (admin) ──────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  ════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  Admin setup complete!" -ForegroundColor Green
    Write-Host "  ════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Next: run this same script again from a NORMAL (non-admin) shell" -ForegroundColor Yellow
    Write-Host "  to install PS7, Windows Terminal, eza, Starship, and your profile." -ForegroundColor Yellow
    Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
#  NORMAL USER PATH  –  dev tools & shell setup
# ══════════════════════════════════════════════════════════════════════════════
} else {

    # ── Show what will be done ────────────────────────────────────────────────
    Write-Host "  The following will be installed:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Dev / Shell Tools:" -ForegroundColor Magenta
    Write-Host "    - PowerShell 7"
    Write-Host "    - Windows Terminal"
    Write-Host "    - eza (modern ls)"
    Write-Host "    - Starship prompt"
    Write-Host "    - PowerShell profile"
    Write-Host ""

    $confirm = Read-Host "  Proceed? (Y/N)"
    if ($confirm -notin @('Y','y')) {
        Write-Host "`n  Aborted." -ForegroundColor Red
        exit 0
    }

    & (Get-Script 'Install-Dev.ps1')
}

# ── Cleanup temp dir ──────────────────────────────────────────────────────────
if ($runFromWeb -and (Test-Path $tmpDir)) {
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
