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
# NB: the local is `target`, never `path` — `path` is a zsh special var aliased to
# $PATH, so `local path=…` would corrupt PATH and break the external lookups below.
trove_get_absolute_path() {
    local target="$1"
    if [[ -e "$target" ]]; then
        # Use realpath if available, fallback to readlink
        if command -v realpath >/dev/null 2>&1; then
            realpath "$target"
        else
            readlink -f "$target" 2>/dev/null || echo "$target"
        fi
    else
        echo "$target"
    fi
}

# Get directory of a file
# Usage: dir=$(trove_get_directory "/path/to/file")
trove_get_directory() {
    local target="$1"          # not `path` — see trove_get_absolute_path
    if [[ -d "$target" ]]; then
        echo "$target"
    elif [[ -f "$target" ]]; then
        dirname "$target"
    else
        dirname "$target"
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

# Get the owning username of a path (portable: macOS + Linux)
# Usage: owner=$(trove_stat_owner "/path")
# Returns: username on stdout + 0; empty + 1 if the path can't be stat'd
# NOTE: the local is `target`, not `path` — `path` is zsh's special array tied
# to $PATH; shadowing it would break command lookup inside the function.
trove_stat_owner() {
    local target="$1"
    [[ -e "$target" ]] || return 1
    if [[ "$OSTYPE" == darwin* ]]; then
        stat -f '%Su' "$target" 2>/dev/null
    else
        stat -c '%U' "$target" 2>/dev/null
    fi
}

# Get the octal permission bits of a path (portable: macOS + Linux)
# Usage: mode=$(trove_stat_mode "/path")    # e.g. "644", "2755"
# Returns: octal mode on stdout + 0; empty + 1 if the path can't be stat'd
# Includes the setuid/setgid/sticky bits (e.g. a setgid dir -> "2755"). On BSD
# `%Lp` reports only the low 9 permission bits, so we read the full mode (`%p`),
# mask off the file-type bits (07777), and emit it normalized like GNU `%a`
# (no leading zero) so both platforms return identical strings.
trove_stat_mode() {
    local target="$1"
    [[ -e "$target" ]] || return 1
    if [[ "$OSTYPE" == darwin* ]]; then
        local full
        full="$(stat -f '%p' "$target" 2>/dev/null)" || return 1
        printf '%o\n' "$(( 8#${full} & 8#7777 ))"
    else
        stat -c '%a' "$target" 2>/dev/null
    fi
}

# Get the owning group of a path (portable: macOS + Linux)
# Usage: group=$(trove_stat_group "/path")
# Returns: group name on stdout + 0; empty + 1 if the path can't be stat'd
trove_stat_group() {
    local target="$1"
    [[ -e "$target" ]] || return 1
    if [[ "$OSTYPE" == darwin* ]]; then
        stat -f '%Sg' "$target" 2>/dev/null
    else
        stat -c '%G' "$target" 2>/dev/null
    fi
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
    echo "  trove_stat_owner, trove_stat_group, trove_stat_mode (portable stat)"
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
# Git utilities
###############################################################################

# trove_ssh_host_from_url <url> → host (stdout); rc 1 if not derivable.
# Parses the git-host out of an ssh://git@host[:port]/…, scp-style git@host:owner/repo,
# or http(s)://host[:port]/… URL (or a bare hostname). Port is stripped.
trove_ssh_host_from_url() {
    emulate -L zsh
    local url="${1:-}" host="" rest
    [[ -n "$url" ]] || return 1
    case "$url" in
        ssh://*)            rest="${url#ssh://}"; rest="${rest#*@}"; host="${rest%%/*}" ;;
        http://*|https://*) rest="${url#*://}"; host="${rest%%/*}" ;;
        *://*)              return 1 ;;                              # other scheme
        *@*:*)              host="${url#*@}"; host="${host%%:*}" ;;  # scp-style git@host:owner/repo
        *)                  [[ "$url" == */* || "$url" == *:* ]] && return 1; host="$url" ;;
    esac
    host="${host%%:*}"                                              # strip :port
    [[ -n "$host" ]] || return 1
    print -r -- "$host"
}

# trove_ssh_verify <host> [user] — does our SSH key authenticate to <host>? Uses
# BatchMode (never prompts) + accept-new host keys (auto-adds the host key on first
# contact, so no known_hosts pre-seed needed). Forgejo/GitHub/GitLab return non-zero
# even on a SUCCESSFUL auth, so we match the greeting banner, not the exit code.
# Pure-zsh match (no external grep). Seams: TROVE_SSH_BIN, TROVE_SSH_CONNECT_TIMEOUT.
trove_ssh_verify() {
    emulate -L zsh
    local host="${1:-}" user="${2:-git}"
    [[ -n "$host" ]] || return 1
    local ssh="${TROVE_SSH_BIN:-ssh}"
    local probe; probe="$("$ssh" -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
        -o "ConnectTimeout=${TROVE_SSH_CONNECT_TIMEOUT:-6}" -T "${user}@${host}" 2>&1)"
    probe="${(L)probe}"
    [[ "$probe" == *"successfully authenticated"* || "$probe" == *"does not provide shell access"* ]]
}

# trove_git_prefer_ssh <repo-dir>
# Opportunistically switch a repo's `origin` from http(s):// to ssh:// — but only
# once the SSH key actually authenticates. Idempotent: an already-ssh origin is a
# no-op; an http(s) origin whose key doesn't verify yet is LEFT on http (with an
# info line) so a later run flips it. Seams: TROVE_GIT_BIN, TROVE_SSH_BIN.
trove_git_prefer_ssh() {
    emulate -L zsh
    local dir="${1:-}"
    [[ -n "$dir" ]] || { trove_log ERROR "trove_git_prefer_ssh: need a repo directory"; return 1; }
    local git="${TROVE_GIT_BIN:-git}"
    [[ -d "${dir}/.git" ]] || { trove_log WARN "trove_git_prefer_ssh: ${dir} is not a git repo"; return 0; }

    local url; url="$("$git" -C "$dir" remote get-url origin 2>/dev/null)" || {
        trove_log WARN "trove_git_prefer_ssh: ${dir} has no 'origin' remote"; return 0; }
    case "$url" in
        ssh://*|git@*)      trove_log INFO "git: ${dir:t} origin already SSH"; return 0 ;;
        http://*|https://*) ;;
        *)                  return 0 ;;   # unknown scheme — leave it alone
    esac

    # Derive ssh://git@<host>/<path> from http(s)://<host>[:port]/<path>.
    # NB: avoid `path` — it's a zsh special var aliased to PATH (would corrupt it).
    local host; host="$(trove_ssh_host_from_url "$url")" || {
        trove_log WARN "git: ${dir:t} could not parse host from origin"; return 0; }
    local rest="${url#http://}"; rest="${rest#https://}"; local rpath="${rest#*/}"
    local ssh_url="ssh://git@${host}/${rpath}"

    if trove_ssh_verify "$host"; then
        if "$git" -C "$dir" remote set-url origin "$ssh_url"; then
            trove_log INFO "git: ${dir:t} origin → SSH (${ssh_url})"
        else
            trove_log WARN "git: ${dir:t} failed to set SSH origin"
        fi
    else
        trove_log INFO "git: ${dir:t} staying on HTTP — SSH to ${host} not verified yet (re-run after adding your key)"
    fi
    return 0
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
