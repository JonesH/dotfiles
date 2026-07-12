#!/usr/bin/env bash
# install-tools.sh — install the CLI tools in packages/tools.tsv the right way
# per-OS, and the uv tools in packages/uv-tools.txt. Idempotent (skips tools
# already on PATH). brew/cask/apt/cargo are automated; script:/manual entries are
# printed for you to run (or pass --allow-scripts to run the curl|sh ones).
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
. "$DOTFILES_DIR/install/lib.sh"

DRY=0; ALLOW_SCRIPTS=0
for a in "$@"; do
  case "$a" in
    --check|--dry-run) DRY=1 ;;
    --allow-scripts)   ALLOW_SCRIPTS=1 ;;
    --quiet)           DF_QUIET=1 ;;
    -h|--help) echo "usage: install-tools.sh [--check] [--allow-scripts] [--quiet]"; exit 0 ;;
    *) log_warn "unknown arg: $a" ;;
  esac
done

OS="$(os_detect)"
TSV="$DOTFILES_DIR/packages/tools.tsv"
UVL="$DOTFILES_DIR/packages/uv-tools.txt"
have() { command -v "$1" >/dev/null 2>&1; }

APT_PKGS=(); SCRIPTS=(); MANUAL=()

install_one() {
  local bin="$1" spec="$2" notes="$3"
  case "$spec" in
    brew:*)  have brew  || { MANUAL+=("$bin: install Homebrew first"); return; }
             if [ "$DRY" = 1 ]; then log_ok "(dry) brew install ${spec#brew:}"; else brew install "${spec#brew:}"; fi ;;
    cask:*)  have brew  || { MANUAL+=("$bin: install Homebrew first"); return; }
             if [ "$DRY" = 1 ]; then log_ok "(dry) brew install --cask ${spec#cask:}"; else brew install --cask "${spec#cask:}"; fi ;;
    apt:*)   APT_PKGS+=("${spec#apt:}") ;;
    cargo:*) have cargo || { MANUAL+=("$bin: install rustup/cargo first"); return; }
             if [ "$DRY" = 1 ]; then log_ok "(dry) cargo install ${spec#cargo:}"; else cargo install "${spec#cargo:}"; fi ;;
    script:*) local url="${spec#script:}"
             if [ "$ALLOW_SCRIPTS" = 1 ] && [ "$DRY" != 1 ]; then
               log "  curl -LsSf $url | sh"; curl -LsSf "$url" | sh
             else
               SCRIPTS+=("$bin	curl -LsSf $url | sh")
             fi ;;
    builtin) log_skip "$bin (builtin on $OS)" ;;
    manual)  MANUAL+=("$bin: $notes") ;;
    -|"")    log_skip "$bin (n/a on $OS)" ;;
    *)       log_warn "$bin: unknown method '$spec'" ;;
  esac
}

[ "$DRY" = 1 ] && log "install-tools — os=$OS (dry run)" || log "install-tools — os=$OS"

# --- tools.tsv -------------------------------------------------------------
while IFS=$'\t' read -r bin mac deb notes; do
  [ -z "${bin:-}" ] && continue
  case "$bin" in \#*) continue ;; esac
  if [ "$bin" = nvm ]; then [ -d "$HOME/.nvm" ] && { log_skip "nvm (present)"; continue; }; fi
  have "$bin" && { log_skip "$bin (present)"; continue; }
  case "$OS" in darwin) install_one "$bin" "$mac" "${notes:-}" ;; *) install_one "$bin" "$deb" "${notes:-}" ;; esac
done < "$TSV"

# batch apt install
if [ "${#APT_PKGS[@]}" -gt 0 ]; then
  if [ "$DRY" = 1 ]; then
    log_ok "(dry) sudo apt-get install -y ${APT_PKGS[*]}"
  else
    sudo apt-get update && sudo apt-get install -y "${APT_PKGS[@]}"
  fi
fi

# --- uv-tools.txt ----------------------------------------------------------
if [ -f "$UVL" ]; then
  if have uv; then
    while read -r kind name rest; do
      [ -z "${kind:-}" ] && continue
      case "$kind" in \#*) continue ;; esac
      case "$kind" in
        install)
          if [ "$DRY" = 1 ]; then log_ok "(dry) uv tool install $name"
          else uv tool install "$name" || log_warn "uv tool install $name failed"; fi ;;
        uvx)
          # materialise ~/.local/bin/<name> that execs the uvx command
          local_bin="$HOME/.local/bin/$name"
          if [ -e "$local_bin" ] && ! grep -q '# dotfiles-uvx-wrapper' "$local_bin" 2>/dev/null; then
            log_skip "uvx wrapper $name (a non-wrapper file exists)"; continue
          fi
          if [ "$DRY" = 1 ]; then log_ok "(dry) wrapper ~/.local/bin/$name -> $rest \"\$@\""
          else
            mkdir -p "$HOME/.local/bin"
            { printf '#!/usr/bin/env bash\n# dotfiles-uvx-wrapper\nexec %s "$@"\n' "$rest"; } > "$local_bin"
            chmod +x "$local_bin"; log_ok "wrapper ~/.local/bin/$name"
          fi ;;
        *) log_warn "uv-tools: unknown kind '$kind'" ;;
      esac
    done < "$UVL"
  else
    MANUAL+=("uv-tools: install uv first (see tools.tsv), then re-run")
  fi
fi

# --- report script/manual entries -----------------------------------------
if [ "${#SCRIPTS[@]}" -gt 0 ]; then
  log ""; log "Install-by-script (run yourself, or re-run with --allow-scripts):"
  printf '  %s\n' "${SCRIPTS[@]}"
fi
if [ "${#MANUAL[@]}" -gt 0 ]; then
  log ""; log "Manual steps (see notes in tools.tsv):"
  printf '  %s\n' "${MANUAL[@]}"
fi
exit 0
