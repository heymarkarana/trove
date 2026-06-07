#!/usr/bin/env zsh
# Trove Requirements — dependency checking and optional installation
# Checks binary presence, version constraints, and provider availability.

: "${TROVE_REQUIRE_JSON:=0}"
: "${TROVE_ALLOW_SUDO:=0}"

if ! (( ${+functions[trove_command_exists]} )); then
    echo "ERROR: trove_requirements.zsh requires trove_helpers.zsh" >&2
    return 1 2>/dev/null || exit 1
fi

###############################################################################
# Version Utilities
###############################################################################

# Extract first semver-like version from arbitrary text
# Usage: version=$(trove_version_parse "git version 2.39.2")
trove_version_parse() {
    local input="$1"
    if [[ "$input" =~ '([0-9]+(\.[0-9]+){0,3}([a-zA-Z0-9\.\-\+]+)?)' ]]; then
        echo "${match[1]}"
        return 0
    fi
    return 1
}

# Parse a version constraint like ">=2.30.0" into op and version
# Sets reply=(operator version)
_trove_version_parse_constraint() {
    local constraint="$1"
    reply=()

    if [[ -z "$constraint" ]]; then
        return 1
    fi

    if [[ "$constraint" =~ '^([<>=!]+)[[:space:]]*(.+)$' ]]; then
        reply=("${match[1]}" "$(trove_version_parse "${match[2]}")")
    else
        reply=(">=" "$(trove_version_parse "$constraint")")
    fi

    [[ -n "${reply[2]}" ]]
}

# Compare two version strings
# Usage: trove_version_compare "2.39.2" ">=" "2.30.0"
# Returns: 0 if comparison holds, 1 otherwise
trove_version_compare() {
    local left="$1"
    local op="$2"
    local right="$3"
    local higher

    [[ -n "$left" && -n "$right" ]] || return 1

    if [[ "$left" == "$right" ]]; then
        case "$op" in
            "=="|"eq"|"="|">="|"gte"|"<="|"lte") return 0 ;;
            ">"|"gt"|"<"|"lt") return 1 ;;
            *) return 1 ;;
        esac
    fi

    higher=$(printf '%s\n%s\n' "$left" "$right" | sort -V | tail -1)

    case "$op" in
        ">"|"gt")   [[ "$higher" == "$left" ]] ;;
        ">="|"gte") [[ "$higher" == "$left" ]] ;;
        "<"|"lt")   [[ "$higher" == "$right" ]] ;;
        "<="|"lte") [[ "$higher" == "$right" ]] ;;
        "=="|"eq"|"=") return 1 ;;
        *) return 1 ;;
    esac
}

# Check installed version against a constraint string
# Usage: trove_version_satisfies "2.39.2" ">=2.30.0"
trove_version_satisfies() {
    local installed="$1"
    local constraint="$2"
    local op required

    _trove_version_parse_constraint "$constraint" || return 0
    op="${reply[1]}"
    required="${reply[2]}"

    trove_version_compare "$installed" "$op" "$required"
}

# Get version of a command via probe
# Usage: version=$(trove_get_command_version "git" "--version")
trove_get_command_version() {
    local cmd="$1"
    local probe="${2:---version}"
    local output

    trove_command_exists "$cmd" || return 1

    output=$("$cmd" ${=probe} 2>&1) || return 1
    trove_version_parse "$output"
}

###############################################################################
# Provider Adapters
###############################################################################

_trove_provider_available() {
    local provider="$1"

    case "$provider" in
        brew)    trove_command_exists brew ;;
        apt)     trove_command_exists apt-get ;;
        snap)    trove_command_exists snap && trove_is_linux ;;
        npm)     trove_command_exists npm ;;
        command) return 0 ;;
        custom)  return 0 ;;
        *)       return 1 ;;
    esac
}

_trove_default_providers() {
    if trove_is_macos; then
        echo "brew,command"
    elif trove_is_linux; then
        echo "apt,snap,command"
    else
        echo "command"
    fi
}

