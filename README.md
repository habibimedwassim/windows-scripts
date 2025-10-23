# windows-scripts
Some useful scripts for windows users
# windows-scripts

Some useful scripts for Windows users.

## Install winget on LTSC (no MS Store)

Use the included PowerShell script `Install-Winget-LTSC.ps1` to install the Microsoft "App Installer" (winget) on Windows LTSC builds or other systems without the Microsoft Store. The script downloads the latest MSIX bundle from the official winget (App Installer) GitHub releases and installs it.

Usage (run in an elevated PowerShell prompt):

```powershell
# From this repo folder
.\Install-Winget-LTSC.ps1

# Force reinstall if winget already exists
.\Install-Winget-LTSC.ps1 -Force
```

Notes:
- The script will re-launch itself with elevation if not already running as Administrator.
- You may need to sign out/in or reboot after installation for the `winget` command to be available.

## Install Nerd Fonts

`Install-NerdFonts.ps1` downloads a curated list of Nerd Fonts from the official repo releases and can optionally install them to `C:\Windows\Fonts`.

Behavior and flags:
- `-InstallFonts` (switch): If supplied, the script copies font files into `C:\Windows\Fonts` and registers them in the registry (requires Administrator privileges). If omitted, the script only downloads and extracts the fonts into your Downloads folder (default).
- `-Force` (switch): When installing, overwrite existing font files without prompting. If not supplied, the script prompts before overwriting existing font files and keeps a timestamped backup of any overwritten file.
- `-Version` (string): Release tag to download (default `v3.4.0`).
- `-DownloadPath` (string): Destination folder for downloaded font folders (default: `$env:USERPROFILE\Downloads\NerdFonts`).

PowerShell safety support:
- The script uses `SupportsShouldProcess` so you can run it with `-WhatIf` and `-Confirm`.
- When installing, it requires Administrator privileges and will exit with an error if not elevated.

Examples:

```powershell
# Download fonts only (no elevation required)
.\Install-NerdFonts.ps1

# Download and install system-wide (run PowerShell as Administrator)
.\Install-NerdFonts.ps1 -InstallFonts

# Download a different release to a specific path
.\Install-NerdFonts.ps1 -Version "v3.3.0" -DownloadPath "D:\Fonts\NerdFonts"
```

Notes:
- Installing fonts system-wide requires running PowerShell as Administrator. The script will report how many fonts were installed, skipped, or failed.
- The script creates a temporary extraction folder under `$env:TEMP` and cleans it up after completion.
- If a font folder already exists in the destination, the script skips downloading that font.
