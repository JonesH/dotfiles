# sync-hook.sh — throttled, detached background trigger for install/sync.sh.
# Sourced by interactive bash/zsh. NEVER blocks the prompt.

__df_sync_maybe() {
  local dir="$HOME/dotfiles" cache="$HOME/.cache/dotfiles"
  [ -x "$dir/install/sync.sh" ] || return 0

  local stamp="$cache/last-sync" now last interval
  now="$(date +%s)"
  interval="${DOTFILES_SYNC_INTERVAL:-14400}"   # 4h default
  last=0; [ -f "$stamp" ] && last="$(cat "$stamp" 2>/dev/null || echo 0)"
  [ $(( now - last )) -lt "$interval" ] && return 0

  mkdir -p "$cache"; printf '%s' "$now" > "$stamp"   # stamp BEFORE launch (no double-fire)

  # Detached subshell background — portable (no setsid needed on macOS),
  # no output to the terminal, survives this shell exiting.
  ( "$dir/install/sync.sh" >/dev/null 2>&1 & )
}

__df_sync_maybe
