#!/usr/bin/env zsh
# tools/lint-zsh-syntax.sh — parse-check every zsh source under Trove.
#
# Runs `zsh -n` (syntax-only, no execution) over bin/ (the klog/kreq/atlas-env
# facades) and lib/. A non-zero exit means at least one file failed to parse.
# This is a static gate: it must pass before any change is considered done.
# Sibling to tools/lint-zsh-locals.sh (the combined-local footgun gate).

set -u
TROVE_ROOT="${0:A:h:h}"
cd "${TROVE_ROOT}"

typeset -i failures=0
typeset -a files
files=(
    bin/*(N.)
    lib/**/*.zsh(N.)
)

for f in "${files[@]}"; do
    if zsh -n "$f" 2>/tmp/trove-lint-err.$$; then
        printf '  ok   %s\n' "$f"
    else
        printf '  FAIL %s\n' "$f"
        sed 's/^/       /' /tmp/trove-lint-err.$$
        (( failures++ ))
    fi
done
rm -f /tmp/trove-lint-err.$$

echo ""
if (( failures )); then
    echo "zsh syntax lint: ${failures} file(s) failed"
    exit 1
fi
echo "zsh syntax lint: all ${#files} file(s) OK"
exit 0
