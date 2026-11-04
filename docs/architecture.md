# Altyapı Mimarisi

İki Windows sanal makinesi, Debian üzerinde QEMU/KVM ile çalışır. İzole libvirt ağı, host ve sanal makineler arasındaki bağlantıyı sağlar. DHCP, libvirt DNS, NAT ve dış ağlara yönlendirme kapalıdır.

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

| Bileşen | Yapılandırma |
|---|---|
| AD forest ve domain | `corp.test` |
| NetBIOS domain adı | `CORP` |
| DC01 işletim sistemi | Windows Server 2025 Standard Evaluation, Desktop Experience |
| CLIENT01 işletim sistemi | Windows 11 Enterprise Evaluation |
| Sanal makinelerin RAM kapasitesi | Her VM için 4 GiB |
| Sanal makinelerin DNS sunucusu | `10.10.10.10` |
| Default gateway | Yok |
| Dosya paylaşımı | `\\DC01\Engineering` |

## Active Directory Yapısı

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

Engineering organizasyon birimine `Engineering-User-Policy`, PCs organizasyon birimine `PCs-WinRM` bağlıdır.
