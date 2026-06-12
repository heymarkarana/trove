# Changelog

All notable changes to Trove will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.6-beta] - 2026-06-12

### Added
- **`trove-skill.md`** — Claude Code skill documenting Trove's logging, color schemes, helpers, monitoring, date utilities, and the `klog`/`kreq` CLIs.

## [0.1.5-beta] - 2026-06-06

### Added
- **`trove_requirements.zsh`** — optional module for dependency checking and opt-in installation via brew, apt, snap, npm, or custom providers
- **`kreq` CLI** — command-line dependency checker for non-shell callers (mirrors `klog`)
- YAML/JSON manifest support with `trove_requirements_check` / `trove_requirements_ensure`
- 23 new tests in `tests/test_requirements.zunit`

## [0.1.4-beta] - 2026-05-30

### Documentation
- **AGENTS.md rewritten** — removed hardcoded `/opt/trove` paths (replaced with `$TROVE_PATH`), removed homelab-specific identity ("kuzcotopia ecosystem", "The Secret Lab"), updated version reference, removed emojis, added architecture rules section (no hardcoding, no homelab identity, graceful degradation), and restructured to match the dotFiles AGENTS.md style. Function reference tables and usage patterns retained.

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
  - Creates `/opt/kuzcotopia/.venv` as the canonical Python runtime for all dotFiles ecosystem tooling
  - Applies kgroup ownership when available
  - Skips silently if venv already exists; warns (non-fatal) if python3 is not installed

## [0.1.1-beta] - 2026-03-22

### Added
- Central application registry system (`/opt/.config/kapps/`)
  - Creates registry directory with kgroup ownership detection
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
