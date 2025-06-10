# pve-scripts 

**Just copy & paste into your PVE shell 😎**

## 📟 **vdsm-arc-toolkit.sh**

All-in-1 toolkit script for **vDSM Arc Loader** from [AuxXxilium](https://github.com/AuxXxilium) on your PVE host.

- **CREATE** new vDSM.Arc
- **UPDATE** existing vDSM.Arc
- **ADD** disks to a VM

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm-arc-toolkit.sh)"
```

---

## 📟 **vdsm-arc-install.sh**

An automated install script for **vDSM Arc Loader** from [AuxXxilium](https://github.com/AuxXxilium) on your PVE host.

- **Default settings**:  
  - **CPU**: 2 Cores  
  - **RAM**: 4096MB  
  - **NIC**: vmbr0  
  - **Storage**: Selectable
- **Supported filesystem types**:  
  `dir`, `btrfs`, `nfs`, `cifs`, `lvm`, `lvmthin`, `zfs`, `zfspool`   
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm-arc-install.sh)"
```

---

## 📟 **vdsm-arc-update.sh**

An automated update script for **vDSM Arc Loader** on an existing VM.
- Boot image will be replaced. **Loader re-build is required!**
- vDSM.Arc will be mapped as SATA0
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm-arc-update.sh)"
```

---

## 📟 vm-disk-update.sh

Add more virtual or physical disks to an existing VM on your PVE host   

- **Supported filesystem types**:  
  `dir`, `btrfs`, `nfs`, `cifs`, `lvm`, `lvmthin`, `zfs`, `zfspool`   
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vm-disk-update.sh)"
```

---

## 📟 laptop-hibernation.sh

This script disable any hibernation mode to run Proxmox VE on a laptop   
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/laptop-hibernation.sh)"
```
