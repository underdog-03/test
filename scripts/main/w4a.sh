#!/bin/bash


#******************************************************************#
# Title: Wall 4 All Main Menu (W4A.BASH)
# Description: Main menu script for Wall 4 All project
# Author: Phoenix-999
# Link: github.com/Phoenix-999
# Date: Jan 2, 2025
#******************************************************************#

##############################################
# Import shared functions and variables
##############################################

source /usr/local/bin/Phoenix_Shield/scripts/shared_functions/shared_functions.sh


##############################################
# Function to perform update and upgrade
##############################################n

update_and_upgrade_server() {
clear
echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
echo -e "${GREY}"
echo -e "${BLUE}  • Updating system & installing essentials...${NC}"
echo -e "${DARK_YELLOW}  • Please wait, this may take a moment.${NC}"
echo -e "${GREEN}      ✓ Operating System Verified $OS${NC}"
echo -e "${GREEN}      ✓ Architecture Verified $ARCH${NC}"
echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
echo -e "${GREY}"

    # Check for supported OS and architecture
    OS=$(lsb_release -is 2>/dev/null || echo "Unknown")
    ARCH=$(uname -m)

    if [[ "$OS" != "Ubuntu" && "$OS" != "Debian" ]]; then
        echo -e "${RED}  ✖ Unsupported operating system: $OS. Only Ubuntu and Debian are supported.${NC}"
        exit 1
    fi

    if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
        echo -e "${RED}  ✖ Unsupported architecture: $ARCH. Only AMD64 and ARM64 are supported.${NC}"
        exit 1
    fi

    local steps=6
    local step=1

    # Update package lists
    step_message="  • Updating package lists"
    show_progress $step $steps "$step_message"
    if ! sudo apt update > /dev/null 2>&1; then
        echo -e "${RED}  ✖ Failed to update package lists.${NC}"
        exit 1
    fi
    sleep 1
    ((step++))

    # Upgrade all packages including kernel updates
    step_message="  • Upgrading installed packagesn"
    show_progress $step $steps "$step_message"
    if ! sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq --with-new-pkgs > /dev/null 2>&1; then
        echo -e "${RED}  ✖ Failed to upgrade packages.${NC}"
        exit 1
    fi
    sleep 1
    ((step++))

    # Perform distribution upgrade
    step_message="  • Performing distribution upgrade"
    show_progress $step $steps "$step_message"
    if ! sudo apt dist-upgrade -y > /dev/null 2>&1; then
        echo -e "${RED}  ✖ Failed to perform distribution upgrade.${NC}"
        exit 1
    fi
    sleep 1
    ((step++))

    # Remove unnecessary packages
    step_message="  • Removing unnecessary packages"
    show_progress $step $steps "$step_message"
    if ! sudo apt-get autoremove -y > /dev/null 2>&1; then
        echo -e "${RED}  ✖ Failed to remove unnecessary packages.${NC}"
        exit 1
    fi
    sleep 1
    ((step++))

    # Check if reboot is required
    clear
    if [ -f /var/run/reboot-required ]; then
        echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
        echo -e "${GREY}"
        echo -e "${DARK_YELLOW}  • A reboot is required to complete kernel updates.${NC}"
        while true; do
        
            read -p "$(echo -e "${CYAN}   ▷ Would you like to reboot now? (${GREEN}Y${RESET}/${RED}N${RESET})${NC}: ")" choice
            case $choice in
                [Yy]* )
                    # echo -e "${NEON_GREEN}      ✓ Rebooting system...${NC}"
                    sudo reboot
                    exit 0
                    ;;
                [Nn]* )
                    echo -e "${YELLOW}  • Skipping reboot. Please remember to reboot manually later.${NC}"
                    break
                    ;;
                * )
                    echo -e "${RED}  ✖ Invalid input. Please enter Y or N.${NC}"
                    ;;
            esac
        done
    fi

                echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
                echo -e "${GREY}"
                echo -e "${GREEN}      ✓ Update & Installations Completed Successfully!${NC}"
                echo -e "${GREEN}      ✓ Ready to proceed with the script and options!${NC}"
                echo -e "${GREY}"
                echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
}


