# Domain user report

[Get-DomainUserReport.ps1](../powershell/Get-DomainUserReport.ps1) queries Active Directory and returns user account objects for display or CSV export. Execution requires Windows PowerShell, the ActiveDirectory module, and directory read permissions. Queries are sent to AD rather than individual computers.

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

Filters are combined with AND. `OUName` selects directory location; `Department` matches the profile attribute. Ali's Department value is `Engineering`.

The output includes account name, enabled status, Department, UPN, distinguished name, password modification time, and `LastLogonDate`. The last-logon value is replicated and approximate; it is not an exact authentication audit.

## CSV export

```powershell
.\powershell\Get-DomainUserReport.ps1 |
    Export-Csv "$env:TEMP\users.csv" -NoTypeInformation -Encoding UTF8 -NoClobber

Import-Csv "$env:TEMP\users.csv" |
    Format-Table Name, SamAccountName, Department, Enabled
```

`Export-Csv` consumes report objects directly. `Format-Table` produces display data rather than exportable report records. `-NoClobber` prevents replacing an existing file.

## Validation

| Test | Result |
|---|---|
| Current-domain query | Administrator, Ali, Guest, krbtgt, and Mehmet returned |
| Enabled users in Engineering OU | Ali only |
| Disabled users | Guest and krbtgt |
| Department set to Engineering | Ali only |
| CSV export and reimport | Account status and Department values retained |
