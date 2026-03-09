<#
.SYNOPSIS
    Automates Adobe Acrobat DC installation with latest available patch

.DESCRIPTION
    This script performs a complete Adobe Acrobat DC deployment by executing the following:
    - Checks for existing Acrobat DC installation
    - Installs Visual C++ 2013 Redistributable if missing
    - Downloads and installs Adobe Acrobat DC if not present
    - Checks and installs Adobe's release notes for the latest update

.NOTES 
    Author: Joshua Romero - jromero@usbr.gov
    Last updated: 3-9-2026

    Change History:
    - 1.0 - 06-01-2025 - Initial Release 
    - 1.1 - 07-15-2025 - Added backup workflow to use previous patch if there's no 32-bit patch for current release
    - 1.2 - 03-09-2026 - Modified parsing methods 
    - Changed Acrobat detection methods


.LINK
    https://helpx.adobe.com/acrobat/release-note/release-notes-acrobat-reader.html
#>

BEGIN {

    $date = (Get-Date -Format yyyy-MM-dd)
    $software = 'Acrobat'
    $logPath = "C:\Patches\Logs\$Software-$date.log"

    function TimeStamp($Message) {
        $timeStamped = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
#        Write-Host $timeStamped -ForegroundColor Cyan - to be removed
        Add-Content -Path $logPath -Value $timeStamped
        return $timeStamped
    }

    $dirs = @(
        "C:\Patches\Logs"
        "C:\Patches\$Software"
    )
    foreach ($dir in $dirs) {
        if (!(Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            TimeStamp "Created directory: $dir"
        }
    }

    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $acrobatExists = $false
    $acrobatVer = $null
    $updateNeeded = $false

    $acrobat = Get-ItemProperty $regPaths | Where-Object { $_.DisplayName -like "*Acrobat*" }

    if ($acrobat) {
        $acrobatExists = $true
        $acrobatVer = $acrobat.DisplayVersion
        TimeStamp "Found $software (v$acrobatVer)"
    } else {
        TimeStamp "$software not installed"
    }

    $relNotesURL = "https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html"

    try {
        $html = curl.exe -s $relNotesURL
        $joinedHtml = $html -join "`n"
        TimeStamp "Getting latest Acrobat version"

        $versionMatches = [regex]::Matches($joinedHtml, '(\d{2}\.\d{3}\.\d{5})')

        if ($versionMatches.Count -gt 0) {
            $latestVer = $versionMatches[0].Value
            $mspVer = $latestVer.Replace('.', '')
            $updateUrl = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/$mspVer/AcrobatDCUpd${mspVer}.msp"
            $mspPath = "C:\Patches\$Software\AcrobatDCUpd${mspVer}.msp"
            TimeStamp "Latest version: $latestVer"
            TimeStamp "Update URL: $updateUrl"
        } else {
            TimeStamp "Could not parse version from release notes"
        }
    } catch {
        TimeStamp "Failed to fetch release notes: $_"
    }

    if ($acrobatExists -and $acrobatVer -and $latestVer) {
        if ([version]$acrobatVer -ge [version]$latestVer) {
            TimeStamp "$software is already up to date (v$acrobatVer)"
        } else {
            TimeStamp "$software needs update: v$acrobatVer -> v$latestVer"
            $updateNeeded = $true
        }
    } elseif (-not $acrobatExists) {
        $updateNeeded = $true
    }

    $vcRedistExists = $false
    if (-not $acrobatExists) {
        $allApps = Get-ItemProperty $regPaths
        $vcRedist = $allApps | Where-Object { 
            $_.DisplayName -like "*Visual C++ 2013*" -and $_.DisplayName -like "*x64*"
        }
        if ($vcRedist) {
            $vcRedistExists = $true
            TimeStamp "Found VC++ 2013 Redistributable (v$($vcRedist.DisplayVersion))"
        } else {
            TimeStamp "VC++ 2013 Redistributable not found"
        }
    }

    $baseInstallerUrl = "https://trials.adobe.com/AdobeProducts/APRO/Acrobat_HelpX/win32/Acrobat_DC_Web_WWMUI.zip"
    $zipPath = "C:\Patches\$Software\Acrobat_DC_Web_WWMUI.zip"
    $msiPath = "C:\Patches\$Software\Adobe Acrobat\AcroPro.msi"
    $vcRedistUrl = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
    $vcRedistPath = "C:\Patches\$Software\vcredist_x64_2013.exe"

}
PROCESS {

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (-not $acrobatExists -and -not $vcRedistExists) {
        try {
            TimeStamp "Downloading VC++ 2013 Redistributable..."
            Invoke-WebRequest -Uri $vcRedistUrl -OutFile $vcRedistPath -UseBasicParsing -TimeoutSec 120
            TimeStamp "Downloaded VC++ 2013 Redistributable"

            TimeStamp "Installing VC++ 2013 Redistributable..."
            Start-Process -FilePath $vcRedistPath -ArgumentList "/install /quiet /norestart" -Wait
            TimeStamp "Installed VC++ 2013 Redistributable"
        } catch {
            TimeStamp "Failed to install VC++ 2013: $_"
            exit 1
        }
    }

    if (-not $acrobatExists) {
        try {
            TimeStamp "Downloading Adobe Acrobat DC..."
            Invoke-WebRequest -Uri $baseInstallerUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 600
            TimeStamp "Downloaded Adobe Acrobat DC"
        } catch {
            TimeStamp "Failed to download Acrobat: $_"
            exit 1
        }

        try {
            TimeStamp "Extracting Adobe Acrobat DC..."
            Expand-Archive -Path $zipPath -DestinationPath "C:\Patches\$Software" -Force
            TimeStamp "Extracted Adobe Acrobat DC"
        } catch {
            TimeStamp "Failed to extract Acrobat: $_"
            exit 1
        }

        if (Test-Path $msiPath) {
            try {
                TimeStamp "Installing Adobe Acrobat DC (this takes a while)..."
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn" -Wait
                TimeStamp "Installed Adobe Acrobat DC"
            } catch {
                TimeStamp "MSI install failed: $_"
                exit 1
            }
        } else {
            TimeStamp "Cannot find AcroPro.msi at $msiPath"
            exit 1
        }
    }

    if ($updateNeeded) {
        try {
            TimeStamp "Downloading Acrobat update $latestVer..."
            Invoke-WebRequest -Uri $updateUrl -OutFile $mspPath -UseBasicParsing -TimeoutSec 600
            TimeStamp "Downloaded Acrobat update"
        } catch {
            TimeStamp "Failed to download update: $_"
            exit 1
        }

        try {
            TimeStamp "Installing Acrobat update $latestVer..."
            $p = Start-Process -FilePath "msiexec.exe" -ArgumentList "/update `"$mspPath`" /norestart /qn" -Wait -PassThru
            
            switch ($p.ExitCode) {
                0       { TimeStamp "Acrobat successfully updated to v$latestVer" }
                3010    { TimeStamp "Update successful (reboot required)" }
                1641    { TimeStamp "Update successful (installer initiated reboot)" }
                default { TimeStamp "Update failed with exit code: $($p.ExitCode)" }
            }
        } catch {
            TimeStamp "Error during update: $_"
        }
    }

}
