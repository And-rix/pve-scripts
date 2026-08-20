#!/bin/bash
# ============================================================================
# MIT License
# Copyright (c) 2026 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE
# ============================================================================

set -euo pipefail

export LANG=en_US.UTF-8

# Load external functions
source <(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/misc/misc.sh)
source <(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/tailscale/tailscale-functions.sh)

clear
# Post message
create_header "Tailscale-Subnet-Router"

# Confirmation & Password Setup
ask_user_confirmation
prompt_password
msg "Password successfully set."

step "Preparing Proxmox Environment"
config_tailscale_lxc
msg "Assigned Container ID: ${CT_ID}"

# Verify network bridge existence
if ! grep -q "$BRIDGE" /etc/network/interfaces 2>/dev/null && ! brctl show 2>/dev/null | grep -q "$BRIDGE"; then
  err "Network bridge '$BRIDGE' not found. Aborting."
  exit 1
fi

spinner_run "Checking/Downloading Ubuntu OS template" dl_template_ubuntu
spinner_run "Creating Tailscale LXC Container (${CT_ID})" create_tailscale_lxc

step "Applying Tailscale Configurations"

spinner_run "Configuring LXC permissions & TUN device" bash -c "
  LXC_CONF='/etc/pve/lxc/${CT_ID}.conf'
  cat <<EOF >> \$LXC_CONF
lxc.cap.drop =
lxc.apparmor.profile = unconfined
lxc.cgroup2.devices.allow = a
lxc.mount.auto = proc:rw sys:rw
lxc.mount.entry = /dev/net/tun dev/net/tun none bind,create=file
EOF
"

spinner_run "Restarting container (${CT_ID})" bash -c "
  pct stop ${CT_ID}
  sleep 2
  pct start ${CT_ID}
  sleep 3
"

spinner_run "Installing Tailscale & configuring network forwarding" pct exec "$CT_ID" -- bash -c "
  set -e
  apt-get update -y && apt-get upgrade -y
  apt-get install -y curl
  curl -fsSL https://tailscale.com/install.sh | sh

  sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
  grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

  sed -i 's|#net.ipv6.conf.all.forwarding=1|net.ipv6.conf.all.forwarding=1|' /etc/sysctl.conf
  grep -q '^net.ipv6.conf.all.forwarding=1' /etc/sysctl.conf || echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf

  sysctl -p
"

step "Subnet Configuration"

# Prompt user for subnet via Whiptail
while true; do
  SUBNET=$(whiptail --title "Tailscale Subnet" \
    --inputbox "Please enter the subnet (e.g. 192.168.178.0/24):" 10 60 3>&1 1>&2 2>&3) || exit 1

  if ! validate_subnet "$SUBNET"; then
    whiptail --title "Invalid Format" --msgbox "Invalid subnet format! Please try again." 8 60
    continue
  fi

  SUBNET_CONFIRM=$(whiptail --title "Confirm Subnet" \
    --inputbox "Please re-enter the subnet to confirm:" 10 60 3>&1 1>&2 2>&3) || exit 1

  if [[ "$SUBNET" != "$SUBNET_CONFIRM" ]]; then
    whiptail --title "Mismatch" --msgbox "The two entries do not match. Please try again." 8 60
    continue
  fi

  break
done

msg "Valid subnet configured: ${SUBNET}"
msg "Container ${CT_ID} is ready."

echo -e "\n${C_YELLOW}[!] Please authenticate with Tailscale (login link below):${C_RESET}\n"

# Output Tailscale login URL directly in terminal
pct exec "$CT_ID" -- tailscale up --advertise-routes="$SUBNET" --accept-routes | \
grep -v "UDP GRO forwarding" | \
grep -v "https://tailscale.com/s/ethtool-config-udp-gro" || true

whiptail --title "Setup Instructions" --msgbox "\
You need to approve the subnet route in your Tailscale admin console:
---
Machine (tailscale) > Settings (•••) > Edit route settings... > Approve
---
https://login.tailscale.com/admin/machines
" 12 80

echo -e "\n${C_GREEN}============================================================${C_RESET}"
echo -e "${C_GREEN} Tailscale Subnet Router installed successfully!${C_RESET}"
echo -e "${C_GREEN}============================================================${C_RESET}"
echo -e " Container ID:   ${CT_ID}"
echo -e " Subnet Route:   ${SUBNET}"
echo -e " Check status:   pct exec ${CT_ID} -- tailscale status"
echo -e "${C_GREEN}============================================================${C_RESET}\n"