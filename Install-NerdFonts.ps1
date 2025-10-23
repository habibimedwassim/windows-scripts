#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Download and (optionally) install Nerd Fonts on Windows.

.DESCRIPTION
    Downloads selected Nerd Fonts from GitHub and either saves them locally
    or installs them system-wide (requires Administrator privileges).
#>

param (
    [switch]$InstallFonts, # If provided, fonts will be installed to C:\Windows\Fonts
    [string]$Version = "v3.4.0",
    [string]$DownloadPath = "$env:USERPROFILE\Downloads\NerdFonts"
)

# Font list
$Fonts = @(
    "JetBrainsMono",
    "FiraCode"
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
                Copy-Item $File.FullName -Destination $FontDest -Force
                # Register font in Windows Registry
                $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                $FontName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
                New-ItemProperty -Path $RegPath -Name "$FontName (TrueType)" -Value $File.Name -PropertyType String -Force | Out-Null
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
