#!/bin/bash

readonly XSS_SEVERITY="HIGH"

XSSDetector::patterns() {
    cat << 'PATTERNS'
%3Cscript
%3Cscript%
3Cscript
<script
%3C%73%63%72%69%70%74
%3Cimg
%3Ciframe
%3Csvg
onerror\s*=
onload\s*=
onclick\s*=
ondblclick\s*=
onmouseover\s*=
onfocus\s*=
onblur\s*=
onanimationend
ontransitionend
javascript\s*:
vbscript\s*:
data\s*:
<body\s
<embed\s
<object\s
<applet\s
<form\s
expression\s*\(
eval\s*\(
alert\s*\(
prompt\s*\(
confirm\s*\(
document\.cookie
document\.location
document\.domain
window\.location
top\.location
parent\.location
iframe\s+
frameset\s+
foreignObject
<![CDATA[
]]>
%22%3E
%3C%2F
%3C/%3E
%27%3E
\%22
\%27
";.*"
';.*'
";.*//
';.*//
\\x3c
\\x3e
\\u003c
\\u003e
%u003c
%u003e
PATTERNS
}

XSSDetector::run() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/xss_hits.log"
    local first_file="$workspace/first_xss.log"
    
    local pattern_file="$workspace/xss_patterns.tmp"
    XSSDetector::patterns > "$pattern_file"
    
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
        echo '{"detector":"XSSDetector","severity":"HIGH","count":'$count'}'
    fi
}

XSSDetector::get_severity() {
    echo "$XSS_SEVERITY"
}