_trove_pkg_installed() {
    local provider="$1"
    local package="$2"

    case "$provider" in
        brew)
            brew list --versions "$package" &>/dev/null
            ;;
        apt)
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"
            ;;
        snap)
            snap list "$package" &>/dev/null
            ;;
        npm)
            npm list -g --depth=0 "$package" &>/dev/null
            ;;
        command)
            trove_command_exists "$package"
            ;;
        *)
            return 1
            ;;
    esac
}

_trove_pkg_version() {
    local provider="$1"
    local package="$2"
    local output version

    case "$provider" in
        brew)
            output=$(brew list --versions "$package" 2>/dev/null | head -1)
            trove_version_parse "$output"
            ;;
        apt)
            output=$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null)
            trove_version_parse "$output"
            ;;
        snap)
            output=$(snap list "$package" 2>/dev/null | awk 'NR==2 {print $2}')
            trove_version_parse "$output"
            ;;
        npm)
            output=$(npm list -g --depth=0 "$package" 2>/dev/null | head -5)
            trove_version_parse "$output"
            ;;
        *)
            return 1
            ;;
    esac
}

_trove_pkg_install_cmd() {
    local provider="$1"
    local package="$2"

    case "$provider" in
        brew)  echo "brew install ${package}" ;;
        apt)
            if [[ "${TROVE_ALLOW_SUDO}" == "1" ]]; then
                echo "sudo apt-get install -y ${package}"
            else
                echo "sudo apt-get install -y ${package}"
            fi
            ;;
        snap)
            if [[ "${TROVE_ALLOW_SUDO}" == "1" ]]; then
                echo "sudo snap install ${package}"
            else
                echo "sudo snap install ${package}"
            fi
            ;;
        npm)   echo "npm install -g ${package}" ;;
        *)     return 1 ;;
    esac
}

# Parse provider spec "brew:git" into provider and package
# Sets reply=(provider package)
_trove_parse_provider_spec() {
    local spec="$1"
    reply=()

    if [[ "$spec" == *:* ]]; then
        reply=("${spec%%:*}" "${spec#*:}")
    else
        reply=("$spec" "")
    fi
}

# Find first available provider from comma-separated list
# Sets reply=(provider package install_hint)
_trove_select_provider() {
    local providers_csv="$1"
    local default_package="$2"
    local spec provider package hint
    local -a providers

    providers=("${(@s/,/)providers_csv}")
    reply=()

    for spec in "${providers[@]}"; do
        spec="${spec// /}"
        [[ -n "$spec" ]] || continue

        _trove_parse_provider_spec "$spec"
        provider="${reply[1]}"
        package="${reply[2]:-$default_package}"

        [[ "$provider" == "command" || "$provider" == "custom" ]] && continue
        _trove_provider_available "$provider" || continue

        hint=$(_trove_pkg_install_cmd "$provider" "$package") || continue
        reply=("$provider" "$package" "$hint")
        return 0
    done

    return 1
}

###############################################################################
# Status Reporting
###############################################################################

# Emit JSON for a single requirement status (when TROVE_REQUIRE_JSON=1)
_trove_require_emit_json() {
    local name="$1"
    local command="$2"
    local required_version="$3"
    local installed_version="$4"
    local req_status="$5"
    local provider="$6"
    local install_hint="$7"
    local message="$8"

    [[ "${TROVE_REQUIRE_JSON}" == "1" ]] || return 0

    local req_ver="${required_version:-null}"
    local inst_ver="${installed_version:-null}"
    local prov="${provider:-null}"
    local hint="${install_hint:-null}"

    if [[ -n "$required_version" ]]; then
        req_ver="\"${required_version}\""
    fi
    if [[ -n "$installed_version" ]]; then
        inst_ver="\"${installed_version}\""
    fi
    if [[ -n "$provider" ]]; then
        prov="\"${provider}\""
    fi
    if [[ -n "$install_hint" ]]; then
        hint="\"${install_hint}\""
    fi

    local line="{\"name\":\"${name}\",\"command\":\"${command}\",\"required_version\":${req_ver},\"installed_version\":${inst_ver},\"status\":\"${req_status}\",\"provider\":${prov},\"install_hint\":${hint},\"message\":\"${message}\"}"

    if (( ${+TROVE_REQUIRE_RESULTS} )); then
        TROVE_REQUIRE_RESULTS+=("$line")
    fi

    print -r -- "$line"
}

