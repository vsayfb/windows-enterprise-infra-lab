# Engineering accounts and security group

The Engineering OU contains department accounts and the `GG_Engineering` global security group. Group membership is assigned explicitly; storing an account in the OU does not grant membership or resource access.

```text
corp.test
└── Engineering
    ├── Ali (ali)
    └── GG_Engineering
        └── Member: ali
```

| Object | Distinguished name |
|---|---|
| Organizational unit | `OU=Engineering,DC=corp,DC=test` |
| User | `CN=Ali,OU=Engineering,DC=corp,DC=test` |
| Security group | `CN=GG_Engineering,OU=Engineering,DC=corp,DC=test` |

`GG_Engineering` is a Global security group used for Engineering resource permissions.

## Account provisioning

Provisioning requires the ActiveDirectory module and permissions to manage users, groups, and OUs in `corp.test`. The example uses the repository root as its working directory.

```powershell
.\powershell\New-ADDepartmentUser.ps1 `
    -DomainName 'corp.test' `
    -OUName 'Engineering' `
    -GroupName 'GG_Engineering' `
    -AccountName 'ali' `
    -DisplayName 'Ali'
```

The script creates missing objects, prompts for a temporary password for new or disabled accounts, and adds direct group membership. Accounts are enabled after a successful password reset.

Existing enabled accounts retain their passwords and password-change state. Accounts outside the Engineering OU and groups with a conflicting location or category are rejected.

## OU and group properties

```powershell
Get-ADOrganizationalUnit -Identity 'OU=Engineering,DC=corp,DC=test' `
    -Properties ProtectedFromAccidentalDeletion |
    Select-Object Name, DistinguishedName, ProtectedFromAccidentalDeletion

Get-ADGroup 'GG_Engineering' |
    Select-Object Name, GroupScope, GroupCategory, DistinguishedName
```

## Account and membership verification

```powershell
Get-ADUser 'ali' -Properties pwdLastSet |
    Select-Object Name, SamAccountName, UserPrincipalName, Enabled, DistinguishedName, pwdLastSet

Get-ADGroupMember 'GG_Engineering' |
    Select-Object Name, SamAccountName
```

`pwdLastSet` is `0` when a password change is required at next logon.
