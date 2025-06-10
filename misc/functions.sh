#!/bin/bash

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
			echo "-------------------------"
			vm_list_all
			echo "-------------------------"
			echo ""

			# Ask for VM ID
			echo -e "${C}Please enter the VM ID (example: 101): ${X}"
			read -r VM_ID
			echo "-------------------------"
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
			echo "-------------------------"
			echo "" 
			exit 1
		else 
			echo -e "${OK}${G}VM is stopped. Starting...${X}"
			echo "-------------------------"
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
		MEMORY=4096
		Q35_VERSION="q35"
	}		

# Function arc release
	arc_release_url() {
		LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/AuxXxilium/arc/releases/latest | grep "browser_download_url" | grep ".img.zip" | cut -d '"' -f 4)
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