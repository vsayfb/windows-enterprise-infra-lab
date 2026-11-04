# Engineering Kullanıcıları ve Güvenlik Grubu

Engineering organizasyon birimi (OU), departman kullanıcılarını ve Global kapsamlı `GG_Engineering` güvenlik grubunu içerir. Departman kaynaklarının erişim izinleri bu grup üzerinden yönetilir.

```text
corp.test
└── Engineering
    ├── Ali (ali)
    └── GG_Engineering
        └── Member: ali
```

| Nesne | Distinguished name |
|---|---|
| OU | `OU=Engineering,DC=corp,DC=test` |
| Kullanıcı | `CN=Ali,OU=Engineering,DC=corp,DC=test` |
| Güvenlik grubu | `CN=GG_Engineering,OU=Engineering,DC=corp,DC=test` |

## Departman Kullanıcısı Oluşturma

Script, ActiveDirectory modülü ve `corp.test` üzerinde kullanıcı, grup ve OU yönetim yetkisi gerektirir. Komutun çalışma dizini repository köküdür.

```powershell
.\powershell\New-ADDepartmentUser.ps1 `
    -DomainName 'corp.test' `
    -OUName 'Engineering' `
    -GroupName 'GG_Engineering' `
    -AccountName 'ali' `
    -DisplayName 'Ali'
```

Script, eksik OU, grup ve kullanıcıyı oluşturur; kullanıcıyı gruba ekler. Yeni veya devre dışı hesaplar için geçici parola ister ve hesabı etkinleştirir. Mevcut etkin hesapların parola ayarları korunur.

## Organizasyon Birimi ve Güvenlik Grubu Bilgileri

```powershell
Get-ADOrganizationalUnit -Identity 'OU=Engineering,DC=corp,DC=test' `
    -Properties ProtectedFromAccidentalDeletion |
    Select-Object Name, DistinguishedName, ProtectedFromAccidentalDeletion

Get-ADGroup 'GG_Engineering' |
    Select-Object Name, GroupScope, GroupCategory, DistinguishedName
```

## Kullanıcı Bilgileri ve Grup Üyeleri

```powershell
Get-ADUser 'ali' -Properties pwdLastSet |
    Select-Object Name, SamAccountName, UserPrincipalName, Enabled, DistinguishedName, pwdLastSet

Get-ADGroupMember 'GG_Engineering' |
    Select-Object Name, SamAccountName
```

`pwdLastSet` değeri `0` olan hesaplarda sonraki oturum açılışında parola değişikliği zorunludur.
