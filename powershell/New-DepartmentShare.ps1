#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Modules SmbShare

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z]:\\.+')]
    [string]$RootPath,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}$')]
    [string]$ShareName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[^\\]+\\[^\\]+$')]
    [string]$AccessGroup
)

$ErrorActionPreference = 'Stop'

$RootPath = [System.IO.Path]::GetFullPath($RootPath).TrimEnd('\')

if ($RootPath -eq [System.IO.Path]::GetPathRoot($RootPath).TrimEnd('\')) {
    throw 'RootPath must be a dedicated folder, not a drive root.'
}

$DepartmentPath = Join-Path $RootPath $ShareName

$AdminSID = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')

$SystemSID = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-18')

$GroupSID = ([System.Security.Principal.NTAccount]::new($AccessGroup)).Translate(
    [System.Security.Principal.SecurityIdentifier])

if ($GroupSID.Value -in @($AdminSID.Value, $SystemSID.Value)) {
    throw 'AccessGroup must be a department security group.'
}

$AdminName = $AdminSID.Translate([System.Security.Principal.NTAccount]).Value

$ExpectedRoot = @{
    $AdminSID.Value  = [System.Security.AccessControl.FileSystemRights]::FullControl
    $SystemSID.Value = [System.Security.AccessControl.FileSystemRights]::FullControl
}

$ExpectedDepartment = @{
    $AdminSID.Value  = [System.Security.AccessControl.FileSystemRights]::FullControl
    $SystemSID.Value = [System.Security.AccessControl.FileSystemRights]::FullControl
    $GroupSID.Value  = [System.Security.AccessControl.FileSystemRights]::Modify
}

# Check existing folders without deleting or replacing unrelated permission entries.
function Assert-FolderAccess {
    param([string]$Path, [hashtable]$Allowed, [bool]$Protected)

    $Item = Get-Item -LiteralPath $Path

    if (-not $Item.PSIsContainer -or
        ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        throw "Use a regular directory: $Path"
    }

    $ACL = Get-Acl -LiteralPath $Path

    if ($ACL.AreAccessRulesProtected -ne $Protected) {
        throw "The existing folder has a different inheritance configuration: $Path"
    }

    $Rules = $ACL.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])

    foreach ($Rule in $Rules) {
        $SID = $Rule.IdentityReference.Value

        # Modify allow entries can also include Synchronize.
        $Rights = $Rule.FileSystemRights -band
            (-bnot [System.Security.AccessControl.FileSystemRights]::Synchronize)

        if (-not $Allowed.ContainsKey($SID) -or
            $Rule.AccessControlType -ne 'Allow' -or
            $Rights -ne ($Allowed[$SID] -band
                (-bnot [System.Security.AccessControl.FileSystemRights]::Synchronize))) {
            throw "The existing folder has conflicting permissions: $Path"
        }
    }

    # The administrative baseline must cover the folder, subfolders, and files.
    foreach ($SID in @($AdminSID.Value, $SystemSID.Value)) {
        $Baseline = @($Rules | Where-Object {
            $_.IdentityReference.Value -eq $SID -and
            $_.FileSystemRights -eq [System.Security.AccessControl.FileSystemRights]::FullControl -and
            $_.InheritanceFlags -eq 'ContainerInherit, ObjectInherit' -and
            $_.PropagationFlags -eq 'None'
        })

        if ($Baseline.Count -eq 0) {
            throw "The existing folder is missing inheritable administrative access: $Path"
        }
    }
}

# 1. Validate existing configuration before changing folders or shares.
if (Test-Path -LiteralPath $RootPath) {
    Assert-FolderAccess -Path $RootPath -Allowed $ExpectedRoot -Protected $true
}

if (Test-Path -LiteralPath $DepartmentPath) {
    Assert-FolderAccess -Path $DepartmentPath -Allowed $ExpectedDepartment -Protected $false
}

$Share = Get-SmbShare | Where-Object Name -eq $ShareName

if ($Share) {
    if (@($Share).Count -ne 1 -or
        [System.IO.Path]::GetFullPath($Share.Path).TrimEnd('\') -ine $DepartmentPath) {
        throw 'The share name is already used for another path or scope.'
    }

    foreach ($Entry in (Get-SmbShareAccess -Name $ShareName)) {
        $SID = ([System.Security.Principal.NTAccount]::new($Entry.AccountName)).Translate(
            [System.Security.Principal.SecurityIdentifier]).Value

        $ExpectedRight = if ($SID -eq $AdminSID.Value) { 'Full' }
            elseif ($SID -eq $GroupSID.Value) { 'Change' }
            else { $null }

        if (-not $ExpectedRight -or $Entry.AccessControlType -ne 'Allow' -or
            $Entry.AccessRight -ne $ExpectedRight) {
            throw 'The existing share has conflicting permissions.'
        }
    }
}

# 2. Establish the administrative baseline on a new parent folder.
if (-not (Test-Path -LiteralPath $RootPath)) {
    New-Item -Path $RootPath -ItemType Directory | Out-Null

    $RootACL = [System.Security.AccessControl.DirectorySecurity]::new()

    $RootACL.SetAccessRuleProtection($true, $false)

    foreach ($SID in @($AdminSID, $SystemSID)) {
        $Rule = [System.Security.AccessControl.FileSystemAccessRule]::new(
            $SID, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow')

        $RootACL.AddAccessRule($Rule)
    }

    Set-Acl -LiteralPath $RootPath -AclObject $RootACL
}

# 3. Inherit the baseline and add department Modify access.
if (-not (Test-Path -LiteralPath $DepartmentPath)) {
    New-Item -Path $DepartmentPath -ItemType Directory | Out-Null
}

$DepartmentACL = Get-Acl -LiteralPath $DepartmentPath

$DepartmentRule = [System.Security.AccessControl.FileSystemAccessRule]::new(
    $GroupSID, 'Modify', 'ContainerInherit, ObjectInherit', 'None', 'Allow')

$DepartmentACL.SetAccessRule($DepartmentRule)

Set-Acl -LiteralPath $DepartmentPath -AclObject $DepartmentACL

# 4. Publish the folder or retain the matching share on a rerun.
if (-not $Share) {
    New-SmbShare -Name $ShareName -Path $DepartmentPath `
        -ChangeAccess $AccessGroup -FullAccess $AdminName
} else {
    Grant-SmbShareAccess -Name $ShareName -AccountName $AdminName -AccessRight Full -Force

    Grant-SmbShareAccess -Name $ShareName -AccountName $AccessGroup -AccessRight Change -Force
}

# 5. Inspect both permission layers.
Get-Acl -LiteralPath $RootPath |
    Format-List Path, AccessToString, AreAccessRulesProtected

Get-Acl -LiteralPath $DepartmentPath |
    Format-List Path, AccessToString, AreAccessRulesProtected

Get-SmbShare -Name $ShareName | Select-Object Name, Path

Get-SmbShareAccess -Name $ShareName
