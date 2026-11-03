# PowerShell scripts

## Deploy DC01

[Deploy-DC01-NewForest.ps1](Deploy-DC01-NewForest.ps1) configures the first domain controller with fixed lab settings:

| Setting | Value |
|---|---|
| Hostname | `DC01` |
| Network adapter | `Ethernet` |
| IPv4 address | `10.10.10.10/24` |
| DNS server | `10.10.10.10` |
| Default gateway | None |
| Forest and domain | `corp.test` |
| NetBIOS domain name | `CORP` |

Run on a fresh Windows Server installation connected to `corp-lab`. Open Windows PowerShell as Administrator and run from this directory:

```powershell
.\Deploy-DC01-NewForest.ps1
```

Run the same file after each restart. Completed deployment stages are skipped. Enter and confirm the DSRM recovery password when prompted, then confirm forest creation. After promotion, sign in as `CORP\Administrator` and run the file again to check networking, DNS discovery, and domain controller services.

Credentials are entered interactively and are not stored in the script. Existing conflicting IPv4 configurations and unrelated domain memberships are rejected.

## Add a domain controller

[Add-DomainController.ps1](Add-DomainController.ps1) configures an additional writable domain controller and DNS server in an existing domain. The existing domain controller and its DNS service must be reachable. Use an unused hostname and IPv4 address on the isolated network.

Run on the new Windows Server VM in elevated Windows PowerShell:

```powershell
.\Add-DomainController.ps1 `
    -ServerName 'DC02' `
    -IPAddress '10.10.10.11' `
    -DNSServer '10.10.10.10' `
    -DomainName 'corp.test' `
    -PrefixLength 24 `
    -InterfaceName 'Ethernet'
```

| Parameter | Purpose |
|---|---|
| `ServerName` | New domain controller hostname |
| `IPAddress` | New domain controller IPv4 address |
| `DNSServer` | Existing domain DNS server IPv4 address |
| `DomainName` | Existing AD domain DNS name |
| `PrefixLength` | Subnet prefix length; default `24` |
| `InterfaceName` | Local network adapter alias; default `Ethernet` |

Run the same command after each restart. Supply an account authorized to add domain controllers and enter the new server's DSRM password when prompted. Confirm promotion and allow the server to restart. Sign in with a domain administrator account and run the same command to inspect DNS discovery, DC services, and inbound replication.

The script does not configure a default gateway or replace conflicting static addresses. After promotion, the verification stage preserves the DC's DNS client configuration. Inspect `dcdiag` and `repadmin` output for test failures and replication errors.

