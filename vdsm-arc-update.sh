#!/bin/bash

# Script Name: vdsm-arc-update.sh
# Author: And-rix (https://github.com/And-rix)
# Version: v1.4 - 02.07.2025
# Creation: 23.05.2025

export LANG=en_US.UTF-8

# Import Misc
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/colors.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/emojis.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/functions.sh)

# Clearing screen
clear

# Post message
create_header "vDSM-Arc-Update"

# Info
echo -e "${INFO}${C}This tool can only update an existing vDSM.Arc VM${X}"
line
echo -e "${C}Boot image will be replaced. ${R}> Loader re-build is required. ${X}"
echo -e "${C}vDSM.Arc will be mapped as SATA0. ${R}> Do NOT CHANGE!${X}"
line
echo ""
continue_script

# VM list promt
vm_list_promt

# Check the VM status
vm_check_status

# VM is turned on > exit
vm_status

# Storage locations
pve_storages

# Check if storages exist
if [ -z "$STORAGES" ]; then
    echo -e "${NOTOK}${R}No storage locations found that support disk images.${X}"
    exit 1
fi

# Storage Options
echo -e "${DISK}${C}Please select target Storage for Arc install (SATA0):${X}"
select STORAGE in $STORAGES; do
    if [ -n "$STORAGE" ]; then
        echo ""
        echo -e "${C}You selected:${X} $STORAGE"
        line
        break
    else
        echo -e "${R}Invalid selection. Please try again.${X}"
    fi
done

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
  echo -e "${NOTOK}${R}Failed to extract volume ID from import output.${X}"
  echo -e "${R}Output was: $IMPORT_OUTPUT${X}"
  exit 1
fi

# echo -e "${G} Disk imported: $VOLUME_ID${X}"

# Attach the imported disk to the VM at the specified bus (e.g., sata0)
qm set "$VM_ID" --sata0 "$VOLUME_ID"

# Set notes to VM
NOTES_HTML=$(vm_notes_html)
qm set "$VM_ID" --description "$NOTES_HTML"

# Spinner group
}> /dev/null 2>&1

clear

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
line
echo -e "${OK}${G}VM ID: $VM_ID has been successfully updated!${X}"
echo -e "${OK}${G}Image: Imported image (${NEW_IMG_FILE})${X}"
echo -e "${OK}${G}SATA0: Attached disk (${VOLUME_ID})${X}"
line
echo -e "${WARN}${Y}Info: Please delete unused disks of the VM by your own!${X}"
echo ""
exit 0
