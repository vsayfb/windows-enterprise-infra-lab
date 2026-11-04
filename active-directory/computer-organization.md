# Bilgisayar Hesaplarının OU Yapısı

PCs organizasyon birimi (OU), client bilgisayar hesaplarını içerir. Bilgisayarlara yönelik GPO'lar bu OU'ya bağlanır. Varsayılan `Computers` container'ına doğrudan GPO bağlanamaz; domain'e bağlı GPO'lar buradaki bilgisayarlara da uygulanabilir.

| Bilgisayar | Active Directory yolu |
|---|---|
| CLIENT01 | `CN=CLIENT01,OU=PCs,DC=corp,DC=test` |
| DC01 | `CN=DC01,OU=Domain Controllers,DC=corp,DC=test` |

## PCs Organizasyon Birimi

Komutlar, DC01 üzerinde yönetici yetkili Windows PowerShell oturumunda çalıştırılır.

```powershell
New-ADOrganizationalUnit `
    -Name 'PCs' `
    -Path 'DC=corp,DC=test' `
    -ProtectedFromAccidentalDeletion $true
```

## CLIENT01 Hesabının PCs OU'ya Taşınması

CLIENT01'in PCs organizasyon biriminde bulunması, WinRM ayarlarının `PCs-WinRM` GPO'suyla merkezi olarak yönetilmesini sağlar.

```powershell
$Client = Get-ADComputer -Identity 'CLIENT01'

Move-ADObject `
    -Identity $Client.DistinguishedName `
    -TargetPath 'OU=PCs,DC=corp,DC=test'
```

## Bilgisayar Hesaplarının OU Bilgileri

```powershell
Get-ADComputer -Filter * |
    Select-Object Name, DistinguishedName
```
