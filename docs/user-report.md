# Domain user report

[Get-DomainUserReport.ps1](../powershell/Get-DomainUserReport.ps1) queries Active Directory and returns user account objects for display or CSV export. Run in Windows PowerShell with the ActiveDirectory module and directory read permissions. WinRM is not required.

## Collect and filter users

Run from the repository root:

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

Combined parameters narrow the results together. OU location and the Department profile field are independent: moving an account does not populate its Department field. Ali's Department is configured as `Engineering`.

The output includes account name, enabled status, Department, UPN, distinguished name, password modification time, and `LastLogonDate`. The last-logon value is replicated and approximate; it is not an exact authentication audit.

## Export and inspect CSV

```powershell
.\powershell\Get-DomainUserReport.ps1 |
    Export-Csv "$env:TEMP\users.csv" -NoTypeInformation -Encoding UTF8 -NoClobber

Import-Csv "$env:TEMP\users.csv" |
    Format-Table Name, SamAccountName, Department, Enabled
```

Pipe report objects directly to `Export-Csv`. Use `Format-Table` only for display. `-NoClobber` prevents replacing an existing file.

## Validation

| Test | Result |
|---|---|
| Current-domain query | Administrator, Ali, Guest, krbtgt, and Mehmet returned |
| Enabled users in Engineering OU | Ali only |
| Disabled users | Guest and krbtgt |
| Department set to Engineering | Ali only |
| CSV export and reimport | Account status and Department values retained |