# Map status string to exit code
_trove_require_status_code() {
    case "$1" in
        ok)        echo 0 ;;
        missing)   echo 1 ;;
        outdated)  echo 2 ;;
        unmanaged) echo 1 ;;
        error)     echo 3 ;;
        *)         echo 3 ;;
    esac
}

###############################################################################
# Core Check Logic
###############################################################################

# Internal: evaluate a single requirement
# Sets reply=(req_status installed_version provider install_hint message exit_code)
_trove_require_eval() {
    local name="$1"
    local command="$2"
    local version_constraint="$3"
    local providers_csv="$4"
    local version_probe="$5"
    local custom_check="$6"
    local custom_install="$7"

    local installed_version="" req_status="ok" provider="" install_hint="" message=""
    local exit_code=0 probe_cmd

    reply=()
    command="${command:-$name}"
    providers_csv="${providers_csv:-$(_trove_default_providers)}"
    probe_cmd="${version_probe:---version}"

    # Custom check hook
    if [[ -n "$custom_check" ]]; then
        if eval "$custom_check"; then
            reply=(ok "" "" "" "${name}: custom check passed" 0)
            return 0
        else
            if [[ -n "$custom_install" ]]; then
                install_hint="$custom_install"
                provider="custom"
            fi
            message="${name}: custom check failed"
            if [[ -n "$install_hint" ]]; then
                message="${message} — run: ${install_hint}"
            fi
            reply=(missing "" "$provider" "$install_hint" "$message" 1)
            return 1
        fi
    fi

    # Command on PATH
    if trove_command_exists "$command"; then
        installed_version=$(trove_get_command_version "$command" "$probe_cmd" 2>/dev/null) || installed_version=""

        if [[ -n "$version_constraint" && -n "$installed_version" ]]; then
            if trove_version_satisfies "$installed_version" "$version_constraint"; then
                message="${name}: ${installed_version} satisfies ${version_constraint}"
                reply=(ok "$installed_version" "" "" "$message" 0)
                return 0
            else
                req_status="outdated"
                message="${name}: ${installed_version} does not satisfy ${version_constraint}"
                exit_code=2
            fi
        elif [[ -n "$version_constraint" && -z "$installed_version" ]]; then
            req_status="outdated"
            message="${name}: installed but version could not be determined (requires ${version_constraint})"
            exit_code=2
        else
            message="${name}: ${command} available${installed_version:+ (${installed_version})}"
            reply=(ok "$installed_version" "" "" "$message" 0)
            return 0
        fi
    else
        req_status="missing"
        message="${name}: ${command} not found"
        exit_code=1
    fi

    # Resolve install provider for missing/outdated
    if _trove_select_provider "$providers_csv" "$name"; then
        provider="${reply[1]}"
        install_hint="${reply[3]}"
        message="${message} — try: ${install_hint}"
    elif [[ -n "$custom_install" ]]; then
        provider="custom"
        install_hint="$custom_install"
        message="${message} — run: ${install_hint}"
    else
        req_status="unmanaged"
        message="${message} — no install provider available"
    fi

    reply=("$req_status" "$installed_version" "$provider" "$install_hint" "$message" "$exit_code")
    return "$exit_code"
}

