#!/bin/bash

# MIT License
# Copyright (c) 2026 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

# Function pve_storages
pve_storages() {
    mapfile -t STORAGES < <(pvesm status -content images | awk 'NR>1 {print $1}')

    if [[ ${#STORAGES[@]} -eq 0 ]]; then
        echo -e "${R}[i] No storage locations found that support disk images.${X}"
        exit 1
    fi

    MENU_OPTIONS=()
    for s in "${STORAGES[@]}"; do
        MENU_OPTIONS+=("$s" "")
    done

    STORAGE=$(whiptail --title "Storage Selection" \
        --menu "Please select target storage for Arc install (SATA0):" 15 60 6 \
        "${MENU_OPTIONS[@]}" 3>&1 1>&2 2>&3) || exit 1

	echo -e "${C}Storage:${X} $STORAGE"
	line	
}

# Function unzip_check_install
unzip_check_install() {
	for pkg in unzip wget; do
		if ! command -v "$pkg" &> /dev/null; then
			echo -e "${Y}'$pkg' is not installed. Installing...${X}"
			apt-get update && apt-get install -y "$pkg"
			if ! command -v "$pkg" &> /dev/null; then
				echo -e "${R}[i] '$pkg' could not be installed. Exiting.${X}"
				exit 1
			fi
		fi
	done
}

# Function unzip_img
unzip_img() {
	echo -e "${Y}Extracting $LATEST_FILENAME...${X}"
    line
	unzip -o "$DOWNLOAD_PATH/$LATEST_FILENAME" -d "$ISO_STORAGE_PATH"
    line
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

# Function arc_stable_url
arc_stable_url() {
	local API_URL="https://api.github.com/repos/AuxXxilium/arc/releases/latest"

	# 1. evo bevorzugen
	LATEST_RELEASE_URL=$(curl -s "$API_URL" \
		| grep -E '"browser_download_url".*arc-[0-9]+\.[0-9]+\.[0-9]+-evo\.img\.zip' \
		| head -n1 \
		| cut -d '"' -f 4)

	# 2. Fallback ohne evo
	if [ -z "$LATEST_RELEASE_URL" ]; then
		LATEST_RELEASE_URL=$(curl -s "$API_URL" \
			| grep -E '"browser_download_url".*arc-[0-9]+\.[0-9]+\.[0-9]+\.img\.zip' \
			| head -n1 \
			| cut -d '"' -f 4)
	fi
}

# Function arc_beta_url
arc_beta_url() {
	local API_URL="https://api.github.com/repos/AuxXxilium/arc-beta/releases/latest"

	# 1. evo bevorzugen
	LATEST_RELEASE_URL=$(curl -s "$API_URL" \
		| grep -E '"browser_download_url".*arc-[0-9]+\.[0-9]+\.[0-9]+-evo\.img\.zip' \
		| head -n1 \
		| cut -d '"' -f 4)

	# 2. Fallback ohne evo
	if [ -z "$LATEST_RELEASE_URL" ]; then
		LATEST_RELEASE_URL=$(curl -s "$API_URL" \
			| grep -E '"browser_download_url".*arc-[0-9]+\.[0-9]+\.[0-9]+\.img\.zip' \
			| head -n1 \
			| cut -d '"' -f 4)
	fi
}


# Function arc_essential_url
arc_essential_url() {
	local API_URL="https://api.github.com/repos/AuxXxilium/arc-essential/releases/latest"

	# 1. evo bevorzugen
	LATEST_RELEASE_URL=$(curl -s "$API_URL" \
		| grep -E '"browser_download_url".*arc-[0-9]+\.[0-9]+\.[0-9]+-evo\.img\.zip' \
		| head -n1 \
		| cut -d '"' -f 4)

	# 2. Fallback ohne evo
	if [ -z "$LATEST_RELEASE_URL" ]; then
		LATEST_RELEASE_URL=$(curl -s "$API_URL" \
			| grep -E '"browser_download_url".*arc-[0-9]+\.[0-9]+\.[0-9]+\.img\.zip' \
			| head -n1 \
			| cut -d '"' -f 4)
	fi
}

# Function arc_release_choice
arc_release_choice() {
	while true; do
		release_choice=$(whiptail --title "Arc Installer - Release Channel" \
			--menu "Please select release channel:" 15 60 3 \
			"1" "Latest [Stable] – recommended!" \
			"2" "Latest [Beta]" \
			"3" "Latest [Essential]" \
			3>&1 1>&2 2>&3) || exit 1

		case "$release_choice" in
			1)
				echo -e "${C}Release: ${G}[Stable]${X}"
				line
				arc_stable_url
				break
				;;
			2)
				echo -e "${C}Release: ${R}[Beta]${X}"
				line
				arc_beta_url
				break
				;;
			3)
				echo -e "${C}Release: ${R}[Essential]${X}"
				line
				arc_essential_url
				break
				;;
			*)
				whiptail --title "Invalid Choice" --msgbox "Invalid selection. Please try again." 8 50
				;;
		esac
	done
}

