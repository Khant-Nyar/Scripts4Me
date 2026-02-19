#!/bin/bash

readonly FILE_DISCLOSURE_SEVERITY="HIGH"

FileDisclosureDetector::patterns() {
    cat << 'PATTERNS'
\.env$
\.env\.
\.git\/config
\.git\/HEAD
\.git\/index
\.svn\/entries
\.hg\/requires
\.htaccess
\.htpasswd
\.bash_history
\.bashrc
\.profile
\.mysql_history
\.psql_history
\.rediscli_history
\.npmrc
\.yarnrc
\.DS_Store
Thumbs\.db
desktop\.ini
\.aws\/credentials
\.aws\/config
\.ssh\/authorized_keys
\.ssh\/id_rsa
\.ssh\/id_dsa
\.ssh\/known_hosts
config\.php\~
database\.php\~
wp-config\.php\~
configuration\.php\~
settings\.php\~
config\.ini
config\.xml
config\.json
settings\.json
\.key$
\.pem$
\.cert$
\.crt$
\.p12$
\.pfx$
\.jks$
keystore\.jks
truststore\.jks
passwd
shadow
group
hosts\.conf
resolv\.conf
nsswitch\.conf
syslog\.conf
httpd\.conf
nginx\.conf
php\.ini
my\.ini
my\.cnf
\.sql$
\.dump$
\.bak$
\.backup$
\.old$
\.orig$
\.save$
\.swp$
\.swo$
\*\.log$
application\.properties
application\.yml
application\.yaml
log4j\.properties
log4j\.xml
PATTERNS
}

FileDisclosureDetector::run() {
    local log_file="$1"
    local workspace="$2"
    local output_file="$workspace/file_hits.log"
    local first_file="$workspace/first_file.log"
    
    local pattern_file="$workspace/file_patterns.tmp"
    FileDisclosureDetector::patterns > "$pattern_file"
    
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
        echo '{"detector":"FileDisclosureDetector","severity":"HIGH","count":'$count'}'
    fi
}

FileDisclosureDetector::get_severity() {
    echo "$FILE_DISCLOSURE_SEVERITY"
}
