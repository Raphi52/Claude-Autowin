<#
.SYNOPSIS
  Deterministic capture of ANY window (WPF / WinForms / any Windows app) -> PNG.
  "Real render" backend of the front-converge skill for desktop targets. ASCII-only (PS5.1 anti-mojibake).

.DESCRIPTION
  Generic (de-hardcoded from capture-tv.ps1): launches an exe OR attaches to an existing process/window,
  waits ROBUSTLY for the real window (MainWindowHandle != 0, or a title SUBSTRING via EnumWindows), restores
  it if minimized, PrintWindow -> PNG. DETECTS "exited early" (process gone, no window = probable crash) AND
  a near-black capture (WPF DirectX/airspace limitation) instead of returning a silent useless PNG.
  Per-monitor DPI aware so high-DPI windows are not truncated.
  Known intrinsic limit: a window hosting a D3D swapchain / WebView2 / HwndHost (airspace) may still render
  black under PrintWindow -- the near-black detector flags it (exit 0, path emitted, WARN) so the caller knows.

.PARAMETER Exe          Exe to launch (optional). If absent, attach to existing -ProcessName / -WindowTitle / -ProcId.
.PARAMETER ProcessName  Process name (no .exe) to find/kill the window. Derived from -Exe if absent.
.PARAMETER WindowTitle  Title SUBSTRING (case-insensitive, EnumWindows) if MainWindowHandle is not enough.
.PARAMETER ProcId       Exact PID to capture (takes priority over ProcessName).
.PARAMETER KillFirst    Kill the homonymous process BEFORE launching (avoids zombie-lock + single-instance).
.PARAMETER Out          Output folder (default = next to this script).
.PARAMETER TimeoutSec   Max wait for the window (default 40).
.PARAMETER SettleSec    Render-settle wait after the window appears (default 2).
.PARAMETER KeepOpen     Do not kill the app after capture.
.OUTPUTS  PNG path (stdout). Exit 1 if binary missing / app exited without window / no window / zero-size.
          WARN (exit 0, path still emitted) if the capture is near-black (probable DX/airspace).
#>
[CmdletBinding()]
param(
    [string]$Exe,
    [string]$ProcessName,
    [string]$WindowTitle,
    [int]$ProcId = 0,
    [switch]$KillFirst,
    [string]$Out = "$PSScriptRoot\captures",
    [int]$TimeoutSec = 40,
    [int]$SettleSec = 2,
    [switch]$KeepOpen
)
$ErrorActionPreference = 'Stop'

if ($Exe -and -not (Test-Path $Exe) -and -not (Get-Command $Exe -ErrorAction SilentlyContinue)) {
    Write-Host "ROUGE : binaire introuvable ($Exe) - chemin invalide ou pas sur le PATH (build d'abord ?)." -ForegroundColor Red; exit 1
}
if (-not $ProcessName -and $Exe) { $ProcessName = [System.IO.Path]::GetFileNameWithoutExtension($Exe) }
if (-not (Test-Path $Out)) { New-Item -ItemType Directory -Force -Path $Out | Out-Null }

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;using System.Text;using System.Collections.Generic;using System.Runtime.InteropServices;
public class CapWin{
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetWindowTextLength(IntPtr h);
 [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr p);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] static extern IntPtr SetProcessDpiAwarenessContext(IntPtr c);
 public delegate bool EnumProc(IntPtr h, IntPtr p);
 public struct RECT { public int L,T,R,B; }
 // Per-monitor-v2 = (IntPtr)-4 ; best-effort, falls back to SetProcessDPIAware.
 public static void DpiAware(){
   try { if (SetProcessDpiAwarenessContext(new IntPtr(-4)) != IntPtr.Zero) return; } catch {}
   try { SetProcessDPIAware(); } catch {}
 }
 public static IntPtr FindByTitle(string sub){
   IntPtr found = IntPtr.Zero; string s = sub.ToLowerInvariant();
   EnumWindows(delegate(IntPtr h, IntPtr p){
     if(!IsWindowVisible(h)) return true;
     int len = GetWindowTextLength(h); if(len<=0) return true;
     var sb = new StringBuilder(len+1); GetWindowText(h, sb, sb.Capacity);
     if(sb.ToString().ToLowerInvariant().Contains(s)){ found = h; return false; }
     return true;
   }, IntPtr.Zero);
   return found;
 } }
"@

# DPI awareness BEFORE any window/graphics work (else high-DPI capture is truncated).
[CapWin]::DpiAware()

# (1) Optional clean kill + poll-until-released (no raw sleep).
if ($KillFirst -and $ProcessName) {
    Get-Process $ProcessName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    $killDeadline = (Get-Date).AddSeconds(10)
    while ((Get-Date) -lt $killDeadline -and @(Get-Process $ProcessName -ErrorAction SilentlyContinue).Count -gt 0) {
        Start-Sleep -Milliseconds 200
    }
}

# (2) Launch if requested.
if ($Exe) { Start-Process $Exe | Out-Null }