# Check a single requirement (check-only by default)
# Usage: trove_require_status git --version ">=2.30.0" --providers brew,apt
# Exit: 0=ok, 1=missing, 2=outdated, 3=error
trove_require_status() {
    local name="$1"
    shift

    local command="" version_constraint="" providers="" version_probe=""
    local custom_check="" custom_install=""

    [[ -n "$name" ]] || return 3

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --command)        command="$2"; shift 2 ;;
            --version|--min)  version_constraint="$2"; shift 2 ;;
            --providers)      providers="$2"; shift 2 ;;
            --version-probe)  version_probe="$2"; shift 2 ;;
            --check)          custom_check="$2"; shift 2 ;;
            --install-cmd)    custom_install="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    _trove_require_eval "$name" "$command" "$version_constraint" "$providers" \
        "$version_probe" "$custom_check" "$custom_install"

    local req_status="${reply[1]}" installed="${reply[2]}" provider="${reply[3]}"
    local hint="${reply[4]}" message="${reply[5]}" code="${reply[6]}"

    _trove_require_emit_json "$name" "${command:-$name}" "$version_constraint" \
        "$installed" "$req_status" "$provider" "$hint" "$message"

    if (( ${+functions[trove_log]} )); then
        case "$req_status" in
            ok)       trove_ok "$message" ;;
            missing)  trove_log WARN "$message" ;;
            outdated) trove_log WARN "$message" ;;
            *)        trove_log WARN "$message" ;;
        esac
    fi

    return "$code"
}

# Ensure a requirement is met; install only with --install
# Usage: trove_ensure git --version ">=2.30.0" --providers brew,apt [--install]
trove_ensure() {
    local name="$1"
    shift

    local do_install=false
    local -a passthrough=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install) do_install=true; shift ;;
            *) passthrough+=("$1"); shift ;;
        esac
    done

    trove_require_status "$name" "${passthrough[@]}"
    local code=$?

    if [[ $code -eq 0 || "$do_install" != true ]]; then
        return "$code"
    fi

    # Re-run eval to get provider/hint (require_status already ran)
    local command="" version_constraint="" providers="" version_probe=""
    local custom_check="" custom_install=""

    local -a args=("${passthrough[@]}")
    while [[ ${#args[@]} -gt 0 ]]; do
        case "${args[1]}" in
            --command)        command="${args[2]}"; args=("${args[@]:3}") ;;
            --version|--min)  version_constraint="${args[2]}"; args=("${args[@]:3}") ;;
            --providers)      providers="${args[2]}"; args=("${args[@]:3}") ;;
            --version-probe)  version_probe="${args[2]}"; args=("${args[@]:3}") ;;
            --check)          custom_check="${args[2]}"; args=("${args[@]:3}") ;;
            --install-cmd)    custom_install="${args[2]}"; args=("${args[@]:3}") ;;
            *) args=("${args[@]:2}") ;;
        esac
    done

    _trove_require_eval "$name" "$command" "$version_constraint" "$providers" \
        "$version_probe" "$custom_check" "$custom_install"

    local provider="${reply[3]}" install_hint="${reply[4]}"
    local install_cmd=""

    if [[ "$provider" == "custom" && -n "$custom_install" ]]; then
        install_cmd="$custom_install"
    elif [[ -n "$provider" && "$provider" != "command" ]]; then
        local package
        _trove_select_provider "${providers:-$(_trove_default_providers)}" "$name"
        package="${reply[2]}"
        install_cmd=$(_trove_pkg_install_cmd "$provider" "$package")
    fi

    [[ -n "$install_cmd" ]] || return "$code"

    if (( ${+functions[trove_running]} )); then
        trove_running "Installing ${name}"
    fi

    if [[ "${TROVE_ALLOW_SUDO}" != "1" && "$install_cmd" == sudo* ]]; then
        if (( ${+functions[trove_log]} )); then
            trove_log WARN "Install requires sudo — set TROVE_ALLOW_SUDO=1 or run: ${install_cmd}"
        fi
        return "$code"
    fi

    if (( ${+functions[trove_silent_run]} )); then
        trove_silent_run "$install_cmd" "Installing ${name}" INFO
    else
        eval "$install_cmd"
    fi

    trove_require_status "$name" "${passthrough[@]}"
}

###############################################################################
# Manifest Loading
###############################################################################

