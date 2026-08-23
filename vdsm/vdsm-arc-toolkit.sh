#!/bin/bash

# MIT License
# Copyright (c) 2026 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

export LANG=en_US.UTF-8

# Import misc functions
source <(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/misc/misc.sh)
source <(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/vdsm/vdsm-functions.sh)

if [[ $EUID -ne 0 ]]; then
  err "Please run as root on the Proxmox host."
  exit 1
fi
if ! command -v qm &>/dev/null; then
  err "This script must be executed on a Proxmox VE host ('qm' command not found)."
  exit 1
fi

# Header
create_header "vDSM-Arc-Toolkit"
sleep 1

while true; do
    OPTION=$(whiptail --title "vDSM-Arc Main Menu" \
        --menu "Select an action:" 15 60 6 \
        "1" "Create new vDSM-Arc" \
        "2" "Update existing vDSM-Arc" \
        "3" "Add disks to existing VM" \
        "x" "Exit script" \
        3>&1 1>&2 2>&3)

    exitstatus=$?

    if [ $exitstatus -ne 0 ]; then
        warn "User cancelled. Exiting..."
        exit 1
    fi

    case "$OPTION" in
        1)
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm/vdsm-arc-install.sh)"
            exit 0
            ;;
        2)
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm/vdsm-arc-update.sh)"
            exit 0
            ;;
        3)
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm/vm-disk-update.sh)"
            exit 0
            ;;
        x)
            msg "Exiting the script..."
            exit 0
            ;;
        *)
            whiptail --title "Invalid Option" --msgbox "Invalid input. Please try again." 8 50
            exit 1
            ;;
    esac
done
