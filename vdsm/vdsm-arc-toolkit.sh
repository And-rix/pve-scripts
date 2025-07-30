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
create_header "vDSM-Arc-Toolkit"

# Sleep
sleep 1

#!/bin/bash

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
        echo -e "\n${R}[!] ${C}User cancelled. Exiting...${X}\n"
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
            echo -e "\n${G}[OK] ${C}Exiting the script...${X}\n"
            exit 0
            ;;
        *)
            whiptail --title "Invalid Option" --msgbox "Invalid input. Please try again." 8 50
            exit 1
            ;;
    esac
done
