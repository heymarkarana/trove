# Trove — agent entry

This file is the authoritative context for AI assistants working in this repository. `CLAUDE.md` references this file for Claude Code.

---

## What this repository is

Trove is a **shared shell utilities library** providing consistent logging, color output, **Atlas discovery**, system helpers, date/time utilities, and system monitoring functions for zsh scripts. It also ships CLI facades — `klog` (logging), `kreq` (requirements), and `atlas-env` (discovery exports). These are **zsh scripts, not compiled binaries**; they expose Trove to any language (Python, Go, Rust, etc.).

Trove is a dependency of dotFiles and Beskar — it is installed first during bootstrap (`/opt/trove`) and loaded by `dotFiles/lib/df_bootstrap.zsh` before any install step runs. It owns **Atlas**, the discovery layer all tiers consume.

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
| `lib/trove_atlas.zsh` | Atlas discovery reader (`trove_atlas_*`) |
| `lib/trove_init.zsh` | Core initialization (auto-loads logging + colors + Atlas) |
| `bin/klog` | CLI logging facade (zsh script) for non-shell callers |
| `bin/kreq` | CLI requirements facade (zsh script) for non-shell callers |
| `bin/atlas-env` | Emits neutral `ATLAS_*` discovery exports (cron/system safe) |
| `tests/` | Test suite (zunit) — run with `bash tests/run_tests.sh` |
| `examples/` | Usage examples |
| `docs/API.md` | Full function reference |

---

## Architecture rules — must follow

### 1. Nothing hardcoded — discover via Atlas

`TROVE_HOME` is the canonical variable for Trove's own location (`TROVE_PATH` is
accepted as a deprecated read-only alias; never write it). Everything else —
other tools, instance facts — resolves through **Atlas**, never hardcoded paths
and never `$HOME`-derived:

```zsh
trove_atlas_tool beskar          # resolve a tool install path
trove_atlas_require primary_user # resolve an instance fact (fail loud if absent)
eval "$(atlas-env)"              # in cron/system contexts with no $HOME
```

```zsh
# Wrong
source /opt/trove/lib/trove_logging.zsh

# Right
source "${TROVE_HOME}/lib/trove_init.zsh"
```

Atlas itself stays tier-pure: **no `DF_*` or `BESKAR_*` references** in
`trove_atlas.zsh` or `bin/atlas-env` — they emit/resolve neutral `ATLAS_*`
names only; each consumer maps them to its own namespace.

### 2. No homelab identity in code

Names specific to any user's environment (codenames, hostnames, usernames, domains, etc.) must not appear in Trove source. Trove is a generic library — it has no knowledge of the environment it is installed in.

### 3. Trove must degrade gracefully

Trove is loaded before the full dotFiles environment is available. It must not assume `df.env` is sourced, Beskar is available, or zsh is the login shell. Keep dependencies to: zsh, standard POSIX tools, and optionally `klog` for the monitoring module.

---

## Loading Trove

Always load via `df_bootstrap` when working in dotFiles scripts:

```zsh
source "${DF_HOME}/lib/df_bootstrap.zsh" && df_bootstrap
# TROVE_HOME is now set; trove_log and friends are available
```

For standalone scripts outside dotFiles, source the minimum needed:

```zsh
source "${TROVE_HOME}/lib/trove_logging.zsh"
# Optionally add helpers, date, monitoring as needed
```

---

## Key functions reference

### Logging (`trove_logging.zsh`)

| Function | Purpose |
|---|---|
| `trove_log LEVEL "msg"` | Level-filtered log — levels: TRACE DEBUG INFO WARN ERROR FATAL |
| `trove_error "msg"` | Shorthand for `trove_log ERROR` |
| `trove_bot "msg"` | Major section header |
| `trove_running "msg"` | In-progress step indicator |
| `trove_ok "msg"` | Success confirmation |
| `trove_action "msg"` | User-input section header |
| `trove_silent_run "cmd" "label"` | Execute command (no `eval`), log result; suppressed output is captured to the file sink |
| `trove_set_logging_enabled false` | Silence the TERMINAL (`TROVE_ENABLE_LOGGING`); the file sink keeps recording |

#### Verbose file sink (always-on, v1.2.0+)

