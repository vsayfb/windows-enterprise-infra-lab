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

## Configure IPv4 and DNS

Run Windows PowerShell as Administrator on CLIENT01. Identify the interface index before configuring the adapter:

```powershell
Get-NetAdapter
```

For interface index `3`:

```powershell
New-NetIPAddress -InterfaceIndex 3 `
    -IPAddress '10.10.10.20' -PrefixLength 24

Set-DnsClientServerAddress -InterfaceIndex 3 `
    -ServerAddresses '10.10.10.10'
```

## Discover the domain controller

```powershell
Get-NetIPConfiguration -InterfaceIndex 3

ping 10.10.10.10

nltest /dsgetdc:corp.test /force
```

`nltest` requests fresh domain controller discovery and reports the selected DC, its address, domain, forest, and site. In this lab the DC is `DC01.corp.test` at `10.10.10.10`.

To inspect the underlying DNS service record:

```powershell
Resolve-DnsName -Name '_ldap._tcp.dc._msdcs.corp.test' -Type SRV
```

The SRV record identifies `dc01.corp.test` on port `389`. Its A record supplies `10.10.10.10`.

## Join the domain

Run in an elevated Windows PowerShell session. Local elevation and authorized domain credentials are both required:

```powershell
Add-Computer -DomainName 'corp.test' `
    -Credential (Get-Credential 'CORP\Administrator') `
    -Restart
```

The lab uses `CORP\Administrator`. For delegated administration, supply an account authorized to join computers to the domain.

## Verify domain sign-in

After restarting, select **Other user** and sign in as `CORP\ali`. Change the temporary password when prompted.

Run in Ali's normal, non-elevated PowerShell session:

```powershell
whoami

whoami /groups | Select-String 'GG_Engineering'

Get-CimInstance Win32_ComputerSystem |
    Select-Object Name, Domain, PartOfDomain
```

The domain sign-in was verified as `corp\ali`, with `CORP\GG_Engineering` enabled in the logon token. The computer reported `Name: CLIENT01`, `Domain: corp.test`, and `PartOfDomain: True`.

## Automate another client

Run [Join-DomainComputer.ps1](../powershell/Join-DomainComputer.ps1) locally on the target computer in elevated Windows PowerShell:

```powershell
.\powershell\Join-DomainComputer.ps1 `
    -ComputerName 'CLIENT02' `
    -IPAddress '10.10.10.21' `
    -DNSServer '10.10.10.10' `
    -DomainName 'corp.test' `
    -PrefixLength 24 `
    -InterfaceName 'Ethernet'
```

Use an unused hostname and address. Run the same command after each restart. After joining, the script performs DC discovery and tests the computer's secure channel without attempting another join. Verify the intended user's sign-in and group token separately in that user's session.

References: [Add-Computer](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/add-computer?view=powershell-5.1), [domain controller discovery](https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/domain-joined-machines-cannot-detect-domain-profile).
