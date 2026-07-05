# STYLE.md — CLI output rules (agent context)

Imperative rule sheet for any CLI built on Trove. Drop into a repo as agent
context; build and audit output against it. Rationale & visuals live in
[cli-style-guide.md](./cli-style-guide.md); functions in [API.md](./API.md);
the mechanical gate is `tools/lint-output-style.sh`.

## Core law

- Reference color by **role** via `COL_*`, **never** a hardcoded `\033[…]` literal.
- Colors work in an `echo` string or a `printf` **format** position — **never** as
  a `%s` argument (they print as raw escapes there).
- Close every colored span with `COL_RESET`.
- The palette is theme-agnostic; the same source must render under all Trove themes.
- `COL_*` are LITERAL `\033[…]` strings; `echo`/`printf`-format interpret them, but
  `print -r` does NOT — materialize first (`x="$(print -- "$COL_X")"`) before raw print.
- Select a theme with `trove_set_colorscheme <monokai|solarized|nord|dracula|gruvbox>`;
  bridge it to an env var at startup (dotFiles `DF_COLOR_SCHEME`, Beskar
  `BESKAR_COLOR_SCHEME`; default `monokai`, applied once Trove is sourced).

## Roles → variable

| Role | Variable | Use for |
|---|---|---|
| Header | `COL_BOLD_PURPLE` | section titles, command banner |
| Key/label | `COL_CYAN` | field names, subcommand names |
| Value | `COL_BOLD` | versions, counts, the primary datum |
| Success | `COL_GREEN` | ok / clean / match / enabled — glyph `✔` |
| Warning | `COL_YELLOW` | dirty / pending / degraded — glyph `⚠` |
| Error | `COL_RED` | failure / critical — glyph `✖` |
| Muted | `COL_GRAY` | metadata, hints, timestamps, separators, disabled |
| Accent | `COL_BLUE` / `COL_PURPLE` | prompts, branches, links, selectable |

Glyphs: `✔` ok · `✖` error · `⚠` warn · `·` neutral/no-match · `➤` result ·
`✪` prompt · `●` status dot · `→ ← ↑ ↓` flow. Shape is the third channel — keep
it meaningful under `NO_COLOR`.

## Structure

- **Inline header** (status/info): Header-role title, then a `%-Ns`-aligned
  key/value block, two-space indent.
- **Ruled header** (dense help): rule / title / rule. The title has **exactly one
  leading space** before the word (`␣USAGE`). Rules in `COL_GRAY`, ≤ ~73 cols.
- Separate inline fields with a muted `·`.
- **Source references are a first-class element.** A `Library:`/`Registry:`/`Resolver:`
  pointer (file → its key functions): the label in the Header role (`COL_BOLD_PURPLE`),
  file paths in the Key role (`COL_CYAN`), functions plain. Use `—` (not `#`) between
  path and functions, and **align the `—`** down a block. One file → inline
  (`Library: lib/foo.zsh — fn, fn`); several → a `Library:` line then aligned
  `  lib/foo.zsh  — fns` rows.
- **Full-command rows take a `#` comment; bare tokens don't.** When a row's left
  column is a full, runnable command (`beskar config`, `dotFiles up`), write the
  description as a muted `#` comment so the whole line is valid, copy-pasteable
  shell: `${COL_CYAN}beskar config${COL_RESET}   ${COL_GRAY}# Show current config${COL_RESET}`.
  When the left column is a bare reference token — subcommand name, flag, or arg
  placeholder (`on`, `--setup`, `issue [domain]`) — use a plain aligned description
  (it isn't runnable alone). Holds for `Examples:` blocks and command-reference
  tables alike.

## Channels

- Status / progress / errors → `trove_*` loggers → **stderr**. Never raw `echo`.
- Structured / tabular / help → `echo`/`printf` + `COL_*` → **stdout**.
- `--json` / `--porcelain` → **no color, ever**. Gate at command entry.
- Honor `NO_COLOR` and non-TTY stdout → plain text.

## Do / don't

```zsh
# DO
printf "  ${COL_CYAN}%-12s${COL_RESET} %s\n" "$key" "$val"
echo "${COL_BOLD_PURPLE}Paths${COL_RESET}"
trove_ok "captured ${key}"

# DON'T
printf "\033[36m%s\033[0m\n" "$key"      # hardcoded escape — use COL_CYAN
printf "%s%s\n" "$COL_CYAN" "$key"       # color as %s arg — prints raw escapes
echo "OK: done"                          # raw status echo — use trove_ok
echo "${COL_CYAN}$key"                   # missing COL_RESET
```

## Conformance checklist

- [ ] Section titles use `COL_BOLD_PURPLE`, not plain uppercase.
- [ ] Keys/labels use `COL_CYAN`, aligned in a fixed-width column.
- [ ] Ruled headings have exactly one leading space before the word.
- [ ] Success/warning/error use green/yellow/red **and** the matching glyph.
- [ ] Metadata, timestamps, separators use `COL_GRAY`.
- [ ] Rows keyed by a FULL command use a muted `#` comment description (copy-pasteable); bare-token reference rows use plain descriptions.
- [ ] `Library:`/`Registry:`/`Resolver:` pointers: Header-role label, cyan paths, plain functions, aligned `—`.
- [ ] No raw `echo` for status — `trove_*` loggers only.
- [ ] Color in `echo` string / `printf` format position — never a `%s` arg.
- [ ] Every colored span closed with `COL_RESET`.
- [ ] Colors via `COL_*` — no hardcoded `\033[…]` literal. *(lint-enforced)*
- [ ] `--json`/`--porcelain` emit no escape codes.
