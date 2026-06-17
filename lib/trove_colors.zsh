#!/usr/bin/env zsh
# Trove Color Schemes
# Provides multiple color themes for terminal output

###############################################################################
# Color Scheme Management
###############################################################################

# Current color scheme (can be changed via trove_set_colorscheme)
TROVE_CURRENT_COLORSCHEME="${TROVE_COLORSCHEME:-monokai}"

# ANSI escape sequence
ESC_SEQ="\033["

###############################################################################
# Monokai Theme (Default)
###############################################################################
declare -gA TROVE_COLORS_MONOKAI=(
    [RESET]="${ESC_SEQ}39;49;00m"
    [RED]="${ESC_SEQ}38;5;203m"
    [GREEN]="${ESC_SEQ}38;5;114m"
    [YELLOW]="${ESC_SEQ}38;5;220m"
    [ORANGE]="${ESC_SEQ}38;5;215m"
    [PURPLE]="${ESC_SEQ}38;5;141m"
    [BOLD_PURPLE]="\033[1;38;5;141m"
    [BLUE]="${ESC_SEQ}38;5;75m"
    [CYAN]="${ESC_SEQ}38;5;81m"
    [WHITE]="${ESC_SEQ}38;5;253m"
    [BLACK]="${ESC_SEQ}38;5;235m"
    [DARK_GREEN]="${ESC_SEQ}48;5;28m"
    [GRAY]="${ESC_SEQ}38;5;240m"
)

###############################################################################
# Solarized Dark Theme
###############################################################################
declare -gA TROVE_COLORS_SOLARIZED=(
    [RESET]="${ESC_SEQ}39;49;00m"
    [RED]="${ESC_SEQ}38;5;160m"      # base red
    [GREEN]="${ESC_SEQ}38;5;64m"     # base green
    [YELLOW]="${ESC_SEQ}38;5;136m"   # base yellow
    [ORANGE]="${ESC_SEQ}38;5;166m"   # base orange
    [PURPLE]="${ESC_SEQ}38;5;125m"   # base magenta
    [BOLD_PURPLE]="\033[1;38;5;125m"
    [BLUE]="${ESC_SEQ}38;5;33m"      # base blue
    [CYAN]="${ESC_SEQ}38;5;37m"      # base cyan
    [WHITE]="${ESC_SEQ}38;5;254m"    # base3
    [BLACK]="${ESC_SEQ}38;5;235m"    # base03
    [DARK_GREEN]="${ESC_SEQ}48;5;22m"
    [GRAY]="${ESC_SEQ}38;5;240m"
)

###############################################################################
# Nord Theme
###############################################################################
declare -gA TROVE_COLORS_NORD=(
    [RESET]="${ESC_SEQ}39;49;00m"
    [RED]="${ESC_SEQ}38;5;203m"      # nord11 (red)
    [GREEN]="${ESC_SEQ}38;5;108m"    # nord14 (green)
    [YELLOW]="${ESC_SEQ}38;5;222m"   # nord13 (yellow)
    [ORANGE]="${ESC_SEQ}38;5;215m"   # nord12 (orange)
    [PURPLE]="${ESC_SEQ}38;5;140m"   # nord15 (purple)
    [BOLD_PURPLE]="\033[1;38;5;140m"
    [BLUE]="${ESC_SEQ}38;5;110m"     # nord9 (blue)
    [CYAN]="${ESC_SEQ}38;5;109m"     # nord8 (cyan)
    [WHITE]="${ESC_SEQ}38;5;254m"    # nord6 (white)
    [BLACK]="${ESC_SEQ}38;5;237m"    # nord0 (black)
    [DARK_GREEN]="${ESC_SEQ}48;5;22m"
    [GRAY]="${ESC_SEQ}38;5;245m"     # nord3
)

###############################################################################
# Dracula Theme
###############################################################################
declare -gA TROVE_COLORS_DRACULA=(
    [RESET]="${ESC_SEQ}39;49;00m"
    [RED]="${ESC_SEQ}38;5;210m"      # dracula red
    [GREEN]="${ESC_SEQ}38;5;84m"     # dracula green
    [YELLOW]="${ESC_SEQ}38;5;228m"   # dracula yellow
    [ORANGE]="${ESC_SEQ}38;5;215m"   # dracula orange
    [PURPLE]="${ESC_SEQ}38;5;141m"   # dracula purple
    [BOLD_PURPLE]="\033[1;38;5;141m"
    [BLUE]="${ESC_SEQ}38;5;117m"     # dracula blue (cyan-ish)
    [CYAN]="${ESC_SEQ}38;5;159m"     # dracula cyan
    [WHITE]="${ESC_SEQ}38;5;255m"    # dracula foreground
    [BLACK]="${ESC_SEQ}38;5;235m"    # dracula background
    [DARK_GREEN]="${ESC_SEQ}48;5;22m"
    [GRAY]="${ESC_SEQ}38;5;241m"     # dracula comment
)

