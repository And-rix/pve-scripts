#!/bin/bash
# ============================================================================
# MIT License
# Copyright (c) 2026 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE
# ============================================================================

# Prompt for LXC container root password via Whiptail
prompt_password() {
  while true; do
    PASSWORD=$(whiptail --title "Set Password" --passwordbox "Enter a password for the container (min. 5 characters):" 10 60 3>&1 1>&2 2>&3) || exit 1
    PASSWORD_CONFIRM=$(whiptail --title "Confirm Password" --passwordbox "Re-enter the password to confirm:" 10 60 3>&1 1>&2 2>&3) || exit 1

    if [[ -z "$PASSWORD" || ${#PASSWORD} -lt 5 ]]; then
      whiptail --title "Invalid Password" --msgbox "Password must be at least 5 characters long." 8 60
    elif [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
      whiptail --title "Password Mismatch" --msgbox "Passwords do not match. Please try again." 8 60
    else
      break
    fi
  done
}

# Download Ubuntu template if missing
dl_template_ubuntu() {
  local template_storage="${TEMPLATE_STORAGE:-local}"
  if ! pveam list "$template_storage" 2>/dev/null | grep -q "ubuntu-22.04-standard_22.04-1_amd64"; then
    pveam download "$template_storage" ubuntu-22.04-standard_22.04-1_amd64.tar.zst
  fi
}

# Set container variables
config_tailscale_lxc() {
  CT_ID=$(pvesh get /cluster/nextid)
  HOSTNAME_CT="${HOSTNAME_CT:-tailscale}"
  TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"
  TEMPLATE="${TEMPLATE_STORAGE}:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  NET_IF="${NET_IF:-eth0}"
  BRIDGE="${BRIDGE:-vmbr0}"
  CT_MEMORY="${CT_MEMORY:-1024}"
  CT_SWAP="${CT_SWAP:-0}"
  CT_CORES="${CT_CORES:-1}"
  DISK_SIZE="${DISK_SIZE:-10}"

  # Auto-detect a storage that supports container root filesystems, unless
  # explicitly overridden. Falls back to 'local-lvm' if detection fails.
  if [[ -z "${ROOTFS_STORAGE:-}" ]]; then
    ROOTFS_STORAGE=$(pvesm status -content rootdir 2>/dev/null | awk 'NR==2{print $1}')
    if [[ -z "$ROOTFS_STORAGE" ]]; then
      ROOTFS_STORAGE="local-lvm"
    fi
  fi
}

# Create LXC container
create_tailscale_lxc() {
  pct create "$CT_ID" "$TEMPLATE" \
    --hostname "$HOSTNAME_CT" \
    --password "$PASSWORD" \
    --unprivileged 1 \
    --features nesting=1,keyctl=1 \
    --net0 name="$NET_IF",bridge="$BRIDGE",ip=dhcp \
    --memory "$CT_MEMORY" \
    --swap "$CT_SWAP" \
    --cores "$CT_CORES" \
    --rootfs "${ROOTFS_STORAGE}:${DISK_SIZE}" \
    --start 1

  pct set "$CT_ID" --onboot 1
}

# Validate subnet CIDR format
validate_subnet() {
  local ip=$1
  if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
    IFS='/' read -r addr mask <<< "$ip"
    IFS='.' read -r o1 o2 o3 o4 <<< "$addr"
    # Force base-10 interpretation so octets with a leading zero (e.g. "008")
    # aren't misread as invalid octal literals by bash's arithmetic evaluator.
    if (( 10#$o1 <= 255 && 10#$o2 <= 255 && 10#$o3 <= 255 && 10#$o4 <= 255 && 10#$mask <= 32 )); then
      return 0
    fi
  fi
  return 1
}