#!/bin/bash

# Script Name: vdsm-arc-update.sh
# Author: And-rix (https://github.com/And-rix)
# Version: v1.2 - 26.05.2025
# Creation: 23.05.2025

export LANG=en_US.UTF-8

# Import Misc
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/colors.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/emojis.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/functions.sh)

# Clearing screen
clear

# Post message
echo ""
echo -e "${C}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++${X}"
echo -e "${C}++++++++++++++++++++${X} VDSM.Arc-Update ${C}++++++++++++++++++++${X}"
echo -e "${C}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++${X}"
echo ""

# Continue Script?
echo -e "${INFO}${C}This tool can only update an existing vDSM.Arc VM${X}"
echo "-----"
echo -e "${C}vDSM.Arc will be mapped as SATA0${X}"
echo -e "${R}> Do NOT change this! <${X}"
echo "-----"
echo ""
continue_script

while true; do
    # Display list of all VMs
    echo ""
    echo -e "${C}List of all VMs:${X}"
    echo "-------------------------"
    LIST_ALL_VMS
    echo "-------------------------"
    echo ""

    # Ask for VM ID
    echo -e "${C}Please enter the VM ID (example: 101): ${X}"
    read -r VM_ID

    # Check VM exists
    if CHECK_VM_EXISTS "$VM_ID"; then
        echo ""
        echo -e "${OK}${G}The VM with ID $VM_ID exists. Starting precheck...${X}"
        break
    else
        echo ""
        echo -e "${NOTOK}${R}The VM with ID $VM_ID does not exist. Please try again.${X}"
    fi
done

# Check the VM status
STATUS=$(qm status $VM_ID | awk '{print $2}')

# VM is turned on > exit
vm_status

# VM is turned off
echo -e "${OK}${G}VM is shut down. Starting...${X}"
echo "------"
# Storage locations > support images
STORAGES=$(pvesm status -content images | awk 'NR>1 {print $1}')

# Check if storages exist
if [ -z "$STORAGES" ]; then
    echo -e "${NOTOK}${R}No storage locations found that support disk images.${X}"
    exit 1
fi

# Storage Options
echo -e "${DISK}${C}Please select target Storage for Arc install (SATA0):${X}"
select STORAGE in $STORAGES; do
    if [ -n "$STORAGE" ]; then
        echo -e "${G}You selected: $STORAGE${X}"
        break
    else
        echo -e "${R}Invalid selection. Please try again.${G}"
    fi
done

# Check for 'unzip' and 'wget' > install if not
unzip_check_install
 
# Target directories
ISO_STORAGE_PATH="/var/lib/vz/template/iso"
DOWNLOAD_PATH="/var/lib/vz/template/tmp"

mkdir -p "$DOWNLOAD_PATH"

# Latest .img.zip from GitHub
arc_release_url
LATEST_FILENAME=$(basename "$LATEST_RELEASE_URL")

if [ -f "$DOWNLOAD_PATH/$LATEST_FILENAME" ]; then
    echo -e "${G}The latest file ($LATEST_FILENAME) is already present.${X}"
	echo -e "${G}Skipping download...${X}"
else
    echo -e "${G}Downloading the latest file ($LATEST_FILENAME)...${X}"
    wget -O "$DOWNLOAD_PATH/$LATEST_FILENAME" "$LATEST_RELEASE_URL"
fi

# Extract the file
echo -e "${Y}Extracting $LATEST_FILENAME...${X}"
unzip -o "$DOWNLOAD_PATH/$LATEST_FILENAME" -d "$ISO_STORAGE_PATH"

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

# Existing SATA0 deletion
qm set $VM_ID -delete sata0

# Import the disk image to the specified storage
IMPORT_OUTPUT=$(qm importdisk "$VM_ID" "$NEW_IMG_FILE" "$STORAGE")

# Extract the volume ID from the output (e.g., local-lvm:vm-105-disk-2)
VOLUME_ID=$(echo "$IMPORT_OUTPUT" | grep -oP "(?<=successfully imported disk ')[^']+")

# Check if extraction was successful
if [ -z "$VOLUME_ID" ]; then
  echo -e "${NOTOK}${R}Failed to extract volume ID from import output.${X}"
  echo -e "${R}Output was: $IMPORT_OUTPUT${X}"
  exit 1
fi

echo -e "${G} Disk imported: $VOLUME_ID${X}"

# Attach the imported disk to the VM at the specified bus (e.g., sata0)
qm set "$VM_ID" --sata0 "$VOLUME_ID"

echo -e "${G} Disk attached to VM $VM_ID as sata0.${X}"

# Delete temp file?
echo ""
echo -e "${INFO}${Y}Do you want to delete the temp downloaded file${X}"
echo -e "${TAB}${Y}($LATEST_FILENAME)${X} from ${Y}$DOWNLOAD_PATH? (y/Y): ${X}"
read delete_answer
echo ""

if [[ "$delete_answer" =~ ^[Yy]$ ]]; then
    echo "Deleting the file..."
    rm -f "$DOWNLOAD_PATH/$LATEST_FILENAME"
    echo -e "${OK}${G}($LATEST_FILENAME) from '$DOWNLOAD_PATH' deleted.${X}"
else
    echo -e "${NOTOK}${Y}($LATEST_FILENAME) from '$DOWNLOAD_PATH' was not deleted.${X}"
fi

# Success message
echo "------"
echo -e "${OK}${G}VM ID: $VM_ID has been successfully updated!${X}"
echo -e "${OK}${G}SATA0: Imported image (${NEW_IMG_FILE})${X}"
echo "------"
echo -e "${WARN}${Y}Info: Please delete unused disks of the VM by your own!${X}"
echo ""
exit 0
