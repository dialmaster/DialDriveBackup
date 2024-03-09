param(
    [string]$driveLetter
)

$driveLetterWithColon = $driveLetter + ":"

$driveInfo = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object {$_.DeviceID -eq $driveLetterWithColon} | Select-Object VolumeSerialNumber

if ($driveInfo) {
    Write-Output "The serial number for drive $driveLetterWithColon is: $($driveInfo.VolumeSerialNumber)"
} else {
    Write-Output "Drive $driveLetterWithColon not found."
}
