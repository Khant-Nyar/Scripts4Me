#!/bin/bash

Utils::timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

Utils::date_to_epoch() {
    local date_str="$1"
    date -d "$date_str" +%s 2>/dev/null || echo "0"
}

Utils::epoch_to_date() {
    local epoch="$1"
    date -d "@$epoch" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$epoch"
}

Utils::file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

Utils::is_ip() {
    local ip="$1"
    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

Utils::extract_ip() {
    local line="$1"
    echo "$line" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

Utils::extract_user_agent() {
    local line="$1"
    echo "$line" | sed -n 's/.*"\(.*\)"$/\1/p' | tail -1
}

Utils::url_decode() {
    local str="$1"
    printf '%b' "${str//%/\\x}"
}

Utils::base64_decode() {
    local str="$1"
    echo "$str" | base64 -d 2>/dev/null || echo "$str"
}

Utils::count_lines() {
    local file="$1"
    wc -l < "$file" 2>/dev/null || echo "0"
}

Utils::unique_count() {
    local file="$1"
    sort -u "$file" | wc -l
}

Utils::sort_by_count() {
    local file="$1"
    sort "$file" | uniq -c | sort -rn
}

Utils::json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

Utils::csv_escape() {
    local str="$1"
    if [[ "$str" == *","* ]] || [[ "$str" == *"\""* ]] || [[ "$str" == *$'\n'* ]]; then
        str="\"${str//\"/\"\"}\""
    fi
    echo "$str"
}

Utils::get_timestamp_epoch() {
    date '+%s'
}

Utils::format_bytes() {
    local bytes="$1"
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

Utils::trim() {
    local str="$1"
    echo "$str" | xargs
}

Utils::to_lowercase() {
    local str="$1"
    echo "$str" | tr '[:upper:]' '[:lower:]'
}

Utils::to_uppercase() {
    local str="$1"
    echo "$str" | tr '[:lower:]' '[:upper:]'
}

Utils::regex_match() {
    local str="$1"
    local pattern="$2"
    [[ "$str" =~ $pattern ]]
}

Utils::array_contains() {
    local element="$1"
    shift
    local arr=("$@")
    for item in "${arr[@]}"; do
        [[ "$item" == "$element" ]] && return 0
    done
    return 1
}
