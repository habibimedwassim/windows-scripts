#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Download and (optionally) install Nerd Fonts on Windows.

.DESCRIPTION
    Downloads selected Nerd Fonts from GitHub and either saves them locally
    or installs them system-wide (requires Administrator privileges).
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param (
    [switch]$InstallFonts, # If provided, fonts will be installed to C:\Windows\Fonts
    [switch]$Force,       # If provided, overwrite existing fonts without prompting
    [string]$Version = "v3.4.0",
    [string]$DownloadPath = "$env:USERPROFILE\Downloads\NerdFonts"
)

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Font list
$Fonts = @(
    "JetBrainsMono",
    "FiraCode",
    "Hack",
    "CascadiaCode",
    "SourceCodePro",
    "RobotoMono",
    "Meslo",
    "UbuntuMono",
    "Inconsolata",
    "VictorMono",
    "Mononoki",
    "Terminus",
    "Lilex"
)

# Ensure download folder exists
if (-not (Test-Path $DownloadPath)) {
    New-Item -ItemType Directory -Path $DownloadPath | Out-Null
}

# Temp folder for extraction
$TempPath = Join-Path $env:TEMP "NerdFonts_$([System.Guid]::NewGuid().ToString())"
New-Item -ItemType Directory -Path $TempPath | Out-Null

Write-Host "`n=== Nerd Fonts Downloader ===" -ForegroundColor Cyan
Write-Host "Downloading to: $DownloadPath"
if ($InstallFonts) {
    Write-Host "Installation: ENABLED (requires Run as Administrator)" -ForegroundColor Yellow
    if (-not (Test-IsAdmin)) {
        Write-Host "ERROR: Installing fonts requires Administrator privileges. Please re-run this script from an elevated PowerShell session." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Installation: DISABLED (download only)" -ForegroundColor DarkGray
}

$start = Get-Date
$installed = 0
$failed = 0
$skipped = 0

foreach ($Font in $Fonts) {
    Write-Host "`nProcessing: $Font" -ForegroundColor Cyan
    $ZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/$Version/$Font.zip"
    $ZipPath = Join-Path $TempPath "$Font.zip"
    $ExtractPath = Join-Path $TempPath $Font

    # Skip if already exists
    if (Test-Path (Join-Path $DownloadPath $Font)) {
        Write-Host "  → Already exists, skipping." -ForegroundColor Yellow
        $skipped++
        continue
    }

    try {
        Write-Host "  ↓ Downloading..."
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -TimeoutSec 60 -ErrorAction Stop

        Write-Host "  ↳ Extracting..."
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

        # Move to destination folder
        $DestFolder = Join-Path $DownloadPath $Font
        Move-Item -Path $ExtractPath -Destination $DestFolder -Force

        if ($InstallFonts) {
            Write-Host "  ⚙ Installing..."
            $FontFiles = Get-ChildItem -Path $DestFolder -Filter "*.ttf" -Recurse
            foreach ($File in $FontFiles) {
                $FontDest = Join-Path "$env:WINDIR\Fonts" $File.Name

                # If the target already exists, back it up and/or prompt unless -Force is provided
                if (Test-Path $FontDest) {
                    if (-not $Force) {
                        $answer = Read-Host "    Font '$($File.Name)' already exists. Overwrite? (y/N)"
                        if ($answer -notmatch '^[Yy]') {
                            Write-Host "    → Skipping $($File.Name)" -ForegroundColor Yellow
                            continue
                        }
                    }

                    # Backup existing font file
                    $timestamp = [DateTime]::UtcNow.ToString('yyyyMMddHHmmss')
                    $backupPath = "$FontDest.bak.$timestamp"
                    if ($PSCmdlet.ShouldProcess($FontDest, "Backup existing font to $backupPath and overwrite")) {
                        try { Copy-Item -Path $FontDest -Destination $backupPath -Force } catch { Write-Host "    ⚠ Failed to backup existing font: $_" -ForegroundColor Yellow }
                    }
                }

                if ($PSCmdlet.ShouldProcess($FontDest, "Copy $($File.Name) -> $FontDest")) {
                    Copy-Item $File.FullName -Destination $FontDest -Force
                }

                # Register font in Windows Registry
                $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                $FontName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
                if ($PSCmdlet.ShouldProcess($RegPath, "Register font entry: $FontName -> $($File.Name)")) {
                    try {
                        New-ItemProperty -Path $RegPath -Name "$FontName (TrueType)" -Value $File.Name -PropertyType String -Force | Out-Null
                    } catch {
                        Write-Host "    ⚠ Failed to register font in registry: $_" -ForegroundColor Yellow
                    }
                }
            }
            $installed++
            Write-Host "  ✓ Installed $Font" -ForegroundColor Green
        } else {
            Write-Host "  ✓ Downloaded $Font" -ForegroundColor Green
        }
    }
    catch {
    Write-Host ("  ✗ Failed to process {0}: {1}" -f $Font, $_.Exception.Message) -ForegroundColor Red
    $failed++
}
}

# Cleanup
Remove-Item -Path $TempPath -Recurse -Force

$end = Get-Date
$duration = ($end - $start).TotalSeconds

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "  Installed: $installed"
Write-Host "  Skipped:   $skipped"
Write-Host "  Failed:    $failed"
Write-Host "  Time:      $([Math]::Round($duration, 1)) seconds"
Write-Host "Fonts saved to: $DownloadPath"
Write-Host "====================" -ForegroundColor Cyan
