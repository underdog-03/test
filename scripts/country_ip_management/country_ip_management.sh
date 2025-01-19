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
# 5) Block All Other Countries (CIDR)
# This section blocks IP ranges specific to countries
##############################################

block_all_countries_ips() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Manage All Countries IP Blocking${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${BLUE}| 1)  - Blocking IP Ranges for a Selected Country"
    echo -e "${BLUE}| 2)  - Unblocking IP Ranges for a Selected Country"
    echo -e "${BLUE}| 3)  - View Blocked IP Ranges"
    echo -e "${BLUE}| 4)  - Help/Info"
    echo -e "${GREY}"
    echo -e "${DARK_RED}| 0)  - Return to Main Menu${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"

    read -p "$(echo -e "${NEON_GREEN}  ▷ Enter your choice ${RED}0-4${RESET}${NEON_GREEN}: ${NC}")" choice
    clear

    case $choice in
        1) enable_country_ip_blocking ;;
        2) disable_country_ip_blocking ;;
        3) view_blocked_ip_ranges ;;
        4) display_help ;;
        0) return ;;  # Return to main menu
        *)
            echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
            echo -e "${GREY}"
            echo -e "${RED}  ✖ Invalid choice! Please try again.${NC}"
            sleep 3
            block_all_countries_ips
            ;;
    esac
}

enable_country_ip_blocking() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Blocking IP Ranges for a Selected Country${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    read -p "$(echo -e "${NEON_GREEN}  ▷ Enter the country initials ${DARK_SILVER}(e.g., CN, US)${RESET}${NEON_GREEN}: ${NC}")" country_code

    # Normalize input to uppercase
    country_code=$(echo "$country_code" | tr '[:lower:]' '[:upper:]')

    # Validate input
    if ! [[ "$country_code" =~ ^[A-Z]{2}$ ]]; then
        echo -e "${RED}  ✖ Invalid format. Please enter a Country Code.${NC}"
        sleep 3
        block_all_countries_ips
        return
    fi

    local ipv4_set="${country_code}_ipv4_blocklist"
    local ipv6_set="${country_code}_ipv6_blocklist"
    local iptables_chain="${country_code}_BLOCK"

    # Check if country is already blocked
    if ipset list | grep -q "$ipv4_set" || ipset list | grep -q "$ipv6_set"; then
        echo -e "${DARK_YELLOW}  ✓ The selected country is already Blocked.${NC}"
        echo -e "${DARK_YELLOW}  • No action required, You are all set.${NC}"
        sleep 3
        block_all_countries_ips
        return
    fi

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

    # Construct URLs
    local ipv4_url="https://www.iwik.org/ipcountry/${country_code}.cidr"
    local ipv6_url="https://www.iwik.org/ipcountry/${country_code}.ipv6"

    # IPv4 Setup
    ipset create "$ipv4_set" hash:net -exist
    curl -s "$ipv4_url" | grep -v '^#' | while read -r ip; do
        ipset add "$ipv4_set" "$ip" -exist
    done

    # IPv6 Setup
    ipset create "$ipv6_set" hash:net family inet6 -exist
    curl -s "$ipv6_url" | grep -v '^#' | while read -r ip; do
        ipset add "$ipv6_set" "$ip" -exist
    done

    # Add to iptables
    iptables -N "$iptables_chain" 2>/dev/null
    iptables -A "$iptables_chain" -m set --match-set "$ipv4_set" src -j DROP
    iptables -I INPUT -j "$iptables_chain" 2>/dev/null

    ip6tables -N "$iptables_chain" 2>/dev/null
    ip6tables -A "$iptables_chain" -m set --match-set "$ipv6_set" src -j DROP
    ip6tables -I INPUT -j "$iptables_chain" 2>/dev/null

    # Stop the spinner
    kill "$spinner_pid" >/dev/null 2>&1
    wait "$spinner_pid" 2>/dev/null


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
    echo -e "${GREEN}  ✓ IP Ranges for ${country_code} Blocked Successfully.${NC}"

    sleep 3
    block_all_countries_ips
}

