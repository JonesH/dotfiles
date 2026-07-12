# os/wsl.sh — Debian-on-WSL setup. Inherits everything from linux.sh, then adds
# Windows interop conveniences. Sourced after the shared modules.

# Reuse all Linux setup
_here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
[ -r "$_here/linux.sh" ] && . "$_here/linux.sh"
unset _here

# --- WSL interop -----------------------------------------------------------
# Open URLs / files with the Windows default handler
if command -v wslview >/dev/null 2>&1; then
  export BROWSER=wslview
fi

# Make Windows-side npm/user tools reachable if present (kept optional/guarded)
if [ -n "${WSL_DISTRO_NAME:-}" ] && command -v cmd.exe >/dev/null 2>&1; then
  _winuser="$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r')"
  [ -n "$_winuser" ] && _path_append "/mnt/c/Users/$_winuser/AppData/Local/Microsoft/WindowsApps"
  unset _winuser
fi

export PATH
