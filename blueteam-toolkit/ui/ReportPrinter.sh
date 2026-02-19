#!/bin/bash

ReportPrinter::print_results() {
    local workspace="$1"
    local findings_json="$2"
    local ip_profile="$3"
    local timeline="$4"
    local total_lines="$5"
    
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        ReportPrinter::print_json "$workspace" "$findings_json" "$ip_profile" "$timeline" "$total_lines"
        return
    fi
    
    if [[ "$CSV_OUTPUT" == "true" ]]; then
        ReportPrinter::print_csv "$workspace" "$findings_json" "$ip_profile"
        return
    fi
    
    ReportPrinter::print_text "$workspace" "$findings_json" "$ip_profile" "$timeline" "$total_lines"
}

ReportPrinter::print_text() {
    local workspace="$1"
    local findings_json="$2"
    local ip_profile="$3"
    local timeline="$4"
    local total_lines="$5"
    
    local critical_count high_count medium_count low_count
    critical_count=0
    high_count=0
    medium_count=0
    low_count=0
    
    for f in "$workspace"/critical_*.log; do
        [[ -f "$f" ]] && critical_count=$((critical_count + $(wc -l < "$f")))
    done
    for f in "$workspace"/high_*.log; do
        [[ -f "$f" ]] && high_count=$((high_count + $(wc -l < "$f")))
    done
    for f in "$workspace"/medium_*.log; do
        [[ -f "$f" ]] && medium_count=$((medium_count + $(wc -l < "$f")))
    done
    for f in "$workspace"/low_*.log; do
        [[ -f "$f" ]] && low_count=$((low_count + $(wc -l < "$f")))
    done
    
    local total_threats=$((critical_count + high_count + medium_count + low_count))
    local threat_score=$((critical_count * 100 + high_count * 50 + medium_count * 20 + low_count * 5))
    
    local risk_level="LOW"
    if [[ $threat_score -gt 1000 ]]; then
        risk_level="CRITICAL"
    elif [[ $threat_score -gt 500 ]]; then
        risk_level="HIGH"
    elif [[ $threat_score -gt 100 ]]; then
        risk_level="MEDIUM"
    fi
    
    local separator=$(printf '=%.0s' {1..60})
    
    echo ""
    echo "$separator"
    echo -e " $(Colors::get BOLD)BLUE TEAM LOG ANALYSIS REPORT$(Colors::reset)"
    echo "$separator"
    echo ""
    echo -e "  $(Colors::get BOLD)Total Requests:$(Colors::reset) $total_lines"
    echo -e "  $(Colors::get BOLD)Suspicious Requests:$(Colors::reset) $total_threats"
    echo -e "  $(Colors::get BOLD)Threat Score:$(Colors::reset) $threat_score"
    echo -e "  $(Colors::get BOLD)Risk Level:$(Colors::reset) $(ReportPrinter::severity_color "$risk_level")$risk_level$(Colors::reset)"
    echo ""
    
    echo "$separator"
    echo -e " $(Colors::get BOLD)FINDINGS BY SEVERITY$(Colors::reset)"
    echo "$separator"
    echo ""
    
    if [[ $critical_count -gt 0 ]]; then
        echo -e "  $(ReportPrinter::severity_color CRITICAL)[CRITICAL]$(Colors::reset) SQL Injection: $critical_count"
    fi
    if [[ $high_count -gt 0 ]]; then
        echo -e "  $(ReportPrinter::severity_color HIGH)[HIGH]$(Colors::reset) Remote Code Execution: $high_count"
    fi
    if [[ $medium_count -gt 0 ]]; then
        echo -e "  $(ReportPrinter::severity_color MEDIUM)[MEDIUM]$(Colors::reset) Path Traversal: $medium_count"
    fi
    if [[ $low_count -gt 0 ]]; then
        echo -e "  $(ReportPrinter::severity_color LOW)[LOW]$(Colors::reset) Scanner Activity: $low_count"
    fi
    
    if [[ $total_threats -eq 0 ]]; then
        echo -e "  $(Colors::get GREEN)[✓] No threats detected$(Colors::reset)"
    fi
    
    echo ""
    echo "$separator"
    echo -e " $(Colors::get BOLD)TOP ATTACKING IPs$(Colors::reset)"
    echo "$separator"
    echo ""
    
    if [[ -f "$workspace/top_ips.txt" ]]; then
        head -20 "$workspace/top_ips.txt" | while read -r count ip; do
            printf "    %-15s %s requests\n" "$ip" "$count"
        done
    else
        echo "    No attacker data available"
    fi
    
    echo ""
    echo "$separator"
    echo -e " $(Colors::get BOLD)TOP USER AGENTS$(Colors::reset)"
    echo "$separator"
    echo ""
    
    if [[ -f "$workspace/top_user_agents.txt" ]]; then
        head -10 "$workspace/top_user_agents.txt" | while read -r count ua; do
            printf "    %s requests: %.50s...\n" "$count" "$ua"
        done
    else
        echo "    No user agent data available"
    fi
    
    echo ""
    echo "$separator"
    echo -e " $(Colors::get BOLD)FIRST MALICIOUS REQUESTS$(Colors::reset)"
    echo "$separator"
    echo ""
    
    local first_malicious
    first_malicious=$(find "$workspace" -name "first_*.log" -type f 2>/dev/null | head -1)
    if [[ -n "$first_malicious" && -s "$first_malicious" ]]; then
        head -5 "$first_malicious" | while read -r line; do
            echo -e "    $(Colors::get YELLOW)$line$(Colors::reset)"
        done
    else
        echo "    No malicious requests found"
    fi
    
    echo ""
    echo "$separator"
    echo -e " $(Colors::get BOLD)SCAN COMPLETED$(Colors::reset)"
    echo "$separator"
    echo ""
}

