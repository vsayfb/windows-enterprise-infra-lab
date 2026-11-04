# CLIENT01 Kurulumu

CLIENT01, QEMU/KVM üzerinde Windows 11 Enterprise Evaluation kullanır. İzole `corp-lab` ağına ve `corp.test` domain'ine bağlıdır.

## Yapılandırma

| Bileşen | Yapılandırma |
|---|---|
| VM adı ve bilgisayar adı | `CLIENT01` |
| İşletim sistemi | Windows 11 Enterprise Evaluation |
| Ağ | `corp-lab` |
| Domain | `corp.test` |

## Bilgisayar Adı

`Rename-Computer`, bilgisayar adını `CLIENT01` olarak ayarlar ve Windows'u yeniden başlatır. Komut, domain üyeliği öncesinde yönetici yetkisiyle çalıştırılır.

```powershell
Rename-Computer -NewName 'CLIENT01' -Restart
```

Bilgisayar adı ve ağ adaptörü sorguları:

```powershell
hostname
Get-NetAdapter
```

[Ağ yapılandırması ve domain üyeliği](../windows-networking/domain-join.md)
