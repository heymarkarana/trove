#!/usr/bin/env zsh
# Example: System Monitoring with Trove
# Demonstrates how to collect system metrics

# Source libraries
source /opt/trove/lib/trove_logging.zsh
source /opt/trove/lib/trove_monitoring.zsh

trove_bot "System Metrics Collection"

# Display all metrics
trove_running "Collecting system metrics"
trove_show_metrics
echo ""

# Individual metric examples
trove_bot "Individual Metrics"

echo "Disk Usage: $(trove_get_disk_usage /)%"
echo "Memory Usage: $(trove_get_memory_usage)%"
echo "CPU Load: $(trove_get_cpu_load)"
echo "Hostname: $(trove_get_hostname)"
echo "IP Address: $(trove_get_ip_address)"
echo "Uptime: $(trove_get_uptime_human)"
echo ""

trove_ok "Metrics collected successfully"
