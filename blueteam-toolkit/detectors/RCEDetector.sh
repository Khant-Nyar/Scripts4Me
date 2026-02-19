#!/bin/bash

readonly RCE_SEVERITY="CRITICAL"

RCEDetector::patterns() {
    cat << 'PATTERNS'
\$\{.*\}
\$\{jndi:
\$\{env\.
\$\{sys\.
\$\{lower\.
\$\{upper\.
\$\{date\.
\$\{java:version
\$\{java:vendor
\$\{os\.
\$\{host\.
cmd\.exe
/bin/bash
/bin/sh
wget\s+http
curl\s+http
lynx\s+http
fetch\s+http
python.*-c
python.*-i
perl.*-e
ruby.*-e
php.*-r
php.*-e
base64\s+-d
bash\s+-i
sh\s+-i
nc\s+-e
/bin/nc
\.exec\s*\(
\.eval\s*\(
system\s*\(
exec\s*\(
passthru\s*\(
shell_exec\s*\(
proc_open\s*\(
popen\s*\(
assert\s*\(
preg_replace.*e
create_function\s*\(
call_user_func\s*
call_user_func_array
 serialize\s*\(
 unserialize\s*\(
\.\.\/\.\.\/
\.\.\%2f
etc\/passwd
etc\/shadow
\/bin\/sh
\/bin\/bash
whoami
id\s*\(
uname\s+-a
ls\s+-la
ls\s+-l
cat\s+\/
pwd\s*
ls\s+/
cd\s+\/
cd\s+..
etc\/hosts
wget\s+
curl\s+
__import__\s*\(
os\.system
os\.popen
subprocess\.
eval\s*\(
exec\s*\(
open\s*\(\s*[\"'\/]
file\s*\(\s*[\"'\/]
read\s*\(
write\s*\(
<script>.*eval
<script>.*document\.cookie
java\.lang\.Runtime
java\.lang\.ProcessBuilder
ProcessBuilder
Runtime\.getRuntime
Class\.forName
javax\.naming
InitialContext
lookup\s*\(
PATTERNS
}

RCEDetector::run() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/rce_hits.log"
    local first_file="$workspace/first_rce.log"
    
    local pattern_file="$workspace/rce_patterns.tmp"
    RCEDetector::patterns > "$pattern_file"
    
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
        echo '{"detector":"RCEDetector","severity":"CRITICAL","count":'$count'}'
    fi
}

RCEDetector::get_severity() {
    echo "$RCE_SEVERITY"
}
