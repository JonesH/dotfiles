# dotfiles

A **plain git** developer environment — no chezmoi, Stow, or symlink manager. The
repository is the single source of truth; a bootstrap script backs up your existing
files and symlinks the repo's copies into `$HOME`. Works on **macOS, Debian, and
Debian-on-WSL** from the same files.

## Quick start (new machine)

```sh
git clone git@github.com:JonesH/dotfiles.git ~/dotfiles
~/dotfiles/install/bootstrap.sh          # backs up existing files, then symlinks
cp ~/dotfiles/secrets.example/bash_tokens.example ~/.bash_tokens && chmod 600 ~/.bash_tokens
$EDITOR ~/.bash_tokens                    # fill in your tokens
exec $SHELL -l                            # reload
# optional: install the package baseline
~/dotfiles/install/bootstrap.sh --packages
```

## How it stays in sync

Configs are **symlinks into this repo**, so a `git pull` updates your live config
instantly. A throttled, backgrounded hook in your shell runs `install/sync.sh` (at
most once every few hours): it commits local changes to tracked files only
(`git add -u`, never `-A`), pulls conflict-safely, re-runs bootstrap if new files
arrived, and pushes. A pre-commit **secret guard** blocks tokens/keys from ever being
committed. You only get interrupted on a genuine conflict (a red `⚠df` in your prompt).

Run a sync by hand anytime with `dfsync` (alias for `install/sync.sh`).

## Layout

| Path | What |
|---|---|
| `install/` | `bootstrap.sh`, `sync.sh`, `update.sh`, `lib.sh`, `git-hooks/pre-commit` |
| `bash/` | thin `bashrc` + shared modules (`env`,`paths`,`aliases`,`functions`,`prompt`) + `os/{darwin,linux,wsl}.sh` |
| `zsh/` | thin zsh that reuses the shared bash modules (secondary shell) |
| `git/` | `gitconfig`, `gitignore_global` |
| `ssh/` | sanitized `config` (infra hosts live in untracked `~/.ssh/config.local`) |
| `zed/` | `keymap.json` (settings deferred — see `zed/README.md`) |
| `scripts/` | hand-authored `~/.local/bin` helpers |
| `packages/` | optional `Brewfile` / `apt.txt` baselines |
| `secrets.example/` | templates for `~/.bash_tokens`, `~/.ssh/config.local`, `~/.gitconfig.local` |
| `claude/`, `mcp/`, `claude-mem/` | **deferred** — see each README (secret/scope reasons) |
| `docs/` | architecture, bootstrap, adding a host, platforms, conventions |

## Secrets

Nothing secret is tracked. Real values live in untracked files that the config sources
if present: `~/.bash_tokens` (API tokens), `~/.ssh/config.local` (real hosts),
`~/.gitconfig.local` (identity overrides), `~/.bashrc.local` / `~/.zshrc.local`
(per-host shell tweaks). Templates for each are in `secrets.example/`.

See [`docs/`](docs/) for the full architecture and conventions.
