# Documentation index

Top-level map of Trove's documentation. Trove is the base tier (logging, colors,
Atlas discovery, helpers, date, monitoring, requirements) of the
Trove/Beskar/dotFiles stack.

| Path | Contents |
|---|---|
| [`../README.md`](../README.md) | Project overview + cold-start install |
| [`../AGENTS.md`](../AGENTS.md) | Authoritative agent instructions (canonical; `CLAUDE.md` symlinks to it) |
| [`../DECISIONS.md`](../DECISIONS.md) | Locked architectural decisions (`Dxxx`) |
| [`../CHANGELOG.md`](../CHANGELOG.md) | Keep-a-changelog release history |
| [`features/INDEX.md`](features/INDEX.md) | Feature catalog (capabilities + status) |
| [`API.md`](API.md) | Full function reference (all `trove_*` functions + the file sink) |
| [`STYLE.md`](STYLE.md) | Output/logging style rules |
| [`cli-style-guide.md`](cli-style-guide.md) | CLI output style guide (also rendered `cli-style-guide.html`) |
| [`migrations/`](migrations/) | Per-release migration notes (e.g. `1.2.0.md`) |

**Gates:** `zsh tools/lint-zsh-syntax.sh` · `bash tools/lint-zsh-locals.sh` ·
`bash tools/lint-output-style.sh` · `bash tests/run_tests.sh` (zunit).
