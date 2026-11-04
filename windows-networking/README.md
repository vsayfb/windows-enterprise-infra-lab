# DC01 Ağ Yapılandırması

DC01, izole `corp-lab` ağında statik IPv4 adresi kullanır. Client'lar AD DS ve DNS hizmetlerine bu adres üzerinden erişir. DNS ayarı DC01'in kendisini gösterir; default gateway yoktur.

| Ayar | Değer |
|---|---|
| Adaptör adı | `Ethernet` |
| IPv4 adresi | `10.10.10.10` |
| Prefix uzunluğu | `24` |
| DNS sunucusu | `10.10.10.10` |
| Default gateway | Yok |

## Ağ Adaptörü ve IP Bilgileri

```powershell
Get-NetAdapter
Get-NetIPConfiguration
```

## IPv4 ve DNS Ayarları

Komutlar, `Ethernet` adaptörünü yapılandırır ve yönetici yetkili Windows PowerShell oturumunda çalıştırılır. Statik IP ayarı, AD DS kurulumu öncesinde yapılır.

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.10.10.10 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.10.10.10
```

## IP Yapılandırması ve Host Bağlantısı

```powershell
Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4
Get-NetIPConfiguration -InterfaceAlias "Ethernet"
ping 10.10.10.1
```

`10.10.10.1`, Debian host'un bridge adresidir. DNS rolü, [domain controller kurulumu](../active-directory/README.md) sırasında yüklenir.
