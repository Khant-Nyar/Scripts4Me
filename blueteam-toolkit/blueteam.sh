#!/bin/bash

readonly BLUE_TEAM_VERSION="1.0.0"
readonly BLUE_TEAM_NAME="Security Toolkit"

set -euo pipefail

QUIET_MODE=false
VERBOSE_MODE=false
JSON_OUTPUT=false
CSV_OUTPUT=false
TOP_COUNT=20
LOG_FILE=""
WORKSPACE=""
CONFIG_FILE=""

export QUIET_MODE VERBOSE_MODE JSON_OUTPUT CSV_OUTPUT TOP_COUNT LOG_FILE WORKSPACE CONFIG_FILE

source "$(dirname "${BASH_SOURCE[0]}")/core/Colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/core/Logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/core/Utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/core/Config.sh"

source "$(dirname "${BASH_SOURCE[0]}")/ui/Banner.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ui/ReportPrinter.sh"

source "$(dirname "${BASH_SOURCE[0]}")/detectors/SQLiDetector.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detectors/RCEDetector.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detectors/BackdoorDetector.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detectors/BruteForceDetector.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detectors/XSSDetector.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detectors/PathTraversalDetector.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detectors/Log4ShellDetector.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detectors/ScannerDetector.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detectors/FileDisclosureDetector.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detectors/EnumerationDetector.sh"

source "$(dirname "${BASH_SOURCE[0]}")/analyzers/IPProfiler.sh"
source "$(dirname "${BASH_SOURCE[0]}")/analyzers/TimelineAnalyzer.sh"

namespace::initialize() {
    core::load_config "$CONFIG_FILE"
    core::setup_workspace
}

core::load_config() {
    local config_file="${1:-config/default.conf}"
    Config::load "$config_file"
}

core::setup_workspace() {
    WORKSPACE=$(mktemp -d)
    Logger::debug "Workspace: $WORKSPACE"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --csv)
                CSV_OUTPUT=true
                shift
                ;;
            --quiet|-q)
                QUIET_MODE=true
                shift
                ;;
            --verbose|-v)
                VERBOSE_MODE=true
                shift
                ;;
            --top)
                TOP_COUNT="${2:-20}"
                shift 2
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            -*)
                Logger::error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$LOG_FILE" ]]; then
                    LOG_FILE="$1"
                else
                    Logger::error "Multiple log files not supported"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$LOG_FILE" ]]; then
        Logger::error "No log file specified"
        show_help
        exit 1
    fi

    if [[ ! -f "$LOG_FILE" ]]; then
        Logger::error "Log file not found: $LOG_FILE"
        exit 1
    fi

    if [[ ! -r "$LOG_FILE" ]]; then
        Logger::error "Log file not readable: $LOG_FILE"
        exit 1
    fi
}

show_help() {
    cat << EOF
$BLUE_TEAM_NAME v$BLUE_TEAM_VERSION

USAGE:
    $(basename "$0") [OPTIONS] <log_file>

OPTIONS:
    --json           Output results in JSON format
    --csv            Output results in CSV format
    --quiet, -q      Suppress banner and non-essential output
    --verbose, -v    Enable verbose output
    --top N          Show top N attackers (default: 20)
    --config FILE    Use custom configuration file
    --help, -h       Show this help message
    --version        Show version information

EXAMPLES:
    $(basename "$0") /var/log/nginx/access.log
    $(basename "$0") --json --top 50 /var/log/apache2/access.log
    $(basename "$0") --csv -v /var/log/nginx/access.log

EOF
}

show_version() {
    echo "$BLUE_TEAM_NAME v$BLUE_TEAM_VERSION"
}

