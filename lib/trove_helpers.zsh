#!/usr/bin/env zsh
# Trove Helper Utilities
# Common utilities for path validation, permissions, environment, and platform detection

###############################################################################
# Path Validation
###############################################################################

# Check if a path exists
# Usage: trove_path_exists "/path/to/check"
# Returns: 0 if exists, 1 if not
trove_path_exists() {
    [[ -e "$1" ]]
}

# Check if path is a directory
# Usage: trove_is_directory "/path/to/check"
# Returns: 0 if directory, 1 if not
trove_is_directory() {
    [[ -d "$1" ]]
}

# Check if path is a file
# Usage: trove_is_file "/path/to/check"
# Returns: 0 if file, 1 if not
trove_is_file() {
    [[ -f "$1" ]]
}

# Check if path is a symlink
# Usage: trove_is_symlink "/path/to/check"
# Returns: 0 if symlink, 1 if not
trove_is_symlink() {
    [[ -L "$1" ]]
}

# Ensure directory exists (create if missing)
# Usage: trove_ensure_directory "/path/to/dir"
# Returns: 0 on success, 1 on failure
trove_ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" 2>/dev/null
        return $?
    fi
    return 0
}

# Get absolute path (resolve symlinks)
# Usage: abs_path=$(trove_get_absolute_path "/path/to/resolve")
trove_get_absolute_path() {
    local path="$1"
    if [[ -e "$path" ]]; then
        # Use realpath if available, fallback to readlink
        if command -v realpath >/dev/null 2>&1; then
            realpath "$path"
        else
            readlink -f "$path" 2>/dev/null || echo "$path"
        fi
    else
        echo "$path"
    fi
}

# Get directory of a file
# Usage: dir=$(trove_get_directory "/path/to/file")
trove_get_directory() {
    local path="$1"
    if [[ -d "$path" ]]; then
        echo "$path"
    elif [[ -f "$path" ]]; then
        dirname "$path"
    else
        dirname "$path"
    fi
}

###############################################################################
# Permission Checking
###############################################################################

# Check if path is readable
# Usage: trove_is_readable "/path/to/check"
# Returns: 0 if readable, 1 if not
trove_is_readable() {
    [[ -r "$1" ]]
}

# Check if path is writable
# Usage: trove_is_writable "/path/to/check"
# Returns: 0 if writable, 1 if not
trove_is_writable() {
    [[ -w "$1" ]]
}

# Check if path is executable
# Usage: trove_is_executable "/path/to/check"
# Returns: 0 if executable, 1 if not
trove_is_executable() {
    [[ -x "$1" ]]
}

# Check if running as root
# Usage: trove_is_root
# Returns: 0 if root, 1 if not
trove_is_root() {
    [[ "$EUID" -eq 0 ]]
}

# Check if running with sudo
# Usage: trove_is_sudo
# Returns: 0 if sudo, 1 if not
trove_is_sudo() {
    [[ -n "$SUDO_USER" ]]
}

###############################################################################
# Platform Detection
###############################################################################

# Get platform name (darwin, linux, etc.)
# Usage: platform=$(trove_get_platform)
trove_get_platform() {
    uname -s | tr '[:upper:]' '[:lower:]'
}

# Check if running on macOS
# Usage: trove_is_macos
# Returns: 0 if macOS, 1 if not
trove_is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# Check if running on Linux
# Usage: trove_is_linux
# Returns: 0 if Linux, 1 if not
trove_is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}

# Check if running on Ubuntu
# Usage: trove_is_ubuntu
# Returns: 0 if Ubuntu, 1 if not
trove_is_ubuntu() {
    if [[ -f /etc/os-release ]]; then
        grep -q "ID=ubuntu" /etc/os-release
        return $?
    fi
    return 1
}

# Get OS distribution name (Ubuntu, Debian, etc.)
# Usage: distro=$(trove_get_distribution)
trove_get_distribution() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

# Get OS version
# Usage: version=$(trove_get_os_version)
trove_get_os_version() {
    if trove_is_macos; then
        sw_vers -productVersion
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${VERSION_ID:-unknown}"
    else
        echo "unknown"
    fi
}

###############################################################################
# Command Detection
###############################################################################

# Check if command exists
# Usage: trove_command_exists "git"
# Returns: 0 if exists, 1 if not
trove_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Require command (exit if missing)
# Usage: trove_require_command "git" "Install git first"
trove_require_command() {
    local cmd="$1"
    local message="${2:-Command not found: $cmd}"

    if ! trove_command_exists "$cmd"; then
        echo "ERROR: $message" >&2
        return 1
    fi
}

# Get command path
# Usage: path=$(trove_get_command_path "git")
trove_get_command_path() {
    command -v "$1" 2>/dev/null
}

###############################################################################
# Environment Helpers
###############################################################################

