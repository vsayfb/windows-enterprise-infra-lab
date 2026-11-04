# Engineering Dosya Paylaşımı

Engineering paylaşımı, DC01 üzerindeki `C:\CorpShares\Engineering` klasörüne ağ üzerinden erişim sağlar. Erişim, NTFS klasör izinleri ve SMB paylaşım izinleriyle belirlenir.

| Hesap veya grup | NTFS izni | SMB izni |
|---|---|---|
| `BUILTIN\Administrators` | Full Control | Full |
| `NT AUTHORITY\SYSTEM` | Full Control | Ayrı paylaşım izni yok |
| `CORP\GG_Engineering` | Modify | Change |

## NTFS İzinleri ve Klasör Hiyerarşisi

```text
C:\CorpShares
│   Administrators: Full Control, inherited by children
│   SYSTEM: Full Control, inherited by children
│   Inheritance from C:\ disabled
│
└── Engineering
    Administrators: Full Control, inherited
    SYSTEM: Full Control, inherited
    GG_Engineering: Modify, explicit and inherited by children
```

`CorpShares`, departman klasörleri için yönetici ve SYSTEM izinlerini sağlar. Departman klasörleri bu izinleri devralır; her klasörde ilgili güvenlik grubunun erişim izni bulunur. `CorpShares`, disk kökündeki Users izinlerini devralmaz.

## Paylaşım Yapılandırması

[New-DepartmentShare.ps1](../powershell/New-DepartmentShare.ps1), mevcut bir güvenlik grubu için klasör ve paylaşım izinlerini yapılandırır. Komut, DC01 üzerinde yönetici yetkili Windows PowerShell oturumunda çalıştırılır. Çalışma dizini repository köküdür.

```powershell
.\powershell\New-DepartmentShare.ps1 `
    -RootPath 'C:\CorpShares' `
    -ShareName 'Engineering' `
    -AccessGroup 'CORP\GG_Engineering'
```

Script, eksik klasörleri oluşturur ve `\\DC01\Engineering` paylaşımını açar. Dosyalara ağ üzerinden erişim, hem NTFS hem SMB izinlerine bağlıdır.

## Erişim Testleri

CLIENT01 üzerindeki erişim testleri, `CORP\ali` ve `CORP\mehmet` oturumlarını kullanır. Test dosyası `\\DC01\Engineering\ali-test.txt`'dir.

| Hesap | Engineering grup üyeliği | Sonuç |
|---|---|---|
| `CORP\ali` | Üye | Dosya oluşturma, düzenleme, okuma ve silme başarılı |
| `CORP\mehmet` | Üye değil | Erişim yok |