ReportPrinter::severity_color() {
    local severity="$1"
    Colors::severity "$severity"
}

ReportPrinter::print_json() {
    local workspace="$1"
    local findings="$2"
    local ip_profile="$3"
    local timeline="$4"
    local total_lines="$5"
    
    local critical_count high_count medium_count low_count
    critical_count=0
    high_count=0
    medium_count=0
    low_count=0
    
    for f in "$workspace"/critical_*.log; do
        [[ -f "$f" ]] && critical_count=$((critical_count + $(wc -l < "$f")))
    done
    for f in "$workspace"/high_*.log; do
        [[ -f "$f" ]] && high_count=$((high_count + $(wc -l < "$f")))
    done
    for f in "$workspace"/medium_*.log; do
        [[ -f "$f" ]] && medium_count=$((medium_count + $(wc -l < "$f")))
    done
    for f in "$workspace"/low_*.log; do
        [[ -f "$f" ]] && low_count=$((low_count + $(wc -l < "$f")))
    done
    
    local total_threats=$((critical_count + high_count + medium_count + low_count))
    local threat_score=$((critical_count * 100 + high_count * 50 + medium_count * 20 + low_count * 5))
    
    cat << EOF
{
  "analysis": {
    "timestamp": "$(Utils::timestamp)",
    "total_requests": $total_lines,
    "suspicious_requests": $total_threats,
    "threat_score": $threat_score
  },
  "findings": {
    "critical": $critical_count,
    "high": $high_count,
    "medium": $medium_count,
    "low": $low_count
  },
  "top_attackers": [
$(ReportPrinter::json_top_ips "$workspace" 10)
  ],
  "top_user_agents": [
$(ReportPrinter::json_top_ua "$workspace" 10)
  ]
}
EOF
}

ReportPrinter::json_top_ips() {
    local workspace="$1"
    local limit="$2"
    local first=true
    
    if [[ -f "$workspace/top_ips.txt" ]]; then
        while read -r count ip; do
            [[ $((--limit)) -lt 0 ]] && break
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo ","
            fi
            printf '    {"ip": "%s", "count": %s}' "$ip" "$count"
        done < <(head -10 "$workspace/top_ips.txt")
    fi
    echo ""
}

ReportPrinter::json_top_ua() {
    local workspace="$1"
    local limit="$2"
    local first=true
    
    if [[ -f "$workspace/top_user_agents.txt" ]]; then
        while read -r count ua; do
            [[ $((--limit)) -lt 0 ]] && break
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo ","
            fi
            ua=$(Utils::json_escape "$ua")
            printf '    {"user_agent": "%s", "count": %s}' "$ua" "$count"
        done < <(head -10 "$workspace/top_user_agents.txt")
    fi
    echo ""
}

ReportPrinter::print_csv() {
    local workspace="$1"
    local findings="$2"
    local ip_profile="$3"
    
    echo "Type,Severity,IP,Count,Details"
    
    if [[ -f "$workspace/sqli_hits.log" ]]; then
        while read -r line; do
            echo "SQLi,CRITICAL,,1,$line"
        done < <(head -50 "$workspace/sqli_hits.log")
    fi
    
    if [[ -f "$workspace/rce_hits.log" ]]; then
        while read -r line; do
            echo "RCE,CRITICAL,,1,$line"
        done < <(head -50 "$workspace/rce_hits.log")
    fi
    
    if [[ -f "$workspace/backdoor_hits.log" ]]; then
        while read -r line; do
            echo "Backdoor,CRITICAL,,1,$line"
        done < <(head -50 "$workspace/backdoor_hits.log")
    fi
    
    if [[ -f "$workspace/bruteforce_hits.log" ]]; then
        while read -r line; do
            echo "BruteForce,HIGH,,1,$line"
        done < <(head -50 "$workspace/bruteforce_hits.log")
    fi
    
    if [[ -f "$workspace/xss_hits.log" ]]; then
        while read -r line; do
            echo "XSS,HIGH,,1,$line"
        done < <(head -50 "$workspace/xss_hits.log")
    fi
    
    if [[ -f "$workspace/path_hits.log" ]]; then
        while read -r line; do
            echo "PathTraversal,MEDIUM,,1,$line"
        done < <(head -50 "$workspace/path_hits.log")
    fi
}
