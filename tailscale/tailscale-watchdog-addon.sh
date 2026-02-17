#!/bin/bash

# MIT License
# Copyright (c) 2026 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

export LANG=en_US.UTF-8

# Import misc functions
source <(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/misc/misc.sh)

# Post message
create_header "Add-on: Tailscale-Watchdog"

# Sleep
sleep 1

# Info
ask_user_confirmation
clear
create_header "Add-on: Tailscale-Watchdog"

# Safety check (LXC, tailscale)

echo -e "${C}Running environment checks...${X}"
line

# 1. Check if running inside an LXC container
# In Proxmox LXCs, /proc/1/environ usually contains 'container=lxc' 
# or the file /run/systemd/container exists.
if [ ! -f /.dockerenv ] && [ ! -e /run/systemd/container ]; then
    echo -e "${NOTOK}${R} ERROR: This script must be run inside an LXC container! ${X}"
    echo -e "${INFO} Aborting to prevent accidental host modification. ${X}"
    line
    exit 1
fi

# 2. Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo -e "${NOTOK}${R} ERROR: Tailscale is not installed in this container! ${X}"
    echo -e "${INFO} Please install Tailscale before running this watchdog setup. ${X}"
    line
    exit 1
fi

echo -e "${OK}${G} Environment checks passed. ${X}"
echo -e "${OK}${G} LXC detected & Tailscale installed. ${X}"
line

# Update system and install dependencies
echo -e "${C}Installing updates and dependencies (jq)... ${X}"
line
apt update && apt install -y jq
line

# 2. Create the watchdog script
echo -e "${C}Creating watchdog at /usr/local/bin/tailscale-watchdog.sh... ${X}"
line

cat << 'EOF' > /usr/local/bin/tailscale-watchdog.sh
#!/bin/bash

LOGFILE="/var/log/tailscale-watchdog.log"

echo "$(date): Checking Tailscale peers..." >> "$LOGFILE"

# Extract all online peers using jq
PEERS=$(tailscale status --json | jq -r '.Peer[] | select(.Online==true) | .TailscaleIPs[0]' 2>/dev/null)

# Choose a random peer from the list
RANDOM_PEER=$(echo "$PEERS" | shuf -n1)

if [ -z "$RANDOM_PEER" ]; then
    echo "$(date): No online peers found in Tailnet!" >> "$LOGFILE"
    systemctl restart tailscaled
    echo "$(date): Restart done." >> "$LOGFILE"
    exit 0
fi

# Connectivity check: 2 attempts with a short break
SUCCESS=0
for i in 1 2; do
    if ping -c 2 -W 2 "$RANDOM_PEER" >/dev/null 2>&1; then
        SUCCESS=1
        break
    else
        sleep 5
    fi
done

if [ "$SUCCESS" -eq 0 ]; then
    echo "$(date): Peer $RANDOM_PEER not reachable. Restarting tailscaled..." >> "$LOGFILE"
    systemctl restart tailscaled
    echo "$(date): Restart done." >> "$LOGFILE"
else
    echo "$(date): Peer $RANDOM_PEER reachable." >> "$LOGFILE"
fi

# Log rotation: Keep only the last 500 lines
tail -n 500 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
EOF

# 3. Make the script executable
chmod +x /usr/local/bin/tailscale-watchdog.sh

# 4. Set up the Cronjob
CRON_JOB="*/10 * * * * /usr/local/bin/tailscale-watchdog.sh > /dev/null 2>&1"
(crontab -l 2>/dev/null | grep -Fq "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo -e "${OK}${G}Setup complete...${X}"
echo -e "${OK}${G}Watchdog scheduled to run every 10 min.${X}"
line
echo -e "${INFO}${C}Logs: /var/log/tailscale-watchdog.log ${X}"
echo -e "${INFO}${C}Script: /usr/local/bin/tailscale-watchdog.sh ${X}"
echo -e "${INFO}${C}Cronjob: crontab -e ${X}"
line