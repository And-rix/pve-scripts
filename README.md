# pve-scripts 

**Just copy & paste into your PVE shell 😎**

---

## ⚠️ Important Notice

All scripts provided here have been tested on multiple Proxmox VE environments and scenarios. 

However, every system is different — **please proceed with caution.**

---

## 🔗 tailscale-subnet-router.sh

Automatically creates an unprivileged Ubuntu 22.04 LXC container on Proxmox and configures it as a [Tailscale subnet router](https://tailscale.com/kb/1019/subnets).

- Just copy & paste the install command into your Proxmox VE shell.
- Follow the instructions to complete the setup.
- Once installed, you can access the entire subnet behind the LXC via Tailscale.
- **⚠️ Important:** You must approve the new subnet route manually in the [Tailscale Admin Panel](https://login.tailscale.com/admin/machines) after setup!
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/tailscale/tailscale-subnet-router.sh)"
```

---

## 🧰 **vdsm-arc-toolkit.sh**

All-in-one toolkit for **vDSM.Arc Loader** by [AuxXxilium](https://github.com/AuxXxilium) on your Proxmox VE host.

- **CREATE** new vDSM.Arc
- **UPDATE** an existing vDSM.Arc
- **ADD** disks to a VM
  

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/vdsm/vdsm-arc-toolkit.sh)"
```

---

## ⚙️ **vdsm-arc-install.sh**

Automated installer for **vDSM.Arc Loader** by [AuxXxilium](https://github.com/AuxXxilium) on your Proxmox VE host.

- **Default settings**:  
  - **CPU**: 2 Cores  
  - **RAM**: 4096MB  
  - **NIC**: vmbr0  
  - **Storage**: Selectable
- **Supported filesystem types**:  
  `dir`, `btrfs`, `nfs`, `cifs`, `lvm`, `lvmthin`, `zfs`, `zfspool`
- ℹ️ ***This script is also included in vdsm-arc-toolkit.sh***
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/vdsm/vdsm-arc-install.sh)"
```

---

## 🔄 **vdsm-arc-update.sh**

Automated update script for **vDSM.Arc Loader** on an existing VM.
- Replaces boot image. Rebuild of loader is required!
- vDSM.Arc is mapped as SATA0
- Backs up old boot disk as 'unused disk'
- ℹ️ ***This script is also included in vdsm-arc-toolkit.sh***
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/vdsm/vdsm-arc-update.sh)"
```

---

## 💾 vm-disk-update.sh

Add additional virtual or physical disks to an existing VM on your Proxmox VE host.  

- **Supported filesystem types**:  
  `dir`, `btrfs`, `nfs`, `cifs`, `lvm`, `lvmthin`, `zfs`, `zfspool`

- **Supported -physical- disk types**:  
  `sata`, `nvme`, `usb`
- ℹ️ ***This script is also included in vdsm-arc-toolkit.sh***
    
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/vdsm/vm-disk-update.sh)"
```

---

## 💻 pve-laptop-hibernation.sh

Disables all hibernation modes to run Proxmox VE smoothly on a laptop. 
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/other/pve-laptop-hibernation.sh)"
```

---

## ♻️ pve8-to-pve9.sh

This script automates the upgrade process from **Proxmox VE 8 (Debian Bookworm)** to **Proxmox VE 9 (Debian Trixie)** for systems using the **no-subscription** repository only. 

Saves APT sources, installs keyrings, sets new repos, upgrades the system, and removes the subscription nag.
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/other/pve8-to-pve9.sh)"
```
