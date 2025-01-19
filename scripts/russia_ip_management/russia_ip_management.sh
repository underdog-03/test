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
# 4) Block Russia IP Ranges (CIDR)
# Blocks Russia-specific IP ranges
##############################################

block_russia_ips() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Manage Russia IP Blocking${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${BLUE}| 1)  - Blocking IP Ranges for Russia"
    echo -e "${BLUE}| 2)  - Unblocking IP Ranges for Russia"
    echo -e "${BLUE}| 3)  - View Blocked IP Ranges"
    echo -e "${GREY}"
    echo -e "${DARK_RED}| 0)  - Return to Main Menu${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"

    read -p "$(echo -e "${NEON_GREEN}  ▷ Enter your choice (${RED}0-3${RESET}${NEON_GREEN}): ${NC}")" choice
    clear

    case $choice in
        1) enable_russia_ip_blocking ;;
        2) disable_russia_ip_blocking ;;
        3) view_russia_ip_rules ;;
        0) return ;;  # Return to main menu
        *)
            echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
            echo -e "${GREY}"
            echo -e "${RED}  ✖ Invalid choice! Please try again.${NC}"
            sleep 3
            block_russia_ips
            ;;
    esac
}

enable_russia_ip_blocking() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Blocking IP Ranges for Russia.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"

    # Spinner animation function
    spinner() {
        local spin='|/-\\'
        local delay=0.1
        local i=0
        while :; do
            printf "\r${DARK_YELLOW}  • Please wait... ${NC}${spin:i++%${#spin}:1}"
            sleep "$delay"
        done
        echo -e "${GREY}"
    }

    # Start the spinner in the background
    spinner &
    spinner_pid=$!

    local ipv4_set="RU_ipv4_blocklist"
    local ipv6_set="RU_ipv6_blocklist"
    local iptables_chain="RUSSIA_BLOCK"

    # IPv4 Setup
    if ipset list | grep -q "$ipv4_set"; then
        echo -e "${GREY}"
        echo -e "${DARK_YELLOW}  ✓ IPv4 IPSet already exists.${NC}"
    else
        ipset create "$ipv4_set" hash:net
        curl -s https://www.iwik.org/ipcountry/RU.cidr | grep -v '^#' | while read -r ip; do
            ipset add "$ipv4_set" "$ip" -exist
        done
    fi

    # IPv6 Setup
    if ipset list | grep -q "$ipv6_set"; then
        echo -e "${DARK_YELLOW}  ✓ IPv6 IPSet already exists.${NC}"
    else
        ipset create "$ipv6_set" hash:net family inet6
        curl -s https://www.iwik.org/ipcountry/RU.ipv6 | grep -v '^#' | while read -r ip; do
            ipset add "$ipv6_set" "$ip" -exist
        done
    fi

    # Add to iptables
    if iptables -L | grep -q "$iptables_chain"; then
        echo -e "${DARK_YELLOW}  ✓ iptables chain already exists.${NC}"
    else
        iptables -N "$iptables_chain"
        iptables -A "$iptables_chain" -m set --match-set "$ipv4_set" src -j DROP
        iptables -I INPUT -j "$iptables_chain"

        ip6tables -N "$iptables_chain"
        ip6tables -A "$iptables_chain" -m set --match-set "$ipv6_set" src -j DROP
        ip6tables -I INPUT -j "$iptables_chain"
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

    # Stop the spinner
    kill "$spinner_pid" >/dev/null 2>&1
    wait "$spinner_pid" 2>/dev/null

    echo -e "${GREY}"
    echo -e "${GREEN}  ✓ Russia IPs Blocked Successfully.${NC}"
    sleep 3
    block_russia_ips
}

