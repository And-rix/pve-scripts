#!/bin/bash

# Script Name: vdsm-arc-install.sh
# Author: And-rix (https://github.com/And-rix)
# Version: v3.3 - 06.06.2025
# Creation: 18.02.2025 

export LANG=en_US.UTF-8

# Import Misc
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/colors.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/emojis.sh)
source <(curl -s https://raw.githubusercontent.com/And-rix/pve-scripts/refs/heads/main/misc/functions.sh)

# Clearing screen
clear

# Post message
create_header "vDSM-Arc-Installer"

# Info
echo -e "${CONSOLE}vDSM.Arc ${C}default settings${X}"
echo "-------------------------"
echo -e "${C}CPU: 2x | Mem: 4096MB | NIC: vmbr0 | Storage: selectable${X}"
echo -e "${Y}> can be changed after creation <${X}"
echo "-------------------------"
echo -e "${C}vDSM.Arc will be mapped as SATA0. ${R}> Do NOT CHANGE!${X}"
echo "-------------------------"
echo ""
continue_script

# Storage locations
pve_storages

# Check if storages exist
if [ -z "$STORAGES" ]; then
    echo -e "${NOTOK}${R}No storage locations found that support disk images.${X}"
    exit 1
fi
echo "-------------------------"
# Storage Options
echo -e "${DISK}${C}Please select target Storage for Arc install (SATA0):${X}"
select STORAGE in $STORAGES; do
    if [ -n "$STORAGE" ]; then
        echo -e "${C}You selected:${X} $STORAGE"
		echo "-------------------------"
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

# Create the VM 
qm create "$VM_ID" --name "$VM_NAME" --memory "$MEMORY" --cores "$CORES" --net0 virtio,bridge=vmbr0 --machine "$Q35_VERSION"

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

clear

# Delete temp file?
echo ""
echo -e "${INFO}${Y}Do you want to delete the temp downloaded file ($LATEST_FILENAME) from $DOWNLOAD_PATH? (y/Y): ${X}"
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
echo "-------------------------"
echo -e "${OK}${G}VM $VM_NAME (ID: $VM_ID) has been successfully created!${X}"
echo -e "${OK}${G}SATA0: Imported image (${NEW_IMG_FILE})${X}"
echo "-------------------------"

# Selection menu / Precheck
while true; do
	# Check available SATA port before proceeding
	PRE_SATA_PORT=$(precheck_sata_port)

	if [[ -z "$PRE_SATA_PORT" ]]; then
		echo ""
		echo -e "${NOTOK}${R}No available SATA ports between SATA1 and SATA5. Exiting...${X}"
		exit 1  
	fi
	
    echo ""
    echo -e "${DISK}${Y}Choose your option:${X}"
    echo -e "${C}a) Create Virtual Hard Disk${X}"
    echo -e "${C}b) Show Physical Hard Disk${X}"
    echo -e "${R}c) Exit${X}"
    read -n 1 option

    case "$option" in
        a) #Virtual Disk
			echo -e "${TAB}${C}Create Virtual Hard Disk${X}"
			echo ""
			
			# Storage locations > Disk images
			VM_DISKS=$(pvesm status -content images | awk 'NR>1 {print $1}')

			# Check availability
			if [ -z "$VM_DISKS" ]; then
			  echo -e "${R}No storage locations found that support disk images.${X}"
			  continue
			fi

			# Display storage options
			echo -e "${Y}Available target location for Virtual Disk:${X}"
			select VM_DISK in $VM_DISKS "Exit"; do
			  if [ "$VM_DISK" == "Exit" ]; then
				echo -e "${OK}${G}Back 2 Menu...${X}"
				continue 2
			  elif [ -n "$VM_DISK" ]; then
				echo -e "${G}You have selected: $VM_DISK${X}"
				break
			  else
				echo -e "${R}Invalid selection. Please try again.${X}"
			  fi
			done
			
			# Check Storage type
			VM_DISK_TYPE=$(pvesm status | awk -v s="$VM_DISK" '$1 == s {print $2}')
			echo "Storage type: $VM_DISK_TYPE"

			# Ask for disk size (at least 32 GB)
			read -p "Enter the disk size in GB (minimum 32 GB): " DISK_SIZE

			if [[ ! "$DISK_SIZE" =~ ^[0-9]+$ ]] || [ "$DISK_SIZE" -lt 32 ]; then
			  echo -e "${R}Invalid input. The disk size must be a number and at least 32 GB.${X}"
			  continue
			fi

			SATA_PORT=$(find_available_sata_port)
			DISK_NAME="vm-$VM_ID-disk-$SATA_PORT"

			# Generate disk path > block/file based
			if [[ "$VM_DISK_TYPE" == "dir" || "$VM_DISK_TYPE" == "btrfs" || "$VM_DISK_TYPE" == "nfs" || "$VM_DISK_TYPE" == "cifs" ]]; then
				DISK_PATH="$VM_DISK:$DISK_SIZE,format=qcow2"  # File level storages 
				sleep 1
				qm set "$VM_ID" -$SATA_PORT "$DISK_PATH",backup=0 # Disable Backup
			elif [[ "$VM_DISK_TYPE" == "pbs" || "$VM_DISK_TYPE" == "glusterfs" || "$VM_DISK_TYPE" == "cephfs" || "$VM_DISK_TYPE" == "iscsi" || "$VM_DISK_TYPE" == "iscsidirect" || "$VM_DISK_TYPE" == "rbd" ]]; then
				echo ""
				echo -e "${NOTOK}${R}Unsupported filesystem type: $VM_DISK_TYPE ${X}" # Disable untested storage types
				echo -e "${DISK}${Y}Supported filesystem types:${X}"
				echo -e "${TAB}${TAB}${C}dir, btrfs, nfs, cifs, lvm, lvmthin, zfs, zfspool${X}"
				continue
			else
				DISK_PATH="$VM_DISK:$DISK_SIZE"  # Block level storages
				sleep 1
				qm set "$VM_ID" -$SATA_PORT "$DISK_PATH",backup=0 # Disable Backup
			fi

			echo ""
			echo -e "${OK}${G}Disk created and assigned to $SATA_PORT: $DISK_PATH ${X}"
			;;
		b) #Physical Disk
			echo -e "${TAB}${C}Show Physical Hard Disk${X}"
			echo ""
			
			SATA_PORT=$(find_available_sata_port)
			DISKS=$(find /dev/disk/by-id/ -type l -print0 | xargs -0 ls -l | grep -v -E '[0-9]$' | awk -F' -> ' '{print $1}' | awk -F'/by-id/' '{print $2}')
			DISK_ARRAY=($(echo "$DISKS"))

			# Display the disk options with numbers
			echo -e "${Y}Select a physical disk:${X}"
			for i in "${!DISK_ARRAY[@]}"; do
			  echo "$((i + 1))) ${DISK_ARRAY[i]}"
			done
			echo "0) Exit"

			read -p "#? " SELECTION

			# Input check
			if ! [[ "$SELECTION" =~ ^[0-9]+$ ]]; then
			  echo ""
			  echo -e "${WARN}${Y}Invalid input. Please enter a number.${X}"
			  continue 2
			fi

			# Validating
			if [[ "$SELECTION" -eq 0 ]]; then
			  echo ""
			  echo -e "${OK}${G}Back 2 Menu...${X}"
			  continue 2
			elif [[ "$SELECTION" -ge 1 && "$SELECTION" -le "${#DISK_ARRAY[@]}" ]]; then
			  SELECTED_DISK="${DISK_ARRAY[$((SELECTION - 1))]}"
			else
			  echo ""
			  echo -e "${WARN}${Y}Invalid selection.${X}"
			  continue 2
			fi
			
			echo ""
				echo -e "${Y}You have selected $SELECTED_DISK.${X}"
				echo -e "${WARN}${Y}Copy & Paste this command into your PVE shell ${R}by your own risk!${X}"
				echo "-------------------------"
				echo -e "${TAB}${START}${C}qm set $VM_ID -$SATA_PORT /dev/disk/by-id/$SELECTED_DISK,backup=0${X}"
				echo "-------------------------"
				sleep 3
			;;
        c) # Exit
            echo ""
			echo -e "${OK}${C}Exiting the script.${X}"
            echo ""
            exit 0
			;;
        *) # False selection
            echo -e "${WARN}${R}Invalid input. Please choose 'a' | 'b' | 'c'.${X}"
			;;
    esac
done

