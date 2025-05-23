#!/bin/bash

# Script Name: vdsm-arc-toolkit.sh
# Author: And-rix (https://github.com/And-rix)
# Version: v1.0 - 23.05.2025
# Creation: 26.05.2025

export LANG=en_US.UTF-8

# Import Misc
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/colors.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/emojis.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/functions.sh)

# Clearing screen
clear

# Post message
echo ""
echo -e "${C}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++${X}"
echo -e "${C}+++++++++++++++++++++${X} vDSM-Arc-Toolkit ${C}++++++++++++++++++${X}"
echo -e "${C}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++${X}"
echo ""
echo ""
echo -e "${DISK}${Y}Choose your option:${X}"
echo -e "${C}1) CREATE new vDSM.Arc VM${X}"
echo -e "${C}2) UPDATE existing vDSM.Arc VM${X}"
echo -e "${C}3) ADD disks to a VM${X}"
echo -e "${R}x) EXIT${X}"
read -n 1 option

    case "$option" in
        1) #CREATE new vDSM.Arc
            bash -c "$(wget -qLO - https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm-arc.sh)"
			;;
		2) #UPDATE existing vDSM.Arc
            bash -c "$(wget -qLO - https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm-arc-update.sh)"
			;;
		3) #ADD existing vDSM.Arc
            bash -c "$(wget -qLO - https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vm-disk-update.sh)"
			;;
        x) #EXIT
            echo -e "${OK}${C}Exiting the script.${X}"
            echo ""
            exit 0
			;;
        *) # False selection
            echo -e "${WARN}${R}Invalid input. Please choose '1' | '2' | '3' | 'x'.${X}"
			;;
    esac
