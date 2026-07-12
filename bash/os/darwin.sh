# os/darwin.sh — macOS-specific setup (sourced after the shared modules)
# Relies on _path_prepend/_path_append from paths.sh.

# --- Homebrew --------------------------------------------------------------
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Homebrew bash-completion
if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
  . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
fi

# --- Compilation flags (Apple Silicon) — derived, never hardcoded versions --
if command -v brew >/dev/null 2>&1; then
  export ARCHFLAGS="-arch arm64"
  export MAKEFLAGS="-j$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
  _cf="-I$(brew --prefix)/include"
  _lf="-L$(brew --prefix)/lib"
  for _keg in readline libevent lua; do
    _kp="$(brew --prefix "$_keg" 2>/dev/null)" || continue
    [ -n "$_kp" ] && { _cf="$_cf -I$_kp/include"; _lf="$_lf -L$_kp/lib"; }
  done
  export CFLAGS="$_cf"
  export LDFLAGS="$_lf"
  unset _cf _lf _kp _keg
fi

# --- macOS-only PATH entries ----------------------------------------------
_path_prepend "$(brew --prefix 2>/dev/null)/opt/python@3.14/libexec/bin"
_path_prepend "$(brew --prefix 2>/dev/null)/opt/openjdk@23/bin"
_path_prepend "$HOME/.antigravity-ide/antigravity-ide/bin"

# --- Homebrew NVM ----------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
_hbnvm="$(brew --prefix nvm 2>/dev/null)"
if [ -n "$_hbnvm" ] && [ -s "$_hbnvm/nvm.sh" ]; then
  . "$_hbnvm/nvm.sh" --no-use
  [ -s "$_hbnvm/etc/bash_completion.d/nvm" ] && . "$_hbnvm/etc/bash_completion.d/nvm"
fi
unset _hbnvm

# --- macOS variants of the system-info aliases ----------------------------
alias meminfo='top -l 1 -s 0 | grep PhysMem'
alias cpuinfo='sysctl -n machdep.cpu.brand_string'
alias ports='netstat -anv | grep LISTEN'

export PATH
