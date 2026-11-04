# DC01 network configuration

DC01 uses a static IPv4 address on the isolated `corp-lab` network. DNS is directed to DC01, which hosts the domain DNS service. No default gateway is configured.

| Setting | Value |
|---|---|
| Adapter alias | `Ethernet` |
| IPv4 address | `10.10.10.10` |
| Prefix length | `24` |
| DNS server | `10.10.10.10` |
| Default gateway | None |

## Adapter identification

Adapter and address information:

```powershell
Get-NetAdapter
Get-NetIPConfiguration
```

## IPv4 and DNS settings

The configuration targets adapter alias `Ethernet` and requires elevated Windows PowerShell. Static addressing precedes AD DS promotion.

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.10.10.10 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.10.10.10
```

## Network verification

```powershell
Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4
Get-NetIPConfiguration -InterfaceAlias "Ethernet"
ping 10.10.10.1
```

`10.10.10.1` is the Debian host's bridge address. DNS service is installed during [domain controller deployment](../active-directory/README.md).