# Parse YAML manifest to JSON using python3 (PyYAML or stdlib json for .json)
# Usage: json=$(_trove_requirements_load_manifest "/path/to/requirements.yaml")
_trove_requirements_load_manifest() {
    local manifest="$1"
    local json

    [[ -f "$manifest" ]] || {
        echo "ERROR: Manifest not found: ${manifest}" >&2
        return 3
    }

    if [[ "$manifest" == *.json ]]; then
        json=$(python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1]))))' "$manifest" 2>/dev/null) || return 3
    elif command -v python3 >/dev/null 2>&1; then
        json=$(python3 -c '
import json, sys
path = sys.argv[1]
try:
    import yaml
except ImportError:
    sys.exit(10)
with open(path) as f:
    print(json.dumps(yaml.safe_load(f)))
' "$manifest" 2>/dev/null)
        local py_exit=$?
        if [[ $py_exit -eq 10 ]]; then
            json=$(_trove_requirements_parse_yaml_minimal "$manifest") || return 3
        elif [[ $py_exit -ne 0 ]]; then
            return 3
        fi
    else
        json=$(_trove_requirements_parse_yaml_minimal "$manifest") || return 3
    fi

    echo "$json"
}

# Minimal YAML parser for Trove requirements schema (no PyYAML)
_trove_requirements_parse_yaml_minimal() {
    local manifest="$1"
    local -a items=()
    local current="" key value in_providers=false
    local line trimmed

    while IFS= read -r line || [[ -n "$line" ]]; do
        trimmed="${line##[[:space:]]}"
        [[ -z "$trimmed" || "$trimmed" == \#* ]] && continue

        if [[ "$trimmed" == "requirements:" ]]; then
            continue
        fi

        if [[ "$trimmed" == "- name:"* ]]; then
            [[ -n "$current" ]] && items+=("$current")
            value="${trimmed#- name:}"
            value="${value// /}"
            current="name=${value}"
            in_providers=false
            continue
        fi

        if [[ "$trimmed" == "providers:" ]]; then
            in_providers=true
            current="${current}|providers="
            continue
        fi

        if [[ "$in_providers" == true && "$trimmed" == "- "* ]]; then
            value="${trimmed#- }"
            value="${value// /}"
            current="${current},${value}"
            continue
        fi

        in_providers=false

        if [[ "$trimmed" == *:* ]]; then
            key="${trimmed%%:*}"
            key="${key// /}"
            value="${trimmed#*:}"
            value="${value// /}"
            value="${value#\"}"
            value="${value%\"}"
            current="${current}|${key}=${value}"
        fi
    done < "$manifest"

    [[ -n "$current" ]] && items+=("$current")

    if [[ ${#items[@]} -eq 0 ]]; then
        echo "ERROR: No requirements found in manifest" >&2
        return 3
    fi

    local json='{"requirements":['
    local first=true item part k v providers_json
    for item in "${items[@]}"; do
        $first || json+=","
        first=false
        json+="{"
        local entry_first=true
        local providers_list=""
        local -a parts
        parts=("${(s:|:)item}")

        for part in "${parts[@]}"; do
            k="${part%%=*}"
            v="${part#*=}"
            if [[ "$k" == "providers" ]]; then
                providers_list="${v#,}"
                continue
            fi
            $entry_first || json+=","
            entry_first=false
            json+="\"${k}\":\"${v}\""
        done

        if [[ -n "$providers_list" ]]; then
            $entry_first || json+=","
            json+='"providers":['
            local pfirst=true p
            for p in "${(@s/,/)providers_list}"; do
                [[ -n "$p" ]] || continue
                $pfirst || json+=","
                pfirst=false
                if [[ "$p" == *:* ]]; then
                    json+="{\"${p%%:*}\":\"${p#*:}\"}"
                else
                    json+="\"${p}\""
                fi
            done
            json+="]"
        fi

        json+="}"
    done
    json+="]}"

    echo "$json"
}

# Expand manifest JSON into pipe-delimited entries for zsh iteration
_trove_requirements_manifest_entries() {
    local json="$1"

    command -v python3 >/dev/null 2>&1 || return 3

    python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
for req in data.get("requirements", []):
    parts = []
    for k, v in req.items():
        if k == "providers":
            provs = []
            for p in v:
                if isinstance(p, dict):
                    for pk, pv in p.items():
                        provs.append(f"{pk}:{pv}")
                else:
                    provs.append(str(p))
            parts.append("providers=" + ",".join(provs))
        else:
            parts.append(f"{k}={v}")
    print("|".join(parts))
' <<< "$json"
}

# Parse a pipe-delimited manifest entry into args for trove_require_status/trove_ensure
_trove_requirements_entry_args() {
    local entry="$1"
    local part k v
    local name="" command="" version="" providers="" probe="" check="" install_cmd=""
    local -a parts args=()

    parts=("${(s:|:)entry}")

    for part in "${parts[@]}"; do
        k="${part%%=*}"
        v="${part#*=}"
        case "$k" in
            name)          name="$v" ;;
            command)       command="$v" ;;
            version)       version="$v" ;;
            providers)     providers="$v" ;;
            version_probe) probe="$v" ;;
            check)         check="$v" ;;
            install)       install_cmd="$v" ;;
        esac
    done

    [[ -n "$command" ]] && args+=(--command "$command")
    [[ -n "$version" ]] && args+=(--version "$version")
    [[ -n "$providers" ]] && args+=(--providers "$providers")
    [[ -n "$probe" ]] && args+=(--version-probe "$probe")
    [[ -n "$check" ]] && args+=(--check "$check")
    [[ -n "$install_cmd" ]] && args+=(--install-cmd "$install_cmd")

    reply=("$name" "${args[@]}")
}

