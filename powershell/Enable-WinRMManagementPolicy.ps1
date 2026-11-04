#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory, GroupPolicy, NetSecurity

<#
.SYNOPSIS
Configures WinRM settings in an existing GPO and links it to an existing OU.

.DESCRIPTION
Sets automatic WinRM service startup, an IPv4 listener policy, and a
Domain-profile TCP 5985 firewall rule scoped to the supplied management IPv4 addresses.
The GPO link is published after configuration. Clients apply settings through
normal Group Policy processing. Existing service permissions are preserved.

.PARAMETER DomainName
DNS name of the existing Active Directory domain.

.PARAMETER GPOName
Display name of the existing GPO. No GPO is created.

.PARAMETER TargetOU
Distinguished name of the existing computer OU receiving the GPO link.

.PARAMETER ManagementAddresses
Complete list of IPv4 addresses permitted by the managed WinRM firewall rule.
Each execution replaces the previous source list rather than appending to it.

.EXAMPLE
.\Enable-WinRMManagementPolicy.ps1 -DomainName corp.test -GPOName 'PCs-WinRM' `
    -TargetOU 'OU=PCs,DC=corp,DC=test' -ManagementAddresses '10.10.10.10', '10.10.10.11'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DomainName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetOU,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$')]
    [ValidateScript({
        ([System.Net.IPAddress]::Parse($_)).AddressFamily -eq
            [System.Net.Sockets.AddressFamily]::InterNetwork
    })]
    [string[]]$ManagementAddresses,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$GPOName
)

$ErrorActionPreference = 'Stop'

$ManagementAddresses = @($ManagementAddresses |
    ForEach-Object { ([System.Net.IPAddress]::Parse($_)).ToString() } |
    Sort-Object -Unique)

# Check the firewall cmdlet interface before modifying the GPO.
foreach ($CommandName in @('Get-NetFirewallRule', 'New-NetFirewallRule', 'Set-NetFirewallRule')) {
    $Command = Get-Command $CommandName

    if (-not $Command.Parameters.ContainsKey('PolicyStore')) {
        throw "$CommandName does not support domain policy stores on this computer."
    }
}

if ($GPOName -in @('Default Domain Policy', 'Default Domain Controllers Policy')) {
    throw 'Use a dedicated WinRM GPO.'
}

$Domain = Get-ADDomain -Identity $DomainName

$DC = $Domain.PDCEmulator

$DomainName = $Domain.DNSRoot

$OU = Get-ADOrganizationalUnit -Identity $TargetOU -Server $DC

if (-not $OU.DistinguishedName.EndsWith(",$($Domain.DistinguishedName)",
    [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'TargetOU must belong to the supplied domain.'
}

# 1. Validate the existing GPO before editing policy settings.
$GPO = Get-GPO -Name $GPOName -Domain $DomainName -Server $DC

if ($GPO.GpoStatus -in @('ComputerSettingsDisabled', 'AllSettingsDisabled')) {
    throw 'Computer settings are disabled on the supplied GPO.'
}

# 2. Set automatic startup through the same Security Settings extension as the GUI.
# MS-GPSB section 2.2.8: StartupMode 2 is Automatic. Preserve an existing service DACL.
$Guid = $GPO.Id.ToString('B').ToUpperInvariant()

$GPODN = "CN=$Guid,CN=Policies,CN=System,$($Domain.DistinguishedName)"

$PolicyPath = "\\$DC\SYSVOL\$DomainName\Policies\$Guid"

$SecurityPath = Join-Path $PolicyPath 'Machine\Microsoft\Windows NT\SecEdit'

$TemplatePath = Join-Path $SecurityPath 'GptTmpl.inf'

$Container = Get-ADObject -Identity $GPODN -Server $DC -Properties gPCMachineExtensionNames

$Extensions = [string]$Container.gPCMachineExtensionNames

$Groups = @([regex]::Matches($Extensions, '\[[^\]]+\]') | ForEach-Object { $_.Value })

if (($Groups -join '') -cne $Extensions) {
    throw 'Unexpected GPO extension metadata. No security template changes were made.'
}

$SecurityCSE = '{827D319E-6EAC-11D2-A4EA-00C04F79F83A}'

$SecurityEditor = '{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}'

$UpdatedGroups = @($Groups | ForEach-Object {
    if ($_.StartsWith("[$SecurityCSE", [System.StringComparison]::OrdinalIgnoreCase) -and
        $_.IndexOf($SecurityEditor, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $_.TrimEnd(']') + $SecurityEditor + ']'
    } else {
        $_
    }
})

if (-not ($UpdatedGroups | Where-Object {
    $_.StartsWith("[$SecurityCSE", [System.StringComparison]::OrdinalIgnoreCase)
})) {
    $UpdatedGroups += "[$SecurityCSE$SecurityEditor]"
}

# Extension groups must remain sorted by their client-side extension GUID.
$UpdatedExtensions = ($UpdatedGroups | Sort-Object) -join ''

$Lines = [System.Collections.Generic.List[string]]::new()

if (Test-Path -LiteralPath $TemplatePath) {
    foreach ($Line in [System.IO.File]::ReadAllLines($TemplatePath)) {
        $Lines.Add($Line)
    }
} else {
    foreach ($Line in @('[Unicode]', 'Unicode=yes', '', '[Version]',
        'signature="$CHICAGO$"', 'Revision=1')) {
        $Lines.Add($Line)
    }
}

$Section = -1

for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
    if ($Lines[$Index].Trim() -ieq '[Service General Setting]') {
        if ($Section -ge 0) {
            throw 'Duplicate service sections found in the security template.'
        }

        $Section = $Index
    }
}

if ($Section -lt 0) {
    $Lines.Add('')
    $Lines.Add('[Service General Setting]')
    $Lines.Add('WinRM,2,""')
} else {
    $End = $Section + 1

    while ($End -lt $Lines.Count -and $Lines[$End] -notmatch '^\s*\[') {
        $End++
    }

    $ServiceEntries = @()

    for ($Index = $Section + 1; $Index -lt $End; $Index++) {
        if ($Lines[$Index] -match '^\s*"?WinRM"?\s*,\s*\d+\s*,(.*)$') {
            $ServiceEntries += $Index
        }
    }

    if ($ServiceEntries.Count -gt 1) {
        throw 'Duplicate WinRM service settings found in the security template.'
    }

    if ($ServiceEntries.Count -eq 1) {
        $Index = $ServiceEntries[0]

        $Lines[$Index] = [regex]::Replace($Lines[$Index],
            '^(\s*"?WinRM"?\s*,\s*)\d+(\s*,.*)$', '${1}2${2}',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    } else {
        $Lines.Insert($End, 'WinRM,2,""')
    }
}

New-Item -Path $SecurityPath -ItemType Directory -Force | Out-Null

[System.IO.File]::WriteAllText($TemplatePath, ($Lines -join "`r`n") + "`r`n",
    [System.Text.Encoding]::Unicode)

Set-ADObject -Identity $GPODN -Server $DC -Replace @{
    gPCMachineExtensionNames = $UpdatedExtensions
}

# 3. Configure listener policy. Native GPO cmdlets also publish the new machine version.
$RegistryParameters = @{
    Guid   = $GPO.Id
    Domain = $DomainName
    Server = $DC
    Key    = 'HKLM\Software\Policies\Microsoft\Windows\WinRM\Service'
}

Set-GPRegistryValue @RegistryParameters -ValueName 'AllowAutoConfig' -Type DWord -Value 1 | Out-Null

Set-GPRegistryValue @RegistryParameters -ValueName 'IPv4Filter' -Type String -Value '*' | Out-Null

Set-GPRegistryValue @RegistryParameters -ValueName 'IPv6Filter' -Type String -Value '' | Out-Null

# 4. Configure the Domain-profile firewall rule in the existing domain GPO.
$RuleName = 'Lab-WinRM-Managed-HTTP-In'

$PolicyStore = "$DomainName\$GPOName"

$ExistingRule = Get-NetFirewallRule -PolicyStore $PolicyStore | Where-Object Name -eq $RuleName

$RuleParameters = @{
    PolicyStore   = $PolicyStore
    Name          = $RuleName
    Enabled       = 'True'
    Direction     = 'Inbound'
    Action        = 'Allow'
    Protocol      = 'TCP'
    LocalPort     = '5985'
    RemoteAddress = $ManagementAddresses
    Profile       = 'Domain'
}

if ($ExistingRule) {
    Set-NetFirewallRule @RuleParameters
} else {
    New-NetFirewallRule @RuleParameters -DisplayName 'WinRM from management hosts' | Out-Null
}

# 5. Publish a direct OU link after writing the settings; retain existing link order.
$Link = (Get-GPInheritance -Target $OU.DistinguishedName -Domain $DomainName -Server $DC).GpoLinks |
    Where-Object { $_.GpoId -eq $GPO.Id }

if ($Link) {
    Set-GPLink -Guid $GPO.Id -Target $OU.DistinguishedName `
        -Domain $DomainName -Server $DC -LinkEnabled Yes | Out-Null
} else {
    New-GPLink -Guid $GPO.Id -Target $OU.DistinguishedName `
        -Domain $DomainName -Server $DC -LinkEnabled Yes | Out-Null
}

[pscustomobject]@{
    GPOName             = $GPOName
    TargetOU            = $OU.DistinguishedName
    ManagementAddresses = $ManagementAddresses -join ', '
    Status              = 'PolicyConfigured'
}
