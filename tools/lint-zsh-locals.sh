#!/usr/bin/env bash
# lint-zsh-locals — flag the zsh combined-`local` footgun: a single
# `local|typeset|declare` statement that declares two-or-more vars where a LATER
# var's value references an EARLIER var from the SAME statement. zsh expands ALL
# right-hand sides before performing any assignment, so the earlier var is still
# empty when the later one reads it — a silent empty string, not an error (it
# passes casual testing and fails at runtime).
#
#   BUG:   local a="$x" b="${a%%/*}"      # b reads a before a is assigned -> empty
#   SAFE:  local a b; a="$x"; b="${a%%/*}"   # separate ;-statements -> a is set
#
# Related discipline (not detected here, but learned the hard way): never
# re-declare a `local` inside a loop body — declare every local once at the top
# of the function and only assign inside loops. Re-`local`-ing an already-set var
# can echo its value to stdout.
#
# Read-only static check. Exits non-zero if any footgun is found, so it can gate a
# commit / CI run (sibling to lint-zsh-syntax.sh). The detector is quote/expansion
# aware (a `;` inside "…", '…', ${…} or $(…) is NOT a statement boundary) and joins
# backslash line-continuations, so it does not silently miss those shapes.
# Ported from dotFiles' tools/lint-zsh-locals.sh (reuse, not reinvent).
#
# Usage:
#   tools/lint-zsh-locals.sh [--root <dir>] [files...]
#     (no args)    scan this repo's tracked *.zsh/*.zunit; exit 1 on any hit
#     --root <dir> scan another repo's checkout
#     files...     scan only the given files (overrides the tracked set)
#     --self-test  prove the detector flags the bug shapes + ignores safe ones
set -uo pipefail

TOOL_REPO="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$TOOL_REPO"
selftest=0
files=()
while (( $# )); do
    case "$1" in
        --root)      ROOT="${2:-}"; [[ -n "$ROOT" ]] || { echo "lint-zsh-locals: --root needs a directory" >&2; exit 2; }; shift 2 ;;
        --self-test) selftest=1; shift ;;
        -h|--help)   sed -n '2,27p' "$0"; exit 0 ;;
        --*)         echo "lint-zsh-locals: unknown arg '$1'" >&2; exit 2 ;;
        *)           files+=("$1"); shift ;;
    esac
done

# The detector. Reads files from @ARGV; prints one report block per footgun.
run_detector() {
    perl - "$@" <<'PERL'
use strict; use warnings;
{
    local $/;                                   # slurp each @ARGV file whole
    while (my $content = <>) {
        my @phys = split /\n/, $content, -1;
        my $i = 0;
        while ($i <= $#phys) {
            my $start = $i + 1;                 # 1-based start line of this logical line
            my $line  = $phys[$i];
            while ($line =~ /\\$/ && $i < $#phys) {   # backslash continuation -> join
                $line =~ s/\\$//; $i++; $line .= $phys[$i];
            }
            $i++;
            next unless $line =~ /^\s*(?:local|typeset|declare)\b/;

            # Mask quoted / expansion / command-sub spans (same length) so a ; | &&
            # || inside them is not a statement boundary.
            my $masked = $line;
            $masked =~ s/('[^']*'|"[^"]*"|\$\{[^{}]*\}|\$\([^()]*\))/"\x01" x length($1)/ge;
            my $cut = length($line);
            for my $re (qr/;/, qr/&&/, qr/\|\|/, qr/(?<!\|)\|(?!\|)/) {
                $cut = $-[0] if $masked =~ $re && $-[0] < $cut;
            }
            my $stmt = substr($line, 0, $cut);

            my @decls;
            while ($stmt =~ /(?<![\$\w])([A-Za-z_]\w*)=/g) {   # NAME= (not $X= / a=b=c inner)
                push @decls, { name => $1, start => $-[0], valstart => $+[0] };
            }
            next if @decls < 2;
            for my $j (0 .. $#decls) {
                my $d   = $decls[$j];
                my $end = ($j < $#decls) ? $decls[$j + 1]{start} : length($stmt);
                my $region = substr($stmt, $d->{valstart}, $end - $d->{valstart});
                for my $k (0 .. $j - 1) {
                    my $e = $decls[$k]{name};
                    if ($region =~ /\$\{?\Q$e\E\b/) {
                        print "$ARGV:$start:  $line\n";
                        print "      ^ '$d->{name}' reads same-statement '\$$e' before it is assigned\n";
                    }
                }
            }
        }
    } continue { close ARGV if eof; }
}
PERL
}

if (( selftest )); then
    tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
    cat > "$tmp" <<'EOF'
  local rest="${url#*://}" host="${rest%%/*}"
  local a="$1" b="$2" c="${a}x"
  local s="x; y" t="${s}z"
  local re="a;b" tail="${re##*;}"
  local p="$1" \
        q="${p}r"
  local repo branch; repo="$(x)"; branch="$(y "$repo")"
  local m="$1" n="$2"
  local name="${1:-z}"; name="${name:t}"
EOF
    out="$(run_detector "$tmp")"
    bugs="$(printf '%s\n' "$out" | grep -c 'reads same-statement' || true)"
    if [[ "$bugs" == "5" ]] && ! printf '%s\n' "$out" | grep -qE 'repo branch|local m=|name="\$\{1'; then
        echo "lint-zsh-locals: self-test PASS (flagged 5 bug shapes; ignored 3 safe ones)"
        exit 0
    fi
    echo "lint-zsh-locals: self-test FAILED (bugs=${bugs}, expected 5)" >&2; printf '%s\n' "$out" >&2; exit 1
fi

# Resolve explicit file args to ABSOLUTE paths BEFORE cd.
if (( ${#files[@]} )); then
    resolved=()
    for f in "${files[@]}"; do
        [[ -e "$f" ]] || { echo "lint-zsh-locals: no such file: $f" >&2; exit 2; }
        resolved+=("$(cd "$(dirname "$f")" && pwd)/$(basename "$f")")
    done
    files=("${resolved[@]}")
fi

cd "$ROOT" || { echo "lint-zsh-locals: cannot cd to '$ROOT'" >&2; exit 2; }

if (( ${#files[@]} == 0 )); then
    while IFS= read -r f; do files+=("$f"); done < <(git ls-files '*.zsh' '*.zunit' 2>/dev/null)
fi
(( ${#files[@]} )) || { echo "lint-zsh-locals: no zsh files to scan"; exit 0; }

for f in "${files[@]}"; do
    [[ -r "$f" ]] || { echo "lint-zsh-locals: cannot read: $f" >&2; exit 2; }
done

report="$(run_detector "${files[@]}")"
if [[ -n "$report" ]]; then
    echo "lint-zsh-locals: combined-local footgun(s) found — split the declarations:" >&2
    printf '%s\n' "$report" >&2
    exit 1
fi
echo "lint-zsh-locals: clean (${#files[@]} files) — no combined-local footguns"
exit 0
