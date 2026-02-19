#!/bin/bash

Banner::show() {
    local width=80
    local tput_result
    tput_result=$(tput cols 2>/dev/null)
    if [[ -n "$tput_result" && "$tput_result" -gt 0 ]] 2>/dev/null; then
        width=$tput_result
    fi
    
    local cyan="\033[36m"
    local yellow="\033[33m"
    local red="\033[31m"
    local bold="\033[1m"
    local reset="\033[0m"
    
    local line=$(printf '%*s' "$width" '' | tr ' ' '═')
    
    echo ""
    echo -e "${cyan}${line}${reset}"
    
    center() {
        local text="$1"
        printf "%*s\n" $(((${#text} + width) / 2)) "$text"
    }
        
    echo
    
    center "${yellow}        .-\"\"\"\"-.${reset}"
    center "${yellow}      .'        '.${reset}"
    center "${yellow}     /     ${red}( BUG? )${yellow}     \\${reset}"
    center "${yellow}    |      .-\"\"\"-.        |${reset}"
    center "${yellow}     \\      \\     /       /${reset}"
    center "${yellow}      '.      '.___.'      .'${reset}"
    center "${yellow}        '-.             .-'${reset}"
    center "${yellow}          '-.         .-'${reset}"
    center "${yellow}            '-.     .-'${reset}"
    center "${yellow}              '\/'${reset}"
    
    echo
    center "${bold}${cyan}🔎  SEARCHING FOR EXPLOITS...${reset}"
    echo
    center "${cyan}DETECTOR v1.0.0  |  Advanced Blue Team Log Analysis Engine${reset}"
    center "${cyan}Developed by Khant-Nyar${reset}"
    
    echo
    echo -e "${cyan}${line}${reset}"
}

Banner::compact() {
    local cyan="\033[36m"
    local reset="\033[0m"
    echo -e "${cyan}[Detector]${reset} Advanced Log Analysis Tool"
}
