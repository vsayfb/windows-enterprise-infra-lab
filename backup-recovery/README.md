# System State backup and file recovery

DC01 uses Windows Server Backup to store System State on a separate 30 GiB virtual disk, formatted as NTFS and mounted at `E:` with label `LabBackup`. The backup catalog includes AD (NTDS), SYSVOL, and Registry components.

## Create the backup

Run from the repository root in elevated Windows PowerShell on DC01:

```powershell
.\powershell\Backup-SystemState.ps1 -BackupTarget 'E:'
```

The script installs Windows Server Backup if needed, checks the target volume, starts the backup with an interactive confirmation, and lists catalog versions. It does not initialize or format disks.

The underlying backup command is:

```powershell
wbadmin start systemstatebackup -backupTarget:E:
```

## Inspect the catalog

```powershell
wbadmin get versions -backupTarget:E:

wbadmin get items -version:11/03/2026-16:11 -backupTarget:E:
```

Use the exact version identifier from the local catalog. `11/03/2026-16:11` identifies the backup used in the recovery test.

## Recover policy files to a separate folder

```powershell
.\powershell\Restore-BackupFiles.ps1 `
    -BackupTarget 'E:' `
    -Version '11/03/2026-16:11' `
    -MachineName 'DC01' `
    -SourcePath 'C:\Windows\SYSVOL\domain\Policies' `
    -RecoveryTarget 'C:\RestoreTest'
```

Select a new or empty destination for each run. The script inspects the catalog, requests confirmation, and performs recursive file recovery. The destination must be outside the source hierarchy and backup volume. Existing nonempty destinations and destination paths containing junctions or symbolic links are rejected.

Inspect recovered files:

```powershell
Get-ChildItem 'C:\RestoreTest' -Recurse -File |
    Select-Object FullName, Length

(Get-ChildItem 'C:\RestoreTest' -Recurse -File | Measure-Object).Count
```

## Validation

| Check | Result |
|---|---|
| System State backup to E: | Completed successfully |
| Catalog inspection | AD, SYSVOL, and Registry components listed |
| Policy folder recovery to C:\RestoreTest | 29 files recovered, zero failures |
| Restored file count on disk | 29 confirmed |

The test recovered files to an alternate directory. A full System State restore, AD database recovery, and complete domain controller recovery were not tested.

## Storage boundary

Separate virtual disks do not establish independent physical storage. If the VM disk and backup disk reside on the same host drive, failure of that drive can destroy both. This lab does not demonstrate off-site, offline, or immutable backup protection.

References: [System State backup](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wbadmin-start-systemstatebackup), [file recovery](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wbadmin-start-recovery).
