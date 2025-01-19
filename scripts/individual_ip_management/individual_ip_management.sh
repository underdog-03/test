#!/bin/bash

#******************************************************************#
# Title: IP Ranges Management
# Description: Manage IP Ranges (CIDR) for All Countries 
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
# 6) Individual IP Blacklist/Whitelist
# Adds or removes specific IPs to/from the list
##############################################

block_individual_ip() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Manage Individual IP Address/Range Blocking${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${BLUE}| 1)  - Block Individual IP Address/Range"
    echo -e "${BLUE}| 2)  - Unblock Individual IP Address/Range"
    echo -e "${BLUE}| 3)  - View Blocked IP Address/Range"
    echo -e "${BLUE}| 4)  - Help/Info"
    echo -e "${GREY}"
    echo -e "${DARK_RED}| 0)  - Return to Main Menu${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"

    read -p "$(echo -e "${NEON_GREEN}  ► Enter your choice ${RED}0-4${RESET}${NEON_GREEN}: ${NC}")" choice
    clear

    case $choice in
        1) block_individual_ip_address ;;
        2) unblock_individual_ip_address ;;
        3) view_blocked_individual_ip_addresses ;;
        4) individual_display_help ;;
        0) return ;;  # Return to main menu
        *)
            echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
            echo -e "${GREY}"
            echo -e "${RED}  ✖ Invalid choice! Please try again.${NC}"
            sleep 3
            block_individual_ip
            ;;
    esac
}

