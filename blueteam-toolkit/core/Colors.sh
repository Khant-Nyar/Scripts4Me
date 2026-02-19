#!/bin/bash

Colors::get() {
    local color="$1"
    local use_color="${USE_COLOR:-true}"
    
    if [[ "$use_color" == "false" ]] || [[ ! -t 1 ]]; then
        echo ""
        return
    fi
    
    case "$color" in
        RESET) echo -e "\033[0m" ;;
        BOLD) echo -e "\033[1m" ;;
        DIM) echo -e "\033[2m" ;;
        UNDERLINE) echo -e "\033[4m" ;;
        BLACK) echo -e "\033[30m" ;;
        RED) echo -e "\033[31m" ;;
        GREEN) echo -e "\033[32m" ;;
        YELLOW) echo -e "\033[33m" ;;
        BLUE) echo -e "\033[34m" ;;
        MAGENTA) echo -e "\033[35m" ;;
        CYAN) echo -e "\033[36m" ;;
        WHITE) echo -e "\033[37m" ;;
        CRITICAL) echo -e "\033[1;31m" ;;
        HIGH) echo -e "\033[1;33m" ;;
        MEDIUM) echo -e "\033[1;34m" ;;
        LOW) echo -e "\033[1;32m" ;;
        INFO) echo -e "\033[0;36m" ;;
        *) echo "" ;;
    esac
}

Colors::reset() {
    echo -e "\033[0m"
}

Colors::severity() {
    local severity="$1"
    Colors::get "$severity"
}

Colors::enabled() {
    [[ -t 1 ]]
}
