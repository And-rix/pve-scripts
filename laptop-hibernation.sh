#!/bin/bash

# Script Name: laptop-hibernation.sh
# Author: And-rix (https://github.com/And-rix)
# Version: v1.0 - 27.02.2025
# Creation: 17.02.2025

export LANG=en_US.UTF-8

# Import Misc
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/colors.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/emojis.sh)

# Clearing screen
clear

# Post message
echo""
echo -e "${C}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++${X}"
echo -e "${C}++++++++++++++++++${X} Laptop-Hibernation ${C}+++++++++++++++++++${X}"
echo -e "${C}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++${X}"
echo""

# Ask for continue script
echo -e "This script will add the required lines into"
echo "-----"
echo -e "${R}'/etc/systemd/logind.conf'${X}"
echo "-----"
echo -e "to use a laptop as an PVE host"
echo ""
echo -e "${INFO}${Y}Run script now? (y/N)${X}"
read run_script
echo ""

if [[ "$run_script" =~ ^[Yy]$ ]]; then
		echo -e "${OK}${G}Running...${X}"
  		echo ""
    else
		echo -e "${NOTOK}${R}Stopping...${X}"
		exit 1
fi

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "${WARN}${R}This script must be run as root!${X}"
    exit 1
fi

echo -e "${G}Configuring Proxmox for laptop usage...${X}"

# Disable hibernation and suspend when closing the lid
echo -e "${Y}Disabling hibernation and suspend on lid close...${X}"
echo ""

CONFIG_FILE="/etc/systemd/logind.conf"

# Backup the original configuration file
cp $CONFIG_FILE ${CONFIG_FILE}.bak

# Remove existing lid switch settings
sed -i '/^HandleLidSwitch=/d' $CONFIG_FILE
sed -i '/^HandleLidSwitchExternalPower=/d' $CONFIG_FILE
sed -i '/^HandleLidSwitchDocked=/d' $CONFIG_FILE

# Apply new settings
echo -e "HandleLidSwitch=ignore" >> $CONFIG_FILE
echo "HandleLidSwitchExternalPower=ignore" >> $CONFIG_FILE
echo "HandleLidSwitchDocked=ignore" >> $CONFIG_FILE

# Restart systemd-logind to apply changes
systemctl restart systemd-logind

echo -e "${OK}${G}Proxmox laptop configuration completed!${X}"
