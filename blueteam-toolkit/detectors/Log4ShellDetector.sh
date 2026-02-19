#!/bin/bash

readonly LOG4SHELL_SEVERITY="CRITICAL"

Log4ShellDetector::patterns() {
    cat << 'PATTERNS'
\$\{jndi:
\$\{jndi:ldap
\$\{jndi:rmi
\$\{jndi:dns
\$\{jndi:iiop
\$\{jndi:http
\$\{jndi:nis
\$\{jndi:nds
\$\{jndi:corba
jndi:ldap
jndi:rmi
jndi:dns
jndi:iiop
jndi:http
\$\{env:BMI1
\$\{env:JAVA_HOME
\$\{lower:
\$\{upper:
\$\{sys:
\$\{date:
\$\{::-j
\$\{::-n
\$\{::-d
\$\{::-i
\${jndi:
${jndi:
%24%7Bjndi
%24%7Bjndi
%24%7b%7bjndi
$%7Bjndi
$%7Bjndi
\${${::-j}${::-n}${::-d}${::-i}
\${${::-j}ndi:
\${jndi:${lower:l}
\${jndi:${lower:d}
\${jndi:${lower:r}
\${jndi:${lower:n}
\${${lower:j}ndi:
\${${lower:n}di:
PATTERNS
}

Log4ShellDetector::run() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/log4j_hits.log"
    local first_file="$workspace/first_log4j.log"
    
    local pattern_file="$workspace/log4j_patterns.tmp"
    Log4ShellDetector::patterns > "$pattern_file"
    
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
        echo '{"detector":"Log4ShellDetector","severity":"CRITICAL","count":'$count'}'
    fi
}

Log4ShellDetector::get_severity() {
    echo "$LOG4SHELL_SEVERITY"
}
