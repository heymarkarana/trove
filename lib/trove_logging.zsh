#!/usr/bin/env zsh
# Trove Logging System
# Structured logging with level filtering and colored output

###############################################################################
# Sudo User Detection
###############################################################################
# Determine the logged-in user's home directory when running with sudo
if [[ -n "${SUDO_USER:-}" ]]; then
    TROVE_ORIGINAL_USER_HOME=$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)
    if [[ -z "$TROVE_ORIGINAL_USER_HOME" ]]; then
        # Fallback for macOS which doesn't have getent
        TROVE_ORIGINAL_USER_HOME=$(dscl . -read "/Users/$SUDO_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    fi
    # Final fallback
    [[ -z "$TROVE_ORIGINAL_USER_HOME" ]] && TROVE_ORIGINAL_USER_HOME="${HOME}"
else
    TROVE_ORIGINAL_USER_HOME="${HOME}"
fi

###############################################################################
# Configuration
###############################################################################
# Set defaults if variables aren't in the environment yet
: ${TROVE_LOG_LEVEL:=INFO}
: ${TROVE_OUTPUT_DISPLAY:=true}
: ${TROVE_COLORSCHEME:=monokai}

# Internal configuration
# TROVE_ENABLE_LOGGING gates ALL Trove output. Respect a value already in the
# environment (so `TROVE_ENABLE_LOGGING=false` / dotFiles `log NONE` maps to a
# real "output off" state) and default to on.
: ${TROVE_ENABLE_LOGGING:=true}
TROVE_LOG_LEVEL_INTERNAL="${TROVE_LOG_LEVEL}"
TROVE_OUTPUT_DISPLAY_INTERNAL="${TROVE_OUTPUT_DISPLAY}"

###############################################################################
# File Sink Configuration (always-on verbose log)
###############################################################################
# The file sink is a SECOND, independent output target: it always records at
# full verbosity (plain text, timestamped, no color), regardless of what the
# terminal shows and even when TROVE_ENABLE_LOGGING=false silences the terminal.
# It is governed solely by the keys below. See docs/API.md and
# docs/migrations/1.2.0.md.
: ${TROVE_FILE_LOGGING:=true}       # master switch for the file sink (independent of terminal)
: ${TROVE_LOG_APP:=trove}           # channel name — apps set this (beskar, dotfiles, …)
: ${TROVE_LOG_DIR:=}                # explicit dir override; empty => per-user XDG / /var/log default
: ${TROVE_LOG_FILE_LEVEL:=TRACE}    # floor for what the file records (default: everything)
: ${TROVE_LOG_RETENTION_DAYS:=7}    # per-channel retention; older daily files pruned
: ${TROVE_LOG_FORMAT:=text}         # text (default) | json
: ${TROVE_LOG_SCRUB:=true}          # redact secrets before writing (default on)
: ${TROVE_LOG_SCRUB_PATTERNS:=}     # extra ':'-separated POSIX-ERE regexes to redact
: ${TROVE_LOG_CAPTURE_TEE:=true}    # whole-process capture: true=live+file, false=file-only synchronous

# Fast, fork-free timestamps: zsh/datetime provides strftime + $EPOCHSECONDS.
# NB: must be the FULL module load — `-F … b:strftime` does NOT export
# $EPOCHSECONDS. zsh/system provides $sysparams[procsubstpid] for the capture
# wrapper. Both are best-effort; the timestamp helper falls back to `date`.
zmodload zsh/datetime 2>/dev/null
zmodload zsh/system 2>/dev/null

# Numeric log levels as an associative array so the hot path compares inline
# without forking a `$(trove_log_level_num …)` subshell per message.
typeset -gA _TROVE_LVL
_TROVE_LVL=( FATAL 6 ERROR 5 WARN 4 INFO 3 DEBUG 2 TRACE 1 )

###############################################################################
# Load Color Scheme
###############################################################################
# Source colors if not already loaded
if [[ -z "${COL_RESET:-}" ]]; then
    TROVE_LIB_DIR="${0:A:h}"
    if [[ -f "${TROVE_LIB_DIR}/trove_colors.zsh" ]]; then
        source "${TROVE_LIB_DIR}/trove_colors.zsh"
    else
        # Fallback: minimal colors if colors library not found
        COL_RESET="\033[0m"
        COL_RED="\033[31m"
        COL_GREEN="\033[32m"
        COL_YELLOW="\033[33m"
        COL_ORANGE="\033[33m"
        COL_PURPLE="\033[35m"
        COL_BOLD_PURPLE="\033[1;35m"
        COL_BLUE="\033[34m"
        COL_CYAN="\033[36m"
        COL_WHITE="\033[37m"
        COL_GRAY="\033[90m"
        COL_DARK_GREEN="\033[42m"
    fi
fi

###############################################################################
# Help Function
###############################################################################
trove_show_help() {
    echo
    echo "Trove Logging and Output Functions"
    echo
    echo "Provides structured logging with level filtering and colored output."
    echo
    echo "Functions Overview:"
    echo
    echo "  trove_log LEVEL \"message\""
    echo "      General-purpose logging function for all severity levels."
    echo "      Levels: TRACE, DEBUG, INFO, WARN, ERROR, FATAL"
    echo "      Example: trove_log INFO \"Starting application\""
    echo
    echo "  Specialized Output Functions:"
    echo
    echo "  trove_bot \"message\""
    echo "      Announces major tasks or multi-step operations (bold purple ✪)."
    echo "      Example: trove_bot \"Installing System Packages\""
    echo
    echo "  trove_running \"message\""
    echo "      Logs individual configuration or setup steps (orange ✨)."
    echo "      Example: trove_running \"Setting default shell to zsh\""
    echo
    echo "  trove_action \"message\""
    echo "      Full-width header for user input prompts (green background)."
    echo "      Example: trove_action \"User Configuration Setup\""
    echo
    echo "  trove_ok \"message\""
    echo "      Indicates successful validation or selection (green ➤)."
    echo "      Example: trove_ok \"Configuration validated successfully\""
    echo
    echo "  Execution Functions:"
    echo
    echo "  trove_silent_run \"command\" \"message\" [LEVEL]"
    echo "      Executes a command and logs success/failure automatically."
    echo "      Example: trove_silent_run \"ls /tmp\" \"Listing files\" DEBUG"
    echo
    echo "  trove_print_result EXIT_CODE \"message\""
    echo "      Logs command result based on exit code."
    echo "      Subfunctions:"
    echo "        - trove_print_success: Logs success (green ✔)"
    echo "        - trove_print_error: Logs error (red ✖)"
    echo
    echo "  Verbose File Sink (always-on, plain, timestamped):"
    echo
    echo "  trove_log_file_path            Print today's channel log file path."
    echo "  trove_log_dir                  Print the resolved channel log directory."
    echo "  trove_log_tail [N]             Tail the current channel's log file."
    echo "  trove_log_prune                Delete daily files older than retention."
    echo "  trove_scrub \"text\"             Redact secrets in a string (prefix + ***)."
    echo "  trove_log_capture_begin        Start capturing all stdout+stderr to the file."
    echo "  trove_log_capture_end          Stop capture (drains fully before returning)."
    echo
    echo "Configuration (Environment Variables):"
    echo "  TROVE_LOG_LEVEL          - Terminal log level filter (default: INFO)"
    echo "  TROVE_OUTPUT_DISPLAY     - Show command output (default: true)"
    echo "  TROVE_COLORSCHEME        - Color scheme (default: monokai)"
    echo "  File sink:"
    echo "  TROVE_FILE_LOGGING       - Master switch for the file sink (default: true)"
    echo "  TROVE_LOG_APP            - Channel name / app (default: trove)"
    echo "  TROVE_LOG_DIR            - Override log dir (default: per-user XDG or /var/log)"
    echo "  TROVE_LOG_FILE_LEVEL     - Floor for the file (default: TRACE = everything)"
    echo "  TROVE_LOG_RETENTION_DAYS - Days of daily files to keep (default: 7)"
    echo "  TROVE_LOG_FORMAT         - text (default) | json"
    echo "  TROVE_LOG_SCRUB          - Redact secrets before writing (default: true)"
    echo "  TROVE_LOG_SCRUB_PATTERNS - Extra ':'-separated ERE regexes to redact"
    echo "  TROVE_LOG_CAPTURE_TEE    - Capture live+file (true) or file-only (false)"
    echo
    echo "Usage Guidelines:"
    echo "  - trove_bot:        Major tasks requiring multiple steps"
    echo "  - trove_running:    Individual setup actions and configurations"
    echo "  - trove_action:     Headers before prompting the user for input"
    echo "  - trove_ok:         Validation confirmations and acceptance"
    echo "  - trove_log:        All other logging (DEBUG, INFO, WARN, ERROR, FATAL)"
    echo "  - trove_silent_run: Commands with automatic success/error logging"
    echo
}

###############################################################################
# File Sink Implementation (always-on verbose log)
###############################################################################
# All helpers here are BEST-EFFORT: every failure path returns 0 so a full disk,
# an unwritable dir, or a missing module never changes a caller's exit status or
# prints stray output — essential to the `klog`-per-subprocess contract.
#
# Hot-path fork discipline: helpers return values via $REPLY (not command
# substitution), the level compare reads the _TROVE_LVL assoc array inline, and
# the effective user / actor line are memoized per process. The only fork on the
# common path is a single `id -un` (memoized) the first time a process logs.

# Effective (writing) user — memoized. At most one `id -un` fork per process.
_trove_log_euser() {
    if [[ -z "${_TROVE_EUSER:-}" ]]; then
        _TROVE_EUSER="$(id -un 2>/dev/null)"
        [[ -n "$_TROVE_EUSER" ]] || _TROVE_EUSER="uid${EUID}"
    fi
    REPLY="$_TROVE_EUSER"
}

# Resolve the channel directory (fork-free; not memoized so a runtime change of
# TROVE_LOG_APP / TROVE_LOG_DIR takes effect — e.g. a second channel mid-script).
_trove_log_dir_resolve() {
    if [[ -n "${TROVE_LOG_DIR:-}" ]]; then
        REPLY="${TROVE_LOG_DIR%/}"
    elif (( EUID == 0 )); then
        REPLY="/var/log/trove/${TROVE_LOG_APP:-trove}"
    else
        local base="${XDG_STATE_HOME:-${TROVE_ORIGINAL_USER_HOME:-$HOME}/.local/state}"
        REPLY="${base}/trove/logs/${TROVE_LOG_APP:-trove}"
    fi
}

# zsh/datetime-backed timestamps with a `date` fallback (best-effort, no stray
# output if the module is somehow absent).
_trove_now_iso() {
    if [[ -n "${EPOCHSECONDS:-}" ]] && strftime -s REPLY '%Y-%m-%dT%H:%M:%S%z' "$EPOCHSECONDS" 2>/dev/null; then
        return 0
    fi
    REPLY="$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null)"
}
_trove_now_day() {
    if [[ -n "${EPOCHSECONDS:-}" ]] && strftime -s REPLY '%Y-%m-%d' "$EPOCHSECONDS" 2>/dev/null; then
        return 0
    fi
    REPLY="$(date +%Y-%m-%d 2>/dev/null)"
}

# Today's per-actor file for the current channel: <dir>/<app>-<actor>-YYYY-MM-DD.log
_trove_log_file_resolve() {
    local dir day euser
    _trove_log_dir_resolve; dir="$REPLY"
    _trove_now_day;         day="$REPLY"
    _trove_log_euser;       euser="$REPLY"
    REPLY="${dir}/${TROVE_LOG_APP:-trove}-${euser}-${day}.log"
}

# Attribution line + JSON components, memoized. Real user is ADVISORY (env-based,
# spoofable / possibly empty under cron); only euid/uid come from the kernel.
_trove_actor_field() {
    if [[ -z "${_TROVE_ACTOR_LINE:-}" ]]; then
        local euser real
        _trove_log_euser; euser="$REPLY"
        real="${SUDO_USER:-${LOGNAME:-${USER:-$euser}}}"
        _TROVE_ACTOR_REAL="$real"
        _TROVE_ACTOR_EUID="$euser"
        _TROVE_ACTOR_LINE="actor=${real} euid=${euser} uid=${EUID} pid=$$"
    fi
    REPLY="$_TROVE_ACTOR_LINE"
}

# --- Secrets scrubbing (POSIX ERE via zsh `=~`; no forks) ---------------------
# Best-effort defense-in-depth, NOT a guarantee. Reveals a short prefix only when
# the secret is long enough (>=12 chars keep first 4 + ***, else fully ***).
typeset -ga _TROVE_SCRUB_ERE
_TROVE_SCRUB_ERE=(
    'AKIA[0-9A-Z]{16}'                                    # AWS access key id
    'ghp_[A-Za-z0-9]{20,}'                                # GitHub PAT (classic)
    'github_pat_[A-Za-z0-9_]{20,}'                        # GitHub PAT (fine-grained)
    'xox[baprs]-[A-Za-z0-9-]{10,}'                        # Slack token
    'AIza[0-9A-Za-z_-]{20,}'                              # Google API key
    'sk-[A-Za-z0-9]{20,}'                                 # generic secret key (sk-)
    'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'  # JWT
)

_trove_mask() {   # $1=secret -> REPLY
    local s="$1"
    if (( ${#s} >= 12 )); then REPLY="${s[1,4]}***"; else REPLY='***'; fi
}

# Cursor-based single pass: replaces the chosen group (0 = whole match) with a
# masked form, advancing past each replacement so masked text is never re-scanned
# (terminates; no oscillation). With ci=1 the match is found on a lowercased copy
# (ASCII/Unicode case-mapping is 1:1 per character, so indices align) while the
# mask is taken from — and applied to — the ORIGINAL-case string.
_trove_scrub_pass() {   # $1=input $2=ere $3=group(0=whole) [$4=ci] -> REPLY
    local in="$1" re="$2" g="$3" ci="${4:-0}" out="" hay
    local -i b e
    while :; do
        hay="$in"; [[ "$ci" == 1 ]] && hay="${in:l}"
        [[ "$hay" =~ "$re" ]] || break
        if (( g == 0 )); then b=$MBEGIN; e=$MEND; else b=${mbegin[$g]}; e=${mend[$g]}; fi
        (( b >= 1 && e >= b )) || break                 # safety: bail on odd indices
        _trove_mask "${in[b,e]}"                        # mask ORIGINAL-case substring
        out+="${in[1,b-1]}${REPLY}"
        in="${in[e+1,-1]}"
    done
    REPLY="${out}${in}"
}

_trove_scrub() {   # $1=line -> REPLY (scrubbed)
    if [[ "${TROVE_LOG_SCRUB:-true}" != true ]]; then REPLY="$1"; return 0; fi
    emulate -L zsh
    REPLY="$1"
    # 1) sensitive key=value / key: value  (case-insensitive key; value is group 3).
    #    Quoted forms first so `password="…"` / `password='…'` mask the inner value,
    #    then the bare (unquoted) form.
    local kv='(password|passwd|pass|secret|token|api[_-]?key|apikey|access[_-]?key|accesskey|authorization|auth|bearer|private[_-]?key|privatekey)'
    local sep='([[:space:]]*[=:][[:space:]]*)'
    # Authorization header: mask the credential AFTER an optional scheme word
    # (Bearer/Basic/…), so the opaque token — not just the scheme — is redacted.
    _trove_scrub_pass "$REPLY" "(authorization|proxy-authorization)${sep}(bearer[[:space:]]+|basic[[:space:]]+|token[[:space:]]+|digest[[:space:]]+|negotiate[[:space:]]+)?([^[:space:],;]+)" 4 1
    _trove_scrub_pass "$REPLY" "${kv}${sep}\"([^\"]*)\"" 3 1     # key="value"
    _trove_scrub_pass "$REPLY" "${kv}${sep}'([^']*)'" 3 1       # key='value'
    _trove_scrub_pass "$REPLY" "${kv}${sep}([^[:space:]\"'\`,;]+)" 3 1
    # 2) credentials embedded in a URL: scheme://user:SECRET@host  (SECRET is group 2)
    _trove_scrub_pass "$REPLY" '([a-zA-Z][a-zA-Z0-9+.-]*://[^:/[:space:]]+:)([^@[:space:]]+)@' 2
    # 3) known token shapes (whole match) + caller-supplied patterns
    local p
    for p in "${_TROVE_SCRUB_ERE[@]}" ${(s.:.)TROVE_LOG_SCRUB_PATTERNS}; do
        [[ -z "$p" ]] && continue
        _trove_scrub_pass "$REPLY" "$p" 0
    done
}

# --- Line formatting ----------------------------------------------------------
_trove_json_escape() {   # $1 -> REPLY
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/\\t}"
    REPLY="$s"
}
_trove_format_line() {   # $1=ts $2=level $3=msg  (actor from memoized globals)
    if [[ "${TROVE_LOG_FORMAT:-text}" == json ]]; then
        local emsg; _trove_json_escape "$3"; emsg="$REPLY"
        printf '{"ts":"%s","level":"%s","app":"%s","actor":"%s","euid":"%s","uid":"%s","pid":"%s","msg":"%s"}\n' \
            "$1" "$2" "${TROVE_LOG_APP:-trove}" "${_TROVE_ACTOR_REAL}" "${_TROVE_ACTOR_EUID}" "$EUID" "$$" "$emsg"
    else
        printf '%s [%-5s] [%s] [%s] %s\n' "$1" "$2" "${TROVE_LOG_APP:-trove}" "${_TROVE_ACTOR_LINE}" "$3"
    fi
}

# --- The emitter --------------------------------------------------------------
_trove_emit_file() {   # $1=level $2..=message
    [[ "${TROVE_FILE_LOGGING:-true}" == true ]] || return 0
    local level="$1"; shift; local raw="$*"

    local -i want=${_TROVE_LVL[$level]:-0}
    local -i floor=${_TROVE_LVL[${TROVE_LOG_FILE_LEVEL:-TRACE}]:-1}
    (( want >= floor )) || return 0

    emulate -L zsh; setopt extendedglob

    local file dir; _trove_log_file_resolve; file="$REPLY"; dir="${file:h}"
    [[ -d "$dir" ]] || { (umask 077; mkdir -p "$dir") 2>/dev/null || return 0; }

    local -i existed=1
    if [[ ! -e "$file" ]]; then
        (umask 077; : >> "$file") 2>/dev/null || return 0   # create 600 BEFORE content (no TOCTOU)
        existed=0
    fi

    local ts; _trove_now_iso; ts="$REPLY"
    _trove_actor_field   # populate memoized actor globals used by _trove_format_line

    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line//$'\e'\[[0-9;]#m/}"     # strip ANSI SGR (extendedglob)
        _trove_scrub "$line"; line="$REPLY"
        _trove_format_line "$ts" "$level" "$line" >> "$file" 2>/dev/null || return 0
    done <<< "$raw"

    if (( ! existed )); then
        chmod 600 "$file" 2>/dev/null        # belt-and-suspenders; content already created 600
        _trove_prune_logs
    fi
    return 0
}

# --- Retention ---------------------------------------------------------------
# Triggered once when a new daily file is created. Fully-dormant channels and
# other users' files in a shared dir are handled by a periodic `klog prune`
# (cron) — see docs/API.md. Portable across BSD (macOS) and GNU find.
_trove_prune_logs() {
    [[ "${TROVE_FILE_LOGGING:-true}" == true ]] || return 0
    local dir; _trove_log_dir_resolve; dir="$REPLY"
    [[ -d "$dir" ]] || return 0
    local -i days=${TROVE_LOG_RETENTION_DAYS:-7}
    find "$dir" -maxdepth 1 -type f -name "${TROVE_LOG_APP:-trove}-*.log" \
        -mtime +${days} -delete 2>/dev/null
    return 0
}

# --- Whole-process capture (opt-in, flush-safe) -------------------------------
# Filter: reads the captured stream, echoes each line to the saved terminal fd
# (this filter's stdout), and appends a timestamped+scrubbed copy to the file.
_trove_capture_filter() {
    emulate -L zsh; setopt extendedglob
    local file dir; _trove_log_file_resolve; file="$REPLY"; dir="${file:h}"
    [[ -d "$dir" ]] || (umask 077; mkdir -p "$dir") 2>/dev/null
    [[ -e "$file" ]] || (umask 077; : >> "$file") 2>/dev/null
    _trove_actor_field
    local line ts clean
    while IFS= read -r line || [[ -n "$line" ]]; do
        print -r -- "$line"                  # to terminal (filter stdout == saved terminal fd)
        _trove_now_iso; ts="$REPLY"
        clean="${line//$'\e'\[[0-9;]#m/}"
        _trove_scrub "$clean"; clean="$REPLY"
        _trove_format_line "$ts" "OUT" "$clean" >> "$file" 2>/dev/null
    done
}

# Last-resort synchronous capture if a FIFO cannot be created. Raw redirect: the
# output is captured but NOT timestamped/scrubbed. Rare; documented.
_trove_capture_file_only_raw() {
    local f; _trove_log_file_resolve; f="$REPLY"
    local d="${f:h}"; [[ -d "$d" ]] || (umask 077; mkdir -p "$d") 2>/dev/null
    [[ -e "$f" ]] || (umask 077; : >> "$f") 2>/dev/null
    exec >> "$f" 2>&1
    _TROVE_CAP_PID=""
    _TROVE_CAP_FIFO=""
}

# Begin/end bracket a region whose stdout+stderr are captured.
#
# Both modes route the region's output through a FIFO into a filter started as a
# real background JOB, so `_end` can `wait` on `$!` and genuinely block until the
# file is fully drained — this is what fixes the classic lost-tail bug. (A
# process-substitution `> >(…)` will NOT work: its PID is not a waitable job, so
# `wait` no-ops and the tail is lost.) The filter always timestamps + scrubs each
# line into the file; the ONLY difference between the modes is the live echo:
#   TROVE_LOG_CAPTURE_TEE=true  (default) — also echo each line to the terminal.
#   TROVE_LOG_CAPTURE_TEE=false           — file only, no live view.
#
# There is deliberately NO auto EXIT/ZERR trap (an in-function `trap … EXIT` fires
# on the function's OWN return in zsh, and ZERR would fire on any non-zero command
# inside the region). For exit-safety install one at TOP LEVEL in your script:
#   trove_log_capture_begin; trap 'trove_log_capture_end' EXIT
#
# WARNING: `_begin` without a paired `_end` strands the FIFO, the background filter
# job, and the saved stdout/stderr fds for the life of the shell. Because
# trove_init.zsh is sourced into interactive login shells, NEVER leave a capture
# open interactively — always pair it, ideally with the EXIT trap above.
trove_log_capture_begin() {
    [[ "${TROVE_FILE_LOGGING:-true}" == true ]] || return 0
    [[ -n "${_TROVE_CAP_OUT:-}" ]] && return 0            # already capturing (no nesting)
    exec {_TROVE_CAP_OUT}>&1 {_TROVE_CAP_ERR}>&2

    local fifo; fifo="$(mktemp -u 2>/dev/null)"
    if [[ -n "$fifo" ]] && mkfifo "$fifo" 2>/dev/null; then
        _TROVE_CAP_FIFO="$fifo"
        # Filter's own stdout = terminal (tee) or /dev/null (file-only); it writes
        # to the log file internally either way. Started as a job so `wait` blocks.
        if [[ "${TROVE_LOG_CAPTURE_TEE:-true}" == true ]]; then
            _trove_capture_filter < "$fifo" >&$_TROVE_CAP_OUT &
        else
            _trove_capture_filter < "$fifo" >/dev/null &
        fi
        _TROVE_CAP_PID=$!
        exec > "$fifo" 2>&1
    else
        _trove_capture_file_only_raw                     # fallback if no FIFO
    fi
    return 0
}
trove_log_capture_end() {
    [[ -n "${_TROVE_CAP_OUT:-}" ]] || return 0
    exec 1>&$_TROVE_CAP_OUT 2>&$_TROVE_CAP_ERR           # restore first -> writers closed -> filter EOF
    exec {_TROVE_CAP_OUT}>&- {_TROVE_CAP_ERR}>&-
    [[ -n "${_TROVE_CAP_PID:-}" ]] && wait "$_TROVE_CAP_PID" 2>/dev/null   # drain before return
    [[ -n "${_TROVE_CAP_FIFO:-}" ]] && rm -f "$_TROVE_CAP_FIFO" 2>/dev/null
    unset _TROVE_CAP_OUT _TROVE_CAP_ERR _TROVE_CAP_PID _TROVE_CAP_FIFO
    return 0
}

# --- Public file-sink API -----------------------------------------------------
trove_log_file_path() { _trove_log_file_resolve; print -r -- "$REPLY"; }
trove_log_dir()       { _trove_log_dir_resolve;  print -r -- "$REPLY"; }
trove_log_prune()     { _trove_prune_logs; }
trove_log_tail() {   # $1 = lines (default 50)
    local n="${1:-50}" f; _trove_log_file_resolve; f="$REPLY"
    [[ -f "$f" ]] && tail -n "$n" "$f"
}
trove_scrub() { _trove_scrub "$1"; print -r -- "$REPLY"; }

###############################################################################
# Core Logging Functions
###############################################################################

# Returns 0 when Trove output is enabled, 1 when disabled.
# Honors TROVE_ENABLE_LOGGING (true/false); dotFiles `log NONE` sets it false.
_trove_logging_enabled() {
    [[ "${TROVE_ENABLE_LOGGING:-true}" == true ]]
}

# Function to get numeric log level for comparison
trove_log_level_num() {
    case $1 in
    FATAL) echo 6 ;; # Fatal is the highest level
    ERROR) echo 5 ;;
    WARN) echo 4 ;;
    INFO) echo 3 ;;
    DEBUG) echo 2 ;;
    TRACE) echo 1 ;; # Trace is the lowest level
    *) echo 0 ;; # Unknown log levels default to 0
    esac
}

