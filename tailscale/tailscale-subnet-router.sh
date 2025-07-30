#!/bin/bash

# MIT License
# Copyright (c) 2025 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

export LANG=en_US.UTF-8

# Import Misc
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/misc.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/tailscale/ts-functions.sh)

# Post message
create_header "Tailscale-Subnet-Router"

# Sleep
sleep 1

# Info
ask_user_confirmation

# Set LXC root Password
prompt_password
echo -e "${C}Password successfully set...${X}"
line

# LXC Config
echo -e "${C}Configuring Proxmox environment...${X}"
line
config_tailscale_lxc

# Check if bridge exists
if ! grep -q "$BRIDGE" /etc/network/interfaces && ! brctl show | grep -q "$BRIDGE"; then
  echo -e "${R}Network bridge '$BRIDGE' not found. Aborting.${X}"
  exit 1
fi

dl_template_ubuntu > /dev/null 2>&1
create_tailscale_lxc > /dev/null 2>&1

# Step
create_header "Tailscale-Subnet-Router"

# Adjust LXC config for Tailscale and enable autostart
echo -e "${C}Adjusting LXC configuration for Tailscale...${X}"
line
LXC_CONF="/etc/pve/lxc/${CT_ID}.conf"
cat <<EOF >> $LXC_CONF
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
pct start $CT_ID > /dev/null 2>&1
sleep 5

# Run post-setup commands inside container with spinner
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

# Step
create_header "Tailscale-Subnet-Router"

echo -e "${G}[OK]${C} Updates and installation completed.${X}"
line

# Enter Subnet for Tailscale
while true; do
  SUBNET=$(whiptail --title "Tailscale Subnet" \
    --inputbox "Please enter the subnet (e.g. 192.168.178.0/24):" 10 60 3>&1 1>&2 2>&3) || exit 1

  if ! validate_subnet "$SUBNET"; then
    whiptail --title "Invalid Subnet" --msgbox "Invalid subnet format! Please enter again." 8 60
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

echo -e "${G}[OK]${C} Valid subnet entered:${X} $SUBNET"
line

echo -e "${G}[OK]${C} Container${X} $CT_ID ${C}is ready.${X}"
line

echo -e "${Y}[ATTENTION]${X} Login URL prompted in the console, now..."
line

# Run tailscale up command directly from host in container
pct exec "$CT_ID" -- tailscale up --advertise-routes="$SUBNET" --accept-routes | \
grep -v "UDP GRO forwarding" | \
grep -v "https://tailscale.com/s/ethtool-config-udp-gro"
line 

whiptail --title "Finish" --msgbox "\
You need to approve the subnet route in your Tailscale machines:
---
Machine (tailscale) > Settings (•••) > Edit route settings... > Approve
---
https://login.tailscale.com/admin/machines
" 12 80
