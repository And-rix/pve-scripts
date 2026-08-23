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
  err "ERROR: This script must be run as root inside the container."
  exit 1
fi

# Post message
create_header "Add-on: Tailscale-Watchdog"

# User confirmation
ask_user_confirmation
clear
create_header "Add-on: Tailscale-Watchdog"

msg "Running environment checks..."

# 1. Check if running inside an LXC container
if [ ! -f /.dockerenv ] && [ ! -e /run/systemd/container ]; then
    err "ERROR: This script must be executed inside an LXC container!"
    err "Aborting to prevent host modification."
    exit 1
fi

# 2. Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    err "ERROR: Tailscale is not installed in this container!"
    err "Please install Tailscale before running this watchdog setup."
    exit 1
fi

msg "Environment checks passed (LXC container & Tailscale verified)."

# Update system and install dependencies
spinner_run "Installing dependencies (jq, cron)" bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y jq cron
"

# Create watchdog script
spinner_run "Creating watchdog script (/usr/local/bin/tailscale-watchdog.sh)" bash -c "
cat << 'EOF' > /usr/local/bin/tailscale-watchdog.sh
#!/usr/bin/env bash

LOGFILE=\"/var/log/tailscale-watchdog.log\"

echo \"\$(date): Checking Tailscale peers...\" >> \"\$LOGFILE\"

# Extract all online peers using jq
PEERS=\$(tailscale status --json | jq -r '.Peer[] | select(.Online==true) | .TailscaleIPs[0]' 2>/dev/null)

# Choose a random peer from the list
RANDOM_PEER=\$(echo \"\$PEERS\" | shuf -n1)

if [ -z \"\$RANDOM_PEER\" ]; then
    echo \"\$(date): No online peers found in Tailnet!\" >> \"\$LOGFILE\"
    systemctl restart tailscaled
    echo \"\$(date): Restart completed.\" >> \"\$LOGFILE\"
    exit 0
fi

# Connectivity check: 2 attempts with a short break
SUCCESS=0
for i in 1 2; do
    if ping -c 2 -W 2 \"\$RANDOM_PEER\" >/dev/null 2>&1; then
        SUCCESS=1
        break
    else
        sleep 5
    fi
done

if [ \"\$SUCCESS\" -eq 0 ]; then
    echo \"\$(date): Peer \$RANDOM_PEER not reachable. Restarting tailscaled...\" >> \"\$LOGFILE\"
    systemctl restart tailscaled
    echo \"\$(date): Restart completed.\" >> \"\$LOGFILE\"
else
    echo \"\$(date): Peer \$RANDOM_PEER reachable.\" >> \"\$LOGFILE\"
fi

# Log rotation: Keep only the last 500 lines
tail -n 500 \"\$LOGFILE\" > \"\$LOGFILE.tmp\" && mv \"\$LOGFILE.tmp\" \"\$LOGFILE\"
EOF

chmod +x /usr/local/bin/tailscale-watchdog.sh
"

# Set up the Cronjob
spinner_run "Scheduling cronjob (every 10 minutes)" bash -c "
    systemctl enable --now cron 2>/dev/null || systemctl enable --now crond 2>/dev/null || true
    CRON_JOB=\"*/10 * * * * /usr/local/bin/tailscale-watchdog.sh > /dev/null 2>&1\"
    (crontab -l 2>/dev/null | grep -Fq \"\$CRON_JOB\") || (crontab -l 2>/dev/null; echo \"\$CRON_JOB\") | crontab -
"

echo -e "\n${C_GREEN}============================================================${C_RESET}"
echo -e "${C_GREEN} Tailscale Watchdog installed successfully!${C_RESET}"
echo -e "${C_GREEN}============================================================${C_RESET}"
echo -e " Watchdog schedule: Every 10 minutes"
echo -e " Script location:   /usr/local/bin/tailscale-watchdog.sh"
echo -e " Log location:      /var/log/tailscale-watchdog.log"
echo -e " Cron configuration: crontab -e"
echo -e "${C_GREEN}============================================================${C_RESET}\n"