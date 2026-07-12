# prompt.sh — bash PS1 (cyan user@host, yellow cwd, green git branch)
# Also shows a red "⚠df" marker when the dotfiles self-sync hit a conflict that
# needs manual resolution (~/.cache/dotfiles/CONFLICT). \001/\002 mark the escape
# sequences as zero-width so line editing stays correct.

__df_conflict() {
  [ -f "$HOME/.cache/dotfiles/CONFLICT" ] || return 0
  printf '\001\033[31m\002⚠df \001\033[00m\002'
}

export PS1="\$(__df_conflict)\[\033[36m\]\u@\h \[\033[33m\]\w \[\033[32m\]\$(git branch --show-current 2>/dev/null)\[\033[00m\] $ "
