#!/bin/bash

# MIT License
# Copyright (c) 2025 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

export LANG=en_US.UTF-8

# Import misc functions
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/misc.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm/vdsm-functions.sh)

# Header
create_header "vDSM-Arc-Update"
sleep 1

# User confirmation
ask_user_confirmation

# Info message
whiptail --title "vDSM-Arc Update" --msgbox \
"Please select the VM in the next step.
---
The boot image will be replaced.
A loader rebuild will be required.
---
The new boot image will be mapped to SATA0.
The existing SATA0 disk will be preserved as an 'unused disk'." 16 60

# VM selection
vm_list_prompt

# Check the VM status
vm_check_status

# VM is turned on > exit
vm_status

# Storage locations
pve_storages

# Check for 'unzip' and 'wget' > install if not
unzip_check_install
 
# Target directories
ISO_STORAGE_PATH="/var/lib/vz/template/iso"
DOWNLOAD_PATH="/var/lib/vz/template/tmp"

mkdir -p "$DOWNLOAD_PATH"

# Latest .img.zip from GitHub
arc_release_choice
arc_release_download

# Extract the file
unzip_img

# Extract the version number from the filename
VERSION=$(echo "$LATEST_FILENAME" | grep -oP "\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?")

# Rename arc.img to arc-[VERSION].img
if [ -f "$ISO_STORAGE_PATH/arc.img" ]; then
    NEW_IMG_FILE="$ISO_STORAGE_PATH/arc-${VERSION}.img"
    mv "$ISO_STORAGE_PATH/arc.img" "$NEW_IMG_FILE"
else
    echo -e "${R}Error: No extracted arc.img found!${X}"
    exit 1
fi

# Spinner group
{
    # Existing SATA0 deletion
    qm set $VM_ID -delete sata0

    # Import the disk image to the specified storage
    IMPORT_OUTPUT=$(qm importdisk "$VM_ID" "$NEW_IMG_FILE" "$STORAGE")

    # Extract the volume ID from the output (e.g., local-lvm:vm-105-disk-2)
    VOLUME_ID=$(echo "$IMPORT_OUTPUT" | grep -oP "(?<=successfully imported disk ')[^']+")

    # Check if extraction was successful
    if [ -z "$VOLUME_ID" ]; then
      echo -e "${R}[!] Failed to extract volume ID from import output.${X}"
      echo -e "${R}Output: $IMPORT_OUTPUT${X}"
      exit 1
    fi

    # Attach the imported disk to the VM at the specified bus (e.g., sata0)
    qm set "$VM_ID" --sata0 "$VOLUME_ID"

    # Set boot order to SATA0 only, disable all other devices
    qm set "$VM_ID" --boot order=sata0
    qm set "$VM_ID" --bootdisk sata0
    qm set "$VM_ID" --onboot 1

    # Set notes to VM
    # NOTES_HTML=$(vm_notes_html)
    # qm set "$VM_ID" --description "$NOTES_HTML"

# Spinner group
}> /dev/null 2>&1 &

SPINNER_PID=$!
show_spinner $SPINNER_PID

# Step
create_header "vDSM-Arc-Update"

# Delete temp file?
confirm_delete_temp_file
line

# Success message
echo -e "${G}[OK] ${C}(ID: $VM_ID) has been successfully updated!${X}"
echo -e "${G}[OK] ${C}SATA0: img (${NEW_IMG_FILE})${X}"
echo -e "${Y}[i] ${C}Please delete unused disks of the VM by your own!${X}"
line