# Main log function with level filtering
trove_log() {
    local level="$1"
    shift

    # If not a known level, treat it as plain message
    if [[ ! "$level" =~ ^(FATAL|ERROR|WARN|INFO|DEBUG|TRACE)$ ]]; then
        local message="${level} $*"
        _trove_emit_file INFO "${message}"          # FILE SINK: always, unfiltered
        if _trove_logging_enabled; then
            echo "${message}" >&2
        fi
        return
    fi

    local message="$*"
    _trove_emit_file "$level" "${message}"          # FILE SINK: always, before the terminal gate
    if _trove_logging_enabled; then
        # Inline level compare via the assoc array — no subshell fork per call.
        local -i current_level_num=${_TROVE_LVL[${TROVE_LOG_LEVEL_INTERNAL}]:-0}
        local -i message_level_num=${_TROVE_LVL[${level}]:-0}

        if ((message_level_num >= current_level_num)); then
            local log_message="${message}"

            case "$level" in
                FATAL) log_message="${COL_PURPLE}    [‼] ${COL_RESET}${log_message}" ;;
                ERROR) log_message="${COL_RED}    [✖] ${COL_RESET}${log_message}" ;;
                WARN)  log_message="${COL_YELLOW}    [⚠] ${COL_RESET}${log_message}" ;;
                INFO)  log_message="${COL_GREEN}    [✔] ${COL_RESET}${log_message}" ;;
                DEBUG) log_message="${COL_CYAN}    [✱] ${COL_RESET}${log_message}" ;;
                TRACE) log_message="${COL_GRAY}    [➤] ${COL_RESET}${log_message}" ;;
            esac

            echo "${log_message}" >&2
        fi
    fi
}

