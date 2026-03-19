#!/usr/bin/env zsh
# Example: Basic Logging with Trove
# Demonstrates how to use Trove logging functions in a shell script

# Source the Trove logging library
source /opt/trove/lib/trove_logging.zsh

# Set log level (optional, defaults to INFO)
export TROVE_LOG_LEVEL="DEBUG"

# Example 1: Level-based logging
echo "=== Example 1: Level-based Logging ==="
trove_log TRACE "This is a trace message (very detailed)"
trove_log DEBUG "This is a debug message (detailed)"
trove_log INFO "This is an info message (normal)"
trove_log WARN "This is a warning message"
trove_log ERROR "This is an error message"
trove_log FATAL "This is a fatal error message"
echo ""

# Example 2: Specialized output functions
echo "=== Example 2: Specialized Functions ==="
trove_bot "Installing Application"
trove_running "Checking prerequisites"
trove_running "Downloading packages"
trove_running "Installing dependencies"
trove_ok "Installation complete"
echo ""

# Example 3: User input headers
echo "=== Example 3: Action Headers ==="
trove_action "User Configuration"
echo "  (This is where you would prompt for input)"
trove_ok "Configuration accepted"
echo ""

# Example 4: Silent run (executing commands)
echo "=== Example 4: Silent Run ==="
trove_silent_run "ls /opt/trove" "Listing Trove directory" DEBUG
echo ""

# Example 5: Changing log level dynamically
echo "=== Example 5: Dynamic Log Level ==="
trove_set_log_level "ERROR"
trove_log INFO "This won't be shown (log level is ERROR)"
trove_log ERROR "This will be shown"
trove_set_log_level "INFO"  # Reset
echo ""

echo "=== All examples complete ==="
