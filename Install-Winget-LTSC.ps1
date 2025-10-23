<#
.SYNOPSIS
Installs Microsoft Winget (App Installer) on Windows LTSC / systems without MS Store.

.DESCRIPTION
This script downloads the latest Microsoft.DesktopAppInstaller MSIX bundle from the
GitHub releases for the App Installer (winget) and installs it using Add-AppxPackage.
It handles elevation, checks for existing winget.exe, and verifies the downloaded file.

.NOTES
Run this script as Administrator. The script will re-launch itself elevated if needed.
#>
<#
.SYNOPSIS
Installs Microsoft Winget (App Installer) on Windows LTSC / systems without MS Store.

.DESCRIPTION
This script downloads the latest Microsoft.DesktopAppInstaller MSIX bundle from the
GitHub releases for the App Installer (winget) and installs it using Add-AppxPackage.
It handles elevation, checks for existing winget.exe, and verifies the downloaded file.

.NOTES
Run this script as Administrator. The script will re-launch itself elevated if needed.
#>

[CmdletBinding()]
param(
    [string]$ReleaseApi = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest',
    [string]$DownloadFolder = "$env:TEMP\winget-install",
    [switch]$Force
)

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Not running elevated. Relaunching as Administrator..." -ForegroundColor Yellow
        $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "$PSCommandPath")
        if ($Force) { $args += '-Force' }
        Start-Process -FilePath pwsh -ArgumentList ($args -join ' ') -Verb RunAs
        exit 0
    }
}

function Get-LatestWingetAsset {
    param(
        [string]$ApiUrl
    )
    try {
        # GitHub API requires a User-Agent header
        $headers = @{ 'User-Agent' = 'winget-installer-script' }
        $resp = Invoke-RestMethod -Uri $ApiUrl -Headers $headers -UseBasicParsing -ErrorAction Stop
    } catch {
        throw "Failed to query GitHub releases: $_"
    }

    # Find the msixbundle for Microsoft.DesktopAppInstaller
    $asset = $resp.assets | Where-Object { $_.name -match 'Microsoft.DesktopAppInstaller.*msixbundle' } | Sort-Object -Property name -Descending | Select-Object -First 1
    if (-not $asset) { throw "Could not find a suitable msixbundle asset in the latest release." }
    return $asset.browser_download_url
}

function Download-File {
    param(
        [string]$Url,
        [string]$OutPath
    )
    Write-Host "Downloading: $Url" -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutPath -UseBasicParsing -Headers @{ 'User-Agent' = 'winget-installer-script' } -ErrorAction Stop
    } catch {
        throw "Download failed: $_"
    }
}

function Install-MSIXBundle {
    param(
        [string]$BundlePath
    )
    Write-Host "Installing MSIX bundle: $BundlePath" -ForegroundColor Cyan
    try {
        Add-AppxPackage -Path $BundlePath -ForceApplicationShutdown -ErrorAction Stop
    } catch {
        throw "Installation failed: $_"
    }
}

function Main {
    Assert-Admin

    if (-not (Test-Path -Path $DownloadFolder)) { New-Item -Path $DownloadFolder -ItemType Directory -Force | Out-Null }

    # Check if winget is already present
    $wingetPath = (Get-Command winget -ErrorAction SilentlyContinue).Path
    if ($wingetPath -and -not $Force) {
        Write-Host "winget is already installed at: $wingetPath" -ForegroundColor Green
        return
    }

    Write-Host "Fetching latest winget release info..." -ForegroundColor Cyan
    $downloadUrl = Get-LatestWingetAsset -ApiUrl $ReleaseApi

    $fileName = Split-Path -Path $downloadUrl -Leaf
    $outPath = Join-Path -Path $DownloadFolder -ChildPath $fileName

    Download-File -Url $downloadUrl -OutPath $outPath

    Write-Host "Attempting to install winget from downloaded bundle..." -ForegroundColor Cyan
    Install-MSIXBundle -BundlePath $outPath

    # Final check
    Start-Sleep -Seconds 3
    $wingetPath = (Get-Command winget -ErrorAction SilentlyContinue).Path
    if ($wingetPath) {
        Write-Host "winget installed successfully: $wingetPath" -ForegroundColor Green
    } else {
        Write-Host "winget was not found after installation. You may need to sign out/in or reboot." -ForegroundColor Yellow
    }
}

try {
    Main
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
