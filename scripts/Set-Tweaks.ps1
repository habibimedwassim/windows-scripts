# Set-Tweaks.ps1
# Applies quality-of-life registry and system tweaks to a fresh Windows install.
#
# Tweaks applied
#   1. Restore classic (Windows 10-style) right-click context menu
#   2. Show file extensions in Explorer
#   3. Show hidden files and folders
#   4. Disable sticky/filter/toggle keys prompts
#   5. Disable mouse enhance pointer precision (acceleration)
#   6. Disable Game DVR / background recording
#   7. Enable Hardware-Accelerated GPU Scheduling (HAGS)
#   8. Set power plan to High Performance

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Continue'

function Write-Header { param($t) Write-Host "`n  -- $t --" -ForegroundColor Magenta }
function Write-Step   { param($t) Write-Host "  >> $t"     -ForegroundColor Cyan }
function Write-Ok     { param($t) Write-Host "  [OK] $t"   -ForegroundColor Green }
function Write-Warn   { param($t) Write-Host "  [!] $t"    -ForegroundColor Yellow }

# Helper – ensures a registry key exists before setting values under it
function Ensure-Key { param($path) if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null } }

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Context Menu - Restore Classic (Windows 10) Style"
# ════════════════════════════════════════════════════════════════════════════════

$ctxKey = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
Ensure-Key $ctxKey
# Setting the (Default) value to an empty string re-enables the classic menu
Set-ItemProperty -Path $ctxKey -Name '(Default)' -Value '' -Type String
Write-Ok "Classic context menu enabled. (Explorer restart required)"

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "File Explorer Defaults"
# ════════════════════════════════════════════════════════════════════════════════

$explorerAdv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

Write-Step "Show file extensions..."
Set-ItemProperty -Path $explorerAdv -Name 'HideFileExt'           -Value 0 -Type DWord
Write-Ok "Done."

Write-Step "Show hidden files and folders..."
Set-ItemProperty -Path $explorerAdv -Name 'Hidden' -Value 1 -Type DWord
Write-Ok "Done."

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Keyboard / Accessibility Annoyances"
# ════════════════════════════════════════════════════════════════════════════════

$toggleFlags = 'HKCU:\Control Panel\Accessibility\ToggleKeys'
$stickyFlags = 'HKCU:\Control Panel\Accessibility\StickyKeys'
$filterFlags = 'HKCU:\Control Panel\Accessibility\Keyboard Response'

# Bit 1 of Flags = HotKey enabled.  Clear it by setting to decimal value with bit 1 off.
foreach ($key in @($toggleFlags, $stickyFlags, $filterFlags)) {
    Ensure-Key $key
    # Default flag value with hotkey disabled
    Set-ItemProperty -Path $key -Name 'Flags' -Value '506' -Type String
}
Write-Ok "Sticky / Filter / Toggle key prompts disabled."

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Mouse - Disable Enhance Pointer Precision"
# ════════════════════════════════════════════════════════════════════════════════

# Mouse acceleration ruins consistent aim in games. These three values together
# fully disable Windows pointer acceleration ("Enhance pointer precision").
$mouseKey = 'HKCU:\Control Panel\Mouse'
Set-ItemProperty -Path $mouseKey -Name 'MouseSpeed'      -Value '0' -Type String
Set-ItemProperty -Path $mouseKey -Name 'MouseThreshold1' -Value '0' -Type String
Set-ItemProperty -Path $mouseKey -Name 'MouseThreshold2' -Value '0' -Type String
Write-Ok "Mouse acceleration disabled."

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Game DVR - Disable Background Recording"
# ════════════════════════════════════════════════════════════════════════════════

# Xbox Game Bar background recording (Game DVR) consumes CPU and GPU even when
# you are not actively recording. Disable it for a clean baseline.
# Note: if you want to USE Game Bar captures, comment these lines out.
$gameDVRUser = 'HKCU:\System\GameConfigStore'
Ensure-Key $gameDVRUser
Set-ItemProperty -Path $gameDVRUser -Name 'GameDVR_Enabled'             -Value 0 -Type DWord
Set-ItemProperty -Path $gameDVRUser -Name 'GameDVR_FSEBehaviorMode'     -Value 2 -Type DWord
Set-ItemProperty -Path $gameDVRUser -Name 'GameDVR_HonorUserFSEBehavior' -Value 1 -Type DWord

$gameDVRPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
Ensure-Key $gameDVRPolicy
Set-ItemProperty -Path $gameDVRPolicy -Name 'AllowGameDVR' -Value 0 -Type DWord
Write-Ok "Game DVR background recording disabled."

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Hardware-Accelerated GPU Scheduling (HAGS)"
# ════════════════════════════════════════════════════════════════════════════════

# HAGS lets the GPU manage its own memory scheduling instead of the CPU,
# reducing frametime variance. Supported on GTX 1000+ / RX 5000+ with up-to-date
# drivers. Safe to enable on unsupported hardware (setting is silently ignored).
$hagsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
Ensure-Key $hagsKey
Set-ItemProperty -Path $hagsKey -Name 'HwSchMode' -Value 2 -Type DWord
Write-Ok "Hardware-Accelerated GPU Scheduling enabled (takes effect after reboot)."

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Power Plan - High Performance"
$hp = powercfg /l | Select-String 'High performance'
if ($hp) {
    $guid = ($hp -split '\s+')[3]
    powercfg /setactive $guid
    Write-Ok "High Performance plan active ($guid)."
} else {
    # On some editions the plan isn't listed – duplicate the Balanced plan
    Write-Warn "High Performance plan not found; duplicating Balanced..."
    powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
    $hp2 = powercfg /l | Select-String 'High performance'
    if ($hp2) {
        $guid2 = ($hp2 -split '\s+')[3]
        powercfg /setactive $guid2
        Write-Ok "High Performance plan created and activated."
    }
}

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Restart Explorer to Apply Visual Changes"
# ════════════════════════════════════════════════════════════════════════════════

Write-Step "Restarting explorer.exe..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 1500
Start-Process explorer.exe
Write-Ok "Explorer restarted."

Write-Host ""
Write-Ok "All tweaks applied."