###############################################################################
# Specialized Output Functions
###############################################################################

# Error convenience wrapper (shorthand for `trove_log ERROR`)
# Usage: trove_error "message"
trove_error() {
    trove_log ERROR "$@"
}

# Success indicator
trove_ok() {
    _trove_emit_file INFO "$1"
    _trove_logging_enabled || return 0
    printf "${COL_GREEN}    [➤] ${COL_RESET}%s\n" "$1" >&2
}

# Major section announcement
trove_bot() {
    _trove_emit_file INFO "$1"
    _trove_logging_enabled || return 0
    echo "" >&2
    echo "" >&2
    printf "${COL_BOLD_PURPLE}    [✪] ${COL_RESET}%s \n" "$1" >&2
}

# Configuration step indicator
trove_running() {
    _trove_emit_file INFO "$1"
    _trove_logging_enabled || return 0
    printf "${COL_ORANGE}   [✨] ${COL_RESET}%s \n" "$1" >&2
}

# Full-width header for user input sections
trove_action() {
    _trove_emit_file INFO "$1"
    _trove_logging_enabled || return 0
    local message="  $1"
    local term_width=$(tput cols 2>/dev/null || echo 80)
    local padded_message="${COL_WHITE}${message}$(printf '%*s' $((term_width - ${#message})) '')"

    printf "${COL_DARK_GREEN}${padded_message}${COL_RESET}\n" >&2
}

