#!/bin/bash
# ============================================================================
# MIT License
# Copyright (c) 2026 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE
# ============================================================================

set -euo pipefail

export LANG=en_US.UTF-8

# Import external functions
source <(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/misc/misc.sh)

if [[ $EUID -ne 0 ]]; then
  err "Please run as root on the Proxmox host."
  exit 1
fi

# Post message
create_header "PVE-Laptop-Hibernation"

# User confirmation
ask_user_confirmation

whiptail --title "PVE Laptop Configuration" --msgbox \
"This script configures your laptop for Proxmox VE usage.

It modifies the following file:
  /etc/systemd/logind.conf

Lid-close behavior will be disabled to prevent
unexpected suspend or hibernation.

A backup of the original config will be created automatically." 14 60

msg "Configuring Proxmox VE for laptop usage..."

# Apply logind changes
spinner_run "Updating systemd logind configuration" bash -c "
  CONFIG_FILE='/etc/systemd/logind.conf'

  # Ensure the config file exists (should always be shipped with systemd,
  # but guard against an unusual/minimal system just in case)
  [ -f \"\$CONFIG_FILE\" ] || touch \"\$CONFIG_FILE\"

  # Back up the ORIGINAL configuration only once. On repeated runs, don't
  # overwrite an existing backup with the already-modified file.
  [ -f \"\${CONFIG_FILE}.bak\" ] || cp -f \"\$CONFIG_FILE\" \"\${CONFIG_FILE}.bak\"

  # Remove existing lid switch settings
  sed -i '/^HandleLidSwitch=/d' \"\$CONFIG_FILE\"
  sed -i '/^HandleLidSwitchExternalPower=/d' \"\$CONFIG_FILE\"
  sed -i '/^HandleLidSwitchDocked=/d' \"\$CONFIG_FILE\"

  # Apply ignore settings
  echo 'HandleLidSwitch=ignore' >> \"\$CONFIG_FILE\"
  echo 'HandleLidSwitchExternalPower=ignore' >> \"\$CONFIG_FILE\"
  echo 'HandleLidSwitchDocked=ignore' >> \"\$CONFIG_FILE\"
"

spinner_run "Restarting systemd-logind service" systemctl restart systemd-logind

echo -e "\n${C_GREEN}============================================================${C_RESET}"
echo -e "${C_GREEN} Proxmox VE Laptop configuration completed!${C_RESET}"
echo -e "${C_GREEN}============================================================${C_RESET}"
echo -e " Target file:     /etc/systemd/logind.conf"
echo -e " Backup created: /etc/systemd/logind.conf.bak"
echo -e " Lid-close actions set to 'ignore'."
echo -e "${C_GREEN}============================================================${C_RESET}\n"