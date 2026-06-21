#!/usr/bin/env bash
# spark.sh — Trove cold-start (curl|bash) installer.
#
# Run AS YOUR NORMAL USER (never sudo/root). It escalates with sudo ONLY for the
# system steps (creating /opt, package installs); everything else runs as you, so
# /opt/trove is owned by you from the start.
#
#   export SPARK_REPO_BASE="https://git.example.com/<user>"   # YOUR git host + namespace
#   curl -fsSL "$SPARK_REPO_BASE/trove/raw/branch/next/spark.sh" | bash
#
# Installs Trove to /opt/trove (git clone + the repo's own ./install). Idempotent:
# re-running is a no-op once Trove is present.
#
# Env:
#   SPARK_REPO_BASE   git base under which trove.git/beskar.git/dotFiles.git live
#                     (http(s):// or ssh://…); REQUIRED — the default is a placeholder.
#   SPARK_REF         branch/tag to clone (default: next)
#   SPARK_OPT_ROOT    install root for the code repos (default: /opt)
#   SPARK_PRIMARY_USER  when started as root, the user to own + run as (cold-start)
set -euo pipefail

REPO_BASE="${SPARK_REPO_BASE:-https://git.example.com/<user>}"   # EDIT or export
REF="${SPARK_REF:-next}"
OPT_ROOT="${SPARK_OPT_ROOT:-/opt}"

_bot(){ printf '\n  \xe2\x9c\xaa %s\n' "$*"; }
_run(){ printf '   \xe2\x9c\xa8 %s\n' "$*"; }
_ok(){  printf '   \xe2\x9c\x94 %s\n' "$*"; }
_err(){ printf '   \xe2\x9c\x96 %s\n' "$*" >&2; }
die(){ _err "$*"; exit 1; }

# ── Privilege model: run as the user; escalate only system steps ──────────────
if [[ "$(id -u)" -eq 0 ]]; then
  OWNER="${SPARK_PRIMARY_USER:-${SUDO_USER:-}}"
  [[ -n "$OWNER" ]] || die "Run spark.sh as your normal user (not root). To cold-start from root, set SPARK_PRIMARY_USER=<user>."
  id "$OWNER" >/dev/null 2>&1 || die "SPARK_PRIMARY_USER '$OWNER' does not exist — create the account first (spark seeds tools, not users)."
else
  OWNER="$(id -un)"
fi
as_root(){ if [[ "$(id -u)" -eq 0 ]]; then "$@"; else sudo "$@"; fi; }
as_user(){ if [[ "$(id -un)" == "$OWNER" ]]; then "$@"; else as_root sudo -u "$OWNER" -H "$@"; fi; }

[[ "$REPO_BASE" == *"example.com"* || "$REPO_BASE" == *"<user>"* ]] && \
  die "Set SPARK_REPO_BASE to your real git base (e.g. https://git.myhost/me) — got the placeholder '$REPO_BASE'."

# ── Prerequisites (bash/git/curl only; trove's ./install handles zsh) ─────────
ensure_prereqs(){
  command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1 && return 0
  if command -v apt-get >/dev/null 2>&1; then
    _run "installing prerequisites (git, curl)"
    as_root apt-get update -q && as_root apt-get install -y -q git curl
  else
    command -v git >/dev/null 2>&1 || die "git not found and no apt-get to install it — install git and retry."
  fi
}

# ── Per-repo helpers (shared shape across all three spark scripts) ────────────
trove_installed(){  [[ -f "${OPT_ROOT}/trove/lib/trove_init.zsh" ]]; }
beskar_installed(){ [[ -f "${OPT_ROOT}/beskar/VERSION" ]]; }
dotfiles_present(){ [[ -x "${OPT_ROOT}/dotFiles/bin/dotFiles" ]]; }

clone_repo(){  # clone_repo <name> → ${OPT_ROOT}/<name>, owned by $OWNER, on $REF
  local name="$1"; local dest="${OPT_ROOT}/${name}"
  if [[ -d "${dest}/.git" ]]; then _ok "${name}: already cloned (${dest})"; return 0; fi
  _run "cloning ${name} → ${dest} (${REF})"
  as_root mkdir -p "$dest"
  as_root chown "$OWNER" "$dest"
  as_user git clone -b "$REF" "${REPO_BASE}/${name}.git" "$dest" \
    || die "failed to clone ${REPO_BASE}/${name}.git (branch ${REF}) — check SPARK_REPO_BASE / access."
}
run_install(){  # run the repo's own ./install as $OWNER (it self-escalates for apt)
  local name="$1"; local dest="${OPT_ROOT}/${name}"
  [[ -x "${dest}/install" ]] || die "${name}: ${dest}/install missing or not executable."
  _run "running ${name} installer"
  ( cd "$dest" && as_user ./install ) || die "${name} ./install failed."
}

main(){
  _bot "Trove cold-start → ${OPT_ROOT}/trove (as ${OWNER})"
  ensure_prereqs
  if trove_installed; then _ok "Trove already installed at ${OPT_ROOT}/trove"; else clone_repo trove; run_install trove; fi
  _ok "Trove ready."
}
main "$@"
