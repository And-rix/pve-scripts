#!/bin/bash

# MIT License
# Copyright (c) 2025 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

export LANG=en_US.UTF-8

# Import Misc
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/misc.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm/vdsm-functions.sh)

# Post message
create_header "VM-Disk-Update"

# Sleep
sleep 1

# Info
ask_user_confirmation

whiptail --title "VM Disk Update" --msgbox \
"Please select the VM in the next step.
---
Available options:
• Virtual disk (vm-ID-disk-#)
• Physical disk (/dev/disk/by-id)
---
Supported filesystem types:
dir, btrfs, nfs, cifs, lvm, lvmthin, zfs, zfspool" 16 60

# VM selection
vm_list_prompt

# Storage selection
sata_disk_menu
