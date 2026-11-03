#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z]:$')]
    [string]$BackupTarget,

    [Parameter(Mandatory)]
    [ValidatePattern('^\d{2}/\d{2}/\d{4}-\d{2}:\d{2}$')]
    [string]$Version,

    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9-]{0,14}$')]
    [string]$MachineName = $env:COMPUTERNAME,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z]:\\[^,*?]+$')]
    [string]$SourcePath,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z]:\\[^,*?]+$')]
    [string]$RecoveryTarget
)

$ErrorActionPreference = 'Stop'

Get-Command wbadmin -ErrorAction Stop | Out-Null

if (-not (Test-Path -LiteralPath "$BackupTarget\" -PathType Container)) {
    throw 'The backup volume is not accessible.'
}

# SourcePath identifies the original path in the backup; it need not exist now.
$SourcePath = [System.IO.Path]::GetFullPath($SourcePath).TrimEnd('\')

$RecoveryTarget = [System.IO.Path]::GetFullPath($RecoveryTarget).TrimEnd('\')

foreach ($Path in @($SourcePath, $RecoveryTarget)) {
    if ($Path -eq [System.IO.Path]::GetPathRoot($Path).TrimEnd('\')) {
        throw 'Specify file or folder paths, not drive roots.'
    }
}

$Comparison = [System.StringComparison]::OrdinalIgnoreCase

if ($RecoveryTarget -ieq $SourcePath -or
    $RecoveryTarget.StartsWith("$SourcePath\", $Comparison) -or
    $SourcePath.StartsWith("$RecoveryTarget\", $Comparison)) {
    throw 'The recovery destination must be separate from the source path, not its parent or child.'
}

if ([System.IO.Path]::GetPathRoot($RecoveryTarget).TrimEnd('\') -ieq $BackupTarget) {
    throw 'Select a recovery destination outside the backup volume.'
}

# Reject junctions and symbolic links along the destination path.
$Ancestor = $RecoveryTarget

while ($Ancestor) {
    if (Test-Path -LiteralPath $Ancestor) {
        $Item = Get-Item -LiteralPath $Ancestor -Force

        if (-not $Item.PSIsContainer -or
            ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            throw 'The recovery destination and its parents must be regular directories.'
        }
    }

    $Ancestor = [System.IO.Path]::GetDirectoryName($Ancestor)
}

if (Test-Path -LiteralPath $RecoveryTarget) {
    if (Get-ChildItem -LiteralPath $RecoveryTarget -Force | Select-Object -First 1) {
        throw 'The recovery destination must be empty. Choose a new folder for each test.'
    }
} else {
    New-Item -Path $RecoveryTarget -ItemType Directory | Out-Null
}

# Inspect the selected catalog before starting file recovery.
wbadmin get items "-version:$Version" "-backupTarget:$BackupTarget" "-machine:$MachineName"

if ($LASTEXITCODE -ne 0) {
    throw 'Could not read the selected backup catalog. Recovery was not started.'
}

# File-only recovery to an alternate directory; retain native confirmation.
wbadmin start recovery `
    "-version:$Version" `
    "-backupTarget:$BackupTarget" `
    "-machine:$MachineName" `
    -itemType:File `
    "-items:$SourcePath" `
    "-recoveryTarget:$RecoveryTarget" `
    -recursive `
    -overwrite:Skip

if ($LASTEXITCODE -ne 0) {
    throw "File recovery did not complete successfully. wbadmin exit code: $LASTEXITCODE"
}

$Files = @(Get-ChildItem -LiteralPath $RecoveryTarget -Recurse -File -Force)

$Files | Select-Object FullName, Length

[pscustomobject]@{
    BackupVersion     = $Version
    MachineName       = $MachineName
    RecoveryTarget    = $RecoveryTarget
    RestoredFileCount = $Files.Count
}
