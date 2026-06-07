# Trove — agent entry

This file is the authoritative context for AI assistants working in this repository. `CLAUDE.md` references this file for Claude Code.

---

## What this repository is

Trove is a **shared shell utilities library** providing consistent logging, color output, system helpers, date/time utilities, and system monitoring functions for zsh scripts. It also ships `klog`, a CLI binary that exposes Trove logging to any language (Python, Go, Rust, etc.).

Trove is a dependency of dotFiles and Beskar — it is installed first during bootstrap (`/opt/trove`) and loaded by `dotFiles/lib/df_bootstrap.zsh` before any install step runs.

---

## Documentation map

| Path | Contents |
|---|---|
| `lib/trove_logging.zsh` | Core logging functions (`trove_log`, `trove_running`, `trove_ok`, etc.) |
| `lib/trove_colors.zsh` | Color scheme management |
| `lib/trove_helpers.zsh` | Path, permission, system, and CLI utilities |
| `lib/trove_date.zsh` | Date/time formatting and arithmetic |
| `lib/trove_monitoring.zsh` | CPU, memory, disk metrics |
| `lib/trove_requirements.zsh` | Dependency checking and optional installation |
| `lib/trove_init.zsh` | Library initialization |
| `bin/klog` | CLI logging binary for non-shell callers |
| `bin/kreq` | CLI requirements checker for non-shell callers |
| `config/` | Default and local config |
| `tests/` | Test suite — run with `bash tests/run_tests.sh` |
| `examples/` | Usage examples |
| `docs/API.md` | Full function reference |

---

## Architecture rules — must follow

### 1. Nothing hardcoded

Do not hardcode `/opt/trove` in scripts that consume Trove. Use `$TROVE_PATH` (set by `df_bootstrap`) or discover it via the standard search order:

1. `$DF_TROVE_PATH` (if set)
2. `/opt/trove`
3. `$DF_APP_INSTALL_DIRECTORY/trove`
4. `$HOME/.local/share/trove`

```zsh
# Wrong
source /opt/trove/lib/trove_logging.zsh

# Right (when called from dotFiles context)
source "${TROVE_PATH}/lib/trove_logging.zsh"
```

### 2. No homelab identity in code

Names specific to any user's environment (`kuzcotopia`, `thesecretlab`, specific hostnames, etc.) must not appear in Trove source. Trove is a generic library — it has no knowledge of the environment it is installed in.

### 3. Trove must degrade gracefully

Trove is loaded before the full dotFiles environment is available. It must not assume `df.env` is sourced, Beskar is available, or zsh is the login shell. Keep dependencies to: zsh, standard POSIX tools, and optionally `klog` for the monitoring module.

---

## Loading Trove

Always load via `df_bootstrap` when working in dotFiles scripts:

```zsh
source "${DF_HOME}/lib/df_bootstrap.zsh" && df_bootstrap
# TROVE_PATH is now set; trove_log and friends are available
```

For standalone scripts outside dotFiles, source the minimum needed:

```zsh
source "${TROVE_PATH}/lib/trove_logging.zsh"
# Optionally add helpers, date, monitoring as needed
```

---

## Key functions reference

### Logging (`trove_logging.zsh`)

| Function | Purpose |
|---|---|
| `trove_log LEVEL "msg"` | Level-filtered log — levels: TRACE DEBUG INFO WARN ERROR FATAL |
| `trove_bot "msg"` | Major section header |
| `trove_running "msg"` | In-progress step indicator |
| `trove_ok "msg"` | Success confirmation |
| `trove_action "msg"` | User-input section header |
| `trove_silent_run "cmd" "label"` | Execute command, log result |

### Helpers (`trove_helpers.zsh`)

| Function | Purpose |
|---|---|
| `trove_path_exists "/path"` | Check if path exists |
| `trove_is_writable "/path"` | Check write permission |
| `trove_command_exists "cmd"` | Check if command is on PATH |
| `trove_ensure_directory "/path"` | Create directory if missing |
| `trove_get_env "VAR" "default"` | Read env var with fallback |
| `trove_is_root` | True if running as root |
| `trove_is_macos` / `trove_is_ubuntu` | Platform detection |

