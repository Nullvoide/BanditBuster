using System;
using System.IO;
using System.Reflection;
using System.Diagnostics;
using System.Security.Principal;
using System.Runtime.Versioning;
using Microsoft.Win32;

[SupportedOSPlatform("windows")]
partial class Program
{
    static void Main(string[] args)
    {
        if (!OperatingSystem.IsWindows())
        {
            Console.WriteLine("This tool only runs on Windows.");
            return;
        }

        // Enforce Administrator Rights natively
        if (!IsAdministrator())
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("[!] Elevation required. Relaunching as Administrator...");
            RelaunchAsAdmin();
            return;
        }

        Console.Clear();
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("======================================================================");
        Console.WriteLine("* * *   [+] CryptoBandits.B BanditBuster Tool by Null  * * *");
        Console.WriteLine("======================================================================");
        Console.ForegroundColor = ConsoleColor.Gray;
        Console.WriteLine("Run as administrator, shit wont work otherwise.");
        Console.WriteLine("Written by //Null (crummysoda on discord- Yeah I tagged myself, so what.)");
        Console.WriteLine("From Toronto, Canada. This is my first ever cleanup tool, and stuff.");
        Console.WriteLine("After all this, make sure to follow up with a regular malware scan.");
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("======================================================================");

        // --- STAGE 1 ---
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[STAGE 1] Let's Rock their shit");
        Console.ForegroundColor = ConsoleColor.Magenta;
        Console.WriteLine("Heads up: killing the proxy will cause a major freeze, like actual paralysis");
        Console.WriteLine("This freeze happens because windows panics, since the proxy was rerouting machine traffic");
        Console.ForegroundColor = ConsoleColor.Red;
        Console.WriteLine("This freeze is expected, DO NOT FORCE SHUTDOWN BY LONGPRESSING THE POWER!!");
        Console.ForegroundColor = ConsoleColor.Red;

