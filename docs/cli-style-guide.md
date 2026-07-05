# CLI Output Style Guide

The shared visual language for every CLI built on Trove — dotFiles, Beskar, and
anything downstream. Color, weight, and structure are not decoration: they encode
**organization and state** so output reads at a glance. Trove owns the primitives
(`COL_*` in `trove_colors.zsh`, the semantic loggers in `trove_logging.zsh`), so it
owns the standard; every consumer inherits it for free.

> **Companion docs.** [`STYLE.md`](./STYLE.md) is the terse, gradeable rule sheet
> (drop it into any repo as agent context). [`API.md`](./API.md) documents the
> underlying functions. `tools/lint-output-style.sh` gates the one mechanical rule.
> [`cli-style-guide.html`](./cli-style-guide.html) is a **visual companion** that
> renders the palette in real color (Markdown can't). This Markdown file is the
> **source of truth**; the HTML is regenerated only when the palette or roles
> change — not on wording edits.

---

## Table of Contents

- [Principle](#principle)
- [The palette — eight semantic roles](#the-palette--eight-semantic-roles)
- [Glyph vocabulary](#glyph-vocabulary)
- [Weight & style](#weight--style)
- [Structure](#structure)
- [Channels](#channels)
- [Worked example](#worked-example)
- [Conformance](#conformance)

---

## Principle

**Name colors by meaning, never by appearance.** Code references a *role*
(`COL_CYAN` = "key"), not a look ("light blue"). Because the role is stable, the
same source renders correctly under every Trove theme — Monokai, Solarized, Nord,
Dracula, Gruvbox — with no change. A reader learns the language once and it holds
across all your tools.

Color is the **primary** channel; weight/underline/reverse are the **second**;
glyph shape is the **third** (it survives pipes, `NO_COLOR`, and colorblindness).
Use the least that communicates — restraint is what makes the loud roles (error,
match) stay loud.

---

## The palette — eight semantic roles

Reference values are the Monokai (default) theme; the point is the **role**, not
the hex.

| Role | Variable | Monokai | Use for |
|---|---|---|---|
| **Header** | `COL_BOLD_PURPLE` | 141 bold | Section titles, the command-name banner — the top of a hierarchy |
| **Key / label** | `COL_CYAN` | 81 | Field names, subcommand names — the left column you scan |
| **Value** | `COL_BOLD` | bold, default fg | The primary datum — versions, counts, the subject of the line |
| **Success** | `COL_GREEN` | 114 | ok · clean · match · enabled · healthy (with `✔`) |
| **Warning** | `COL_YELLOW` | 220 | Attention, not failure — dirty · pending · degraded (with `⚠`) |
| **Error** | `COL_RED` | 203 | Failure or a critical alert (with `✖`); keep rare so it stays loud |
| **Muted** | `COL_GRAY` | 240 | Metadata, hints, timestamps, separators, disabled — present but recessive |
| **Accent** | `COL_BLUE` (or `COL_PURPLE`) | 75 / 141 | Interactive & navigational — prompts, branch names, links, selectable items |

`COL_ORANGE` is reserved for Trove's `trove_running` step marker; `COL_WHITE`,
`COL_BLACK`, `COL_DARK_GREEN` exist in the palette but are not part of the everyday
role set — don't reach for them without a reason.

---

## Glyph vocabulary

Each glyph is locked to a role's color. Shape carries meaning where color can't.

| Glyph | Role | Meaning |
|---|---|---|
| `✔` | Success (green) | ok / match / present |
| `✖` | Error (red) | failure |
| `⚠` | Warning (yellow) | attention |
| `·` | Muted (gray) | neutral bullet / no-match |
| `➤` | default / green | result, action taken (`trove_ok`) |
| `✪` | Header (bold purple) | interactive / prompt (`trove_bot`) |
| `●` | green / yellow / red | status dot — up / degraded / down |
| `→` `←` `↑` `↓` | muted | flow & annotation — `match →`, `← MATCH`, ahead/behind |

The `trove_log` levels map fixed glyphs already: TRACE `➤`, DEBUG `✱`, INFO `✔`,
WARN `⚠`, ERROR `✖`, FATAL `‼` (see [API.md](./API.md#logging-functions)).

---

## Weight & style

SGR attributes are the second channel. Reach down this ladder only as emphasis
climbs — most lines need none.

| Attribute | SGR | Use | Caveat |
|---|---|---|---|
| **Bold** (`COL_BOLD`) | 1 | Everyday emphasis — versions, the matched value, a key figure | — |
| Dim | 2 | Softer mute than gray for inline secondary text | Not all terminals render it |
| _Italic_ | 3 | Optional annotation / caption | Inconsistent support — never load-bearing |
| Underline | 4 | Actionable paths & URLs, or the live heading | Sparingly |
| Reverse | 7 | Max severity only — status bar, selected row, blocking alert | Rare by design |

---

## Structure

Two header styles, chosen by output type. Both put the title in the **Header** role.

**A · Inline header** — the default for status / info output. Title, then an
aligned key/value block:

```
Paths                          # Header (bold purple)
  install     /opt/dotFiles_data      # key = cyan, value aligned
  config      /opt/dotFiles_data/.config
```

**B · Ruled header** — for dense help with many command groups. A rule, the title,
a rule:

```
──────────────────────────────
 CONFIGURATION                 # Header (bold purple); rules in gray
──────────────────────────────
  config        Show config    # command = cyan, description = muted
  config init   Initialize it
```

> ### The leading-space rule
>
> A ruled heading gets **exactly one leading space** before the word —
> `␣CONFIGURATION`, not `CONFIGURATION` flush to the margin. That single space
> lifts the title off the rule so it reads as a deliberate, typeset label rather
> than a run-on. It is the difference between the block looking designed and
> looking accidental.

**Inline is the ecosystem default.** dotFiles and Beskar both use inline headers
throughout; reach for the ruled form only when a screen is so dense that inline
titles don't separate the groups clearly enough.

**Alignment.** Keys go in a fixed-width column (`printf '%-Ns'`), two-space base
indent under a header. Separate inline fields with a muted `·`. Cap decorative
rules at a sensible width (≈ 73 columns) so they don't wrap.

**Full commands take a `#` comment; bare tokens don't.** When a row's left column
is a full, runnable command, write its description as a muted **`#` comment** — so
the whole line is valid, copy-pasteable shell. This holds in `Examples:` blocks
*and* in command-reference tables (e.g. Beskar's help):

```
beskar config                       # Show current configuration
beskar <project> get NAME           # Read a variable
```

When the left column is instead a **bare reference token** — a subcommand name,
flag, or argument placeholder that isn't runnable on its own — use a plain aligned
description (no `#`):

```
Commands:
  on               Enable the trailer
  --setup          Create the symlink
  issue [domain]   Issue a cert
```

Put the command in the Key role (cyan) and the `# comment` in muted gray. If a
description won't fit inline, drop it to its own indented line beneath the command
instead — never leave a bare description that looks like a broken command.

**Source references are first-class.** A `Library:` / `Registry:` / `Resolver:`
pointer — a file path plus its key functions — gets full section weight: the label
in the **Header** role (bold purple), file paths in the **Key** role (cyan), the
function list plain. Separate path from functions with `—` (a definition, not a
runnable command, so no `#`), and **align the `—`** down the block:

```
Library:                          ← Header role (bold purple)
  lib/beskar_config_commands.zsh — beskar_config_init, validate, edit, show
  lib/beskar_config.zsh          — beskar_load_config, beskar_validate_config, …
      ↑ paths in the Key role (cyan)   ↑ em-dashes aligned; functions plain
```

One file → inline (`Library: lib/foo.zsh — fn, fn`); several → the block form above,
paths aligned in a column.

---

## Channels

Where output goes matters as much as how it looks.

- **Status, progress, errors → the `trove_*` loggers → stderr.** They apply the
  role color and glyph for you. Never hand-roll status with raw `echo`.
- **Structured, tabular & help text → `echo` / `printf` with `COL_*` → stdout.**
  This is the *only* place you write color yourself.
- **`--json` / `--porcelain` → zero color, ever.** Machine output must stay
  byte-stable. Gate it at the top of the command.
- **Honor `NO_COLOR` and non-TTY stdout.** Degrade to plain text; glyph shapes
  still carry meaning.

**The escape-placement rule.** `COL_*` are literal `\033[…]` sequences. They work
in an `echo` string or a `printf` **format** position; passed as a `%s` **argument**
they print as raw escape text.

```zsh
printf "  ${COL_CYAN}%-12s${COL_RESET} %s\n" "$key" "$val"   # correct
printf "%s%s\n" "$COL_CYAN" "$key"                           # WRONG — prints \033[…]
```

Always close a colored span with `COL_RESET`.

**Materialize before `print -r`.** `COL_*` are *literal* `\033[…]` strings — `echo`
and a `printf` format position interpret them into real escape bytes, but `print -r`
(raw) does **not**; it emits the backslashes verbatim. If you must print raw lines
(e.g. a filter that must not touch the payload), interpret the codes once up front —
`hdr="$(print -- "$COL_BOLD_PURPLE")"` — then use `$hdr` with `print -r`.

**Selecting a theme.** The active palette is chosen with `trove_set_colorscheme
<monokai|solarized|nord|dracula|gruvbox>` (see [API.md](./API.md#color-management)).
Bridge it to your own env var at startup so users can pick: dotFiles bridges
`DF_COLOR_SCHEME`, Beskar bridges `BESKAR_COLOR_SCHEME` — each defaults to `monokai`
and calls `trove_set_colorscheme` once Trove is sourced. Because code references
roles (`COL_*`), not the theme's hex, every scheme just works with no other change.

---

## Worked example

Beskar's help, before and after — same information, brought into the standard.
Uppercase-plain headings become **inline** Header-role titles; the `====` slab and
`━━━` rules are dropped; command names take the Key role; descriptions become `#`
comments; the `Library:` pointer gets first-class weight.

**Before**

```
Beskar - Secure Environment Variable Manager
=============================================
Armory: ~/.config/beskar/armory

USAGE:
  beskar [--json|--porcelain] <command> [arguments]

CONFIGURATION
  beskar config          Show current configuration
```

**After** — Beskar's actual output (color annotated in comments)

```
beskar — Secure Environment Variable Manager    # "beskar" bold-cyan, tagline plain
  armory: ~/.config/beskar/armory               # muted

Usage:                                          # Header (bold purple)
  beskar [--json|--porcelain] <command> [args]  # command in the Key role (cyan)

Configuration                                   # Header — inline, no rules
  beskar config        # Show current configuration   # cmd cyan, # comment muted
  beskar config init   # Initialize config file

Library:                                        # Header — source reference
  lib/beskar_config.zsh — beskar_load_config, …  # path cyan, functions plain
```

The dotFiles `status` and `wallpaper status` screens are the reference
implementations of every role working at once.

---

## Conformance

The mechanical rule — **no hardcoded `\033[…]` literals in consumer code, use
`COL_*`** — is enforced by `tools/lint-output-style.sh` (see
[STYLE.md](./STYLE.md) for the full checklist an agent applies during review).

```sh
tools/lint-output-style.sh              # scan this repo
tools/lint-output-style.sh --root ../beskar   # scan another CLI
```

Everything else — correct role choice, the leading-space heading, closed spans,
color-free machine output — is verified against the [STYLE.md](./STYLE.md)
checklist during review.
