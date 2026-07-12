#!/usr/bin/env bash
# sync.sh — converge this host with the dotfiles remote. Run anytime as `dfsync`.
# NOTE: no `set -e` — failures are handled explicitly; this must never crash a shell.
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
. "$DOTFILES_DIR/install/lib.sh"

CACHE="$HOME/.cache/dotfiles"; mkdir -p "$CACHE"
LOG="$CACHE/sync.log"
CONFLICT_FLAG="$CACHE/CONFLICT"
BRANCH="${DOTFILES_BRANCH:-main}"

ts()  { date -u +%FT%TZ; }
say() { printf '%s %s\n' "$(ts)" "$*" >> "$LOG"; }

cd "$DOTFILES_DIR" || exit 0

# timeout wrapper: gtimeout (macOS/coreutils) or timeout (Linux); else run bare
TIMEOUT=""
command -v timeout  >/dev/null 2>&1 && TIMEOUT="timeout 20"
command -v gtimeout >/dev/null 2>&1 && TIMEOUT="gtimeout 20"

# 1) offline guard
if ! $TIMEOUT git ls-remote --exit-code origin >/dev/null 2>&1; then
  say "offline or remote unreachable — skip"; exit 0
fi

# 2) commit local tracked changes (never -A)
if ! git diff --quiet || ! git diff --cached --quiet; then
  # avoid committing mid-edit: skip if any tracked file changed <2 min ago
  recent="$(find . -path ./.git -prune -o -type f -mmin -2 -print 2>/dev/null | head -1 || true)"
  if [ -n "$recent" ]; then
    say "recent edit ($recent) — deferring commit to next cycle"
  else
    git add -u
    if git commit -m "auto: sync from $(hostname -s 2>/dev/null || hostname) $(ts)" >>"$LOG" 2>&1; then
      say "committed local changes"
    else
      say "commit failed/blocked (secret guard?) — manual review needed"
    fi
  fi
fi

# 3) integrate remote — fast-forward, else rebase, else stop and flag a conflict
if $TIMEOUT git pull --ff-only origin "$BRANCH" >>"$LOG" 2>&1; then
  :
elif $TIMEOUT git pull --rebase origin "$BRANCH" >>"$LOG" 2>&1; then
  say "integrated via rebase"
else
  git rebase --abort >/dev/null 2>&1 || true
  : > "$CONFLICT_FLAG"
  say "CONFLICT — sync paused; resolve in $DOTFILES_DIR then run: dfsync"
  exit 1
fi
rm -f "$CONFLICT_FLAG"

# 4) if the pull changed the tree, re-apply symlinks (picks up any new files)
if git rev-parse ORIG_HEAD >/dev/null 2>&1 && ! git diff --quiet ORIG_HEAD HEAD 2>/dev/null; then
  "$DOTFILES_DIR/install/bootstrap.sh" --quiet >>"$LOG" 2>&1 || say "bootstrap re-run failed"
fi

# 5) push
if $TIMEOUT git push origin "$BRANCH" >>"$LOG" 2>&1; then
  say "pushed"
else
  say "push failed (will retry next cycle)"
fi
exit 0
