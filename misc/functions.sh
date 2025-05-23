#!/bin/bash

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
			echo -e "${NOTOK}${R}VM $VM_ID is not shut down (Status: $STATUS). Please shut it down first.${X}"
			exit 1
		fi
	}

# Function arc release
	arc_release_url() {
		LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/AuxXxilium/arc/releases/latest | grep "browser_download_url" | grep ".img.zip" | cut -d '"' -f 4)
	}

	