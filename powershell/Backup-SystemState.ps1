#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Modules ServerManager, Storage

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z]:$')]
    [string]$BackupTarget
)

$ErrorActionPreference = 'Stop'

# Use an existing local backup volume; never initialize or format disks here.
if ($BackupTarget -ieq $env:SystemDrive) {
    throw 'Select a backup volume other than the Windows system volume.'
}

$Volume = Get-Volume -DriveLetter $BackupTarget.Substring(0, 1)

if ($Volume.FileSystem -ne 'NTFS' -or $Volume.HealthStatus -ne 'Healthy') {
    throw 'The backup target must be an existing healthy NTFS volume.'
}

$Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, SizeRemaining, Size

# Install the optional backup feature when absent.
$Feature = Get-WindowsFeature -Name Windows-Server-Backup

if (-not $Feature.Installed) {
    $Installation = Install-WindowsFeature -Name Windows-Server-Backup

    if (-not $Installation.Success) {
        throw 'Windows Server Backup installation failed.'
    }

    if ($Installation.RestartNeeded -eq 'Yes') {
        throw 'Restart Windows, then run this script again before creating the backup.'
    }
}

# Retain wbadmin's confirmation prompt and native progress output.
wbadmin start systemstatebackup "-backupTarget:$BackupTarget"

if ($LASTEXITCODE -ne 0) {
    throw "System State backup did not complete successfully. wbadmin exit code: $LASTEXITCODE"
}

# List available versions without assuming a locale-specific output format.
wbadmin get versions "-backupTarget:$BackupTarget"

if ($LASTEXITCODE -ne 0) {
    throw 'The backup operation completed, but listing the backup catalog failed.'
}
