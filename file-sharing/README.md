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

## Share provisioning

[New-DepartmentShare.ps1](../powershell/New-DepartmentShare.ps1) provisions the share using an existing security group. Execution requires elevated Windows PowerShell on DC01; the example is relative to the repository root:

```powershell
.\powershell\New-DepartmentShare.ps1 `
    -RootPath 'C:\CorpShares' `
    -ShareName 'Engineering' `
    -AccessGroup 'CORP\GG_Engineering'
```

The script creates missing folders and publishes `\\DC01\Engineering`. Existing folders must have compatible permissions; conflicting ACLs or a share mapped to another path stop execution. Network operations must be allowed by both NTFS and SMB permissions.

## Access validation

Access tests used separate CLIENT01 sign-in sessions for `CORP\ali` and `CORP\mehmet`, without alternate SMB credentials. Ali created, edited, saved, reopened, and deleted `ali-test.txt` through `\\DC01\Engineering`. Mehmet's access to the same path was denied.

| Account | Engineering group membership | Result |
|---|---|---|
| `CORP\ali` | Member | Create, edit, read, and delete succeeded |
| `CORP\mehmet` | Not a member | Access denied |
