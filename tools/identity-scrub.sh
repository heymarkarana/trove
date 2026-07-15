#!/usr/bin/env bash
# identity-scrub — the cross-repo release gate. Fails (exit non-zero) if any
# forbidden instance-identity literal appears in committed, publishable content.
# Lives in Trove (the base tier) so every repo shares one gate; dotFiles and
# Beskar invoke it with --root. CHANGELOG.md is reported SEPARATELY (dotFiles'
# v4 history is a known offender whose rewrite-vs-fresh handling is an owner
# decision at cutover).
#
# Usage:
#   tools/identity-scrub.sh [--root <dir>] [--changelog] [--all]
#     (no flags)   scan publishable content; exit 1 on any hit
#     --root <dir> scan another repo's checkout (default: this tool's own repo)
#     --changelog  ALSO scan CHANGELOG.md and fail on hits there too
#     --all        scan every committed file (incl. internal planning docs)
#
# Extensible ignore-list: a repo-root .scrubignore (one path-prefix regex per
# line, '#' comments) is honored with the justified exclusions below.
set -uo pipefail

# TOOL_REPO = this tool's own repo (trove); never affected by --root.
# Default scan root = TOOL_REPO; --root <dir> points it at another checkout
# (dotFiles/beskar) so the gate works cross-repo.
TOOL_REPO="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$TOOL_REPO"

scan_changelog=0 scan_all=0
while (( $# )); do
    case "$1" in
        --root)      ROOT="${2:-}"; [[ -n "$ROOT" ]] || { echo "identity-scrub: --root needs a directory" >&2; exit 2; }; shift 2 ;;
        --changelog) scan_changelog=1; shift ;;
        --all)       scan_all=1; shift ;;
        -h|--help)   sed -n '2,17p' "$0"; exit 0 ;;
        *)           echo "identity-scrub: unknown arg '$1'" >&2; exit 2 ;;
    esac
done
cd "$ROOT" || { echo "identity-scrub: cannot cd to '$ROOT'" >&2; exit 2; }

# The forbidden-literal list is kept OUTSIDE every scanned repo (so the literals
# never live in publishable content). Resolution order:
#   1. $SCRUB_LITERALS_FILE — explicit override
#   2. <install_root>/dotFiles-config/shared/scrub-literals — the encrypted
#      config-backup repo; install_root comes from Atlas via bin/atlas-env
#      (registry override: $ATLAS_REGISTRY)
# Fail loud if neither resolves — the gate must not run blind.
# Format: "<literal|substring|pattern> <value>" per line, '#' comments.
if [[ -z "${SCRUB_LITERALS_FILE:-}" ]]; then
    _atlas_exports="$(zsh "${TOOL_REPO}/bin/atlas-env" 2>/dev/null)" && eval "$_atlas_exports"
    [[ -n "${ATLAS_INSTALL_ROOT:-}" ]] && SCRUB_LITERALS_FILE="${ATLAS_INSTALL_ROOT}/dotFiles-config/shared/scrub-literals"
fi
if [[ ! -r "${SCRUB_LITERALS_FILE:-}" ]]; then
    echo "identity-scrub: forbidden-literal list not found: ${SCRUB_LITERALS_FILE:-<unresolved — no Atlas install_root>}" >&2
    echo "  it is kept outside the repos by design — set SCRUB_LITERALS_FILE to its path." >&2
    exit 2
fi
LITERALS=() SUBSTRINGS=() PATTERNS=()
while read -r _kind _val; do
    [[ -z "${_kind:-}" || "$_kind" == \#* ]] && continue
    case "$_kind" in
        literal)   LITERALS+=("$_val") ;;
        substring) SUBSTRINGS+=("$_val") ;;
        pattern)   PATTERNS+=("$_val") ;;
    esac
done < "$SCRUB_LITERALS_FILE"

# Justified default exclusions (the gate's scope is publishable content):
#  - .git              not content
#  - CHANGELOG.md      dotFiles v4 history, handled separately (--changelog to include)
#  - tools/identity-scrub.sh  this tool (self-referential grep patterns)
#  - .scrubignore      the ignore-list itself
EXCLUDE_DEFAULT='^(CHANGELOG\.md$|tools/identity-scrub\.sh$|\.scrubignore$)'
EXTRA_IGNORE=""
[[ -f .scrubignore ]] && EXTRA_IGNORE="$(grep -vE '^\s*(#|$)' .scrubignore | paste -sd'|' -)"

# Build the file list from git (committed content only). Portable to bash 3.2
# (macOS) — no mapfile.
FILES=()
_filter() {
    if (( scan_all )); then git ls-files
    elif [[ -n "$EXTRA_IGNORE" ]]; then git ls-files | grep -vE "$EXCLUDE_DEFAULT" | grep -vE "$EXTRA_IGNORE"
    else git ls-files | grep -vE "$EXCLUDE_DEFAULT"
    fi
}
while IFS= read -r f; do [[ -n "$f" ]] && FILES+=("$f"); done < <(_filter)

# Assemble one extended-regex alternation. (${ARR[@]+...} keeps bash 3.2's
# set -u happy when a kind has no entries.)
alt=""
for l in ${LITERALS[@]+"${LITERALS[@]}"};   do alt+="|\\b${l}\\b"; done
for s in ${SUBSTRINGS[@]+"${SUBSTRINGS[@]}"}; do alt+="|${s//./\\.}"; done
for p in ${PATTERNS[@]+"${PATTERNS[@]}"};   do alt+="|${p}"; done
alt="${alt#|}"

# A line carrying the marker `scrub-allow` is an intentional, justified occurrence
# (e.g. a per-lib identity-scrub assertion whose grep pattern must spell the
# forbidden words). It is reported as allowed, never a failure.
hits=0
if (( ${#FILES[@]} )); then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "$line" == *scrub-allow* ]]; then continue; fi
        echo "  ✘ $line"
        hits=$((hits + 1))
    done < <(grep -rInE "$alt" -- "${FILES[@]}" 2>/dev/null)
fi

if (( hits )); then
    echo ""
    echo "identity-scrub: ${hits} forbidden-literal hit(s) in publishable content — FAIL"
    rc=1
else
    echo "identity-scrub: clean — no forbidden literals in publishable content ✔"
    rc=0
fi

# CHANGELOG is reported separately (informational unless --changelog).
if [[ -f CHANGELOG.md ]]; then
    cl=$(grep -cInE "$alt" CHANGELOG.md 2>/dev/null || true)
    cl="${cl:-0}"
    if (( cl > 0 )); then
        echo "identity-scrub: NOTE — CHANGELOG.md has ${cl} hit(s) (v4 history; rewrite-vs-fresh is an owner decision at cutover)"
        (( scan_changelog )) && rc=1
    fi
fi

exit $rc
