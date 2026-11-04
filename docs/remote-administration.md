# WinRM Yönetimi

`PCs-WinRM` GPO'su, PCs organizasyon birimine (`OU=PCs,DC=corp,DC=test`) bağlıdır.

| Ayar | Yapılandırma |
|---|---|
| Servis başlangıç türü | Automatic |
| IPv4 listener filtresi | `*` |
| IPv6 listener filtresi | Boş |
| Firewall profili | Domain |
| Protokol ve port | TCP 5985 |
| İzin verilen yönetim adresi | `10.10.10.10` |
| Standart yerel WinRM HTTP kuralları | Devre dışı |

## Script ile WinRM Policy Yapılandırması

[Enable-WinRMManagementPolicy.ps1](../powershell/Enable-WinRMManagementPolicy.ps1), mevcut bir GPO'nun WinRM ayarlarını yapılandırır ve GPO'yu mevcut bir OU'ya bağlar. `ManagementAddresses`, firewall kuralında izin verilen kaynak adresleri belirler; her çalıştırmada önceki listenin yerini alır.

```powershell
.\powershell\Enable-WinRMManagementPolicy.ps1 `
    -DomainName 'corp.test' `
    -GPOName 'PCs-WinRM' `
    -TargetOU 'OU=PCs,DC=corp,DC=test' `
    -ManagementAddresses '10.10.10.10'
```

## Test Sonuçları

| CLIENT01 kontrolü | Sonuç |
|---|---|
| Uygulanan bilgisayar GPO'su | `PCs-WinRM` |
| WinRM servisi | Running, Automatic |
| GPO tarafından yönetilen listener | `10.10.10.20:5985` |
| Firewall kuralının kaynak adresi | `10.10.10.10` |
| Yerel kurallar kapalıyken DC01 üzerinden kimlik doğrulamalı komut çalıştırma | Başarılı |
