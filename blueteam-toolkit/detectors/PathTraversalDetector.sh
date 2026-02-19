#!/bin/bash

readonly PATH_TRAVERSAL_SEVERITY="MEDIUM"

PathTraversalDetector::patterns() {
    cat << 'PATTERNS'
\.\./
\.\.\\.
\.\.%2f
\.\.%5c
\.\.%252f
\.\.\/
\.\.\
%2e%2e
%2e%2e%2f
%2e%2e%5c
%2e%2e\
%252e%252e
%252e%252e%252f
%c0%ae%c0%ae
%c0%ae%c0%af
%c0%ae%5c
%c0%ae/
\.\.%c0%af
\.\.%c1%9c
\..\..\
\..\../
etc/passwd
etc/shadow
etc/group
/etc/passwd
/etc/shadow
/etc/group
win.ini
boot.ini
windows/system32
windows/system
system32/cmd
system32/exec
/../../etc/passwd
/../..//etc/passwd
..;/..;/..;/etc/passwd
....//....//....//etc/passwd
..\/..\/..\/etc/passwd
..//..//..//etc/passwd
%2e%2e%2fetc%2fpasswd
%2e%2e%5cetc%5cpasswd
c:\\windows
d:\\windows
/././etc/passwd
/././././etc/passwd
proc/self/environ
proc/version
proc/cmdline
proc/self/cwd
/etc/hosts
/etc/hostname
/etc/resolv.conf
/proc/net/tcp
/proc/net/udp
PATTERNS
}

PathTraversalDetector::run() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/path_hits.log"
    local first_file="$workspace/first_path.log"
    
    local pattern_file="$workspace/path_patterns.tmp"
    PathTraversalDetector::patterns > "$pattern_file"
    
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
        echo '{"detector":"PathTraversalDetector","severity":"MEDIUM","count":'$count'}'
    fi
}

PathTraversalDetector::get_severity() {
    echo "$PATH_TRAVERSAL_SEVERITY"
}