run_analysis() {
    local log_file="$1"
    local results_file="$WORKSPACE/results.json"

    Logger::info "Starting analysis of: $log_file"

    local total_lines
    total_lines=$(wc -l < "$log_file")
    Logger::info "Total lines in log: $total_lines"

    echo '{"findings": [], "attacks": [], "stats": {}}' > "$results_file"

    local findings=()

    Logger::info "Running SQLi detection..."
    local sqli_results
    sqli_results=$(SQLiDetector::run "$log_file" "$WORKSPACE")
    if [[ -n "$sqli_results" ]]; then
        findings+=("$sqli_results")
    fi

    Logger::info "Running RCE detection..."
    local rce_results
    rce_results=$(RCEDetector::run "$log_file" "$WORKSPACE")
    if [[ -n "$rce_results" ]]; then
        findings+=("$rce_results")
    fi

    Logger::info "Running Backdoor detection..."
    local backdoor_results
    backdoor_results=$(BackdoorDetector::run "$log_file" "$WORKSPACE")
    if [[ -n "$backdoor_results" ]]; then
        findings+=("$backdoor_results")
    fi

    Logger::info "Running Brute Force detection..."
    local brute_results
    brute_results=$(BruteForceDetector::run "$log_file" "$WORKSPACE")
    if [[ -n "$brute_results" ]]; then
        findings+=("$brute_results")
    fi

    Logger::info "Running XSS detection..."
    local xss_results
    xss_results=$(XSSDetector::run "$log_file" "$WORKSPACE")
    if [[ -n "$xss_results" ]]; then
        findings+=("$xss_results")
    fi

    Logger::info "Running Path Traversal detection..."
    local path_results
    path_results=$(PathTraversalDetector::run "$log_file" "$WORKSPACE")
    if [[ -n "$path_results" ]]; then
        findings+=("$path_results")
    fi

    Logger::info "Running Log4Shell detection..."
    local log4j_results
    log4j_results=$(Log4ShellDetector::run "$log_file" "$WORKSPACE")
    if [[ -n "$log4j_results" ]]; then
        findings+=("$log4j_results")
    fi

    Logger::info "Running Scanner detection..."
    local scanner_results
    scanner_results=$(ScannerDetector::run "$log_file" "$WORKSPACE")
    if [[ -n "$scanner_results" ]]; then
        findings+=("$scanner_results")
    fi

    Logger::info "Running File Disclosure detection..."
    local file_results
    file_results=$(FileDisclosureDetector::run "$log_file" "$WORKSPACE")
    if [[ -n "$file_results" ]]; then
        findings+=("$file_results")
    fi

    Logger::info "Running Enumeration detection..."
    local enum_results
    enum_results=$(EnumerationDetector::run "$log_file" "$WORKSPACE")
    if [[ -n "$enum_results" ]]; then
        findings+=("$enum_results")
    fi

    categorize_findings_by_severity

    Logger::info "Running IP Profiling..."
    local ip_profile
    ip_profile=$(IPProfiler::analyze "$log_file" "$WORKSPACE")

    Logger::info "Running Timeline Analysis..."
    local timeline
    timeline=$(TimelineAnalyzer::analyze "$log_file" "$WORKSPACE")

    ReportPrinter::print_results "$WORKSPACE" "$findings" "$ip_profile" "$timeline" "$total_lines"
}

cleanup() {
    if [[ -n "$WORKSPACE" && -d "$WORKSPACE" ]]; then
        rm -rf "$WORKSPACE"
        Logger::debug "Cleaned up workspace"
    fi
}

categorize_findings_by_severity() {
    local critical_files="sqli_hits.log rce_hits.log backdoor_hits.log log4j_hits.log"
    local high_files="bruteforce_hits.log xss_hits.log file_hits.log"
    local medium_files="path_hits.log enum_hits.log"
    local low_files="scanner_hits.log"
    
    for f in $critical_files; do
        if [[ -f "$WORKSPACE/$f" && -s "$WORKSPACE/$f" ]]; then
            cp "$WORKSPACE/$f" "$WORKSPACE/critical_$f" 2>/dev/null || true
        fi
    done
    
    for f in $high_files; do
        if [[ -f "$WORKSPACE/$f" && -s "$WORKSPACE/$f" ]]; then
            cp "$WORKSPACE/$f" "$WORKSPACE/high_$f" 2>/dev/null || true
        fi
    done
    
    for f in $medium_files; do
        if [[ -f "$WORKSPACE/$f" && -s "$WORKSPACE/$f" ]]; then
            cp "$WORKSPACE/$f" "$WORKSPACE/medium_$f" 2>/dev/null || true
        fi
    done
    
    for f in $low_files; do
        if [[ -f "$WORKSPACE/$f" && -s "$WORKSPACE/$f" ]]; then
            cp "$WORKSPACE/$f" "$WORKSPACE/low_$f" 2>/dev/null || true
        fi
    done
}

main() {
    trap cleanup EXIT

    parse_arguments "$@"

    if [[ "$QUIET_MODE" == "false" ]]; then
        Banner::show
    fi

    namespace::initialize

    run_analysis "$LOG_FILE"
}

main "$@"
