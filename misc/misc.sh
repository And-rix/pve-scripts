#!/bin/bash

# MIT License
# Copyright (c) 2025 And-rix
# GitHub: https://github.com/And-rix
# License: /LICENSE

# -----------------------------
# Global functions
# -----------------------------

# Function create_header
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
	
	clear
	echo ""
	echo -e "${C}${plus_line_top_bottom}${X}"
	echo -e "${C}${left_plus}${X} ${title} ${C}${right_plus}${X}"
	echo -e "${C}${plus_line_top_bottom}${X}"
	echo ""
}
# Function line
line() {
	printf '%*s\n' 60 '' | tr ' ' '-'
}

# Function ask_user_confirmation
ask_user_confirmation() {
  if whiptail --title "Run Script?" --yesno "Do you want to execute the script?" 10 60; then
	  echo -e "${C}Starting script...${X}"
    line
  else
	  echo -e "${R}Operation cancelled by user.${X}"
    line
    exit 1
  fi
}

# -----------------------------
# Colors
# -----------------------------
BK='\033[0;30m' # Black
R='\033[0;31m'  # Red
G='\033[0;32m'  # Green
Y='\033[0;33m'  # Yellow
B='\033[0;34m'  # Blue
M='\033[0;35m'  # Magenta
C='\033[0;36m'  # Cyan
W='\033[0;37m'  # White

# -----------------------------
# BG_Colors
# -----------------------------
BG_R='\033[41m'
BG_G='\033[42m'
BG_Y='\033[43m'
BG_B='\033[44m'
BG_M='\033[45m'
BG_C='\033[46m'
BG_W='\033[47m'

# -----------------------------
# Reset Color
# -----------------------------
X='\033[0m'

# -----------------------------
# Emojis
# -----------------------------
TAB="  "
INFO="${TAB}ℹ️${TAB}${X}"
START="${TAB}▶️${TAB}${X}"
OK="${TAB}✅${TAB}${X}"
NOTOK="${TAB}❌${TAB}${X}"
WARN="${TAB}⚠️${TAB}${X}"
DISK="${TAB}💾${TAB}${X}"
CONSOLE="${TAB}📟${TAB}${X}"
ROBOT="${TAB}🤖${TAB}${X}"
TOOL="${TAB}🛠️${TAB}${X}"
