# WinRM management

`PCs-WinRM` is linked to `OU=PCs,DC=corp,DC=test`.

| Setting | Configuration |
|---|---|
| Service startup | Automatic |
| IPv4 listener filter | `*` |
| IPv6 listener filter | Empty |
| Firewall profile | Domain |
| Protocol and port | TCP 5985 |
| Allowed management address | `10.10.10.10` |
| Standard local WinRM HTTP rules | Disabled |

## Automation

[Enable-WinRMManagementPolicy.ps1](../powershell/Enable-WinRMManagementPolicy.ps1) configures an existing GPO and links it to an existing OU. All four parameters are required; `ManagementAddresses` replaces the managed rule's source address list.

```powershell
.\powershell\Enable-WinRMManagementPolicy.ps1 `
    -DomainName 'corp.test' `
    -GPOName 'PCs-WinRM' `
    -TargetOU 'OU=PCs,DC=corp,DC=test' `
    -ManagementAddresses '10.10.10.10'
```

## Verification

| Check on CLIENT01 | Result |
|---|---|
| Applied computer GPO | `PCs-WinRM` |
| WinRM service | Running, Automatic |
| Listener | GPO-managed, `10.10.10.20:5985` |
| Managed firewall rule source | `10.10.10.10` |
| Authenticated execution from DC01 after local-rule removal | Succeeded |
