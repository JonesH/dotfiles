# prompt.sh — bash PS1. The user@host segment is colored by context so you always
# know where you are: root → red (any OS), macOS → cyan, Linux/Debian → magenta.
# cwd is yellow, git branch green. A red "⚠df" marker appears when the dotfiles
# self-sync hit a conflict needing manual resolution (~/.cache/dotfiles/CONFLICT).
# \[ \] (and \001/\002 in the function) mark escapes as zero-width so line editing
# stays correct. Identity color + prompt symbol don't change within a shell, so
# they're resolved once here and baked into PS1.

__df_conflict() {
  [ -f "$HOME/.cache/dotfiles/CONFLICT" ] || return 0
  printf '\001\033[31m\002⚠df \001\033[00m\002'
}

if [ "$EUID" -eq 0 ]; then
  __df_id=31; __df_sym='#'          # root → red + '#', on every OS
else
  __df_sym='$'
  case "$OSTYPE" in
    darwin*) __df_id=36 ;;          # macOS → cyan
    *)       __df_id=35 ;;          # Linux/Debian → magenta
  esac
fi

export PS1="\$(__df_conflict)\[\033[${__df_id}m\]\u@\h \[\033[33m\]\w \[\033[32m\]\$(git branch --show-current 2>/dev/null)\[\033[00m\] ${__df_sym} "
unset __df_id __df_sym
