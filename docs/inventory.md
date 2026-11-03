# Domain computer inventory

[Get-DomainInventory.ps1](../powershell/Get-DomainInventory.ps1) discovers AD computer accounts and collects live system information over WinRM. [Export-InventoryCsv.ps1](../powershell/Export-InventoryCsv.ps1) writes the returned objects to CSV.

Run from the repository root on DC01 in an administrative Windows PowerShell session. The ActiveDirectory module is required for discovery. WinRM must be enabled on the targets, and the executing account must have remote session access.

## Collect inventory

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

## Filter computers

```powershell
$Clients = .\powershell\Get-DomainInventory.ps1 -Filter "Name -like 'CLIENT*'"

$DomainControllers = .\powershell\Get-DomainInventory.ps1 `
    -SearchBase 'OU=Domain Controllers,DC=corp,DC=test'
```

OU searches select computer accounts stored within that OU hierarchy. A user's OU location does not determine the location of their computer account.

## Export and inspect CSV

```powershell
$Inventory |
    .\powershell\Export-InventoryCsv.ps1 -Path "$env:TEMP\inventory.csv"

Import-Csv "$env:TEMP\inventory.csv" |
    Format-Table ComputerName, OS, RAM_GB, Status
```

Use `-Overwrite` to replace an existing CSV. Pipe inventory objects directly to the exporter; use `Format-Table` only for display. CSV fields are imported as strings.

## Validation

| Test | Result |
|---|---|
| Current-domain collection | CLIENT01 and DC01 returned Success; both reported 4 GB RAM |
| CSV export and reimport | Completed |
| Name filter `CLIENT*` | CLIENT01 only |
| Domain Controllers OU search | DC01 only |