# (3) Robust wait for the real window. Detect exit-early (crash).
$h = [IntPtr]::Zero
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$sawProcess = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 500
    if ($WindowTitle) {
        $fh = [CapWin]::FindByTitle($WindowTitle)   # SUBSTRING match, case-insensitive, visible top-level only
        if ($fh -ne [IntPtr]::Zero) { $h = $fh; break }
    }
    if ($ProcId -gt 0) {
        $p = Get-Process -Id $ProcId -ErrorAction SilentlyContinue
        if (-not $WindowTitle -and $p -and $p.MainWindowHandle -ne 0) { $h = $p.MainWindowHandle; break }
        if ($sawProcess -and -not $p) { Write-Host "ROUGE : PID $ProcId sorti sans fenetre = crash probable." -ForegroundColor Red; exit 1 }
        if ($p) { $sawProcess = $true }
    } elseif ($ProcessName) {
        # Crash-detect runs even in -WindowTitle mode (don't go blind for the full timeout on early-exit).
        $procs = @(Get-Process $ProcessName -ErrorAction SilentlyContinue)
        if ($procs.Count -gt 0) { $sawProcess = $true }
        if (-not $WindowTitle) {
            $ui = $procs | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
            if ($ui) { $h = $ui.MainWindowHandle; break }
        }
        if ($sawProcess -and $procs.Count -eq 0) {
            Write-Host "ROUGE : l'app a demarre puis SORTI sans fenetre = crash probable (XAML / init ?)." -ForegroundColor Red
            exit 1
        }
    }
}
if ($h -eq [IntPtr]::Zero) { Write-Host "ROUGE : pas de fenetre apres ${TimeoutSec}s (app figee ? mauvais ProcessName/Title ?)." -ForegroundColor Red; exit 1 }

# (3b) Restore if minimized (else GetWindowRect gives off-screen junk dims -> useless capture).
if ([CapWin]::IsIconic($h)) {
    [CapWin]::ShowWindow($h, 9) | Out-Null   # SW_RESTORE
    Start-Sleep -Milliseconds 400
}

if ($SettleSec -gt 0) { Start-Sleep -Seconds $SettleSec }  # sleep-ok: settle du rendu (WPF post-InitializeAsync), aucun signal de fin-de-rendu fiable a poller. NE PAS retirer ce token (anti-flaky.ps1 bloque -Seconds >=2 sans lui).

# (4) PrintWindow -> PNG, with guaranteed GDI cleanup (try/finally) even if PrintWindow throws.
[CapWin+RECT]$r = New-Object CapWin+RECT
[CapWin]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.R - $r.L; $ht = $r.B - $r.T
if ($w -le 0 -or $ht -le 0) { Write-Host "ROUGE : fenetre de taille nulle/hors-ecran (minimisee ?)." -ForegroundColor Red; exit 1 }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$safe = ($ProcessName, $WindowTitle, 'win' | Where-Object { $_ } | Select-Object -First 1) -replace '[^\w.-]','_'
$png = Join-Path $Out "$safe-$stamp.png"
$bmp = $null; $g = $null; $hdc = [IntPtr]::Zero; $pwOk = $false
try {
    $bmp = New-Object Drawing.Bitmap($w, $ht)
    $g = [Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    $pwOk = [CapWin]::PrintWindow($h, $hdc, 2)   # flag 2 = PW_RENDERFULLCONTENT ; capture le bool de retour
    $g.ReleaseHdc($hdc); $hdc = [IntPtr]::Zero
    $bmp.Save($png)
}
finally {
    if ($hdc -ne [IntPtr]::Zero -and $g) { try { $g.ReleaseHdc($hdc) } catch {} }
    if ($g) { $g.Dispose() }
    # keep $bmp alive for the near-black sample below; disposed after.
}
if (-not $pwOk) { Write-Host "JAUNE : PrintWindow a renvoye FALSE - capture potentiellement incomplete/noire (independamment du ratio near-black)." -ForegroundColor Yellow }

# (4b) Near-black detection (WPF DirectX / WebView2 / airspace -> PrintWindow renders black).
$dark = 0; $samples = 0
$stepX = [Math]::Max(1, [int]($w/12)); $stepY = [Math]::Max(1, [int]($ht/12))
for ($x = 0; $x -lt $w; $x += $stepX) {
    for ($y = 0; $y -lt $ht; $y += $stepY) {
        $px = $bmp.GetPixel($x, $y); $samples++
        if (($px.R + $px.G + $px.B) -lt 24) { $dark++ }
    }
}
$bmp.Dispose()
$ratio = if ($samples -gt 0) { $dark / $samples } else { 0 }
if ($ratio -ge 0.98) {
    Write-Host "JAUNE : capture quasi-NOIRE ($([int]($ratio*100))% pixels noirs) - probable surface DirectX/WebView2/airspace non capturable par PrintWindow." -ForegroundColor Yellow
    Write-Host "  -> limite intrinseque ; pour ces controles, capturer via l'app elle-meme (RenderTargetBitmap cote WPF) ou un outil ecran." -ForegroundColor Yellow
}
Write-Host "VERT : $png ($w x $ht)" -ForegroundColor Green
Write-Output $png

if (-not $KeepOpen -and $ProcessName) { Get-Process $ProcessName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }
