#!/bin/bash

#******************************************************************#
# Title: Shared Functions
# Description: Common functions and variables used across scripts
# Author: Phoenix-999
# Link: github.com/Phoenix-999
# Date: Jan 2, 2025
#******************************************************************#

# Check to prevent sourcing itself
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: shared_functions.sh cannot be executed directly."
    exit 1
fi

# Initialize BASE_PATH to the current directory of the script
BASE_PATH=$(dirname "${BASH_SOURCE[0]}")

# Ensure the shared_functions.sh file exists
if [ ! -f "$BASE_PATH/shared_functions.sh" ]; then
    echo "Error: shared_functions.sh not found in $BASE_PATH."
    exit 1
fi

# Placeholder for shared functions
# Define common functions here
example_function() {
    echo "This is a shared function."
}



###############################
# Define ANSI color codes
###############################

RED='\033[0;31m'
DARK_RED='\033[1;31m'
LESS_SATURATED_RED='\033[0;31m'
BOLD_RED='\033[1;31m'
YELLOW='\033[1;33m'
DARK_YELLOW='\033[0;33m'
BLUE='\033[0;34m'
DARK_BLUE='\033[1;34m'
CYAN='\033[0;36m'
BOLD_CYAN='\033[1;36m'
GREEN='\033[0;32m'
NEON_GREEN='\033[1;38;5;154m'
PURPLE='\033[0;35m'
GREY='\033[0;37m'
DARK_GRAY='\033[1;30m'
DARK_SILVER='\033[38;5;244m'
SPACE_GRAY='\033[38;5;238m'
TIN_DARK_SILVER='\033[38;5;250m'
BOLD='\033[1m'
PLAIN='\033[0m'
RESET='\033[0m'
NC='\033[0m'  # No Color

# URL
URL="github.com/Phoenix-999"

#############################################
# Function to display a unified progress bar
#############################################
show_progress() {
    local progress=$1
    local total_steps=$2
    local step_message=$3
    local bar_width=34

    # Calculate percentage
    local pct=$(( progress * 100 / total_steps ))
    local num_stars=$(( progress * bar_width / total_steps ))
    local num_spaces=$(( bar_width - num_stars ))

    # Move cursor up two lines and clear the lines to update progress
    if [ "$progress" -ne 1 ]; then
        printf "\033[A\033[K\033[A\033[K"
    fi

    # Print the progress bar
    printf "${DARK_SILVER}   ["
    for ((i=0; i<num_stars; i++)); do
        printf "${GREEN}*"
    done
    for ((i=0; i<num_spaces; i++)); do
        printf "-"
    done
    printf "${DARK_SILVER}] ${NEON_GREEN}${pct}%%${RESET}\n"

    # Print the step message on the next line
    printf "   ${DARK_SILVER}${step_message}${RESET}\n"

    # Move cursor to the beginning of the next line if progress is complete
    if [ "$pct" -eq 100 ]; then
        echo ""
    fi
}

#####################################################
# Function to check and install jq if not installed
#####################################################
check_jq() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    local steps=2
    local step=1
    local step_message="  • Checking jq installation"
    echo -e "${DARK_BLUE}  • Server Assessment & Script Preparation${NC}"
    echo -e "${DARK_YELLOW}  • Please Wait...${NC}"
    show_progress $step $steps "$step_message"


    if ! command -v jq &> /dev/null; then
        step_message="  • Installing jq"
        echo -e "${PURPLE}\n  • jq not found. Installing jq...${NC}"
        if command -v apt-get &> /dev/null; then
            sudo apt-get update > /dev/null 2>&1
            sudo apt-get install -y jq > /dev/null 2>&1
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq > /dev/null 2>&1
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y jq > /dev/null 2>&1
        elif command -v pacman &> /dev/null; then
            sudo pacman -Sy jq > /dev/null 2>&1
        else
            echo -e "${RED}  • Error: Package manager not supported. Install jq manually.${NC}"
            exit 1
        fi
        step=2
        show_progress $step $steps "$step_message"
    fi

    # Complete progress bar
    step=$steps
    step_message="  • jq check and installation complete"
    show_progress $step $steps "$step_message"
    echo -e "\n${PURPLE}  • jq check and installation complete.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
}
##############################################
# Function to log messages
##############################################
log_message() {
    local message=$1
    local log_file=$2
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo -e "[${timestamp}] ${message}" | tee -a "$log_file"
}

##############################################
# Function to validate numeric input
##############################################
validate_numeric_input() {
    local input=$1
    local min=$2
    local max=$3

    if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge "$min" ] && [ "$input" -le "$max" ]; then
        return 0
    else
        echo -e "${RED}✖ Invalid input! Please enter a number between $min and $max.${NC}"
        return 1
    fi
}

##############################################
# Function to validate yes/no input
##############################################
validate_yes_no_input() {
    local input=$1
    if [[ "$input" =~ ^[YyNn]$ ]]; then
        return 0
    else
        echo -e "${RED}✖ Invalid input! Please enter 'Y' or 'N'.${NC}"
        return 1
    fi
}


##############################################################
####################### End of Script ########################
##############################################################