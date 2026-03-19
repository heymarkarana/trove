#!/usr/bin/env zsh
# Trove Date and Time Utilities
# Timestamp formatting, date arithmetic, timezone handling, duration calculations

###############################################################################
# Timestamp Formatting
###############################################################################

# Get current timestamp in ISO 8601 format (UTC)
# Usage: timestamp=$(trove_timestamp_iso)
# Returns: ISO 8601 timestamp (e.g., "2026-03-18T14:30:00Z")
trove_timestamp_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Get current timestamp in ISO 8601 format (local time)
# Usage: timestamp=$(trove_timestamp_iso_local)
# Returns: ISO 8601 timestamp with timezone (e.g., "2026-03-18T10:30:00-04:00")
trove_timestamp_iso_local() {
    date +"%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9][0-9]\)$/:\1/'
}

# Get current Unix timestamp (seconds since epoch)
# Usage: timestamp=$(trove_timestamp_unix)
# Returns: Unix timestamp (e.g., "1710774600")
trove_timestamp_unix() {
    date +%s
}

# Get current timestamp in custom format
# Usage: timestamp=$(trove_timestamp_format "%Y%m%d_%H%M%S")
# Returns: Formatted timestamp (e.g., "20260318_143000")
trove_timestamp_format() {
    local format="${1:-%Y-%m-%d %H:%M:%S}"
    date +"$format"
}

# Get current date (YYYY-MM-DD)
# Usage: date=$(trove_date_today)
# Returns: Date string (e.g., "2026-03-18")
trove_date_today() {
    date +%Y-%m-%d
}

# Get current time (HH:MM:SS)
# Usage: time=$(trove_time_now)
# Returns: Time string (e.g., "14:30:00")
trove_time_now() {
    date +%H:%M:%S
}

###############################################################################
# Date Arithmetic
###############################################################################

# Add days to a date
# Usage: new_date=$(trove_date_add_days "2026-03-18" 7)
# Returns: New date (e.g., "2026-03-25")
trove_date_add_days() {
    local date="$1"
    local days="$2"

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        date -j -v+${days}d -f "%Y-%m-%d" "$date" +%Y-%m-%d
    else
        # Linux
        date -d "$date + $days days" +%Y-%m-%d
    fi
}

# Subtract days from a date
# Usage: new_date=$(trove_date_sub_days "2026-03-18" 7)
# Returns: New date (e.g., "2026-03-11")
trove_date_sub_days() {
    local date="$1"
    local days="$2"

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        date -j -v-${days}d -f "%Y-%m-%d" "$date" +%Y-%m-%d
    else
        # Linux
        date -d "$date - $days days" +%Y-%m-%d
    fi
}

# Get date N days ago
# Usage: past_date=$(trove_date_days_ago 7)
# Returns: Date (e.g., "2026-03-11")
trove_date_days_ago() {
    local days="$1"
    trove_date_sub_days "$(trove_date_today)" "$days"
}

# Get date N days from now
# Usage: future_date=$(trove_date_days_from_now 7)
# Returns: Date (e.g., "2026-03-25")
trove_date_days_from_now() {
    local days="$1"
    trove_date_add_days "$(trove_date_today)" "$days"
}

# Calculate days between two dates
# Usage: days=$(trove_date_diff "2026-03-11" "2026-03-18")
# Returns: Number of days (e.g., "7")
trove_date_diff() {
    local date1="$1"
    local date2="$2"

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        local ts1=$(date -j -f "%Y-%m-%d" "$date1" +%s)
        local ts2=$(date -j -f "%Y-%m-%d" "$date2" +%s)
    else
        # Linux
        local ts1=$(date -d "$date1" +%s)
        local ts2=$(date -d "$date2" +%s)
    fi

    echo $(( (ts2 - ts1) / 86400 ))
}

###############################################################################
# Duration Calculations
###############################################################################

# Calculate duration between two timestamps (in seconds)
# Usage: duration=$(trove_duration_seconds "1710774000" "1710774600")
# Returns: Duration in seconds (e.g., "600")
trove_duration_seconds() {
    local start="$1"
    local end="$2"
    echo $(( end - start ))
}

