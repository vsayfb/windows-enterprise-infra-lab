# Virtual network

The Windows VMs are connected through `corp-lab`, an isolated libvirt network. Static addressing is used; DHCP, libvirt DNS, and external forwarding are disabled.

| Setting | Value |
|---|---|
| Libvirt connection | `qemu:///system` |
| Network | `corp-lab` |
| Subnet | `10.10.10.0/24` |
| Bridge | `virbr1` |
| Host bridge address | `10.10.10.1/24` |
| Autostart | Enabled |

## Network definition

Network definition commands, relative to the repository root:

```bash
sudo virsh -c qemu:///system net-define virtualization/corp-lab.xml
sudo virsh -c qemu:///system net-start corp-lab
sudo virsh -c qemu:///system net-autostart corp-lab
```

## Network inspection

```bash
sudo virsh -c qemu:///system net-list --all
sudo virsh -c qemu:///system net-dumpxml corp-lab
ip -4 address show virbr1
```
