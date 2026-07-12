# Adding a new host

```sh
# 1. Clone
git clone git@github.com:JonesH/dotfiles.git ~/dotfiles

# 2. Bootstrap (backs up any existing dotfiles, then symlinks)
~/dotfiles/install/bootstrap.sh

# 3. Secrets — copy the templates and fill them in
cp ~/dotfiles/secrets.example/bash_tokens.example ~/.bash_tokens && chmod 600 ~/.bash_tokens
$EDITOR ~/.bash_tokens
#   (optional) real SSH hosts and git identity:
cp ~/dotfiles/secrets.example/ssh-config.local.example ~/.ssh/config.local && chmod 600 ~/.ssh/config.local
cp ~/dotfiles/secrets.example/gitconfig.local.example ~/.gitconfig.local

# 4. Reload the shell
exec $SHELL -l

# 5. (optional) install the package baseline
~/dotfiles/install/bootstrap.sh --packages
```

From here on the host self-syncs: a background hook pulls/pushes changes every few
hours. Run `dfsync` to sync immediately.

## Rollback

Everything the bootstrap replaced is in `~/.dotfiles-backup/<timestamp>/`. To undo,
remove the symlinks and copy the backups back.

## Per-host tweaks

Put anything machine-specific in the untracked local files — they're sourced if present
and never leave the machine: `~/.bashrc.local`, `~/.zshrc.local`, `~/.ssh/config.local`,
`~/.gitconfig.local`.
