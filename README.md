# pve-scripts 

**Just copy & paste into your PVE shell 😎**

<br><br>
## ⚠️ Important Notice

All scripts provided here have been tested on multiple Proxmox VE environments and scenarios. 

However, every system is different — **please proceed with caution.**


<br><br>
# 🔗 Tailscale

## 🔗 *tailscale-subnet-router.sh*

Automatically creates an unprivileged Ubuntu 22.04 LXC container on Proxmox and configures it as a [Tailscale subnet router](https://tailscale.com/kb/1019/subnets).

### Features

- Just copy & paste the install command into your Proxmox VE shell.
- Follow the instructions to complete the setup.
- Once installed, you can access the entire subnet behind the LXC via Tailscale.
- **⚠️ Important:** You must approve the new subnet route manually in the [Tailscale Admin Panel](https://login.tailscale.com/admin/machines) after setup!

### Install

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/tailscale/tailscale-subnet-router.sh)"
```

---

## 🔗 *tailscale-watchdog-addon.sh*

Self-healing Watchdog Add-On for Tailscale LXCs

An automated bash script that monitors Tailscale connectivity by pinging random online peers (from your own tailscale network). It automatically restarts tailscaled upon connection loss and includes built-in logging and cron integration.

### Details

- logs `/var/log/tailscale-watchdog.log`
- script `/usr/local/bin/tailscale-watchdog.sh`
- cronjob `crontab -e`

> ❯ Execute inside LXC container!

### Install

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/tailscale/tailscale-watchdog-addon.sh)"
```

<br><br>
# 🧰 vDSM.Arc

## 🧰 *vdsm-arc-toolkit.sh*

All-in-one toolkit for **vDSM.Arc Loader** by [AuxXxilium](https://github.com/AuxXxilium) on your Proxmox VE host.

### Features

- **CREATE** new vDSM.Arc
- **UPDATE** an existing vDSM.Arc
- **ADD** disks to a VM

### Install

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/vdsm/vdsm-arc-toolkit.sh)"
```

---

## ⚙️ *vdsm-arc-install.sh*

Automated installer for **vDSM.Arc Loader** by [AuxXxilium](https://github.com/AuxXxilium) on your Proxmox VE host.

### Default settings

- **CPU**: 2 Cores  
- **RAM**: 4096MB  
- **NIC**: vmbr0  
- **Storage**: Selectable

### Supported filesystem types

`dir`, `btrfs`, `nfs`, `cifs`, `lvm`, `lvmthin`, `zfs`, `zfspool`

- ℹ️ ***This script is also included in vdsm-arc-toolkit.sh***

### Install

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/vdsm/vdsm-arc-install.sh)"
```

---

## 🔄 *vdsm-arc-update.sh*

Automated update script for **vDSM.Arc Loader** on an existing VM.

### Features

- Replaces boot image. Rebuild of loader is required!
- vDSM.Arc is mapped as SATA0
- Backs up old boot disk as 'unused disk'
- ℹ️ ***This script is also included in vdsm-arc-toolkit.sh***

### Install

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/vdsm/vdsm-arc-update.sh)"
```

---

## 💾 *vm-disk-update.sh*

Add additional virtual or physical disks to an existing VM on your Proxmox VE host.

### Supported filesystem types

`dir`, `btrfs`, `nfs`, `cifs`, `lvm`, `lvmthin`, `zfs`, `zfspool`

### Supported -physical- disk types

`sata`, `nvme`, `usb`

- ℹ️ ***This script is also included in vdsm-arc-toolkit.sh***

### Install

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/vdsm/vm-disk-update.sh)"
```

<br><br>
# 💻 Other Scripts

## 💻 *pve-laptop-hibernation.sh*

Disables all hibernation modes to run Proxmox VE smoothly on a laptop.

### Install

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/other/pve-laptop-hibernation.sh)"
```

---

<p align="center">

![GitHub stars](https://img.shields.io/github/stars/And-rix/pve-scripts?style=social)
![GitHub license](https://img.shields.io/github/license/And-rix/pve-scripts)

</p>
