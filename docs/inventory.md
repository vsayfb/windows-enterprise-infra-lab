# Domain Bilgisayar Envanteri

[Get-DomainInventory.ps1](../powershell/Get-DomainInventory.ps1), AD bilgisayar hesaplarını sorgular ve WinRM üzerinden sistem bilgilerini toplar. [Export-InventoryCsv.ps1](../powershell/Export-InventoryCsv.ps1), sonuçları CSV'ye aktarır.

ActiveDirectory modülü ve hedef bilgisayarlarda WinRM erişim yetkisi gereklidir. Komutlar, DC01 üzerinde yönetici yetkili Windows PowerShell oturumunda çalıştırılır. Çalışma dizini repository köküdür.

## Bilgisayar Envanteri Sorgulama

```powershell
$Inventory = .\powershell\Get-DomainInventory.ps1

$Inventory | Format-Table ComputerName, OS, RAM_GB, Status, Error
```

| Parametre | İşlev |
|---|---|
| `DomainName` | Sorgulanacak domain; varsayılan değer mevcut domain |
| `Filter` | `Get-ADComputer` filtresi; varsayılan değer `Enabled -eq $true` |
| `SearchBase` | Alt nesneleriyle birlikte sorgulanacak OU veya container'ın distinguished name değeri |

Her kayıt `ComputerName`, `DNSHostName`, `Domain`, `OS`, `RAM_GB`, `LogicalCPUs`, `LastBoot`, `Status` ve `Error` alanlarını içerir.

## Bilgisayar Adı ve OU Filtreleri

```powershell
$Clients = .\powershell\Get-DomainInventory.ps1 -Filter "Name -like 'CLIENT*'"

$DomainControllers = .\powershell\Get-DomainInventory.ps1 `
    -SearchBase 'OU=Domain Controllers,DC=corp,DC=test'
```

## Envanteri CSV'ye Aktarma

```powershell
$Inventory |
    .\powershell\Export-InventoryCsv.ps1 -Path "$env:TEMP\inventory.csv"

Import-Csv "$env:TEMP\inventory.csv" |
    Format-Table ComputerName, OS, RAM_GB, Status
```

## Test Sonuçları

| Test | Sonuç |
|---|---|
| Mevcut domain sorgusu | CLIENT01 ve DC01; her biri 4 GB RAM |
| CSV dışa aktarma ve içe aktarma | Başarılı |
| `CLIENT*` ad filtresi | Yalnızca CLIENT01 |
| Domain Controllers OU sorgusu | Yalnızca DC01 |
