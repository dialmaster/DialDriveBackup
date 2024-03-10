# Backup Utility
This repository contains a PowerShell script for automating the backup process of multiple drives. The script is designed to ensure that backups are performed consistently and reliably, even if the drive letters change.

## Purpose
The main purpose of this backup utility is to simplify and automate the process of backing up data from primary drives to their corresponding backup drives. By using drive serial numbers instead of drive letters, the script ensures that the backups always work as expected, even if the drive letters are reassigned or changed.

## Features
* Reads backup configuration from an external JSON file
* Supports multiple pairs of primary and backup drives
* Performs incremental backups using Robocopy
* Performs quick health checks on the drives using chkdsk
* Updates a "LastBackup" file on each drive with the current date, making it easy to tell when the last backup was run

## Prerequisites
* Windows operating system
* PowerShell v3.0 or later
* Administrator privileges

## Usage
1. Clone this repository to your local machine.

2. Update the config.json file with your specific drive serial numbers and directories to backup.

3. Open a PowerShell console with Administrator privileges.

4. Navigate to the directory containing the backup script.

5. Run the script using the following command:
```
.\backup_drives.ps1
```

6. The script will read the configuration from config.json, perform the backups, health checks, and update the "LastBackup" files on each drive.

7. Once the backup process is complete, a summary of the backup operations will be displayed in the console.


## Files
* **config.json**: The required configuration file to run the script, see below for more information. You must create this file.
* **config.json.example**: The provided example configuration showing how to fill in values. ***You cannot use this as provided, it is only an example.***
* **backup_drives.ps1**: The script to execute to run your backup & drive health check.
* **get_drive_serial.ps1**: A helper script to get drive serial numbers for specific drive letters.

## Configuration setup
The backup configuration is stored in a file named config.json. 

This file contains an array of "drives to backup", where each item represents a pair of primary and backup drives along with their respective directories to backup. 

See config.json.example for an example config, copy it to config.json and fill in your details before you run the backup scripts.

To obtain the serial number of a drive, you can use the get_drive_serial.ps1 script provided in this repository. Simply run the script with the drive letter as an argument, and it will return the corresponding serial number.

Example usage of get_drive_serial.ps1:

```
.\get_drive_serial.ps1 C
```

## Why Use Drive Serial Numbers?
**Using drive serial numbers instead of drive letters offers several advantages:**

* **Consistency:** Drive letters can change due to various reasons, such as adding or removing drives, or changing the drive connection order. By using serial numbers, the script ensures that the backups are always performed between the intended drives, regardless of their assigned letters.
* **Flexibility:** If you need to move the drives to a different system or reconnect them in a different order, the script will still function correctly as long as the serial numbers match the configuration.
* **Automation:** By relying on serial numbers, the script can be scheduled to run automatically without the need to manually update drive letters in the configuration file.

## Contributing
If you have any suggestions, bug reports, or feature requests, please open an issue or submit a pull request to this repository. I appreciate your contributions!
