# Sanal Ağ

Windows sanal makineleri, izole `corp-lab` libvirt ağına bağlıdır. IP adresleri statiktir; DHCP, libvirt DNS ve dış ağlara yönlendirme kapalıdır.

| Ayar | Değer |
|---|---|
| Libvirt bağlantısı | `qemu:///system` |
| Ağ | `corp-lab` |
| Subnet | `10.10.10.0/24` |
| Bridge | `virbr1` |
| Host bridge adresi | `10.10.10.1/24` |
| Autostart | Etkin |

## Libvirt Ağının Oluşturulması

Komutların çalışma dizini repository köküdür.

```bash
sudo virsh -c qemu:///system net-define virtualization/corp-lab.xml
sudo virsh -c qemu:///system net-start corp-lab
sudo virsh -c qemu:///system net-autostart corp-lab
```

## Ağ Durumu ve Bridge Adresi

```bash
sudo virsh -c qemu:///system net-list --all
sudo virsh -c qemu:///system net-dumpxml corp-lab
ip -4 address show virbr1
```
