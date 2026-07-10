# Changelog

All notable changes to Trove will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **`TROVE_VERSION`** — the root `VERSION` file is now read at runtime in
  `lib/trove_init.zsh` and exported (single source of truth; D002).
- **`DECISIONS.md`** — decision log (`D001`–`D009`) backfilling the standing
  base-tier decisions; **`docs/INDEX.md`** + **`docs/features/INDEX.md`** catalog.
- **Static-gate tools** — `tools/lint-zsh-syntax.sh` (`zsh -n` over `bin/`+`lib/`)
  and `tools/lint-zsh-locals.sh` (combined-`local` footgun gate; D009).

### Changed
- **`CLAUDE.md` is now a symlink to `AGENTS.md`** (D004) — one source of truth,
  replacing the interim markdown stub.

### Fixed
- **Disk-metric helpers were broken by a `$PATH`-shadow footgun.**
  `trove_get_disk_{usage,used_gb,total_gb,available_gb}` declared `local path=…` —
  but `path` is the array tied to `$PATH`, so inside the function `$PATH` collapsed to
  the argument and `df`/`awk`/`sed` were "command not found" (the helpers silently
  returned empty). Renamed the local to `dir`. (`lib/trove_monitoring.zsh`.)

## [1.2.0] - 2026-07-08

### Added
- **Always-on verbose file logging** — a second, independent output sink
  (`lib/trove_logging.zsh`) that always records at full `TRACE` verbosity in plain
  text, timestamped, ANSI-stripped, and secret-scrubbed, regardless of the terminal
  log level and even when `TROVE_ENABLE_LOGGING=false` silences the terminal. Point a
  human or an LLM at these files to troubleshoot.
  - **Per-app, per-actor files:** channel via `TROVE_LOG_APP`; each writer gets its
    own `‹dir›/‹app›-‹euser›-YYYY-MM-DD.log` (effective user) at mode `600` (no
    cross-user sharing/leak, including root/cron write-on-behalf). Every line records
    both the real (`actor=`) and effective (`euid=`) identity.
  - **Location:** `TROVE_LOG_DIR`, else per-user XDG state, else `/var/log/trove/‹app›`
    when running as root.
  - **Retention:** `TROVE_LOG_RETENTION_DAYS` (default 7), pruned on new-day file
    creation and via `klog prune`.
  - **Secret scrubbing:** on by default (`TROVE_LOG_SCRUB`) — masks AWS/GitHub/Slack/
    Google/JWT tokens, `sensitive_key=value`, and URL-embedded credentials.
  - **Formats:** `TROVE_LOG_FORMAT=text` (default) or `json`.
- **`trove_log_capture_begin` / `trove_log_capture_end`** — opt-in wrapper capturing a
  region's entire stdout+stderr (including non-Trove output) to the file, live-tee'd to
  the terminal and fully drained before returning (fixes the classic lost-tail bug via a
  FIFO + waitable background writer).
- **New public API:** `trove_log_file_path`, `trove_log_dir`, `trove_log_prune`,
  `trove_log_tail`, `trove_scrub`.
- **`trove_git`** (`lib/trove_helpers.zsh`) — run git through Trove so git/git-crypt
  activity is logged and scrubbed (operations only; never decrypted content).
- **`klog` subcommands:** `--app NAME`, `path`, `tail [N]`, `prune`, `init`.
- **New config keys** in `config/trove.conf`: `TROVE_FILE_LOGGING`, `TROVE_LOG_APP`,
  `TROVE_LOG_DIR`, `TROVE_LOG_FILE_LEVEL`, `TROVE_LOG_RETENTION_DAYS`,
  `TROVE_LOG_FORMAT`, `TROVE_LOG_SCRUB`, `TROVE_LOG_SCRUB_PATTERNS`,
  `TROVE_LOG_CAPTURE_TEE`.
- **Reusable review agents** (`.claude/agents/`): `architecture-review`,
  `docs-parity-review`.
- **`docs/migrations/1.2.0.md`** — migration notes + a paste-in agent prompt for
  downstream apps (dotFiles, Beskar) to self-adapt.

### Changed
- **`trove_silent_run`**: with `TROVE_OUTPUT_DISPLAY=false`, suppressed command output
  is now **captured to the file sink** instead of `/dev/null`. Display-on behavior is
  unchanged (native, live, separated streams).
- **`TROVE_ENABLE_LOGGING=false`** now silences only the terminal; the file sink keeps
  recording (disable it with `TROVE_FILE_LOGGING=false`).
- `docs/API.md`, `AGENTS.md`, `README.md`, `config/trove.conf` document the file sink
  (README/API version stamps bumped to 1.2.0; the `TROVE_ENABLE_LOGGING` description
  corrected to "silences the terminal only").

