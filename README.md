# windows-scripts

A collection of PowerShell scripts to fully set up a fresh Windows LTSC (or any clean Windows) install for **gaming, content creation, and development** — no Microsoft Store required.

---

## What it does

| Step | Script | Run as | Description |
|------|--------|--------|-------------|
| 0 | `Install-Winget.ps1` | Admin | Installs winget from GitHub (no Store needed) |
| 1 | `Install-Runtimes.ps1` | Admin | VCRedist, .NET, DirectX, WebView2, XNA, 7-Zip, codecs |
| 2 | `Set-Tweaks.ps1` | Admin | Classic context menu, Explorer defaults, accessibility, Photo Viewer |
| 3 | `Install-Dev.ps1` | **User** | PS7 (interactive), Terminal, eza, Starship, PS profile |

---

## Quick start

> **On LTSC** PowerShell 7 is not pre-installed — open **Windows PowerShell** (the built-in one) as Administrator.

**Step 1 – Admin setup** (runtimes + tweaks). Open **Windows PowerShell as Administrator**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
irm https://raw.githubusercontent.com/habibimedwassim/windows-scripts/main/setup.ps1 | iex
```

The script shows a summary of everything that will be installed and applied, then asks you to confirm with **Y/N** before proceeding. It handles winget install if missing, all runtimes, and system tweaks.

**Step 2 – Shell setup** (run as your normal user, not elevated):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
irm https://raw.githubusercontent.com/habibimedwassim/windows-scripts/main/setup.ps1 | iex
```

The script shows the list of tools that will be installed and asks for **Y/N** confirmation. It launches the PS7 MSI interactively (so you can uncheck telemetry and the Windows Update auto-update option), then silently installs Windows Terminal, eza, and Starship, and deploys your PowerShell profile.

---

## Scripts

### `setup.ps1`

The entry point. Runs cleanly from a remote `irm … | iex` one-liner or from a local clone. Automatically detects whether it is running elevated or not:

**As Administrator** — shows a bullet-point summary and asks **Y/N**:

```
Runtimes:
  - VC++ Redistributables (2005-2022)
  - .NET Desktop Runtimes
  - Windows App Runtime
  - Edge WebView2 Runtime
  - DirectX End-User Runtime
  - OpenAL
  - XNA Framework 4.0
  - 7-Zip
  - K-Lite Codec Pack

Tweaks:
  - Classic right-click menu
  - Show file extensions
  - Show hidden files
  - Disable accessibility hotkeys
  - Disable mouse acceleration
  - Restore Windows Photo Viewer (optional, prompted)
```

**As Normal User** — shows the dev/shell tools and asks **Y/N**:

```
Dev / Shell Tools:
  - PowerShell 7
  - Windows Terminal
  - eza (modern ls)
  - Starship prompt
  - PowerShell profile
```

At the end of the admin path it prints instructions to re-run as a normal user.

---

### `scripts/Install-Winget.ps1`

Installs [winget](https://github.com/microsoft/winget-cli) on machines that don't have it (LTSC, Server, Sandbox). Downloads:

- `Microsoft.VCLibs.x64.14.00.Desktop.appx` (via `aka.ms` redirect)
- `Microsoft.UI.Xaml 2.8` (from NuGet, no Store required)
- Latest `Microsoft.DesktopAppInstaller` msixbundle from the GitHub release

---

### `scripts/Install-Runtimes.ps1`

Installs all common runtimes that games and apps depend on:

- Visual C++ Redistributables (2005, 2008, 2010, 2012, 2013, 2015+) — x86 & x64
- .NET Desktop Runtime (3.1, 5, 6, 7, 8, 9, 10)
- Windows App Runtime 1.8
- Microsoft Edge WebView2 Runtime
- DirectX End-User Runtime
- OpenAL
- XNA Framework 4.0
- 7-Zip
- K-Lite Codec Pack Standard

---

### `scripts/Install-Dev.ps1`

> **Run as your normal user — not as Administrator.**  
> winget installs user-scoped by default when not elevated, which is correct for these tools. The script will refuse to run if it detects an elevated session.

Installs the base shell environment:

- **PowerShell 7** — launched via `winget install -i` (interactive MSI) so you can uncheck telemetry and the "update via Windows Update" option
- **Windows Terminal**
- **eza** (modern `ls`)
- **Starship** prompt
- Deploys `profile/Microsoft.PowerShell_profile.ps1` to the PS7 profile path

---

### `scripts/Set-Tweaks.ps1`

Registry and system tweaks (requires Admin):

- **Classic context menu** — restores the Windows 10-style right-click menu
- Show file extensions in Explorer
- Show hidden files and folders
- Disable Sticky / Filter / Toggle key prompts
- Disable mouse enhance pointer precision (acceleration)
- **Windows Photo Viewer** — prompts to restore the classic image viewer or undo the change (imports `profile/windows_photo_viewer.reg` / `windows_photo_viewer_undo.reg`)

---

### `profile/Microsoft.PowerShell_profile.ps1`

Configures `eza`-based `ls` aliases and initialises the Starship prompt.

---

### `profile/windows_photo_viewer.reg` / `windows_photo_viewer_undo.reg`

Registry files that restore (or remove) the classic **Windows Photo Viewer** on Windows 10/11. Imported automatically by `Set-Tweaks.ps1` when the user chooses the Photo Viewer option. Can also be double-clicked manually.  
Installed automatically by `Install-Dev.ps1`, or copy it manually to:

```
%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

---

## Notes

- `setup.ps1` and all `Install-Runtimes` / `Set-Tweaks` / `Install-Winget` scripts require **Administrator** privileges.
- `Install-Dev.ps1` should be run as a **normal user** (installs per-user by default).
- Scripts are designed to be idempotent — safe to re-run; winget will skip already-installed packages.
- `irm … | iex` downloads each sub-script from GitHub at runtime so no local clone is needed on a bare machine.
- This repo intentionally does **not** install opinionated apps (editors, browsers, games, etc.). It is a base layer — install whatever you want on top.

---

## License

MIT
