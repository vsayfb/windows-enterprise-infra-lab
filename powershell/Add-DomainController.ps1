#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^(?![0-9]+$)[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,13}[a-zA-Z0-9])?$')]
    [string]$ServerName,

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

# This script configures an isolated network without a default gateway.
if ($IPAddress -eq $DNSServer) {
    throw 'Use the DNS address of an existing domain controller, not the new server address.'
}

$Computer = Get-CimInstance Win32_ComputerSystem
if ($Computer.PartOfDomain -and $Computer.Domain -ine $DomainName) {
    throw 'This server belongs to another domain.'
}
if ($Computer.PartOfDomain -and $env:COMPUTERNAME -ine $ServerName) {
    throw 'The requested hostname differs from this domain member. Rename it separately before continuing.'
}

# After promotion, inspect the DC without changing its DNS configuration.
if ($Computer.DomainRole -ge 4) {
    $LocalAddress = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.IPAddress -eq $IPAddress -and $_.PrefixLength -eq $PrefixLength
    }
    if (-not $LocalAddress) {
        throw 'The supplied IPv4 configuration does not match this domain controller.'
    }

    Import-Module ActiveDirectory
    Get-ADDomainController -Identity $ServerName |
        Select-Object HostName, IPv4Address, IsGlobalCatalog
    Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$DomainName" -Type SRV -Server $IPAddress

    dcdiag /test:Advertising /test:SysVolCheck /test:NetLogons
    if ($LASTEXITCODE -ne 0) {
        throw 'Domain controller diagnostics reported a failure. Review the output.'
    }
    repadmin /showrepl $env:COMPUTERNAME
    if ($LASTEXITCODE -ne 0) {
        throw 'Replication inspection reported a failure. Review the output.'
    }
    return
}

# 1. Set the hostname before promotion.
if ($env:COMPUTERNAME -ine $ServerName) {
    Write-Host 'Renaming the server. Run this file with the same parameters after restarting.'
    Rename-Computer -NewName $ServerName -Restart
    return
}

# 2. Configure static IPv4 and use an existing domain DNS server.
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
if (-not ($Addresses | Where-Object {
    $_.IPAddress -eq $IPAddress -and $_.PrefixLength -eq $PrefixLength
})) {
    New-NetIPAddress -InterfaceIndex $Adapter.ifIndex `
        -IPAddress $IPAddress -PrefixLength $PrefixLength
}
Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $DNSServer

# Confirm that the existing DNS server publishes domain controller discovery records.
Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$DomainName" -Type SRV -Server $DNSServer

# 3. Install AD DS and management tools.
Import-Module ServerManager
if (-not (Get-WindowsFeature -Name AD-Domain-Services).Installed) {
    $Installation = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    if (-not $Installation.Success) {
        throw 'AD DS installation failed.'
    }
    if ($Installation.RestartNeeded -eq 'Yes') {
        Write-Host 'Run this file with the same parameters after restarting.'
        Restart-Computer
        return
    }
}

# 4. Promote into the existing domain. No new forest or domain is created.
Import-Module ADDSDeployment
$Credential = Get-Credential -Message "Enter credentials authorized to add a DC to $DomainName"
if ($null -eq $Credential) {
    throw 'Domain credentials were not supplied.'
}

Write-Host 'Run this file with the same parameters after promotion and restart to verify the DC.'

# Prompt securely for and confirm the DSRM password through the deployment cmdlet.
Install-ADDSDomainController -DomainName $DomainName -Credential $Credential -InstallDns
