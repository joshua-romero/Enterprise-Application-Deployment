## Enterprise Software Installer Scripts

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=for-the-badge)

**Automated PowerShell scripts for enterprise software deployment**

</div>

---

## 📋 Overview

This repository contains PowerShell scripts designed for automated, up-to-date software deployment in enterprise environments. Perfect for system administrators, IT professionals, and deployment automation.

### 📦 Available Scripts

| Script | Purpose | Installation Type |
|--------|---------|--------|
| **Adobe Acrobat DC** | Install + Auto-update to latest version | x86 |
| **Google Chrome** | Enterprise MSI installation | x64 |
| **Microsoft Edge** | Enterprise MSI installation | x64 |
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

# PowerShell version 5.0+ Required
$PSVersionTable.PSVersion

# Administrative Privileges Required
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
```

### 🚀 Execution

#### Method 1: Direct Execution
```powershell
# Adobe Acrobat DC
.\installAcrobat.ps1

# Google Chrome Enterprise
.\installChrome.ps1

# Microsoft Edge Enterprise
.\installEdge.ps1
```

#### Method 2: Bypass Execution Policy
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File ".\installAcrobat.ps1"
PowerShell.exe -ExecutionPolicy Bypass -File ".\installChrome.ps1"
PowerShell.exe -ExecutionPolicy Bypass -File ".\installEdge.ps1"
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
└── 📂 Edge\
    └── 🗂️ [temporary files]
```

---

## 🎯 Exit Code Reference

| Code | Status | Action Required |
|------|--------|----------------|
| `0` | ✅ **Success** | None |
| `1641` | ✅ **Success** | Restart initiated by installer |
| `3010` | ⚠️ **Success** | Manual restart required |
| `Other` | ❌ **Failed** | Check logs for details |

---

## 🏆 Acknowledgments

---
<div align="center">

**Special Thanks To:**

🙏 [**asheroto**](https://github.com/asheroto) - URL parsing techniques for Adobe Acrobat script 

</div>

