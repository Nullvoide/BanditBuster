# Threat Analysis & Incident Response Report: CryptoBandits.B Infostealer

## Executive Summary
This repository documents the end-to-end technical triage, forensic artifact analysis, and Zero-Trust architectural mitigation of **CryptoBandits.B**. This modular information stealer targets local cryptocurrency assets, browser credentials, and session tokens. The malware leverages twin JavaScript (`.js`) loaders for persistence, an engineered Windows Task Scheduler persistence loop, and an embedded Tor network anonymity proxy (`ugate.exe`) for data exfiltration. 

As a hobbyist malware researcher, I triaged this infection on a live Windows host (yes my actual computer; no vm, it was literally a random afternoon). Because the local threat history was automatically rotated and purged by the operating system during the response phase, traditional static file analysis was limited. This report details how I reverse-engineered the malware's remaining disk artifacts and established a comprehensive **Proactive Hardening Strategy** that completely drops the malware’s capabilities into a null execution state.

---

## Technical Analysis & Threat Anatomy

The lifecycle of the `CryptoBandits.B` infection relies on a highly modular design to establish access, evade local antivirus detection, and securely tunnel stolen data back to attacker-controlled infrastructure.

### 1. Delivery & The Staging Ground
The threat operates out of a hidden subfolder inside the Public user directory:  
`C:\Users\Public\Documents\ature\`

This path is explicitly chosen by the malware authors because it lacks strict folder access control lists (ACLs), allowing unprivileged processes to write files directly to the disk without triggering User Account Control (UAC) prompts.

### 2. The Persistence Engine (XML Core)
The core persistence loop is maintained via the Windows Task Scheduler database, backed by two distinct configuration files dropped into the staging folder:
* **`exiho.xml`:** Acts as the structural blueprint for a hidden scheduled task. It handles registration, dictating how frequently the malware runs and forcing it to execute repeatedly and silently.
* **`afujo.xml`:** Configures the precise execution parameters, handles, and triggers required to repeatedly invoke the primary JavaScript payload, `afujo.js`.
* **UTF-16LE Anti-Forensics Encoding:** Forensics revealed that both `exiho.xml` and `afujo.xml` were explicitly encoded in **UTF-16 Little Endian (UTF-16LE)**. This encoding inserts null bytes between characters, heavily obfuscating the configuration content so legacy security scanners searching for standard ASCII text strings overlook the tasks on disk.

### 3. Execution & Exfiltration Tiers
* **`afujo.js` Script:** This script serves as a local clipboard "clipper." It silently monitors the Windows clipboard for cryptographic wallet string patterns (e.g., Bitcoin, Ethereum, MetaMask addresses) and dynamically replaces the user's copied target addresses with the attacker's wallet address.
* **`ugate.exe` (Tor Network Proxy):** To exfiltrate stolen browser credentials (`logins.json` / `key4.db`) safely past standard corporate firewalls, the malware bundles a compiled Tor proxy binary named `ugate.exe`. This establishes a secure, encrypted local SOCKS tunnel to forward data directly to an `.onion` Command and Control (C2) address anonymously.

---

## Incident Forensic Obstacles

### Initial Detection via AMSI & Windows Defender
The threat was originally caught by a real-time behavioral alert triggered by the **Antimalware Scan Interface (AMSI)** and **Windows Defender**. AMSI intercepted the initial execution layer of the obfuscated script in memory as it attempted to pass dangerous instructions to the operating system shell. 

### Log Evaporation
Although Windows Defender successfully stepped in to kill the active process, an automated system maintenance task immediately followed up by purging the local history logs before further manual forensics could take place:

```text
Microsoft Defender Antivirus has removed history of malware and other potentially unwanted software.
Time: 2026-05-26T05:41:33Z
User: NT AUTHORITY\SYSTEM
```

Because this automated log rotation wiped local threat logs and cleared the standard user quarantine cache, I could not rely on traditional, reactive file signatures. The investigation immediately pivoted to tracing the disk artifacts left behind in the staging directory and building an architectural defense.

---

## Proactive System Hardening Matrix

To guarantee that `CryptoBandits.B` cannot run, reinstall, or execute any phase of its attack chain, four aggressive host-hardening layers were deployed to fundamentally strip away the operating system's capability to run the files.

### Layer 1: Windows Script Host Neutralization (`wscript.exe`)
Because the initial access and persistence loops rely on Windows executing native JavaScript files directly on the desktop, the Windows Script Host was globally disabled via the registry. 

* **Registry Key Path:** `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Script Host\Settings`
* **DWORD Value Name:** `Enabled`
* **Value Data:** `0` (Disabled)

Any attempt by a scheduled task to launch `afujo.js` is blocked immediately at the kernel level by the operating system core, preventing execution entirely.

### Layer 2: Command-Line Shell Hardening
To prevent scripts from executing secondary payloads, dropping binaries into memory, or referencing external administrative APIs, both **PowerShell and Command Prompt (CMD) were forced into Constrained Language Mode**. This strips away the advanced `.NET` functionalities required by multi-stage loaders.

### Layer 3: Application Blockade (IFEO Registry Sinkhole)
To prevent the Tor proxy (`ugate.exe`) from ever initiating a network connection—even if it is successfully dropped onto the disk by an updated variant—an **Image File Execution Options (IFEO)** debugger block was established in the Registry:

* **Key Path:** `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ugate.exe`
* **String Name:** `Debugger`
* **Value Data:** `systrace.exe`

When any process calls `ugate.exe`, the Windows kernel intercepts the command and redirects the execution into an empty string, rendering the binary instantly inert.

### Layer 4: Credential Surface Reduction
Infostealers target browser databases for saved identities. By configuring the local web browsers (Firefox) to **never retain passwords, cookies, or browsing history**, the file system contains zero local data for the malware to scrape or exfiltrate.

---

## Deployment & Usage

An automated script [`CBCleanup.bat`](./CBCleanup.bat) is provided in this repository to cleanly kill active processes, unregister scheduled persistence loops, seize administrative file rights, clean the local directory surface, and hardcode your Registry defense configurations.

### Installation Instructions
1. Clone this repository or download the raw [`CBCleanup.bat`](./CBCleanup.bat) file.
2. Right-click `CBCleanup.bat` and select **Run as Administrator**.
3. Allow the system integrity scans (`SFC` / `DISM`) to run completely (this may take a few minutes).
4. The system will issue an immediate reboot sequence to apply all kernel-level blocks.

---

## Indicators of Compromise (IoCs)

| Indicator Type | Artifact / Target Path | Status / Defensive Realignment |
| :--- | :--- | :--- |
| **Malware Family** | CryptoBandits.B Infostealer | Blocked / Defanged [CryptoBandits] |
| **Staging Root** | `C:\Users\Public\Documents\ature\` | Purged / Permissions Seized |
| **Task Blueprint** | `\ature\exiho.xml` (UTF-16LE) | Task Unregistered / Deleted |
| **Task Configuration** | `\ature\afujo.xml` (UTF-16LE) | Task Unregistered / Deleted |
| **Clipper Payload** | `\ature\afujo.js` | Blocked via `wscript.exe` global ban |
| **C2 Proxy Binary** | `\ature\ugate.exe` | Sunk via Registry IFEO Debugger Block |

---

## Conclusion
By shifting focus from static signature detection to proactive attack surface reduction, `CryptoBandits.B` was completely neutralized. Even if the malware updates its payload file names or hashes in future campaigns, the systemic configurations deployed on this host permanently prevent its execution models from succeeding.

---

**Write-up by Nova**  
*Alias:* `//Null`  
*Discord:* `crummysoda`  
*Location:* Toronto, Canada  
*Role:* Independent Threat Researcher & Security Hobbyist  
*Report Generated: June 2026*
