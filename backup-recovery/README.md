# System State Yedeği ve Dosya Kurtarma

DC01, System State yedeğini Windows Server Backup ile ayrı bir 30 GiB sanal diskte tutar. Disk NTFS formatındadır; sürücü harfi `E:`, etiketi `LabBackup`'tır. Yedek kataloğu AD (NTDS), SYSVOL ve Registry bileşenlerini içerir.

## System State Yedekleme

Komut, DC01 üzerinde yönetici yetkili Windows PowerShell oturumunda çalıştırılır. Çalışma dizini repository köküdür.

```powershell
.\powershell\Backup-SystemState.ps1 -BackupTarget 'E:'
```

Script, gerektiğinde Windows Server Backup bileşenini kurar, hedef diski kontrol eder ve onay sonrasında yedeklemeyi başlatır. İşlem sonunda yedek sürümlerini listeler.

## Yedek Kataloğu

```powershell
wbadmin get versions -backupTarget:E:

wbadmin get items -version:11/03/2026-16:11 -backupTarget:E:
```

Kurtarma için kullanılan yedek sürümü `11/03/2026-16:11`'dir.

## Farklı Konuma Dosya Kurtarma

```powershell
.\powershell\Restore-BackupFiles.ps1 `
    -BackupTarget 'E:' `
    -Version '11/03/2026-16:11' `
    -MachineName 'DC01' `
    -SourcePath 'C:\Windows\SYSVOL\domain\Policies' `
    -RecoveryTarget 'C:\RestoreTest'
```

Kurtarma hedefi, kaynak dizinin ve yedek diskin dışında, yeni veya boş bir dizindir. Script, kataloğu kontrol eder ve onay sonrasında alt dizinlerle birlikte dosyaları kurtarır.

Kurtarılan dosyaların listesi ve sayısı:

```powershell
Get-ChildItem 'C:\RestoreTest' -Recurse -File |
    Select-Object FullName, Length

(Get-ChildItem 'C:\RestoreTest' -Recurse -File | Measure-Object).Count
```

## Test Sonuçları

| Test | Sonuç |
|---|---|
| E: üzerinde System State yedeği | Başarılı |
| Katalog içeriği | AD, SYSVOL ve Registry bileşenleri mevcut |
| C:\RestoreTest konumuna policy dosyası kurtarma | Başarılı; 29 dosya |

## Yedek Depolama

Yedek diski ve VM diski aynı fiziksel makinededir.

Ayrı bir fiziksel cihazda, farklı bir lokasyonda veya çevrimdışı tutulan yedekler veri kaybına karşı korumayı artırır; bu projede tüm sistem aynı bilgisayarda çalışır.

Kaynaklar: [System State yedekleme](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wbadmin-start-systemstatebackup), [dosya kurtarma](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wbadmin-start-recovery).