disable_country_ip_blocking() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Unblocking IP Ranges for a Selected Country${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    read -p "$(echo -e "${NEON_GREEN}  ▷ Enter the country initials ${DARK_SILVER}(e.g., CN, US)${RESET}${NEON_GREEN}: ${NC}")" country_code

    # Normalize input to uppercase
    country_code=$(echo "$country_code" | tr '[:lower:]' '[:upper:]')

    # Validate input
    if ! [[ "$country_code" =~ ^[A-Z]{2}$ ]]; then
        echo -e "${RED}  ✖ Invalid format. Please enter a valid Country Code.${NC}"
        sleep 3
        block_all_countries_ips
        return
    fi

    local ipv4_set="${country_code}_ipv4_blocklist"
    local ipv6_set="${country_code}_ipv6_blocklist"
    local iptables_chain="${country_code}_BLOCK"

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

    echo -e "${GREY}"
    echo -e "${GREEN}  ✓ IP Ranges for ${country_code} Unblocked Successfully.${NC}"
    sleep 3
    block_all_countries_ips
}

view_blocked_ip_ranges() {
    # Function to iptables & ipset persist
    source /usr/local/bin/Phoenix_Shield/scripts/rules_persist/rules_persist.sh
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • View Blocked IP Ranges.${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"

    # Retrieve and sort blocked countries alphabetically, excluding "INDV_<shortened_hash>" IP sets but allowing "speedtest_blocklist"
    local blocked_countries=($(ipset list 2>/dev/null | grep "Name:" | awk '{print $2}' | sed -e 's/_ipv[46]_blocklist//g' | grep -v "^INDV_" | grep -v "^speedtest_blocklist$" | grep -v "^ipscan_blocklist$" | sort -u | sort))

    if [ ${#blocked_countries[@]} -eq 0 ]; then
        echo -e "${RED}  ✖ No countries currently have blocked IP ranges.${NC}"
    else
        echo -e "${GREY}"
        echo -e "${PLAIN} ┌──────────────┬─────────────┬─────────────┐${NC}"
        printf " │ ${DARK_YELLOW}%-11s${NC} │ ${DARK_YELLOW}%-11s${NC} │ ${DARK_YELLOW}%-11s${NC} │\n" "Country Code" "IPv4 Ranges" "IPv6 Ranges"
        echo -e "${PLAIN} ├──────────────┤─────────────┤─────────────┤${NC}"

        for country in "${blocked_countries[@]}"; do
            local ipv4_set="${country}_ipv4_blocklist"
            local ipv6_set="${country}_ipv6_blocklist"
            
            # Error handling: Ensure ipset list runs without errors
            local ipv4_count=$(ipset list "$ipv4_set" 2>/dev/null | awk '/^[0-9]/ {count++} END {print count}' || echo "0")
            local ipv6_count=$(ipset list "$ipv6_set" 2>/dev/null | awk '/^[0-9]/ {count++} END {print count}' || echo "0")
            
            printf " │ ${GREEN}%-11s${NC}  │ ${RED}%-11s${NC} │ ${RED}%-11s${NC} │\n" "$country" "$ipv4_count" "$ipv6_count"
        done
        echo -e "${PLAIN} └──────────────┴─────────────┴─────────────┘${NC}"
    fi
    echo -e "\n${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "\n${CYAN}  ▷ Press ${RED}Enter${RESET}${CYAN} to return to the menu.${NC}"
    read
    block_all_countries_ips
}


display_help() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Help/Info${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "Use the country initials to select the IP ranges for blocking or unblocking."
    echo -e "\nBelow is a guide with country initials and their corresponding country names:"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"

    # Complete list of countries
    declare -A country_names=(
        ["AD"]="Andorra" ["AE"]="United Arab Emirates" ["AF"]="Afghanistan" ["AG"]="Antigua and Barbuda"
        ["AI"]="Anguilla" ["AL"]="Albania" ["AM"]="Armenia" ["AO"]="Angola"
        ["AQ"]="Antarctica" ["AR"]="Argentina" ["AS"]="American Samoa" ["AT"]="Austria"
        ["AU"]="Australia" ["AW"]="Aruba" ["AX"]="Aland Islands" ["AZ"]="Azerbaijan"
        ["BA"]="Bosnia and Herzegovina" ["BB"]="Barbados" ["BD"]="Bangladesh" ["BE"]="Belgium"
        ["BF"]="Burkina Faso" ["BG"]="Bulgaria" ["BH"]="Bahrain" ["BI"]="Burundi"
        ["BJ"]="Benin" ["BL"]="Saint Barthelemy" ["BM"]="Bermuda" ["BN"]="Brunei"
        ["BO"]="Bolivia" ["BQ"]="Bonaire" ["BR"]="Brazil" ["BS"]="Bahamas"
        ["BT"]="Bhutan" ["BV"]="Bouvet Island" ["BW"]="Botswana" ["BY"]="Belarus"
        ["BZ"]="Belize" ["CA"]="Canada" ["CC"]="Cocos Islands" ["CD"]="Congo"
        ["CF"]="Central African Republic" ["CG"]="Congo" ["CH"]="Switzerland" ["CI"]="Ivory Coast"
        ["CK"]="Cook Islands" ["CL"]="Chile" ["CM"]="Cameroon" ["CN"]="China"
        ["CO"]="Colombia" ["CR"]="Costa Rica" ["CU"]="Cuba" ["CV"]="Cape Verde"
        ["CW"]="Curacao" ["CY"]="Cyprus" ["CZ"]="Czech Republic" ["DE"]="Germany"
        ["DJ"]="Djibouti" ["DK"]="Denmark" ["DM"]="Dominica" ["DO"]="Dominican Republic"
        ["DZ"]="Algeria" ["EC"]="Ecuador" ["EE"]="Estonia" ["EG"]="Egypt"
        ["EH"]="Western Sahara" ["ER"]="Eritrea" ["ES"]="Spain" ["ET"]="Ethiopia"
        ["FI"]="Finland" ["FJ"]="Fiji" ["FK"]="Falkland Islands" ["FM"]="Micronesia"
        ["FO"]="Faroe Islands" ["FR"]="France" ["GA"]="Gabon" ["GB"]="United Kingdom"
        ["GD"]="Grenada" ["GE"]="Georgia" ["GF"]="French Guiana" ["GG"]="Guernsey"
        ["GH"]="Ghana" ["GI"]="Gibraltar" ["GL"]="Greenland" ["GM"]="Gambia"
        ["GN"]="Guinea" ["GP"]="Guadeloupe" ["GQ"]="Equatorial Guinea" ["GR"]="Greece"
        ["GT"]="Guatemala" ["GU"]="Guam" ["GW"]="Guinea-Bissau" ["GY"]="Guyana"
        ["HK"]="Hong Kong" ["HN"]="Honduras" ["HR"]="Croatia" ["HT"]="Haiti"
        ["HU"]="Hungary" ["ID"]="Indonesia" ["IE"]="Ireland" ["IL"]="Israel"
        ["IM"]="Isle of Man" ["IN"]="India" ["IO"]="British Indian Ocean" ["IQ"]="Iraq"
        ["IR"]="Iran" ["IS"]="Iceland" ["IT"]="Italy" ["JE"]="Jersey"
        ["JM"]="Jamaica" ["JO"]="Jordan" ["JP"]="Japan" ["KE"]="Kenya"
        ["KG"]="Kyrgyzstan" ["KH"]="Cambodia" ["KI"]="Kiribati" ["KM"]="Comoros"
        ["KN"]="Saint Kitts and Nevis" ["KP"]="North Korea" ["KR"]="South Korea" ["KW"]="Kuwait"
        ["KY"]="Cayman Islands" ["KZ"]="Kazakhstan" ["LA"]="Laos" ["LB"]="Lebanon"
        ["LC"]="Saint Lucia" ["LI"]="Liechtenstein" ["LK"]="Sri Lanka" ["LR"]="Liberia"
        ["LS"]="Lesotho" ["LT"]="Lithuania" ["LU"]="Luxembourg" ["LV"]="Latvia"
        ["LY"]="Libya" ["MA"]="Morocco" ["MC"]="Monaco" ["MD"]="Moldova"
        ["ME"]="Montenegro" ["MF"]="Saint Martin" ["MG"]="Madagascar" ["MH"]="Marshall Islands"
        ["MK"]="North Macedonia" ["ML"]="Mali" ["MM"]="Myanmar" ["MN"]="Mongolia"
        ["MO"]="Macao" ["MP"]="Northern Mariana Islands" ["MQ"]="Martinique" ["MR"]="Mauritania"
        ["MS"]="Montserrat" ["MT"]="Malta" ["MU"]="Mauritius" ["MV"]="Maldives"
        ["MW"]="Malawi" ["MX"]="Mexico" ["MY"]="Malaysia" ["MZ"]="Mozambique"
        ["NA"]="Namibia" ["NC"]="New Caledonia" ["NE"]="Niger" ["NF"]="Norfolk Island"
        ["NG"]="Nigeria" ["NI"]="Nicaragua" ["NL"]="Netherlands" ["NO"]="Norway"
        ["NP"]="Nepal" ["NR"]="Nauru" ["NU"]="Niue" ["NZ"]="New Zealand"
        ["OM"]="Oman" ["PA"]="Panama" ["PE"]="Peru" ["PF"]="French Polynesia"
        ["PG"]="Papua New Guinea" ["PH"]="Philippines" ["PK"]="Pakistan" ["PL"]="Poland"
        ["PM"]="Saint Pierre & Miquelon" ["PN"]="Pitcairn" ["PR"]="Puerto Rico" ["PS"]="Palestine"
        ["PT"]="Portugal" ["PW"]="Palau" ["PY"]="Paraguay" ["QA"]="Qatar"
        ["RE"]="Reunion" ["RO"]="Romania" ["RS"]="Serbia" ["RU"]="Russia"
        ["RW"]="Rwanda" ["SA"]="Saudi Arabia" ["SB"]="Solomon Islands" ["SC"]="Seychelles"
        ["SD"]="Sudan" ["SE"]="Sweden" ["SG"]="Singapore" ["SH"]="Saint Helena"
        ["SI"]="Slovenia" ["SJ"]="Svalbard & Jan Mayen" ["SK"]="Slovakia" ["SL"]="Sierra Leone"
        ["SM"]="San Marino" ["SN"]="Senegal" ["SO"]="Somalia" ["SR"]="Suriname"
        ["SS"]="South Sudan" ["ST"]="Sao Tome & Principe" ["SV"]="El Salvador" ["SX"]="Sint Maarten"
        ["SY"]="Syria" ["SZ"]="Eswatini" ["TC"]="Turks & Caicos Islands" ["TD"]="Chad"
        ["TF"]="French Southern" ["TG"]="Togo" ["TH"]="Thailand" ["TJ"]="Tajikistan"
        ["TK"]="Tokelau" ["TL"]="East Timor" ["TM"]="Turkmenistan" ["TN"]="Tunisia"
        ["TO"]="Tonga" ["TR"]="Turkey" ["TT"]="Trinidad and Tobago" ["TV"]="Tuvalu"
        ["TW"]="Taiwan" ["TZ"]="Tanzania" ["UA"]="Ukraine" ["UG"]="Uganda"
        ["UM"]="US Minor Outlying Islands" ["US"]="United States" ["UY"]="Uruguay" ["UZ"]="Uzbekistan"
        ["VA"]="Vatican" ["VC"]="Saint Vincent" ["VE"]="Venezuela" ["VG"]="British Virgin Islands"
        ["VI"]="US Virgin Islands" ["VN"]="Vietnam" ["VU"]="Vanuatu" ["WF"]="Wallis and Futuna"
        ["WS"]="Samoa" ["YE"]="Yemen" ["YT"]="Mayotte" ["ZA"]="South Africa"
        ["ZM"]="Zambia" ["ZW"]="Zimbabwe"
    )

    local sorted_codes=($(for code in "${!country_names[@]}"; do echo "$code"; done | sort))

    # Pagination settings
    local page_size=20
    local total=${#sorted_codes[@]}
    local pages=$(( (total + page_size - 1) / page_size ))

    for (( page=0; page<pages; page++ )); do
        clear
        echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
        echo -e "${PLAIN} ┌─────────────┬───────────────────────────┐${NC}"
        printf " │ ${DARK_YELLOW}%-11s${NC} │ ${DARK_YELLOW}%-25s${NC} │\n" "Initials" "Country Name"
        echo -e "${PLAIN} ├─────────────┼───────────────────────────┤${NC}"

        for (( i=page*page_size; i<(page+1)*page_size && i<total; i++ )); do
            printf " │ ${GREEN}%-11s${NC} │ ${CYAN}%-25s${NC} │\n" "${sorted_codes[i]}" "${country_names[${sorted_codes[i]}]}"
        done

        echo -e "${PLAIN} └─────────────┴───────────────────────────┘${NC}"
        echo -e "${DARK_YELLOW}  Page $((page + 1)) of $pages${NC}"
        echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"

        # Navigation
        if (( page < pages - 1 )); then
            echo -e "${GREY}"
            echo -e "${CYAN}  ▷ Press ${DARK_YELLOW}ENTER${CYAN} for Next Page.${NC}"
            echo -e "${CYAN}  ▷ Press ${RED}""Q""${CYAN} to Quit.${NC}"
        else
            echo -e "${CYAN}  ▷ End of list. Press ${RED}Q${CYAN} to quit.${NC}"
        fi

        read -r -n 1 input
        if [[ "$input" == "q" || "$input" == "Q" ]]; then
            break  # Exit
        elif [[ "$input" != "" ]]; then
            ((page--))  # Stay on current page for invalid input
        fi
    done
    block_all_countries_ips
}

block_all_countries_ips