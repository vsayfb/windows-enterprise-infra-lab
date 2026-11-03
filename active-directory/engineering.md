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

`GG_Engineering` uses Global scope: members are drawn from `corp.test`, including accounts in other OUs. The group name identifies its intended purpose; it does not enforce an OU-based membership rule.

## Provision an Engineering account

Run in Windows PowerShell on DC01 with an account authorized to create and manage AD users, groups, and OUs:

```powershell
.\powershell\New-ADDepartmentUser.ps1 `
    -DomainName 'corp.test' `
    -OUName 'Engineering' `
    -GroupName 'GG_Engineering' `
    -AccountName 'ali' `
    -DisplayName 'Ali'
```

The script creates the OU, security group, and Ali account when absent, prompts securely for a temporary password for a new or disabled account, and adds direct group membership. The password must satisfy the domain policy. A failed password reset stops execution before account activation.

To provision another Engineering account:

```powershell
.\powershell\New-ADDepartmentUser.ps1 `
    -DomainName 'corp.test' `
    -OUName 'Engineering' `
    -GroupName 'GG_Engineering' `
    -AccountName 'ayse' `
    -DisplayName 'Ayse'
```

Existing enabled accounts retain their passwords and password-change state. Accounts outside the Engineering OU and groups with a conflicting location or category are rejected.

## Verify the OU and group

```powershell
Get-ADOrganizationalUnit -Identity 'OU=Engineering,DC=corp,DC=test' `
    -Properties ProtectedFromAccidentalDeletion |
    Select-Object Name, DistinguishedName, ProtectedFromAccidentalDeletion

Get-ADGroup 'GG_Engineering' |
    Select-Object Name, GroupScope, GroupCategory, DistinguishedName
```

## Verify Ali's account and membership

```powershell
Get-ADUser 'ali' -Properties pwdLastSet |
    Select-Object Name, SamAccountName, UserPrincipalName, Enabled, DistinguishedName, pwdLastSet

Get-ADGroupMember 'GG_Engineering' |
    Select-Object Name, SamAccountName
```

`pwdLastSet` is `0` when a password change is required at next logon.
