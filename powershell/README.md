# PowerShell scripts

## Initial domain controller

[Deploy-DC01-NewForest.ps1](Deploy-DC01-NewForest.ps1) configures the first domain controller with fixed lab settings:

| Setting | Value |
|---|---|
| Hostname | `DC01` |
| Network adapter | `Ethernet` |
| IPv4 address | `10.10.10.10/24` |
| DNS server | `10.10.10.10` |
| Default gateway | None |
| Forest and domain | `corp.test` |
| NetBIOS domain name | `CORP` |

Deployment requires a fresh Windows Server installation on `corp-lab` and elevated Windows PowerShell. Examples in this reference use `powershell/` as the working directory.

```powershell
.\Deploy-DC01-NewForest.ps1
```

The script advances through deployment stages across restarts. Completed stages are skipped on re-execution. Forest promotion prompts for a DSRM password and confirmation. After promotion, re-execution performs networking, DNS, and domain controller checks.

Password entry is interactive. Conflicting IPv4 configurations and unrelated domain memberships stop deployment.

## Additional domain controllers

[Add-DomainController.ps1](Add-DomainController.ps1) configures an additional writable domain controller and DNS server in an existing domain. The existing domain controller and its DNS service must be reachable. Use an unused hostname and IPv4 address on the isolated network.

Execution context: elevated Windows PowerShell on the new Windows Server VM.

```powershell
.\Add-DomainController.ps1 `
    -ServerName 'DC02' `
    -IPAddress '10.10.10.11' `
    -DNSServer '10.10.10.10' `
    -DomainName 'corp.test' `
    -PrefixLength 24 `
    -InterfaceName 'Ethernet'
```

| Parameter | Purpose |
|---|---|
| `ServerName` | New domain controller hostname |
| `IPAddress` | New domain controller IPv4 address |
| `DNSServer` | Existing domain DNS server IPv4 address |
| `DomainName` | Existing AD domain DNS name |
| `PrefixLength` | Subnet prefix length; default `24` |
| `InterfaceName` | Local network adapter alias; default `Ethernet` |

Promotion prompts for authorized domain credentials and a DSRM password, then restarts the server. Re-execution with the same parameters advances the deployment and performs DNS, DC service, and inbound replication checks after promotion.

The script targets an isolated network without a default gateway. Conflicting static addresses stop deployment. The post-promotion stage preserves DNS client settings and reports `dcdiag` and `repadmin` results.

