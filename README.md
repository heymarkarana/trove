# Trove — Shared Utilities Library

**Version**: 1.0.0

A collection of reusable zsh utilities: structured logging, color schemes,
discovery (Atlas), monitoring helpers, and common path/system helpers. Trove is
the foundation layer other tools build on — it has no dependencies of its own.

---

## Features

- 🧭 **Atlas Discovery** — find where tools and instance config live, from any
  context (cron, systemd, root, another user), without relying on `$HOME`
- 📝 **Structured Logging** — level-filtered logging with colored output
- 🗄️ **Verbose File Logging** — always-on, per-app, secret-scrubbed log files with
  retention; point a human or an LLM at them to troubleshoot (see `docs/API.md`)
- 🎨 **Color Schemes** — Monokai, Solarized, Nord, Dracula, Gruvbox
- 📊 **Monitoring Helpers** — system metrics for monitoring integrations
- 🛠️ **Helpers** — path validation, portable stat, permission checks, platform detection
- 📅 **Date Utilities** — timestamp formatting, date arithmetic, durations
- 🚀 **CLI facades** — `klog` (logging), `kreq` (requirements), `atlas-env` (discovery)

> `klog`, `kreq`, and `atlas-env` are **zsh scripts**, not compiled binaries.
> They are thin CLI facades over the libraries, callable from any language.

---

## Quick Start

### Installation

**From a local checkout** (default install root is `/opt/trove`):

```sh
./install
```

**Cold-start over the network** (`spark.sh` — clones to `/opt/trove`, then runs
`./install`). Run it **as your normal user** (never sudo/root; it escalates only
the system steps). The branch is chosen in **two places that must match** — the
`SPARK_REF` env var (the branch cloned) and the `raw/branch/<branch>/` segment of
the URL (the branch `spark.sh` is fetched from):

```sh
export SPARK_REPO_BASE="http://git.<your-domain>/<user>"   # your git host + namespace

# Production — the released `main` branch:
export SPARK_REF=main
curl -fsSL "$SPARK_REPO_BASE/trove/raw/branch/main/spark.sh" | bash

# Development — the `next` branch (the default if SPARK_REF is unset):
export SPARK_REF=next
curl -fsSL "$SPARK_REPO_BASE/trove/raw/branch/next/spark.sh" | bash
```

`SPARK_REF` accepts a branch **or a release tag** (pin a reproducible install).
Trove is the foundation tier; to install the **full stack** (Trove → Beskar →
dotFiles) in one shot, run dotFiles' `spark.sh` instead — see the dotFiles README.

The installer is bash (so it runs on a box without zsh yet). It ensures Trove's
one runtime dependency — **zsh** — is present (installing it via the platform
package manager if missing), then validates the tree, sets permissions, and
symlinks the CLI facades into a standard bin dir (or tells you how to add them to
`PATH`). Beyond ensuring zsh it does **not** provision the machine: no Homebrew,
Xcode, SSH keys, 1Password, Python venvs, or default-shell (`chsh`) changes —
those belong to bootstrap/dotFiles.

### Usage in shell

```zsh
# Source the core (logging + colors + Atlas):
source /opt/trove/lib/trove_init.zsh

trove_log INFO "Starting application"
trove_bot "Major Task"
trove_running "Configuring system"
trove_ok "Configuration complete"
trove_error "Something went wrong"

# Load optional modules on demand:
trove_load helpers
trove_load date
```

### Usage from the CLIs

```sh
klog INFO "Application started"
klog ERROR "Connection failed"
kreq check zsh
eval "$(atlas-env)"        # export ATLAS_* discovery values (cron/system safe)
```

---

## Libraries

| Module | Loaded | Provides |
|---|---|---|
| `trove_logging.zsh` | core (auto) | `trove_log`, `trove_error`, `trove_ok`, `trove_bot`, `trove_running`, `trove_action`, `trove_silent_run`, level + display + on/off config |
| `trove_colors.zsh` | core (auto) | `trove_set_colorscheme`, `trove_get_colorscheme`, `trove_show_colorschemes`, the `COL_*` globals (every scheme exported globally) |
| `trove_atlas.zsh` | core (auto) | `trove_atlas_get/require/tool/set/unset/dump/sync` — discovery reader |
| `trove_helpers.zsh` | `trove_load helpers` | path validation, permission checks, `trove_stat_owner/group/mode`, platform detection, env + string helpers |
| `trove_date.zsh` | `trove_load date` | timestamps, date arithmetic, durations |
| `trove_monitoring.zsh` | `trove_load monitoring` | disk/memory/CPU metrics, metric sender |
| `trove_requirements.zsh` | `trove_load requirements` | dependency checking + version helpers |

---

## Atlas (discovery)

Atlas resolves ecosystem paths and instance facts from a tiny registry at
`/opt/.atlas/registry` (override with `ATLAS_REGISTRY` for tests). Resolution
order is **env → registry → default**; instance facts with no safe default
(`primary_user`, `config_home`) fail loud when unresolved.

```zsh
trove_atlas_get config_home              # env ATLAS_CONFIG_HOME → registry → (none)
trove_atlas_require primary_user         # fail loud if unresolved
trove_atlas_tool beskar                  # resolve a tool install path
trove_atlas_sync primary_user=alice group=devs install_root=/opt/app config_home=/opt/app/.config/dotFiles
```

`atlas-env` emits **neutral** `ATLAS_*` export lines (no consumer-specific
names) so cron/systemd jobs can learn absolute paths with no `$HOME`:

```sh
eval "$(/opt/trove/bin/atlas-env)"
# now $ATLAS_PRIMARY_USER, $ATLAS_INSTALL_ROOT, $ATLAS_CONFIG_HOME, … are set
```

The registry is non-secret discovery data (dir `2755`, file `644`). It is never
committed and never backed up — it is rebuildable on demand via
`trove_atlas_sync`.

---

## Configuration

Trove reads an optional `config/trove.conf` (auto-sourced by `trove_init.zsh`)
and these environment variables. Precedence: **env var > `config/trove.conf` >
built-in default**. Delete `trove.conf` to configure purely by environment.

| Variable | Default | Purpose |
|---|---|---|
| `TROVE_HOME` | script location | Trove install dir (canonical; `TROVE_PATH` is a deprecated read-only alias) |
| `TROVE_LOG_LEVEL` | `INFO` | `TRACE`/`DEBUG`/`INFO`/`WARN`/`ERROR`/`FATAL` |
| `TROVE_COLORSCHEME` | `monokai` | `monokai`/`solarized`/`nord`/`dracula`/`gruvbox` |
| `TROVE_OUTPUT_DISPLAY` | `true` | show command output in `trove_silent_run` |
| `TROVE_ENABLE_LOGGING` | `true` | set `false` to silence **all** Trove output |
| `ATLAS_REGISTRY` | `/opt/.atlas/registry` | registry path override (tests/dev) |

These can also be set at runtime: `trove_set_log_level`, `trove_set_colorscheme`,
`trove_set_output_display`, `trove_set_logging_enabled`.

---

## Testing

Tests use [zunit](https://github.com/zunit-zsh/zunit):

```sh
# Run the whole suite (sets TROVE_HOME to this checkout):
./tests/run_tests.sh

# Run a single suite:
TROVE_HOME="$(pwd)" zunit tests/test_atlas.zunit
```

---

## Dependencies

- **Required**: zsh
- **Optional**: zunit (tests), `flock` (registry write serialization)

---

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Deepcut Labs, LLC.

---

For detailed API documentation, see [docs/API.md](docs/API.md).
