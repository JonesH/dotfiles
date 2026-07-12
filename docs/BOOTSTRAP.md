# Bootstrap & sync

## `install/bootstrap.sh`

Idempotent, safe to re-run. It:

1. Detects the OS (`darwin` | `linux` | `wsl`).
2. Creates required directories (`~/.config/bash/os`, `~/.config/git`, `~/.local/bin`,
   `~/.ssh` (0700), …).
3. For each entry in its symlink table: if the target is already the correct symlink it
   **skips**; if a real file/other symlink exists it **backs it up** to
   `~/.dotfiles-backup/<UTC-timestamp>/<relpath>` first, then creates the symlink.
4. Sets `git config --global core.hooksPath ~/dotfiles/install/git-hooks` (secret guard).
5. Seeds `~/.bash_tokens` from the example if it's missing (never overwrites).

Flags:
- `--check` — dry run; print intended actions, change nothing.
- `--packages` — also install CLI tools via `install/install-tools.sh` (reads
  `packages/tools.tsv` + `packages/uv-tools.txt`; idempotent, skips tools already on PATH).
- `--quiet` — minimal output (used by the sync engine).

Backups are never deleted automatically — they're your rollback.

## `install/sync.sh` (aka `dfsync`)

1. **Offline guard** — bail quietly if the remote is unreachable.
2. **Commit** tracked changes only (`git add -u`; never `-A`), skipping if a tracked
   file changed in the last 2 minutes (avoid committing mid-edit).
3. **Integrate** — `pull --ff-only`, else `pull --rebase`, else abort + drop a
   `~/.cache/dotfiles/CONFLICT` flag and stop (the only time you're asked to intervene).
4. **Re-apply** — if the pull changed files, run `bootstrap.sh --quiet`.
5. **Push**.

Triggered automatically by a throttled, detached shell hook
(`install/sync-hook.sh`, default every 4h — override `DOTFILES_SYNC_INTERVAL`). Logs to
`~/.cache/dotfiles/sync.log`.

## `install/update.sh`

Runs `sync.sh` in the foreground for an on-demand full sync.
