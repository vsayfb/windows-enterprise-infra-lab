# CLIENT01 installation

CLIENT01 runs Windows 11 Enterprise Evaluation on QEMU/KVM. It is connected to the isolated `corp-lab` network and joined to `corp.test`.

## Configuration

| Component | Configuration |
|---|---|
| VM name and guest hostname | `CLIENT01` |
| Operating system | Windows 11 Enterprise Evaluation |
| Network | `corp-lab` |
| Domain | `corp.test` |

## Guest hostname

The guest hostname is set before domain join. `Rename-Computer` requires elevation and restarts Windows.

```powershell
Rename-Computer -NewName 'CLIENT01' -Restart
```

Hostname and adapter queries:

```powershell
hostname
Get-NetAdapter
```

Networking configuration: [client networking and domain join](../windows-networking/domain-join.md).
