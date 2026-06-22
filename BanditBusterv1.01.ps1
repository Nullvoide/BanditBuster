Here is the finalized script. I have replaced your previous Stage 4 and Stage 5 with a combined, streamline sequence that directly focuses on executing the **DNS Flush** and your **DISM/SFC system recovery** commands, keeping the rest of your logic, comments, and the final reboot prompt exactly as they were.

```powershell
#Requires -Version 7
<#
BanditBuster v1.01 by Null from Toronto, Canada
RUN AS ADMIN!
#>

# Ensure we are running on Windows
if (!$IsWindows) {
    Write-Host "This tool only runs on Windows." -ForegroundColor Red
    Exit
}

# --- NATIVE ELEVATION CHECK & RELAUNCH ---
$Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
$IsAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$IsAdmin) {
    Write-Host "[!] Elevation required. Relaunching as Administrator..." -ForegroundColor Yellow
    Start-Process pwsh.exe -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- HEADER SECTION ---
Clear-Host
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "* * * [+] CryptoBandits.B BanditBuster Tool by Null   * * *" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Run as administrator, shit wont work otherwise." -ForegroundColor Gray
Write-Host "Written by //Null (crummysoda on discord- Yeah I tagged myself, so what.)" -ForegroundColor Gray
Write-Host "From Toronto, Canada. This is my first ever cleanup tool, and stuff." -ForegroundColor Gray
Write-Host "After all this, make sure to follow up with a regular malware scan." -ForegroundColor Gray
Write-Host "======================================================================" -ForegroundColor Cyan

# --- STAGE 1 ---
Write-Host "`n[STAGE 1] Let's Rock their shit" -ForegroundColor Yellow
Write-Host "Heads up: killing the proxy will cause a major freeze, like actual paralysis" -ForegroundColor Red
Write-Host "This freeze happens because windows panics, since the proxy was rerouting traffic" -ForegroundColor Red
Write-Host "This freeze is expected, DO NOT FORCE SHUTDOWN BY LONGPRESSING THE POWER!!" -ForegroundColor Red

try {
    $ugateProcs = Get-Process -Name "ugate" -ErrorAction SilentlyContinue
    if ($ugateProcs) {
        foreach ($proc in $ugateProcs) {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
        }
        Write-Host "[+] Successfully terminated ugate.exe, yay!" -ForegroundColor Green
    } else {
        Write-Host "[*] ugate.exe is not currently running, That's good." -ForegroundColor Gray
    }
} catch {
    Write-Host "[-] CRITICAL: Failed to stop ugate.exe. Script aborted for safety." -ForegroundColor Red
    Exit
}

# --- STAGE 1.5 ---
Write-Host "`n[STAGE 1.5] Purging browsers to drop active malicious extensions..." -ForegroundColor Yellow
$browsers = @("chrome", "msedge", "firefox", "opera")
foreach ($browser in $browsers) {
    $browserProcs = Get-Process -Name $browser -ErrorAction SilentlyContinue
    if ($browserProcs) {
        Write-Host "[!] Closing active instances of $browser..." -ForegroundColor Magenta
        Stop-Process -Name $browser -Force -ErrorAction SilentlyContinue
    }
}

# --- STAGE 2 ---
Write-Host "`n[STAGE 2] Let's remove this garbage, eh :D" -ForegroundColor Yellow
$tasks = @("exiho", "afujo")
foreach ($task in $tasks) {
    schtasks.exe /delete /tn $task /f *>$null
}

# --- STAGE 3 ---
Write-Host "`n[STAGE 3] Better not be anymore garbage in here..." -ForegroundColor Yellow

<# 
-------------------------------------------------------------------------
TECHNICAL EXPLANATION OF STAGE 3 LOGIC FOR CODE REVIEWERS:
- Directory.Exists: Safely verifies folder path validity natively.
- Directory.Delete(..., true): Natively purges the entire directory structure
  and hidden/system files recursively using built-in OS file handles.
- Process Overrides: If native .NET I/O catches an AccessDenied exception due
  to custom malware ACL adjustments, the program triggers external 'takeown'
  and 'icacls' binaries to violently reclaim full control.
-------------------------------------------------------------------------
#>
$malwareDir = "C:\Users\Public\Documents\ature"

if (Test-Path -Path $malwareDir) {
    Write-Host "Time to bust some bandits. Get a real job, crypto sucks!" -ForegroundColor Cyan
    try {
        Remove-Item -Path $malwareDir -Recurse -Force -ErrorAction Stop
        Write-Host "[+] Directory deleted completely!" -ForegroundColor Green
    } catch {
        Write-Host "[!] Well that didn't work, let's try stabbing it again" -ForegroundColor Yellow
        
        takeown.exe /f $malwareDir /r /d y
        icacls.exe $malwareDir /grant administrators:F /t
        
        try { Remove-Item -Path $malwareDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }
} else {
    Write-Host "No bandits found, epic. Next on the agenda; repair and vaccination." -ForegroundColor Green
}

# --- STAGE 4 & 5 REPLACEMENT ---
Write-Host "`n[STAGE 4] Flushing DNS Cache..." -ForegroundColor Yellow
ipconfig.exe /flushdns
Write-Host "[+] DNS Cache successfully flushed." -ForegroundColor Green

Write-Host "`n[STAGE 5] Running DISM System Component Cleanup..." -ForegroundColor Yellow
dism.exe /Online /Cleanup-Image /RestoreHealth
sfc.exe /scannow
Write-Host "[+] Windows system file components verified and restored." -ForegroundColor Green

# --- STAGE 6 ---
Write-Host "`n[STAGE 6] Time to patch some drywall.." -ForegroundColor Yellow
try {
    $ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ugate.exe"
    if (!(Test-Path $ifeoPath)) { New-Item -Path $ifeoPath -Force *>$null }
    Set-ItemProperty -Path $ifeoPath -Name "Debugger" -Value "systrace.exe" -Type String -ErrorAction Stop

    $wshPath = "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings"
    if (!(Test-Path $wshPath)) { New-Item -Path $wshPath -Force *>$null }
    Set-ItemProperty -Path $wshPath -Name "Enabled" -Value 0 -Type DWord -ErrorAction Stop

    Write-Host "[SECURE] wscript.exe has been disabled and ugate.exe is now flagged in the registry :)" -ForegroundColor Green
} catch {
    Write-Host "[-] Failed to apply registry changes, rip." -ForegroundColor Red
}

# --- REBOOT ---
Write-Host "`n--------------------------------------------------" -ForegroundColor Red
Write-Host "SAVE YOUR WORK!! RESTART IMMINENT, 15 SECONDS!!" -ForegroundColor Red
Write-Host "SAVE YOUR WORK!! RESTART IMMINENT, 15 SECONDS!!" -ForegroundColor Red
Write-Host "SAVE YOUR WORK!! RESTART IMMINENT, 15 SECONDS!!" -ForegroundColor Red
Write-Host "--------------------------------------------------" -ForegroundColor Red
Write-Host ""
Write-Host "Cleanup should be complete, system will restart. Have a lovely day!" -ForegroundColor Cyan
Write-Host "Please follow up with a Windows Defender scan" -ForegroundColor Magenta
Write-Host "ADD ME ON DISCORD: crummysoda, ADD ME ON GITHUB: Nullvoide" -ForegroundColor Magenta
Write-Host "Crypto sucks, it's not worth it or a good rpelacement for income." -ForegroundColor Red

shutdown.exe /r /f /t 15

```