disable_russia_ip_blocking() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Unblocking IP Ranges for Russia.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"

    local ipv4_set="RU_ipv4_blocklist"
    local ipv6_set="RU_ipv6_blocklist"
    local iptables_chain="RUSSIA_BLOCK"

    # Remove iptables rules referencing the chain or sets
    if iptables -L | grep -q "$iptables_chain"; then
        iptables -D INPUT -j "$iptables_chain"
        iptables -F "$iptables_chain"
        iptables -X "$iptables_chain"
        echo -e "${GREEN}  ✓ iptables rules removed.${NC}"
    else
        echo -e "${DARK_YELLOW}  ✖ No iptables rules found.${NC}"
    fi

    if ip6tables -L | grep -q "$iptables_chain"; then
        ip6tables -D INPUT -j "$iptables_chain"
        ip6tables -F "$iptables_chain"
        ip6tables -X "$iptables_chain"
        echo -e "${GREEN}  ✓ ip6tables rules removed.${NC}"
    else
        echo -e "${DARK_YELLOW}  ✖ No ip6tables rules found.${NC}"
    fi

    # Ensure all iptables rules referencing sets are removed
    iptables -L | grep -q "$ipv4_set" && iptables -D INPUT -m set --match-set "$ipv4_set" src -j DROP
    ip6tables -L | grep -q "$ipv6_set" && ip6tables -D INPUT -m set --match-set "$ipv6_set" src -j DROP

    # Attempt to destroy the IPv4 IP set
    if ipset list | grep -q "$ipv4_set"; then
        ipset flush "$ipv4_set"  # Clear all entries in the set
        if ipset destroy "$ipv4_set"; then
            echo -e "${GREEN}  ✓ IPv4 IPSet successfully removed.${NC}"
        else
            echo -e "${RED}  ✖ IPv4 IPSet could not be destroyed.${NC}"
            echo -e "${RED}  ✖ Ensure it is not in use.${NC}"
        fi
    else
        echo -e "${RED}  ✖ IPv4 IPSet does not exist.${NC}"
    fi

    # Attempt to destroy the IPv6 IP set
    if ipset list | grep -q "$ipv6_set"; then
        ipset flush "$ipv6_set"  # Clear all entries in the set
        if ipset destroy "$ipv6_set"; then
            echo -e "${GREEN}  ✓ IPv6 IPSet successfully removed.${NC}"
        else
            echo -e "${RED}  ✖ IPv6 IPSet could not be destroyed.${NC}"
            echo -e "${RED}  ✖ Ensure it is not in use.${NC}"
        fi
    else
        echo -e "${RED}  ✖ IPv6 IPSet does not exist.${NC}"
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

    echo -e "${GREEN}  ✓ Russia IPs Unblocked Successfully.${NC}"
    sleep 3
    block_russia_ips
}


view_russia_ip_rules() {
     # Function to iptables & ipset persist
    source /usr/local/bin/Phoenix_Shield/scripts/rules_persist/rules_persist.sh

    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • View Blocked IP Ranges.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"

    local ipv4_set="RU_ipv4_blocklist"
    local ipv6_set="RU_ipv6_blocklist"

    if ipset list | grep -q "$ipv4_set" || ipset list | grep -q "$ipv6_set"; then
        echo -e "${GREY}"
        echo -e "${PLAIN} ┌─────────┬───────────────┐${NC}"
        printf " │ ${DARK_YELLOW}%-7s${NC} │ ${DARK_YELLOW}%-14s${NC}│\n" "IP Type" "Blocked Ranges"
        echo -e "${PLAIN} ├─────────┼───────────────┤${NC}"

        local ipv4_count=$(ipset list "$ipv4_set" 2>/dev/null | grep -c "^")
        local ipv6_count=$(ipset list "$ipv6_set" 2>/dev/null | grep -c "^")

        printf " │ ${GREEN}%-7s${NC} │ ${RED}%-14s${NC}│\n" "IPv4" "$ipv4_count"
        echo -e "${PLAIN} ├─────────┼───────────────┤${NC}"
        printf " │ ${GREEN}%-7s${NC} │ ${RED}%-14s${NC}│\n" "IPv6" "$ipv6_count"
        echo -e "${PLAIN} └─────────┴───────────────┘${NC}"
    else
        echo -e "${GREY}"
        echo -e "${RED}  ✖ No Russia IP Blocking Rules Found.${NC}"
    fi
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "\n${CYAN}  ▷ Press ${RED}Enter${RESET}${CYAN} to return to the menu.${NC}"
    read
    block_russia_ips
}
block_russia_ips