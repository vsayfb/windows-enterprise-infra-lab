# Domain computer inventory

[Get-DomainInventory.ps1](../powershell/Get-DomainInventory.ps1) discovers AD computer accounts and collects live system information over WinRM. [Export-InventoryCsv.ps1](../powershell/Export-InventoryCsv.ps1) writes the returned objects to CSV.

Execution requires the ActiveDirectory module and authorized WinRM access to each target. Examples use an administrative Windows PowerShell session on DC01 with the repository root as the working directory.

## Inventory collection

```powershell
$Inventory = .\powershell\Get-DomainInventory.ps1

$Inventory | Format-Table ComputerName, OS, RAM_GB, Status, Error
```

| Parameter | Purpose |
|---|---|
| `DomainName` | AD domain to query; defaults to the current domain |
| `Filter` | `Get-ADComputer` filter; defaults to `Enabled -eq $true` |
| `SearchBase` | Parent distinguished name for an OU or container search, including descendants |

Each record contains `ComputerName`, `DNSHostName`, `Domain`, `OS`, `RAM_GB`, `LogicalCPUs`, `LastBoot`, `Status`, and `Error`. A failed connection produces a failed record without stopping collection from other computers.

## Computer selection

```powershell
$Clients = .\powershell\Get-DomainInventory.ps1 -Filter "Name -like 'CLIENT*'"

$DomainControllers = .\powershell\Get-DomainInventory.ps1 `
    -SearchBase 'OU=Domain Controllers,DC=corp,DC=test'
```

`SearchBase` restricts discovery to computer accounts in the specified directory subtree.

## CSV export

```powershell
$Inventory |
    .\powershell\Export-InventoryCsv.ps1 -Path "$env:TEMP\inventory.csv"

Import-Csv "$env:TEMP\inventory.csv" |
    Format-Table ComputerName, OS, RAM_GB, Status
```

`-Overwrite` permits replacement of an existing CSV. The exporter accepts inventory objects; `Format-Table` produces display data unsuitable for export. CSV fields are imported as strings.

## Validation

| Test | Result |
|---|---|
| Current-domain collection | CLIENT01 and DC01 returned Success; both reported 4 GB RAM |
| CSV export and reimport | Completed |
| Name filter `CLIENT*` | CLIENT01 only |
| Domain Controllers OU search | DC01 only |
