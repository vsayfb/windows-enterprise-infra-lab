# Domain controller deployment

DC01 is the first domain controller in the `corp.test` forest. Active Directory Domain Services and DNS are hosted on the same server.

| Setting | Value |
|---|---|
| Domain controller | `DC01` |
| Forest root domain | `corp.test` |
| NetBIOS domain name | `CORP` |
| IPv4 address | `10.10.10.10` |

Configure the [hostname](../virtualization/dc01.md) and [static IP address](../windows-networking/README.md) before promotion.

## Install AD DS

Run PowerShell as Administrator:

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

## Create the forest

```powershell
Install-ADDSForest `
    -DomainName "corp.test" `
    -DomainNetbiosName "CORP" `
    -InstallDns
```

Enter and confirm a Directory Services Restore Mode (DSRM) password at the prompt. Store the password securely outside the repository. Confirm promotion and allow the server to restart.

Sign in as `CORP\Administrator` after restarting.

## Inspect Active Directory and DNS

Open **Server Manager → Tools → Active Directory Users and Computers**. Expand **corp.test → Domain Controllers** to locate `DC01`.

Open **Server Manager → Tools → DNS**. Expand **DC01 → Forward Lookup Zones** to inspect the AD-integrated zones `corp.test` and `_msdcs.corp.test`.

## Verify DNS discovery

```powershell
Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.corp.test" -Type SRV
```

The LDAP service record identifies `dc01.corp.test`; the corresponding IPv4 address is `10.10.10.10`.

## Verify domain controller services

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
