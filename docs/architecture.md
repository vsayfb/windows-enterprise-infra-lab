# Lab architecture

Two Windows VMs run on a Debian QEMU/KVM host. The isolated libvirt network provides connectivity between the host and guests without DHCP, libvirt DNS, NAT, or external forwarding.

```mermaid
flowchart TB
    Host["Debian host<br/>QEMU/KVM and libvirt<br/>virbr1: 10.10.10.1/24"]
    LAN["corp-lab<br/>10.10.10.0/24<br/>Isolated virtual network"]
    DC["DC01<br/>10.10.10.10/24<br/>AD DS, DNS, SMB"]
    Client["CLIENT01<br/>10.10.10.20/24<br/>Windows 11 domain member"]
    Backup["LabBackup E:<br/>30 GiB virtual disk<br/>System State backup"]
    Host --- LAN
    LAN --- DC
    LAN --- Client
    DC --- Backup
```

| Component | Configuration |
|---|---|
| AD forest and domain | `corp.test` |
| NetBIOS domain name | `CORP` |
| DC01 OS | Windows Server 2025 Standard Evaluation, Desktop Experience |
| CLIENT01 OS | Windows 11 Enterprise Evaluation |
| Guest RAM | 4 GiB per VM |
| Guest DNS | `10.10.10.10` |
| Guest default gateway | None |
| Share | `\\DC01\Engineering` |

## Directory layout

```text
corp.test
├── Domain Controllers OU
│   └── DC01
├── PCs OU
│   └── CLIENT01
├── Engineering OU
│   ├── Ali (ali)
│   └── GG_Engineering
└── Users container
    └── Mehmet (mehmet)
```

`Engineering-User-Policy` is linked to Engineering; `PCs-WinRM` is linked to PCs.