###############################################################################
# Gruvbox Theme
###############################################################################
declare -gA TROVE_COLORS_GRUVBOX=(
    [RESET]="${ESC_SEQ}39;49;00m"
    [RED]="${ESC_SEQ}38;5;167m"      # gruvbox red
    [GREEN]="${ESC_SEQ}38;5;142m"    # gruvbox green
    [YELLOW]="${ESC_SEQ}38;5;214m"   # gruvbox yellow
    [ORANGE]="${ESC_SEQ}38;5;208m"   # gruvbox orange
    [PURPLE]="${ESC_SEQ}38;5;175m"   # gruvbox purple
    [BOLD_PURPLE]="\033[1;38;5;175m"
    [BLUE]="${ESC_SEQ}38;5;109m"     # gruvbox blue
    [CYAN]="${ESC_SEQ}38;5;108m"     # gruvbox aqua
    [WHITE]="${ESC_SEQ}38;5;223m"    # gruvbox fg
    [BLACK]="${ESC_SEQ}38;5;235m"    # gruvbox bg
    [DARK_GREEN]="${ESC_SEQ}48;5;100m"
    [GRAY]="${ESC_SEQ}38;5;246m"
)

###############################################################################
# Helper Functions
###############################################################################

# Set the color scheme
# Usage: trove_set_colorscheme monokai|solarized|nord|dracula|gruvbox
trove_set_colorscheme() {
    local scheme="$1"

    case "$scheme" in
        monokai)
            TROVE_CURRENT_COLORSCHEME="monokai"
            _trove_load_colorscheme TROVE_COLORS_MONOKAI
            ;;
        solarized)
            TROVE_CURRENT_COLORSCHEME="solarized"
            _trove_load_colorscheme TROVE_COLORS_SOLARIZED
            ;;
        nord)
            TROVE_CURRENT_COLORSCHEME="nord"
            _trove_load_colorscheme TROVE_COLORS_NORD
            ;;
        dracula)
            TROVE_CURRENT_COLORSCHEME="dracula"
            _trove_load_colorscheme TROVE_COLORS_DRACULA
            ;;
        gruvbox)
            TROVE_CURRENT_COLORSCHEME="gruvbox"
            _trove_load_colorscheme TROVE_COLORS_GRUVBOX
            ;;
        *)
            echo "Unknown color scheme: $scheme" >&2
            echo "Available: monokai, solarized, nord, dracula, gruvbox" >&2
            return 1
            ;;
    esac

    return 0
}

# Internal: Load a color scheme into the global COL_* variables.
#
# Every COL_* is declared `typeset -g` so the colors remain visible no matter
# what scope trove_set_colorscheme is called from (a nested function with a
# `local COL_*` in an enclosing frame previously shadowed four of the five
# schemes — only Monokai used `typeset -g`). The keys are copied generically via
# indirect expansion so all schemes are guaranteed identical coverage.
_trove_load_colorscheme() {
    local scheme_name="$1"
    local key

    for key in RESET RED GREEN YELLOW ORANGE PURPLE BOLD_PURPLE \
               BLUE CYAN WHITE BLACK DARK_GREEN GRAY; do
        typeset -g "COL_${key}=${(P)${:-${scheme_name}[$key]}}"
    done

    # Static extras present in every scheme.
    typeset -g COL_BOLD="\033[1m"
    typeset -g COL_SPACE="        "
}

# Show available color schemes with samples
trove_show_colorschemes() {
    echo "Available Color Schemes:"
    echo ""

    local schemes=(monokai solarized nord dracula gruvbox)
    local original_scheme="$TROVE_CURRENT_COLORSCHEME"

    for scheme in "${schemes[@]}"; do
        trove_set_colorscheme "$scheme"
        echo "  ${COL_BOLD_PURPLE}$scheme${COL_RESET}:"
        echo "    ${COL_RED}Red${COL_RESET} ${COL_GREEN}Green${COL_RESET} ${COL_YELLOW}Yellow${COL_RESET} ${COL_ORANGE}Orange${COL_RESET} ${COL_PURPLE}Purple${COL_RESET} ${COL_BLUE}Blue${COL_RESET} ${COL_CYAN}Cyan${COL_RESET}"
        echo ""
    done

    # Restore original scheme
    trove_set_colorscheme "$original_scheme"
}

# Get current color scheme
trove_get_colorscheme() {
    echo "$TROVE_CURRENT_COLORSCHEME"
}

###############################################################################
# Initialization
###############################################################################

# Load default color scheme on source
trove_set_colorscheme "$TROVE_CURRENT_COLORSCHEME"

# Check if being executed directly (for testing)
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    if [[ "$#" -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Trove Color Schemes"
        echo ""
        echo "Usage:"
        echo "  source /opt/trove/lib/trove_colors.zsh"
        echo "  trove_set_colorscheme <scheme>"
        echo "  trove_show_colorschemes"
        echo "  trove_get_colorscheme"
        echo ""
        trove_show_colorschemes
        exit 0
    elif [[ "$1" == "show" ]]; then
        trove_show_colorschemes
        exit 0
    fi
fi
