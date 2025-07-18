#!/bin/bash

# MIT License
# Copyright (c) 2025 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

# Function Header
	create_header() {
		local title="$1"
		local total_width=60
		local title_length=${#title}

		local padding_needed=$(( total_width - title_length - 2 ))
		local left_padding=$(( padding_needed / 2 ))
		local right_padding=$(( padding_needed - left_padding ))

		local plus_line_top_bottom=$(printf "+%.0s" $(seq 1 $total_width))
		local left_plus=$(printf "+%.0s" $(seq 1 $left_padding))
		local right_plus=$(printf "+%.0s" $(seq 1 $right_padding))

		echo ""
		echo -e "${C}${plus_line_top_bottom}${X}"
		echo -e "${C}${left_plus}${X} ${title} ${C}${right_plus}${X}"
		echo -e "${C}${plus_line_top_bottom}${X}"
		echo ""
	}

# Function seperating line
#	line() {
#		local cols
#		cols=$(tput cols) 
#
#		printf '%*s\n' "$cols" '' | tr ' ' '-'
#	}
	line() {
		printf '%*s\n' 60 '' | tr ' ' '-'
	}

# Function Continue Script
	continue_script() {
		echo -e "${START}${Y}Run script now? (y/Y)${X}"
		read -n 1 run_script
		echo ""

		if [[ "$run_script" =~ ^[Yy]$ ]]; then
			echo ""
			echo -e "${OK}${G}Running...${X}"
			echo ""
			echo ""
		else
			echo ""
			echo -e "${NOTOK}${R}Stopping...${X}"
			echo ""
			echo ""
			exit 1
		fi
	}

# Function Storage locations > support images
	pve_storages() {
		STORAGES=$(pvesm status -content images | awk 'NR>1 {print $1}')
	}

# Function Pre-Check SATA Port
	precheck_sata_port() {
		for PORT in {1..5}; do
			if ! qm config $VM_ID | grep -q "sata$PORT"; then
				echo "sata$PORT"
				return
			fi
		done
		echo ""  
	}


# Function Available SATA Port
	find_available_sata_port() {
		for PORT in {1..5}; do
			if ! qm config $VM_ID | grep -q "sata$PORT"; then
				echo "sata$PORT"
				return
			fi
		done
		echo -e "${R}No available SATA ports between SATA1 and SATA5${X}"
	}

# Function to generate disk path > block/file based
	disk_path_generate() {
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
	}	

# Function wget check & install
	unzip_check_install() {
		for pkg in unzip wget; do
			if ! command -v "$pkg" &> /dev/null; then
				echo -e "${Y}'$pkg' is not installed. Installing...${X}"
				apt-get update && apt-get install -y "$pkg"
				if ! command -v "$pkg" &> /dev/null; then
					echo -e "${NOTOK}${R}Error: '$pkg' could not be installed. Exiting.${X}"
					exit 1
				fi
			fi
		done
	}

# Function to check VM status
	vm_list_promt() {
		while true; do
			# Display list of all VMs
			echo ""
			echo -e "${C}List of all VMs:${X}"
			line
			vm_list_all
			line
			echo ""

			# Ask for VM ID
			echo -e "${C}Please enter the VM ID (example: 101): ${X}"
			read -r VM_ID
			line
			# Check VM exists
			if vm_check_exist "$VM_ID"; then
				echo -e "${OK}${G}The VM with ID $VM_ID exists. Starting precheck...${X}"
				break
			else
				echo -e "${NOTOK}${R}The VM with ID $VM_ID does not exist. Please try again.${X}"
			fi
		done
	}	

# Function to check VM status 
	vm_check_status() {
		STATUS=$(qm status $VM_ID | awk '{print $2}')
	}

# Function vm stopped or not
	vm_status() {
		if [ "$STATUS" != "stopped" ]; then
			echo -e "${NOTOK}${R}VM $VM_ID is $STATUS. Please SHUT DOWN FIRST!${X}"
			line
			echo "" 
			exit 1
		else 
			echo -e "${OK}${G}VM is stopped. Starting...${X}"
			line
		fi
	}	

# Function to list all VMs 
	vm_list_all() {
		qm list | awk 'NR>1 {print $2" - ID: "$1}'
	}

# Function to check if a VM exists 
	vm_check_exist() {
		qm list | awk 'NR>1 {print $1}' | grep -q "^$1$"
	}

# Function to check run as root
	run_as_root() {
		if [[ $EUID -ne 0 ]]; then
			echo "${WARN}${R}This script must be run as root!${X}"
			exit 1
		fi
	}

# Function vDSM.Arc default VM settings
	arc_default_vm() {
		VM_ID=$(pvesh get /cluster/nextid)
		VM_NAME="vDSM.Arc"
		STORAGE=$STORAGE
		CORES=2
		CPU=host
		MEMORY=4096
		Q35_VERSION="q35"
	}		

# Function arc release choice
	arc_release_choice() {
		while true; do
			echo ""
			line
			echo -e "${TOOL}${C}Please select release channel:${X}"
			echo -e "1) Latest ${G}[Stable]${X} > recommended!"
			echo -e "2) Latest ${R}[Beta]${X}"
			read -p "#? " release_choice
			echo ""

			release_choice=${release_choice:-1}

			if [[ "$release_choice" == "1" ]]; then
				echo -e "${C}You selected: ${G}[Stable]${X}"
				line
				arc_release_url
				break
			elif [[ "$release_choice" == "2" ]]; then
				echo -e "${C}You selected: ${R}[Beta]${X}"
				line
				arc_beta_url
				break
			else
				echo -e "${R}Invalid selection. Please try again.${X}"
			fi
		done
	}
	
# Function release version
	arc_version() {
		ARC_STABLE=$(curl -s https://api.github.com/repos/AuxXxilium/arc/releases/latest | grep '"name":' | head -n 1 | sed -E 's/.*"name": ?"([^"]+)".*/\1/')
		ARC_BETA=$(curl -s https://api.github.com/repos/AuxXxilium/arc-beta/releases/latest | grep '"name":' | head -n 1 | sed -E 's/.*"name": ?"([^"]+)".*/\1/')

		while true; do
			echo ""
			line
			echo -e "${TOOL}${C}Please select latest release channel:${X}"
			echo -e "1) Stable ${G}[$ARC_STABLE]${X} - Recommended!"
			echo -e "2) Beta ${R}[$ARC_BETA]${X}"
			read -p "#? " release_choice
			echo ""

			release_choice=${release_choice:-1}

			if [[ "$release_choice" == "1" ]]; then
				echo -e "${C}You selected: Stable ${G}[$ARC_STABLE]${X}"
				line
				arc_release_url
				break
			elif [[ "$release_choice" == "2" ]]; then
				echo -e "${C}You selected: Beta ${R}[$ARC_BETA]${X}"
				line
				arc_beta_url
				break
			else
				echo -e "${R}Invalid selection. Please try again.${X}"
			fi
		done
	}

# Function arc stable release
	arc_release_url() {
		LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/AuxXxilium/arc/releases/latest | grep "browser_download_url" | grep ".img.zip" | cut -d '"' -f 4)
	}

# Function arc beta release
	arc_beta_url() {
		LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/AuxXxilium/arc-beta/releases/latest | grep "browser_download_url" | grep ".img.zip" | cut -d '"' -f 4)
	}	

# Function arc download
	arc_release_download() {
		LATEST_FILENAME=$(basename "$LATEST_RELEASE_URL")

		if [ -f "$DOWNLOAD_PATH/$LATEST_FILENAME" ]; then
			echo -e "${C}The latest file ${X}($LATEST_FILENAME) ${C}is already present.${X}"
			echo -e "${G}Skipping download...${X}"
		else
			echo -e "${C}Downloading the latest file ${X}($LATEST_FILENAME)${C}...${X}"
			wget -O "$DOWNLOAD_PATH/$LATEST_FILENAME" "$LATEST_RELEASE_URL" --show-progress --quiet
		fi
	}	

# Function unzip img.zip
	unzip_img() {
		echo -e "${Y}Extracting $LATEST_FILENAME...${X}"
		unzip -o "$DOWNLOAD_PATH/$LATEST_FILENAME" -d "$ISO_STORAGE_PATH"
	}	

# Function Spinner
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

# Function VM notes	
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
<hr>
<p>
[arc-$VERSION] - $(date)
</p>
EOF
}	
