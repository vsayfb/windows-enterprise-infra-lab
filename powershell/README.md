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
