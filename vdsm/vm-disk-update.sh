#!/bin/bash

# MIT License
# Copyright (c) 2025 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

export LANG=en_US.UTF-8

# Import misc functions
source <(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/misc/misc.sh)
source <(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/vdsm/vdsm-functions.sh)

# Header
create_header "VM-Disk-Update"
sleep 1

# User confirmation
ask_user_confirmation

# Info message
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
