#!/usr/bin/env zsh
# Trove Monitoring Utilities
# System metrics and monitoring integration helpers for Beszel, Arcane, etc.

###############################################################################
# Configuration
###############################################################################
: ${TROVE_MONITORING_URL:=""}          # URL for metric submission
: ${TROVE_MONITORING_ENABLED:=false}   # Enable/disable monitoring

###############################################################################
# System Metrics - Disk
###############################################################################

# Get disk usage percentage for a path
# Usage: usage=$(trove_get_disk_usage "/")
# Returns: Percentage (e.g., "45")
trove_get_disk_usage() {
    local path="${1:-.}"
    df -h "$path" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Get disk usage in GB
# Usage: used=$(trove_get_disk_used_gb "/")
# Returns: Used space in GB (e.g., "42.5")
trove_get_disk_used_gb() {
    local path="${1:-.}"
    df -BG "$path" 2>/dev/null | awk 'NR==2 {print $3}' | sed 's/G//'
}

# Get disk total in GB
# Usage: total=$(trove_get_disk_total_gb "/")
# Returns: Total space in GB (e.g., "100.0")
trove_get_disk_total_gb() {
    local path="${1:-.}"
    df -BG "$path" 2>/dev/null | awk 'NR==2 {print $2}' | sed 's/G//'
}

# Get disk available in GB
# Usage: avail=$(trove_get_disk_available_gb "/")
# Returns: Available space in GB (e.g., "57.5")
trove_get_disk_available_gb() {
    local path="${1:-.}"
    df -BG "$path" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//'
}

###############################################################################
# System Metrics - Memory
###############################################################################

# Get memory usage percentage
# Usage: usage=$(trove_get_memory_usage)
# Returns: Percentage (e.g., "65")
trove_get_memory_usage() {
    if command -v free >/dev/null 2>&1; then
        # Linux
        free | awk 'NR==2 {printf "%.0f", $3/$2 * 100}'
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        local used=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
        local wired=$(vm_stat | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
        local compressed=$(vm_stat | grep "Pages occupied by compressor" | awk '{print $5}' | sed 's/\.//')
        local total=$(sysctl -n hw.memsize)
        local page_size=$(pagesize)

        local used_bytes=$(( (used + wired + compressed) * page_size ))
        echo $(( used_bytes * 100 / total ))
    else
        echo "unknown"
    fi
}

# Get memory usage in MB
# Usage: used=$(trove_get_memory_used_mb)
# Returns: Used memory in MB (e.g., "4096")
trove_get_memory_used_mb() {
    if command -v free >/dev/null 2>&1; then
        # Linux
        free -m | awk 'NR==2 {print $3}'
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        local used=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
        local wired=$(vm_stat | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
        local compressed=$(vm_stat | grep "Pages occupied by compressor" | awk '{print $5}' | sed 's/\.//')
        local page_size=$(pagesize)

        local used_bytes=$(( (used + wired + compressed) * page_size ))
        echo $(( used_bytes / 1024 / 1024 ))
    else
        echo "unknown"
    fi
}

# Get total memory in MB
# Usage: total=$(trove_get_memory_total_mb)
# Returns: Total memory in MB (e.g., "8192")
trove_get_memory_total_mb() {
    if command -v free >/dev/null 2>&1; then
        # Linux
        free -m | awk 'NR==2 {print $2}'
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        local total=$(sysctl -n hw.memsize)
        echo $(( total / 1024 / 1024 ))
    else
        echo "unknown"
    fi
}

###############################################################################
# System Metrics - CPU
###############################################################################

# Get CPU load average (1 minute)
# Usage: load=$(trove_get_cpu_load)
# Returns: Load average (e.g., "1.23")
trove_get_cpu_load() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
}

# Get CPU load averages (1, 5, 15 minutes)
# Usage: loads=$(trove_get_cpu_loads)
# Returns: Space-separated loads (e.g., "1.23 0.98 0.87")
trove_get_cpu_loads() {
    uptime | awk -F'load average:' '{print $2}' | sed 's/,//g'
}

# Get CPU count
# Usage: count=$(trove_get_cpu_count)
# Returns: Number of CPUs (e.g., "4")
trove_get_cpu_count() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        sysctl -n hw.ncpu
    else
        nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo
    fi
}

# Get CPU usage percentage (average over short period)
# Usage: usage=$(trove_get_cpu_usage)
# Returns: Percentage (e.g., "35")
# Note: Requires a short measurement period
trove_get_cpu_usage() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS: Use top to get CPU usage
        top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//'
    elif command -v mpstat >/dev/null 2>&1; then
        # Linux with sysstat
        mpstat 1 1 | awk 'END {print 100 - $NF}'
    else
        # Fallback: Estimate from load average
        local load=$(trove_get_cpu_load)
        local cpus=$(trove_get_cpu_count)
        echo "scale=0; $load * 100 / $cpus" | bc 2>/dev/null || echo "unknown"
    fi
}

###############################################################################
# System Metrics - Network
###############################################################################

# Get hostname
# Usage: host=$(trove_get_hostname)
# Returns: Hostname (e.g., "webserver01")
trove_get_hostname() {
    hostname
}

# Get hostname (short, no domain)
# Usage: host=$(trove_get_hostname_short)
# Returns: Short hostname (e.g., "webserver01")
trove_get_hostname_short() {
    hostname -s 2>/dev/null || hostname | cut -d. -f1
}

# Get IP address (primary)
# Usage: ip=$(trove_get_ip_address)
# Returns: IP address (e.g., "10.0.10.5")
trove_get_ip_address() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS: Get primary interface IP
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1
    else
        # Linux: Get primary interface IP
        hostname -I 2>/dev/null | awk '{print $1}' || \
        ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1
    fi
}

