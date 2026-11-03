#Requires -Version 5.1
#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$DomainName,

    [Nullable[bool]]$Enabled,

    [ValidateNotNullOrEmpty()]
    [string]$OUName,

    [ValidateNotNullOrEmpty()]
    [string]$Department,

    [ValidateNotNullOrEmpty()]
    [string]$AccountName,

    [ValidateNotNullOrEmpty()]
    [string]$SearchBase,

    [ValidateNotNullOrEmpty()]
    [string]$Filter = '*'
)

$ErrorActionPreference = 'Stop'

if ($OUName -and $SearchBase) {
    throw 'Supply OUName or SearchBase, not both.'
}

if (-not $DomainName) {
    $DomainName = (Get-ADDomain).DNSRoot
}

# Resolve a friendly OU name; require a full path if the name is ambiguous.
if ($OUName) {
    $OUs = @(Get-ADOrganizationalUnit -Server $DomainName -Filter { Name -eq $OUName })

    if ($OUs.Count -ne 1) {
        throw "OU name matched $($OUs.Count) objects. Supply an exact distinguished name with SearchBase."
    }

    $SearchBase = $OUs[0].DistinguishedName
}

# AD filter expressions resolve these local variables as values.
$Conditions = [System.Collections.Generic.List[string]]::new()

$Conditions.Add("($Filter)")

if ($PSBoundParameters.ContainsKey('Enabled')) {
    if ($Enabled) {
        $Conditions.Add('Enabled -eq $true')
    } else {
        $Conditions.Add('Enabled -eq $false')
    }
}

if ($Department) {
    $Conditions.Add('Department -eq $Department')
}

if ($AccountName) {
    $Conditions.Add('SamAccountName -like $AccountName')
}

# '*' is an entire filter, not a comparison that can be combined with -and.
if ($Filter -eq '*') {
    $Conditions.RemoveAt(0)
}

$CombinedFilter = if ($Conditions.Count -gt 0) {
    $Conditions -join ' -and '
} else {
    '*'
}

$Query = @{
    Server      = $DomainName
    Filter      = $CombinedFilter
    SearchScope = 'Subtree'
    Properties  = @('Department', 'PasswordLastSet', 'LastLogonDate')
}

if ($SearchBase) {
    $Query.SearchBase = $SearchBase
}

Get-ADUser @Query |
    Sort-Object SamAccountName |
    Select-Object Name, SamAccountName, Enabled, Department, UserPrincipalName,
        DistinguishedName, PasswordLastSet, LastLogonDate
