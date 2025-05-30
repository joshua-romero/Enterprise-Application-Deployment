**# Enterprise Software Installer Scripts

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=for-the-badge)

**Automated PowerShell scripts for enterprise software deployment**

[📖 Documentation](#-documentation) • [🎯 Features](#-features)

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


## 📈 Roadmap

- [ ] 🔗 **Integration** with SCCM/Intune

---

## 🏆 Acknowledgments

<div align="center">

**Special Thanks To:**

🙏 [**asheroto**](https://github.com/asheroto) - URL parsing techniques for Adobe Acrobat script 

</div>

