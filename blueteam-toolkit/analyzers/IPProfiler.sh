#!/bin/bash

IPProfiler::analyze() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/top_ips.txt"
    local ua_file="$workspace/top_user_agents.txt"
    local all_ips_file="$workspace/all_attacker_ips.txt"
    
    local -a hit_files=(
        "$workspace/sqli_hits.log"
        "$workspace/rce_hits.log"
        "$workspace/backdoor_hits.log"
        "$workspace/bruteforce_hits.log"
        "$workspace/xss_hits.log"
        "$workspace/path_hits.log"
        "$workspace/log4j_hits.log"
        "$workspace/file_hits.log"
        "$workspace/enum_hits.log"
    )
    
    > "$all_ips_file"
    
    for file in "${hit_files[@]}"; do
        if [[ -f "$file" ]]; then
            awk '{print $1}' "$file" 2>/dev/null >> "$all_ips_file"
        fi
    done
    
    if [[ -s "$all_ips_file" ]]; then
        sort "$all_ips_file" | uniq -c | sort -rn | head -30 > "$output_file"
    else
        touch "$output_file"
    fi
    
    local -a scan_files=(
        "$workspace/sqli_hits.log"
        "$workspace/rce_hits.log"
        "$workspace/backdoor_hits.log"
        "$workspace/bruteforce_hits.log"
        "$workspace/xss_hits.log"
        "$workspace/path_hits.log"
        "$workspace/log4j_hits.log"
        "$workspace/scanner_hits.log"
        "$workspace/file_hits.log"
        "$workspace/enum_hits.log"
    )
    
    > "$workspace/all_user_agents.txt"
    
    for file in "${scan_files[@]}"; do
        if [[ -f "$file" ]]; then
            awk -F'"' '{print $6}' "$file" 2>/dev/null >> "$workspace/all_user_agents.txt"
        fi
    done
    
    if [[ -s "$workspace/all_user_agents.txt" ]]; then
        sort "$workspace/all_user_agents.txt" | uniq -c | sort -rn | head -20 > "$ua_file"
    else
        touch "$ua_file"
    fi
    
    local ip_count
    ip_count=$(wc -l < "$output_file")
    
    echo "IP profiling complete: $ip_count unique attacker IPs identified"
}

IPProfiler::get_top_attackers() {
    local workspace="$1"
    local limit="${2:-10}"
    
    if [[ -f "$workspace/top_ips.txt" ]]; then
        head -"$limit" "$workspace/top_ips.txt"
    fi
}

IPProfiler::profile_ip() {
    local ip="$1"
    local log_file="$2"
    
    local count
    count=$(grep "^$ip " "$log_file" | wc -l)
    
    local methods
    methods=$(grep "^$ip " "$log_file" | awk '{print $6}' | sort -u | tr '\n' ',' | sed 's/,$//')
    
    local status_codes
    status_codes=$(grep "^$ip " "$log_file" | awk '{print $9}' | sort -u | tr '\n' ',' | sed 's/,$//')
    
    echo "IP: $ip"
    echo "Requests: $count"
    echo "Methods: $methods"
    echo "Status Codes: $status_codes"
}
