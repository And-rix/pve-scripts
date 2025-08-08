#!/bin/bash

# MIT License
# Copyright (c) 2025 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

export LANG=en_US.UTF-8

# Import misc functions
source <(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/misc/misc.sh)

# Post message
create_header "PVE-Laptop-Hibernation"

# Sleep
sleep 1

# Info
ask_user_confirmation

whiptail --title "PVE Laptop Configuration" --msgbox \
"This script configures your laptop for Proxmox VE usage.

It modifies the following file:
  /etc/systemd/logind.conf

The lid-close behavior will be disabled to prevent
unexpected suspend or hibernation.

A backup of the original config will be created automatically." 13 60

echo -e "${C}Configuring Proxmox for laptop usage...${X}"
line

# Disable hibernation and suspend when closing the lid
echo -e "${C}Disabling hibernation and suspend on lid close...${X}"
line

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

echo -e "${G}[OK] Proxmox laptop configuration completed!${X}"
