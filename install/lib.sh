# lib.sh — shared helpers for bootstrap.sh / sync.sh. Sourced, not executed.

# Repo root (this file lives in install/)
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)}"

# --- logging ---------------------------------------------------------------
: "${DF_QUIET:=0}"
_c_reset=$'\033[0m'; _c_grn=$'\033[32m'; _c_yel=$'\033[33m'; _c_red=$'\033[31m'; _c_dim=$'\033[2m'
log()        { [ "$DF_QUIET" = 1 ] || printf '%s\n' "$*"; }
log_ok()     { [ "$DF_QUIET" = 1 ] || printf '%s✓%s %s\n' "$_c_grn" "$_c_reset" "$*"; }
log_skip()   { [ "$DF_QUIET" = 1 ] || printf '%s· skip%s %s\n' "$_c_dim" "$_c_reset" "$*"; }
log_backup() { printf '%s↳ backup%s %s\n' "$_c_yel" "$_c_reset" "$*"; }
log_warn()   { printf '%s! %s%s\n' "$_c_yel" "$*" "$_c_reset" >&2; }
log_err()    { printf '%s✗ %s%s\n' "$_c_red" "$*" "$_c_reset" >&2; }

# --- OS detection ----------------------------------------------------------
os_detect() {
  case "$(uname -s)" in
    Darwin) echo darwin ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then echo wsl; else echo linux; fi ;;
    *) echo unknown ;;
  esac
}

# --- symlinking ------------------------------------------------------------
# Set by bootstrap before linking; a per-run backup dir (created lazily).
: "${DF_BACKUP_DIR:=}"
: "${DF_DRYRUN:=0}"

_backup() {
  # Move an existing path into the timestamped backup dir, preserving its
  # location relative to $HOME.
  local f="$1" rel dst
  rel="${f#"$HOME"/}"
  dst="$DF_BACKUP_DIR/$rel"
  if [ "$DF_DRYRUN" = 1 ]; then log_backup "(dry) $f -> $dst"; return 0; fi
  mkdir -p "$(dirname "$dst")"
  mv "$f" "$dst"
  log_backup "$f -> $dst"
}

link_file() {
  # link_file <repo-src-abs> <home-dest-abs>
  local src="$1" dest="$2"
  if [ ! -e "$src" ]; then log_warn "missing source, skipping: $src"; return 0; fi
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    log_skip "$dest"; return 0
  fi
  if [ "$DF_DRYRUN" = 1 ]; then
    [ -e "$dest" ] || [ -L "$dest" ] && log_backup "(dry) would back up $dest"
    log_ok "(dry) link $dest -> $src"; return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then _backup "$dest"; fi
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  log_ok "link $dest -> $src"
}
