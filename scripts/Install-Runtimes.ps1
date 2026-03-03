# Install-Runtimes.ps1
# Installs all common Windows runtimes and redistributables needed for gaming / apps:
#   - Visual C++ Redistributables (2005 – 2022)
#   - .NET Desktop Runtime (3.1, 5-10)
#   - .NET Framework 3.5 (via DISM)
#   - Windows App Runtime
#   - Microsoft Edge WebView2
#   - DirectX End-User Runtime
#   - OpenAL
#   - XNA Framework 4.0 Redistributable
#   - Xbox Game Bar (Store-only, skipped if msstore source unavailable)

param(
    [switch]$Quiet   # pass -Quiet to suppress individual winget progress bars
)

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Continue'

function Write-Header { param($t) Write-Host "`n  -- $t --" -ForegroundColor Magenta }
function Write-Step   { param($t) Write-Host "  >> $t"     -ForegroundColor Cyan }
function Write-Ok     { param($t) Write-Host "  [OK] $t"   -ForegroundColor Green }
function Write-Warn   { param($t) Write-Host "  [!] $t"    -ForegroundColor Yellow }

$wingetArgs = @('install', '--exact', '--accept-package-agreements', '--accept-source-agreements', '--silent')

function wgi {
    param([string]$id)
    Write-Step "Installing $id"
    winget @wingetArgs --id $id
}

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Visual C++ Redistributables"
# ════════════════════════════════════════════════════════════════════════════════

$vcRedists = @(
    'Microsoft.VCRedist.2005.x86',
    'Microsoft.VCRedist.2005.x64',
    'Microsoft.VCRedist.2008.x86',
    'Microsoft.VCRedist.2008.x64',
    'Microsoft.VCRedist.2010.x86',
    'Microsoft.VCRedist.2010.x64',
    'Microsoft.VCRedist.2012.x86',
    'Microsoft.VCRedist.2012.x64',
    'Microsoft.VCRedist.2013.x86',
    'Microsoft.VCRedist.2013.x64',
    'Microsoft.VCRedist.2015+.x86',
    'Microsoft.VCRedist.2015+.x64'
)

foreach ($id in $vcRedists) { wgi $id }

# ════════════════════════════════════════════════════════════════════════════════
Write-Header ".NET Desktop Runtimes"
# ════════════════════════════════════════════════════════════════════════════════

$dotnetRuntimes = @(
    'Microsoft.DotNet.DesktopRuntime.3_1',
    'Microsoft.DotNet.DesktopRuntime.5',
    'Microsoft.DotNet.DesktopRuntime.6',
    'Microsoft.DotNet.DesktopRuntime.7',
    'Microsoft.DotNet.DesktopRuntime.8',
    'Microsoft.DotNet.DesktopRuntime.9',
    'Microsoft.DotNet.DesktopRuntime.10'
)

foreach ($id in $dotnetRuntimes) { wgi $id }

# # ════════════════════════════════════════════════════════════════════════════════
# Write-Header ".NET Framework 3.5  (DISM)"
# # ════════════════════════════════════════════════════════════════════════════════

# Write-Step "Enabling .NET Framework 3.5 via DISM..."
# $result = dism /online /enable-feature /featurename:NetFx3 /all /norestart 2>&1
# if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010) {
#     Write-Ok ".NET Framework 3.5 enabled (reboot may be required)."
# } else {
#     Write-Warn ".NET Framework 3.5 DISM exited with code $LASTEXITCODE - it may already be enabled."
# }

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Windows App Runtime & WebView2"
# ════════════════════════════════════════════════════════════════════════════════

wgi 'Microsoft.WindowsAppRuntime.1.8'
wgi 'Microsoft.EdgeWebView2Runtime'

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "DirectX End-User Runtime"
# ════════════════════════════════════════════════════════════════════════════════

wgi 'Microsoft.DirectX'

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "OpenAL"
# ════════════════════════════════════════════════════════════════════════════════

# Required by many games: Source engine titles, id Tech games, Unity games, etc.
wgi 'OpenAL.OpenAL'

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Xbox Game Bar  (9NZKPSTSNW4P)"
# ════════════════════════════════════════════════════════════════════════════════

# Game Bar is stripped from LTSC. It provides the gaming overlay (FPS counter,
# screen capture, performance widgets) and is required by some games/launchers.
# It lives in the MS Store, so the msstore winget source must be available.
# On LTSC without the Store this will likely fail – a manual sideload is needed.
Write-Step "Installing Xbox Game Bar from msstore..."
winget install 9NZKPSTSNW4P --accept-source-agreements --silent 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warn "Xbox Game Bar install failed - msstore source may not be available on LTSC."
    Write-Warn "Sideload guide: https://github.com/microsoft/xbox-game-bar"
}

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "XNA Framework 4.0 Redistributable"
# ════════════════════════════════════════════════════════════════════════════════

# Required by older indie games (Terraria legacy, Stardew Valley pre-1.6, etc.)
Write-Step "Installing XNA Framework 4.0..."
winget install --exact --id Microsoft.XNARedist --accept-package-agreements --accept-source-agreements --silent

# ════════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Ok "Runtime installation complete."