A second sink writes a plain-text, timestamped, secret-scrubbed log **all the time**
at full TRACE verbosity — independent of the terminal level and of
`TROVE_ENABLE_LOGGING`. Per-app, per-actor files
(`‹dir›/‹app›-‹user›-YYYY-MM-DD.log`, mode `600`); 7-day retention (configurable).

| Function / CLI | Purpose |
|---|---|
| `TROVE_LOG_APP=beskar` | Select the channel (per app). Set in the app's own env/config |
| `klog --app beskar INFO "msg"` | Log to the beskar channel from any language |
| `klog --app beskar path` | Print the log file path (point an LLM/human here) |
| `klog --app beskar tail [N]` / `prune` / `init` | Tail / apply retention / pre-create dir |
| `trove_log_capture_begin` / `_end` | Capture ALL stdout+stderr of a region (opt-in) |
| `trove_git …` | Run git through Trove so git/git-crypt activity is logged (scrubbed) |

Key env vars: `TROVE_FILE_LOGGING`, `TROVE_LOG_DIR`, `TROVE_LOG_FILE_LEVEL`,
`TROVE_LOG_RETENTION_DAYS`, `TROVE_LOG_FORMAT` (text|json), `TROVE_LOG_SCRUB`. See
`docs/API.md` (Verbose File Sink) and `docs/migrations/1.2.0.md`.

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
| `trove_stat_owner` / `trove_stat_group` / `trove_stat_mode` | Portable owner/group/octal-mode (macOS + Linux) |

### Atlas discovery (`trove_atlas.zsh`, core)

| Function | Purpose |
|---|---|
| `trove_atlas_get <key> [default]` | Resolve env → registry → default |
| `trove_atlas_require <key>` | Resolve or fail loud (instance facts) |
| `trove_atlas_tool <trove\|beskar\|dotfiles>` | Resolve a tool install path |
| `trove_atlas_set/unset <key> [val]` | Mutate the registry idempotently |
| `trove_atlas_dump` / `trove_atlas_sync k=v…` | Print / rebuild the registry |

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

### `klog` facade (zsh script, not a compiled binary)

For logging from non-shell programs:

```zsh
"${TROVE_HOME}/bin/klog" INFO  "message"
"${TROVE_HOME}/bin/klog" ERROR "message"
```

Resolve the path via `$TROVE_HOME` (or a `klog` on `PATH`) — never hardcode it.

---

## Common usage patterns

### Installation script

```zsh
#!/usr/bin/env zsh
source "${TROVE_HOME}/lib/trove_logging.zsh"
source "${TROVE_HOME}/lib/trove_helpers.zsh"

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

> In real code, resolve `klog` from `$TROVE_HOME` or `PATH` — don't hardcode the
> path. The literals below are illustrative only.

### Logging from Python

```python
import os, subprocess

KLOG = os.path.join(os.environ.get("TROVE_HOME", "/opt/trove"), "bin", "klog")

def klog(level, message):
    subprocess.run([KLOG, level, message])

klog("INFO", "Application started")
klog("ERROR", "Connection failed")
```

### Logging from Go

```go
import (
    "os"
    "os/exec"
    "path/filepath"
)

func klog(level, message string) {
    home := os.Getenv("TROVE_HOME")
    if home == "" {
        home = "/opt/trove"
    }
    exec.Command(filepath.Join(home, "bin", "klog"), level, message).Run()
}
```

---

## Configuration

Trove reads an optional `config/trove.conf` (auto-sourced by `trove_init.zsh`)
plus these environment variables. Precedence: **env var > `config/trove.conf` >
built-in default**.

```zsh
export TROVE_LOG_LEVEL="INFO"        # TRACE DEBUG INFO WARN ERROR FATAL
export TROVE_COLORSCHEME="monokai"   # monokai solarized nord dracula gruvbox
export TROVE_OUTPUT_DISPLAY="true"   # show command output in trove_silent_run
export TROVE_ENABLE_LOGGING="true"   # set false to silence ALL Trove output
export ATLAS_REGISTRY="/opt/.atlas/registry"   # registry path override (tests/dev)
```

---

## Development expectations

- Run `bash tests/run_tests.sh` before finishing any change to lib functions.
- Trove must work on both macOS and Ubuntu — test platform-specific branches.
- No zsh-only syntax in code paths that run before zsh is guaranteed to be available.
- **No commits without explicit user direction.**
