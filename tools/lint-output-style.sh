#!/usr/bin/env zsh
# lint-output-style — gate the one MECHANICAL rule of the CLI output standard:
# consumer code must reference COLOR by role via COL_*, never a hardcoded color
# escape. See docs/STYLE.md and docs/cli-style-guide.md.
#
# Scope, deliberately narrow so the gate never cries wolf:
#   * Flags hardcoded COLOR SGR only — foreground/background codes and 256-color
#     (e.g. \033[1;36m, \e[0;31m, \033[38;5;81m). These have COL_* equivalents.
#   * Does NOT flag cursor movement (\033[%dC), bare attributes (\033[1m/\033[0m),
#     or blink (\033[5m) — the palette offers no COL_* for those, so raw is fine.
#   * PROVIDERS (files that define COL_*/ESC_SEQ from raw escapes, e.g.
#     trove_colors.zsh, a logger's fallback) are auto-detected and skipped.
#   * A line with a legitimate raw color (e.g. LESS_TERMCAP exports for `less`)
#     opts out with a trailing  # style:allow  comment.
#
# Everything else in the standard (role choice, the leading-space heading, closed
# spans, color-free --json) is a review checklist, not auto-lintable — this tool
# covers only what it can verify with certainty.
#
# Usage:
#   tools/lint-output-style.sh [--root <dir>] [--strict] [-h|--help]
#     (no flags)   scan this repo's shell sources; exit 1 on any violation
#     --root <dir> scan another checkout (e.g. ../beskar) so the gate works cross-repo
#     --strict     reserved: also fail on WARN-level heuristics (none yet)
#
# A repo-root .styleignore (one path-prefix regex per line, '#' comments) excludes
# extra paths. .git and this tool are always excluded.

emulate -L zsh
setopt pipe_fail

_LOS_SELF="${0:A}"   # capture before any function frame (in zsh $0 becomes the fn name inside one)

# Hardcoded COLOR SGR: ESC [ …params… (fg 3x/9x · bg 4x/10x · 256 38;5;/48;5;) m
_LOS_COLOR_RE='(\\033|\\x1b|\\e)\[[0-9;]*(3[0-9]|4[0-9]|9[0-9]|10[0-9]|38;5;|48;5;)[0-9;]*m'

# A palette PROVIDER assigns COL_*/ESC_SEQ from a raw escape — allowed; skipped.
_los_is_provider() {
    grep -qE '(COL_[A-Z_]+|ESC_SEQ)[[:space:]]*=.*(\\033|\\x1b|\\e)\[' "$1" 2>/dev/null
}

_los_ignored() {   # $1 = repo-relative path; reads _ignore via dynamic scope
    local rel="$1" pat
    for pat in "${_ignore[@]}"; do [[ "$rel" =~ $pat ]] && return 0; done
    return 1
}

_los_main() {
    local root="." strict=0
    while (( $# )); do
        case "$1" in
            --root)    root="${2:-}"; [[ -n "$root" ]] || { print -u2 "lint-output-style: --root needs a directory"; return 2; }; shift 2 ;;
            --strict)  strict=1; shift ;;
            -h|--help) sed -n '2,25p' "$0"; return 0 ;;
            *)         print -u2 "lint-output-style: unknown arg '$1'"; return 2 ;;
        esac
    done
    [[ -d "$root" ]] || { print -u2 "lint-output-style: not a directory: ${root}"; return 2; }
    root="${root:A}"

    # Load .styleignore path-prefix regexes (optional). Visible to _los_ignored.
    local -a _ignore=()
    local line
    if [[ -f "${root}/.styleignore" ]]; then
        while IFS= read -r line; do
            line="${line%%#*}"; line="${line//[[:space:]]/}"
            [[ -n "$line" ]] && _ignore+=("$line")
        done < "${root}/.styleignore"
    fi

    # Collect shell sources: *.zsh/*.sh/*.bash, plus extension-less shebang files.
    local -a files=()
    local f rel
    while IFS= read -r f; do
        rel="${f#${root}/}"
        [[ "$rel" == .git/* || "$rel" == */.git/* ]] && continue
        [[ "${f:A}" == "$_LOS_SELF" ]] && continue
        _los_ignored "$rel" && continue
        if [[ "$f" != *.zsh && "$f" != *.sh && "$f" != *.bash ]]; then
            head -1 "$f" 2>/dev/null | grep -qE '^#!.*(zsh|bash|sh)\b' || continue
        fi
        _los_is_provider "$f" && continue
        files+=("$f")
    done < <(find "$root" -type f 2>/dev/null)

    local violations=0 scanned=${#files} hits
    for f in "${files[@]}"; do
        rel="${f#${root}/}"
        # Grep color escapes, then drop any line that opts out with # style:allow.
        hits="$(grep -nE "$_LOS_COLOR_RE" "$f" 2>/dev/null | grep -vF 'style:allow')" || continue
        [[ -z "$hits" ]] && continue
        (( violations++ ))
        print -r -- "✖ ${rel}"
        print -r -- "$hits" | sed 's/^/    /'
    done

    print ""
    if (( violations )); then
        print -r -- "lint-output-style: ${violations} file(s) hardcode color escapes — use COL_* (docs/STYLE.md)."
        print -r -- "  legitimate raw color (e.g. LESS_TERMCAP) → add a trailing '# style:allow'."
        return 1
    fi
    print -r -- "lint-output-style: clean (${scanned} consumer files) — no hardcoded color escapes."
    return 0
}

_los_main "$@"
