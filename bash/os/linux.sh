# os/linux.sh — Debian/Linux-specific setup (sourced after the shared modules)
# Relies on _path_prepend/_path_append from paths.sh.

# --- Linuxbrew (optional) --------------------------------------------------
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# --- System bash-completion ------------------------------------------------
if [ -r /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -r /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# --- Compilation flags -----------------------------------------------------
export MAKEFLAGS="-j$(nproc 2>/dev/null || echo 4)"

# On Debian the `bat` package installs the binary as `batcat`
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  alias bat='batcat'
fi

# --- Linux variants of the system-info aliases ----------------------------
alias meminfo='free -h'
alias cpuinfo='grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed "s/^ //"'
alias ports='ss -tlnp'

export PATH