###############################################################################
# Result Printing Functions
###############################################################################

# Print error message
trove_print_error() {
    _trove_emit_file ERROR "$1"
    _trove_logging_enabled || return 0
    printf "${COL_RED}    [✖] ${COL_RESET}%s\n" "$1" >&2
}

# Print success message
trove_print_success() {
    _trove_emit_file INFO "$1"
    _trove_logging_enabled || return 0
    printf "${COL_GREEN}    [✔] ${COL_RESET}%s\n" "$1" >&2
}

# Print result based on exit code
trove_print_result() {
    if [ "$1" -eq 0 ]; then
        trove_print_success "$2"
    else
        trove_print_error "$2"
    fi

    return "$1"
}

###############################################################################
# Command Execution with Logging
###############################################################################

# Execute a command based on TROVE_OUTPUT_DISPLAY.
# If TROVE_OUTPUT_DISPLAY is true, the command runs with its native, separated,
# LIVE stdout/stderr on the terminal (unchanged behavior) — only the command line
# and result are recorded to the verbose file. If false, the command's output was
# historically dropped to /dev/null; it is now CAPTURED to the verbose log file
# instead (this is the "suppressed" material the file sink exists to preserve),
# still shown nowhere on the terminal. For full capture of a display-ON command's
# output, wrap the region in trove_log_capture_begin / trove_log_capture_end.
# Usage: trove_silent_run "command_to_execute" "Log message" "Log level (default: DEBUG)"
#
# The command string is tokenized into an argv array honoring quotes
# (`${(Q)${(z)...}}`) and run directly — NOT through `eval`. This removes the
# shell-injection surface: parameter/command substitutions embedded in the
# string are passed as literal arguments, never executed. The command therefore
# runs as a single program with arguments; a caller that genuinely needs a
# pipeline or redirection must request a shell explicitly, e.g.
#     trove_silent_run 'zsh -c "foo | bar"' "Message"
trove_silent_run() {
    local cmd="$1"                    # Command to execute
    local log_message="$2"            # Message to log
    local log_level="${3:-DEBUG}"     # Log level (default to DEBUG)
    local result                      # Stores the result of the command

    local -a argv_cmd
    argv_cmd=( ${(Q)${(z)cmd}} )

    _trove_emit_file "$log_level" "\$ ${cmd}"   # always record the command line

    if [[ "${TROVE_OUTPUT_DISPLAY_INTERNAL:-false}" == true ]]; then
        # Display command output — preserve native, separated, live streams.
        "${argv_cmd[@]}"
        result=$?
    else
        # Suppressed: capture combined stdout+stderr to the file (was /dev/null).
        local captured
        captured="$( "${argv_cmd[@]}" 2>&1 )"
        result=$?
        [[ -n "$captured" ]] && _trove_emit_file "$log_level" "$captured"
    fi

    # Log the result
    trove_print_result ${result} "${log_message}"
    return ${result}
}

