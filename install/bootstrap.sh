#!/usr/bin/env bash
# bootstrap.sh — back up existing dotfiles and symlink this repo into $HOME.
# Idempotent and safe to re-run. See docs/BOOTSTRAP.md.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
. "$DOTFILES_DIR/install/lib.sh"

# --- flags -----------------------------------------------------------------
DO_PACKAGES=0
for arg in "$@"; do
  case "$arg" in
    --check|--dry-run) DF_DRYRUN=1 ;;
    --packages)        DO_PACKAGES=1 ;;
    --quiet)           DF_QUIET=1 ;;
    -h|--help)
      cat <<EOF
Usage: bootstrap.sh [--check] [--packages] [--quiet]
  --check      dry run: show what would happen, change nothing
  --packages   also install the package baseline (brew bundle / apt)
  --quiet      minimal output
EOF
      exit 0 ;;
    *) log_warn "unknown arg: $arg" ;;
  esac
done
export DF_DRYRUN DF_QUIET

OS="$(os_detect)"
DF_BACKUP_DIR="$HOME/.dotfiles-backup/$(date -u +%Y%m%dT%H%M%SZ)"
export DF_BACKUP_DIR
log "dotfiles bootstrap — os=$OS repo=$DOTFILES_DIR"
[ "$DF_DRYRUN" = 1 ] && log_warn "dry run: no changes will be made"

# --- required directories --------------------------------------------------
for d in "$HOME/.config/bash/os" "$HOME/.config/git" "$HOME/.config/zed" \
         "$HOME/.local/bin"; do
  [ "$DF_DRYRUN" = 1 ] || mkdir -p "$d"
done
[ "$DF_DRYRUN" = 1 ] || { mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"; }

# --- symlink table: "<repo-relpath>|<home-relpath>" ------------------------
LINKS="
bash/bashrc|.bashrc
bash/bash_profile|.bash_profile
bash/profile|.profile
bash/env.sh|.config/bash/env.sh
bash/paths.sh|.config/bash/paths.sh
bash/aliases.sh|.config/bash/aliases.sh
bash/functions.sh|.config/bash/functions.sh
bash/prompt.sh|.config/bash/prompt.sh
bash/os/darwin.sh|.config/bash/os/darwin.sh
bash/os/linux.sh|.config/bash/os/linux.sh
bash/os/wsl.sh|.config/bash/os/wsl.sh
zsh/zshrc|.zshrc
zsh/zshenv|.zshenv
zsh/zprofile|.zprofile
git/gitconfig|.gitconfig
git/gitignore_global|.config/git/ignore
ssh/config|.ssh/config
zed/keymap.json|.config/zed/keymap.json
"
while IFS='|' read -r src rel; do
  [ -z "$src" ] && continue
  link_file "$DOTFILES_DIR/$src" "$HOME/$rel"
done <<< "$LINKS"

# hand-authored scripts → ~/.local/bin (skip docs)
for s in "$DOTFILES_DIR"/scripts/*; do
  [ -f "$s" ] || continue
  case "$(basename "$s")" in README.md|*.md) continue ;; esac
  link_file "$s" "$HOME/.local/bin/$(basename "$s")"
done

# --- git secret-guard hook (scoped to THIS repo, not global) ---------------
if [ "$DF_DRYRUN" = 1 ]; then
  log_ok "(dry) would set repo-local core.hooksPath -> install/git-hooks"
else
  chmod +x "$DOTFILES_DIR/install/git-hooks/pre-commit" 2>/dev/null || true
  git -C "$DOTFILES_DIR" config --local core.hooksPath install/git-hooks
  log_ok "git core.hooksPath (repo-local) -> install/git-hooks"
fi

# --- seed local secrets file (never overwrite) -----------------------------
if [ ! -f "$HOME/.bash_tokens" ]; then
  if [ "$DF_DRYRUN" = 1 ]; then
    log_ok "(dry) would seed ~/.bash_tokens from example"
  else
    cp "$DOTFILES_DIR/secrets.example/bash_tokens.example" "$HOME/.bash_tokens"
    chmod 600 "$HOME/.bash_tokens"
    log_ok "seeded ~/.bash_tokens (chmod 600) — fill in your tokens"
  fi
else
  log_skip "~/.bash_tokens (exists)"
fi

# --- optional package baseline ---------------------------------------------
if [ "$DO_PACKAGES" = 1 ] && [ "$DF_DRYRUN" != 1 ]; then
  case "$OS" in
    darwin)
      if command -v brew >/dev/null 2>&1; then
        log "installing Homebrew packages…"
        brew bundle --file "$DOTFILES_DIR/packages/Brewfile"
      else
        log_warn "brew not found; skipping --packages"
      fi ;;
    linux|wsl)
      if command -v apt-get >/dev/null 2>&1; then
        log "installing apt packages…"
        pkgs="$(grep -vE '^\s*#|^\s*$' "$DOTFILES_DIR/packages/apt.txt")"
        sudo apt-get update && sudo apt-get install -y $pkgs
      else
        log_warn "apt-get not found; skipping --packages"
      fi ;;
  esac
fi

if [ "$DF_DRYRUN" = 1 ]; then log_ok "bootstrap complete (dry run)"; else log_ok "bootstrap complete"; fi
[ "$DF_DRYRUN" != 1 ] && [ -d "$DF_BACKUP_DIR" ] && log "backups: $DF_BACKUP_DIR"
exit 0
