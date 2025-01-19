#!/bin/bash

#******************************************************************#
# Title: IP Ranges Management
# Description: Installing necessary packages & essential packages
# Author: Phoenix-999
# Link: github.com/Phoenix-999
# Date: Jan 2, 2025
#******************************************************************#

##############################################
# Function to Import shared functions and variables
##############################################

source /usr/local/bin/Phoenix_Shield/scripts/shared_functions/shared_functions.sh

##############################################
# installing necessary packages & essential packages
# managing dependencies effectively.
##############################################

clear
# List of packages to install
PACKAGES=("iptables" "iptables-persistent" "ipset" "ufw" "fail2ban" "geoip-bin" "geoip-database" "geoipupdate")

# Unified progress bar variables
TOTAL_STEPS=$((4 + ${#PACKAGES[@]})) # 4 main steps + number of packages
CURRENT_STEP=0
STEP_MESSAGES=("Checking system prerequisites" "Detecting package manager" "Updating the system" "Installing iptables & ipset" "Finalizing installation")

# Function to display progress bar and messages
display_progress() {
    local progress=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((progress * 30 / 100))
    local empty=$((30 - filled))

    clear
    
    echo -e "${SPACE_GRAY}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Installing Necessary & Essential Packages.${NC}"
    echo -e "${SPACE_GRAY}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"


# Function to display progress

    bar_length=20  # Adjust the total length of the progress bar
    filled=$((progress * bar_length / 100))
    empty=$((bar_length - filled))

    printf "${DARK_RED}   ▷ Progress:${NC} [%3d%%] [${GREEN}%s${NC}%s]\n" \
    "$progress" \
    "$(printf '█%.0s' $(seq 1 $filled))" \
    "$(printf ' %.0s' $(seq 1 $empty))"

    echo -e "${GREY}"

    for i in "${!STEP_MESSAGES[@]}"; do
        if [ "$i" -lt "$CURRENT_STEP" ]; then
            printf "${PURPLE}   ✓  %s${NC}\n" "${STEP_MESSAGES[$i]}"
        elif [ "$i" -eq "$CURRENT_STEP" ]; then
            printf "${DARK_YELLOW}   •  %s${NC}\n" "${STEP_MESSAGES[$i]}"
        else
            printf "${DARK_YELLOW}   •  %s${NC}\n" "${STEP_MESSAGES[$i]}"
        fi
    done
}

# Increment progress
increment_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    display_progress
}

# Error handling
error_exit() {
    printf "\n${RED}    ✖  ${NC} $1\n"
    exit 1
}

# Retry command on failure with logging
retry_command() {
    local cmd="$1"
    local retries=3
    for attempt in $(seq 1 $retries); do
        if $cmd &>/dev/null; then
            return 0
        fi
        sleep $((attempt * 2))  # Exponential backoff
    done
    printf "\n${RED}    ✖   Command failed after $retries retries:${NC} $cmd\n" >&2
    return 1
}

# Pre-flight checklist
check_prerequisites() {
    # Check disk space
    local available_space=$(df / | awk 'NR==2 {print $4}')
    [ "$available_space" -lt 1000000 ] && error_exit "Insufficient disk space."

    # Check internet connectivity
    ping -c 1 google.com &>/dev/null || error_exit "No network connectivity."

    increment_progress
}

# Detect package manager
detect_package_manager() {
    if command -v apt-get &>/dev/null; then
        PACKAGE_MANAGER="apt-get"
        export DEBIAN_FRONTEND=noninteractive  # Automate package configuration for Debian-based systems
    elif command -v yum &>/dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v dnf &>/dev/null; then
        PACKAGE_MANAGER="dnf"
    else
        error_exit "Unsupported package manager."
    fi
    increment_progress
}

# Update and upgrade the system
update_system() {
    retry_command "$PACKAGE_MANAGER update"
    retry_command "$PACKAGE_MANAGER upgrade -y"
    increment_progress
}

# Install packages
install_packages() {
    for pkg in "${PACKAGES[@]}"; do
        if ! retry_command "$PACKAGE_MANAGER install -y $pkg"; then
            printf "\n${RED}    ✖   Failed to install $pkg. Skipping...${NC}\n" >&2
        fi
        increment_progress
    done
}

# Finalize and ensure progress reaches 100%
finalize_installation() {
    increment_progress
    printf "\n${NEON_GREEN}   ✓  All tasks completed successfully!${NC}\n"
}

# Main function
main() {
    display_progress # Initial display
    check_prerequisites
    detect_package_manager
    update_system
    install_packages
    finalize_installation
}

# Run the main script
main
