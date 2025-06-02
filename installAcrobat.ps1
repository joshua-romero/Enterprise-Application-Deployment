BEGIN {
    $date = (Get-Date -Format yyyy-MM-dd)
    $software = 'Acrobat'
    $acrobatPath = "${env:ProgramFiles(x86)}\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
    $logPath = "C:\Patches\Logs\$Software-$date.log"

    function TimeStamp($Message) {
        $timeStamped = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
        #Write-Host $timeStamped -ForegroundColor Cyan
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

    TimeStamp "Checking to see if $Software is already installed..."
    $acrobatExists = $false

    if (Test-Path -Path $acrobatPath) {
        $acrobatExists = $true
        $ver = (Get-Item "${env:ProgramFiles(x86)}\Adobe\Acrobat DC\Acrobat\Acrobat.exe").VersionInfo.FileVersion
        TimeStamp "Found $Software (v$ver) - checking for updates..." | Out-Null
    }


}
PROCESS {

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Checking and installing Acrobat prerequisite: Visual C++ Redistributable 2013...
    TimeStamp "Checking for Visual C++ 2013..."

    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $vcRedisExists = $false
    foreach ($reg in $regPaths) {
        $vcRedis = Get-ItemProperty $reg | Where-Object { 
            ($_.DisplayName -like "*Visual C++ 2013*" -and $_.DisplayName -like "*x64*") -or
            ($_.DisplayName -like "*Visual C++ Redistributable*2013*" -and $_.DisplayName -like "*x64*")
        }
        if ($vcRedis) {
            $vcRedisExists = $true
            TimeStamp "Found Visual C++ Redistributable 2013... (v$($vcRedis.DisplayVersion))"
            break
        }
    }

    if (-not $vcRedisExists) {
        $vcRedistUrl = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
        $vcRedistPath = "C:\Patches\Acrobat\vcredist_x64_2013.exe" 
        try {
            TimeStamp "Downloading: Visual C++ Redistributable 2013..."
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $vcRedistUrl -Destination $vcRedistPath -Priority High
            TimeStamp "Downloaded: Visual C++ Redistributable 2013..."
        }
        catch {
            TimeStamp "Download Failed: BitsTransfer failed - Attempting alternate method"
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($vcRedistUrl, $vcRedistPath)
            TimeStamp "Downloaded: Visual C++ Redistributable 2013..."
        }
        try {
            TimeStamp "Installing: Visual C++ Redistributable 2013..."
            Start-Process -FilePath $vcRedistPath -ArgumentList "/install /quiet /norestart" -Wait
            TimeStamp "Installed: Visual C++ Redistributable 2013..."
        }
        catch {
            TimeStamp "Failed: Visual C++ Redistributable 2013 - $_"
        }
    }

#Checking and downloading/installing Acrobat DC
    if ($acrobatExists) {
        TimeStamp "Acrobat installed - Checking for updates"
    }
    else {
        TimeStamp "Acrobat not found - Installing..."
        $url = "https://trials.adobe.com/AdobeProducts/APRO/Acrobat_HelpX/win32/Acrobat_DC_Web_WWMUI.zip"
        $zipFile = "C:\Patches\$Software\Acrobat_DC_Web_WWMUI.zip"

        try {
            TimeStamp "Downloading: Adobe Acrobat DC via Start-BitsTransfer"
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $url -Destination $zipFile -Priority High
            TimeStamp "Downloaded: Adobe Acrobat DC"
        }
        catch {
            TimeStamp "Download failed: BitsTransfer failed - Attempting alternate method"
            try {
                TimeStamp "Downloading: Adobe Acrobat DC via Invoke-WebRequest"
                Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing
                TimeStamp "Downloaded: Adobe Acrobat DC"
            }
            catch {
                TimeStamp "Download failed: $_"
                exit 1
            }
        }

        try {
            TimeStamp "Extracting Adobe Acrobat DC..."
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, "C:\Patches\$Software")
            }
            catch {
                Expand-Archive -Path $zipFile -DestinationPath "C:\Patches\$Software" -Force
            }
            
            TimeStamp "Extracted: Adobe Acrobat DC install"
            
        } 
        catch {
            TimeStamp "Extraction failed: $_"
            exit 1
        }
        
# Install Acrobat
        $msiPath = "C:\Patches\$Software\Adobe Acrobat\AcroPro.msi"
        if (Test-Path -Path $msiPath) {
            TimeStamp "Installing Acrobat DC (this takes a while)..."
            try {
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn" -Wait
                
                TimeStamp "Installed: Adobe Acrobat DC"
            } 
            catch {
                TimeStamp "MSI install failed: $_"
                exit 1
            }
        } 
        else {
            TimeStamp "Can't find AcroPro.msi at $msiPath"
            exit 1
        }
        TimeStamp "Base Acrobat installation finished"
    }
}

