#!/bin/bash

#******************************************************************#
# Title: SSH Management
# Description: Manage SSH settings such as port and password
# Author: Phoenix-999
# Link: github.com/Phoenix-999
# Date: Jan 2, 2025
#******************************************************************#

# Import shared functions and variables
source /usr/local/bin/Phoenix_Shield/scripts/shared_functions/shared_functions.sh

#******************************************************************#
# Manage SSH settings
#******************************************************************#
# Define the location of the iptables rules file
RULES_FILE="/etc/iptables/rules.v4"

# Function to ensure the iptables rules file exists
ensure_rules_file() {
    if [ ! -d "/etc/iptables" ]; then
        #echo "Warning: /etc/iptables directory not found. Creating it..." >&2
        sudo mkdir -p "/etc/iptables"
        if [ $? -ne 0 ]; then
            log_error "Failed to create directory /etc/iptables."
            return 1
        fi
    fi

    if [ ! -f "$RULES_FILE" ]; then
        #echo "Warning: $RULES_FILE not found. Creating it..." >&2
        sudo touch "$RULES_FILE"
        if [ $? -ne 0 ]; then
            log_error "Failed to create file $RULES_FILE."
            return 1
        fi
        sudo chmod 644 "$RULES_FILE"
    fi
}

# Example usage in close_port function
if ! ensure_rules_file; then
    #echo "Error: Unable to create rules file. Exiting..."
    return 1
fi


##############################################
# 1) Change SSH port & password
# Adjusts the SSH port and password settings
##############################################

change_ssh_settings() {
    clear
    while true; do
        # Retrieve the current SSH port
        local ssh_config="/etc/ssh/sshd_config"
        local current_port
        current_port=$(grep -E '^Port ' "$ssh_config" | awk '{print $2}')
        current_port=${current_port:-22}  # Default to 22 if no port is found

        # Display submenu
        echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
        echo -e "${GREY}"
        echo -e "${DARK_YELLOW}  • Manage SSH Settings${NC}"
        echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
        echo -e "${GREY}"
        echo -e "${BLUE}| 1)  - Change SSH Port"
        echo -e "${BLUE}| 2)  - Change SSH Password"
        echo -e "${BLUE}| 3)  - View Current SSH Settings"
        echo -e "${GREY}"
        echo -e "${DARK_RED}| 0)  - Return to Main Menu${NC}"
        echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
        echo -e "${GREY}"

        # Prompt user for choice
        read -p "$(echo -e "${NEON_GREEN}  ▷ Enter your choice (${RED}0-3${RESET}${NEON_GREEN}): ${NC}")" choice
        clear

        case $choice in
            1) change_ssh_port ;;
            2) change_ssh_password ;;
            3) view_current_ssh_settings ;;
            0) return ;;
            *)
                echo -e "${RED}  ✖ Invalid choice! Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

