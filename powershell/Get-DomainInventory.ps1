#Requires -Version 5.1
#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$DomainName,

    [ValidateNotNullOrEmpty()]
    [string]$Filter = 'Enabled -eq $true',

    [ValidateNotNullOrEmpty()]
    [string]$SearchBase
)

$ErrorActionPreference = 'Stop'

if (-not $DomainName) {
    $DomainName = (Get-ADDomain).DNSRoot
}

$Query = @{
    Server      = $DomainName
    Filter      = $Filter
    Properties  = 'DNSHostName'
    SearchScope = 'Subtree'
}

if ($SearchBase) {
    $Query.SearchBase = $SearchBase
}

$Computers = @(Get-ADComputer @Query | Sort-Object Name)

if ($Computers.Count -eq 0) {
    Write-Warning 'No computer accounts matched the supplied domain, OU, and filter.'
}

foreach ($Computer in $Computers) {
    $Record = [ordered]@{
        ComputerName = $Computer.Name
        DNSHostName  = $Computer.DNSHostName
        Domain       = $null
        OS           = $null
        RAM_GB       = $null
        LogicalCPUs  = $null
        LastBoot     = $null
        Status       = 'Failed'
        Error        = $null
    }

    try {
        if (-not $Computer.DNSHostName) {
            throw 'The AD computer account has no DNS hostname.'
        }

        $Details = Invoke-Command `
            -ComputerName $Computer.DNSHostName `
            -ErrorAction Stop `
            -ScriptBlock {
                $System = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop

                $OS = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop

                [pscustomobject]@{
                    Domain      = $System.Domain
                    OS          = $OS.Caption
                    RAM_GB      = [math]::Round(
                        $System.TotalPhysicalMemory / 1GB, 1
                    )
                    LogicalCPUs = $System.NumberOfLogicalProcessors
                    LastBoot    = $OS.LastBootUpTime
                }
            }

        $Record.Domain = $Details.Domain

        $Record.OS = $Details.OS

        $Record.RAM_GB = $Details.RAM_GB

        $Record.LogicalCPUs = $Details.LogicalCPUs

        $Record.LastBoot = $Details.LastBoot

        $Record.Status = 'Success'
    }
    catch {
        $Record.Error = $_.Exception.Message
    }

    [pscustomobject]$Record
}