END {
    # Credit where credit is due
    <# 
        Thanks to asheroto on GitHub for the URL parsing approach
        Modified and improved for better reliability
    #>

    TimeStamp "Checking Adobe Acrobat updates..."

    $relNotesURL = "https://helpx.adobe.com/acrobat/release-note/release-notes-acrobat-reader.html"
    try {
        $wc = New-Object System.Net.WebClient
        $html = $wc.DownloadString($relNotesURL)
        
        if ([string]::IsNullOrEmpty($html)) {
            throw "Got empty page from Adobe"
        }
    }
    catch {
        try {
            TimeStamp "Download failed - Attempting alternate method"
            $html = curl.exe -s $relNotesURL
            if ([string]::IsNullOrEmpty($html)) {
                throw "Got empty page from curl"
            }
        }
        catch {
            TimeStamp "Download failed: $_"
        }
    }

    try {
        $pattern = [regex]::new('<a href="(https://www\.adobe\.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/[^"]+)"[^>]*>(DC [^<]+)</a>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $match = $pattern.Match($html)
        if (-not $match.Success) {
            throw "Couldn't find version link - Adobe changed their page?"
        }
        $verUrl = $match.Groups[1].Value
        $verNum = $match.Groups[2].Value

        TimeStamp "Found latest Acrobat version: $verNum"
    }
    catch {
        TimeStamp "Failed to find version info: $_"
        return
    }
    
    try {
        try {
            $verPage = $wc.DownloadString($verUrl)
        }
        catch {
            $verPage = curl.exe -s $verUrl
            if ([string]::IsNullOrEmpty($verPage)) {
                throw "Got empty version page"
            }
        }
    } 
    catch {
        TimeStamp "Couldn't get version details: $_"
        return
    }
    
    try {
        $mspPattern = [regex]::new('<a[^>]+href="([^"]+\.msp)"[^>]*>([^<]+)</a>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $mspMatch = $mspPattern.Match($verPage)
        if (-not $mspMatch.Success) {
            throw "Couldn't find MSP link - maybe format changed?"
        }
        $mspUrl = $mspMatch.Groups[1].Value
        $mspName = [System.IO.Path]::GetFileNameWithoutExtension($mspUrl)
        $mspVer = $mspName -replace '.*?(\d{4,}).*', '$1'
        
        TimeStamp "Found update package: $mspVer"
    } 
    catch {
        TimeStamp "Failed to get update details: $_"
        return
    }

    try {
        $updateUrl = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/$mspVer/AcrobatDCUpd${mspVer}.msp"
        $mspPath = "C:\Patches\$Software\AcrobatDCUpd${mspVer}.msp"  # THIS WAS MISSING!
    } 
    catch {
        TimeStamp "Couldn't build update URL: $_"
        return
    }
   
    TimeStamp "Downloading Acrobat update $mspVer..."
    
    try {
        Import-Module BitsTransfer -ErrorAction Stop
        Start-BitsTransfer -Source $updateUrl -Destination $mspPath -Priority High
    
        TimeStamp "Downloaded: Adobe Acrobat DC (v$mspVer)"
    }
    catch {
        TimeStamp "Download failed - Attempting alternate method"
        
        try {
            Invoke-WebRequest -Uri $updateUrl -OutFile $mspPath -UseBasicParsing
            
            TimeStamp "Downloaded: Adobe Acrobat DC (v$mspVer)"
        }
        catch {
            TimeStamp "Failed to download update: $_"
            return
        }
    }
    
    if (-not (Test-Path $mspPath)) {
        TimeStamp "Downloaded file not found at $mspPath"
        return
    }
    
    try {
        TimeStamp "Installing Acrobat update $mspVer..."
        
        $p = Start-Process -FilePath "msiexec.exe" -ArgumentList "/update `"$mspPath`" /norestart /qn /l*v $logPath" -Wait -PassThru
        $exitCode = $p.ExitCode
        
        switch ($exitCode) {
            0 {
                TimeStamp "Update successful!"
            }
            3010 {
                TimeStamp "Update successful! (Exit code 3010 - reboot required)"
                TimeStamp "NOTE: For full functionality, reboot the system when available"
            }
            1641 {
                TimeStamp "Update successful! (Exit code 1641 - installer initiated reboot)"
            }
            default {
                TimeStamp "Update failed with code: $exitCode - check log at $logPath"
            }
        }
    }
    catch {
        TimeStamp "Error during update: $_"
    }
    finally {
        TimeStamp "Cleaning up..."
        if (Test-Path "C:\Patches\$Software") {
            Remove-Item "C:\Patches\$Software" -Recurse -Force -ErrorAction SilentlyContinue
        }
        TimeStamp "Acrobat update completed"
    }    
}
