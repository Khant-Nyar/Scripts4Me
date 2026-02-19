#!/bin/bash

CONFIG_FILE=""

Config::load() {
    local config_file="${1:-config/default.conf}"
    
    if [[ -f "$config_file" ]]; then
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            eval "CONFIG_$key='$value'"
        done < "$config_file"
    else
        Config::defaults
    fi
}

Config::defaults() {
    CONFIG_THRESHOLD_BRUTE_FORCE=10
    CONFIG_THRESHOLD_SCANNER=50
    CONFIG_THRESHOLD_ENUMERATION=30
    CONFIG_THRESHOLD_SQLI=1
    CONFIG_THRESHOLD_RCE=1
    CONFIG_THRESHOLD_XSS=1
    CONFIG_THRESHOLD_PATH_TRAVERSAL=1
    CONFIG_MIN_SEVERITY=LOW
    CONFIG_ENABLE_SQLI=true
    CONFIG_ENABLE_RCE=true
    CONFIG_ENABLE_BACKDOOR=true
    CONFIG_ENABLE_BRUTEFORCE=true
    CONFIG_ENABLE_XSS=true
    CONFIG_ENABLE_PATH_TRAVERSAL=true
    CONFIG_ENABLE_LOG4SHELL=true
    CONFIG_ENABLE_SCANNER=true
    CONFIG_ENABLE_FILE_DISCLOSURE=true
    CONFIG_ENABLE_ENUMERATION=true
    CONFIG_WEBSHELL_PATTERNS="c99,r57,shell,webshell,b374k,anj"
    CONFIG_SUSPICIOUS_USER_AGENTS="sqlmap,nikto,nmap,masscan,gobuster,dirbuster,hydra,medusa"
    CONFIG_LOG_FORMAT=combined
    CONFIG_IP_REGEX="^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"
    CONFIG_OUTPUT_JSON=false
    CONFIG_OUTPUT_CSV=false
    CONFIG_VERBOSE=false
    CONFIG_QUIET=false
    CONFIG_TOP_COUNT=20
}

Config::get() {
    local key="$1"
    local default="${2:-}"
    eval "echo \${CONFIG_$key:-$default}"
}

Config::set() {
    local key="$1"
    local value="$2"
    eval "CONFIG_$key='$value'"
}

Config::is_enabled() {
    local key="$1"
    eval "[[ \"\${CONFIG_$key:-false}\" == \"true\" ]]"
}

Config::threshold() {
    local key="$1"
    eval "echo \${CONFIG_THRESHOLD_$key:-1}"
}

Config::save() {
    local config_file="$1"
    echo "Saving config not implemented in bash 3.2 mode"
}

Config::list() {
    echo "Config list not available in bash 3.2 mode"
}
