#!/usr/bin/env zsh
# Trove Initialization - Auto-loaded on shell startup
# Sources core libraries and sets up PATH for immediate availability

###############################################################################
# Installation Directory Detection
###############################################################################
# Detect Trove installation directory from this script's location
TROVE_HOME="${0:A:h:h}"

###############################################################################
# Environment Configuration
###############################################################################
# Set environment defaults (respect existing values)
: ${TROVE_LOG_LEVEL:=INFO}
: ${TROVE_COLORSCHEME:=monokai}
: ${TROVE_OUTPUT_DISPLAY:=true}

###############################################################################
# PATH Setup
###############################################################################
# Add bin to PATH if not already present
if [[ ":$PATH:" != *":${TROVE_HOME}/bin:"* ]]; then
    export PATH="${TROVE_HOME}/bin:$PATH"
fi

###############################################################################
# Core Library Loading
###############################################################################
# Auto-load core library (logging automatically loads colors)
if [[ -f "${TROVE_HOME}/lib/trove_logging.zsh" ]]; then
    source "${TROVE_HOME}/lib/trove_logging.zsh"
fi

###############################################################################
# Optional Library Loader
###############################################################################
# Helper function to load optional libraries on-demand
trove_load() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: trove_load <library>" >&2
        echo "" >&2
        echo "Available libraries:" >&2
        echo "  helpers    - Path validation, permissions, platform detection" >&2
        echo "  monitoring - System metrics for monitoring integrations" >&2
        echo "  date       - Timestamp formatting, date arithmetic" >&2
        echo "  all        - Load all optional libraries" >&2
        return 1
    fi

    case "$1" in
        helpers|helper)
            if [[ -f "${TROVE_HOME}/lib/trove_helpers.zsh" ]]; then
                source "${TROVE_HOME}/lib/trove_helpers.zsh"
            else
                echo "Error: trove_helpers.zsh not found" >&2
                return 1
            fi
            ;;
        monitoring|monitor)
            if [[ -f "${TROVE_HOME}/lib/trove_monitoring.zsh" ]]; then
                source "${TROVE_HOME}/lib/trove_monitoring.zsh"
            else
                echo "Error: trove_monitoring.zsh not found" >&2
                return 1
            fi
            ;;
        date|dates)
            if [[ -f "${TROVE_HOME}/lib/trove_date.zsh" ]]; then
                source "${TROVE_HOME}/lib/trove_date.zsh"
            else
                echo "Error: trove_date.zsh not found" >&2
                return 1
            fi
            ;;
        all)
            trove_load helpers
            trove_load monitoring
            trove_load date
            ;;
        *)
            echo "Unknown library: $1" >&2
            echo "Available: helpers, monitoring, date, all" >&2
            return 1
            ;;
    esac
}
