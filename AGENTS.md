# Trove - AI Agent Guide

This document helps AI agents understand how to use Trove when working with shell scripts and applications in the kuzcotopia ecosystem.

---

## What is Trove?

Trove is a **shared utilities library** that provides consistent, colorful logging and helper functions for shell scripts and compiled applications. Think of it as a standardized toolkit for:

- 📝 **Structured Logging** - Level-filtered logs with beautiful colored output
- 🎨 **Color Schemes** - Multiple themes (Monokai, Solarized, Nord, Dracula, Gruvbox)
- 📊 **System Monitoring** - CPU, memory, disk metrics for monitoring integrations
- 🛠️ **Path Utilities** - File validation, permissions, directory operations
- 📅 **Date/Time** - Timestamps, date arithmetic, duration formatting
- 🚀 **CLI Binary** - `klog` for logging from any language (Go, Python, Rust, etc.)

**Version**: 0.1.0-beta
**Installation Path**: `/opt/trove`

---

## When to Use Trove

Use Trove when you need to:

1. **Add logging to shell scripts** - Consistent, colorful output across all scripts
2. **Log from compiled binaries** - Use `klog` CLI from any programming language
3. **Validate paths and permissions** - Before file operations
4. **Monitor system metrics** - CPU, memory, disk usage for Beszel/Arcane
5. **Work with dates and times** - Formatting, arithmetic, duration calculations
6. **Standardize output** - Consistent UX across the kuzcotopia ecosystem

---

## Quick Start

### For Shell Scripts

```bash
#!/usr/bin/env zsh
# Source the library
source /opt/trove/lib/trove_logging.zsh

# Use logging functions
trove_log INFO "Application started"
trove_bot "Installing Dependencies"
trove_running "Downloading packages"
trove_ok "Installation complete"
```

### For Compiled Applications

```python
# Python example
import subprocess

def log(level, message):
    subprocess.run(["/opt/trove/bin/klog", level, message])

log("INFO", "Python app started")
log("ERROR", "Connection failed")
```

```go
// Go example
package main

import "os/exec"

func log(level, message string) {
    exec.Command("/opt/trove/bin/klog", level, message).Run()
}

func main() {
    log("INFO", "Go app started")
}
```

---

## Common Usage Patterns

### 1. Shell Script with Logging

```bash
#!/usr/bin/env zsh
source /opt/trove/lib/trove_logging.zsh
source /opt/trove/lib/trove_helpers.zsh

# Set configuration
export TROVE_LOG_LEVEL="INFO"
trove_set_colorscheme "monokai"

# Major section header
trove_bot "Deploy Application"

# Check requirements
if ! trove_command_exists "git"; then
    trove_log ERROR "Git is required but not installed"
    exit 1
fi

# Configuration steps
trove_running "Cloning repository"
trove_silent_run "git clone https://example.com/repo.git" "Cloning" INFO

trove_running "Installing dependencies"
trove_silent_run "npm install" "Installing" INFO

# Success confirmation
trove_ok "Deployment complete"
```

### 2. System Monitoring Script

```bash
#!/usr/bin/env zsh
source /opt/trove/lib/trove_monitoring.zsh

# Enable monitoring
export TROVE_MONITORING_ENABLED="true"
export TROVE_MONITORING_URL="https://beszel.example.com"

# Get system metrics
disk_usage=$(trove_get_disk_usage "/")
memory_usage=$(trove_get_memory_usage)
cpu_load=$(trove_get_cpu_load)

# Send to monitoring system
trove_send_metric "disk_usage" "$disk_usage" "percent"
trove_send_metric "memory_usage" "$memory_usage" "percent"
trove_send_metric "cpu_load" "$cpu_load" ""

# Or send all at once
trove_send_system_metrics
```

### 3. Path Validation Before Operations

```bash
#!/usr/bin/env zsh
source /opt/trove/lib/trove_helpers.zsh
source /opt/trove/lib/trove_logging.zsh

CONFIG_DIR="/etc/myapp"

# Validate directory exists
if ! trove_path_exists "$CONFIG_DIR"; then
    trove_log ERROR "Config directory not found: $CONFIG_DIR"
    exit 1
fi

# Check permissions
if ! trove_is_writable "$CONFIG_DIR"; then
    trove_log ERROR "No write permission for: $CONFIG_DIR"
    exit 1
fi

# Ensure subdirectory exists
trove_ensure_directory "$CONFIG_DIR/cache"

trove_log INFO "All path validations passed"
```

### 4. Date/Time Operations

```bash
#!/usr/bin/env zsh
source /opt/trove/lib/trove_date.zsh

# Get timestamps
echo "ISO timestamp: $(trove_timestamp_iso)"
echo "Unix timestamp: $(trove_timestamp_unix)"
echo "Today's date: $(trove_date_today)"

# Date arithmetic
tomorrow=$(trove_date_days_from_now 1)
last_week=$(trove_date_days_ago 7)
echo "Tomorrow: $tomorrow"
echo "Last week: $last_week"

# Duration measurement
start=$(trove_timestamp_unix)
sleep 2
end=$(trove_timestamp_unix)
duration=$(trove_duration_seconds $start $end)
echo "Operation took: $(trove_duration_format $duration)"

# File age checking
log_file="/var/log/myapp.log"
if trove_path_exists "$log_file"; then
    age=$(trove_file_age_days "$log_file")
    echo "Log file is $age days old"
fi
```