# Check if variable is set (not empty)
# Usage: trove_is_set "$VAR_NAME"
# Returns: 0 if set and not empty, 1 otherwise
trove_is_set() {
    local var_name="$1"
    [[ -n "${(P)var_name}" ]]
}

# Validate required environment variables
# Usage: trove_require_vars "VAR1" "VAR2" "VAR3"
# Returns: 0 if all set, 1 if any missing
trove_require_vars() {
    local missing=()

    for var in "$@"; do
        if ! trove_is_set "$var"; then
            missing+=("$var")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing required environment variables: ${missing[*]}" >&2
        return 1
    fi

    return 0
}

# Get environment variable with default
# Usage: value=$(trove_get_env "VAR_NAME" "default_value")
trove_get_env() {
    local var_name="$1"
    local default="${2:-}"

    if trove_is_set "$var_name"; then
        echo "${(P)var_name}"
    else
        echo "$default"
    fi
}

###############################################################################
# String Utilities
###############################################################################

# Trim whitespace from string
# Usage: trimmed=$(trove_trim "  text  ")
trove_trim() {
    local text="$1"
    # Remove leading whitespace
    text="${text#"${text%%[![:space:]]*}"}"
    # Remove trailing whitespace
    text="${text%"${text##*[![:space:]]}"}"
    echo "$text"
}

# Convert string to lowercase
# Usage: lower=$(trove_lowercase "TEXT")
trove_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Convert string to uppercase
# Usage: upper=$(trove_uppercase "text")
trove_uppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Check if string starts with prefix
# Usage: trove_starts_with "hello world" "hello"
# Returns: 0 if starts with, 1 if not
trove_starts_with() {
    local string="$1"
    local prefix="$2"
    [[ "$string" == "$prefix"* ]]
}

# Check if string ends with suffix
# Usage: trove_ends_with "hello.txt" ".txt"
# Returns: 0 if ends with, 1 if not
trove_ends_with() {
    local string="$1"
    local suffix="$2"
    [[ "$string" == *"$suffix" ]]
}

###############################################################################
# User Interaction
###############################################################################

# Ask yes/no question
# Usage: if trove_ask_yes_no "Continue?"; then ... fi
# Returns: 0 for yes, 1 for no
trove_ask_yes_no() {
    local question="$1"
    local default="${2:-n}"  # Default to no
    local prompt

    if [[ "$default" == "y" ]]; then
        prompt="$question [Y/n]: "
    else
        prompt="$question [y/N]: "
    fi

    echo -n "$prompt" >&2
    read -r response

    # Empty response uses default
    if [[ -z "$response" ]]; then
        response="$default"
    fi

    # Check response
    response=$(trove_lowercase "$response")
    [[ "$response" =~ ^y(es)?$ ]]
}

###############################################################################
# Process Utilities
###############################################################################

# Check if process is running by name
# Usage: trove_process_running "nginx"
# Returns: 0 if running, 1 if not
trove_process_running() {
    local process_name="$1"
    pgrep -f "$process_name" >/dev/null 2>&1
}

# Get process ID by name
# Usage: pid=$(trove_get_pid "nginx")
trove_get_pid() {
    local process_name="$1"
    pgrep -f "$process_name" | head -1
}

###############################################################################
# Help Function
###############################################################################

trove_helpers_help() {
    echo "Trove Helper Utilities"
    echo ""
    echo "Path Validation:"
    echo "  trove_path_exists, trove_is_directory, trove_is_file, trove_is_symlink"
    echo "  trove_ensure_directory, trove_get_absolute_path, trove_get_directory"
    echo ""
    echo "Permission Checking:"
    echo "  trove_is_readable, trove_is_writable, trove_is_executable"
    echo "  trove_is_root, trove_is_sudo"
    echo ""
    echo "Platform Detection:"
    echo "  trove_get_platform, trove_is_macos, trove_is_linux, trove_is_ubuntu"
    echo "  trove_get_distribution, trove_get_os_version"
    echo ""
    echo "Command Detection:"
    echo "  trove_command_exists, trove_require_command, trove_get_command_path"
    echo ""
    echo "Environment:"
    echo "  trove_is_set, trove_require_vars, trove_get_env"
    echo ""
    echo "String Utilities:"
    echo "  trove_trim, trove_lowercase, trove_uppercase"
    echo "  trove_starts_with, trove_ends_with"
    echo ""
    echo "User Interaction:"
    echo "  trove_ask_yes_no"
    echo ""
    echo "Process Utilities:"
    echo "  trove_process_running, trove_get_pid"
    echo ""
}

###############################################################################
# Initialization
###############################################################################

# Check if being executed directly (for testing)
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    if [[ "$#" -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        trove_helpers_help
        exit 0
    fi
fi