# Format duration in seconds to human-readable format
# Usage: formatted=$(trove_duration_format 3665)
# Returns: Human-readable duration (e.g., "1h 1m 5s")
trove_duration_format() {
    local seconds="$1"

    local days=$(( seconds / 86400 ))
    local hours=$(( (seconds % 86400) / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$(( seconds % 60 ))

    local result=""

    [[ $days -gt 0 ]] && result="${days}d "
    [[ $hours -gt 0 ]] && result="${result}${hours}h "
    [[ $minutes -gt 0 ]] && result="${result}${minutes}m "
    [[ $secs -gt 0 || -z "$result" ]] && result="${result}${secs}s"

    echo "$result" | sed 's/ $//'
}

# Format duration in seconds to HH:MM:SS format
# Usage: formatted=$(trove_duration_hms 3665)
# Returns: HH:MM:SS format (e.g., "01:01:05")
trove_duration_hms() {
    local seconds="$1"

    local hours=$(( seconds / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$(( seconds % 60 ))

    printf "%02d:%02d:%02d" $hours $minutes $secs
}

# Measure duration of a command
# Usage: duration=$(trove_measure_duration "sleep 2")
# Returns: Duration in seconds
trove_measure_duration() {
    local command="$1"
    local start=$(trove_timestamp_unix)

    eval "$command" >/dev/null 2>&1

    local end=$(trove_timestamp_unix)
    echo $(( end - start ))
}

###############################################################################
# Timezone Handling
###############################################################################

# Get current timezone
# Usage: tz=$(trove_get_timezone)
# Returns: Timezone (e.g., "America/New_York")
trove_get_timezone() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        readlink /etc/localtime | sed 's#/var/db/timezone/zoneinfo/##'
    else
        # Linux
        timedatectl show --property=Timezone --value 2>/dev/null || \
        cat /etc/timezone 2>/dev/null || \
        echo "UTC"
    fi
}

# Get UTC offset
# Usage: offset=$(trove_get_utc_offset)
# Returns: UTC offset (e.g., "-0400")
trove_get_utc_offset() {
    date +%z
}

# Convert timestamp to specific timezone
# Usage: converted=$(trove_convert_timezone "2026-03-18T14:30:00Z" "America/New_York")
# Returns: Timestamp in target timezone
trove_convert_timezone() {
    local timestamp="$1"
    local target_tz="$2"

    TZ="$target_tz" date -d "$timestamp" +"%Y-%m-%dT%H:%M:%S%z" 2>/dev/null || \
    TZ="$target_tz" date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" +"%Y-%m-%dT%H:%M:%S%z" 2>/dev/null || \
    echo "Error: Could not convert timezone"
}

###############################################################################
# Parsing and Validation
###############################################################################

# Parse ISO 8601 timestamp to Unix timestamp
# Usage: unix=$(trove_parse_iso "2026-03-18T14:30:00Z")
# Returns: Unix timestamp (e.g., "1710774600")
trove_parse_iso() {
    local iso_timestamp="$1"

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_timestamp" +%s 2>/dev/null || \
        date -j -f "%Y-%m-%dT%H:%M:%S" "$iso_timestamp" +%s 2>/dev/null
    else
        # Linux
        date -d "$iso_timestamp" +%s
    fi
}

# Validate date format (YYYY-MM-DD)
# Usage: if trove_is_valid_date "2026-03-18"; then ... fi
# Returns: 0 if valid, 1 if invalid
trove_is_valid_date() {
    local date_str="$1"

    # Check format
    if [[ ! "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 1
    fi

    # Try to parse
    if [[ "$(uname -s)" == "Darwin" ]]; then
        date -j -f "%Y-%m-%d" "$date_str" >/dev/null 2>&1
    else
        date -d "$date_str" >/dev/null 2>&1
    fi
}

# Validate timestamp format (ISO 8601)
# Usage: if trove_is_valid_timestamp "2026-03-18T14:30:00Z"; then ... fi
# Returns: 0 if valid, 1 if invalid
trove_is_valid_timestamp() {
    local timestamp="$1"

    # Try to parse
    trove_parse_iso "$timestamp" >/dev/null 2>&1
}

###############################################################################
# Convenience Functions
###############################################################################

# Get start of today (00:00:00)
# Usage: start=$(trove_start_of_today)
# Returns: Unix timestamp
trove_start_of_today() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        date -j -f "%Y-%m-%d" "$(trove_date_today)" +%s
    else
        date -d "$(trove_date_today) 00:00:00" +%s
    fi
}

# Get end of today (23:59:59)
# Usage: end=$(trove_end_of_today)
# Returns: Unix timestamp
trove_end_of_today() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        date -j -f "%Y-%m-%d %H:%M:%S" "$(trove_date_today) 23:59:59" +%s
    else
        date -d "$(trove_date_today) 23:59:59" +%s
    fi
}

# Get age of file in days
# Usage: age=$(trove_file_age_days "/path/to/file")
# Returns: Age in days (e.g., "7")
trove_file_age_days() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "Error: File not found" >&2
        return 1
    fi

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        local file_time=$(stat -f %m "$file")
    else
        # Linux
        local file_time=$(stat -c %Y "$file")
    fi

    local now=$(trove_timestamp_unix)
    echo $(( (now - file_time) / 86400 ))
}

# Check if timestamp is in the past
# Usage: if trove_is_past "1710774000"; then ... fi
# Returns: 0 if past, 1 if future
trove_is_past() {
    local timestamp="$1"
    local now=$(trove_timestamp_unix)
    [[ $timestamp -lt $now ]]
}

# Check if timestamp is in the future
# Usage: if trove_is_future "1710774000"; then ... fi
# Returns: 0 if future, 1 if past
trove_is_future() {
    local timestamp="$1"
    local now=$(trove_timestamp_unix)
    [[ $timestamp -gt $now ]]
}

###############################################################################
# Logging Integration
###############################################################################

# Get timestamp for log files (YYYYMMDD-HHMMSS)
# Usage: timestamp=$(trove_log_timestamp)
# Returns: Log-friendly timestamp (e.g., "20260318-143000")
trove_log_timestamp() {
    date +%Y%m%d-%H%M%S
}

# Get date for log files (YYYY-MM-DD)
# Usage: date=$(trove_log_date)
# Returns: Log-friendly date (e.g., "2026-03-18")
trove_log_date() {
    trove_date_today
}

###############################################################################
# Help Function
###############################################################################

trove_date_help() {
    echo "Trove Date and Time Utilities"
    echo ""
    echo "Timestamp Formatting:"
    echo "  trove_timestamp_iso, trove_timestamp_iso_local, trove_timestamp_unix"
    echo "  trove_timestamp_format, trove_date_today, trove_time_now"
    echo ""
    echo "Date Arithmetic:"
    echo "  trove_date_add_days, trove_date_sub_days, trove_date_days_ago"
    echo "  trove_date_days_from_now, trove_date_diff"
    echo ""
    echo "Duration:"
    echo "  trove_duration_seconds, trove_duration_format, trove_duration_hms"
    echo "  trove_measure_duration"
    echo ""
    echo "Timezone:"
    echo "  trove_get_timezone, trove_get_utc_offset, trove_convert_timezone"
    echo ""
    echo "Parsing & Validation:"
    echo "  trove_parse_iso, trove_is_valid_date, trove_is_valid_timestamp"
    echo ""
    echo "Convenience:"
    echo "  trove_start_of_today, trove_end_of_today, trove_file_age_days"
    echo "  trove_is_past, trove_is_future"
    echo ""
    echo "Logging:"
    echo "  trove_log_timestamp, trove_log_date"
    echo ""
}

###############################################################################
# Initialization
###############################################################################

# Check if being executed directly (for testing)
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    if [[ "$#" -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        trove_date_help
        exit 0
    fi
fi
