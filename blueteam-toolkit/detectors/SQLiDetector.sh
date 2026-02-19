#!/bin/bash

readonly SQLI_SEVERITY="CRITICAL"

SQLiDetector::patterns() {
    cat << 'PATTERNS'
union\s+select
union\s+all\s+select
union\s+select\s+all
select\s+from
insert\s+into
delete\s+from
update\s+set
drop\s+table
drop\s+database
create\s+table
alter\s+table
exec\s*\(
exec\s+
xp_cmdshell
sp_executesql
information_schema
concat\s*\(
concat_ws\s*\(
char\s*\(
benchmark\s*
sleep\s*\(
waitfor\s+delay
between\s+\d+\s+and
1\s*=\s*1
1\s*=\s*1\s*--
1\s*=\s*1\s*/
'\s*or\s*'1'\s*=\s*'1
'\s*or\s*1\s*=\s*1
'\s*or\s*'1'\s*=\s*'1\s*--
or\s+1\s*=\s*1
'\s*or\s+1=1
and\s+1=1
and\s+1=1\s*--
and\s+1=1\s*/
'\s*and\s+'1'\s*=\s*'1
'\s*and\s+1=1\s*--
'\s*and\s+1=1\s*/
1\s*>\s*0
1\s*<\s*2
'\s*>\s*'0
having\s+\d+\s*=\s*\d+
having\s+'.*'\s*=\s*'.*
group\s+by\s+.*
order\s+by\s+\d+
order\s+by\s+\w+
into\s+outfile
into\s+dumpfile
load_file\s*\(
load\s+data\s+infile
prepare\s+
declar(e|ing)\s+cursor
PATTERNS
}

SQLiDetector::run() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/sqli_hits.log"
    local first_file="$workspace/first_sqli.log"
    
    local pattern_file="$workspace/sqli_patterns.tmp"
    SQLiDetector::patterns > "$pattern_file"
    
    awk -v pattern_file="$pattern_file" '
    BEGIN {
        while ((getline line < pattern_file) > 0) {
            patterns[++count] = tolower(line)
        }
        close(pattern_file)
    }
    {
        line = tolower($0)
        for (i = 1; i <= count; i++) {
            if (index(line, patterns[i])) {
                print $0
                found = 1
                exit
            }
        }
    }
    ' "$log_file" > "$first_file" 2>/dev/null || true
    
    awk -v pattern_file="$pattern_file" '
    BEGIN {
        while ((getline line < pattern_file) > 0) {
            patterns[++count] = tolower(line)
        }
        close(pattern_file)
    }
    {
        line = tolower($0)
        for (i = 1; i <= count; i++) {
            if (index(line, patterns[i])) {
                print $0
                next
            }
        }
    }
    ' "$log_file" > "$output_file" 2>/dev/null || true
    
    local count
    count=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    
    rm -f "$pattern_file"
    
    if [[ $count -gt 0 ]]; then
        echo '{"detector":"SQLiDetector","severity":"CRITICAL","count":'$count'}'
    fi
}

SQLiDetector::report() {
    local workspace="$1"
    local output_file="$workspace/sqli_hits.log"
    
    if [[ -f "$output_file" ]]; then
        local count
        count=$(wc -l < "$output_file")
        echo "SQL Injection Attempts: $count"
        head -5 "$output_file"
    fi
}

SQLiDetector::get_severity() {
    echo "$SQLI_SEVERITY"
}
