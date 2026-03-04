# Set-Tweaks.ps1
# Applies quality-of-life registry and system tweaks to a fresh Windows install.
#
# Tweaks applied
#   1. Restore classic (Windows 10-style) right-click context menu
#   2. Show file extensions in Explorer
#   3. Show hidden files and folders
#   4. Disable sticky/filter/toggle keys prompts
#   5. Disable mouse enhance pointer precision (acceleration)
#   6. Disable Game DVR / background recording          (commented out – may break recording features)
#   7. Disable Xbox Game Bar (ms-gamingoverlay popup)     (commented out – modifies HKLM policies)
#   8. Enable Hardware-Accelerated GPU Scheduling (HAGS)  (commented out – may cause issues on some GPUs)
#   9. Set power plan to High Performance                 (commented out – aggressive for laptops)
#  10. Restore / undo classic Windows Photo Viewer (prompted)

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

# # ════════════════════════════════════════════════════════════════════════════════
# Write-Header "Game DVR - Disable Background Recording"
# # ════════════════════════════════════════════════════════════════════════════════

# # Xbox Game Bar background recording (Game DVR) consumes CPU and GPU even when
# # you are not actively recording. Disable it for a clean baseline.
# $gameDVRUser = 'HKCU:\System\GameConfigStore'
# Ensure-Key $gameDVRUser
# Set-ItemProperty -Path $gameDVRUser -Name 'GameDVR_Enabled'              -Value 0 -Type DWord
# Set-ItemProperty -Path $gameDVRUser -Name 'GameDVR_FSEBehaviorMode'      -Value 2 -Type DWord
# Set-ItemProperty -Path $gameDVRUser -Name 'GameDVR_HonorUserFSEBehavior' -Value 1 -Type DWord

# $gameDVRCapture = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR'
# Ensure-Key $gameDVRCapture
# Set-ItemProperty -Path $gameDVRCapture -Name 'AppCaptureEnabled' -Value 0 -Type DWord

# $gameDVRPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
# Ensure-Key $gameDVRPolicy
# Set-ItemProperty -Path $gameDVRPolicy -Name 'AllowGameDVR' -Value 0 -Type DWord
# Write-Ok "Game DVR background recording disabled."

# # ════════════════════════════════════════════════════════════════════════════════
# Write-Header "Xbox Game Bar - Disable (suppress ms-gamingoverlay popup)"
# # ════════════════════════════════════════════════════════════════════════════════

# # When Xbox Game Bar is not installed, Windows still tries to launch it via the
# # ms-gamingoverlay URI scheme (triggered by Win+G or game start hooks), causing
# # an annoying "Try the new Xbox app" popup.  Disabling these registry keys
# # prevents the popup from appearing entirely.
# $gameBarKey = 'HKCU:\Software\Microsoft\GameBar'
# Ensure-Key $gameBarKey
# Set-ItemProperty -Path $gameBarKey -Name 'ShowStartupPanel'    -Value 0 -Type DWord
# Set-ItemProperty -Path $gameBarKey -Name 'AutoGameModeEnabled'  -Value 0 -Type DWord
# Set-ItemProperty -Path $gameBarKey -Name 'AllowAutoGameMode'    -Value 0 -Type DWord

# # Also block the Game Bar via policy (machine-wide)
# $gameBarPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
# Ensure-Key $gameBarPolicy
# Set-ItemProperty -Path $gameBarPolicy -Name 'AllowGameDVR' -Value 0 -Type DWord

# Write-Ok "Xbox Game Bar disabled (ms-gamingoverlay popup suppressed)."

# # ════════════════════════════════════════════════════════════════════════════════
# Write-Header "Hardware-Accelerated GPU Scheduling (HAGS)"
# # ════════════════════════════════════════════════════════════════════════════════

# # HAGS lets the GPU manage its own memory scheduling instead of the CPU,
# # reducing frametime variance. Supported on GTX 1000+ / RX 5000+ with up-to-date
# # drivers. Safe to enable on unsupported hardware (setting is silently ignored).
# $hagsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
# Ensure-Key $hagsKey
# Set-ItemProperty -Path $hagsKey -Name 'HwSchMode' -Value 2 -Type DWord
# Write-Ok "Hardware-Accelerated GPU Scheduling enabled (takes effect after reboot)."

# # ════════════════════════════════════════════════════════════════════════════════
# Write-Header "Power Plan - High Performance"
# $hp = powercfg /l | Select-String 'High performance'
# if ($hp) {
#     $guid = ($hp -split '\s+')[3]
#     powercfg /setactive $guid
#     Write-Ok "High Performance plan active ($guid)."
# } else {
#     # On some editions the plan isn't listed – duplicate the Balanced plan
#     Write-Warn "High Performance plan not found; duplicating Balanced..."
#     powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
#     $hp2 = powercfg /l | Select-String 'High performance'
#     if ($hp2) {
#         $guid2 = ($hp2 -split '\s+')[3]
#         powercfg /setactive $guid2
#         Write-Ok "High Performance plan created and activated."
#     }
# }

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Windows Photo Viewer"
# ════════════════════════════════════════════════════════════════════════════════

# The classic Windows Photo Viewer is still present in Windows 10/11 but hidden.
# A .reg file import is the most reliable way to restore (or undo) it.
$repoBase   = 'https://raw.githubusercontent.com/habibimedwassim/windows-scripts/main'
$localProfile = Join-Path $PSScriptRoot '..\profile'

function Get-RegFile {
    param([string]$name)
    $local = Join-Path $localProfile $name
    if (Test-Path $local) { return $local }
    # Running from web – download to temp
    $tmp = Join-Path $env:TEMP $name
    Invoke-WebRequest "$repoBase/profile/$name" -OutFile $tmp -UseBasicParsing
    return $tmp
}

Write-Host ""
Write-Host "  [1] Restore Windows Photo Viewer" -ForegroundColor Cyan
Write-Host "  [2] Undo   (remove Photo Viewer associations)" -ForegroundColor Cyan
Write-Host "  [3] Skip" -ForegroundColor Cyan
$pvChoice = Read-Host "  Choose [1/2/3]"

switch ($pvChoice) {
    '1' {
        try {
            $regRestore = Get-RegFile 'windows_photo_viewer.reg'
            reg import "$regRestore" 2>$null
            Write-Ok "Windows Photo Viewer restored. Set it as default in Settings > Default Apps."
        } catch {
            Write-Warn "Failed to get reg file: $_"
        }
    }
    '2' {
        try {
            $regUndo = Get-RegFile 'windows_photo_viewer_undo.reg'
            reg import "$regUndo" 2>$null
            Write-Ok "Windows Photo Viewer associations removed."
        } catch {
            Write-Warn "Failed to get reg file: $_"
        }
    }
    default { Write-Step "Skipped." }
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
