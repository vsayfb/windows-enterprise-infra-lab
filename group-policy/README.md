# Engineering Kullanıcı Policy'si

`Engineering-User-Policy` GPO'su, Engineering organizasyon birimine (`OU=Engineering,DC=corp,DC=test`) bağlıdır. Kullanıcı ayarlarının kapsamı, hesabın bulunduğu OU ve GPO filtrelerine bağlıdır.

## GPO Oluşturma ve OU'ya Bağlama

Komutlar, DC01 üzerinde yönetici yetkili Windows PowerShell oturumunda çalıştırılır.

```powershell
New-GPO -Name 'Engineering-User-Policy'

New-GPLink `
    -Name 'Engineering-User-Policy' `
    -Target 'OU=Engineering,DC=corp,DC=test'
```

## Settings ve Control Panel Kısıtlaması

`Engineering-User-Policy` içindeki Administrative Template ayarı:

| Ayar | Değer |
|---|---|
| Policy yolu | User Configuration → Policies → Administrative Templates → Control Panel |
| Kısıtlama | Prohibit access to Control Panel and PC settings |
| Test durumu | Enabled |
| Mevcut durum | Not Configured |

## Policy Yenileme ve Uygulanan GPO Listesi

Komutlar, CLIENT01 üzerinde Ali'nin standart kullanıcı oturumunda çalıştırılır.

```powershell
gpupdate /target:user /force

gpresult /scope user /r
```

`gpresult` çıktısındaki **Applied Group Policy Objects** listesinde `Engineering-User-Policy` bulunur.

## Mevcut Kısıtlama Ayarı

Kısıtlama **Not Configured** durumundadır; Settings ve Control Panel erişimi açıktır. GPO, Engineering organizasyon birimine bağlıdır.

## Test Sonuçları

| Test | Sonuç |
|---|---|
| Kısıtlama etkinken Settings ve Control Panel | Ali için erişim yok |
| Ali'nin oturumunda `gpresult` | `Engineering-User-Policy` uygulanmış GPO listesinde |
| Kısıtlama kapalıyken policy yenilemesi sonrası Settings ve Control Panel | Erişim var |
