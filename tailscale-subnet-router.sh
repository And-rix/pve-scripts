#!/bin/bash

# MIT License
# Copyright (c) 2025 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

export LANG=en_US.UTF-8

# Import Misc
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/colors.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/emojis.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/functions.sh)

# Clearing screen
clear

# Post message
create_header "Tailscale-Subnet-Router"

# Info
echo -e "${CONSOLE}This script will automatically install:"
line
echo -e "${C}LXC Container (ubuntu-22.04)${X}"
echo -e "${C}Tailscale subnet router${X}"
line
echo -e "${INFO}You will be asked to enter your local subnet later."
echo ""
continue_script

# Prompt for LXC container password with validation
echo ""
echo -e "${C}Please enter a password for the container user 'root' (min. 5 characters):${X}"

while true; do
  read -s -p "Password: " PASSWORD
  echo ""
  read -s -p "Confirm Password: " PASSWORD_CONFIRM
  echo ""

  if [[ -z "$PASSWORD" || ${#PASSWORD} -lt 5 ]]; then
    echo -e "${R}Password must be at least 5 characters long.${X}"
  elif [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
    echo -e "${R}Passwords do not match. Please try again.${X}"
  else
    break
  fi
  echo ""
done

clear

line
echo -e "${C}Configuring Proxmox environment...${X}"
line

config_tailscale_lxc

# Check if bridge exists
if ! grep -q "$BRIDGE" /etc/network/interfaces && ! brctl show | grep -q "$BRIDGE"; then
  echo -e "${R}Network bridge '$BRIDGE' not found. Aborting.${X}"
  exit 1
fi

dl_template_ubuntu
create_tailscale_lxc

clear

# Adjust LXC config for Tailscale and enable autostart
line
echo -e "${C}Adjusting LXC configuration for Tailscale...${X}"
line
LXC_CONF="/etc/pve/lxc/${CT_ID}.conf"
cat <<EOF >> $LXC_CONF

# Tailscale settings
lxc.cap.drop =
lxc.apparmor.profile = unconfined
lxc.cgroup.devices.allow = a
lxc.mount.auto = proc:rw sys:rw
lxc.mount.entry = /dev/net/tun dev/net/tun none bind,create=file
EOF

# Restart container
echo -e "${C}Restarting container...${X}"
line
pct stop $CT_ID
sleep 2
pct start $CT_ID
sleep 5

clear

# Run post-setup commands inside container with spinner
line
echo -e "${C}Running updates and Tailscale install...${X}"
line

pct exec $CT_ID -- bash -c "
  apt update && apt upgrade -y
  apt install -y curl
  curl -fsSL https://tailscale.com/install.sh | sh

  sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
  grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

  sed -i 's|#net.ipv6.conf.all.forwarding=1|net.ipv6.conf.all.forwarding=1|' /etc/sysctl.conf
  grep -q '^net.ipv6.conf.all.forwarding=1' /etc/sysctl.conf || echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf

  sysctl -p
" > /dev/null 2>&1 &

PID=$!
show_spinner $PID
wait $PID

echo ""
echo ""
line
echo -e "${G}[OK]${X} Updates and installation completed."

# Final user instruction
line
echo ""
echo -e "${C}Please enter the subnet for Tailscale ${Y}(e.g. 192.168.10.0/24):${X}"
read SUBNET
while ! validate_subnet "$SUBNET"; do
  echo -e "${R}Invalid subnet format! Please enter again.${X}"
  read SUBNET
done
line
echo -e "${R}Manual Tailscale login required:${X}"
echo -e "Automatically running this command inside the container:"
echo ""
echo -e "${C}pct exec $CT_ID -- tailscale up --advertise-routes=$SUBNET --accept-routes${X}"
echo ""
echo -e "If the command fails or you want to login interactively later, run the above manually."
line
echo -e "${G}[OK]${X} Container $CT_ID is ready."
line

# Run tailscale up command directly from host in container
pct exec $CT_ID -- tailscale up --advertise-routes=$SUBNET --accept-routes
line 
