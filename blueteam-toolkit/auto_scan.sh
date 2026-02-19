#!/bin/bash

readonly AUTO_SCAN_VERSION="1.0.0"

source "$(dirname "${BASH_SOURCE[0]}")/core/Colors.sh"

AutoScanner::run() {
    local bold red yellow green reset
    bold=$(Colors::get BOLD)
    red=$(Colors::get RED)
    yellow=$(Colors::get YELLOW)
    green=$(Colors::get GREEN)
    reset=$(Colors::reset)
    
    echo ""
    echo "============================================================"
    echo " AUTO SYSTEM SCAN - DETECTOR"
    echo "============================================================"
    echo ""
    
    AutoScanner::check_access_logs "$red" "$yellow" "$green" "$bold" "$reset"
    AutoScanner::check_system_processes "$red" "$yellow" "$bold" "$reset"
    AutoScanner::check_backdoors "$red" "$yellow" "$bold" "$reset"
    AutoScanner::check_shells "$red" "$yellow" "$bold" "$reset"
    AutoScanner::check_suspicious_files "$yellow" "$bold" "$reset"
    AutoScanner::check_network_connections "$bold" "$reset"
    AutoScanner::check_cron_jobs "$bold" "$reset"
    AutoScanner::check_rootkit_indicators "$red" "$yellow" "$bold" "$reset"
    
    echo ""
    echo "============================================================"
    echo " AUTO SCAN COMPLETED"
    echo "============================================================"
}

AutoScanner::check_access_logs() {
    local red=$1 yellow=$2 green=$3 bold=$4 reset=$5
    
    echo -e "${bold}[*] Checking Access Logs...${reset}"
    
    local found_logs=""
    
    for dir in "/var/log/apache2" "/var/log/nginx" "/var/log/httpd" "/var/log" "/var/www/logs" "."; do
        if [[ -d "$dir" ]]; then
            found_logs=$(find "$dir" -name "access.log*" -o -name "access_log*" 2>/dev/null)
            if [[ -n "$found_logs" ]]; then
                break
            fi
        fi
    done
    
    if [[ -n "$found_logs" ]]; then
        echo "  Found access logs:"
        echo "$found_logs" | head -5 | while read -r log; do
            echo "    - $log"
        done
        
        if [[ -f "./blueteam.sh" ]]; then
            echo "  Running log analysis..."
            echo "$found_logs" | head -3 | while read -r log; do
                if [[ -r "$log" ]]; then
                    ./blueteam.sh --quiet "$log" 2>/dev/null
                fi
            done
        fi
    else
        echo "  No access logs found"
    fi
}

AutoScanner::check_system_processes() {
    local red=$1 yellow=$2 bold=$3 reset=$4
    
    echo -e "${bold}[*] Checking System Processes...${reset}"
    
    echo "  Top 5 processes:"
    ps -eo pid,pcpu,pmem,comm 2>/dev/null | head -6
    
    echo ""
    echo "  Suspicious processes:"
    local suspicious
    suspicious=$(ps -eo pid,comm 2>/dev/null | grep -iE "nc |ncat |netcat |socat |python.*http |ruby.*-e |perl.*-e |bash.*-i |sh.*-i |mkfifo" | grep -v grep)
    
    if [[ -n "$suspicious" ]]; then
        echo -e "    ${red}$suspicious${reset}"
    else
        echo "    No suspicious processes detected"
    fi
}

AutoScanner::check_backdoors() {
    local red=$1 yellow=$2 bold=$3 reset=$4
    
    echo -e "${bold}[*] Checking for Backdoors...${reset}"
    
    echo "  Checking for known backdoor filenames in web dirs..."
    
    local backdoor_found=false
    for dir in "/var/www" "/home" "/tmp" "/var/tmp"; do
        if [[ -d "$dir" ]]; then
            local results
            results=$(find "$dir" -type f \( -name "*.php" -o -name "*.sh" \) -iname "*c99*" -o -name "*r57*" -o -name "*shell*" -o -name "*webshell*" -o -name "*backdoor*" 2>/dev/null | head -5)
            if [[ -n "$results" ]]; then
                echo -e "    ${red}$results${reset}"
                backdoor_found=true
            fi
        fi
    done
    
    if [[ "$backdoor_found" == "false" ]]; then
        echo "    No known backdoor files found"
    fi
    
    echo "  Checking for SUID files:"
    find / -perm -4000 -type f 2>/dev/null | head -5
}

