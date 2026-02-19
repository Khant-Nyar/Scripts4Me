#!/bin/bash

readonly BACKDOOR_SEVERITY="CRITICAL"

BackdoorDetector::patterns() {
    cat << 'PATTERNS'
c99\.php
c99
r57\.php
r57
c100\.php
c100
c57
b374k
b374k\.php
mini\.php
shell\.php
backdoor
webshell
ghost\.php
up\.php
x\.php
h4k
h4k\.php
anj
anj\.php
pwn
pwn\.php
cmd\.php
cmd
webshell
shellcode
bot\.php
bottles
r00t
r00t\.php
sniper
sniper\.php
xploit
xploit\.php
root\.php
rootkit
wso
wso\.php
dron
dron\.php
fake
fake\.php
passthru
system
exec
shell_exec
base64_decode
eval\s*\(
assert\s*\(
preg_replace.*\/e
create_function
call_user_func
gzinflate
gzdeflate
str_rot13
rawurldecode
urldecode
chr\s*\(
file_get_contents
file_put_contents
fopen\s*\(
fclose\s*\(
readfile\s*\(
_symlink
symlink
mail\s*\(
email
_POST
_GET
_REQUEST
GLOBALS
_\[GLOBALS\]
_\[POST\]
_\[GET\]
_\[REQUEST\]
_FILES
_SERVER
_SESSION
COOKIE
HTTP_COOKIE
HTTP_USER_AGENT
HTTP_REFERER
HTTP_X_FORWARDED
HTTP_CLIENT_IP
getcwd\s*\(
getenv\s*\(
ini_get
ini_set
set_time_limit
error_reporting
ignore_user_abort
apache_child_terminate
phpinfo
PATTERNS
}

BackdoorDetector::run() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/backdoor_hits.log"
    local first_file="$workspace/first_backdoor.log"
    
    local pattern_file="$workspace/backdoor_patterns.tmp"
    BackdoorDetector::patterns > "$pattern_file"
    
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
        echo '{"detector":"BackdoorDetector","severity":"CRITICAL","count":'$count'}'
    fi
}

BackdoorDetector::get_severity() {
    echo "$BACKDOOR_SEVERITY"
}
