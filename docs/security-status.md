# Security inspection

Firewall, Defender, local account, and installed-hotfix inspection results.

| Check | Configuration |
|---|---|
| Firewall profiles on DC01 and CLIENT01 | Domain, Private, and Public enabled |
| Effective default firewall actions | Inbound Block, outbound Allow |
| Defender service, antivirus, real-time protection | Enabled on both machines |
| Defender signature timestamp | September 16, 2025, on both machines |
| Latest listed DC01 hotfix installation date | January 14, 2026 |
| Latest listed CLIENT01 hotfix installation date | September 13, 2026 |

## Remote inspection commands

Commands execute from an authorized administrative session on DC01:

```powershell
Invoke-Command -ComputerName DC01, CLIENT01 -ScriptBlock {
    Get-NetFirewallProfile -PolicyStore ActiveStore |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction

    Get-MpComputerStatus |
        Select-Object AMServiceEnabled, AntivirusEnabled,
            RealTimeProtectionEnabled, AntivirusSignatureLastUpdated

    Get-HotFix |
        Sort-Object InstalledOn -Descending |
        Select-Object -First 5 HotFixID, Description, InstalledOn
}
```

## CLIENT01 local administration

| Member | Category | State or purpose |
|---|---|---|
| `CLIENT01\Administrator` | Local user | Disabled |
| `CLIENT01\CLIENT01` | Local user | Enabled |
| `CORP\Domain Admins` | Domain group | Local administrator membership |

```powershell
Invoke-Command -ComputerName CLIENT01 -ScriptBlock {
    Get-LocalGroupMember -SID 'S-1-5-32-544' |
        Select-Object Name, ObjectClass, PrincipalSource

    Get-LocalUser |
        Select-Object Name, Enabled, LastLogon
}
```

## WinRM access

The `PCs-WinRM` GPO defines the following configuration:

| Property | Value |
|---|---|
| WinRM startup | Automatic |
| Listener | HTTP, TCP 5985 |
| Firewall profile | Domain |
| Allowed remote address | `10.10.10.10` |

| WinRM access check | Result |
|---|---|
| Standard local `WINRM-HTTP-In-TCP*` rules | Disabled |
| New authenticated command from DC01 | Succeeded |
| Source restriction test from another host | Not performed |
