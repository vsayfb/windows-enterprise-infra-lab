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
