#!/bin/bash

TimelineAnalyzer::analyze() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/timeline.txt"
    
    local log_format
    log_format=$(detect_log_format "$log_file")
    
    case "$log_format" in
        "apache_combined"|"nginx")
            awk -F'[' '{print $2}' "$log_file" 2>/dev/null | \
                awk '{print $1}' | \
                cut -d: -f1,2 | \
                sort | uniq -c | sort -rn > "$output_file"
            ;;
        "apache_common")
            awk '{print $4}' "$log_file" 2>/dev/null | \
                cut -d: -f1,2 | \
                sort | uniq -c | sort -rn > "$output_file"
            ;;
        *)
            awk '{print $4}' "$log_file" 2>/dev/null | \
                cut -d: -f1,2 | \
                sort | uniq -c | sort -rn > "$output_file"
            ;;
    esac
    
    TimelineAnalyzer::attack_timeline "$workspace"
    
    echo "Timeline analysis complete"
}

TimelineAnalyzer::attack_timeline() {
    local workspace="$1"
    local attack_timeline="$workspace/attack_timeline.txt"
    
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
    
    > "$attack_timeline"
    
    for file in "${hit_files[@]}"; do
        if [[ -f "$file" && -s "$file" ]]; then
            local detector
            detector=$(basename "$file" | sed 's/_hits.log//' | sed 's/_/ /g' | awk '{print toupper($0)}')
            
            head -5 "$file" | while read -r line; do
                echo "$detector: $line" >> "$attack_timeline"
            done
        fi
    done
    
    sort "$attack_timeline" | uniq > "${attack_timeline}.tmp"
    mv "${attack_timeline}.tmp" "$attack_timeline"
}

detect_log_format() {
    local log_file="$1"
    
    local first_line
    first_line=$(head -1 "$log_file")
    
    if echo "$first_line" | grep -q '\[.*\]";'; then
        echo "apache_combined"
    elif echo "$first_line" | grep -q '\[.*\]'; then
        echo "apache_common"
    else
        echo "unknown"
    fi
}

TimelineAnalyzer::get_hourly_distribution() {
    local workspace="$1"
    local log_file="$2"
    
    awk -F'[' '{print $2}' "$log_file" 2>/dev/null | \
        awk '{print $1}' | \
        cut -d: -f1 | \
        sort | uniq -c | sort -k2n
}

TimelineAnalyzer::get_daily_distribution() {
    local workspace="$1"
    local log_file="$2"
    
    awk -F'/' '{print $2}' "$log_file" 2>/dev/null | \
        awk '{print $1}' | \
        sort | uniq -c | sort -k2n
}
