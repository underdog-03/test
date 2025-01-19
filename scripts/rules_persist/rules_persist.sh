#!/bin/bash

#******************************************************************#
# Title: Shared Functions
# Description: Common functions and variables used across scripts
# Author: Phoenix-999
# Link: github.com/Phoenix-999
# Date: Jan 2, 2025
#******************************************************************#



##############################################
# Function to save iptables and ipset rules
##############################################
save_iptables_and_ipset_rules() {

    # Define the base path for scripts
    BASE_PATH="/usr/local/bin/Phoenix_Shield"

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
    clear
}

##############################################
# Function to create and enable the ipset-restore systemd service
##############################################
create_ipset_restore_service() {
    # Create the systemd service file for restoring ipset rules on boot
    cat > /etc/systemd/system/ipset-restore.service <<EOF
[Unit]
Description=Restore ipset rules
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'if ! /sbin/ipset list | grep -q "IR_ipv4_blocklist"; then /sbin/ipset restore -f /etc/ipset.rules; fi'
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to recognize the new service
    # sudo systemctl daemon-reload

    # Enable and start the ipset-restore service to restore ipset rules on boot
    sudo systemctl enable ipset-restore.service
    sudo systemctl start ipset-restore.service
    clear
}

# Call the function to save iptables and ipset rules
    #save_iptables_and_ipset_rules

# Call the function to create and enable the ipset-restore service
    #create_ipset_restore_service


##############################################################
####################### End of Script ########################
##############################################################