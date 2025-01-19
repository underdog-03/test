#!/bin/bash

#******************************************************************#
# Title: SSH Management
# Description: Manage SSH settings such as port and password
# Author: Phoenix-999
# Link: github.com/Phoenix-999
# Date: Jan 2, 2025
#******************************************************************#

##############################################
# Function to Import shared functions and variables
##############################################

source /usr/local/bin/Phoenix_Shield/scripts/shared_functions/shared_functions.sh

# Define the base path for scripts
BASE_PATH="/usr/local/bin/Phoenix_Shield"

##############################################
# 8) Block SpeedTest
# Blocks speed test services from accessing the server
##############################################


block_speed_test() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Manage SpeedTest Block/Unblock${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${BLUE}| 1)  - Block SpeedTest Sites & Apps"
    echo -e "${BLUE}| 2)  - Unblock SpeedTest Sites & Apps"
    echo -e "${BLUE}| 3)  - View Blocked list"
    echo -e "${GREY}"
    echo -e "${DARK_RED}| 0)  - Return to Main Menu${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"

    read -p "$(echo -e "${NEON_GREEN}  ▷ Enter your choice (${RED}0-3${RESET})${NEON_GREEN}: ${NC}")" choice
    clear

    case $choice in
        1) apply_speedtest_block ;;
        2) remove_speedtest_block ;;
        3) view_speedtest_blacklist ;;
        0) return ;;
        *)
            echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
            echo -e "${GREY}"
            echo -e "${RED}  ✖ Invalid choice! Please try again.${NC}"
            sleep 2
            block_speed_test
            ;;
    esac
}

apply_speedtest_block() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Blocking SpeedTest Services.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${PURPLE}  • Applying SpeedTest Block...${NC}"

    local IPSET_NAME="speedtest_blocklist"
    local iptables_chain="SPEEDTEST_BLOCK"

    # Check if IPSet already exists
    if ipset list | grep -q "$IPSET_NAME"; then
        echo -e "${DARK_YELLOW}  ✓ IPSet already exists. Skipping creation.${NC}"
    else
        # Create and populate IPSet
        echo -e "${PURPLE}  • Creating IPSet and populating with SpeedTest domains...${NC}"
        ipset create "$IPSET_NAME" hash:net

        local speedtest_domains=(
            "bandwidthplace.com" "dslreports.com" "fast.com" "highspeedinternet.com"
            "internethealthtest.org" "m-lab" "speed.io" "speedcheck.org"
            "speedsmart.net" "speedof.me" "speedspot.org" "speedtest.net"
            "testmyspeed.com" "testmy.net" "v-speed.eu" "xfinity.com/speedtest"
        )

        for domain in "${speedtest_domains[@]}"; do
            ipset add "$IPSET_NAME" "$(dig +short "$domain" | head -n 1)" >/dev/null 2>&1
        done
    fi

    # Check if iptables chain exists
    if iptables -L | grep -q "$iptables_chain"; then
        echo -e "${DARK_YELLOW}  ✓ iptables chain already exists. Skipping creation.${NC}"
    else
        echo -e "${PURPLE}  • Creating iptables chain and applying rules...${NC}"
        iptables -N "$iptables_chain"
        iptables -I INPUT -m set --match-set "$IPSET_NAME" src -j DROP
        iptables -I FORWARD -m set --match-set "$IPSET_NAME" src -j DROP
    fi


    # Save iptables rules to system file for persistence
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    ipset save > /etc/ipset.rules

    # Save iptables and ipset configurations to internal config folder for script use
    ipset save > "$BASE_PATH/configs/ipset_rules/ipset_rules.conf"
    iptables-save > "$BASE_PATH/configs/iptables_rules/iptables_rules.conf"
    ip6tables-save > "$BASE_PATH/configs/iptables_rules/ip6tables_rules.conf"

    # Ensure iptables rules persist after reboot
    sudo iptables-save > /etc/iptables/rules.v4
    sudo ip6tables-save > /etc/iptables/rules.v6

    # Ensure ipset rules persist after reboot
    sudo ipset save > /etc/ipset.rules

    echo -e "${GREEN}  ✓ SpeedTest Services Blocked Successfully.${NC}"
    sleep 3
    block_speed_test
}