### 5. User Input with Colored Prompts

```bash
#!/usr/bin/env zsh
source /opt/trove/lib/trove_logging.zsh
source /opt/trove/lib/trove_helpers.zsh

# User input section
trove_action "Configuration Setup"

# Ask yes/no questions
if trove_ask_yes_no "Enable monitoring?" "y"; then
    export TROVE_MONITORING_ENABLED="true"
    trove_ok "Monitoring enabled"
else
    trove_log INFO "Monitoring disabled"
fi

# Get environment variable with default
PORT=$(trove_get_env "PORT" "8080")
trove_log INFO "Using port: $PORT"
```

### 6. Multi-Language Logging Integration

**From Python:**
```python
import subprocess
import sys

def klog(level, message):
    """Log using Trove's klog binary"""
    try:
        subprocess.run(["/opt/trove/bin/klog", level, message], check=True)
    except subprocess.CalledProcessError:
        print(f"[{level}] {message}", file=sys.stderr)

# Usage
klog("INFO", "Application started")
klog("WARN", "Low memory detected")
klog("ERROR", "Database connection failed")
```

**From Go:**
```go
package main

import (
    "fmt"
    "os/exec"
)

type Logger struct{}

func (l *Logger) Log(level, message string) error {
    cmd := exec.Command("/opt/trove/bin/klog", level, message)
    return cmd.Run()
}

func main() {
    logger := &Logger{}
    logger.Log("INFO", "Go application started")
    logger.Log("ERROR", "Processing failed")
}
```

**From Rust:**
```rust
use std::process::Command;

fn klog(level: &str, message: &str) {
    Command::new("/opt/trove/bin/klog")
        .arg(level)
        .arg(message)
        .output()
        .expect("Failed to execute klog");
}

fn main() {
    klog("INFO", "Rust application started");
    klog("ERROR", "Connection timeout");
}
```

---

## Key Functions Reference

### Essential Logging Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `trove_log LEVEL "msg"` | Level-filtered logging | `trove_log INFO "Started"` |
| `trove_bot "msg"` | Major section header | `trove_bot "Installation"` |
| `trove_running "msg"` | Configuration step | `trove_running "Setting up DB"` |
| `trove_ok "msg"` | Success confirmation | `trove_ok "Complete"` |
| `trove_silent_run "cmd" "msg"` | Execute and log | `trove_silent_run "make" "Building"` |

**Log Levels**: TRACE, DEBUG, INFO, WARN, ERROR, FATAL

### Essential Helper Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `trove_path_exists "/path"` | Check if path exists | `if trove_path_exists "/opt/app"; then` |
| `trove_is_writable "/path"` | Check write permission | `if trove_is_writable "$dir"; then` |
| `trove_command_exists "cmd"` | Check if command available | `if trove_command_exists "git"; then` |
| `trove_ensure_directory "/path"` | Create dir if missing | `trove_ensure_directory "/var/cache/app"` |
| `trove_get_env "VAR" "default"` | Get env with default | `port=$(trove_get_env "PORT" "8080")` |

### Essential Date Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `trove_timestamp_iso` | ISO 8601 timestamp | `ts=$(trove_timestamp_iso)` |
| `trove_date_today` | Today's date (YYYY-MM-DD) | `date=$(trove_date_today)` |
| `trove_date_days_ago N` | Date N days ago | `last_week=$(trove_date_days_ago 7)` |
| `trove_duration_format SECS` | Format duration | `$(trove_duration_format 3665)` → "1h 1m 5s" |
| `trove_file_age_days "/path"` | File age in days | `age=$(trove_file_age_days "$log")` |

### Essential Monitoring Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `trove_get_disk_usage "/path"` | Disk usage percentage | `usage=$(trove_get_disk_usage "/")` |
| `trove_get_memory_usage` | Memory usage percentage | `mem=$(trove_get_memory_usage)` |
| `trove_get_cpu_load` | 1-minute load average | `load=$(trove_get_cpu_load)` |
| `trove_send_metric "name" "val"` | Send metric | `trove_send_metric "requests" "1234"` |

---

## Configuration

### Environment Variables

Set these before sourcing Trove libraries or using `klog`:

```bash
# Log level filtering (default: INFO)
export TROVE_LOG_LEVEL="DEBUG"

# Color scheme (default: monokai)
export TROVE_COLORSCHEME="nord"

# Show command output (default: true)
export TROVE_OUTPUT_DISPLAY="true"

# Enable monitoring (default: false)
export TROVE_MONITORING_ENABLED="true"
export TROVE_MONITORING_URL="https://beszel.example.com"
```

