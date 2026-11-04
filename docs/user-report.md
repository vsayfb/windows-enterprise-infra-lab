# Domain user report

[Get-DomainUserReport.ps1](../powershell/Get-DomainUserReport.ps1) queries Active Directory and returns user account objects for display or CSV export. Execution requires Windows PowerShell, the ActiveDirectory module, and directory read permissions.

## User selection

Examples, relative to the repository root:

```powershell
.\powershell\Get-DomainUserReport.ps1

.\powershell\Get-DomainUserReport.ps1 -Enabled $true -OUName 'Engineering'

.\powershell\Get-DomainUserReport.ps1 -Department 'Engineering'

.\powershell\Get-DomainUserReport.ps1 -AccountName 'meh*'
```

| Parameter | Purpose |
|---|---|
| `DomainName` | Domain to query; defaults to the current domain |
| `Enabled` | `$true` for enabled accounts; `$false` for disabled accounts; omitted for both |
| `OUName` | OU name, searched with its descendants; must resolve to exactly one OU |
| `Department` | Exact match against the user's Department profile field |
| `AccountName` | SAM account name pattern; supports wildcards |
| `SearchBase` | Exact parent distinguished name, including descendants; alternative to `OUName` |
| `Filter` | Advanced `Get-ADUser` filter; defaults to all users |

The output includes account name, enabled status, Department, UPN, distinguished name, password modification time, and `LastLogonDate`.

## CSV export

```powershell
.\powershell\Get-DomainUserReport.ps1 |
    Export-Csv "$env:TEMP\users.csv" -NoTypeInformation -Encoding UTF8 -NoClobber

Import-Csv "$env:TEMP\users.csv" |
    Format-Table Name, SamAccountName, Department, Enabled
```

## Validation

| Test | Result |
|---|---|
| Current-domain query | Administrator, Ali, Guest, krbtgt, and Mehmet returned |
| Enabled users in Engineering OU | Ali only |
| Disabled users | Guest and krbtgt |
| Department set to Engineering | Ali only |
| CSV export and reimport | Account status and Department values retained |