block_individual_ip_address() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Block Individual IP Address/Range${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    read -p "$(echo -e "${NEON_GREEN}  ► Enter IP Address/Range: ${NC}")" ip_address

    

    # Validate input for IPv4/IPv6 address or CIDR range
    if ! [[ "$ip_address" =~ ^(([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?|(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))(\/[0-9]{1,3})?)$ ]]; then
        echo -e "${RED}  ✖ Invalid input. Please enter a valid IPv4/IPv6 Address or Range.${NC}"
        sleep 3
        block_individual_ip
        return
    fi

    # Normalize input
    if [[ "$ip_address" =~ ^([a-fA-F0-9:]+:+)+[a-fA-F0-9]*$ ]]; then
        ip_address="${ip_address}/128"
    elif [[ "$ip_address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        ip_address="${ip_address}/32"
    fi

    # Generate unique hash for the IP address or range
    local hash_name="$(echo -n "$ip_address" | md5sum | cut -c1-10)"
    local ip_set="INDV_${hash_name}"

    # Determine protocol family (IPv4 or IPv6)
    local family="inet"
    local iptables_cmd="iptables"
    if [[ "$ip_address" =~ ":" ]]; then
        family="inet6"
        iptables_cmd="ip6tables"
    fi

    # Check if already blocked
    if ipset list | grep -q "$ip_set"; then
        echo -e "${DARK_YELLOW}  ✔ IP Address/Range ${ip_address} is already blocked.${NC}"
        sleep 3
        block_individual_ip
        return
    fi

    # Block the IP address or range
    ipset create "$ip_set" hash:net family "$family" -exist
    ipset add "$ip_set" "$ip_address" -exist
    $iptables_cmd -N "$ip_set" 2>/dev/null
    $iptables_cmd -A "$ip_set" -m set --match-set "$ip_set" src -j DROP
    $iptables_cmd -I INPUT -j "$ip_set" 2>/dev/null


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

    echo -e "${GREY}"
    echo -e "${GREEN}  ✔ IP Address/Range ${ip_address} Blocked Successfully.${NC}"
    sleep 3
    block_individual_ip
}

unblock_individual_ip_address() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Unblock Individual IP Address/Range${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    read -p "$(echo -e "${NEON_GREEN}  ► Enter IP Address/Range: ${NC}")" ip_address

    # Validate input for IPv4/IPv6 address or CIDR range
    if ! [[ "$ip_address" =~ ^(([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?|(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))(\/[0-9]{1,3})?)$ ]]; then
        echo -e "${RED}  ✖ Invalid input. Please enter a valid IPv4/IPv6 Address or Range.${NC}"
        sleep 3
        block_individual_ip
        return
    fi

    # Normalize input
    if [[ "$ip_address" =~ ^([a-fA-F0-9:]+:+)+[a-fA-F0-9]*$ ]]; then
        ip_address="${ip_address}/128"
    elif [[ "$ip_address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        ip_address="${ip_address}/32"
    fi

    # Generate unique hash for the IP address or range
    local hash_name="$(echo -n "$ip_address" | md5sum | cut -c1-10)"
    local ip_set="INDV_${hash_name}"

    # Check if already unblocked
    if ! ipset list "$ip_set" &>/dev/null; then
        echo -e "${RED}  ✖ No rules found for IP Address/Range ${ip_address}.${NC}"
        sleep 3
        block_individual_ip
        return
    fi

    # Remove rules and set
    iptables -D INPUT -j "$ip_set" 2>/dev/null || true
    iptables -F "$ip_set" 2>/dev/null || true
    iptables -X "$ip_set" 2>/dev/null || true

    ip6tables -D INPUT -j "$ip_set" 2>/dev/null || true
    ip6tables -F "$ip_set" 2>/dev/null || true
    ip6tables -X "$ip_set" 2>/dev/null || true

    ipset flush "$ip_set" 2>/dev/null || true
    ipset destroy "$ip_set" 2>/dev/null || true


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

    echo -e "${GREY}"
    echo -e "${GREEN}  ✔ IP Address/Range ${ip_address} Unblocked Successfully.${NC}"
    sleep 3
    block_individual_ip
}

view_blocked_individual_ip_addresses() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • View Blocked IP Address/Range${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"

    # Retrieve IP sets with INDV_ prefix
    local ip_sets=($(ipset list | grep -E "^Name: INDV_" | awk '{print $2}'))

    # Arrays to hold IPv4 and IPv6 entries
    local blocked_ipv4=()
    local blocked_ipv6=()

    for ip_set in "${ip_sets[@]}"; do
        # Extract entries for each IP set
        local entries=$(ipset list "$ip_set" | grep -E "^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?|([a-fA-F0-9:]+:+)+[a-fA-F0-9]*(/[0-9]+)?)$")
        while IFS= read -r entry; do
            if [[ "$entry" =~ ":" ]]; then
                blocked_ipv6+=("$entry")
            else
                blocked_ipv4+=("$entry")
            fi
        done <<< "$entries"
    done

    if [ ${#blocked_ipv4[@]} -eq 0 ] && [ ${#blocked_ipv6[@]} -eq 0 ]; then
        echo -e "${RED}  ✖ No IP Address/Range is currently blocked.${NC}"
    else
        echo -e "${GREY}"
        echo -e "${PLAIN} ┌─────────────────────┬────────────────────────────────────────┐${NC}"
        printf " │ ${DARK_YELLOW}%-20s${NC}│ ${DARK_YELLOW}%-39s${NC}│\n" "IPv4 Addr/Range" "IPv6 Addr/Range"
        echo -e "${PLAIN} ├─────────────────────┼────────────────────────────────────────┤${NC}"

        # Determine the maximum rows based on the larger list
        local max_len=$((${#blocked_ipv4[@]} > ${#blocked_ipv6[@]} ? ${#blocked_ipv4[@]} : ${#blocked_ipv6[@]}))

        for ((i = 0; i < max_len; i++)); do
            local ipv4="${blocked_ipv4[i]:-}"
            local ipv6="${blocked_ipv6[i]:-}"
            printf " │ ${GREEN}%-20s${NC}│ ${BLUE}%-39s${NC}│\n" "$ipv4" "$ipv6"
        done

        echo -e "${PLAIN} └─────────────────────┴────────────────────────────────────────┘${NC}"
    fi

    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "\n${CYAN}  ► Press ${RED}Enter${RESET}${CYAN} to return to the menu.${NC}"
    read
    block_individual_ip
}

individual_display_help() {
    # Function to iptables & ipset persist
    source /usr/local/bin/Phoenix_Shield/scripts/rules_persist/rules_persist.sh

    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Help & Information${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${BLUE}  • ${RED}IPv4${RESET}${BLUE} Address and Range Examples:${NC}"
    echo -e "${GREEN}      ${DARK_SILVER}- Address:${RESET}${GREEN} 203.80.136.65${NC}"
    echo -e "${GREEN}      ${DARK_SILVER}- Range:${RESET}${GREEN}.  203.76.168.0/22${NC}"
    echo -e "${GREY}"
    echo -e "${BLUE}  • ${RED}IPv6${RESET}${BLUE} Address and Range Examples:${NC}"
    echo -e "${GREEN}      ${DARK_SILVER}- Address:${RESET}${GREEN} 2a13:aac4:f400::1${NC}"
    echo -e "${GREEN}      ${DARK_SILVER}- Range:${RESET}${GREEN}   2a13:aac4:f400::/38${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "\n${CYAN}  ► Press ${RED}Enter${RESET}${CYAN} to return to the menu.${NC}"
    read -p ""
    block_individual_ip
}
block_individual_ip