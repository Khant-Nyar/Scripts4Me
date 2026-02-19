#!/bin/bash

readonly BRUTEFORCE_SEVERITY="HIGH"
readonly BRUTEFORCE_THRESHOLD=10

BruteForceDetector::run() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/bruteforce_hits.log"
    local first_file="$workspace/first_bruteforce.log"
    local ip_counts="$workspace/bruteforce_ips.txt"
    
    local status_codes="401|403"
    local auth_patterns="login|auth|admin|dashboard|wp-login|xmlrpc|signin|password|forgot"
    
    awk -F'"' -v status="$status_codes" -v patterns="$auth_patterns" '
    $2 ~ patterns && $0 ~ status {
        gsub(/^[ \t]+/, "", $1)
        split($1, parts, " ")
        if (parts[1] ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
            print parts[1]
        }
    }
    ' "$log_file" | sort | uniq -c | sort -rn > "$ip_counts"
    
    awk -v threshold='"$BRUTEFORCE_THRESHOLD"' '
    $1 >= threshold {
        ip = $2
        print ip
    }
    ' "$ip_counts" > "$workspace/bruteforce_ips_filtered.txt"
    
    if [[ -s "$workspace/bruteforce_ips_filtered.txt" ]]; then
        local ips
        ips=$(tr '\n' '|' < "$workspace/bruteforce_ips_filtered.txt" | sed 's/|$//')
        
        grep -E "^($ips) " "$log_file" > "$output_file"
        
        head -1 "$output_file" > "$first_file"
    else
        touch "$output_file"
        touch "$first_file"
    fi
    
    local count
    count=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    
    if [[ $count -gt 0 ]]; then
        echo '{"detector":"BruteForceDetector","severity":"HIGH","count":'$count'}'
    fi
}

BruteForceDetector::get_severity() {
    echo "$BRUTEFORCE_SEVERITY"
}

BruteForceDetector::get_threshold() {
    echo "$BRUTEFORCE_THRESHOLD"
}
