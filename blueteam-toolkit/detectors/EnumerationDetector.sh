#!/bin/bash

readonly ENUMERATION_SEVERITY="MEDIUM"
readonly ENUMERATION_THRESHOLD=30

EnumerationDetector::run() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/enum_hits.log"
    local first_file="$workspace/first_enum.log"
    local ip_counts="$workspace/enum_ips.txt"
    
    awk '$9 == "404" || $9 == "400" || $9 == "403" || $9 == "405" {
        gsub(/^[ \t]+/, "", $1)
        split($1, parts, " ")
        if (parts[1] ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
            print parts[1]
        }
    }
    ' "$log_file" | sort | uniq -c | sort -rn > "$ip_counts"
    
    awk -v threshold="$ENUMERATION_THRESHOLD" '
    $1 >= threshold {
        print $2
    }
    ' "$ip_counts" > "$workspace/enum_ips_filtered.txt"
    
    if [[ -s "$workspace/enum_ips_filtered.txt" ]]; then
        local ips
        ips=$(tr '\n' '|' < "$workspace/enum_ips_filtered.txt" | sed 's/|$//')
        
        grep -E "^($ips) " "$log_file" | awk '$9 == "404" || $9 == "400" || $9 == "403" || $9 == "405"' > "$output_file"
        
        head -1 "$output_file" > "$first_file"
    else
        touch "$output_file"
        touch "$first_file"
    fi
    
    local count
    count=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    
    if [[ $count -gt 0 ]]; then
        echo '{"detector":"EnumerationDetector","severity":"MEDIUM","count":'$count'}'
    fi
}

EnumerationDetector::get_severity() {
    echo "$ENUMERATION_SEVERITY"
}

EnumerationDetector::get_threshold() {
    echo "$ENUMERATION_THRESHOLD"
}
