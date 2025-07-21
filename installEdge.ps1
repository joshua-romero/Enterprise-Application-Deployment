<#
.SYNOPSIS
    Automates latest available Microsoft Edge installation 

.DESCRIPTION
    This script performs a complete Microsoft Edge deployment by executing the following:
    - Checks for existing Microsoft Edge installation
    - Downloads and installs latest Microsoft Edge if not present

.NOTES 
    Author: Joshua Romero - jromero@usbr.gov
    Last updated: 06/01/2025

    Change History:
    - 1.0 - 06-01-2025 - Initial Release 

#>

BEGIN {
    $date = (Get-Date -Format yyyy-MM-dd)
    $Software = 'Edge'
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
        "C:\Patches\Edge"
    )

    foreach ($dir in $dirs) {
        if (!(Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            TimeStamp "Created directory: $dir"
        }
    }

    TimeStamp "Checking if Edge is already installed..."
    $edgeExists = $false
    $edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"

    if (Test-Path -Path $edgePath) {
        $edgeExists = $true
        $ver = (Get-Item $edgePath).VersionInfo.FileVersion
        TimeStamp "Found $Software (v$ver)" | Out-Null
    }

    try {
        TimeStamp "Fetching latest Edge download information" | Out-Null
        $uri = "https://edgeupdates.microsoft.com/api/products?view=enterprise"
        $response = Invoke-RestMethod -Uri $uri -Method Get

        $allReleases = foreach ($product in $response) {
            foreach ($release in $product.Releases) {
                foreach ($artifact in $release.Artifacts) {
                    if ($artifact.location -and $artifact.location.EndsWith('.msi')) {
                        [PSCustomObject]@{
                            Product = $product.Product
                            Platform = $release.Platform
                            Architecture = $release.Architecture
                            Version = $release.ProductVersion
                            Location = $artifact.location
                        }
                    }
                }
            }
        }

        $matchingRelease = $allReleases | Where-Object { 
            $_.Platform -eq "Windows" -and 
            $_.Architecture -eq "x64" -and 
            $_.Product -eq "Stable" 
        } | Select-Object -First 1

        if ($matchingRelease -and $matchingRelease.Location) {
            TimeStamp "Found Edge version $($matchingRelease.Version) for download" | Out-Null
            TimeStamp "Download URL: $($matchingRelease.Location)" | Out-Null
        } else {
            TimeStamp "Could not find matching Edge release. Trying fallback URL..." | Out-Null
            $matchingRelease = [PSCustomObject]@{
                Version = "Latest"
                Location = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/b525f788-c301-40c8-9dea-b79e0f7a2e52/MicrosoftEdgeEnterpriseX64.msi"
            }
            TimeStamp "Using fallback URL for Edge download" | Out-Null
        }
    }
    catch {
        TimeStamp "API call failed, using fallback URL..." | Out-Null
        $matchingRelease = [PSCustomObject]@{
            Version = "Latest"
            Location = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/b525f788-c301-40c8-9dea-b79e0f7a2e52/MicrosoftEdgeEnterpriseX64.msi"
        }
        TimeStamp "Using fallback URL for Edge download" | Out-Null
    }
}

PROCESS {
    if ($edgeExists) {
        TimeStamp "Edge is already installed (v$ver). Checking for updates..." | Out-Null
    }
    
    $msiPath = "C:\Patches\Edge\Edge-v$($matchingRelease.Version).msi"

    try {
        TimeStamp "Downloading Microsoft Edge MSI (v$($matchingRelease.Version))" | Out-Null
        Import-Module BitsTransfer -ErrorAction Stop
        Start-BitsTransfer -Source $matchingRelease.Location -Destination $msiPath -Priority High
        TimeStamp "Download completed successfully" | Out-Null
    }
    catch {
        TimeStamp "Unable to download through BITS. Downloading Edge MSI using WebRequest" | Out-Null
        try {
            Invoke-WebRequest -Uri $matchingRelease.Location -OutFile $msiPath
            TimeStamp "Download completed successfully using WebRequest" | Out-Null
        }
        catch {
            $errorMsg = "Failed to download Edge: $_"
            TimeStamp $errorMsg | Out-Null
            throw $errorMsg
        }
    }

    try {
        if ($edgeExists) {
            TimeStamp "Updating Microsoft Edge to version $($matchingRelease.Version)" | Out-Null
        } else {
            TimeStamp "Installing Microsoft Edge" | Out-Null
        }
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qb" -Wait -PassThru
        $exitCode = $process.ExitCode

        switch ($exitCode) {
            0 {
                if ($edgeExists) {
                    TimeStamp "Update successful with exit code: $exitCode" | Out-Null
                } else {
                    TimeStamp "Installation successful with exit code: $exitCode" | Out-Null
                }
            }
            3010 {
                if ($edgeExists) {
                    TimeStamp "Update successful with exit code: $exitCode (restart required)" | Out-Null
                } else {
                    TimeStamp "Installation successful with exit code: $exitCode (restart required)" | Out-Null
                }
            }
            1641 {
                if ($edgeExists) {
                    TimeStamp "Update initiated a restart with exit code: $exitCode" | Out-Null
                } else {
                    TimeStamp "Installation initiated a restart with exit code: $exitCode" | Out-Null
                }
            }
            1603 {
                TimeStamp "Operation failed with exit code: $exitCode (ERROR_INSTALL_FAILURE)" | Out-Null
            }
            1619 {
                TimeStamp "Operation failed with exit code: $exitCode (ERROR_INSTALL_PACKAGE_OPEN_FAILED)" | Out-Null
            }
            1636 {
                TimeStamp "Operation failed with exit code: $exitCode (ERROR_PATCH_PACKAGE_INVALID)" | Out-Null
            }
            default {
                TimeStamp "Operation finished with code: $exitCode" | Out-Null
            }
        }
    }
    catch {
        if ($edgeExists) {
            $errorMsg = "An error occurred while updating Microsoft Edge: $_"
        } else {
            $errorMsg = "An error occurred while installing Microsoft Edge: $_"
        }
        TimeStamp $errorMsg | Out-Null
        throw $errorMsg
    }
}

END {
    TimeStamp "Script execution completed" | Out-Null
    if (Test-Path "C:\Patches\Edge") {
        TimeStamp "Cleaning up downloaded installer" | Out-Null
        Remove-Item -Path "C:\Patches\Edge" -Force -Recurse
    }
}