Reference: [Install-ADDSDomainController](https://learn.microsoft.com/en-us/powershell/module/addsdeployment/install-addsdomaincontroller?view=windowsserver2025-ps).

## Department account provisioning

[New-ADDepartmentUser.ps1](New-ADDepartmentUser.ps1) creates a department OU, a global security group, and a user account with direct group membership.

Provisioning requires Windows PowerShell and permissions to manage users, groups, and OUs in the selected domain.

```powershell
.\New-ADDepartmentUser.ps1 `
    -DomainName 'corp.test' `
    -OUName 'Engineering' `
    -GroupName 'GG_Engineering' `
    -AccountName 'ali' `
    -DisplayName 'Ali'
```

| Parameter | Purpose |
|---|---|
| `DomainName` | Existing AD domain DNS name |
| `OUName` | Department OU name |
| `GroupName` | Global security group name and SAM account name |
| `AccountName` | User SAM account name; also used for the UPN prefix |
| `DisplayName` | User object name and display name |
| `ParentPath` | Existing parent OU distinguished name; defaults to the domain root |

Sales department example:

```powershell
.\New-ADDepartmentUser.ps1 `
    -DomainName 'corp.test' `
    -OUName 'Sales' `
    -GroupName 'GG_Sales' `
    -AccountName 'ayse' `
    -DisplayName 'Ayse'
```

`ParentPath` identifies an existing parent OU, such as `OU=Departments,DC=corp,DC=test`. The default parent is the domain root.

OU names support letters, digits, spaces, underscores, and hyphens. Group names support letters, digits, underscores, and hyphens. New or disabled accounts require a temporary password entered at a secure prompt. Existing enabled accounts retain their passwords and password-change state. Existing objects with conflicting locations or group settings are rejected.

Directory structure and verification: [Engineering accounts and security group](../active-directory/engineering.md).

## Computer domain join

[Join-DomainComputer.ps1](Join-DomainComputer.ps1) configures a hostname, static IPv4 address, and domain DNS server, discovers a DC, and joins an existing domain. Execution requires elevated Windows PowerShell on a Windows edition supporting AD domain membership.

```powershell
.\Join-DomainComputer.ps1 `
    -ComputerName 'CLIENT01' `
    -IPAddress '10.10.10.20' `
    -DNSServer '10.10.10.10' `
    -DomainName 'corp.test' `
    -PrefixLength 24 `
    -InterfaceName 'Ethernet'
```

| Parameter | Purpose |
|---|---|
| `ComputerName` | Target Windows hostname |
| `IPAddress` | Computer's static IPv4 address |
| `DNSServer` | AD DNS server IPv4 address |
| `DomainName` | Existing AD domain DNS name |
| `PrefixLength` | Subnet prefix length; default `24` |
| `InterfaceName` | Local adapter alias; default `Ethernet` |

Re-execution with the same parameters advances deployment after restarts. Domain credentials are requested interactively at the join stage.

The network configuration is intended for the isolated lab: no default gateway is configured, and conflicting static addresses are rejected. Computers in another domain and domain controllers are rejected. On a joined computer, the script preserves network settings, performs DC discovery, and tests the secure channel.

Configuration and authentication results: [client networking and domain join](../windows-networking/domain-join.md).

## Department share provisioning

[New-DepartmentShare.ps1](New-DepartmentShare.ps1) creates a protected parent folder and a department folder with inherited administrative permissions, then publishes an SMB share.

Execution context: elevated Windows PowerShell on the file server.

```powershell
.\New-DepartmentShare.ps1 `
    -RootPath 'C:\CorpShares' `
    -ShareName 'Engineering' `
    -AccessGroup 'CORP\GG_Engineering'
```

| Parameter | Purpose |
|---|---|
| `RootPath` | Dedicated local parent folder for department shares |
| `ShareName` | Department folder name and SMB share name |
| `AccessGroup` | Existing department security group in `DOMAIN\Name` form |

The script grants Administrators and SYSTEM inheritable NTFS Full Control at the parent. The department group receives NTFS Modify and SMB Change. Administrators receive SMB Full access.

Existing folders and shares are checked before configuration. Conflicting permissions, disabled inheritance on a department folder, or a share mapped to another path stop execution. Matching existing configuration can be reused. No files are deleted, and no credentials are stored.

Permission layout and access results: [Engineering file share](../file-sharing/README.md).

## Computer inventory and CSV export

[Get-DomainInventory.ps1](Get-DomainInventory.ps1) queries computer accounts in the current domain or a supplied domain, applies AD filters, and collects live inventory over WinRM. [Export-InventoryCsv.ps1](Export-InventoryCsv.ps1) exports those objects separately.

```powershell
$Inventory = .\Get-DomainInventory.ps1

$Inventory | Format-Table ComputerName, OS, RAM_GB, Status, Error

$Inventory | .\Export-InventoryCsv.ps1 -Path "$env:TEMP\inventory.csv"
```

`DomainName`, `Filter`, and `SearchBase` control computer selection. The exporter requires `-Overwrite` to replace an existing CSV. Parameters and validation: [domain computer inventory](../docs/inventory.md).

## Domain user reporting

[Get-DomainUserReport.ps1](Get-DomainUserReport.ps1) returns user account objects from Active Directory with filters for enabled status, OU, Department, and account name:

```powershell
.\Get-DomainUserReport.ps1 -Enabled $true -OUName 'Engineering'

.\Get-DomainUserReport.ps1 -Department 'Engineering'
```

The returned objects support `Export-Csv`. Parameters and validation: [domain user report](../docs/user-report.md).

## System State backup

[Backup-SystemState.ps1](Backup-SystemState.ps1) installs Windows Server Backup if needed and creates a System State backup on an existing local NTFS volume. Execution requires elevated Windows PowerShell:

```powershell
.\Backup-SystemState.ps1 -BackupTarget 'E:'
```

The script retains the backup confirmation prompt and lists catalog versions after completion. It does not partition or format the target disk.

## File recovery

[Restore-BackupFiles.ps1](Restore-BackupFiles.ps1) restores a file or folder recursively to a separate directory:

```powershell
.\Restore-BackupFiles.ps1 `
    -BackupTarget 'E:' `
    -Version '11/03/2026-16:11' `
    -MachineName 'DC01' `
    -SourcePath 'C:\Windows\SYSVOL\domain\Policies' `
    -RecoveryTarget 'C:\RestoreTest'
```

`Version` identifies a backup catalog entry from `wbadmin get versions`. `MachineName` defaults to the current computer. Recovery requires an empty or new destination outside the source hierarchy and backup volume. Confirmation is interactive; the output includes restored file paths and a count. Recovery scope is files and folders.

Catalog checks, results, and storage scope: [System State backup and file recovery](../backup-recovery/README.md).
