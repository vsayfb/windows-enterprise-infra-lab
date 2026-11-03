#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^(?![0-9]+$)[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,13}[a-zA-Z0-9])?$')]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [ValidateScript({
        ([System.Net.IPAddress]::Parse($_)).AddressFamily -eq
            [System.Net.Sockets.AddressFamily]::InterNetwork
    })]
    [string]$IPAddress,

    [Parameter(Mandatory)]
    [ValidateScript({
        ([System.Net.IPAddress]::Parse($_)).AddressFamily -eq
            [System.Net.Sockets.AddressFamily]::InterNetwork
    })]
    [string]$DNSServer,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z0-9-]+$')]
    [string]$DomainName,

    [ValidateRange(1, 30)]
    [int]$PrefixLength = 24,

    [ValidateNotNullOrEmpty()]
    [string]$InterfaceName = 'Ethernet'
)

$ErrorActionPreference = 'Stop'

$Computer = Get-CimInstance Win32_ComputerSystem

if ($Computer.DomainRole -ge 4) {
    throw 'Run on a member computer, not a domain controller.'
}

if ($Computer.PartOfDomain -and $Computer.Domain -ine $DomainName) {
    throw 'This computer already belongs to another domain.'
}

if ($Computer.PartOfDomain -and $env:COMPUTERNAME -ine $ComputerName) {
    throw 'The requested hostname differs from this domain member. Rename it separately before continuing.'
}

# 1. Set the hostname before joining the domain.
if ($env:COMPUTERNAME -ine $ComputerName) {
    Write-Host 'Renaming the computer. Run this file with the same parameters after restarting.'

    Rename-Computer -NewName $ComputerName -Restart

    return
}

# 2. Inspect the isolated lab network before making changes.
$Adapter = Get-NetAdapter -Name $InterfaceName

$Addresses = @(Get-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4)

$Conflicts = @($Addresses | Where-Object {
    $_.IPAddress -notlike '169.254.*' -and
    ($_.IPAddress -ne $IPAddress -or $_.PrefixLength -ne $PrefixLength)
})

if ($Conflicts.Count -gt 0) {
    throw 'An existing IPv4 address conflicts with the requested configuration.'
}

$DefaultRoute = Get-NetRoute -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 |
    Where-Object DestinationPrefix -eq '0.0.0.0/0'

if ($DefaultRoute) {
    throw 'A default gateway is configured. Review it before configuring the isolated lab.'
}

$ConfiguredAddress = $Addresses | Where-Object {
    $_.IPAddress -eq $IPAddress -and $_.PrefixLength -eq $PrefixLength
}

if ($Computer.PartOfDomain -and -not $ConfiguredAddress) {
    throw 'The supplied IPv4 configuration does not match this domain member.'
}

# Preserve the network configuration of an existing domain member on reruns.
if (-not $Computer.PartOfDomain) {
    if (-not $ConfiguredAddress) {
        New-NetIPAddress -InterfaceIndex $Adapter.ifIndex `
            -IPAddress $IPAddress -PrefixLength $PrefixLength
    }

    Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $DNSServer
}

# 3. Discover a domain controller using the client's configured DNS servers.
Get-NetIPConfiguration -InterfaceIndex $Adapter.ifIndex

nltest "/dsgetdc:$DomainName" /force

if ($LASTEXITCODE -ne 0) {
    throw 'Domain controller discovery failed. Check DNS settings and connectivity before joining.'
}

# 4. Verify an existing membership rather than attempting another join.
if ($Computer.PartOfDomain) {
    $Computer | Select-Object Name, Domain, PartOfDomain

    if (-not (Test-ComputerSecureChannel -Verbose)) {
        throw 'The computer secure channel check failed. No repair was attempted.'
    }

    return
}

# 5. Join the existing domain and restart. Credentials are entered interactively.
$Credential = Get-Credential -Message "Enter credentials authorized to join computers to $DomainName"

if ($null -eq $Credential) {
    throw 'Domain credentials were not supplied.'
}

Write-Host 'Run this file with the same parameters after restarting to verify domain membership.'

Add-Computer -DomainName $DomainName -Credential $Credential -Restart -Verbose