###############################################################################
# System Metrics - Process
###############################################################################

# Get process count
# Usage: count=$(trove_get_process_count)
# Returns: Number of processes (e.g., "142")
trove_get_process_count() {
    ps aux | wc -l
}

# Get uptime in seconds
# Usage: seconds=$(trove_get_uptime_seconds)
# Returns: Uptime in seconds (e.g., "3600")
trove_get_uptime_seconds() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        local boot=$(sysctl -n kern.boottime | awk '{print $4}' | sed 's/,//')
        local now=$(date +%s)
        echo $(( now - boot ))
    else
        # Linux
        awk '{print int($1)}' /proc/uptime
    fi
}

# Get uptime in human-readable format
# Usage: uptime=$(trove_get_uptime_human)
# Returns: Uptime string (e.g., "2 days, 5 hours")
trove_get_uptime_human() {
    uptime | sed 's/.*up //' | sed 's/, *[0-9]* user.*//'
}

###############################################################################
# Monitoring Integration
###############################################################################

# Send a single metric to monitoring system
# Usage: trove_send_metric "metric_name" "value" ["unit"]
# Returns: 0 on success, 1 on failure
trove_send_metric() {
    local metric_name="$1"
    local value="$2"
    local unit="${3:-}"

    # Check if monitoring is enabled
    if [[ "${TROVE_MONITORING_ENABLED}" != "true" ]]; then
        return 0
    fi

    # Check if monitoring URL is configured
    if [[ -z "${TROVE_MONITORING_URL}" ]]; then
        echo "WARNING: TROVE_MONITORING_URL not configured" >&2
        return 1
    fi

    # Build JSON payload
    local payload=$(cat <<EOF
{
    "metric": "$metric_name",
    "value": $value,
    "unit": "$unit",
    "host": "$(trove_get_hostname)",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)

    # Send to monitoring system
    curl -X POST "${TROVE_MONITORING_URL}/metrics" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        -s -f >/dev/null 2>&1

    return $?
}

# Send all system metrics to monitoring system
# Usage: trove_send_system_metrics
# Returns: 0 on success
trove_send_system_metrics() {
    # Check if monitoring is enabled
    if [[ "${TROVE_MONITORING_ENABLED}" != "true" ]]; then
        return 0
    fi

    # Collect all metrics
    local disk_usage=$(trove_get_disk_usage "/")
    local memory_usage=$(trove_get_memory_usage)
    local cpu_load=$(trove_get_cpu_load)
    local uptime=$(trove_get_uptime_seconds)

    # Send metrics
    trove_send_metric "disk_usage" "$disk_usage" "percent"
    trove_send_metric "memory_usage" "$memory_usage" "percent"
    trove_send_metric "cpu_load" "$cpu_load" "load"
    trove_send_metric "uptime" "$uptime" "seconds"

    return 0
}

# Print all system metrics (for debugging)
# Usage: trove_show_metrics
trove_show_metrics() {
    echo "System Metrics:"
    echo "  Hostname:       $(trove_get_hostname)"
    echo "  IP Address:     $(trove_get_ip_address)"
    echo "  Uptime:         $(trove_get_uptime_human)"
    echo ""
    echo "Disk (/):"
    echo "  Usage:          $(trove_get_disk_usage "/")%"
    echo "  Used:           $(trove_get_disk_used_gb "/")GB"
    echo "  Total:          $(trove_get_disk_total_gb "/")GB"
    echo "  Available:      $(trove_get_disk_available_gb "/")GB"
    echo ""
    echo "Memory:"
    echo "  Usage:          $(trove_get_memory_usage)%"
    echo "  Used:           $(trove_get_memory_used_mb)MB"
    echo "  Total:          $(trove_get_memory_total_mb)MB"
    echo ""
    echo "CPU:"
    echo "  Count:          $(trove_get_cpu_count)"
    echo "  Load (1m):      $(trove_get_cpu_load)"
    echo "  Loads (1,5,15): $(trove_get_cpu_loads)"
    echo ""
    echo "Processes:        $(trove_get_process_count)"
}

###############################################################################
# Help Function
###############################################################################

trove_monitoring_help() {
    echo "Trove Monitoring Utilities"
    echo ""
    echo "Disk Metrics:"
    echo "  trove_get_disk_usage, trove_get_disk_used_gb, trove_get_disk_total_gb"
    echo ""
    echo "Memory Metrics:"
    echo "  trove_get_memory_usage, trove_get_memory_used_mb, trove_get_memory_total_mb"
    echo ""
    echo "CPU Metrics:"
    echo "  trove_get_cpu_load, trove_get_cpu_loads, trove_get_cpu_count, trove_get_cpu_usage"
    echo ""
    echo "Network:"
    echo "  trove_get_hostname, trove_get_hostname_short, trove_get_ip_address"
    echo ""
    echo "Process & Uptime:"
    echo "  trove_get_process_count, trove_get_uptime_seconds, trove_get_uptime_human"
    echo ""
    echo "Monitoring Integration:"
    echo "  trove_send_metric, trove_send_system_metrics, trove_show_metrics"
    echo ""
    echo "Configuration (Environment Variables):"
    echo "  TROVE_MONITORING_URL      - URL for metric submission"
    echo "  TROVE_MONITORING_ENABLED  - Enable/disable monitoring (true/false)"
    echo ""
}

###############################################################################
# Initialization
###############################################################################

# Check if being executed directly (for testing)
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    if [[ "$#" -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        trove_monitoring_help
        exit 0
    elif [[ "$1" == "show" ]]; then
        trove_show_metrics
        exit 0
    fi
fi
