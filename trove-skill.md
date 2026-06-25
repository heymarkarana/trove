---
name: trove
description: Use Trove's shared shell utilities for logging, color output, path/system helpers, date/time formatting, monitoring metrics, and dependency checking in zsh scripts (or via the klog/kreq CLI binaries from any language). Use when writing or reviewing shell scripts that need structured logging (trove_log, trove_bot, trove_running, trove_ok), platform detection, dependency checks (kreq), or system metrics.
---

# Trove

Trove is a shared shell utilities library (a dependency of dotFiles and
Beskar). It provides structured logging, color schemes, path/system helpers,
date utilities, and monitoring metrics for zsh scripts, plus two standalone
CLI binaries (`klog`, `kreq`) usable from any language.

## Locating Trove — never hardcode `/opt/trove`

Scripts that consume Trove must discover its path, not hardcode it. Search
order:

1. `$DF_TROVE_PATH` (if set)
2. `/opt/trove`
3. `$DF_APP_INSTALL_DIRECTORY/trove`
4. `$HOME/.local/share/trove`

In dotFiles scripts, load Trove via bootstrap instead of sourcing directly:

```zsh
source "${DF_HOME}/lib/df_bootstrap.zsh" && df_bootstrap
# TROVE_PATH is now set; trove_log and friends are available
```

In standalone scripts:

```zsh
source "${TROVE_PATH}/lib/trove_logging.zsh"
# Optionally: trove_colors.zsh, trove_helpers.zsh, trove_date.zsh, trove_monitoring.zsh
```

## Logging (`lib/trove_logging.zsh`)

```zsh
trove_log LEVEL "message"      # TRACE|DEBUG|INFO|WARN|ERROR|FATAL, level-filtered
trove_bot "message"            # major section header (bold)
trove_running "message"        # in-progress step
trove_action "message"         # full-width user-input section header
trove_ok "message"             # success confirmation
trove_silent_run "cmd" "label" [LEVEL]   # run cmd, log result, returns cmd's exit code
trove_print_success "message"
trove_print_error "message"
trove_print_result EXIT_CODE "message"   # prints success/error based on $?

trove_set_log_level LEVEL      # change filter at runtime
trove_get_log_level
trove_set_output_display true|false   # suppress/show command output
```

## Color schemes (`lib/trove_colors.zsh`)

```zsh
trove_set_colorscheme monokai|solarized|nord|dracula|gruvbox
trove_get_colorscheme
trove_show_colorschemes
```

## Helpers (`lib/trove_helpers.zsh`)

Path/permission/platform checks — use these instead of ad-hoc `[[ -e ]]` /
`uname` checks so behavior is consistent across scripts:

```zsh
trove_path_exists "/path"
trove_is_writable "/path"
trove_command_exists "name"
trove_is_macos
trove_is_ubuntu
```

## Dependency checking — `kreq` CLI

```bash
kreq check NAME [--version ">=2.30.0"] [--json]
kreq ensure NAME [--providers brew,apt] --install
kreq check-file MANIFEST [--json]
kreq ensure-file MANIFEST --install
```

| Exit code | Meaning |
|---|---|
| 0 | Satisfied |
| 1 | Missing |
| 2 | Outdated |
| 3 | Error |

## Logging from non-shell languages — `klog` CLI

```bash
klog INFO "Application started"
klog ERROR "Connection failed"
klog bot "Installing Packages"
klog running "Configuring system"
klog ok "Installation complete"
```

```python
import subprocess
subprocess.run(["/opt/trove/bin/klog", "INFO", "Python app started"])
```

```go
exec.Command("/opt/trove/bin/klog", "INFO", "Go app started").Run()
```

## Configuration

Env vars (override `config/trove.conf`):

| Variable | Default | Meaning |
|---|---|---|
| `TROVE_LOG_LEVEL` | `INFO` | TRACE\|DEBUG\|INFO\|WARN\|ERROR\|FATAL |
| `TROVE_COLORSCHEME` | `monokai` | monokai\|solarized\|nord\|dracula\|gruvbox |
| `TROVE_OUTPUT_DISPLAY` | `true` | Show command output in terminal |
| `TROVE_MONITORING_ENABLED` | `false` | Enable monitoring helpers |
| `TROVE_MONITORING_URL` | `""` | Monitoring system URL |

Local overrides go in `config/trove.local.conf` (gitignored).

## Architecture rules — must follow when editing Trove itself

1. **Nothing hardcoded** — no `/opt/trove` literals; use `$TROVE_PATH` / the
   search order above.
2. **No instance identity in code** — homelab codenames, specific hostnames, or
   private domains must never appear in Trove source (it is a publishable repo).
3. **Degrade gracefully** — Trove loads before the full dotFiles environment
   exists. Don't assume `df.env` is sourced, Beskar is available, or that
   zsh is the login shell. Dependencies: zsh, POSIX tools, optionally `klog`.
4. Works on both macOS and Ubuntu — test platform-specific branches
   (`trove_is_macos` / `trove_is_ubuntu`).
5. Run `bash tests/run_tests.sh` before finishing any change to `lib/`.

## Further reading

- Full reference: [README.md](README.md), [docs/API.md](docs/API.md)
- Repo architecture and rules for AI agents: [AGENTS.md](AGENTS.md)
