# Check if the script is running as an Administrator
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run it as an Administrator."
    Exit
}

# Read the configuration file
$configFile = "config.json"
$config = Get-Content $configFile | ConvertFrom-Json

# Function to get the drive letter from the volume serial number
Function Get-DriveLetterFromVolumeSerial($volumeSerial) {
    $drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3"
    foreach ($drive in $drives) {
        # Get the volume serial number
        $volSerial = (Get-WmiObject Win32_Volume -Filter "DriveLetter = '$($drive.DeviceID)'").SerialNumber
        # Remove dashes and spaces from the serial number for comparison
        $formattedDecimalSerial = $volSerial -replace "[-\s]"

        # Convert to integer and then to hex
        $intSerial = [long]$formattedDecimalSerial
        $hexSerial = '{0:X}' -f $intSerial        # For debug, echo the drive letter and serial number
        if ($hexSerial -eq $volumeSerial) {
            return $drive.DeviceID
        }
    }
    return $null
}

Function DoRobocopyAndGetNewFileCount($sourcePath, $destinationPath) {
    Write-Host -NoNewline "-- Backing up $sourcePath\ to $destinationPath\"
    $progressIndicator = "."
    $progressCounter = 0
    $script:newFilesCopied = 0

    $robocopyOutput = & robocopy $sourcePath $destinationPath /E /ZB /SEC /COPYALL /V /DCOPY:T
    foreach ($line in $robocopyOutput) {
        if ($line -match "New File") {
            $script:newFilesCopied++
            $script:progressCounter++
            Write-Host -NoNewline $progressIndicator
        }
    }

    Write-Host ""
    Write-Host "---- Copied $script:newFilesCopied new files."

    return $script:newFilesCopied
}



# Function to run chkdsk in read-only mode and return PASS or FAIL
Function DoChkDskReadOnly($driveLetter) {
    $chkdskOutput = chkdsk $driveLetter | Out-String
    if ($chkdskOutput -match "Windows has scanned the file system and found no problems") {
        return "PASS"
    }
    else {
        return "FAIL"
    }
}

# Function to update the last backup file
Function Update-LastBackupFile($driveLetter) {
    # Define the path for the new last backup file
    $dateString = (Get-Date).ToString("yyyy-MM-dd")
    $newBackupFilePath = "${driveLetter}LastBackup$dateString.txt"

    # Delete old last backup files
    Get-ChildItem -Path "${driveLetter}LastBackup*.txt" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

    # Create new last backup file
    New-Item -Path $newBackupFilePath -ItemType "file" -ErrorAction SilentlyContinue | Out-Null
}

### Main Script Execution Starts Here ###

# Loop over the drivesToBackup array from the configuration
foreach ($driveBackup in $config.drivesToBackup) {
    $primarySerial = $driveBackup.primarySerial
    $backupSerial = $driveBackup.backupSerial
    $directories = $driveBackup.directories
    $name = $driveBackup.name

    # Get drive letters based on volume serial numbers
    $primaryLetter = Get-DriveLetterFromVolumeSerial $primarySerial
    $backupLetter = Get-DriveLetterFromVolumeSerial $backupSerial

    # Verify if required drive letters are detected
    if (-not $primaryLetter -or -not $backupLetter) {
        Write-Host "Error: One or both drives are missing for primary serial $primarySerial and backup serial $backupSerial"
        Continue
    }

    Write-Host "#### Backing up $name from $primaryLetter\ to $backupLetter\ ####"

    $copySummary = @{}

    # Loop over the directories and perform the backup for each directory
    foreach ($dir in $directories) {
        $sourcePath = "${primaryLetter}\$dir"
        $destinationPath = "${backupLetter}\$dir"
        $newFilesCopied = DoRobocopyAndGetNewFileCount $sourcePath $destinationPath
        $copySummary[$dir] = $newFilesCopied
    }

    # Perform a quick health check on each drive
    $doHealthCheck = $true
    if ($doHealthCheck) {
        $checkResults = @{}
        Write-Host "Performing Health Check on $primaryLetter..."
        $checkResults["Primary ($primaryLetter)"] = DoChkDskReadOnly $primaryLetter
        Write-Host "Performing Health Check on $backupLetter..."
        $checkResults["Backup ($backupLetter)"] = DoChkDskReadOnly $backupLetter

        # Report the health check results
        Write-Host "Drive Health Check Results:"
        Write-Host "----------------------------"
        foreach ($result in $checkResults.GetEnumerator()) {
            Write-Host "$($result.Key) - $($result.Value)"
        }
    }

    Write-Host ""

    # Update last backup file for each drive
    Update-LastBackupFile $primaryLetter
    Update-LastBackupFile $backupLetter
}

Write-Host "Backup Complete! LastBackup Filenames Updated on all Drives."