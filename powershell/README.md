# PowerShell Script'leri

| Script | İşlev | Zorunlu parametreler |
|---|---|---|
| [Deploy-DC01-NewForest.ps1](Deploy-DC01-NewForest.ps1) | DC01 yapılandırması ve ilk `corp.test` forest kurulumu | Yok; sabit proje yapılandırması |
| [Add-DomainController.ps1](Add-DomainController.ps1) | Mevcut domain'e ek domain controller kurulumu | `ServerName`, `IPAddress`, `DNSServer`, `DomainName` |
| [New-ADDepartmentUser.ps1](New-ADDepartmentUser.ps1) | Departman organizasyon birimi, güvenlik grubu ve kullanıcı oluşturma | `DomainName`, `OUName`, `GroupName`, `AccountName`, `DisplayName` |
| [Join-DomainComputer.ps1](Join-DomainComputer.ps1) | Bilgisayar ağ yapılandırması ve domain üyeliği | `ComputerName`, `IPAddress`, `DNSServer`, `DomainName` |
| [New-DepartmentShare.ps1](New-DepartmentShare.ps1) | NTFS klasör izinleri ve SMB paylaşımı | `RootPath`, `ShareName`, `AccessGroup` |
| [Get-DomainInventory.ps1](Get-DomainInventory.ps1) | AD bilgisayar sorgusu ve uzaktan sistem envanteri | Yok; mevcut domain'deki etkin bilgisayarlar |
| [Export-InventoryCsv.ps1](Export-InventoryCsv.ps1) | Envanter verilerini CSV'ye aktarma | Pipeline üzerinden `InputObject`, `Path` |
| [Get-DomainUserReport.ps1](Get-DomainUserReport.ps1) | Filtrelenebilir AD kullanıcı raporu | Yok; mevcut domain'deki tüm kullanıcılar |
| [Backup-SystemState.ps1](Backup-SystemState.ps1) | System State yedeği | `BackupTarget` |
| [Restore-BackupFiles.ps1](Restore-BackupFiles.ps1) | Farklı konuma dosya kurtarma | `BackupTarget`, `Version`, `SourcePath`, `RecoveryTarget` |
| [Enable-WinRMManagementPolicy.ps1](Enable-WinRMManagementPolicy.ps1) | Mevcut GPO'nun WinRM yapılandırması ve OU bağlantısı | `DomainName`, `GPOName`, `TargetOU`, `ManagementAddresses` |

## İlgili Belgeler

| Alan | Belge |
|---|---|
| Domain controller | [AD DS ve DNS](../active-directory/README.md) |
| Departman hesapları | [Engineering yapısı](../active-directory/engineering.md) |
| Domain üyeliği | [Client ağ yapılandırması ve domain üyeliği](../windows-networking/domain-join.md) |
| Dosya paylaşımı | [NTFS ve SMB yapılandırması](../file-sharing/README.md) |
| Bilgisayar raporu | [Envanter parametreleri ve CSV dışa aktarma](../docs/inventory.md) |
| Kullanıcı raporu | [Kullanıcı filtreleri ve CSV dışa aktarma](../docs/user-report.md) |
| Yedekleme ve kurtarma | [System State ve dosya kurtarma](../backup-recovery/README.md) |
| WinRM | [Uzaktan yönetim](../docs/remote-administration.md) |
