

# Trove API Reference

Complete API documentation for Trove v1.0.0

> CLI facades `klog`, `kreq`, and `atlas-env` are **zsh scripts**, not compiled
> binaries.

---

## Table of Contents

- [Atlas Discovery](#atlas-discovery)
- [Logging Functions](#logging-functions)
- [Color Management](#color-management)
- [Helper Utilities](#helper-utilities)
- [Monitoring Functions](#monitoring-functions)
- [Date & Time Utilities](#date--time-utilities)
- [Requirements](#requirements)
- [Configuration](#configuration)

---

## Atlas Discovery

Discovery reader (in `trove_atlas.zsh`, auto-loaded by the core). Resolves
ecosystem paths and instance facts from `/opt/.atlas/registry` (override
`ATLAS_REGISTRY`) with precedence **env → registry → default**. Pure data
reader; works with no `$HOME`, as any user. Contains no `DF_*`/`BESKAR_*`
references — it emits/resolves neutral `ATLAS_*` names only.

#### `trove_atlas_get <key> [default]`
Resolve a key: neutral env override `ATLAS_<UPPERCASE_KEY>` → registry → caller
default. Prints the value (exit 0); prints nothing and returns 1 when unresolved
and no default given.

#### `trove_atlas_require <key>`
Like `get`, but logs FATAL and returns 1 when unresolved. Use for instance facts
that have no safe default (`primary_user`, `config_home`).

#### `trove_atlas_tool <trove|beskar|dotfiles>`
Resolve a tool install path (knows the fixed `/opt/<tool>` default; honors
`TROVE_HOME` for the `trove` tool).

#### `trove_atlas_set <key> <value>` / `trove_atlas_unset <key>`
Write/update or remove a registry key idempotently (creates the store with the
correct mode if missing).

#### `trove_atlas_dump`
Print the whole registry as `key=value` (comments/blank lines omitted).

#### `trove_atlas_sync key=value [key=value ...]`
Rebuild the registry from the provided facts (used by bootstrap/heal).

#### `atlas-env`
CLI facade that emits `export ATLAS_*='value'` lines (POSIX, bash/sh-consumable)
for cron/system contexts:

```sh
eval "$(/opt/trove/bin/atlas-env)"
```

---

## Logging Functions

### Core Logging

#### `trove_log LEVEL "message"`

General-purpose logging with level filtering.

**Levels**: TRACE, DEBUG, INFO, WARN, ERROR, FATAL

**Example**:
```bash
trove_log INFO "Application started"
trove_log ERROR "Connection failed"
trove_log DEBUG "Variable x = $x"
```

**Output**:
- TRACE: Gray ➤
- DEBUG: Cyan ✱
- INFO: Green ✔
- WARN: Yellow ⚠
- ERROR: Red ✖
- FATAL: Purple ‼

#### `trove_error "message"`

Shorthand for `trove_log ERROR "message"`.

#### `trove_set_logging_enabled <true|false>`

Enable or disable **all** Trove output (honors `TROVE_ENABLE_LOGGING`). Setting
`false` silences `trove_log` and every specialized output function.

---

### Specialized Output

#### `trove_bot "message"`

Announce major tasks or sections (bold purple ✪).

**Example**:
```bash
trove_bot "Installing System Packages"
```

#### `trove_running "message"`

Log configuration steps (orange ✨).

**Example**:
```bash
trove_running "Configuring database"
trove_running "Setting up SSL certificates"
```

#### `trove_action "message"`

Full-width header for user input sections (green background).

**Example**:
```bash
trove_action "User Configuration"
```

#### `trove_ok "message"`

Success confirmation (green ➤).

**Example**:
```bash
trove_ok "Installation complete"
trove_ok "Configuration validated"
```

---

### Command Execution

#### `trove_silent_run "command" "message" [LEVEL]`

Execute a command and log the result.

**Parameters**:
- `command`: Command to execute
- `message`: Log message
- `LEVEL`: Optional log level (default: DEBUG)

**Example**:
```bash
trove_silent_run "apt-get update" "Updating package list" INFO
trove_silent_run "brew install git" "Installing git" INFO
```

**Returns**: Command's exit code

---

### Result Printing

#### `trove_print_success "message"`

Print success message (green ✔).

#### `trove_print_error "message"`

Print error message (red ✖).

#### `trove_print_result EXIT_CODE "message"`

Print result based on exit code.

**Example**:
```bash
command_that_might_fail
trove_print_result $? "Command execution"
```

---

### Configuration Functions

#### `trove_set_log_level LEVEL`

Change log level at runtime.

**Example**:
```bash
trove_set_log_level DEBUG
trove_set_log_level ERROR
```

#### `trove_get_log_level`

Get current log level.

**Example**:
```bash
current_level=$(trove_get_log_level)
echo "Current log level: $current_level"
```

#### `trove_set_output_display true|false`

Enable/disable command output display.

**Example**:
```bash
trove_set_output_display false  # Suppress output
trove_silent_run "noisy-command" "Running silently"
trove_set_output_display true   # Re-enable
```

---

## Color Management

### `trove_set_colorscheme SCHEME`

Set the color scheme.

**Available schemes**: monokai, solarized, nord, dracula, gruvbox

**Example**:
```bash
trove_set_colorscheme nord
trove_set_colorscheme dracula
```

### `trove_show_colorschemes`

Display all available color schemes with samples.

**Example**:
```bash
trove_show_colorschemes
```

### `trove_get_colorscheme`

Get current color scheme name.

**Example**:
```bash
scheme=$(trove_get_colorscheme)
echo "Current scheme: $scheme"
```

---

## Helper Utilities

### Path Validation

#### `trove_path_exists "/path"`

Check if path exists.

**Returns**: 0 if exists, 1 if not

**Example**:
```bash
if trove_path_exists "/opt/trove"; then
    echo "Trove is installed"
fi
```

#### `trove_is_directory "/path"`

Check if path is a directory.

#### `trove_is_file "/path"`

Check if path is a file.

#### `trove_is_symlink "/path"`

Check if path is a symlink.

#### `trove_ensure_directory "/path"`

Create directory if it doesn't exist.

**Example**:
```bash
trove_ensure_directory "/opt/myapp/config"
```

#### `trove_get_absolute_path "/path"`

Resolve symlinks and get absolute path.

**Example**:
```bash
abs_path=$(trove_get_absolute_path "~/myfile")
```

---

### Permission Checking

#### `trove_is_readable "/path"`

Check if path is readable.

#### `trove_is_writable "/path"`

Check if path is writable.

#### `trove_is_executable "/path"`

Check if path is executable.

#### `trove_is_root`

Check if running as root.

**Example**:
```bash
if trove_is_root; then
    echo "Running as root"
fi
```

#### `trove_is_sudo`

Check if running with sudo.

---

### Platform Detection

#### `trove_get_platform`

Get platform name (darwin, linux, etc.).

**Example**:
```bash
platform=$(trove_get_platform)
```

#### `trove_is_macos`

Check if running on macOS.

**Example**:
```bash
if trove_is_macos; then
    # macOS-specific code
fi
```

#### `trove_is_linux`

Check if running on Linux.

#### `trove_is_ubuntu`

Check if running on Ubuntu.

#### `trove_get_distribution`

Get Linux distribution name.

**Example**:
```bash
distro=$(trove_get_distribution)
```

#### `trove_get_os_version`

Get OS version.

---

### Command Detection

#### `trove_command_exists "command"`

Check if command is available.

**Example**:
```bash
if trove_command_exists "git"; then
    echo "Git is installed"
fi
```

#### `trove_require_command "command" "message"`

Require command or exit with error.

**Example**:
```bash
trove_require_command "git" "Please install git first"
```

#### `trove_get_command_path "command"`

Get full path to command.

---

### Environment Helpers

#### `trove_is_set "VAR_NAME"`

Check if environment variable is set.

**Example**:
```bash
if trove_is_set "HOME"; then
    echo "HOME is set to: $HOME"
fi
```

#### `trove_require_vars "VAR1" "VAR2" ...`

Require multiple environment variables.

**Example**:
```bash
trove_require_vars "HOME" "USER" "PATH"
```

#### `trove_get_env "VAR_NAME" "default"`

Get environment variable with default.

**Example**:
```bash
port=$(trove_get_env "PORT" "8080")
```

---

### String Utilities

#### `trove_trim "text"`

Trim whitespace from string.

#### `trove_lowercase "TEXT"`

Convert to lowercase.

#### `trove_uppercase "text"`

Convert to uppercase.

#### `trove_starts_with "string" "prefix"`

Check if string starts with prefix.

#### `trove_ends_with "string" "suffix"`

Check if string ends with suffix.

---

### User Interaction

#### `trove_ask_yes_no "question" [default]`

Ask yes/no question.

**Example**:
```bash
if trove_ask_yes_no "Continue?" "y"; then
    echo "Continuing..."
fi
```

---

## Monitoring Functions

### System Metrics - Disk

#### `trove_get_disk_usage "/path"`

Get disk usage percentage.

**Returns**: Percentage (e.g., "45")

**Example**:
```bash
usage=$(trove_get_disk_usage "/")
echo "Disk usage: ${usage}%"
```

#### `trove_get_disk_used_gb "/path"`

Get used space in GB.

#### `trove_get_disk_total_gb "/path"`

Get total space in GB.

#### `trove_get_disk_available_gb "/path"`

Get available space in GB.

---

### System Metrics - Memory

#### `trove_get_memory_usage`

Get memory usage percentage.

**Example**:
```bash
mem=$(trove_get_memory_usage)
echo "Memory usage: ${mem}%"
```

#### `trove_get_memory_used_mb`

Get used memory in MB.

#### `trove_get_memory_total_mb`

Get total memory in MB.

---

### System Metrics - CPU

#### `trove_get_cpu_load`

Get 1-minute CPU load average.

**Example**:
```bash
load=$(trove_get_cpu_load)
echo "CPU load: $load"
```

#### `trove_get_cpu_loads`

Get all load averages (1, 5, 15 minutes).

#### `trove_get_cpu_count`

Get number of CPUs.

#### `trove_get_cpu_usage`

Get current CPU usage percentage.

---

### System Metrics - Network

#### `trove_get_hostname`

Get full hostname.

#### `trove_get_hostname_short`

Get short hostname (no domain).

#### `trove_get_ip_address`

Get primary IP address.

---

### System Metrics - Process

#### `trove_get_process_count`

Get number of running processes.

#### `trove_get_uptime_seconds`

Get system uptime in seconds.

#### `trove_get_uptime_human`

Get uptime in human-readable format.

---

### Monitoring Integration

#### `trove_send_metric "name" "value" ["unit"]`

Send metric to monitoring system.

**Example**:
```bash
export TROVE_MONITORING_ENABLED="true"
export TROVE_MONITORING_URL="https://beszel.example.com"

trove_send_metric "app_requests" "1234" "count"
trove_send_metric "response_time" "45" "ms"
```

#### `trove_send_system_metrics`

Send all system metrics at once.

#### `trove_show_metrics`

Display all system metrics (for debugging).

**Example**:
```bash
trove_show_metrics
```

---

## Date & Time Utilities

### Timestamp Formatting

#### `trove_timestamp_iso`

Get ISO 8601 timestamp (UTC).

**Returns**: "2026-03-18T14:30:00Z"

**Example**:
```bash
timestamp=$(trove_timestamp_iso)
```

#### `trove_timestamp_iso_local`

Get ISO 8601 timestamp (local time with timezone).

#### `trove_timestamp_unix`

Get Unix timestamp (seconds since epoch).

#### `trove_timestamp_format "%Y%m%d_%H%M%S"`

Get custom formatted timestamp.

#### `trove_date_today`

Get today's date (YYYY-MM-DD).

#### `trove_time_now`

Get current time (HH:MM:SS).

---

### Date Arithmetic

#### `trove_date_add_days "2026-03-18" 7`

Add days to a date.

**Returns**: "2026-03-25"

#### `trove_date_sub_days "2026-03-18" 7`

Subtract days from a date.

#### `trove_date_days_ago 7`

Get date N days ago.

#### `trove_date_days_from_now 7`

Get date N days from now.

#### `trove_date_diff "2026-03-11" "2026-03-18"`

Calculate days between two dates.

**Returns**: 7

---

### Duration Calculations

#### `trove_duration_seconds START END`

Calculate duration in seconds.

#### `trove_duration_format SECONDS`

Format seconds to human-readable (e.g., "1h 30m 45s").

#### `trove_duration_hms SECONDS`

Format seconds to HH:MM:SS.

#### `trove_measure_duration "command"`

Measure command execution time.

**Example**:
```bash
duration=$(trove_measure_duration "sleep 2")
echo "Command took $duration seconds"
```

---

### Timezone Handling

#### `trove_get_timezone`

Get current timezone.

#### `trove_get_utc_offset`

Get UTC offset (e.g., "-0400").

#### `trove_convert_timezone "timestamp" "timezone"`

Convert timestamp to specific timezone.

---

### Parsing & Validation

#### `trove_parse_iso "2026-03-18T14:30:00Z"`

Parse ISO timestamp to Unix timestamp.

#### `trove_is_valid_date "2026-03-18"`

Validate date format.

#### `trove_is_valid_timestamp "2026-03-18T14:30:00Z"`

Validate ISO timestamp.

---

### Convenience Functions

#### `trove_start_of_today`

Get Unix timestamp for today at 00:00:00.

#### `trove_end_of_today`

Get Unix timestamp for today at 23:59:59.

#### `trove_file_age_days "/path/to/file"`

Get age of file in days.

#### `trove_is_past TIMESTAMP`

Check if timestamp is in the past.

#### `trove_is_future TIMESTAMP`

Check if timestamp is in the future.

#### `trove_log_timestamp`

Get timestamp for log files (YYYYMMDD-HHMMSS).

#### `trove_log_date`

Get date for log files (YYYY-MM-DD).

---

## Requirements

Load with `trove_load requirements` (sources helpers automatically).

Check-only by default. Install only when `--install` is passed or `trove_requirements_ensure` is used.

### Version Utilities

#### `trove_version_parse "text"`

Extract the first semver-like version from arbitrary text.

#### `trove_version_compare "v1" "op" "v2"`

Compare versions. Operators: `>=`, `>`, `<=`, `<`, `==`, `eq`.

#### `trove_version_satisfies "installed" "constraint"`

Check if installed version satisfies a constraint like `>=2.30.0`.

#### `trove_get_command_version "command" "probe"`

Get version from a command (default probe: `--version`).

### Single Requirement

#### `trove_require_status NAME [options]`

Check one requirement. Returns exit code: `0` ok, `1` missing, `2` outdated, `3` error.

**Options**:
- `--command CMD` — binary to check (default: NAME)
- `--version CONSTRAINT` — version constraint (e.g. `>=2.30.0`)
- `--providers LIST` — comma-separated providers (e.g. `brew,apt`)
- `--version-probe PROBE` — version command args (default: `--version`)
- `--check SCRIPT` — custom check shell snippet
- `--install-cmd SCRIPT` — custom install command

**Example**:
```bash
trove_require_status git --version ">=2.30.0" --providers brew,apt
TROVE_REQUIRE_JSON=1 trove_require_status git --version ">=2.30.0"
```

#### `trove_ensure NAME [options] [--install]`

Check and optionally install a requirement.

```bash
trove_ensure git --providers brew,apt --install
```

### Manifest (Batch)

#### `trove_requirements_check MANIFEST`

Check all entries in a YAML or JSON manifest.

#### `trove_requirements_ensure MANIFEST --install`

Install missing dependencies from a manifest (requires `--install`).

**Manifest example** (`examples/requirements.yaml`):
```yaml
requirements:
  - name: git
    command: git
    version: ">=2.30.0"
    providers:
      - brew: git
      - apt: git
```

### Providers

| Provider | Install hint |
|----------|--------------|
| `brew` | `brew install PACKAGE` |
| `apt` | `sudo apt-get install -y PACKAGE` |
| `snap` | `sudo snap install PACKAGE` |
| `npm` | `npm install -g PACKAGE` |
| `custom` | User-supplied `install` script in manifest |

Set `TROVE_ALLOW_SUDO=1` to allow apt/snap install commands to run. Without it, install hints are reported only.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TROVE_REQUIRE_JSON` | 0 | Emit JSON status on stdout |
| `TROVE_ALLOW_SUDO` | 0 | Allow sudo install commands |

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TROVE_LOG_LEVEL` | INFO | Log level filter (TRACE\|DEBUG\|INFO\|WARN\|ERROR\|FATAL) |
| `TROVE_ENABLE_LOGGING` | true | Master output switch; `false` silences all Trove output |
| `TROVE_OUTPUT_DISPLAY` | true | Show command output in `trove_silent_run` |
| `TROVE_COLORSCHEME` | monokai | Color scheme (monokai\|solarized\|nord\|dracula\|gruvbox) |
| `TROVE_MONITORING_ENABLED` | false | Enable monitoring integration |
| `TROVE_MONITORING_URL` | "" | Monitoring system URL |
| `ATLAS_REGISTRY` | /opt/.atlas/registry | Atlas registry path override (tests/dev) |

### Configuration File

`config/trove.conf` is auto-sourced by `trove_init.zsh` if present. Precedence
is **environment variable > `config/trove.conf` > built-in default** (the file
uses `: ${VAR:=...}` form). Delete it to configure purely by environment.

**Example**:
```zsh
: ${TROVE_LOG_LEVEL:=DEBUG}
: ${TROVE_COLORSCHEME:=nord}
: ${TROVE_MONITORING_ENABLED:=true}
: ${TROVE_MONITORING_URL:=https://monitor.example.internal}
```

---

## CLI Usage (klog)

The `klog` binary provides command-line access to logging functions.

### Syntax

```bash
klog LEVEL "message"
klog COMMAND "message"
```

### Examples

```bash
# Log levels
klog INFO "Application started"
klog ERROR "Connection failed"
klog DEBUG "Debug information"

# Special commands
klog bot "Installing Packages"
klog running "Configuring system"
klog ok "Installation complete"
```

### Help

```bash
klog --help
```

---

## CLI Usage (kreq)

The `kreq` binary checks dependencies from shell scripts, CI, or other languages.

### Syntax

```bash
kreq check NAME [options]
kreq ensure NAME [options] --install
kreq check-file MANIFEST [--json]
kreq ensure-file MANIFEST --install
```

### Examples

```bash
kreq check git --version ">=2.30.0" --json
kreq ensure node --providers brew,apt --install
kreq check-file ./requirements.yaml --json
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Satisfied |
| 1 | Missing |
| 2 | Outdated |
| 3 | Error |

---

## Integration Examples

### In Shell Scripts

```bash
#!/usr/bin/env zsh
source /opt/trove/lib/trove_logging.zsh
source /opt/trove/lib/trove_helpers.zsh

trove_bot "My Application"

if ! trove_command_exists "git"; then
    trove_log ERROR "Git is required"
    exit 1
fi

trove_running "Cloning repository"
trove_silent_run "git clone https://example.com/repo.git" "Cloning" INFO

trove_ok "Application ready"
```

### From Python

```python
import subprocess

def log(level, message):
    subprocess.run(["/opt/trove/bin/klog", level, message])

log("INFO", "Python application started")
log("ERROR", "Something went wrong")
```

### From Go

```go
package main

import (
    "os/exec"
)

func log(level, message string) {
    exec.Command("/opt/trove/bin/klog", level, message).Run()
}

func main() {
    log("INFO", "Go application started")
}
```

---

## See Also

- [README.md](../README.md) - Overview and quick start
- [Examples](../examples/) - Usage examples
- [Configuration](#configuration) - Configuration details

---

**Version**: 1.0.0
**Last Updated**: 2026-06-16