### Notes
- Minor release: existing terminal behavior and public-function contracts are preserved.
  See `docs/migrations/1.2.0.md` for the two behavioral changes and the downstream
  checklist. File sink requires zsh ≥ 5.3 (degrades gracefully otherwise).

## [1.1.1] - 2026-07-04

### Added
- **CLI Output Style Guide** — the shared visual language for every CLI built on
  Trove (dotFiles, Beskar, downstream). `docs/cli-style-guide.md` (human guide +
  rationale), `docs/STYLE.md` (terse, gradeable agent rules), and
  `docs/cli-style-guide.html` (visual companion rendering the palette in real
  color). Covers the eight semantic color roles, the glyph vocabulary, structure
  (inline/ruled headers, the leading-space rule, alignment), the full-command
  `#`-comment and first-class source-reference rules, output channels, and color
  integration (the `print -r` materialization gotcha + `trove_set_colorscheme`).
- **`tools/lint-output-style.sh`** — gate for the one mechanical rule (no hardcoded
  color escapes; reference `COL_*`), honoring a repo `.styleignore` and inline
  `# style:allow` opt-outs; scans another checkout via `--root`.

### Changed
- `docs/API.md` — pointer from the Color Management section to the style guide.

## [1.1.0] - 2026-06-24

### Added
- **`trove_ssh_host_from_url`** + **`trove_ssh_verify`** (`lib/trove_helpers.zsh`) — generic
  SSH transport helpers. `host_from_url` parses the git host out of ssh:// / scp-style /
  http(s):// URLs (or a bare host), stripping any port. `verify <host> [user]` answers
  "does our key authenticate?" via `ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new
  -T` and matching the git-host greeting banner (Forgejo/GitHub/GitLab return non-zero even
  on success). Seams: `TROVE_SSH_BIN`, `TROVE_SSH_CONNECT_TIMEOUT`. Consumed by dotFiles'
  SSH-key provisioning. Tests: `tests/test_helpers.zunit`.
- **`trove-skill.md`** — a Claude Code skill documenting Trove's logging, color schemes,
  helpers, date utilities, monitoring, and the `klog`/`kreq` CLIs, plus the discover-don't-
  hardcode loading contract and the repo's architecture rules.

### Changed
- **`trove_git_prefer_ssh` refactored** to use the new `trove_ssh_host_from_url` /
  `trove_ssh_verify` helpers (no behavior change — same verify-before-switch, idempotent flip).

### Fixed
- **`trove_get_absolute_path` / `trove_get_directory`** used `local path=…`, which corrupts
  `$PATH` (zsh ties the `path` var to `$PATH`) and silently broke the `realpath`/`readlink`/
  `dirname` lookups inside them. Renamed the local to `target`.

## [1.0.3] - 2026-06-21

### Changed
- **Identity scrub of historical CHANGELOG entries** — de-identified the remaining
  instance literals in older release notes (replaced with generic placeholders).
  No code change; the whole tracked tree is now free of homelab identity.

## [1.0.2] - 2026-06-20

### Added
- **`spark.sh`** — a `curl … | bash` cold-start installer. Runs as the user
  (escalates only system steps via `sudo`), clones Trove to `/opt/trove`, and runs
  `./install`. Idempotent; refuses the placeholder `SPARK_REPO_BASE`.
- **`trove_git_prefer_ssh <dir>`** (in `trove_helpers`) — opportunistically switch
  a repo's `origin` from http(s):// to ssh:// once the SSH key authenticates;
  leaves it on HTTP otherwise. Pure-zsh match (no `grep` dependency). Seams:
  `TROVE_GIT_BIN`, `TROVE_SSH_BIN`. The installer calls it as a final step.

## [1.0.1] - 2026-06-18

### Fixed
- **`trove_stat_mode` now reports the setuid/setgid/sticky bits** on macOS/BSD.
  The `%Lp` stat format dropped the high bits, so a setgid `2755` dir read back
  as `755` — breaking the helper's own documented contract (`# e.g. "2755"`) and
  making setgid invariants uncheckable by consumers (dotFiles `df_perms`). It now
  reads the full mode (`%p`), masks `& 07777`, and emits it normalized like GNU
  `%a`, so both platforms return identical strings including the special bits.
  Surfaced by dotFiles WS3 (Wave-0b `df_perms`).

## [1.0.0] - 2026-06-16

### Added
- **Atlas discovery** (`lib/trove_atlas.zsh`) — the keystone discovery reader:
  `trove_atlas_get/require/tool/set/unset/dump/sync`. Registry at
  `/opt/.atlas/registry` (override `ATLAS_REGISTRY`), parsed as data, resolution
  order env → registry → default, fail-loud for instance facts. Auto-loaded by
  the core. Contains zero consumer-namespace (`DF_*`/`BESKAR_*`) references.
