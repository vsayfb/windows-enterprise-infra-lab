# PowerShell scripts

| Script | Purpose | Required parameters |
|---|---|---|
| [Deploy-DC01-NewForest.ps1](Deploy-DC01-NewForest.ps1) | DC01 configuration and initial `corp.test` forest deployment | None; fixed lab configuration |
| [Add-DomainController.ps1](Add-DomainController.ps1) | Additional DC deployment in an existing domain | `ServerName`, `IPAddress`, `DNSServer`, `DomainName` |
| [New-ADDepartmentUser.ps1](New-ADDepartmentUser.ps1) | Department OU, security group, and user provisioning | `DomainName`, `OUName`, `GroupName`, `AccountName`, `DisplayName` |
| [Join-DomainComputer.ps1](Join-DomainComputer.ps1) | Computer network configuration and domain join | `ComputerName`, `IPAddress`, `DNSServer`, `DomainName` |
| [New-DepartmentShare.ps1](New-DepartmentShare.ps1) | NTFS folder permissions and SMB share provisioning | `RootPath`, `ShareName`, `AccessGroup` |
| [Get-DomainInventory.ps1](Get-DomainInventory.ps1) | AD computer discovery and remote system inventory | None; current domain, enabled computers |
| [Export-InventoryCsv.ps1](Export-InventoryCsv.ps1) | Inventory object export | `InputObject` through the pipeline, `Path` |
| [Get-DomainUserReport.ps1](Get-DomainUserReport.ps1) | Filtered AD user reporting | None; all users in the current domain |
| [Backup-SystemState.ps1](Backup-SystemState.ps1) | System State backup | `BackupTarget` |
| [Restore-BackupFiles.ps1](Restore-BackupFiles.ps1) | Alternate-location file recovery | `BackupTarget`, `Version`, `SourcePath`, `RecoveryTarget` |
| [Enable-WinRMManagementPolicy.ps1](Enable-WinRMManagementPolicy.ps1) | WinRM configuration and OU linking for an existing GPO | `DomainName`, `GPOName`, `TargetOU`, `ManagementAddresses` |

## Configuration references

| Area | Reference |
|---|---|
| Domain controller | [AD DS and DNS](../active-directory/README.md) |
| Department accounts | [Engineering directory structure](../active-directory/engineering.md) |
| Domain membership | [Client networking and domain join](../windows-networking/domain-join.md) |
| File services | [NTFS and SMB configuration](../file-sharing/README.md) |
| Computer reporting | [Inventory parameters and CSV export](../docs/inventory.md) |
| User reporting | [User filters and CSV export](../docs/user-report.md) |
| Backup and recovery | [System State and file recovery](../backup-recovery/README.md) |
| WinRM | [Remote administration](../docs/remote-administration.md) |
