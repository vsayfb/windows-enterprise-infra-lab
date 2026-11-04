# Güvenlik Kontrolleri

DC01 ve CLIENT01 üzerindeki firewall, Defender, yerel hesap ve güncelleme bilgileri:

| Kontrol | Durum |
|---|---|
| DC01 ve CLIENT01 firewall profilleri | Domain, Private ve Public etkin |
| Varsayılan firewall işlemleri | Gelen trafik Block, giden trafik Allow |
| Defender servisi, antivirüs ve gerçek zamanlı koruma | Her iki bilgisayarda etkin |
| Defender imza tarihi | Her iki bilgisayarda 16 Eylül 2025 |
| DC01 güncelleme listesi: son kurulum tarihi | 14 Ocak 2026 |
| CLIENT01 güncelleme listesi: son kurulum tarihi | 13 Eylül 2026 |

## Firewall, Defender ve Güncelleme Sorguları

Komutlar, DC01 üzerinde yetkili bir yönetici oturumunda çalıştırılır.

```powershell
Invoke-Command -ComputerName DC01, CLIENT01 -ScriptBlock {
    Get-NetFirewallProfile -PolicyStore ActiveStore |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction

    Get-MpComputerStatus |
        Select-Object AMServiceEnabled, AntivirusEnabled,
            RealTimeProtectionEnabled, AntivirusSignatureLastUpdated

    Get-HotFix |
        Sort-Object InstalledOn -Descending |
        Select-Object -First 5 HotFixID, Description, InstalledOn
}
```

## CLIENT01 Yerel Hesapları ve Administrators Grubu

| Üye | Tür | Durum |
|---|---|---|
| `CLIENT01\Administrator` | Yerel kullanıcı | Devre dışı |
| `CLIENT01\CLIENT01` | Yerel kullanıcı | Etkin |
| `CORP\Domain Admins` | Domain grubu | Yerel Administrators grubuna üye |

```powershell
Invoke-Command -ComputerName CLIENT01 -ScriptBlock {
    Get-LocalGroupMember -SID 'S-1-5-32-544' |
        Select-Object Name, ObjectClass, PrincipalSource

    Get-LocalUser |
        Select-Object Name, Enabled, LastLogon
}
```

## WinRM Erişimi

`PCs-WinRM` GPO yapılandırması:

| Ayar | Değer |
|---|---|
| WinRM başlangıç türü | Automatic |
| Listener | HTTP, TCP 5985 |
| Firewall profili | Domain |
| İzin verilen kaynak adres | `10.10.10.10` |

| Erişim kontrolü | Sonuç |
|---|---|
| Standart yerel `WINRM-HTTP-In-TCP*` kuralları | Devre dışı |
| DC01 üzerinden kimlik doğrulamalı komut | Başarılı |
