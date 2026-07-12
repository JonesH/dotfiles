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
# shellcheck disable=SC2034  # DF_QUIET is consumed by the sourced lib.sh log_* helpers
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
    script:*) local url="${spec#script:}" sh_args=""
             # Some install scripts assume bash, not sh; -y makes rustup unattended.
             case "$bin" in rustup) sh_args="-s -- -y" ;; esac
             if [ "$ALLOW_SCRIPTS" = 1 ] && [ "$DRY" != 1 ]; then
               log "  curl -LsSf $url | bash $sh_args"
               # sh_args must word-split (rustup gets `-s -- -y`, the only prompting installer)
               # shellcheck disable=SC2086
               curl -LsSf "$url" | bash $sh_args || log_warn "$bin installer failed"
             else
               SCRIPTS+=("$bin	curl -LsSf $url | bash $sh_args")
             fi ;;
    builtin) log_skip "$bin (builtin on $OS)" ;;
    manual)  MANUAL+=("$bin: $notes") ;;
    -|"")    log_skip "$bin (n/a on $OS)" ;;
    *)       log_warn "$bin: unknown method '$spec'" ;;
  esac
}

[ "$DRY" = 1 ] && log "install-tools — os=$OS (dry run)" || log "install-tools — os=$OS"

# --- ensure Homebrew on Linux when the debian column uses brew: ------------
# macOS bootstraps brew separately; DOTFILES_SKIP_BREW=1 skips this entirely.
# Only runs when tools.tsv's debian column actually needs brew, so a box that
# uses pure apt/cargo never pulls Homebrew.
if [ "$OS" != darwin ] && [ "${DOTFILES_SKIP_BREW:-0}" != 1 ] \
   && awk -F'\t' '$3 ~ /^(brew|cask):/ {f=1} END{exit !f}' "$TSV"; then
  # shellcheck disable=SC2046  # deliberate: expands to --check or to nothing
  "$DOTFILES_DIR/install/install-brew.sh" $([ "$DRY" = 1 ] && echo --check) || true
  [ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# --- tools.tsv -------------------------------------------------------------
while IFS=$'\t' read -r bin mac deb notes; do
  [ -z "${bin:-}" ] && continue
  case "$bin" in \#*) continue ;; esac
  have "$bin" && { log_skip "$bin (present)"; continue; }
  case "$OS" in darwin) install_one "$bin" "$mac" "${notes:-}" ;; *) install_one "$bin" "$deb" "${notes:-}" ;; esac
done < "$TSV"

# batch apt install (non-interactive; never hang on a sudo/apt prompt)
if [ "${#APT_PKGS[@]}" -gt 0 ]; then
  if [ "$DRY" = 1 ]; then
    log_ok "(dry) apt-get install -y ${APT_PKGS[*]}"
  else
    # Pick a privilege prefix without ever prompting: root → none; else sudo -n
    # (passwordless). If neither works, defer to a manual step instead of blocking.
    if [ "$(id -u)" = 0 ]; then SUDO=""
    elif sudo -n true 2>/dev/null; then SUDO="sudo -n"
    else SUDO=""; MANUAL+=("apt: run yourself: sudo apt-get install -y ${APT_PKGS[*]}"); fi
    if [ "$SUDO" != "" ] || [ "$(id -u)" = 0 ]; then
      DEBIAN_FRONTEND=noninteractive $SUDO apt-get update \
        && DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y \
             -o Dpkg::Options::=--force-confold "${APT_PKGS[@]}" \
        || log_warn "apt install failed (see output above)"
    fi
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
          # strip inline "# comment" from the trailing args, keep flags like --python 3.12
          rest="${rest%%#*}"
          # word-split $rest so flags like `--python 3.12` pass through as separate args
          # shellcheck disable=SC2086
          if [ "$DRY" = 1 ]; then log_ok "(dry) uv tool install $name $rest"
          else uv tool install "$name" $rest || log_warn "uv tool install $name failed"; fi ;;
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
