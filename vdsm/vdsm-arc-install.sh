#!/bin/bash

# MIT License
# Copyright (c) 2025 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

export LANG=en_US.UTF-8

# Import Misc
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/misc.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/vdsm/vdsm-functions.sh)

# Post message
create_header "vDSM-Arc-Install"

# Sleep
sleep 1

# Info
ask_user_confirmation

whiptail --title "vDSM-Arc default settings" --msgbox \
"CPU: 2x | Mem: 4096MB | NIC: vmbr0 | Storage: selectable

---

Can be changed after creation!" 12 60

# Storage menu
pve_storages
echo -e "${C}You selected:${X} $STORAGE"
line

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


# VM-ID and configuration
arc_default_vm

# Spinner group
{

# Create the VM 
qm create "$VM_ID" --name "$VM_NAME" --memory "$MEMORY" --cores "$CORES" --cpu "$CPU" --net0 virtio,bridge=vmbr0 --machine "$Q35_VERSION"

# Set VirtIO-SCSI as the default controller
qm set "$VM_ID" --scsihw virtio-scsi-single

# Delete scsi0 if it exists
if qm config "$VM_ID" | grep -q "scsi0"; then
    qm set "$VM_ID" --delete scsi0
fi

# Import image
qm importdisk "$VM_ID" "$NEW_IMG_FILE" "$STORAGE"

# Check storage type
STORAGE_TYPE=$(pvesm status | awk -v s="$STORAGE" '$1 == s {print $2}')
echo -e "$STORAGE_TYPE"

# Disk format > block/file based
if [[ "$STORAGE_TYPE" == "dir" || "$STORAGE_TYPE" == "nfs" || "$STORAGE_TYPE" == "cifs" || "$STORAGE_TYPE" == "btrfs" ]]; then
    qm set "$VM_ID" --sata0 "$STORAGE:$VM_ID/vm-$VM_ID-disk-0.raw" # file-based 
else
	qm set "$VM_ID" --sata0 "$STORAGE:vm-${VM_ID}-disk-0" # block-based 
fi

# Enable QEMU Agent
qm set "$VM_ID" --agent enabled=1

# Set boot order to SATA0 only, disable all other devices
qm set "$VM_ID" --boot order=sata0
qm set "$VM_ID" --bootdisk sata0
qm set "$VM_ID" --onboot 1

# Disable all other boot devices
qm set "$VM_ID" --ide0 none
qm set "$VM_ID" --net0 virtio,bridge=vmbr0
qm set "$VM_ID" --cdrom none
qm set "$VM_ID" --delete ide0
qm set "$VM_ID" --delete ide2

# Set notes to VM
NOTES_HTML=$(vm_notes_html)
qm set "$VM_ID" --description "$NOTES_HTML"

# Spinner group
}> /dev/null 2>&1 &

SPINNER_PID=$!
show_spinner $SPINNER_PID

# Step
create_header "vDSM-Arc-Install"

# Delete temp file?
confirm_delete_temp_file
line

# Success message
echo -e "${G}[OK] ${C}$VM_NAME (ID: $VM_ID) has been successfully created!${X}"
echo -e "${G}[OK] ${C}SATA0: img (${NEW_IMG_FILE})${X}"
line

# Storage selection
sata_disk_menu
