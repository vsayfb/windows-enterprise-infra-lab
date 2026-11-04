# Windows Enterprise Infrastructure Lab

A Windows infrastructure lab on Debian with QEMU/KVM and libvirt, covering AD DS, DNS, Group Policy, NTFS/SMB permissions, remote administration, reporting, and backup recovery. The configuration represents an isolated training environment.

![Windows enterprise lab topology with DC01 and CLIENT01 on the isolated corp-lab network](diagram.png)

## Installation media

| VM | Evaluation ISO |
|---|---|
| DC01 | [Windows Server 2025](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2025) |
| CLIENT01 | [Windows 11 Enterprise](https://info.microsoft.com/ww-landing-windows-11-enterprise.html) |

[Architecture and directory layout](docs/architecture.md)

## Verified operations

| Area | Result |
|---|---|
| AD DS and DNS | corp.test forest; DC discovery and selected DC diagnostics passed |
| Domain membership | CLIENT01 joined; Ali authenticated with Engineering group in token |
| Group Policy | User restriction applied and reverted; WinRM computer policy applied |
| File sharing | Ali read/write/delete allowed; Mehmet denied |
| Remote administration | Authenticated execution and service stop/start verified |
| Reporting | Domain inventory and user-report filtering; CSV export and reimport |
| Recovery | System State backup; 29 policy files recovered with zero failures |

## Environment scope

| Component | Scope |
|---|---|
| Directory | One forest, one domain, one domain controller |
| Network | Isolated virtual subnet without external forwarding |
| Recovery test | Alternate-location restoration of SYSVOL policy files |
| Backup storage | Separate virtual disk on the same host |

Full domain controller recovery and independent backup storage are outside the demonstrated recovery scope.

## Virtualization

- [Virtual network](virtualization/README.md)
- [DC01 installation](virtualization/dc01.md)
- [CLIENT01 installation](virtualization/client01.md)

## Windows networking

- [DC01 static IP and DNS configuration](windows-networking/README.md)
- [Client networking and domain join](windows-networking/domain-join.md)

## Active Directory

- [Domain controller deployment](active-directory/README.md)
- [Engineering accounts and security group](active-directory/engineering.md)
- [Computer account organization](active-directory/computer-organization.md)

## Group Policy

- [Engineering user policy](group-policy/README.md)

## File sharing

- [Engineering file share](file-sharing/README.md)

## PowerShell

- [Deployment and verification scripts](powershell/README.md)

## Administration and reporting

- [PowerShell remote administration](docs/remote-administration.md)
- [Domain computer inventory](docs/inventory.md)
- [Domain user report](docs/user-report.md)

## Backup and recovery

- [System State backup and file recovery](backup-recovery/README.md)

## Security

- [Security inspection](docs/security-status.md)
