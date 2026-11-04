# Domain Kullanıcı Raporu

[Get-DomainUserReport.ps1](../powershell/Get-DomainUserReport.ps1), Active Directory kullanıcı hesaplarını sorgular. Sonuçlar ekranda görüntülenir veya CSV'ye aktarılır. Windows PowerShell, ActiveDirectory modülü ve dizin okuma yetkisi gereklidir.

## Kullanıcı Raporu ve Filtreler

Komutların çalışma dizini repository köküdür.

```powershell
.\powershell\Get-DomainUserReport.ps1

.\powershell\Get-DomainUserReport.ps1 -Enabled $true -OUName 'Engineering'

.\powershell\Get-DomainUserReport.ps1 -Department 'Engineering'

.\powershell\Get-DomainUserReport.ps1 -AccountName 'meh*'
```

| Parametre | İşlev |
|---|---|
| `DomainName` | Sorgulanacak domain; varsayılan değer mevcut domain |
| `Enabled` | Etkin hesaplar için `$true`, devre dışı hesaplar için `$false`; parametresiz kullanımda tümü |
| `OUName` | Alt OU'larla birlikte sorgulanacak OU adı; tek bir OU ile eşleşmelidir |
| `Department` | Kullanıcının Department alanıyla tam eşleşme |
| `AccountName` | SAM hesap adı filtresi; wildcard desteği |
| `SearchBase` | Alt nesneleriyle birlikte sorgulanacak distinguished name; `OUName` alternatifi |
| `Filter` | Gelişmiş `Get-ADUser` filtresi; varsayılan değer tüm kullanıcılar |

Rapor; hesap adı, hesap durumu, Department, UPN, distinguished name, parola değişiklik zamanı ve `LastLogonDate` bilgilerini içerir.

## Kullanıcı Raporunu CSV'ye Aktarma

```powershell
.\powershell\Get-DomainUserReport.ps1 |
    Export-Csv "$env:TEMP\users.csv" -NoTypeInformation -Encoding UTF8 -NoClobber

Import-Csv "$env:TEMP\users.csv" |
    Format-Table Name, SamAccountName, Department, Enabled
```

## Test Sonuçları

| Test | Sonuç |
|---|---|
| Mevcut domain sorgusu | Administrator, Ali, Guest, krbtgt ve Mehmet |
| Engineering OU içindeki etkin kullanıcılar | Yalnızca Ali |
| Devre dışı kullanıcılar | Guest ve krbtgt |
| Department değeri Engineering olan kullanıcılar | Yalnızca Ali |
| CSV dışa aktarma ve içe aktarma | Hesap durumu ve Department bilgileri korunuyor |