change_ssh_port() {
    clear
    local ssh_config="/etc/ssh/sshd_config"
    local ssh_socket_config="/lib/systemd/system/ssh.socket"
    local current_port
    current_port=$(grep -E '^Port ' "$ssh_config" | awk '{print $2}')
    current_port=${current_port:-22}  # Default to 22 if no port is found

    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Change SSH Port${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${BLUE}  • Current SSH Port: ${NEON_GREEN}${current_port}${NC}"

    while true; do
        echo -e "${GREY}"
        echo -ne "${NEON_GREEN}  ▷ Enter new SSH Port ${DARK_SILVER}(leave blank to keep current)${RESET}${NEON_GREEN}: ${NC}"
        read -r new_port

        if [[ -z "$new_port" ]]; then
            echo -e "${GREEN}  • Keeping the current SSH port: ${current_port}${NC}"
            new_port=$current_port
            break
        elif [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
            # Check if the port is already in use
            if sudo lsof -i -P -n | grep -q ":$new_port"; then
                echo -e "${RED}  ✖ Port ${new_port} is busy. Please choose a different port.${NC}"
                continue
            fi

            # Check if the port is blocked by the firewall
            if ! sudo iptables -L INPUT -n | grep -q "dpt:$new_port"; then
                echo -e "${PURPLE}  • Opening port ${new_port} in the firewall...${NC}"
                if ! sudo iptables -A INPUT -p tcp --dport $new_port -j ACCEPT; then
                    log_error "Failed to open port $new_port in the firewall."
                    return
                fi
                ensure_rules_file
                if ! sudo iptables-save > "$RULES_FILE"; then
                    log_error "Failed to save iptables rules to $RULES_FILE."
                    return
                fi
                echo -e "${GREEN}  • Port ${new_port} is now open.${NC}"
            fi

            echo -e "${PURPLE}  \u25b7 Updating SSH Port to ${new_port}...${NC}"

            # Update SSH port in configuration file
            if grep -q "^Port " "$ssh_config"; then
                sudo sed -i "s/^Port .*/Port ${new_port}/" "$ssh_config"
            else
                echo "Port ${new_port}" | sudo tee -a "$ssh_config" > /dev/null
            fi

            # Update ssh.socket configuration if it exists
            if [[ -f "$ssh_socket_config" ]]; then
                sudo sed -i "/ListenStream=/d" "$ssh_socket_config"
                echo -e "ListenStream=${new_port}" | sudo tee -a "$ssh_socket_config" > /dev/null
            fi

            # Restart SSH services
            sudo systemctl daemon-reload
            sudo systemctl restart ssh
            sudo systemctl restart ssh.socket || true

            echo -e "${GREEN}  ✓ SSH Port updated successfully to ${new_port}.${NC}"

            # Close the previous port for security
            if [[ "$new_port" != "$current_port" ]]; then
                echo -e "${PURPLE}  • Closing the old port ${current_port} in the firewall...${NC}"
                if sudo iptables -D INPUT -p tcp --dport $current_port -j ACCEPT 2>/dev/null; then
                    ensure_rules_file
                    if ! sudo iptables-save > "$RULES_FILE"; then
                        log_error "Failed to save iptables rules after closing port $current_port."
                        return
                    fi
                    echo -e "${DARK_YELLOW}  • Old port ${current_port} is now closed.${NC}"
                else
                    echo -e "${PURPLE}  • No existing rule found for port ${current_port} in the firewall. Skipping.${NC}"
                fi
            fi

            break
        else
            echo -e "${RED}  ✖ Invalid Port. Enter a number between 1 and 65535.${NC}"
        fi
    done
    sleep 3
    clear
}


change_ssh_password() {
    clear
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Change SSH Password${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"

    while true; do
        echo -e "${GREY}"
        echo -ne "${NEON_GREEN}  ▷ Enter new SSH Password: ${NC}"
        read -s new_password
        echo

        if [[ -z "$new_password" ]]; then
            echo -e "${RED}  ✖ Password cannot be empty. Please try again.${NC}"
        else
            echo -ne "${NEON_GREEN}  ▷ Confirm new SSH password: ${NC}"
            read -s confirm_password
            echo

            if [[ "$new_password" == "$confirm_password" ]]; then
                echo -e "${PURPLE}  • Updating SSH password...${NC}"

                # Change the password for the user (default to root)
                echo -e "${USER}:${new_password}" | sudo chpasswd

                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}  ✓ SSH password updated successfully.${NC}"

                    # Ensure SSH configuration allows password-based authentication
                    local ssh_config="/etc/ssh/sshd_config"
                    if grep -q "^PasswordAuthentication" "$ssh_config"; then
                        sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "$ssh_config"
                    else
                        echo "PasswordAuthentication yes" | sudo tee -a "$ssh_config" > /dev/null
                    fi

                    if grep -q "^PermitRootLogin" "$ssh_config"; then
                        sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' "$ssh_config"
                    else
                        echo "PermitRootLogin yes" | sudo tee -a "$ssh_config" > /dev/null
                    fi

                    # Restart SSH service to apply changes
                    echo -e "${PURPLE}  • Restarting SSH service...${NC}"
                    sudo systemctl restart ssh

                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}  ✓ SSH service restarted successfully.${NC}"
                    else
                        echo -e "${RED}  ✖ Failed to restart SSH service. Please check manually.${NC}"
                    fi
                else
                    echo -e "${RED}  ✖ Failed to update SSH password. Please verify system permissions.${NC}"
                fi
                break
            else
                echo -e "${RED}  ✖ Passwords do not match. Please try again.${NC}"
            fi
        fi
    done
    sleep 3
    clear
}

view_current_ssh_settings() {
    clear
    local ssh_config="/etc/ssh/sshd_config"
    local current_port
    current_port=$(grep -E '^Port ' "$ssh_config" | awk '{print $2}')
    current_port=${current_port:-22}  # Default to 22 if no port is found

    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${DARK_YELLOW}  • Current SSH Settings${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "${GREY}"
    echo -e "${BLUE}  • SSH Port: ${NEON_GREEN}${current_port}${NC}"
    echo -e "${GREY}"
    echo -e "${NEON_GREEN}  ✓ ${RESET}  ${DARK_YELLOW}ssh -p ${GREEN}${current_port}${RESET}${DARK_YELLOW} ${USER}@$(hostname -I | awk '{print $1}')${NC}"
    echo -e "${DARK_SILVER}${BOLD} ____________________________________________${NC}"
    echo -e "\n${CYAN}  \u25b7 Press ${RED}Enter${RESET}${CYAN} to return to the menu.${NC}"
    read
    sleep
    clear
}

change_ssh_settings