### Requirements (`trove_requirements.zsh`)

Load with `trove_load requirements`.

| Function | Purpose |
|---|---|
| `trove_require_status NAME [opts]` | Check dependency (check-only) |
| `trove_ensure NAME [opts] --install` | Check and optionally install |
| `trove_requirements_check MANIFEST` | Batch check from YAML/JSON |
| `trove_requirements_ensure MANIFEST --install` | Batch install from manifest |
| `trove_version_compare` / `trove_version_satisfies` | Version constraint helpers |

Providers: `brew`, `apt`, `snap`, `npm`, `custom`. See `examples/requirements.yaml`.

### Date/time (`trove_date.zsh`)

| Function | Purpose |
|---|---|
| `trove_timestamp_iso` | ISO 8601 timestamp |
| `trove_timestamp_unix` | Unix epoch seconds |
| `trove_date_today` | YYYY-MM-DD |
| `trove_date_days_ago N` | Date N days in the past |
| `trove_date_days_from_now N` | Date N days in the future |
| `trove_duration_format SECS` | Human-readable duration ("1h 2m 3s") |
| `trove_file_age_days "/path"` | File age in days |

### Monitoring (`trove_monitoring.zsh`)

| Function | Purpose |
|---|---|
| `trove_get_disk_usage "/path"` | Disk usage percentage |
| `trove_get_memory_usage` | Memory usage percentage |
| `trove_get_cpu_load` | 1-minute load average |
| `trove_get_uptime_human` | Human-readable uptime |
| `trove_send_metric "name" "val"` | Send metric to configured endpoint |
| `trove_send_system_metrics` | Send all system metrics at once |

### Colors (`trove_colors.zsh`)

```zsh
trove_set_colorscheme "monokai"   # monokai (default), solarized, nord, dracula, gruvbox
trove_set_log_level "DEBUG"
trove_set_output_display false
```

### `klog` binary

For logging from non-shell programs:

```zsh
/opt/trove/bin/klog INFO  "message"
/opt/trove/bin/klog ERROR "message"
```

Or via `$TROVE_PATH/bin/klog` — never hardcode the path.

---

## Common usage patterns

### Installation script

```zsh
#!/usr/bin/env zsh
source "${TROVE_PATH}/lib/trove_logging.zsh"
source "${TROVE_PATH}/lib/trove_helpers.zsh"

trove_bot "MyApp Installation"

if trove_is_macos; then
    trove_running "Installing on macOS"
    trove_silent_run "brew install myapp" "Installing" INFO
elif trove_is_ubuntu; then
    trove_running "Installing on Ubuntu"
    trove_silent_run "apt-get install -y myapp" "Installing" INFO
else
    trove_log ERROR "Unsupported platform"
    exit 1
fi

trove_ok "Installation complete"
```

### Logging from Python

```python
import subprocess

def klog(level, message):
    subprocess.run(["/opt/trove/bin/klog", level, message])

klog("INFO", "Application started")
klog("ERROR", "Connection failed")
```

### Logging from Go

```go
import "os/exec"

func klog(level, message string) {
    exec.Command("/opt/trove/bin/klog", level, message).Run()
}
```

---

## Configuration

```zsh
export TROVE_LOG_LEVEL="INFO"        # TRACE DEBUG INFO WARN ERROR FATAL
export TROVE_COLORSCHEME="monokai"   # monokai solarized nord dracula gruvbox
export TROVE_OUTPUT_DISPLAY="true"   # show command output
export TROVE_MONITORING_ENABLED="true"
export TROVE_MONITORING_URL="https://monitoring.example.com"
```

Local config overrides go in `config/trove.local.conf` (gitignored).

---

## Development expectations

- Run `bash tests/run_tests.sh` before finishing any change to lib functions.
- Trove must work on both macOS and Ubuntu — test platform-specific branches.
- No zsh-only syntax in code paths that run before zsh is guaranteed to be available.
- **No commits without explicit user direction.**
