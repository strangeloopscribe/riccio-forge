# ── StartWorkspace.ps1 ────────────────────────────────────────────────────────
# Opens Firefox + VS Code side by side, display-aware.
# Firefox left, VS Code right.
# Detects external (2560x1440) vs laptop (1440x900 effective) and sizes accordingly.
# ─────────────────────────────────────────────────────────────────────────────

Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class WinAPI {
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int W, int H, bool repaint);
    [DllImport("user32.dll")] public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
  }
"@

# ── Detect display ────────────────────────────────────────────────────────────
$screen = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1
$width  = (Get-CimInstance -ClassName Win32_DesktopMonitor | Select-Object -First 1).ScreenWidth

# Fallback via .NET
if (-not $width) {
    Add-Type -AssemblyName System.Windows.Forms
    $width = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
}

if ($width -ge 2000) {
    # External 2560x1440 @ 100% — logical = physical
    $screenW = 2560
    $screenH = 1440
} else {
    # Laptop 2880x1800 @ 200% — logical resolution
    $screenW = 1440
    $screenH = 900
}

$half = [int]($screenW / 2)

# ── Launch Firefox ────────────────────────────────────────────────────────────
$firefox = "C:\Program Files\Mozilla Firefox\firefox.exe"
Start-Process $firefox -ArgumentList "https://github.com/strangeloopscribe/riccio-forge"
Start-Sleep -Seconds 3

# ── Launch VS Code ────────────────────────────────────────────────────────────
$code = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
Start-Process $code -ArgumentList "C:\projects\riccio-forge"
Start-Sleep -Seconds 4

# ── Position windows ──────────────────────────────────────────────────────────
# Firefox — left half
$ffHandle = (Get-Process firefox | Sort-Object StartTime -Descending | Select-Object -First 1).MainWindowHandle
if ($ffHandle) {
    [WinAPI]::ShowWindow($ffHandle, 9)  # restore
    [WinAPI]::MoveWindow($ffHandle, 0, 0, $half, $screenH, $true)
}

# VS Code — right half
$codeHandle = (Get-Process Code | Sort-Object StartTime -Descending | Select-Object -First 1).MainWindowHandle
if ($codeHandle) {
    [WinAPI]::ShowWindow($codeHandle, 9)
    [WinAPI]::MoveWindow($codeHandle, $half, 0, $half, $screenH, $true)
}

Write-Host "Workspace ready. Display: $($screenW)x$($screenH)" -ForegroundColor Green
