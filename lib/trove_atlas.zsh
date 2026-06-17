#!/usr/bin/env zsh
# Trove Atlas — Discovery Reader
#
# Atlas is the ecosystem's discovery mechanism: how any tool, from any execution
# context (interactive shell, cron, systemd, root, a different username), finds
# where the foundation tools and the instance config live — WITHOUT relying on
# $HOME and WITHOUT hardcoding instance-specific paths.
#
# This module is the single reader. It lives in Trove (tier 1) and is consumed
# by every higher tier. It reads and writes *values*; it knows nothing about
# what those values mean beyond their key names. It contains NO references to
# any consumer's variable namespace — it emits and resolves neutral names only.
#
# Registry: /opt/.atlas/registry  (override: $ATLAS_REGISTRY, for tests/dev)
#   - format: key=value, one per line; lines beginning with # are comments
#   - parsed as DATA, never sourced as code
#   - dir 2755, file 644 (non-secret discovery data, world-readable on purpose)
#   - owner primary_user:group
#
# Resolution order for any key X:
#   1. neutral env override  ATLAS_<UPPERCASE_KEY>
#   2. Atlas registry lookup (key X)
#   3. caller-supplied generic default
#   For instance facts (primary_user, group, install_root, config_home) there is
#   no safe generic default — trove_atlas_require fails loud when unresolved.

###############################################################################
# Internals
###############################################################################

# Resolve the active registry path (test override wins).
_trove_atlas_registry() {
    print -r -- "${ATLAS_REGISTRY:-/opt/.atlas/registry}"
}

# Fail-loud helper that degrades gracefully if logging isn't loaded.
_trove_atlas_fatal() {
    if (( ${+functions[trove_log]} )); then
        trove_log FATAL "$@"
    else
        print -r -- "FATAL: $*" >&2
    fi
}