# Shared manifest runner
_trove_requirements_run_manifest() {
    local manifest="$1"
    local mode="$2"
    local json entries entry name worst=0 code
    local -a args

    json=$(_trove_requirements_load_manifest "$manifest") || return 3
    entries=$(_trove_requirements_manifest_entries "$json") || return 3
    [[ -n "$entries" ]] || {
        echo "ERROR: No requirements in manifest" >&2
        return 3
    }

    typeset -ga TROVE_REQUIRE_RESULTS
    TROVE_REQUIRE_RESULTS=()

    local saved_json="${TROVE_REQUIRE_JSON}"
    TROVE_REQUIRE_JSON=1

    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue

        _trove_requirements_entry_args "$entry"
        name="${reply[1]}"
        args=("${reply[@]:2}")

        if [[ "$mode" == "ensure" ]]; then
            trove_ensure "$name" "${args[@]}" --install
        else
            trove_require_status "$name" "${args[@]}"
        fi
        code=$?
        (( code > worst )) && worst=$code
    done <<< "$entries"

    TROVE_REQUIRE_JSON="$saved_json"

    if [[ "${TROVE_REQUIRE_JSON}" == "1" && ${#TROVE_REQUIRE_RESULTS[@]} -gt 0 ]]; then
        print -r -- "{\"results\":[$(printf '%s,' "${TROVE_REQUIRE_RESULTS[@]}" | sed 's/,$//')],\"exit_code\":${worst}}"
    fi

    return "$worst"
}

# Check all requirements in a manifest (check-only)
# Usage: trove_requirements_check ./requirements.yaml
trove_requirements_check() {
    local manifest="$1"
    [[ -n "$manifest" ]] || return 3
    _trove_requirements_run_manifest "$manifest" "check"
}

# Ensure all requirements in a manifest (install with --install flag)
# Usage: trove_requirements_ensure ./requirements.yaml --install
trove_requirements_ensure() {
    local manifest="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install) shift ;;
            *)
                echo "ERROR: trove_requirements_ensure requires --install" >&2
                return 3
                ;;
        esac
    done

    [[ -n "$manifest" ]] || return 3
    _trove_requirements_run_manifest "$manifest" "ensure"
}
