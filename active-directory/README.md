# Domain Controller Kurulumu

DC01, `corp.test` forest'ının ilk domain controller'ıdır. AD DS ve DNS aynı sunucuda çalışır.

| Ayar | Değer |
|---|---|
| Domain controller | `DC01` |
| Forest root domain | `corp.test` |
| NetBIOS domain adı | `CORP` |
| IPv4 adresi | `10.10.10.10` |

[DC01](../virtualization/dc01.md), [statik IP ve DNS yapılandırmasıyla](../windows-networking/README.md) çalışır.

## AD DS Kurulumu

Komut, yönetici yetkili Windows PowerShell oturumunda çalıştırılır.

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

## Forest Kurulumu

```powershell
Install-ADDSForest `
    -DomainName "corp.test" `
    -DomainNetbiosName "CORP" `
    -InstallDns
```

`Install-ADDSForest`, DSRM kurtarma parolasını ister, DNS rolünü kurar ve sunucuyu yeniden başlatır. Domain yönetici hesabı `CORP\Administrator`'dır.

## DNS Üzerinden Domain Controller Sorgusu

```powershell
Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.corp.test" -Type SRV
```

LDAP SRV kaydı `dc01.corp.test` adresini gösterir. Sunucunun IPv4 adresi `10.10.10.10`'dur.

## AD DS ve SYSVOL Kontrolleri

```powershell
dcdiag /test:Advertising /test:SysVolCheck /test:NetLogons
```

| Test | Kapsam |
|---|---|
| Connectivity | DNS ve Active Directory bağlantısı |
| Advertising | Sunucunun domain controller olarak hizmet vermesi |
| SysVolCheck | SYSVOL durumu |
| NetLogons | SYSVOL ve NETLOGON paylaşımlarına erişim |

## Kullanıcılar ve Gruplar

- [Engineering kullanıcıları ve güvenlik grubu](engineering.md)

## Bilgisayar Hesapları

- [PCs organizasyon birimi ve bilgisayar hesapları](computer-organization.md)
