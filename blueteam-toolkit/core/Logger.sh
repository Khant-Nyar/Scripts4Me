#!/bin/bash

readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARNING=2
readonly LOG_LEVEL_ERROR=3

LOG_LEVEL="${LOG_LEVEL:-$LOG_LEVEL_INFO}"
LOG_FILE=""
VERBOSE="${VERBOSE_MODE:-false}"

export LOG_LEVEL LOG_FILE VERBOSE

Logger::debug() {
    [[ "$LOG_LEVEL" -le $LOG_LEVEL_DEBUG ]] || [[ "$VERBOSE" == "true" ]] || return 0
    local message="$1"
    echo -e "$(Colors::get CYAN)[DEBUG]$(Colors::reset) $message" >&2
    Logger::to_file "DEBUG" "$message"
}

Logger::info() {
    [[ "$LOG_LEVEL" -le $LOG_LEVEL_INFO ]] || return 0
    local message="$1"
    echo -e "$(Colors::get GREEN)[INFO]$(Colors::reset) $message" >&2
    Logger::to_file "INFO" "$message"
}

Logger::warn() {
    [[ "$LOG_LEVEL" -le $LOG_LEVEL_WARNING ]] || return 0
    local message="$1"
    echo -e "$(Colors::get YELLOW)[WARN]$(Colors::reset) $message" >&2
    Logger::to_file "WARN" "$message"
}

Logger::error() {
    [[ "$LOG_LEVEL" -le $LOG_LEVEL_ERROR ]] || return 0
    local message="$1"
    echo -e "$(Colors::get RED)[ERROR]$(Colors::reset) $message" >&2
    Logger::to_file "ERROR" "$message"
}

Logger::success() {
    local message="$1"
    echo -e "$(Colors::get GREEN)[✓]$(Colors::reset) $message" >&2
}

Logger::to_file() {
    local level="$1"
    local message="$2"
    
    if [[ -n "$LOG_FILE" && -w "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
    fi
}

Logger::set_level() {
    local level="$1"
    case "$level" in
        debug) LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        info) LOG_LEVEL=$LOG_LEVEL_INFO ;;
        warn) LOG_LEVEL=$LOG_LEVEL_WARNING ;;
        error) LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        *) Logger::warn "Unknown log level: $level" ;;
    esac
}

Logger::set_file() {
    LOG_FILE="$1"
}

Logger::banner() {
    local message="$1"
    echo -e "$(Colors::get BOLD)$message$(Colors::reset)" >&2
}