AutoScanner::check_shells() {
    local red=$1 yellow=$2 bold=$3 reset=$4
    
    echo -e "${bold}[*] Checking for Suspicious Shells...${reset}"
    
    echo "  Checking for reverse shell indicators:"
    local shells
    shells=$(ps aux 2>/dev/null | grep -iE "/dev/tcp|/dev/udp|bash -i|sh -i|nc -e|ncat -e|python.*socket" | grep -v grep)
    
    if [[ -n "$shells" ]]; then
        echo -e "    ${red}$shells${reset}"
    else
        echo "    No active reverse shells detected"
    fi
    
    echo ""
    echo "  Checking SSH authorized_keys:"
    local ssh_keys
    ssh_keys=$(find /home -name "authorized_keys" -type f 2>/dev/null)
    if [[ -n "$ssh_keys" ]]; then
        echo -e "    ${yellow}$ssh_keys${reset}"
    else
        echo "    No unauthorized SSH keys found"
    fi
}

AutoScanner::check_suspicious_files() {
    local yellow=$1 bold=$2 reset=$3
    
    echo -e "${bold}[*] Checking for Suspicious Files...${reset}"
    
    echo "  Recently modified executables (last 24h):"
    find /usr/bin /usr/sbin /bin /sbin -type f -mtime -1 2>/dev/null | head -5
    
    echo ""
    echo "  World-writable directories:"
    find / -type d -perm -002 2>/dev/null | grep -v "^/proc" | grep -v "^/sys" | head -5
}

AutoScanner::check_network_connections() {
    local bold=$1 reset=$2
    
    echo -e "${bold}[*] Checking Network Connections...${reset}"
    
    if command -v netstat &>/dev/null; then
        echo "  Established connections:"
        netstat -tn 2>/dev/null | grep ESTABLISHED | head -5
        
        echo ""
        echo "  Listening ports:"
        netstat -tln 2>/dev/null | grep LISTEN | head -5
    elif command -v ss &>/dev/null; then
        echo "  Established connections:"
        ss -tn 2>/dev/null | grep ESTABLISHED | head -5
        
        echo ""
        echo "  Listening ports:"
        ss -tln 2>/dev/null | grep LISTEN | head -5
    else
        echo "  No network tools available"
    fi
}

AutoScanner::check_cron_jobs() {
    local bold=$1 reset=$2
    
    echo -e "${bold}[*] Checking Cron Jobs...${reset}"
    
    echo "  System crontab:"
    cat /etc/crontab 2>/dev/null | grep -v "^#" | head -5
    
    echo ""
    echo "  Cron directories:"
    for dir in /etc/cron.d /etc/cron.hourly /etc/cron.daily; do
        if [[ -d "$dir" ]]; then
            echo "    $dir:"
            ls -la "$dir" 2>/dev/null | tail -n +4 | head -3
        fi
    done
}

AutoScanner::check_rootkit_indicators() {
    local red=$1 yellow=$2 bold=$3 reset=$4
    
    echo -e "${bold}[*] Checking Rootkit Indicators...${reset}"
    
    echo "  Kernel modules:"
    ls /proc/modules 2>/dev/null | head -5
    
    echo ""
    echo "  Process count comparison:"
    local proc_count ps_count
    proc_count=$(ls /proc/ 2>/dev/null | grep -E "^[0-9]+$" | wc -l)
    ps_count=$(ps -eo pid 2>/dev/null | wc -l)
    echo "    /proc entries: $proc_count"
    echo "    ps entries: $ps_count"
    
    if [[ $((proc_count - ps_count)) -gt 5 ]]; then
        echo -e "    ${red}WARNING: Possible hidden processes${reset}"
    fi
    
    echo ""
    echo "  Recent login failures:"
    if [[ -f "/var/log/auth.log" ]]; then
        grep -i "failed password" /var/log/auth.log 2>/dev/null | tail -3
    elif [[ -f "/var/log/secure" ]]; then
        grep -i "failed password" /var/log/secure 2>/dev/null | tail -3
    else
        echo "    No auth logs available"
    fi
}
