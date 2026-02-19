#!/bin/bash

Banner::show() {
    local color=$(Colors::get CYAN)
    local bold=$(Colors::get BOLD)
    local reset=$(Colors::reset)
    
    local width=${COLUMNS:-80}
    local line=$(printf '%*s' "$width" '' | tr ' ' '=')
    
    cat << EOF

${bold}${color}${line}${reset}

${bold}${color}        .--.       .--.${reset}
${bold}${color}    _  \`    \\     /    \`  _${reset}
${bold}${color}     \`\\.===. \\.^./ .===./\`${reset}
${bold}${color}            \\/\`"\`\\\\\/${reset}
${bold}${color}         ,  | y2k |  ,${reset}
${bold}${color}        / \`|;-.-'|\` \\${reset}
${bold}${color}       /    |::\\\\  |    \\${reset}
${bold}${color}    .-' ,-'|\`:::-; |\`'-, '-.${reset}
${bold}${color}        |   |::::\\\\|   |${reset}
${bold}${color}        |   |::::;|   |${reset}
${bold}${color}        |   \:::://   |${reset}
${bold}${color}        |    \`.://'   |${reset}
${bold}${color}    jgs    .'             \`.${reset}
${bold}${color}    _,'                 \`,_${reset}

${bold}${color}                    DETECTOR v1.0.0${reset}
${bold}${color}               Advanced Log Analysis Tool${reset}
${bold}${color}                 Developed by Khant-Nyar${reset}

${bold}${color}${line}${reset}
EOF
}

Banner::compact() {
    local color=$(Colors::get CYAN)
    local reset=$(Colors::reset)
    echo -e "${color}[Detector]${reset} Advanced Log Analysis Tool"
}
