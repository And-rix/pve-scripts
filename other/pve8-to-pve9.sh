#!/bin/bash

# MIT License
# Copyright (c) 2025 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

export LANG=en_US.UTF-8

# Import misc functions
source <(curl -fsSL https://raw.githubusercontent.com/And-rix/pve-scripts/main/misc/misc.sh)

# Header
create_header "PVE8-to-PVE9"
sleep 1

# User confirmation
ask_user_confirmation

# Info message
whiptail --title "Proxmox VE 9 Upgrade" --yesno \
"This will upgrade your system from Proxmox VE 8 (Debian Bookworm) to Proxmox VE 9 (Debian Trixie).

⚠️  IMPORTANT:
Ensure that the 'no-subscription' repository is active and reachable.

🧪  RECOMMENDED:
Run 'pve8to9' first to check for potential issues before upgrading.

ℹ️  INFO:
https://pve.proxmox.com/wiki/Upgrade_from_8_to_9

Proceed with upgrade?" 20 80 || {
    line
    echo -e "${Y}[INFO]${X} Upgrade aborted by user."
    echo -e "${Y}[INFO]${X} Run 'pve8to9' before starting the upgrade."
    echo -e "${Y}[INFO]${X} https://pve.proxmox.com/wiki/Upgrade_from_8_to_9"
    line
    exit 1
}

# Root check
if [ "$EUID" -ne 0 ]; then
    echo -e "${R}[ERROR] This script must be run as root.${X}"
    line
    exit 1
fi

# Check Proxmox version >= 8.4.1
echo -e "${C}Checking current Proxmox version...${X}"
line
CURRENT_VERSION=$(pveversion | grep -oP 'pve-manager/\K[0-9]+\.[0-9]+(\.[0-9]+)?')

if [[ -z "$CURRENT_VERSION" ]]; then
    echo -e "${R}[ERROR] Unable to detect Proxmox version. Aborting...${X}"
    line
    exit 1
fi

REQUIRED_VERSION="8.4.1"

dpkg --compare-versions "$CURRENT_VERSION" ge "$REQUIRED_VERSION"
if [ $? -ne 0 ]; then
    echo -e "${Y}Your current PVE ${X}($CURRENT_VERSION) ${Y}is below the required min. ${X}($REQUIRED_VERSION)."
    line
    
    # Ask user if automatic upgrade to latest PVE 8 should be performed
    if command -v whiptail >/dev/null 2>&1; then
        if ! whiptail --title "Upgrade Required" --yesno \
            "Your current Proxmox version is too old for a direct upgrade to VE 9.\n\nUpgrade to the latest VE 8 version now?" 12 60; then
            echo -e "${C}Upgrade aborted by user...${X}"
            line
            exit 1
        fi
    else
        read -rp "Upgrade to latest Proxmox VE 8 before continuing? [y/N]: " confirm_upgrade
        if [[ ! "$confirm_upgrade" =~ ^[Yy]$ ]]; then
            echo -e "${C}Upgrade aborted by user...${X}"
            line
            exit 1
        fi
    fi

    echo -e "${C}Performing system upgrade to latest Proxmox VE 8...${X}"
    line
    apt update && apt upgrade -y
    line

    echo -e "${C}Re-checking Proxmox version after upgrade...${X}"
    line
    CURRENT_VERSION=$(pveversion | grep -oP 'pve-manager/\K[0-9]+\.[0-9]+(\.[0-9]+)?')

    if [[ -z "$CURRENT_VERSION" ]]; then
        echo -e "${R}[ERROR] Unable to detect Proxmox version. Aborting...${X}"
        line
        exit 1
    fi

    dpkg --compare-versions "$CURRENT_VERSION" ge "$REQUIRED_VERSION"
    if [ $? -ne 0 ]; then
        echo -e "${R}Your system is still below the required minimum version ($REQUIRED_VERSION).${X}"
        echo -e "${R}Please upgrade manually before re-running this script.${X}"
        line
        exit 1
    fi

    echo -e "${C}System upgraded to PVE $CURRENT_VERSION — proceeding major upgrade.${X}"
    line
else
    echo -e "${C}Detected Proxmox VE $CURRENT_VERSION — meets minimum requirement.${X}"
    line
fi

# Step 1: Update current system
echo -e "${C}Updating current system (apt update && full-upgrade)...${X}"
line
apt update && apt full-upgrade -y
line

# Step 2: Check if reboot is required
if [ -f /var/run/reboot-required ]; then
    echo -e "${Y}A system reboot is required before proceeding.${X}"
    echo -e "${Y}Please reboot and rerun this script.${X}"
    line
    exit 0
fi

# Step 3: Backup current APT sources
echo -e "${C}Backing up APT sources to /root/repo-backup/...${X}"
line
mkdir -p /root/repo-backup
cp -v /etc/apt/sources.list /root/repo-backup/sources.list.bak
cp -v /etc/apt/sources.list.d/* /root/repo-backup/ 2>/dev/null || true
line
echo -e "${C}Backup completed.${X}"
line

# Step 4: Remove all old repos
echo -e "${C}Removing old APT repository files...${X}"
rm -f /etc/apt/sources.list
rm -f /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources
rm -f /etc/apt/sources.list.d/pve-enterprise.list
rm -f /etc/apt/sources.list.d/ceph.list

# Step 5: Create Debian 13 (Trixie)
cat <<'EOF' > /etc/apt/sources.list.d/debian.sources
Types: deb deb-src
URIs: http://deb.debian.org/debian/
Suites: trixie trixie-updates
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb deb-src
URIs: http://security.debian.org/debian-security/
Suites: trixie-security
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
echo -e "${C}Debian sources configured in deb822 format.${X}"
line

# Step 6: Create Proxmox VE 9 No-Subscription repo 
cat <<'EOF' > /etc/apt/sources.list.d/proxmox.sources
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
echo -e "${C}Proxmox No-Subscription repository configured.${X}"
line

# Step 6.1: Remove Proxmox subscription nag
echo -e "${C}Removing Proxmox subscription nag...${X}"
NAG_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
if [ -f "$NAG_FILE" ]; then
    cp "$NAG_FILE" "${NAG_FILE}.bak"
    sed -i.bak "s/data.status !== 'Active'/false/" "$NAG_FILE"
    echo -e "${Y}Subscription nag removed...${X}"
else
    echo -e "${R}Subscription nag file not found — skipping.${X}"
fi
line

# Step 7: Update package lists
echo -e "${C}Refreshing APT package lists...${X}"
line
apt update
line

# Step 8: Perform dist-upgrade
echo -e "${C}Starting dist-upgrade to Proxmox VE 9...${X}"
line
apt dist-upgrade -y
line
echo -e "${C}Upgrade process completed.${X}"
line

# Step 9: Final message
create_header "PVE8-to-PVE9"
sleep 1
echo -e "${C}The upgrade is complete. Please reboot your system:${X}"
echo -e "${TAB}${Y}reboot${X}"
line
echo -e "${C}APT source backups are stored at:${X}"
echo -e "${TAB}${Y}/root/repo-backup/${X}"
line
echo -e "${C}Debian Trixie Repo added:${X}"
echo -e "${TAB}${Y}/etc/apt/sources.list.d/debian.sources${X}"
echo -e "${C}pve-no-subscription added:${X}"
echo -e "${TAB}${Y}/etc/apt/sources.list.d/proxmox.sources${X}"
line