# Function arc_release_download
arc_release_download() {
	LATEST_FILENAME=$(basename "$LATEST_RELEASE_URL")

	# Falls Datei existiert → löschen
	if [ -f "$DOWNLOAD_PATH/$LATEST_FILENAME" ]; then
		echo -e "${C}Removing existing file ${X}($LATEST_FILENAME)${C}...${X}"
		line
		rm -f "$DOWNLOAD_PATH/$LATEST_FILENAME"
	fi

	echo -e "${C}Downloading the latest file ${X}($LATEST_FILENAME)${C}...${X}"
	line
	wget -O "$DOWNLOAD_PATH/$LATEST_FILENAME" "$LATEST_RELEASE_URL" --show-progress --quiet
}


# Function arc_default_vm
arc_default_vm() {
	VM_ID=$(pvesh get /cluster/nextid)
	VM_NAME="vDSM.Arc"
	STORAGE=$STORAGE
	CORES=2
	CPU=host
	MEMORY=4096
	Q35_VERSION="q35"
}

# Function confirm_delete_temp_file
confirm_delete_temp_file() {
    if whiptail --title "Delete Temporary File?" \
        --yesno "Do you want to delete the downloaded file:\n\n  $LATEST_FILENAME\n\nFrom:\n  $DOWNLOAD_PATH\n\nContinue?" 15 60; then

        echo ""
        echo "Deleting the file..."
        rm -f "$DOWNLOAD_PATH/$LATEST_FILENAME"
        echo -e "${G}[OK] ${X}($LATEST_FILENAME) ${C}deleted.${X}"
    else
        echo ""
        echo -e "${Y}[i] ${X}($LATEST_FILENAME) ${C}was not deleted.${X}"
    fi
}

# Function precheck_sata_port
precheck_sata_port() {
	for PORT in {1..5}; do
		if ! qm config $VM_ID | grep -q "sata$PORT"; then
			echo "sata$PORT"
			return
		fi
	done
	echo ""  
}

# Function find_available_sata_port
find_available_sata_port() {
	for PORT in {1..5}; do
		if ! qm config $VM_ID | grep -q "sata$PORT"; then
			echo "sata$PORT"
			return
		fi
	done
	echo -e "${R}[EXIT] No available SATA ports between SATA1 and SATA5${X}"
}

