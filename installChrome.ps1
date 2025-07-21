<#
.SYNOPSIS
    Automates Google Chrome installation with latest available patch

.DESCRIPTION
    This script performs a complete Google Chrome deployment by executing the following:
    - Checks for existing Google Chrome installation
    - Downloads and installs latest Google Chrome if not present

.NOTES 
    Author: Joshua Romero - jromero@usbr.gov
    Last updated: 06/01/2025

    Change History:
    - 1.0 - 06-01-2025 - Initial Release 

#>

BEGIN {
    $date = (Get-Date -Format yyyy-MM-dd)
    $Software = 'Chrome'
    $logPath = "C:\Patches\Logs\$Software-$date.log"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    function TimeStamp($Message) {
        $timeStamped = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
        Write-Host $timeStamped -ForegroundColor Cyan
        Add-Content -Path $logPath -Value $timeStamped
        return $timeStamped
    }

    $dirs = @(
        "C:\Patches\Logs",
        "C:\Patches\Chrome"
    )

    foreach ($dir in $dirs) {
        if (!(Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            TimeStamp "Created directory: $dir"
        }
    }

    TimeStamp "Checking if Chrome is already installed..."
    $chromeExists = $false
    $chromePath = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"

    if (Test-Path -Path $chromePath) {
        $chromeExists = $true
        $ver = (Get-Item $chromePath).VersionInfo.FileVersion
        TimeStamp "Found $Software (v$ver)" | Out-Null
    }
}

PROCESS {
    if ($chromeExists) {
        TimeStamp "Chrome is already installed. Script will exit." | Out-Null
    }
    else {
        $url = "https://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise64.msi"
        $msiPath = "C:\Patches\Chrome\GoogleChromeStandaloneEnterprise64.msi"

        try {
            TimeStamp "Downloading Google Chrome MSI" | Out-Null
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $url -Destination $msiPath -Priority High
            TimeStamp "Download completed successfully" | Out-Null
        }
        catch {
            TimeStamp "Unable to download through BITS. Downloading Google Chrome MSI using WebRequest" | Out-Null
            try {
                Invoke-WebRequest -Uri $url -OutFile $msiPath
                TimeStamp "Download completed successfully using WebRequest" | Out-Null
            }
            catch {
                $errorMsg = "Failed to download Chrome: $_"
                TimeStamp $errorMsg | Out-Null
                throw $errorMsg
            }
        }

        try {
            TimeStamp "Installing Google Chrome" | Out-Null
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qb" -Wait -PassThru
            $exitCode = $process.ExitCode

            switch ($exitCode) {
                0 {
                    TimeStamp "Installation successful with exit code: $exitCode" | Out-Null
                }
                3010 {
                    TimeStamp "Installation successful with exit code: $exitCode (restart required)" | Out-Null
                }
                1641 {
                    TimeStamp "Installation initiated a restart with exit code: $exitCode" | Out-Null
                }
                default {
                    TimeStamp "Installation finished with code: $exitCode" | Out-Null
                }
            }
        }
        catch {
            $errorMsg = "An error occurred while installing Google Chrome: $_"
            TimeStamp $errorMsg | Out-Null
            throw $errorMsg
        }
    }
}

END {
    TimeStamp "Script execution completed" | Out-Null
    if (Test-Path "C:\Patches\Chrome") {
        TimeStamp "Cleaning up downloaded installer" | Out-Null
        Remove-Item -Path "C:\Patches\Chrome" -Force -Recurse
    }
}
