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
# 7) Block IP scan
# Prevents IP scanning on the server
##############################################
block_ip_scan() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Manage IP Scan Block/Unblock${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${BLUE}| 1)  - Enable IP Scan Blocking"
    echo -e "${BLUE}| 2)  - Disable IP Scan Blocking"
    echo -e "${BLUE}| 3)  - View Blocking Rules Status"
    echo -e "${GREY}"
    echo -e "${DARK_RED}| 0)  - Return to Main Menu${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"

    read -p "$(echo -e "${NEON_GREEN}  ▷ Enter your choice (${RED}0-3${RESET}${NEON_GREEN}): ${NC}")" choice
    clear

    case $choice in
        1) enable_ip_scan_blocking ;;
        2) disable_ip_scan_blocking ;;
        3) view_ip_scan_rules ;;
        0) return ;;  # Return to main menu
        *)
            echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
            echo -e "${GREY}"
            echo -e "${RED}  ✖ Invalid choice! Please try again.${NC}"
            sleep 3
            block_ip_scan
            ;;
    esac
}

enable_ip_scan_blocking() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Blocking IP Scan for Security.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${PURPLE}  • Enabling IP Scan Blocking...${NC}"

    local ipset_name="ipscan_blocklist"
    local iptables_chain="IPSCAN_BLOCK"

    # Check if IPSet exists, create if not
    if ipset list | grep -q "$ipset_name"; then
        echo -e "${DARK_YELLOW}  ✓ IPSet already exists. Skipping creation.${NC}"
    else
       ipset create "$ipset_name" hash:net

        # Add IP ranges to the ipset for blocking incoming traffic
            # Private Address Ranges
            ipset add "$ipset_name" "10.0.0.0/8"         # Private Class A Range
            ipset add "$ipset_name" "172.16.0.0/12"      # Private Class B Range
            ipset add "$ipset_name" "192.168.0.0/16"     # Private Class C Range

            # Link-Local and Reserved Ranges
            ipset add "$ipset_name" "169.254.0.0/16"     # Link-Local Address Range
            ipset add "$ipset_name" "0.0.0.0/8"          # Reserved (0.0.0.0/8)

            # Infrastructure and Specialized Use
            ipset add "$ipset_name" "100.64.0.0/10"      # Carrier-Grade NAT Range
            ipset add "$ipset_name" "198.18.0.0/15"      # Benchmark Reserved Range
            ipset add "$ipset_name" "192.0.2.0/24"       # Documentation Range
            ipset add "$ipset_name" "198.51.100.0/24"    # Test Range

            # Multicast and Future Use
            ipset add "$ipset_name" "224.0.0.0/4"        # Multicast Range
            ipset add "$ipset_name" "240.0.0.0/4"        # Future Use Range

            # Bogon Ranges
            ipset add "$ipset_name" "23.0.0.0/8"         # Bogon Range 1
            ipset add "$ipset_name" "39.0.0.0/8"         # Bogon Range 2
            ipset add "$ipset_name" "126.0.0.0/8"        # Bogon Range 3

            # Malicious and Attackers' Ranges
            ipset add "$ipset_name" "185.0.0.0/8"        # Malicious Range 1
            ipset add "$ipset_name" "213.0.0.0/8"        # Malicious Range 2
            ipset add "$ipset_name" "93.0.0.0/8"         # Attackers' Range

    fi

    # Check if iptables chain exists, create if not
    if iptables -L | grep -q "$iptables_chain"; then
        echo -e "${DARK_YELLOW}  ✓ iptables chain already exists. Skipping creation.${NC}"
    else
        iptables -N "$iptables_chain"
        iptables -A "$iptables_chain" -m set --match-set "$ipset_name" src -j DROP
        iptables -I INPUT -j "$iptables_chain"  # Block incoming traffic only
    fi

    # Save iptables and ipset rules for persistence
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    ipset save > /etc/ipset.rules

    # Save iptables and ipset configurations for internal use
    ipset save > "$BASE_PATH/configs/ipset_rules/ipset_rules.conf"
    iptables-save > "$BASE_PATH/configs/iptables_rules/iptables_rules.conf"
    ip6tables-save > "$BASE_PATH/configs/iptables_rules/ip6tables_rules.conf"

    # Ensure iptables rules persist after reboot
    sudo iptables-save > /etc/iptables/rules.v4
    sudo ip6tables-save > /etc/iptables/rules.v6

    # Ensure ipset rules persist after reboot
    sudo ipset save > /etc/ipset.rules

    # Allow outgoing traffic to ipinfo.io (no changes made here)
    iptables -A OUTPUT -d ipinfo.io -j ACCEPT

    echo -e "${GREEN}  ✓ IP Scan Blocking Enabled Successfully.${NC}"
    sleep 3
    block_ip_scan
}


