# Domain controller deployment

DC01 is the first domain controller in the `corp.test` forest. Active Directory Domain Services and DNS are hosted on the same server.

| Setting | Value |
|---|---|
| Domain controller | `DC01` |
| Forest root domain | `corp.test` |
| NetBIOS domain name | `CORP` |
| IPv4 address | `10.10.10.10` |

Promotion requires the [DC01 hostname](../virtualization/dc01.md) and [static IP configuration](../windows-networking/README.md).

## AD DS installation

AD DS installation requires elevated Windows PowerShell.

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

## Forest creation

```powershell
Install-ADDSForest `
    -DomainName "corp.test" `
    -DomainNetbiosName "CORP" `
    -InstallDns
```

Forest promotion prompts for a DSRM recovery password, installs DNS, and restarts the server. The domain administrator account is `CORP\Administrator`.

## DNS discovery

```powershell
Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.corp.test" -Type SRV
```

The LDAP service record identifies `dc01.corp.test`; the corresponding IPv4 address is `10.10.10.10`.

## Domain controller diagnostics

```powershell
dcdiag /test:Advertising /test:SysVolCheck /test:NetLogons
```

| Test | Scope |
|---|---|
| Connectivity | Preliminary DNS and directory connectivity checks |
| Advertising | Domain controller service advertisement |
| SysVolCheck | SYSVOL readiness |
| NetLogons | Access to SYSVOL and NETLOGON shares |

## Accounts and groups

- [Engineering accounts and security group](engineering.md)

## Computer accounts

- [PCs OU and computer placement](computer-organization.md)