        try
        {
            Process[] processes = Process.GetProcessesByName("ugate");
            if (processes.Length > 0)
            {
                foreach (var proc in processes)
                {
                    proc.Kill(true); // True kills the process tree entirely
                }
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("[+] Successfully terminated ugate.exe.");
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Gray;
                Console.WriteLine("[*] ugate.exe is not currently running.");
            }
        }
        catch (Exception)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("[-] CRITICAL: Failed to stop ugate.exe. Script aborted for safety.");
            return;
        }

        // --- STAGE 1.5 ---
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[STAGE 1.5] Purging browsers to drop active malicious extensions...");
        string[] browsers = { "chrome", "msedge", "firefox", "opera" };
        foreach (string browser in browsers)
        {
            foreach (var proc in Process.GetProcessesByName(browser))
            {
                try
                {
                    Console.ForegroundColor = ConsoleColor.Magenta;
                    Console.WriteLine($"[!] Closing active instances of {browser}...");
                    proc.Kill();
                }
                catch { }
            }
        }

        // --- STAGE 2 ---
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[STAGE 2] Let's remove this garbage, eh :D");
        string[] tasks = { "exiho", "afujo" };
        foreach (string task in tasks)
        {
            RunCommand("schtasks", $"/delete /tn \"{task}\" /f");
        }

        // --- STAGE 3 ---
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[STAGE 3] Better not be anymore garbage in here...");
        
        /* 
        -------------------------------------------------------------------------
        TECHNICAL EXPLANATION OF STAGE 3 LOGIC FOR CODE REVIEWERS:
        - Directory.Exists: Safely verifies folder path validity natively.
        - Directory.Delete(..., true): Natively purges the entire directory structure
          and hidden/system files recursively using built-in OS file handles.
        - Process Overrides: If native .NET I/O catches an AccessDenied exception due
          to custom malware ACL adjustments, the program triggers external 'takeown'
          and 'icacls' binaries to violently reclaim full control.
        -------------------------------------------------------------------------
        */
        string malwareDir = @"C:\Users\Public\Documents\ature";
        if (Directory.Exists(malwareDir))
        {
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("Time to bust some bandits. Get a real job, crypto sucks!");
            try
            {
                Directory.Delete(malwareDir, true);
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("[+] Directory deleted completely!");
            }
            catch (Exception)
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("[!] You're being cockblocked, time for extreme measures!");
                RunCommand("takeown", $"/f \"{malwareDir}\" /r /d y");
                RunCommand("icacls", $"\"{malwareDir}\" /grant administrators:F /t");
                try { Directory.Delete(malwareDir, true); } catch { }
            }
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("Not a bandit to be found, maybe they got a real job, yeah?");
        }

        // --- STAGE 4 ---
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[STAGE 4] Scrubbing the toilets...");
        RunCommand("sfc", "/scannow");
        RunCommand("dism", "/Online /Cleanup-Image /RestoreHealth");

        // --- STAGE 5 ---
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[STAGE 5] What kind of socks Windows would wear, if Windows COULD wear socks. Hm..");
        Console.ForegroundColor = ConsoleColor.Gray;
        Console.WriteLine("[*] Would the socks have like, little windows logos on them? That would be kind of cute ngl.");

        string[] regPaths = {
            @"Software\Microsoft\Windows\CurrentVersion\Internet Settings",
            @"SYSTEM\CurrentControlSet\Services\RemoteAccess\Parameters\Ip"
        };
        
        // Native C# Registry Manipulation (Extremely fast, bypasses terminal blocking)
        foreach (string path in regPaths)
        {
            try
            {
#pragma warning disable CS8600 // Converting null literal or possible null value to non-nullable type.
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(path, true))
                {
                    if (key != null)
                    {
                        key.SetValue("ProxyEnable", 0, RegistryValueKind.DWord);
                        key.DeleteValue("ProxyServer", false);
                        key.DeleteValue("AutoConfigURL", false);
                    }
                }
#pragma warning restore CS8600 // Converting null literal or possible null value to non-nullable type.
            }
            catch { }
        }
        
        RunCommand("netsh", "winhttp reset proxy");
        RunCommand("netsh", "winsock reset");
        RunCommand("ipconfig", "/flushdns");
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("[+] Network settings successfully restored.");

        // --- STAGE 6 ---
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[STAGE 6] Time to patch some drywall..");
        try
        {
            using (RegistryKey ifeo = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ugate.exe", true))
            {
                ifeo.SetValue("Debugger", "systrace.exe", RegistryValueKind.String);
            }
            using (RegistryKey wsh = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows Script Host\Settings", true))
            {
                wsh.SetValue("Enabled", 0, RegistryValueKind.DWord);
            }
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("[SECURE] wscript.exe has been disabled and ugate.exe is now flagged in the registry and ready to be made inert.");
        }
        catch (Exception)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("[-] Failed to apply registry hardening parameters.");
        }

        // --- REBOOT ---
        Console.ForegroundColor = ConsoleColor.Red;
        Console.WriteLine("\n--------------------------------------------------");
        Console.WriteLine("RESTART IMMINENT!!");
        Console.WriteLine("RESTART IMMINENT!!");
        Console.WriteLine("RESTART IMMINENT!!");
        Console.WriteLine("--------------------------------------------------");
        Console.WriteLine("");
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("Cleanup should be complete, system will restart in 10 seconds. Have a lovely day!");
        Console.ForegroundColor = ConsoleColor.Gray;
        Console.WriteLine("Please follow up with a Windows Defender scan");

        RunCommand("shutdown", "/r /f /t 10");
    }

    // Helper function to run fallback terminal commands smoothly hidden
    static void RunCommand(string filename, string arguments)
    {
        try
        {
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = filename,
                Arguments = arguments,
                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

#pragma warning disable CS8600 // Converting null literal or possible null value to non-nullable type.
            using (Process proc = Process.Start(startInfo))
            {
                proc?.WaitForExit();
            }
#pragma warning restore CS8600 // Converting null literal or possible null value to non-nullable type.
        }
        catch { }
    }

    static bool IsAdministrator()
    {
#pragma warning disable CA1416 // Validate platform compatibility
        using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
        {
            WindowsPrincipal principal = new WindowsPrincipal(identity);
            return principal.IsInRole(WindowsBuiltInRole.Administrator);
        }
#pragma warning restore CA1416 // Validate platform compatibility
    }

    static void RelaunchAsAdmin()
    {
        try
        {
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = Environment.ProcessPath,
                UseShellExecute = true,
                Verb = "runas"
            };
            Process.Start(startInfo);
        }
        catch { }
    }
}

