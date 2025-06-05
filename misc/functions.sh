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

# Function wget check & install
	vm_status() {
		if [ "$STATUS" != "stopped" ]; then
			echo -e "${NOTOK}${R}VM $VM_ID is $STATUS. Please SHUT DOWN FIRST!${X}"
			echo "-------------------------"
			echo "" 
			exit 1
		fi
	}

# Function to check if a VM exists
	CHECK_VM_EXISTS() {
		qm list | awk 'NR>1 {print $1}' | grep -q "^$1$"
	}

# Function to list all VMs
	LIST_ALL_VMS() {
		qm list | awk 'NR>1 {print $2" - ID: "$1}'
	}

# Function to check run as root
	run_as_root() {
		if [[ $EUID -ne 0 ]]; then
			echo "${WARN}${R}This script must be run as root!${X}"
			exit 1
		fi
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