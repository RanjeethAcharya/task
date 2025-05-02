#!/bin/bash

r='\033[0;31m'
g='\033[0;32m'
nc='\033[0m'

refresh=4

top_apps() {
    echo -e "\nTop 10 Applications (CPU & Memory):"
    echo -e "\n|--------CPU--------|"
    ps -eo pid,comm,%cpu --sort=-%cpu | head -n 11
    echo -e "\n|--------Mem--------|"
    ps -eo pid,comm,%mem --sort=-%mem | head -n 11
}



network() {
    echo -e "\n+-------------------Network Monitoring----------------------+"
    echo -e "\n--- Concurrent Connections ---"
    count=$(ss -s | grep estab | awk '{print $4}')
    echo "Number of connections: $count"
    echo -e "\n--- Packet Drops Since Boot ---"
    netstat -s | grep -i "dropped\|segments retransmitted" | while read -r line; do
        echo "- $line"
    done
    echo -e "\n--- Network Data Transfer (MB) ---"
    RX=$(awk '/eth0|ens|enp|eno/ {sum += $2} END {print sum}' /proc/net/dev)
    TX=$(awk '/eth0|ens|enp|eno/ {sum += $10} END {print sum}' /proc/net/dev)
    RX_MB=$(echo "scale=2; $RX/1024/1024" | bc)
    TX_MB=$(echo "scale=2; $TX/1024/1024" | bc)

    echo "Data Received: ${RX_MB} MB"
    echo "Data Transmitted: ${TX_MB} MB"
}




disk_usage() {
    echo -e "\n+------------------------Disk Usage-------------------------+"
    echo ""
    df -h | awk 'NR==1 || $5+0 > 0 {print $0}'
    echo -e "\n${r}----Partitions over 80% usage----${nc}"
    df -h | awk '$5+0 > 80 {print $0}'
}



system_load() {
    echo -e "\n+------------------------System Load------------------------+"
    echo ""
    echo "Load Average: $(uptime | awk -F'load average:' '{ print $2 }')"
    echo -n "CPU Usage: "
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    printf "%.1f%%\n" "$cpu_idle"
}


memory_usage() {
    echo -e "\n+-----------------------Memory Usage------------------------+"
    echo ""
    free -h
}


service_monitor() {
    echo -e "\n+----------------------Service Status-----------------------+"
    echo ""
    for service in sshd nginx apache2 iptables; do
        if systemctl is-active --quiet "$service"; then
            echo -e "$service: ${g}[RUNNING]${nc}"
        else
            echo -e "$service: ${r}[STOPPED]${nc}"
        fi
    done
}



process() {
    echo -e "\n+-------------------Process Monitoring----------------------+"
    echo "Total Active Processes: $(ps aux | wc -l)"
    echo -e "\nTop 5 Processes:"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
}

print_dashboard() {
    clear
    echo "================================================================================="
    echo "|                           SYSTEM MONITOR DASHBOARD                            |"
    echo "================================================================================="
    top_apps
    network
    disk_usage
    system_load
    memory_usage
    process
    service_monitor
    
    echo -e "\n================================================================================="
    echo "|                  Press [Ctrl+C] to exit | Refreshing every ${refresh}s…                |"
    echo "================================================================================="
}
while [[ $# -gt 0 ]]; do
    case $1 in
        -cpu) system_load ;;
        -memory) memory_usage ;;
        -disk) disk_usage ;;
        -processes) process ;;
        -network) network ;;
        -services) service_monitor ;;
        -top) top_apps ;;
        -all) print_dashboard ;;
        *) echo "Usage: $0 [-cpu] [-memory] [-disk] [-network] [-processes] [-services] [-top] [-all]"; exit 1 ;;
    esac
    exit 0
done
while true; do
    print_dashboard
    sleep "$refresh"
done