disable_ip_scan_blocking() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Disabling IP Scan Range.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${PURPLE}  • Disabling IP Scan Blocking...${NC}"

    local ipset_name="ipscan_blocklist"
    local iptables_chain="IPSCAN_BLOCK"

    if iptables -L | grep -q "$iptables_chain"; then
        iptables -D INPUT -j "$iptables_chain"
        iptables -F "$iptables_chain"
        iptables -X "$iptables_chain"
        echo -e "${GREEN}  ✓ iptables rules removed.${NC}"
    else
        echo -e "${DARK_YELLOW}  ✖ No iptables rules found.${NC}"
    fi

    if ipset list | grep -q "$ipset_name"; then
        ipset destroy "$ipset_name"
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

    echo -e "${GREEN}  ✓ IP Scan Blocking Disabled Successfully.${NC}"
    sleep 3
    block_ip_scan
}

view_ip_scan_rules() {
     # Function to iptables & ipset persist
    source /usr/local/bin/Phoenix_Shield/scripts/rules_persist/rules_persist.sh

    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Viewing the Current Blocked IP Range.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"

    local ipset_name="ipscan_blocklist"

    if ipset list | grep -q "$ipset_name"; then
        echo -e "${GREY}"
        echo -e "${PLAIN} ┌──────────────────────────┬──────────────────┐${NC}"
printf " │ ${DARK_YELLOW}%-24s${NC} │ ${DARK_YELLOW}%-16s${NC} │\n" "Range Name" "IP Range Block"
echo -e "${PLAIN} ├──────────────────────────┼──────────────────┤${NC}"

declare -A ip_ranges
ip_ranges=(
    ["Private Class A Range"]="10.0.0.0/8"          # Private Class A Range
    ["Private Class B Range"]="172.16.0.0/12"       # Private Class B Range
    ["Private Class C Range"]="192.168.0.0/16"      # Private Class C Range
    ["Link-Local Address Range"]="169.254.0.0/16"   # Link-Local Address Range
    ["Reserved (0.0.0.0/8)"]="0.0.0.0/8"            # Reserved (0.0.0.0/8)
    ["Carrier-Grade NAT Range"]="100.64.0.0/10"     # Carrier-Grade NAT Range
    ["Benchmark Reserved Range"]="198.18.0.0/15"    # Benchmark Reserved Range
    ["Documentation Range"]="192.0.2.0/24"          # Documentation Range
    ["Test Range"]="198.51.100.0/24"                # Test Range
    ["Multicast Range"]="224.0.0.0/4"               # Multicast Range
    ["Future Use Range"]="240.0.0.0/4"              # Future Use Range
    ["Bogon Range 1"]="23.0.0.0/8"                  # Bogon Range 1
    ["Bogon Range 2"]="39.0.0.0/8"                  # Bogon Range 2
    ["Bogon Range 3"]="126.0.0.0/8"                 # Bogon Range 3
    ["Malicious Range 1"]="185.0.0.0/8"             # Malicious Range 1
    ["Malicious Range 2"]="213.0.0.0/8"             # Malicious Range 2
    ["Attackers' Range"]="93.0.0.0/8"               # Attackers' Range
)

# Define the exact order for printing
ordered_keys=(
    "Private Class A Range"
    "Private Class B Range"
    "Private Class C Range"
    "Link-Local Address Range"
    "Reserved (0.0.0.0/8)"
    "Carrier-Grade NAT Range"
    "Benchmark Reserved Range"
    "Documentation Range"
    "Test Range"
    "Multicast Range"
    "Future Use Range"
    "Bogon Range 1"
    "Bogon Range 2"
    "Bogon Range 3"
    "Malicious Range 1"
    "Malicious Range 2"
    "Attackers' Range"
)

# Iterate over the ordered keys to maintain the desired order
for range in "${ordered_keys[@]}"; do
    printf " │ ${GREEN}%-24s${NC} │ ${RED}%-16s${NC} │\n" "$range" "${ip_ranges[$range]}"
done

echo -e "${PLAIN} └──────────────────────────┴──────────────────┘${NC}"

    else
        echo -e "${GREY}"
        echo -e "${RED}  ✖ No IP Scan Blocking Rules Found.${NC}"
    fi

    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "\n${CYAN}  ▷ Press ${RED}Enter${RESET}${CYAN} to return to the menu.${NC}"
    read
    block_ip_scan
}

block_ip_scan
