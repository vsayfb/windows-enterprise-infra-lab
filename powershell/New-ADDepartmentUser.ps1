#Requires -Version 5.1
#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DomainName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9 _-]{0,63}$')]
    [string]$OUName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$')]
    [string]$GroupName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z][a-zA-Z0-9._-]{0,19}$')]
    [string]$AccountName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,

    [ValidateNotNullOrEmpty()]
    [string]$ParentPath
)

$ErrorActionPreference = 'Stop'

$Domain = Get-ADDomain -Identity $DomainName

$ADServer = $Domain.PDCEmulator

if (-not $ParentPath) {
    $ParentPath = $Domain.DistinguishedName
}

$Parent = Get-ADObject -Identity $ParentPath -Server $ADServer

$InDomain = $Parent.DistinguishedName -ieq $Domain.DistinguishedName -or
    $Parent.DistinguishedName.EndsWith(",$($Domain.DistinguishedName)",
        [System.StringComparison]::OrdinalIgnoreCase)

if (-not $InDomain -or $Parent.ObjectClass -notin @('domainDNS', 'organizationalUnit')) {
    throw 'ParentPath must identify the domain root or an existing OU in the selected domain.'
}

$OUPath = "OU=$OUName,$($Parent.DistinguishedName)"

# 1. Create the department OU.
$OU = Get-ADOrganizationalUnit -Server $ADServer `
    -SearchBase $Parent.DistinguishedName -SearchScope OneLevel `
    -Filter "Name -eq '$OUName'" -Properties ProtectedFromAccidentalDeletion

if (-not $OU) {
    New-ADOrganizationalUnit -Name $OUName `
        -Path $Parent.DistinguishedName `
        -ProtectedFromAccidentalDeletion $true -Server $ADServer
} elseif (-not $OU.ProtectedFromAccidentalDeletion) {
    Set-ADOrganizationalUnit -Identity $OUPath `
        -ProtectedFromAccidentalDeletion $true -Server $ADServer
}

# 2. Create the global security group without moving or repurposing another group.
$GroupPath = "CN=$GroupName,$OUPath"

$Group = Get-ADGroup -Filter "SamAccountName -eq '$GroupName'" -Server $ADServer

if (-not $Group) {
    $Group = New-ADGroup -Name $GroupName -SamAccountName $GroupName `
        -GroupScope Global -GroupCategory Security -Path $OUPath `
        -Server $ADServer -PassThru
} elseif ($Group.DistinguishedName -ine $GroupPath -or
    $Group.GroupScope -ne 'Global' -or $Group.GroupCategory -ne 'Security') {
    throw 'The existing group has a different location, scope, or category.'
}

# 3. Create the user disabled, then set a valid password before enabling it.
$UPN = "$AccountName@$($Domain.DNSRoot)"

$User = Get-ADUser -Filter "SamAccountName -eq '$AccountName'" -Server $ADServer

if (-not $User) {
    $User = New-ADUser -Name $DisplayName -DisplayName $DisplayName `
        -SamAccountName $AccountName -UserPrincipalName $UPN `
        -Path $OUPath -Enabled $false -Server $ADServer -PassThru
} else {
    $OUUsers = @(Get-ADUser -SearchBase $OUPath -SearchScope OneLevel `
        -Filter "SamAccountName -eq '$AccountName'" -Server $ADServer)

    if ($OUUsers.Count -ne 1 -or $User.UserPrincipalName -ine $UPN) {
        throw 'The existing account has a different OU or user principal name.'
    }
}

if (-not $User.Enabled) {
    $Password = Read-Host "Enter a temporary password for $AccountName" -AsSecureString

    try {
        Set-ADAccountPassword -Identity $User -Reset -NewPassword $Password -Server $ADServer
    } finally {
        if ($null -ne $Password) {
            $Password.Dispose()

            Remove-Variable Password
        }
    }

    Set-ADUser -Identity $User -ChangePasswordAtLogon $true -Server $ADServer

    Enable-ADAccount -Identity $User -Server $ADServer
}

# 4. Add direct membership without resetting an already enabled user's password.
$Members = @(Get-ADGroupMember -Identity $Group -Server $ADServer)

if ($User.SID.Value -notin @($Members | ForEach-Object { $_.SID.Value })) {
    Add-ADGroupMember -Identity $Group -Members $User -Server $ADServer
}

# 5. Display the resulting objects and membership.
Get-ADOrganizationalUnit -Identity $OUPath -Server $ADServer `
    -Properties ProtectedFromAccidentalDeletion |
    Select-Object Name, DistinguishedName, ProtectedFromAccidentalDeletion

Get-ADGroup -Identity $GroupName -Server $ADServer |
    Select-Object Name, GroupScope, GroupCategory, DistinguishedName

Get-ADUser -Identity $AccountName -Server $ADServer -Properties pwdLastSet |
    Select-Object Name, SamAccountName, UserPrincipalName, Enabled, DistinguishedName, pwdLastSet

Get-ADGroupMember -Identity $GroupName -Server $ADServer |
    Select-Object Name, SamAccountName
