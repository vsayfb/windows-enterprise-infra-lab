# Client networking and domain join

CLIENT01 uses DC01 for DNS and domain controller discovery. Domain membership establishes the computer account in `corp.test`; users authenticate with their own domain accounts.

| Setting | Value |
|---|---|
| Hostname | `CLIENT01` |
| IPv4 address | `10.10.10.20/24` |
| DNS server | `10.10.10.10` |
| Default gateway | None |
| Domain | `corp.test` |
| Test user | `CORP\ali` |

## IPv4 and DNS settings

CLIENT01 network configuration requires elevated Windows PowerShell. Adapter indexes are host-specific:

```powershell
Get-NetAdapter
```

CLIENT01 used interface index `3`:

```powershell
New-NetIPAddress -InterfaceIndex 3 `
    -IPAddress '10.10.10.20' -PrefixLength 24

Set-DnsClientServerAddress -InterfaceIndex 3 `
    -ServerAddresses '10.10.10.10'
```

## Domain controller discovery

```powershell
Get-NetIPConfiguration -InterfaceIndex 3

ping 10.10.10.10

nltest /dsgetdc:corp.test /force
```

`nltest` requests fresh domain controller discovery and reports the selected DC, its address, domain, forest, and site. In this lab the DC is `DC01.corp.test` at `10.10.10.10`.

LDAP service discovery record:

```powershell
Resolve-DnsName -Name '_ldap._tcp.dc._msdcs.corp.test' -Type SRV
```

The SRV record identifies `dc01.corp.test` on port `389`. Its A record supplies `10.10.10.10`.

## Domain join

Domain join requires local elevation and credentials authorized to create or reuse the computer account:

```powershell
Add-Computer -DomainName 'corp.test' `
    -Credential (Get-Credential 'CORP\Administrator') `
    -Restart
```

The recorded join used `CORP\Administrator`. Delegated computer-join accounts can provide the required domain permissions.

## Domain sign-in verification

Ali's first domain sign-in completed the required password change. Identity, group token, and membership were checked in the non-elevated user session:

```powershell
whoami

whoami /groups | Select-String 'GG_Engineering'

Get-CimInstance Win32_ComputerSystem |
    Select-Object Name, Domain, PartOfDomain
```

| Check | Verified value |
|---|---|
| User identity | `corp\ali` |
| Enabled group in logon token | `CORP\GG_Engineering` |
| Computer name | `CLIENT01` |
| Domain | `corp.test` |
| PartOfDomain | `True` |

Post-join placement: [computer account organization](../active-directory/computer-organization.md).

## Client provisioning automation

[Join-DomainComputer.ps1](../powershell/Join-DomainComputer.ps1) automates hostname, address, DNS, and domain membership configuration. Execution requires elevated Windows PowerShell on the target computer:

```powershell
.\powershell\Join-DomainComputer.ps1 `
    -ComputerName 'CLIENT02' `
    -IPAddress '10.10.10.21' `
    -DNSServer '10.10.10.10' `
    -DomainName 'corp.test' `
    -PrefixLength 24 `
    -InterfaceName 'Ethernet'
```

Deployment requires an available hostname and IP address. Re-execution after each restart advances the remaining stages. For existing members, the script performs DC discovery and secure-channel verification. User-session authentication and token checks are separate from machine membership.

References: [Add-Computer](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/add-computer?view=powershell-5.1), [domain controller discovery](https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/domain-joined-machines-cannot-detect-domain-profile).