- **`bin/atlas-env`** — emits neutral `ATLAS_*` export lines for cron/system
  contexts with no `$HOME`; consumable from bash/sh.
- **`trove_error`** — convenience wrapper for `trove_log ERROR`.
- **Portable stat helpers** — `trove_stat_owner`, `trove_stat_group`,
  `trove_stat_mode` (octal), working on macOS + Linux.
- **`trove_set_logging_enabled`** + `TROVE_ENABLE_LOGGING` honored from the
  environment — a real "logging off" state that silences all output functions.
- New test suites `tests/test_atlas.zunit`, `tests/test_atlas_env.zunit`, plus
  Atlas/stat/logging/color coverage in the existing suites.
- `LICENSE` (MIT).

### Changed
- **`trove_silent_run` no longer uses `eval`** — the command string is tokenized
  with `${(Q)${(z)...}}` and executed directly, removing the shell-injection
  surface (embedded command substitution is passed as literal arguments).
- **All five colorschemes export every `COL_*` with `typeset -g`** (previously
  only Monokai did, so the other schemes could be shadowed by a caller's local).
- **Installer slimmed to Trove only** — removed machine provisioning (Xcode,
  Homebrew, default-shell `chsh`, SSH keys, 1Password, Python venv) and the
  legacy central registry. It still ensures Trove's one runtime dependency
  (**zsh**) is installed — a zsh library needs zsh — but nothing else. The
  installer is bash-shebanged so it runs on a box without zsh yet.
- Tests are path-agnostic (honor `TROVE_HOME`); the runner targets the checkout.
- Documentation: `klog`/`kreq`/`atlas-env` documented honestly as zsh scripts
  (not compiled binaries); version strings reconciled; identity references and
  the proprietary license removed in favor of MIT.

### Fixed
- `local path=` footgun in the stat helpers (would shadow zsh's special `path`
  array and break command lookup) — renamed to `target`.

## [0.1.5-beta] - 2026-06-06

### Added
- **`trove_requirements.zsh`** — optional module for dependency checking and opt-in installation via brew, apt, snap, npm, or custom providers
- **`kreq` CLI** — command-line dependency checker for non-shell callers (mirrors `klog`)
- YAML/JSON manifest support with `trove_requirements_check` / `trove_requirements_ensure`
- 23 new tests in `tests/test_requirements.zunit`

## [0.1.4-beta] - 2026-05-30

### Documentation
- **AGENTS.md rewritten** — removed hardcoded `/opt/trove` paths (replaced with `$TROVE_PATH`), removed homelab-specific identity ("<codename> ecosystem", "The Secret Lab"), updated version reference, removed emojis, added architecture rules section (no hardcoding, no homelab identity, graceful degradation), and restructured to match the dotFiles AGENTS.md style. Function reference tables and usage patterns retained.

## [0.1.3-beta] - 2026-04-25

### Added
- Machine prerequisites setup in installer, replacing the bootstrap repo
  - Xcode Command Line Tools check and install (macOS)
  - Homebrew install for macOS (Apple Silicon + Intel) and Linux
  - ZSH install via `brew` or `apt` if missing; offer to set as default shell
  - SSH key generation (ed25519), clipboard copy, and interactive git service setup
  - 1Password CLI install (macOS via Homebrew cask, Ubuntu via APT) with account auth

### Changed
- Installer shebang changed from `#!/usr/bin/env zsh` to `#!/bin/bash` so the
  script runs on a fresh Ubuntu machine before ZSH is installed
- ZSH check changed from a fatal error to an automatic install

## [0.1.2-beta] - 2026-04-25

### Added
- Shared Python virtual environment setup during installation
  - Creates `/opt/<codename>/.venv` as the canonical Python runtime for all dotFiles ecosystem tooling
  - Applies <group> ownership when available
  - Skips silently if venv already exists; warns (non-fatal) if python3 is not installed

## [0.1.1-beta] - 2026-03-22

### Added
- Central application registry system (`/opt/.config/registry/`)
  - Creates registry directory with <group> ownership detection
  - Installs `locations.zsh` library with registry functions (register, lookup, list, remove, verify)
  - Automatically registers Trove during installation
  - Enables cross-tool discovery for dotFiles ecosystem
- Missing `COL_BOLD` color variable

### Fixed
- Bash strict mode compatibility: unbound variable errors for `SUDO_USER` and `COL_RESET`
- Color variable exports now use `typeset -g` for proper global scope

## [0.1.0-beta] - 2024-03-18

### Added
- Initial release of Trove shared utilities library
- Logging system with structured levels (DEBUG, INFO, WARN, ERROR)
- Color schemes (Monokai, Solarized, Nord, Dracula, Gruvbox)
- Helper functions (trove_bot, trove_running, trove_ok)
- Monitoring utilities
- Date/time utilities
- klog binary for logging from non-zsh contexts
- Comprehensive test suite
