# Decisions

The Trove decision log. Each locked decision gets a number (`Dxxx`); cite decisions
by number in commits, reviews, and code comments rather than restating them.
Decisions are durable — revisit only with a new decision that supersedes the old
(note the supersession). Trove is the base tier of the Trove/Beskar/dotFiles stack;
where a decision mirrors the platform standard, the Dais decision is cited.

---

## D001 — Trove is the base tier; no upward dependencies

Trove is installed first (`/opt/trove`) and loaded before the rest of the
environment exists. It may depend only on zsh, standard POSIX tools, and
(optionally) its own `klog` facade — never on dotFiles, Beskar, `df.env`, or any
higher tier. Trove owns **Atlas**, the discovery layer every other tier consumes.
Mirrors Dais D001 (tier position) from the base-tier side.

## D002 — One version source: the root `VERSION` file

The root `VERSION` file is authoritative. `TROVE_VERSION` is derived from it at
runtime in `lib/trove_init.zsh` and exported (so subprocess facades and
other-language callers can read it). Never hardcode a version literal elsewhere.
Mirrors Dais D002.

## D003 — Discovery via Atlas only; Atlas stays tier-pure

All path/identity resolution flows through `trove_atlas_*` — never hardcoded paths,
never `$HOME`-derived. `TROVE_HOME` is the canonical variable for Trove's own
location (`TROVE_PATH` is a deprecated read-only alias; never write it). Atlas
itself emits/resolves **neutral `ATLAS_*` names only** — no `DF_*` or `BESKAR_*`
references in `trove_atlas.zsh` or `bin/atlas-env`; each consumer maps `ATLAS_*`
into its own namespace. Mirrors Dais D003.

## D004 — Canonical instruction file is `AGENTS.md`; `CLAUDE.md` is a symlink

`AGENTS.md` is the single authoritative agent-instruction file. Tool-specific names
(`CLAUDE.md`, …) are **POSIX symlinks** to it — never separate copies (which drift)
and never a macOS Alias. This supersedes the interim markdown-stub `CLAUDE.md`
introduced in `79e88d3` after `CLAUDE.md` had been accidentally committed as a
binary macOS Alias leaking system metadata (username / machine / volume UUID). A
`ln -s` symlink is plain text ("AGENTS.md"), carries no metadata, and keeps exactly
one source of truth. Mirrors Dais D004.

## D005 — Trove must degrade gracefully

Trove is loaded before the full environment is available. It must not assume
`df.env` is sourced, Beskar is present, or zsh is the login shell. Missing optional
capabilities warn-and-continue; they never hard-fail the base library. Dependencies
stay limited to zsh + POSIX (+ optional `klog` for the monitoring module).

## D006 — No instance/homelab identity in source

Trove is a generic library with no knowledge of the environment it is installed in.
Names specific to any user's environment (codenames, hostnames, usernames, domains)
must not appear in source, docs, or committed config examples. Instance facts are
resolved at runtime through Atlas. Mirrors Dais D009 (no instance identity in code).

## D007 — Always-on, secret-scrubbed verbose file sink (v1.2.0)

Beyond the terminal logger, a second sink writes plain-text, timestamped,
secret-scrubbed logs **all the time** at full TRACE verbosity — independent of the
terminal level and of `TROVE_ENABLE_LOGGING`. Per-app, per-actor files, mode `600`,
with configurable retention. Rationale: a durable, redacted audit trail for humans
and LLMs without leaking secrets. Governed by `TROVE_FILE_LOGGING`, `TROVE_LOG_*`.

## D008 — Trove is a sourced library tier; dispatcher-CLI conventions are N/A

Trove is consumed by `source`-ing `lib/trove_init.zsh` and calling `trove_*`
functions; it also ships fixed facades (`klog`, `kreq`, `atlas-env`) for non-shell
callers. It has **no `bin/trove` dispatcher, no `cli/<cmd>.zsh` tree, and no
standard `status`/`version`/`help` subcommands** — by design. Under the Dais
standard this is the `library` archetype, for which those CLI-tool conventions are
not applicable (Dais D010). The init lib plus the public function API are the
equivalent surface.

## D009 — Declare every `local` once; no combined-local footgun

Never re-declare a `local` inside a loop body, and never declare two-or-more vars in
one `local`/`typeset` statement where a later var reads an earlier one (zsh expands
all right-hand sides before assigning, so the earlier var is still empty). Both
shapes fail silently. `tools/lint-zsh-locals.sh` gates the combined-local footgun;
`tools/lint-zsh-syntax.sh` parse-checks all sources. Mirrors Dais D008. See
`6ae69a3` (a `local path` shadowed `$PATH` and broke disk metrics).
