# CLIENT01 installation

CLIENT01 runs Windows 11 Enterprise Evaluation on QEMU/KVM. It is connected to the isolated `corp-lab` network and joined to `corp.test`.

## Install Windows 11

1. Create a VM named `CLIENT01` in virt-manager using local installation media.
2. Select the Windows 11 Enterprise Evaluation ISO.
3. Connect the network adapter to `corp-lab`.
4. Install Windows 11 and complete initial setup with a local administrator account.

## Set the hostname

The VM name and Windows hostname are configured separately. Open Windows PowerShell as Administrator:

```powershell
Rename-Computer -NewName 'CLIENT01' -Restart
```

After restarting, sign in with the local account and inspect the hostname and network adapter:

```powershell
hostname
Get-NetAdapter
```

Continue with [client networking and domain join](../windows-networking/domain-join.md).
