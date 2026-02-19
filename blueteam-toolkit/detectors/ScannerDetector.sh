#!/bin/bash

readonly SCANNER_SEVERITY="LOW"
readonly SCANNER_THRESHOLD=50

ScannerDetector::patterns() {
    cat << 'PATTERNS'
sqlmap
nikto
nmap
masscan
gobuster
dirbuster
dirb
hydra
medusa
wpscan
joomscan
wappalyzer
wpscan
whatweb
acunetix
netsparker
appscan
burp
zap
metasploit
nessus
openvas
nexpose
qualys
recon-ng
theHarvester
sublist3r
amass
subfinder
assetfinder
findomain
waybackurls

gaugospider
hakrawler
unog
commix
xsstrike
dalfox
xssed
w3af
vega
paros
proxystrike
grendel-scan
grabber
n-Stealth
stealth
pangolin
havij
b SQL
bsqlbf
mdb-sql
sqldumper
mysql
postgres
sqlexp
n0
scanner
penetration
exploit
vulnerability\s+scan
PATTERNS
}

ScannerDetector::run() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/scanner_hits.log"
    local first_file="$workspace/first_scanner.log"
    local ua_counts="$workspace/scanner_ua.txt"
    
    local pattern_file="$workspace/scanner_patterns.tmp"
    ScannerDetector::patterns > "$pattern_file"
    
    awk -F'"' -v pattern_file="$pattern_file" '
    BEGIN {
        while ((getline line < pattern_file) > 0) {
            patterns[++count] = tolower(line)
        }
        close(pattern_file)
    }
    {
        ua = $6
        ua = tolower(ua)
        for (i = 1; i <= count; i++) {
            if (index(ua, patterns[i])) {
                print ua
                next
            }
        }
    }
    ' "$log_file" | sort | uniq -c | sort -rn > "$ua_counts"
    
    awk -v threshold="$SCANNER_THRESHOLD" '
    $1 >= threshold {
        ua = $2
        for (i = 3; i <= NF; i++) {
            ua = ua " " $i
        }
        print $1, ua
    }
    ' "$ua_counts" > "$workspace/scanner_ua_filtered.txt"
    
    if [[ -s "$workspace/scanner_ua_filtered.txt" ]]; then
        local first_ua
        first_ua=$(head -1 "$workspace/scanner_ua_filtered.txt" | cut -d' ' -f2-)
        
        awk -F'"' -v ua="$first_ua" '
        tolower($6) ~ ua {
            print $0
            exit
        }
        ' "$log_file" > "$first_file"
        
        while read -r line; do
            local ua
            ua=$(echo "$line" | cut -d' ' -f2-)
            awk -F'"' -v ua="$ua" '
            tolower($6) ~ ua {
                print $0
            }
            ' "$log_file"
        done < "$workspace/scanner_ua_filtered.txt" > "$output_file"
    else
        touch "$output_file"
        touch "$first_file"
    fi
    
    local count
    count=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    
    rm -f "$pattern_file"
    
    if [[ $count -gt 0 ]]; then
        echo '{"detector":"ScannerDetector","severity":"LOW","count":'$count'}'
    fi
}

ScannerDetector::get_severity() {
    echo "$SCANNER_SEVERITY"
}