Reference: [Install-ADDSDomainController](https://learn.microsoft.com/en-us/powershell/module/addsdeployment/install-addsdomaincontroller?view=windowsserver2025-ps).

## Provision department users

[New-ADDepartmentUser.ps1](New-ADDepartmentUser.ps1) creates a department OU, a global security group, and a user account with direct group membership.

Run in Windows PowerShell with permissions to manage users, groups, and OUs in the selected domain:

```powershell
.\New-ADDepartmentUser.ps1 `
    -DomainName 'corp.test' `
    -OUName 'Engineering' `
    -GroupName 'GG_Engineering' `
    -AccountName 'ali' `
    -DisplayName 'Ali'
```

| Parameter | Purpose |
|---|---|
| `DomainName` | Existing AD domain DNS name |
| `OUName` | Department OU name |
| `GroupName` | Global security group name and SAM account name |
| `AccountName` | User SAM account name; also used for the UPN prefix |
| `DisplayName` | User object name and display name |
| `ParentPath` | Existing parent OU distinguished name; defaults to the domain root |

Use a different OU, group, and account for another department:

```powershell
.\New-ADDepartmentUser.ps1 `
    -DomainName 'corp.test' `
    -OUName 'Sales' `
    -GroupName 'GG_Sales' `
    -AccountName 'ayse' `
    -DisplayName 'Ayse'
```

To create a department beneath an existing OU, supply its distinguished name with `-ParentPath`, for example `-ParentPath 'OU=Departments,DC=corp,DC=test'`. The parent OU must already exist.

OU names support letters, digits, spaces, underscores, and hyphens. Group names support letters, digits, underscores, and hyphens. New or disabled accounts require a temporary password entered at a secure prompt. Existing enabled accounts retain their passwords and password-change state. Existing objects with conflicting locations or group settings are rejected.

See [Engineering accounts and security group](../active-directory/engineering.md) for the lab structure and verification commands.

## Join a computer to the domain

[Join-DomainComputer.ps1](Join-DomainComputer.ps1) configures a hostname, static IPv4 address, and domain DNS server, discovers a DC, and joins an existing domain. Run locally in elevated Windows PowerShell on a Windows edition that supports AD domain membership.

```powershell
.\Join-DomainComputer.ps1 `
    -ComputerName 'CLIENT01' `
    -IPAddress '10.10.10.20' `
    -DNSServer '10.10.10.10' `
    -DomainName 'corp.test' `
    -PrefixLength 24 `
    -InterfaceName 'Ethernet'
```

| Parameter | Purpose |
|---|---|
| `ComputerName` | Target Windows hostname |
| `IPAddress` | Computer's static IPv4 address |
| `DNSServer` | AD DNS server IPv4 address |
| `DomainName` | Existing AD domain DNS name |
| `PrefixLength` | Subnet prefix length; default `24` |
| `InterfaceName` | Local adapter alias; default `Ethernet` |

Run the same command after each restart. Enter credentials authorized to join computers when prompted. Credentials are not stored in the script.

The network configuration is intended for the isolated lab: no default gateway is configured, and conflicting static addresses are rejected. Computers in another domain and domain controllers are rejected. On a joined computer, the script preserves network settings, performs DC discovery, and tests the secure channel.

See [client networking and domain join](../windows-networking/domain-join.md) for manual setup and user-session verification.

## Provision a department share

[New-DepartmentShare.ps1](New-DepartmentShare.ps1) creates a protected parent folder and a department folder with inherited administrative permissions, then publishes an SMB share.

Run locally in elevated Windows PowerShell on the file server:

```powershell
.\New-DepartmentShare.ps1 `
    -RootPath 'C:\CorpShares' `
    -ShareName 'Engineering' `
    -AccessGroup 'CORP\GG_Engineering'
```

| Parameter | Purpose |
|---|---|
| `RootPath` | Dedicated local parent folder for department shares |
| `ShareName` | Department folder name and SMB share name |
| `AccessGroup` | Existing department security group in `DOMAIN\Name` form |

The script grants Administrators and SYSTEM inheritable NTFS Full Control at the parent. The department group receives NTFS Modify and SMB Change. Administrators receive SMB Full access.

Existing folders and shares are checked before configuration. Conflicting permissions, disabled inheritance on a department folder, or a share mapped to another path stop execution. Matching existing configuration can be reused. No files are deleted, and no credentials are stored.

See [Engineering file share](../file-sharing/README.md) for the permission layout and client access tests.

## Collect and export inventory

[Get-DomainInventory.ps1](Get-DomainInventory.ps1) queries computer accounts in the current domain or a supplied domain, applies AD filters, and collects live inventory over WinRM. [Export-InventoryCsv.ps1](Export-InventoryCsv.ps1) exports those objects separately.

```powershell
$Inventory = .\Get-DomainInventory.ps1

$Inventory | Format-Table ComputerName, OS, RAM_GB, Status, Error

$Inventory | .\Export-InventoryCsv.ps1 -Path "$env:TEMP\inventory.csv"
```

Use `-DomainName`, `-Filter`, and `-SearchBase` to select computers. Use `-Overwrite` on the exporter to replace an existing CSV. See [domain computer inventory](../docs/inventory.md) for parameters, filter examples, and validation results.
