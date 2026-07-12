# zed/

- **`keymap.json`** — versioned + symlinked to `~/.config/zed/keymap.json`. Stable, no secrets.
- **`settings.json`** — **deferred**. The live file embeds `ssh_connections` (your remote
  hosts + open project paths). That is (a) an infra map and (b) **volatile state Zed rewrites
  as you open/close remote projects** — symlinking it would cause constant auto-sync churn and
  cross-machine conflicts.

## Intended approach for settings.json (when we do it)

Version the **editor preferences** only, with `ssh_connections` stripped to `[]` (remote
project lists stay machine-local). Because Zed has no `include` mechanism, this needs either
a generated/merged settings file or an accepted "ssh_connections not synced" trade-off —
a small design decision to make deliberately rather than by default.
