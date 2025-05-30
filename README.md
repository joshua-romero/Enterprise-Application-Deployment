# 🚀 Enterprise Software Installer Scripts

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=for-the-badge)

**Automated PowerShell scripts for enterprise software deployment**

[📖 Documentation](#-documentation) • [🎯 Features](#-features) • [⚡ Quick Start](#-quick-start) • [🔧 Troubleshooting](#-troubleshooting)

</div>

---

## 📋 Overview

This repository contains PowerShell scripts designed for automated, up-to-date software deployment in enterprise environments. Perfect for system administrators, IT professionals, and deployment automation.

### 📦 Available Scripts

| Script | Purpose | Status |
|--------|---------|--------|
| 🅰️ **Adobe Acrobat DC** | Install + Auto-update to latest version | ✅ Active |
| 🌐 **Google Chrome** | Enterprise MSI installation | ✅ Active |

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 **Core Capabilities**
- 📝 **Comprehensive Logging** - Timestamped activity logs
- 🛡️ **Error Handling** - Multiple fallback methods
- 🔇 **Silent Installation** - Zero user interaction
- 🧹 **Auto Cleanup** - Removes temporary files
- ✅ **Pre-flight Checks** - Detects existing installations

</td>
<td width="50%">

### 🅰️ **Adobe Acrobat Specific**
- 📋 **Prerequisite Management** - Auto-installs VC++ 2013
- 🔄 **Smart Updates** - Parses Adobe release notes
- 🎯 **Version Detection** - Always gets latest patches
- 📊 **Exit Code Handling** - Proper MSI result processing

</td>
</tr>
</table>

---

## ⚡ Quick Start

### 🛠️ Prerequisites

```powershell
# Check PowerShell version (requires 5.0+)
$PSVersionTable.PSVersion

# Verify admin privileges
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
```

### 🚀 Installation

#### Method 1: Direct Execution
```powershell
# Adobe Acrobat DC
.\Install-AdobeAcrobat.ps1

# Google Chrome Enterprise
.\Install-GoogleChrome.ps1
```

#### Method 2: Bypass Execution Policy
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File ".\Install-AdobeAcrobat.ps1"
PowerShell.exe -ExecutionPolicy Bypass -File ".\Install-GoogleChrome.ps1"
```

#### Method 3: Remote Execution
```powershell
# Download and run directly (use with caution)
iex (iwr -Uri "https://raw.githubusercontent.com/yourusername/repo/main/Install-GoogleChrome.ps1").Content
```

---

## 📁 File Structure

```
📂 C:\Patches\
├── 📂 Logs\
│   ├── 📄 Acrobat-2024-01-15.log
│   └── 📄 Chrome-2024-01-15.log
├── 📂 Acrobat\
│   └── 🗂️ [temporary files]
└── 📂 Chrome\
    └── 🗂️ [temporary files]
```

---

## 📊 Logging & Monitoring

### 📈 Real-time Monitoring
```powershell
# Watch logs in real-time
Get-Content "C:\Patches\Logs\Acrobat-$(Get-Date -Format yyyy-MM-dd).log" -Wait

# Check last 10 log entries
Get-Content "C:\Patches\Logs\Chrome-$(Get-Date -Format yyyy-MM-dd).log" -Tail 10
```

### 🎯 Exit Code Reference

| Code | Status | Action Required |
|------|--------|----------------|
| `0` | ✅ **Success** | None |
| `1641` | ✅ **Success** | Restart initiated by installer |
| `3010` | ⚠️ **Success** | Manual restart required |
| `Other` | ❌ **Failed** | Check logs for details |

---

## 🔧 Troubleshooting

<details>
<summary>🌐 <strong>Download Issues</strong></summary>

```powershell
# Test internet connectivity
Test-NetConnection -ComputerName "www.google.com" -Port 80

# Check proxy settings
netsh winhttp show proxy

# Manual download test
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/GoogleChromeStandaloneEnterprise64.msi" -OutFile "test.msi"
```
</details>

<details>
<summary>🔒 <strong>Permission Problems</strong></summary>

```powershell
# Check execution policy
Get-ExecutionPolicy -List

# Set execution policy (run as admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify admin rights
whoami /groups | findstr "S-1-16-12288"
```
</details>

<details>
<summary>🚫 <strong>Installation Failures</strong></summary>

```powershell
# Check disk space
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}}

# Verify Windows Installer service
Get-Service -Name "msiserver"

# Check for pending reboots
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
```
</details>

---

## ⚙️ Advanced Configuration

### 🎨 Customize Installation Paths

```powershell
# Modify these variables at the top of each script
$customPath = "D:\MyDeployments"
$dirs = @(
    "$customPath\Logs",
    "$customPath\Software"
)
```

### 📧 Add Email Notifications

```powershell
# Add this function to send completion emails
function Send-CompletionEmail {
    param($Status, $Software)
    
    $emailParams = @{
        To = "admin@company.com"
        From = "deployment@company.com"
        Subject = "$Software Installation - $Status"
        Body = "Installation completed with status: $Status"
        SmtpServer = "mail.company.com"
    }
    
    Send-MailMessage @emailParams
}
```

---

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. 🍴 **Fork** this repository
2. 🌿 **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. 💾 **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. 📤 **Push** to the branch (`git push origin feature/amazing-feature`)
5. 🔄 **Open** a Pull Request

### 📋 Contribution Guidelines

- ✅ Test in isolated environment first
- 📝 Update documentation for changes
- 🎯 Follow existing code patterns
- 📊 Include appropriate logging
- 🔍 Add error handling for new features

---

## 📈 Roadmap

- [ ] 🔗 **Integration** with SCCM/Intune

---

## 🏆 Acknowledgments

<div align="center">

**Special Thanks To:**

🙏 [**asheroto**](https://github.com/asheroto) - URL parsing techniques for Adobe Acrobat script 

</div>