###############################################################################
# Configuration Functions
###############################################################################

# Set log level dynamically
trove_set_log_level() {
    local level="$1"
    if [[ "$level" =~ ^(FATAL|ERROR|WARN|INFO|DEBUG|TRACE)$ ]]; then
        TROVE_LOG_LEVEL_INTERNAL="$level"
        export TROVE_LOG_LEVEL="$level"
        trove_log DEBUG "Log level set to: $level"
    else
        trove_log ERROR "Invalid log level: $level"
        return 1
    fi
}

# Get current log level
trove_get_log_level() {
    echo "${TROVE_LOG_LEVEL_INTERNAL}"
}

# Enable/disable output display
trove_set_output_display() {
    local value="$1"
    if [[ "$value" =~ ^(true|false)$ ]]; then
        TROVE_OUTPUT_DISPLAY_INTERNAL="$value"
        export TROVE_OUTPUT_DISPLAY="$value"
        trove_log DEBUG "Output display set to: $value"
    else
        trove_log ERROR "Invalid output display value: $value (must be true or false)"
        return 1
    fi
}

# Enable/disable ALL Trove output ("logging off"). dotFiles `log NONE` -> off.
# Usage: trove_set_logging_enabled <true|false>
trove_set_logging_enabled() {
    local value="$1"
    if [[ "$value" =~ ^(true|false)$ ]]; then
        TROVE_ENABLE_LOGGING="$value"
        export TROVE_ENABLE_LOGGING="$value"
        return 0
    fi
    # Reported before any disable takes effect, so this is always visible.
    trove_log ERROR "Invalid logging-enabled value: $value (must be true or false)"
    return 1
}

###############################################################################
# Compatibility Shims (Non-prefixed functions)
###############################################################################

# Provide non-prefixed versions for backward compatibility (optional)
# Uncomment if you want both prefixed and non-prefixed functions available
#
# log() { trove_log "$@"; }
# ok() { trove_ok "$@"; }
# bot() { trove_bot "$@"; }
# running() { trove_running "$@"; }
# action() { trove_action "$@"; }
# print_error() { trove_print_error "$@"; }
# print_success() { trove_print_success "$@"; }
# print_result() { trove_print_result "$@"; }
# silent_run() { trove_silent_run "$@"; }

###############################################################################
# Initialization Check
###############################################################################

# Check if the script is being sourced or executed directly
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    # The script is being executed directly
    if [[ "$#" -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        trove_show_help
        exit 0
    fi
else
    # The script is being sourced
    return 0
fi

# Symbol reference: ‣ ★ ☛ ✪ ✱ ➠ ➡ ➥ ✔ ✘ ✦ ✨ ❖ ➤ ⬥ ⮕ ‼ ⚠
