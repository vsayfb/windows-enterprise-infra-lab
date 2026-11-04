# Client Ağ Yapılandırması ve Domain Üyeliği

CLIENT01, DNS sorguları ve domain controller bağlantısı için DC01'i kullanır. Bilgisayar hesabı `corp.test` domain'ine üyedir. Kullanıcılar kendi domain hesaplarıyla oturum açar.

| Ayar | Değer |
|---|---|
| Bilgisayar adı | `CLIENT01` |
| IPv4 adresi | `10.10.10.20/24` |
| DNS sunucusu | `10.10.10.10` |
| Default gateway | Yok |
| Domain | `corp.test` |
| Test kullanıcısı | `CORP\ali` |

## IPv4 ve DNS Ayarları

Ağ yapılandırma komutları, yönetici yetkili Windows PowerShell oturumunda çalıştırılır.

```powershell
Get-NetAdapter
```

CLIENT01 üzerindeki adaptörün index değeri `3`'tür.

```powershell
New-NetIPAddress -InterfaceIndex 3 `
    -IPAddress '10.10.10.20' -PrefixLength 24

Set-DnsClientServerAddress -InterfaceIndex 3 `
    -ServerAddresses '10.10.10.10'
```

## Domain Controller ve LDAP SRV Kaydı

```powershell
Get-NetIPConfiguration -InterfaceIndex 3

ping 10.10.10.10

nltest /dsgetdc:corp.test /force
```

`nltest`, domain controller bilgisini yeniden sorgular; sunucu adı, IP adresi, domain, forest ve site bilgilerini döndürür. Bu ağda domain controller `DC01.corp.test`, IP adresi `10.10.10.10`'dur.

LDAP SRV kaydı:

```powershell
Resolve-DnsName -Name '_ldap._tcp.dc._msdcs.corp.test' -Type SRV
```

SRV kaydı, `dc01.corp.test` ve `389` portunu gösterir. A kaydındaki IP adresi `10.10.10.10`'dur.

## Client'ın Domain'e Eklenmesi

Komut, yerel yönetici yetkisi ve domain'de bilgisayar hesabı oluşturma veya mevcut hesabı kullanma yetkisi gerektirir.

```powershell
Add-Computer -DomainName 'corp.test' `
    -Credential (Get-Credential 'CORP\Administrator') `
    -Restart
```

Domain üyeliği komutu `CORP\Administrator` hesabını kullanır.

## Kullanıcı Kimliği ve Domain Üyeliği

Ali'nin ilk domain oturumunda parola değişikliği zorunludur. Kullanıcı kimliği, grup üyeliği ve bilgisayarın domain bilgisi için sorgular standart kullanıcı oturumunda çalıştırılır.

```powershell
whoami

whoami /groups | Select-String 'GG_Engineering'

Get-CimInstance Win32_ComputerSystem |
    Select-Object Name, Domain, PartOfDomain
```

| Kontrol | Değer |
|---|---|
| Kullanıcı kimliği | `corp\ali` |
| Oturum token'ındaki etkin grup | `CORP\GG_Engineering` |
| Bilgisayar adı | `CLIENT01` |
| Domain | `corp.test` |
| PartOfDomain | `True` |

[Bilgisayar hesabının bulunduğu OU](../active-directory/computer-organization.md)

## Script ile Client Yapılandırması

[Join-DomainComputer.ps1](../powershell/Join-DomainComputer.ps1), bilgisayar adı, IP adresi, DNS ve domain üyeliğini yapılandırır. Hedef bilgisayarda yönetici yetkili Windows PowerShell oturumu gereklidir.

```powershell
.\powershell\Join-DomainComputer.ps1 `
    -ComputerName 'CLIENT02' `
    -IPAddress '10.10.10.21' `
    -DNSServer '10.10.10.10' `
    -DomainName 'corp.test' `
    -PrefixLength 24 `
    -InterfaceName 'Ethernet'
```

Script, yeniden başlatma sonrasında tekrar çalıştırıldığında kalan aşamaları tamamlar. Domain'e zaten üye bilgisayarlarda domain controller bağlantısını ve secure channel durumunu kontrol eder.

Kaynaklar: [Add-Computer](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/add-computer?view=powershell-5.1), [domain controller sorgusu](https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/domain-joined-machines-cannot-detect-domain-profile).
