# Changelog

All notable changes to Trove will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
