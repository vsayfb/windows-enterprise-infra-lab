#Requires -Version 5.1
#Requires -RunAsAdministrator

# Run in Windows PowerShell. Run this file again after each restart.
$ErrorActionPreference = 'Stop'

$ServerName    = 'DC01'
$InterfaceName = 'Ethernet'
$IPAddress     = '10.10.10.10'
$PrefixLength  = 24
$DomainName    = 'corp.test'
$NetBIOSName   = 'CORP'

# Reject existing domain members other than the intended domain controller.
$Computer = Get-CimInstance Win32_ComputerSystem
if ($Computer.PartOfDomain -and (
    $Computer.DomainRole -lt 4 -or
    $Computer.Domain -ine $DomainName -or
    $env:COMPUTERNAME -ine $ServerName
)) {
    throw 'Run on a standalone server or the existing DC01 domain controller for corp.test.'
}

# 1. Configure the Windows hostname.
if ($env:COMPUTERNAME -ine $ServerName) {
    Write-Host 'Renaming the server. Run this file again after restarting.'
    Rename-Computer -NewName $ServerName -Restart
    return
}

# 2. Configure the isolated lab network without replacing other static addresses.
$Adapter = Get-NetAdapter -Name $InterfaceName
$Addresses = @(
    Get-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4
)
$Conflicts = @(
    $Addresses | Where-Object {
        $_.IPAddress -notlike '169.254.*' -and
        ($_.IPAddress -ne $IPAddress -or $_.PrefixLength -ne $PrefixLength)
    }
)
if ($Conflicts.Count -gt 0) {
    throw 'An existing IPv4 address conflicts with the lab configuration. Review it before continuing.'
}

$DefaultRoute = Get-NetRoute -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 |
    Where-Object DestinationPrefix -eq '0.0.0.0/0'
if ($DefaultRoute) {
    throw 'A default gateway is configured. Review it before configuring the isolated lab.'
}

$ConfiguredAddress = $Addresses | Where-Object {
    $_.IPAddress -eq $IPAddress -and $_.PrefixLength -eq $PrefixLength
}
if (-not $ConfiguredAddress) {
    New-NetIPAddress -InterfaceIndex $Adapter.ifIndex `
        -IPAddress $IPAddress -PrefixLength $PrefixLength
}
Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $IPAddress

# 3. Install AD DS and management tools.
Import-Module ServerManager
$Role = Get-WindowsFeature -Name AD-Domain-Services
if (-not $Role.Installed) {
    $Installation = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    if (-not $Installation.Success) {
        throw 'AD DS installation failed.'
    }
    if ($Installation.RestartNeeded -eq 'Yes') {
        Write-Host 'Run this file again after restarting.'
        Restart-Computer
        return
    }
}

# 4. Create the forest. Promotion prompts for confirmation and restarts the server.
if ($Computer.DomainRole -lt 4) {
    Import-Module ADDSDeployment
    Write-Host 'Run this file again after promotion and restart to verify DC01.'

    # Allow the deployment cmdlet to prompt securely for and confirm the DSRM password.
    Install-ADDSForest -DomainName $DomainName `
        -DomainNetbiosName $NetBIOSName -InstallDns
    return
}

# 5. Verify the deployed domain controller.
Import-Module ActiveDirectory
hostname
Get-NetIPConfiguration -InterfaceIndex $Adapter.ifIndex
Test-Connection -ComputerName '10.10.10.1' -Count 2

Get-ADDomain |
    Select-Object DNSRoot, NetBIOSName, DomainMode
Get-ADDomainController -Identity $ServerName |
    Select-Object HostName, IPv4Address, IsGlobalCatalog

Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$DomainName" -Type SRV

dcdiag /test:Advertising /test:SysVolCheck /test:NetLogons
if ($LASTEXITCODE -ne 0) {
    throw 'Domain controller diagnostics reported a failure. Review the output.'
}
