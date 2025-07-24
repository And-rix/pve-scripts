# pve-scripts 

**Just copy & paste into your PVE shell 😎**

---

## 🧰 **vdsm-arc-toolkit.sh**

All-in-one toolkit script for **vDSM.Arc Loader** by [AuxXxilium](https://github.com/AuxXxilium) on your Proxmox VE host.

- **CREATE** new vDSM.Arc
- **UPDATE** existing vDSM.Arc
- **ADD** disks to a VM
  

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm-arc-toolkit.sh)"
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
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm-arc-install.sh)"
```

---

## 🔄 **vdsm-arc-update.sh**

Automated update script for **vDSM.Arc Loader** on an existing VM.
- Replaces boot image. Rebuild of loader required!
- vDSM.Arc mapped as SATA0
- Backs up old boot disk as 'unused disk'
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm-arc-update.sh)"
```

---

## 💾 vm-disk-update.sh

Add additional virtual or physical disks to an existing VM on your Proxmox VE host.  

- **Supported filesystem types**:  
  `dir`, `btrfs`, `nfs`, `cifs`, `lvm`, `lvmthin`, `zfs`, `zfspool`   
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vm-disk-update.sh)"
```

---

## 🔗 tailscale-subnet-router.sh

Automatically creates an unprivileged Ubuntu 22.04 LXC container on Proxmox and configures it as a [Tailscale subnet router](https://tailscale.com/kb/1019/subnets).

- Just copy & paste the install command into your Proxmox shell.
- Follow the prompts to set up your subnet router.
- Once installed, you can access the entire subnet behind the LXC via Tailscale.
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/tailscale-subnet-router.sh)"
```

---

## 💻 laptop-hibernation.sh

Disables all hibernation modes to run Proxmox VE smoothly on a laptop. 
  
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/laptop-hibernation.sh)"
```