#Function disk_path_generate
disk_path_generate() {
	if [[ "$VM_DISK_TYPE" == "dir" || "$VM_DISK_TYPE" == "btrfs" || "$VM_DISK_TYPE" == "nfs" || "$VM_DISK_TYPE" == "cifs" ]]; then
		DISK_PATH="$VM_DISK:$DISK_SIZE,format=qcow2"  # File level storages 
		sleep 1
		qm set "$VM_ID" -$SATA_PORT "$DISK_PATH",backup=0 # Disable Backup
	elif [[ "$VM_DISK_TYPE" == "pbs" || "$VM_DISK_TYPE" == "glusterfs" || "$VM_DISK_TYPE" == "cephfs" || "$VM_DISK_TYPE" == "iscsi" || "$VM_DISK_TYPE" == "iscsidirect" || "$VM_DISK_TYPE" == "rbd" ]]; then
		echo ""
		echo -e "${R}[i] Unsupported filesystem type: $VM_DISK_TYPE ${X}" # Disable untested storage types
		echo -e "${Y}Supported filesystem types:${X}"
		echo -e "${TAB}${TAB}${C}dir, btrfs, nfs, cifs, lvm, lvmthin, zfs, zfspool${X}"
		return
	else
		DISK_PATH="$VM_DISK:$DISK_SIZE"  # Block level storages
		sleep 1
		qm set "$VM_ID" -$SATA_PORT "$DISK_PATH",backup=0 # Disable Backup
	fi
}	

# Function sata_disk_menu
sata_disk_menu() {
  while true; do
    # Check available SATA port before proceeding
    PRE_SATA_PORT=$(precheck_sata_port)
    if [[ -z "$PRE_SATA_PORT" ]]; then
      echo -e "${R}[i] No available SATA ports between SATA1 and SATA5. Exiting...${X}"
      exit 1
    fi

    OPTION=$(whiptail --title "Disk Configuration" \
      --menu "Choose your option:" 15 60 3 \
      "a" "Create Virtual Hard Disk" \
      "b" "Show Physical Hard Disk" \
      "c" "Exit" 3>&1 1>&2 2>&3) || return

    case "$OPTION" in
      a)
        # Virtual Disk
		VM_DISKS=$(pvesm status -content images 2>/dev/null | awk 'NR>1 {print $1}')
		if [[ -z "$VM_DISKS" ]]; then
			whiptail --title "No Storage" --msgbox "No storage locations found that support disk images." 8 60
			continue
		fi

        STORAGE_MENU=()
        for disk in $VM_DISKS; do
        STORAGE_MENU+=("$disk" "")
        done
        STORAGE_MENU+=("Exit" "Return to main menu")

        VM_DISK=$(whiptail --title "Storage Selection" \
        --menu "Select target location for Virtual Disk:" 15 60 6 \
        "${STORAGE_MENU[@]}" 3>&1 1>&2 2>&3) || continue

        [[ "$VM_DISK" == "Exit" ]] && continue

        while true; do
        DISK_SIZE=$(whiptail --title "Disk Size" --inputbox "Enter disk size in GB (minimum 32 GB):" 10 60 3>&1 1>&2 2>&3)

        if [[ $? -ne 0 ]]; then
            continue 2  
        fi

        if ! [[ "$DISK_SIZE" =~ ^[0-9]+$ ]] || [[ "$DISK_SIZE" -lt 32 ]]; then
            whiptail --title "Invalid Size" --msgbox "The disk size must be a number and at least 32 GB." 8 60
        else
            break
        fi
        done

        SATA_PORT=$(find_available_sata_port)
        DISK_NAME="vm-$VM_ID-disk-$SATA_PORT"
        VM_DISK_TYPE=$(pvesm status 2>/dev/null | awk -v s="$VM_DISK" '$1 == s {print $2}')

        disk_path_generate

        whiptail --title "Success" \
        --msgbox "Disk created and assigned to $SATA_PORT:\n\n  $DISK_NAME" 10 60
        ;;

      b)
        # Physical Disk
        DISKS=$(find /dev/disk/by-id/ -type l \( -name 'ata-*' -o -name 'nvme-*' -o -name 'usb-*' \) -print0 \
		| xargs -0 ls -l \
		| grep -v -E '[0-9]+p[0-9]+$' \
		| awk -F' -> ' '{print $1}' \
		| awk -F'/by-id/' '{print $2}' \
		| grep -v '^nvme-eui')

        DISK_ARRAY=()
        for d in $DISKS; do
          DISK_ARRAY+=("$d" "")
        done

        if [[ ${#DISK_ARRAY[@]} -eq 0 ]]; then
          whiptail --title "No Disks" --msgbox "No physical disks found." 8 60
          continue
        fi

        SELECTED_DISK=$(whiptail --title "Physical Disk Selection" \
          --menu "Select a physical disk:" 20 70 10 \
          "${DISK_ARRAY[@]}" 3>&1 1>&2 2>&3) || continue

        SATA_PORT=$(find_available_sata_port)

        whiptail --title "Warning" \
          --msgbox "You selected:\n\n  $SELECTED_DISK\n\n Copy and paste this command in PVE shell **at your own risk**:\n\n  qm set $VM_ID -$SATA_PORT /dev/disk/by-id/$SELECTED_DISK,backup=0" 15 70

        sleep 1
        ;;

      c)
        whiptail --title "Exit" --msgbox "Exiting the script..." 8 50
        exit 0
        ;;

      *)
        whiptail --title "Invalid Selection" --msgbox "Invalid input. Please try again." 8 50
        ;;
    esac
  done
}

