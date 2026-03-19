#!/usr/bin/env zsh
# Trove Logging System
# Structured logging with level filtering and colored output

###############################################################################
# Sudo User Detection
###############################################################################
# Determine the logged-in user's home directory when running with sudo
if [[ -n "$SUDO_USER" ]]; then
    TROVE_ORIGINAL_USER_HOME=$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)
    if [[ -z "$TROVE_ORIGINAL_USER_HOME" ]]; then
        # Fallback for macOS which doesn't have getent
        TROVE_ORIGINAL_USER_HOME=$(dscl . -read "/Users/$SUDO_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    fi
    # Final fallback
    [[ -z "$TROVE_ORIGINAL_USER_HOME" ]] && TROVE_ORIGINAL_USER_HOME="${HOME}"
else
    TROVE_ORIGINAL_USER_HOME="${HOME}"
fi

###############################################################################
# Configuration
###############################################################################
# Set defaults if variables aren't in the environment yet
: ${TROVE_LOG_LEVEL:=INFO}
: ${TROVE_OUTPUT_DISPLAY:=true}
: ${TROVE_COLORSCHEME:=monokai}

# Internal configuration
TROVE_ENABLE_LOGGING=true
TROVE_LOG_LEVEL_INTERNAL="${TROVE_LOG_LEVEL}"
TROVE_OUTPUT_DISPLAY_INTERNAL="${TROVE_OUTPUT_DISPLAY}"

###############################################################################
# Load Color Scheme
###############################################################################
# Source colors if not already loaded
if [[ -z "$COL_RESET" ]]; then
    TROVE_LIB_DIR="${0:A:h}"
    if [[ -f "${TROVE_LIB_DIR}/trove_colors.zsh" ]]; then
        source "${TROVE_LIB_DIR}/trove_colors.zsh"
    else
        # Fallback: minimal colors if colors library not found
        COL_RESET="\033[0m"
        COL_RED="\033[31m"
        COL_GREEN="\033[32m"
        COL_YELLOW="\033[33m"
        COL_ORANGE="\033[33m"
        COL_PURPLE="\033[35m"
        COL_BOLD_PURPLE="\033[1;35m"
        COL_BLUE="\033[34m"
        COL_CYAN="\033[36m"
        COL_WHITE="\033[37m"
        COL_GRAY="\033[90m"
        COL_DARK_GREEN="\033[42m"
    fi
fi

###############################################################################
# Help Function
###############################################################################
trove_show_help() {
    echo
    echo "Trove Logging and Output Functions"
    echo
    echo "Provides structured logging with level filtering and colored output."
    echo
    echo "Functions Overview:"
    echo
    echo "  trove_log LEVEL \"message\""
    echo "      General-purpose logging function for all severity levels."
    echo "      Levels: TRACE, DEBUG, INFO, WARN, ERROR, FATAL"
    echo "      Example: trove_log INFO \"Starting application\""
    echo
    echo "  Specialized Output Functions:"
    echo
    echo "  trove_bot \"message\""
    echo "      Announces major tasks or multi-step operations (bold purple ✪)."
    echo "      Example: trove_bot \"Installing System Packages\""
    echo
    echo "  trove_running \"message\""
    echo "      Logs individual configuration or setup steps (orange ✨)."
    echo "      Example: trove_running \"Setting default shell to zsh\""
    echo
    echo "  trove_action \"message\""
    echo "      Full-width header for user input prompts (green background)."
    echo "      Example: trove_action \"User Configuration Setup\""
    echo
    echo "  trove_ok \"message\""
    echo "      Indicates successful validation or selection (green ➤)."
    echo "      Example: trove_ok \"Configuration validated successfully\""
    echo
    echo "  Execution Functions:"
    echo
    echo "  trove_silent_run \"command\" \"message\" [LEVEL]"
    echo "      Executes a command and logs success/failure automatically."
    echo "      Example: trove_silent_run \"ls /tmp\" \"Listing files\" DEBUG"
    echo
    echo "  trove_print_result EXIT_CODE \"message\""
    echo "      Logs command result based on exit code."
    echo "      Subfunctions:"
    echo "        - trove_print_success: Logs success (green ✔)"
    echo "        - trove_print_error: Logs error (red ✖)"
    echo
    echo "Configuration (Environment Variables):"
    echo "  TROVE_LOG_LEVEL         - Log level filter (default: INFO)"
    echo "  TROVE_OUTPUT_DISPLAY    - Show command output (default: true)"
    echo "  TROVE_COLORSCHEME       - Color scheme (default: monokai)"
    echo
    echo "Usage Guidelines:"
    echo "  - trove_bot:        Major tasks requiring multiple steps"
    echo "  - trove_running:    Individual setup actions and configurations"
    echo "  - trove_action:     Headers before prompting the user for input"
    echo "  - trove_ok:         Validation confirmations and acceptance"
    echo "  - trove_log:        All other logging (DEBUG, INFO, WARN, ERROR, FATAL)"
    echo "  - trove_silent_run: Commands with automatic success/error logging"
    echo
}

###############################################################################
# Core Logging Functions
###############################################################################

# Function to get numeric log level for comparison
trove_log_level_num() {
    case $1 in
    FATAL) echo 6 ;; # Fatal is the highest level
    ERROR) echo 5 ;;
    WARN) echo 4 ;;
    INFO) echo 3 ;;
    DEBUG) echo 2 ;;
    TRACE) echo 1 ;; # Trace is the lowest level
    *) echo 0 ;; # Unknown log levels default to 0
    esac
}

