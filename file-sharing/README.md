# Engineering file share

The Engineering share provides network access to `C:\CorpShares\Engineering` on DC01. Access is controlled by both the NTFS folder ACL and the SMB share ACL.

| Principal | NTFS permissions | SMB permissions |
|---|---|---|
| `BUILTIN\Administrators` | Full Control | Full |
| `NT AUTHORITY\SYSTEM` | Full Control | No separate share grant |
| `CORP\GG_Engineering` | Modify | Change |

## Permission layout

```text
C:\CorpShares
│   Administrators: Full Control, inherited by children
│   SYSTEM: Full Control, inherited by children
│   Inheritance from C:\ disabled
│
└── Engineering
    Administrators: Full Control, inherited
    SYSTEM: Full Control, inherited
    GG_Engineering: Modify, explicit and inherited by children
```

The parent establishes administrative access for department folders. Department folders retain inheritance and add their own security group. Broad Users permissions inherited from the drive root are excluded at `CorpShares`.

## Configure the share

Run [New-DepartmentShare.ps1](../powershell/New-DepartmentShare.ps1) from the repository root in elevated Windows PowerShell on DC01. The security group must already exist:

```powershell
.\powershell\New-DepartmentShare.ps1 `
    -RootPath 'C:\CorpShares' `
    -ShareName 'Engineering' `
    -AccessGroup 'CORP\GG_Engineering'
```

The script creates missing folders and publishes `\\DC01\Engineering`. Existing folders must have compatible permissions; conflicting ACLs or a share mapped to another path stop execution. Network operations must be allowed by both NTFS and SMB permissions.

## Test user access

On CLIENT01, sign in as `CORP\ali` and open `\\DC01\Engineering`. Create `ali-test.txt`, edit and save it, close and reopen it, then delete it.

Sign out and sign in as `CORP\mehmet`. Open the same UNC path. Do not supply alternate credentials if prompted.

| Account | Engineering group membership | Result |
|---|---|---|
| `CORP\ali` | Member | Create, edit, read, and delete succeeded |
| `CORP\mehmet` | Not a member | Access denied |