##############################################
# Unified Function: Gather VPS Details & Handle Updates
##############################################

gather_vps_details_and_handle_updates() {
    local steps=8
    local step=1

    clear
    echo -e "${GREY}"
    echo -e "${DARK_BLUE}   • Server Assessment & Script Preparation${NC}"
    echo -e "${DARK_YELLOW}   • Please Wait...${NC}"

    # VPS Name
    step_message="• Gathering VPS Name"
    VPS_NAME=$(hostname)
    show_progress $step $steps "$step_message"
    sleep 1
    ((step++))

    # System distribution and release info
    step_message="• Gathering System Distribution Info"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRIBUTOR_ID=$ID
        RELEASE=$VERSION_ID
    else
        DISTRIBUTOR_ID="Unknown"
        RELEASE="Unknown"
    fi
    show_progress $step $steps "$step_message"
    sleep 1
    ((step++))

    # VPS IPv4 Address
    step_message="• Gathering VPS IPv4 Address"
    VPS_IPV4=$(hostname -I | awk '{print $1}')
    show_progress $step $steps "$step_message"
    sleep 1
    ((step++))

    # VPS IPv6 Address
    step_message="• Gathering VPS IPv6 Address"
    VPS_IPV6=$(ip -6 addr show scope global | grep inet6 | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    show_progress $step $steps "$step_message"
    sleep 1
    ((step++))

    # SSH Port
    step_message="• Gathering SSH Port"
    SSH_PORT=$(grep '^Port ' /etc/ssh/sshd_config | awk '{print $2}')
    if [ -z "$SSH_PORT" ]; then
        SSH_PORT="Default (22)"  # Default SSH port if not specified
    fi
    show_progress $step $steps "$step_message"
    sleep 1
    ((step++))

    # Location of the server (using ipinfo.io)
    step_message="• Gathering Server Location"
    IP=$(curl -s https://ipinfo.io/ip)
    LOCATION_JSON=$(curl -s "https://ipinfo.io/${IP}?token=${IPINFO_TOKEN}")
    CITY=$(echo "$LOCATION_JSON" | jq -r '.city // "Unknown"')
    COUNTRY=$(echo "$LOCATION_JSON" | jq -r '.country // "Unknown"')
    LOCATION="${CITY}, ${COUNTRY}"
    show_progress $step $steps "$step_message"
    sleep 1
    ((step++))

    # Check if server and packages are up to date
    step_message="• Checking Server & Packages Update Status"
    sudo apt update > /dev/null 2>&1
    UPGRADABLE=$(apt list --upgradable 2> /dev/null | grep -v "Listing" | wc -l)
    if [ "$UPGRADABLE" -eq 0 ]; then
        STATUS="${NEON_GREEN}✓ UP TO DATE${NC}"
    else
        STATUS="${BOLD_RED}✗ NOT UP TO DATE${NC}"
    fi
    show_progress $step $steps "$step_message"
    sleep 1
    ((step++))
    clear

    # Print gathered details
    echo -e "${SPACE_GRAY}${BOLD} ____________________________________________${NC}"
    echo -e "${DARK_SILVER}            »»——— VPS Details ———««             ${NC}"
    echo -e "${SPACE_GRAY}${BOLD} ____________________________________________${NC}"
    printf "${YELLOW}  • ${TIN_DARK_SILVER}%-15s${NC} | ${DARK_YELLOW}%-30s${NC}\n" "IPv4 Address" "$VPS_IPV4"
    printf "${YELLOW}  • ${TIN_DARK_SILVER}%-15s${NC} | ${DARK_YELLOW}%-30s${NC}\n" "IPv6 Address" "$VPS_IPV6"
    printf "${YELLOW}  • ${TIN_DARK_SILVER}%-15s${NC} | ${DARK_YELLOW}%-30s${NC}\n" "SSH Port" "$SSH_PORT"
    printf "${YELLOW}  • ${TIN_DARK_SILVER}%-15s${NC} | ${DARK_YELLOW}%-30s${NC}\n" "Location" "$LOCATION"
    printf "${YELLOW}  • ${TIN_DARK_SILVER}%-15s${NC} | ${DARK_YELLOW}%-30s${NC}\n" "Distributor ID" "$DISTRIBUTOR_ID"
    printf "${YELLOW}  • ${TIN_DARK_SILVER}%-15s${NC} | ${DARK_YELLOW}%-30s${NC}\n" "Release" "$RELEASE"
    echo -e "${SPACE_GRAY}${BOLD} ____________________________________________${NC}"

    # Echo the Server Status separately
    echo -e "${GREY}"
    echo -e "${TIN_DARK_SILVER}  • Server & Packages Status: $STATUS${NC}"
    echo -e "${SPACE_GRAY}${BOLD} ____________________________________________${NC}"

    # Handle updates if needed
    if [ "$UPGRADABLE" -gt 0 ]; then
        echo -e "${GREY}"
        echo -e "${DARK_YELLOW}  • Your server is ${DARK_RED}not currently up to date.${NC}"
        echo -e "${DARK_YELLOW}  • Necessary dependencies & essential packages ${DARK_RED}MUST${RESET}${DARK_YELLOW} be installed.${NC}"
        while true; do
            echo -e "${TIN_DARK_SILVER}  • Would you like to update & upgrade your OS before proceeding? (${GREEN}Y${RESET}${TIN_DARK_SILVER}/${RESET}${DARK_RED}N${RESET}${TIN_DARK_SILVER})${NC}"
            echo -e "${GREY}"
            read -p "$(echo -e "${CYAN}   ▷ Enter your choice: ")" choice

            if [[ "$choice" =~ ^[Yy]$ ]]; then
                update_and_upgrade_server
                break
            elif [[ "$choice" =~ ^[Nn]$ ]]; then
                clear
                echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
                echo -e "${GREY}"
                echo -e "${DARK_YELLOW}  • Skipping update and upgrade.${NC}"
                echo -e "${RED}  • Server update is strongly recommended.${NC}"
                echo -e "${CYAN}  • Proceeding with the script...${NC}"

                echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
                echo -e "${GREY}"
                break
            else
                clear
                echo -e "${GREY}"
                tput cuu 1    # Move cursor up by 2 lines
            
                echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
                echo -e "${GREY}"
                echo -e "${BOLD_RED}  • Invalid input!${NC}"
                echo -e "${DARK_YELLOW}  • Please enter ${GREEN}Y${RESET}${DARK_YELLOW} for Yes or ${DARK_RED}N${RESET}${DARK_YELLOW} for No.${NC}"
            fi
        done
    fi
}

# Call the unified function
gather_vps_details_and_handle_updates


##############################################
# Function to print the introduction message
##############################################
print_introduction() {
    echo -e "${GREY}"
    echo -e "${PURPLE}╭━━━━━━━━━━━━━━━━━━━━∙⋆⋅⋆∙━━━━━━━━━━━━━━━━━━━╮${NC}"
    echo -e "${BLUE}${BOLD}            ✭✭✭✭✭✭ Wall 4 All ✭✭✭✭✭✭ ${NC}"
    echo -e "${PURPLE}╰━━━━━━━━━━━━━━━━━━━━∙⋆⋅⋆∙━━━━━━━━━━━━━━━━━━━╯${NC}"
}
##############################################
# Function to print the menu
##############################################
print_menu() {
    echo -e "${YELLOW}\\033[1m ____________________________________________\\033[0m${NC}"
    echo -e "${BLUE}"
    echo -e "${BLUE}| 1)  - Change ${DARK_YELLOW}SSH${RESET}${BLUE} port & password"
    echo -e "${BLUE}"
    echo -e "${BLUE}| 2)  - Manage ${RED}Iran${RESET}${BLUE} IP Ranges (CIDR)"
    echo -e "${BLUE}| 3)  - Manage ${RED}China${RESET}${BLUE} IP Ranges (CIDR)"
    echo -e "${BLUE}| 4)  - Manage ${RED}Russia${RESET}${BLUE} IP Ranges (CIDR)"
    echo -e "${BLUE}| 5)  - Manage ${RED}All other countries'${RESET}${BLUE} IP Ranges (CIDR)"
    echo -e "${BLUE}| 6)  - Individual IP Blacklist/Whitelist"
    echo -e "${BLUE}"
    echo -e "${BLUE}| 7)  - Block IP scan"
    echo -e "${BLUE}| 8)  - Block SpeedTest"
    echo -e "${BLUE}| 9)  - Brute-Force Shield"
    echo -e "${BLUE}| 10) - DDoS Attack Shield"
    echo -e "${BLUE}| 11) - Other Security Management"
    echo -e "${BLUE}"
    echo -e "${BLUE}| 12) - Current Status Overview"
    echo -e "${BLUE}| 13) - Real-Time System Monitoring"
    echo -e "${BLUE}| 14) - Restoring Default Server Settings"
    echo -e "${BLUE}"
    echo -e "${DARK_RED}| 0  - Exit"
    echo -e "${YELLOW}\\033[1m ____________________________________________\\033[0m${NC}"
}

##############################################################
# Function to handle user input and execute the chosen option
##############################################################
handle_menu_selection() {
    # Define the base path for scripts
    BASE_PATH="/usr/local/bin/Phoenix_Shield/scripts"
    while true; do
        print_introduction
        print_menu
        echo -e "${GREY}"
        echo -ne "${NEON_GREEN}\\033[1m ➤ Enter your choice ${BLUE}(0-14): ${NC}"

        read choice
        case $choice in
            1) "$BASE_PATH/ssh_management/ssh_management.sh" ;;
            2) "$BASE_PATH/iran_ip_management/iran_ip_management.sh" ;;
            3) "$BASE_PATH/china_ip_management/china_ip_management.sh" ;;
            4) "$BASE_PATH/russia_ip_management/russia_ip_management.sh" ;;
            5) "$BASE_PATH/country_ip_management/country_ip_management.sh" ;;
            6) "$BASE_PATH/individual_ip_management/individual_ip_management.sh" ;;

            7) "$BASE_PATH/ip_scan_management/ip_scan_management.sh" ;;
            8) "$BASE_PATH/speedtest_management/speedtest_management.sh" ;;
            9) "$BASE_PATH/brute_force_shield/brute_force_shield.sh" ;;
            10) "$BASE_PATH/ddos_attack/ddos_attack.sh" ;;
            11) "$BASE_PATH/general_security_management/general_security_management.sh" ;;

            12) "$BASE_PATH/status_overview/status_overview.sh" ;;
            13) "$BASE_PATH/monitor_system/monitor_system.sh" ;;
            14) "$BASE_PATH/restore_default_settings/restore_default_settings.sh" ;;
            0) 
                clear
                echo -e "${GREY}"
                echo -e "${RED}   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
                echo -e "${GREEN}       • Hope you enjoyed using the script!${NC}"
                echo -e "${DARK_YELLOW}       • Please don't forget to check the output files.${NC}"
                echo -e "${BLUE}       • Any comments or suggestions? Please refer to ${CYAN}${URL}${RESET}${NC}"
                echo -e "${RED}   ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
                echo -e "${GREY}"
                echo -e "${GREY}"
                echo -e "${DARK_RED}   ╰┈➤ Exiting script...${NC}"
                echo -e "${GREY}"
                echo -e "${GREY}"
                echo -e "${DARK_YELLOW}   ◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤${NC}"
                echo -e "${GREY}"
                echo -e "${GREY}"
                
                # Exit the Script
                exit 0 ;;
            *)
                clear
                echo -e "${GREY}"
                echo -e "${RED}  • Invalid Entry!${NC}"
                echo -e "${RED}  • Please choose a number between (0-8)${NC}"

                ;;
        esac
    done
}

# Main script execution

        # Show introduction and menu
        # print_introduction
        handle_menu_selection

##############################################################
####################### End of Script ########################
##############################################################