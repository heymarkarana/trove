# Feature catalog

Master catalog of Trove capabilities and their status. Trove is a **sourced
library tier** (Dais `library` archetype, D008): consumers `source
lib/trove_init.zsh` and call `trove_*` functions; three facades expose Trove to
non-shell callers. Function-level reference lives in [`../API.md`](../API.md).

| Feature | Surface | Status | Reference |
|---|---|---|---|
| Logging (levels, section headers, `trove_silent_run`) | `lib/trove_logging.zsh` | **shipped** | [API.md](../API.md) |
| Always-on verbose file sink (secret-scrubbed, per-app/per-actor, retention) | `lib/trove_logging.zsh`, env `TROVE_LOG_*` | **shipped** (v1.2.0) | [API.md](../API.md) → Verbose File Sink; [migrations/1.2.0.md](../migrations/1.2.0.md) |
| Color schemes | `lib/trove_colors.zsh` | **shipped** | [API.md](../API.md) |
| Atlas discovery (env → registry → default; tier-pure `ATLAS_*`) | `lib/trove_atlas.zsh` | **shipped** (v1.0.0) | [API.md](../API.md) |
| System/CLI helpers (paths, permissions, platform, `stat_*`, ssh url) | `lib/trove_helpers.zsh` | **shipped** | [API.md](../API.md) |
| Date/time formatting + arithmetic | `lib/trove_date.zsh` | **shipped** | [API.md](../API.md) |
| System monitoring (cpu/mem/disk/uptime, metric send) | `lib/trove_monitoring.zsh` | **shipped** | [API.md](../API.md) |
| Requirements / dependency checking + optional install | `lib/trove_requirements.zsh` | **shipped** | [API.md](../API.md); `examples/requirements.yaml` |
| `klog` — logging facade for non-shell callers | `bin/klog` | **shipped** | [API.md](../API.md) |
| `kreq` — requirements facade for non-shell callers | `bin/kreq` | **shipped** | [API.md](../API.md) |
| `atlas-env` — emit neutral `ATLAS_*` exports (cron/system safe) | `bin/atlas-env` | **shipped** | [API.md](../API.md) |
| Static gates (zsh syntax, combined-local footgun, output style) | `tools/lint-*.sh` | **shipped** | [../INDEX.md](../INDEX.md) |

**Consumption model:** sourced library — no command dispatcher, no `cli/` tree, no
`status`/`version`/`help` subcommands (Dais D010). Load via
`source "${TROVE_HOME}/lib/trove_init.zsh"` (or `df_bootstrap` inside dotFiles).