# Main log function with level filtering
trove_log() {
    local level="$1"
    shift

    # If not a known level, treat it as plain message
    if [[ ! "$level" =~ ^(FATAL|ERROR|WARN|INFO|DEBUG|TRACE)$ ]]; then
        local message="${level} $*"
        if ${TROVE_ENABLE_LOGGING}; then
            echo "${message}" >&2
        fi
        return
    fi

    local message="$*"
    if ${TROVE_ENABLE_LOGGING}; then
        local current_level_num=$(trove_log_level_num "${TROVE_LOG_LEVEL_INTERNAL}")
        local message_level_num=$(trove_log_level_num "${level}")

        if ((message_level_num >= current_level_num)); then
            local log_message="${message}"

            case "$level" in
                FATAL) log_message="${COL_PURPLE}    [‼] ${COL_RESET}${log_message}" ;;
                ERROR) log_message="${COL_RED}    [✖] ${COL_RESET}${log_message}" ;;
                WARN)  log_message="${COL_YELLOW}    [⚠] ${COL_RESET}${log_message}" ;;
                INFO)  log_message="${COL_GREEN}    [✔] ${COL_RESET}${log_message}" ;;
                DEBUG) log_message="${COL_CYAN}    [✱] ${COL_RESET}${log_message}" ;;
                TRACE) log_message="${COL_GRAY}    [➤] ${COL_RESET}${log_message}" ;;
            esac

            echo "${log_message}" >&2
        fi
    fi
}

###############################################################################
# Specialized Output Functions
###############################################################################

# Success indicator
trove_ok() {
    printf "${COL_GREEN}    [➤] ${COL_RESET}%s\n" "$1" >&2
}

# Major section announcement
trove_bot() {
    echo "" >&2
    echo "" >&2
    printf "${COL_BOLD_PURPLE}    [✪] ${COL_RESET}%s \n" "$1" >&2
}

# Configuration step indicator
trove_running() {
    printf "${COL_ORANGE}   [✨] ${COL_RESET}%s \n" "$1" >&2
}

# Full-width header for user input sections
trove_action() {
    local message="  $1"
    local term_width=$(tput cols 2>/dev/null || echo 80)
    local padded_message="${COL_WHITE}${message}$(printf '%*s' $((term_width - ${#message})) '')"

    printf "${COL_DARK_GREEN}${padded_message}${COL_RESET}\n" >&2
}

###############################################################################
# Result Printing Functions
###############################################################################

# Print error message
trove_print_error() {
    printf "${COL_RED}    [✖] ${COL_RESET}%s\n" "$1" >&2
}

# Print success message
trove_print_success() {
    printf "${COL_GREEN}    [✔] ${COL_RESET}%s\n" "$1" >&2
}

# Print result based on exit code
trove_print_result() {
    if [ "$1" -eq 0 ]; then
        trove_print_success "$2"
    else
        trove_print_error "$2"
    fi

    return "$1"
}

###############################################################################
# Command Execution with Logging
###############################################################################

# Execute a command based on TROVE_OUTPUT_DISPLAY
# If TROVE_OUTPUT_DISPLAY is true, writes stdout to display
# If false, redirects stdout to /dev/null
# Usage: trove_silent_run "command_to_execute" "Log message" "Log level (default: DEBUG)"
trove_silent_run() {
    local cmd="$1"                    # Command to execute
    local log_message="$2"            # Message to log
    local log_level="${3:-DEBUG}"     # Log level (default to DEBUG)
    local result                      # Stores the result of the command

    if [[ "${TROVE_OUTPUT_DISPLAY_INTERNAL:-false}" == true ]]; then
        # Display command output
        eval "${cmd}"
        result=$?
    else
        # Suppress stdout
        eval "$cmd" >/dev/null 2>&1
        result=$?
    fi

    # Log the result
    trove_print_result ${result} "${log_message}"
    return ${result}
}

###############################################################################
# Configuration Functions
###############################################################################

# Set log level dynamically
trove_set_log_level() {
    local level="$1"
    if [[ "$level" =~ ^(FATAL|ERROR|WARN|INFO|DEBUG|TRACE)$ ]]; then
        TROVE_LOG_LEVEL_INTERNAL="$level"
        export TROVE_LOG_LEVEL="$level"
        trove_log DEBUG "Log level set to: $level"
    else
        trove_log ERROR "Invalid log level: $level"
        return 1
    fi
}

# Get current log level
trove_get_log_level() {
    echo "${TROVE_LOG_LEVEL_INTERNAL}"
}

# Enable/disable output display
trove_set_output_display() {
    local value="$1"
    if [[ "$value" =~ ^(true|false)$ ]]; then
        TROVE_OUTPUT_DISPLAY_INTERNAL="$value"
        export TROVE_OUTPUT_DISPLAY="$value"
        trove_log DEBUG "Output display set to: $value"
    else
        trove_log ERROR "Invalid output display value: $value (must be true or false)"
        return 1
    fi
}

###############################################################################
# Compatibility Shims (Non-prefixed functions)
###############################################################################

# Provide non-prefixed versions for backward compatibility (optional)
# Uncomment if you want both prefixed and non-prefixed functions available
#
# log() { trove_log "$@"; }
# ok() { trove_ok "$@"; }
# bot() { trove_bot "$@"; }
# running() { trove_running "$@"; }
# action() { trove_action "$@"; }
# print_error() { trove_print_error "$@"; }
# print_success() { trove_print_success "$@"; }
# print_result() { trove_print_result "$@"; }
# silent_run() { trove_silent_run "$@"; }

###############################################################################
# Initialization Check
###############################################################################

# Check if the script is being sourced or executed directly
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    # The script is being executed directly
    if [[ "$#" -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        trove_show_help
        exit 0
    fi
else
    # The script is being sourced
    return 0
fi

# Symbol reference: ‣ ★ ☛ ✪ ✱ ➠ ➡ ➥ ✔ ✘ ✦ ✨ ❖ ➤ ⬥ ⮕ ‼ ⚠