### Runtime Configuration

```bash
# Change settings during script execution
trove_set_log_level "ERROR"
trove_set_colorscheme "dracula"
trove_set_output_display false
```

---

## Integration Examples

### Example 1: Installation Script

```bash
#!/usr/bin/env zsh
source /opt/trove/lib/trove_logging.zsh
source /opt/trove/lib/trove_helpers.zsh

trove_bot "MyApp Installation"

# Check if running as root
if ! trove_is_root; then
    trove_log ERROR "This script must be run as root"
    exit 1
fi

# Detect platform
if trove_is_macos; then
    trove_running "Installing on macOS"
    trove_silent_run "brew install myapp" "Installing" INFO
elif trove_is_ubuntu; then
    trove_running "Installing on Ubuntu"
    trove_silent_run "apt-get install -y myapp" "Installing" INFO
else
    trove_log ERROR "Unsupported platform: $(trove_get_platform)"
    exit 1
fi

trove_ok "Installation complete"
```

### Example 2: Backup Script with Monitoring

```bash
#!/usr/bin/env zsh
source /opt/trove/lib/trove_logging.zsh
source /opt/trove/lib/trove_helpers.zsh
source /opt/trove/lib/trove_date.zsh
source /opt/trove/lib/trove_monitoring.zsh

BACKUP_DIR="/backups"
SOURCE_DIR="/data"

trove_bot "Backup System"

# Validate paths
trove_ensure_directory "$BACKUP_DIR"
if ! trove_path_exists "$SOURCE_DIR"; then
    trove_log ERROR "Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Create timestamped backup
timestamp=$(trove_timestamp_format "%Y%m%d-%H%M%S")
backup_file="$BACKUP_DIR/backup-$timestamp.tar.gz"

trove_running "Creating backup"
start=$(trove_timestamp_unix)

if tar -czf "$backup_file" -C "$SOURCE_DIR" .; then
    end=$(trove_timestamp_unix)
    duration=$(trove_duration_seconds $start $end)

    trove_ok "Backup created: $backup_file"
    trove_log INFO "Duration: $(trove_duration_format $duration)"

    # Send metrics
    trove_send_metric "backup_duration" "$duration" "seconds"
    trove_send_metric "backup_success" "1" "bool"
else
    trove_log ERROR "Backup failed"
    trove_send_metric "backup_success" "0" "bool"
    exit 1
fi

# Clean old backups (keep 7 days)
trove_running "Cleaning old backups"
find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime +7 -delete
trove_ok "Old backups cleaned"
```

### Example 3: Health Check Script

```bash
#!/usr/bin/env zsh
source /opt/trove/lib/trove_logging.zsh
source /opt/trove/lib/trove_monitoring.zsh

# Get all metrics
disk=$(trove_get_disk_usage "/")
memory=$(trove_get_memory_usage)
cpu=$(trove_get_cpu_load)
uptime=$(trove_get_uptime_human)

trove_bot "System Health Check"
trove_log INFO "Disk usage: ${disk}%"
trove_log INFO "Memory usage: ${memory}%"
trove_log INFO "CPU load: $cpu"
trove_log INFO "Uptime: $uptime"

# Alert on high usage
if [[ $disk -gt 90 ]]; then
    trove_log ERROR "Disk usage critical: ${disk}%"
    exit 1
fi

if [[ $memory -gt 90 ]]; then
    trove_log WARN "Memory usage high: ${memory}%"
fi

trove_ok "Health check passed"
```

---

## Tips for AI Agents

1. **Always source libraries first** - Before calling any Trove functions
2. **Check command existence** - Use `trove_command_exists` before running external commands
3. **Validate paths** - Use `trove_path_exists` and permission checkers before file operations
4. **Use appropriate log levels** - DEBUG for verbose, INFO for normal, ERROR for failures
5. **Prefer `trove_silent_run`** - Instead of running commands directly (better logging)
6. **Set color schemes** - Match the user's preference (check config or ask)
7. **Use `klog` for binaries** - When working with compiled applications
8. **Measure durations** - Use date utilities for timing operations
9. **Handle errors properly** - Log errors and return appropriate exit codes

---

## Complete API Documentation

For the full function reference, see:
- **[docs/API.md](docs/API.md)** - Complete API documentation with all functions
- **[README.md](README.md)** - Project overview and installation
- **[examples/](examples/)** - More usage examples

---

## Library Files

Source these in your shell scripts:

- `/opt/trove/lib/trove_logging.zsh` - Logging functions
- `/opt/trove/lib/trove_colors.zsh` - Color scheme management
- `/opt/trove/lib/trove_helpers.zsh` - Path and system utilities
- `/opt/trove/lib/trove_monitoring.zsh` - System monitoring functions
- `/opt/trove/lib/trove_date.zsh` - Date and time utilities

---

**Version**: 0.1.0-beta
**Maintained by**: The Secret Lab
**Part of**: kuzcotopia ecosystem