remove_speedtest_block() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Allowing SpeedTest Services.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${PURPLE}  • Removing SpeedTest Block...${NC}"

    local IPSET_NAME="speedtest_blocklist"
    local iptables_chain="SPEEDTEST_BLOCK"

    # Remove iptables rules
    if iptables -L | grep -q "$IPSET_NAME"; then
        iptables -D INPUT -m set --match-set "$IPSET_NAME" src -j DROP
        iptables -D FORWARD -m set --match-set "$IPSET_NAME" src -j DROP
        echo -e "${GREEN}  ✓ iptables rules removed.${NC}"
    else
        echo -e "${DARK_YELLOW}  ✖ No iptables rules found!.${NC}"
    fi

    # Destroy IPSet
    if ipset list | grep -q "$IPSET_NAME"; then
        ipset destroy "$IPSET_NAME"
        echo -e "${GREEN}  ✓ IPSet successfully removed.${NC}"
    else
        echo -e "${RED}  ✖ IPSet does not exist.${NC}"
    fi


    # Save iptables rules to system file for persistence
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    ipset save > /etc/ipset.rules

    # Save iptables and ipset configurations to internal config folder for script use
    ipset save > "$BASE_PATH/configs/ipset_rules/ipset_rules.conf"
    iptables-save > "$BASE_PATH/configs/iptables_rules/iptables_rules.conf"
    ip6tables-save > "$BASE_PATH/configs/iptables_rules/ip6tables_rules.conf"

    # Ensure iptables rules persist after reboot
    sudo iptables-save > /etc/iptables/rules.v4
    sudo ip6tables-save > /etc/iptables/rules.v6

    # Ensure ipset rules persist after reboot
    sudo ipset save > /etc/ipset.rules


    echo -e "${GREEN}  ✓ SpeedTest block removed successfully.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    sleep 3
    block_speed_test
}

view_speedtest_blacklist() {
     # Function to iptables & ipset persist
    source /usr/local/bin/Phoenix_Shield/scripts/rules_persist/rules_persist.sh

    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Viewing the status of SpeedTest services.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${BLUE}  • Current SpeedTest Blacklist...${NC}"

    local IPSET_NAME="speedtest_blocklist"

    if ipset list | grep -q "$IPSET_NAME"; then
        echo -e "${PURPLE}  • Review the SpeedTest Blacklist below.${NC}"
        local members=($(ipset list "$IPSET_NAME" | grep -Eo '^[0-9.]+'))

        declare -A organized_list
        organized_list=(
            ["bandwidthplace.com"]="184.25.66.202"
            ["dslreports.com"]="64.91.255.98"
            ["fast.com"]="64.111.22.3"
            ["highspeedinternet.com"]="151.101.194.219"
            ["internethealthtest.org"]="52.211.50.43"
            ["m-lab"]="46.21.148.2"
            ["speed.io"]="145.239.26.36"
            ["speedcheck.org"]="151.101.194.219"
            ["speedsmart.net"]="46.21.148.2"
            ["speedof.me"]="145.239.26.36"
            ["speedspot.org"]="104.21.112.1"
            ["speedtest.net"]="64.91.255.98"
            ["testmyspeed.com"]="52.13.119.180"
            ["testmy.net"]="52.13.119.180"
            ["v-speed.eu"]="104.21.112.1"
            ["xfinity.com/speedtest"]="18.222.50.214"
        )

        echo -e "${GREY}"
        echo -e "${PLAIN} ┌────────────────────────┬─────────────────┐${NC}"
        printf " │ ${DARK_YELLOW}%-22s${NC} │ ${DARK_YELLOW}%-15s${NC} │\n" "Website/App" "IP Address"
        echo -e "${PLAIN} ├────────────────────────┼─────────────────┤${NC}"

        for key in "${!organized_list[@]}"; do
            printf " │ ${GREEN}%-22s${NC} │ ${RED}%-15s${NC} │\n" "$key" "${organized_list[$key]}"
        done

        echo -e "${PLAIN} └────────────────────────┴─────────────────┘${NC}"
    else
        echo -e "${RED}  ✖ No SpeedTest blocklist found.${NC}"
    fi

    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "\n${CYAN}  ▷ Press ${RED}Enter${RESET}${CYAN} to return to the menu.${NC}"
    read
    block_speed_test
}


# Integration point
    block_speed_test