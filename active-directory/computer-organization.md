# Computer account organization

The `PCs` OU contains workstation computer accounts and provides a target for computer-specific Group Policy links. The built-in `Computers` container accepts computer accounts but does not support direct GPO links; domain-linked policies can still apply to its contents.

| Computer | Directory location |
|---|---|
| CLIENT01 | `CN=CLIENT01,OU=PCs,DC=corp,DC=test` |
| DC01 | `CN=DC01,OU=Domain Controllers,DC=corp,DC=test` |

## PCs OU definition

OU administration is performed on DC01 in elevated Windows PowerShell.

```powershell
New-ADOrganizationalUnit `
    -Name 'PCs' `
    -Path 'DC=corp,DC=test' `
    -ProtectedFromAccidentalDeletion $true
```

## CLIENT01 placement

```powershell
$Client = Get-ADComputer -Identity 'CLIENT01'

Move-ADObject `
    -Identity $Client.DistinguishedName `
    -TargetPath 'OU=PCs,DC=corp,DC=test'
```

## Directory verification

```powershell
Get-ADComputer -Filter * |
    Select-Object Name, DistinguishedName
```

Verified directory locations are listed in the table above.
