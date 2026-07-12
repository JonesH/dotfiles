# paths.sh — portable PATH assembly (shared by bash + zsh)
# Every entry is guarded so the same file is safe on macOS, Debian, and WSL.
# Homebrew and other macOS-only paths live in bash/os/darwin.sh.

# Idempotent helpers — only add an existing dir, and never duplicate it.
_path_prepend() { [ -d "$1" ] && case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac; }
_path_append()  { [ -d "$1" ] && case ":$PATH:" in *":$1:"*) ;; *) PATH="$PATH:$1" ;; esac; }

# User-local binaries
_path_append "$HOME/.local/bin"
_path_append "$HOME/bin"

# Rust / Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Deno
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# LM Studio CLI (present on machines where it's installed)
_path_append "$HOME/.lmstudio/bin"

# pyenv (guarded; init only if the binary resolves)
export PYENV_ROOT="$HOME/.pyenv"
_path_prepend "$PYENV_ROOT/bin"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - 2>/dev/null)"
fi

# NVM — standard (non-Homebrew) install location; Homebrew's is handled in os/darwin.sh
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh" --no-use
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi

export PATH