# Is a registry line a comment or blank?
_trove_atlas_is_skippable() {
    emulate -L zsh
    setopt extended_glob
    local line="$1"
    [[ "$line" == [[:space:]]#\#* ]] && return 0   # optional leading space then #
    [[ -z "${line//[[:space:]]/}" ]] && return 0   # blank / whitespace-only
    return 1
}

# Trim surrounding whitespace from a key token.
_trove_atlas_trim() {
    emulate -L zsh
    setopt extended_glob
    local s="$1"
    s="${s##[[:space:]]#}"
    s="${s%%[[:space:]]#}"
    print -r -- "$s"
}

# Look up a raw key in the registry file. echo value + return 0, or return 1.
_trove_atlas_lookup() {
    emulate -L zsh
    local key="$1" reg line k v
    reg="$(_trove_atlas_registry)"
    [[ -r "$reg" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        _trove_atlas_is_skippable "$line" && continue
        [[ "$line" == *=* ]] || continue
        k="$(_trove_atlas_trim "${line%%=*}")"
        if [[ "$k" == "$key" ]]; then
            v="${line#*=}"
            print -r -- "$v"
            return 0
        fi
    done < "$reg"
    return 1
}

# Ensure the registry dir + file exist with correct mode (best-effort owner).
_trove_atlas_ensure_store() {
    emulate -L zsh
    local reg dir
    reg="$(_trove_atlas_registry)"
    dir="${reg:h}"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" 2>/dev/null || {
            _trove_atlas_fatal "Atlas: cannot create registry directory: $dir"
            return 1
        }
        chmod 2755 "$dir" 2>/dev/null
    fi
    if [[ ! -f "$reg" ]]; then
        : > "$reg" 2>/dev/null || {
            _trove_atlas_fatal "Atlas: cannot create registry file: $reg"
            return 1
        }
        chmod 644 "$reg" 2>/dev/null
    fi
    return 0
}

# Best-effort: align registry ownership to primary_user:group when both are
# resolvable and we have the privilege to do it. Never fails the caller.
_trove_atlas_align_owner() {
    emulate -L zsh
    local reg user group
    reg="$(_trove_atlas_registry)"
    user="$(_trove_atlas_lookup primary_user)" || return 0
    group="$(_trove_atlas_lookup group)" || group=""
    [[ -n "$user" ]] || return 0
    local target="$user"
    [[ -n "$group" ]] && target="${user}:${group}"
    chown "$target" "$reg" 2>/dev/null \
        && chown "$target" "${reg:h}" 2>/dev/null
    return 0
}

# Rewrite the registry, dropping $1 (a key) and optionally appending "$2" verbatim.
_trove_atlas_rewrite() {
    emulate -L zsh
    local drop_key="$1" append_line="$2"
    local reg dir tmp line k
    reg="$(_trove_atlas_registry)"
    _trove_atlas_ensure_store || return 1
    dir="${reg:h}"
    tmp="$(mktemp "${dir}/.registry.XXXXXX" 2>/dev/null)" || {
        _trove_atlas_fatal "Atlas: cannot create temp file in $dir"
        return 1
    }
    if [[ -f "$reg" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            if _trove_atlas_is_skippable "$line"; then
                print -r -- "$line" >> "$tmp"
                continue
            fi
            k="$(_trove_atlas_trim "${line%%=*}")"
            [[ "$k" == "$drop_key" ]] && continue
            print -r -- "$line" >> "$tmp"
        done < "$reg"
    fi
    [[ -n "$append_line" ]] && print -r -- "$append_line" >> "$tmp"
    mv "$tmp" "$reg" || { rm -f "$tmp"; return 1; }
    chmod 644 "$reg" 2>/dev/null
    return 0
}

###############################################################################
# Public API
###############################################################################

# Resolve a single key: env override -> registry -> caller default.
# Usage: trove_atlas_get <key> [generic_default]
# Returns: value on stdout + 0; empty + non-zero if unresolved and no default.
trove_atlas_get() {
    emulate -L zsh
    local key="$1" default="${2:-}"
    [[ -n "$key" ]] || { _trove_atlas_fatal "Atlas: get requires a key"; return 1; }

    # 1. neutral env override (ATLAS_<UPPERCASE_KEY>)
    local envname="ATLAS_${(U)key}" envval
    envval="${(P)envname}"
    if [[ -n "$envval" ]]; then
        print -r -- "$envval"
        return 0
    fi

    # 2. registry
    local v
    if v="$(_trove_atlas_lookup "$key")"; then
        print -r -- "$v"
        return 0
    fi

    # 3. caller default
    if [[ -n "$default" ]]; then
        print -r -- "$default"
        return 0
    fi

    return 1
}

# Require a key; fail loud (FATAL + return 1) when unresolved.
# Usage: trove_atlas_require <key>
trove_atlas_require() {
    emulate -L zsh
    local key="$1" v
    if v="$(trove_atlas_get "$key")"; then
        print -r -- "$v"
        return 0
    fi
    _trove_atlas_fatal "Atlas: required key '$key' is unresolved (no ATLAS_${(U)key} env override and not present in registry: $(_trove_atlas_registry))"
    return 1
}

# Resolve a known tool install path (env alias + registry key + fixed default).
# Usage: trove_atlas_tool <trove|beskar|dotfiles>
trove_atlas_tool() {
    emulate -L zsh
    local tool="$1"
    case "$tool" in
        trove)
            # Trove's own canonical var wins (TROVE_PATH is a read-only legacy alias).
            if [[ -n "${TROVE_HOME:-}" ]]; then
                print -r -- "$TROVE_HOME"; return 0
            fi
            if [[ -n "${TROVE_PATH:-}" ]]; then
                print -r -- "$TROVE_PATH"; return 0
            fi
            trove_atlas_get trove /opt/trove
            ;;
        beskar)
            trove_atlas_get beskar /opt/beskar
            ;;
        dotfiles)
            trove_atlas_get dotfiles /opt/dotFiles
            ;;
        *)
            _trove_atlas_fatal "Atlas: unknown tool '$tool' (expected: trove, beskar, dotfiles)"
            return 1
            ;;
    esac
}

# Write/update a key in the registry (idempotent; creates store if missing).
# Usage: trove_atlas_set <key> <value>
trove_atlas_set() {
    emulate -L zsh
    local key="$1" value="$2"
    [[ -n "$key" ]] || { _trove_atlas_fatal "Atlas: set requires a key"; return 1; }
    [[ "$key" == *=* ]] && { _trove_atlas_fatal "Atlas: key may not contain '=': $key"; return 1; }
    _trove_atlas_rewrite "$key" "${key}=${value}" || return 1
    _trove_atlas_align_owner
    return 0
}

# Remove a key from the registry. Always succeeds if the store is writable.
# Usage: trove_atlas_unset <key>
trove_atlas_unset() {
    emulate -L zsh
    local key="$1"
    [[ -n "$key" ]] || { _trove_atlas_fatal "Atlas: unset requires a key"; return 1; }
    _trove_atlas_rewrite "$key" "" || return 1
    return 0
}

# Print the whole registry as key=value (comments/blank lines omitted).
# Usage: trove_atlas_dump
trove_atlas_dump() {
    emulate -L zsh
    local reg line
    reg="$(_trove_atlas_registry)"
    [[ -r "$reg" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        _trove_atlas_is_skippable "$line" && continue
        print -r -- "$line"
    done < "$reg"
}

# Rebuild the registry from a provided set of facts (used by bootstrap/heal).
# Usage: trove_atlas_sync key=value [key=value ...]
trove_atlas_sync() {
    emulate -L zsh
    [[ $# -gt 0 ]] || { _trove_atlas_fatal "Atlas: sync requires at least one key=value"; return 1; }
    local reg dir tmp arg
    reg="$(_trove_atlas_registry)"
    _trove_atlas_ensure_store || return 1
    dir="${reg:h}"
    tmp="$(mktemp "${dir}/.registry.XXXXXX" 2>/dev/null)" || {
        _trove_atlas_fatal "Atlas: cannot create temp file in $dir"
        return 1
    }
    {
        print -r -- "# Atlas discovery registry — regenerated by trove_atlas_sync"
        print -r -- "# Non-secret, world-readable. Never committed; rebuildable on demand."
        for arg in "$@"; do
            if [[ "$arg" != *=* ]]; then
                _trove_atlas_fatal "Atlas: sync argument is not key=value: $arg"
                rm -f "$tmp"
                return 1
            fi
            print -r -- "$arg"
        done
    } >> "$tmp"
    mv "$tmp" "$reg" || { rm -f "$tmp"; return 1; }
    chmod 644 "$reg" 2>/dev/null
    _trove_atlas_align_owner
    return 0
}

###############################################################################
# Direct-execution help (sourced: no-op)
###############################################################################
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    if [[ "$#" -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Trove Atlas — discovery reader"
        echo ""
        echo "API:"
        echo "  trove_atlas_get <key> [default]   Resolve env -> registry -> default"
        echo "  trove_atlas_require <key>         Resolve or fail loud"
        echo "  trove_atlas_tool <trove|beskar|dotfiles>"
        echo "  trove_atlas_set <key> <value>     Write/update a key"
        echo "  trove_atlas_unset <key>           Remove a key"
        echo "  trove_atlas_dump                  Print the registry"
        echo "  trove_atlas_sync key=value ...    Rebuild the registry"
        echo ""
        echo "Registry: ${ATLAS_REGISTRY:-/opt/.atlas/registry}"
        exit 0
    fi
fi