# Function vm_notes_html
vm_notes_html() {
    cat <<EOF
<h2><center>vDSM.Arc</center></h2>
<hr>
<h3>🚀 Arc Loader</h3>
<p>
  <a href="https://github.com/AuxXxilium/arc/" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/GitHub-AuxXxilium-24292e?logo=github&logoColor=white" alt="Arc GitHub">
  </a>
</p>
<hr>
<h3>📟 pve-scripts</h3>
<p>
  <a href="https://github.com/And-rix/pve-scripts" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/GitHub-And--rix-24292e?logo=github&logoColor=white" alt="PVE Scripts GitHub">
  </a>
</p>
EOF
}	

# Function vm_list_prompt
vm_list_prompt() {
	while true; do
		clear
		echo ""
		echo -e "${C}List of all VMs:${X}"
		line
		vm_list_all
		line
		echo ""

		echo -e "${Y}Press any key to continue to VM selection...${X}"
		read -n1 -s
		echo ""
        line

		VM_ID=$(whiptail --title "Select VM" \
            --inputbox "Please enter the VM ID (e.g. 101):" 10 60 3>&1 1>&2 2>&3)

        if [[ $? -ne 0 ]]; then
            whiptail --title "Cancelled" --msgbox "VM selection cancelled.\n\nExiting..." 10 60
            exit 1
        fi
        
		if vm_check_exist "$VM_ID"; then
			whiptail --title "VM Found" \
				--msgbox "The VM with ID $VM_ID exists.\n\nStarting precheck..." 10 60
			break
		else
			whiptail --title "VM Not Found" \
				--msgbox "The VM with ID $VM_ID does not exist.\n\nPlease try again." 10 60
		fi
	done
}

# Function vm_list_all
vm_list_all() {
	echo -e "VMID\tNAME\t\tSTATUS"
	line
	qm list | awk 'NR > 1 {printf "%-5s\t%-15s\t%s\n", $1, $2, $3}'
}

# Function vm_check_exist
vm_check_exist() {
	qm list | awk 'NR>1 {print $1}' | grep -q "^$1$"
}

# Function vm_check_status
vm_check_status() {
	STATUS=$(qm status $VM_ID | awk '{print $2}')
}

# vm_status
vm_status() {
	if [ "$STATUS" != "stopped" ]; then
		echo -e "${R}[i] ${C}VM $VM_ID is $STATUS. ${R}Please SHUTDOWN FIRST!${X}"
		line
		echo "" 
		exit 1
	else 
		echo -e "${G}[OK] ${C}VM $VM_ID is $STATUS. Continue update...${X}"
		line
	fi
}	
