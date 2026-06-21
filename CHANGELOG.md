# Changelog

All notable changes to Trove will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
