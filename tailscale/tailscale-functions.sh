#!/bin/bash
# ============================================================================
# MIT License
# Copyright (c) 2026 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE
# ============================================================================

# ---------- Spinner / Loading Helper ----------
spinner_run() {
  local label="$1"
  shift
  local logfile
  logfile=$(mktemp /tmp/tailscale-task-XXXXXX.log)

  echo -ne "  ${C_BLUE}[-]${C_RESET} ${label} "

  ( "$@" ) > "$logfile" 2>&1 &
  local pid=$!
  local spinstr='|/-\'
  local delay=0.1

  while kill -0 "$pid" 2>/dev/null; do
    local temp=${spinstr#?}
    printf "[%c]" "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b"
  done

  wait "$pid"
  local status=$?

  if [ $status -eq 0 ]; then
    printf "\r  ${C_GREEN}[✓]${C_RESET} ${label}\n"
    rm -f "$logfile"
  else
    printf "\r  ${C_RED}[X]${C_RESET} ${label}\n"
    err "Error executing: ${label}"
    echo -e "${C_YELLOW}--- Log / Error Output ---${C_RESET}"
    cat "$logfile" >&2
    echo -e "${C_YELLOW}--------------------------${C_RESET}"
    rm -f "$logfile"
    exit $status
  fi
}

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
  if ! pveam list local 2>/dev/null | grep -q "ubuntu-22.04-standard_22.04-1_amd64"; then
    pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
  fi
}

# Set container variables
config_tailscale_lxc() {
  CT_ID=$(pvesh get /cluster/nextid)
  HOSTNAME="tailscale"
  TEMPLATE="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  NET_IF="eth0"
  BRIDGE="vmbr0"
}

# Create LXC container
create_tailscale_lxc() {
  pct create "$CT_ID" "$TEMPLATE" \
    --hostname "$HOSTNAME" \
    --password "$PASSWORD" \
    --unprivileged 1 \
    --features nesting=1,keyctl=1 \
    --net0 name="$NET_IF",bridge="$BRIDGE",ip=dhcp \
    --memory 1024 \
    --swap 0 \
    --cores 1 \
    --rootfs local-lvm:10 \
    --start 1

  pct set "$CT_ID" --onboot 1
}

# Validate subnet CIDR format
validate_subnet() {
  local ip=$1
  if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
    IFS='/' read -r addr mask <<< "$ip"
    IFS='.' read -r o1 o2 o3 o4 <<< "$addr"
    if (( o1 <= 255 && o2 <= 255 && o3 <= 255 && o4 <= 255 && mask <= 32 )); then
      return 0
    fi
  fi
  return 1
}