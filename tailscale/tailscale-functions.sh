#!/bin/bash

# MIT License
# Copyright (c) 2026 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

# Function prompt_password
prompt_password() {
  while true; do
    PASSWORD=$(whiptail --title "Set Password" --passwordbox "Enter a password (min. 5 characters):" 10 60 3>&1 1>&2 2>&3) || exit 1
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

# Function show_spinner
show_spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'

  tput civis
	printf "\n"

  while ps -p $pid &> /dev/null; do
	local temp=${spinstr#?}
	printf "\r[ %c ] ${C}Loading...${X}" "$spinstr"
	spinstr=$temp${spinstr%"$temp"}
	sleep $delay
	printf "\b\b\b\b\b\b"
  done
  tput cnorm
}

# Function dl_template_ubuntu
dl_template_ubuntu() {
	if ! pveam list local | grep -q "ubuntu-22.04-standard_22.04-1_amd64"; then
	echo -e "${C}Downloading Ubuntu template...${X}"
	pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
	fi
}

# Function config_tailscale_lxc
config_tailscale_lxc() {
	CT_ID=$(pvesh get /cluster/nextid)
	echo -e "${C}Using container ID: $CT_ID${X}"
	HOSTNAME="tailscale"
	TEMPLATE="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
	NET_IF="eth0"
	BRIDGE="vmbr0"
}

# Function create_tailscale_lxc
create_tailscale_lxc() {
	line
	echo -e "${C}Creating LXC container $CT_ID...${X}"
	line
	pct create $CT_ID $TEMPLATE \
	  	--hostname $HOSTNAME \
  		--password $PASSWORD \
  		--unprivileged 1 \
  		--features nesting=1 \
  		--net0 name=$NET_IF,bridge=$BRIDGE,ip=dhcp \
  		--memory 1024 \
		--swap 0 \
  		--cores 1 \
  		--rootfs local-lvm:10 \
  		--start 1 

	pct set $CT_ID --onboot 1
}

# Function validate_subnet 
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
