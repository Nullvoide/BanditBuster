@echo off
cls

echo ======================================================================
echo * * *   [+] CryptoBandits.B BanditBuster Tool by Null  * * *
echo ======================================================================
echo Run as administrator, shit wont work otherwise.
echo Written by //Null (crummysoda on discord- Yeah I tagged myself, so what.)
echo From Toronto, Canada. This is my first ever cleanup tool, and stuff.
echo After all this, make sure to follow up with a regular malware scan.
echo ======================================================================

echo [STAGE 1] Let's end this proxy's life. 
echo Heads up: killing the proxy will cause a major freeze, like actual paralysis
echo This freeze happens because windows panics, since the proxy was rerouting machine traffic 
echo This freeze is epected, DO NOT FORCE SHUTDOWN BY LONGPRESSING THE POWER!!
taskkill /f /im ugate.exe 2>nul

echo [STAGE 2] Let's remove this garbage, eh :D
schtasks /delete /tn "exiho" /f 2>nul
schtasks /delete /tn "afujo" /f 2>nul

echo [STAGE 3] Better not be anymore garbage in here...
:: -------------------------------------------------------------------------
:: TECHNICAL EXPLANATION OF STAGE 3 COMMANDS FOR CODE REVIEWERS:
:: - 'takeown /f ... /r /d y': Forces the OS to assign file ownership to the
::   current Administrator group recursively, breaking the malware's ACL blocks.
:: - 'icacls ... /grant administrators:F /t': Grants full control access 
::   rights to the administrators group recursively across all folder objects.
:: - 'del /f /q /a': Force-deletes hidden, read-only, and system file attributes.
:: - 'rd /s /q': Quietly deletes the entire directory structure from disk.
:: -------------------------------------------------------------------------
if exist "C:\Users\Public\Documents\ature" (
    echo Time to bust some bandits. Get a real job, crypto sucks!
    takeown /f "C:\Users\Public\Documents\ature" /r /d y >nul 2>&1
    icacls "C:\Users\Public\Documents\ature" /grant administrators:F /t >nul 2>&1
    del /f /q /a "C:\Users\Public\Documents\ature\exiho.xml" 2>nul
    del /f /q /a "C:\Users\Public\Documents\ature\afujo.xml" 2>nul
    del /f /q /a "C:\Users\Public\Documents\ature\ugate.exe" 2>nul
    rd /s /q "C:\Users\Public\Documents\ature" 2>nul
) else (
    echo Not a bandit to be found, maybe they got a real job, yeah?
)

echo [STAGE 4] Scrubbing the toilets...
sfc /scannow
dism /Online /Cleanup-Image /RestoreHealth

echo [STAGE 5] What kind of socks Windows would wear, if Windows COULD wear socks. Hm..
netsh winsock reset
ipconfig /flushdns

echo [STAGE 6] Time to patch some drywall..
reg add "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v "Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ugate.exe" /v "Debugger" /t REG_SZ /d "systrace.exe" /f >nul
echo [SECURE] wscript.exe has been disabled and ugate.exe is now flagged in the registry and ready to be made inert.

echo --------------------------------------------------
echo RESTART IMMINENT!!
echo RESTART IMMINENT!!
echo RESTART IMMINENT!!
echo --------------------------------------------------
echo.
echo Cleanup should be complete, system will restart in 10 seconds. Have a lovely day!
echo Please follow up with a Windows Defender scan
shutdown /r /f /t 10

