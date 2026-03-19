# Trove - Shared Utilities Library

**Version**: 0.1.0-beta

A collection of reusable shell utilities for the kuzcotopia ecosystem. Trove provides logging, color schemes, monitoring helpers, and common utilities that can be used across multiple applications.

---

## Features

- 🎨 **Color Schemes** - Multiple themes (Monokai, Solarized, Nord, Dracula)
- 📝 **Structured Logging** - Level-filtered logging with colored output
- 📊 **Monitoring Helpers** - System metrics for Beszel, Arcane, etc.
- 🛠️ **Path Utilities** - Validation, permission checking, directory helpers
- 📅 **Date Utilities** - Timestamp formatting, date arithmetic, timezone helpers
- 🚀 **CLI Binary** - `klog` executable for compiled applications

---

## Quick Start

### Installation

```bash
# Clone or download to /opt/trove
cd /opt/trove
./install

# Add to PATH (optional)
export PATH="/opt/trove/bin:$PATH"
```

### Usage in Shell Scripts

```bash
#!/bin/bash
# Source the libraries
source /opt/trove/lib/trove_logging.zsh
source /opt/trove/lib/trove_colors.zsh

# Set color scheme
trove_set_colorscheme monokai

# Use logging functions
trove_log INFO "Starting application"
trove_bot "Major Task"
trove_running "Configuring system"
trove_ok "Configuration complete"
```

### Usage from Binaries

```bash
# From any compiled application (Go, Rust, Python, etc.)
/opt/trove/bin/klog INFO "Application started"
/opt/trove/bin/klog ERROR "Connection failed"

# Or add to PATH
klog WARN "Low disk space detected"
```

---

## Libraries

### trove_logging.zsh
Structured logging with multiple output functions:
- `trove_log LEVEL "message"` - Level-filtered logging
- `trove_bot "message"` - Major section headers
- `trove_running "message"` - Configuration steps
- `trove_action "message"` - User input headers
- `trove_ok "message"` - Success confirmations
- `trove_silent_run "cmd" "msg"` - Execute and log

### trove_colors.zsh
Color management with multiple schemes:
- Monokai (default)
- Solarized Dark/Light
- Nord
- Dracula
- Gruvbox

### trove_helpers.zsh
Path and system utilities:
- Path validation and permission checking
- Directory operations
- Platform detection
- Environment helpers

### trove_monitoring.zsh
System metrics for monitoring integrations:
- Disk usage
- Memory usage
- CPU load
- Generic metric sender

### trove_date.zsh
Date and time utilities:
- Timestamp formatting
- Date arithmetic
- Timezone handling
- Duration calculations

---

## Configuration

Edit `/opt/trove/config/trove.conf`:

```bash
TROVE_LOG_LEVEL="INFO"           # TRACE|DEBUG|INFO|WARN|ERROR|FATAL
TROVE_COLORSCHEME="monokai"      # monokai|solarized|nord|dracula|gruvbox
TROVE_OUTPUT_DISPLAY="true"      # Show output in terminal
TROVE_MONITORING_ENABLED="false" # Enable monitoring helpers
```

---

## Project Structure

```
/opt/trove/
├── bin/
│   └── klog                 # CLI executable
├── lib/
│   ├── trove_logging.zsh    # Logging functions
│   ├── trove_colors.zsh     # Color schemes
│   ├── trove_helpers.zsh    # Path/system helpers
│   ├── trove_monitoring.zsh # Monitoring utilities
│   └── trove_date.zsh       # Date/time utilities
├── config/
│   └── trove.conf           # Default configuration
├── tests/
│   └── *.bats               # Test suite
├── docs/
│   ├── API.md               # Function reference
│   └── COLORSCHEMES.md      # Color scheme guide
├── examples/
│   └── *.sh                 # Usage examples
├── VERSION                  # Semantic version
├── install                  # Installation script
├── LICENSE
└── README.md
```

---

## Testing

```bash
# Run all tests
cd /opt/trove
./tests/run_tests.sh

# Run specific test
bats tests/test_logging.bats
```

---

## Dependencies

- **Required**: zsh (or bash)
- **Optional**: bats (for running tests)

---

## License

Proprietary - The Secret Lab

---

## Version History

**0.1.0-beta** (2026-03-18)
- Initial beta release
- Core logging system
- Color schemes support
- Monitoring helpers
- Path and date utilities
- klog CLI binary

---

For detailed API documentation, see [docs/API.md](docs/API.md)
