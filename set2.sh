#!/bin/bash

g="\e[32m"
r="\e[31m"
nc="\e[0m"

pause() {
    echo -e "\nPress Enter to continue..."
    read
}
heading() {
    clear
    echo -e "${g}=== Linux Security Audit Tool ===${nc}"
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo ""
}
user_audit() {
    heading
    echo -e "${g}User and Group Audit:${nc}"
    echo -e "\nUsers with UID 0 (should be root only):"
    awk -F: '($3 == 0) {print $1}' /etc/passwd
    echo -e "\nUsers with empty passwords:"
    awk -F: '($2 == "" || $2 == "*") {print $1}' /etc/shadow
    echo -e "\nAll Users:"
    cut -d: -f1 /etc/passwd | column
    pause
}
permission_check() {
    heading
    echo -e "${g}Checking for world-writable files...${nc}"
    find / -xdev -type f -perm -0002 -ls 2>/dev/null | head -n 20

    echo -e "\n${g}SUID/SGID files:${nc}"
    find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null | head -n 20
    pause
}
service_check() {
    heading
    echo -e "${g}Running services:${nc}"
    systemctl list-units --type=service --state=running | grep '.service'

    echo -e "\n${g}Checking critical services:${nc}"
    for svc in sshd iptables ufw; do
        systemctl is-active --quiet $svc && echo "$svc: ${g}RUNNING${nc}" || echo "$svc: ${r}NOT RUNNING${nc}"
    done
    pause
}
network_check() {
    heading
    echo -e "${g}Open Ports:${nc}"
    ss -tuln | grep -E 'LISTEN|UDP'

    echo -e "\nIPv4 Forwarding: $(sysctl -n net.ipv4.ip_forward)"
    pause
}
ip_info() {
    heading
    echo -e "${g}IP Addresses (private/public):${nc}"
    ip -4 addr | grep inet

    echo -e "\nPublic IP:"
    curl -s ifconfig.me
    pause
}
patch_status() {
    heading
    echo -e "${g}Security Updates:${nc}"
    if command -v apt &>/dev/null; then
        apt update > /dev/null
        apt list --upgradable | grep security
    elif command -v yum &>/dev/null; then
        yum check-update --security
    fi
    pause
}
logs_check() {
    heading
    echo -e "${g}Recent SSH Login Failures:${nc}"
    grep "Failed password" /var/log/auth.log | tail -10
    pause
}
hardening_tips() {
    heading
    echo -e "${g}Basic Hardening Recommendations:${nc}"
    echo "1. Disable root SSH login"
    echo "2. Use SSH keys instead of passwords"
    echo "3. Set GRUB password"
    echo "4. Configure firewall rules"
    echo "5. Disable IPv6 if unused"
    echo "6. Enable unattended security updates"
    pause
}
main_menu() {
    while true; do
        heading
        echo -e "${g}Select an option:${nc}"
        echo "1) User and Group Audit"
        echo "2) Permission Check"
        echo "3) Running Services"
        echo "4) Network and Firewall"
        echo "5) IP and Exposure"
        echo "6) Security Patches"
        echo "7) SSH Log Monitoring"
        echo "8) Hardening Tips"
        echo "9) Run All Checks"
        echo "0) Exit"
        read -p "Enter your choice: " choice

        case "$choice" in
            1) user_audit ;;
            2) permission_check ;;
            3) service_check ;;
            4) network_check ;;
            5) ip_info ;;
            6) patch_status ;;
            7) logs_check ;;
            8) hardening_tips ;;
            9)
                user_audit
                permission_check
                service_check
                network_check
                ip_info
                patch_status
                logs_check
                hardening_tips
                ;;
            0) exit ;;
            *) echo "Invalid option!" ; pause ;;
        esac
    done
}

main_menu
