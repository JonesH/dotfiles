#!/usr/bin/env bash
# install-brew.sh — ensure Homebrew (Linuxbrew) is present on Linux, unattended.
# Homebrew is the uniform installer for the few CLI tools apt ships too old or not
# at all (gh, glow, hcloud, kubectl, deno — the brew: entries in the debian column
# of packages/tools.tsv). No-op on macOS (brew is bootstrapped elsewhere there) and
# idempotent: once /home/linuxbrew/.linuxbrew/bin/brew exists it short-circuits.
#
# Safe for the cloud-init first-login bootstrap on a bare Debian:
#   - runs the official installer NONINTERACTIVE with stdin closed → never hangs;
#   - Homebrew must NOT run as root, so we require a non-root user with passwordless
#     sudo (jones on hcbase); anything else is a soft-skip with a note, never fatal;
#   - the installer needs build-essential procps curl file git pre-installed (it does
#     NOT add them itself), so we apt-install them first.
# Set DOTFILES_SKIP_BREW=1 to skip entirely (used by the fast test harness).
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
. "$DOTFILES_DIR/install/lib.sh"

BREW_BIN=/home/linuxbrew/.linuxbrew/bin/brew
INSTALL_URL=https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh

DRY=0
case "${1:-}" in --check|--dry-run) DRY=1 ;; esac
[ "${DF_DRYRUN:-0}" = 1 ] && DRY=1

ensure_brew() {
  if [ -x "$BREW_BIN" ] || command -v brew >/dev/null 2>&1; then
    log_skip "Homebrew (present)"; return 0
  fi
  if [ "${DOTFILES_SKIP_BREW:-0}" = 1 ]; then
    log_skip "Homebrew (DOTFILES_SKIP_BREW=1)"; return 0
  fi
  case "$(os_detect)" in
    linux|wsl) : ;;
    *) log_skip "Homebrew (Linux-only here; macOS handled separately)"; return 0 ;;
  esac
  # Homebrew refuses to run as root; require a non-root user with passwordless sudo.
  if [ "$(id -u)" = 0 ]; then
    log_warn "Homebrew: cannot install as root — run bootstrap as a non-root user with passwordless sudo"
    return 0
  fi
  if ! sudo -n true 2>/dev/null; then
    log_warn "Homebrew: need passwordless sudo (for prereqs + /home/linuxbrew); skipping"
    return 0
  fi
  if [ "$DRY" = 1 ]; then
    log_ok "(dry) would apt-install build-essential procps curl file git, then run Homebrew installer NONINTERACTIVE"
    return 0
  fi

  log "Homebrew: installing prerequisites (build-essential procps curl file git)…"
  DEBIAN_FRONTEND=noninteractive sudo -n apt-get update \
    && DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y \
         -o Dpkg::Options::=--force-confold build-essential procps curl file git \
    || { log_err "Homebrew: prerequisite apt install failed"; return 1; }

  log "Homebrew: running official installer (NONINTERACTIVE, stdin closed)…"
  local tmp; tmp="$(mktemp)"; trap 'rm -f "$tmp"' RETURN
  if ! curl -fsSL "$INSTALL_URL" -o "$tmp"; then
    log_err "Homebrew: failed to download installer"; return 1
  fi
  if ! NONINTERACTIVE=1 /bin/bash "$tmp" </dev/null; then
    log_err "Homebrew installer failed"; return 1
  fi
  if [ ! -x "$BREW_BIN" ]; then
    log_err "Homebrew installer finished but $BREW_BIN is missing"; return 1
  fi
  # Load into THIS process so a caller that sources us can use brew immediately.
  eval "$("$BREW_BIN" shellenv)"
  log_ok "Homebrew installed ($BREW_BIN)"
}

ensure_brew
