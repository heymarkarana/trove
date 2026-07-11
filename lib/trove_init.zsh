#!/usr/bin/env zsh
# Trove Initialization - Auto-loaded on shell startup
# Sources core libraries and sets up PATH for immediate availability

###############################################################################
# Installation Directory Detection
###############################################################################
# Detect Trove installation directory from this script's location
TROVE_HOME="${0:A:h:h}"

###############################################################################
# Version
###############################################################################
# Single source of truth: the root VERSION file, read at runtime (never a
# hardcoded literal). Consumers read $TROVE_VERSION; exported so subprocess
# facades (klog/kreq) and other-language callers can read it too.
if [[ -r "${TROVE_HOME}/VERSION" ]]; then
    TROVE_VERSION="$(<"${TROVE_HOME}/VERSION")"
    TROVE_VERSION="${TROVE_VERSION//[[:space:]]/}"
    export TROVE_VERSION
fi

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
# Optional Config File
###############################################################################
# Auto-source config/trove.conf if present, BEFORE the libraries apply their
# defaults. The file uses `: ${VAR:=...}` form, so precedence is:
#   environment variable > config file > built-in default.
if [[ -f "${TROVE_HOME}/config/trove.conf" ]]; then
    source "${TROVE_HOME}/config/trove.conf"
fi

###############################################################################
# Core Library Loading
###############################################################################
# Auto-load core library (logging automatically loads colors)
if [[ -f "${TROVE_HOME}/lib/trove_logging.zsh" ]]; then
    source "${TROVE_HOME}/lib/trove_logging.zsh"
fi

# Auto-load Atlas discovery — every tier depends on it, so it is core (not an
# optional module). Pure reader; safe to source in any context (no $HOME needed).
if [[ -f "${TROVE_HOME}/lib/trove_atlas.zsh" ]]; then
    source "${TROVE_HOME}/lib/trove_atlas.zsh"
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
        echo "  helpers      - Path validation, permissions, platform detection" >&2
        echo "  requirements - Dependency checking and optional installation" >&2
        echo "  monitoring   - System metrics for monitoring integrations" >&2
        echo "  date         - Timestamp formatting, date arithmetic" >&2
        echo "  all          - Load all optional libraries" >&2
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
        requirements|require|req)
            if ! (( ${+functions[trove_command_exists]} )); then
                if [[ -f "${TROVE_HOME}/lib/trove_helpers.zsh" ]]; then
                    source "${TROVE_HOME}/lib/trove_helpers.zsh"
                else
                    echo "Error: trove_helpers.zsh not found (required by requirements)" >&2
                    return 1
                fi
            fi
            if [[ -f "${TROVE_HOME}/lib/trove_requirements.zsh" ]]; then
                source "${TROVE_HOME}/lib/trove_requirements.zsh"
            else
                echo "Error: trove_requirements.zsh not found" >&2
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
            trove_load requirements
            trove_load monitoring
            trove_load date
            ;;
        *)
            echo "Unknown library: $1" >&2
            echo "Available: helpers, requirements, monitoring, date, all" >&2
            return 1
            ;;
    esac
}
