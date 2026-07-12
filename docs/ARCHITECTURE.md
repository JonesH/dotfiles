# Architecture

## Principle: the repo is the single source of truth

No management tool (chezmoi/Stow/etc.). The repo holds the real files; `bootstrap.sh`
creates **symlinks** from `$HOME` into the repo. Editing `~/.bashrc` edits the repo file
(it's a symlink), so there's never a separate "apply" step for content changes — only
`git pull` (which updates symlink targets) and, when *new* files appear, a re-run of
bootstrap to add the new links.

## Layering (shell)

```
~/.bashrc  (symlink → bash/bashrc)
   └─ sources ~/.config/bash/{env,paths,aliases,functions,prompt}.sh   (shared modules)
   └─ sources ~/.config/bash/os/<darwin|linux|wsl>.sh                  (platform layer)
   └─ sources ~/.bash_tokens, ~/.bashrc.local                         (untracked, if present)

~/.zshrc   (symlink → zsh/zshrc)   # secondary shell
   └─ oh-my-zsh, then the SAME shared modules + platform layer
```

- **Shared modules** are POSIX-safe so both bash and zsh can source them → aliases,
  env, paths, and functions are defined exactly once.
- **Platform differences** live only in `bash/os/*.sh` (and guards inside modules),
  never as duplicated whole configs.
- **bash-only** behaviour (`shopt`, completions, `PROMPT_COMMAND`, prompt escapes)
  stays in `bash/bashrc` / `bash/prompt.sh`.

## Self-sync

`install/sync.sh` (triggered by a throttled background shell hook, or run as `dfsync`)
keeps hosts converged: commit tracked changes → pull (ff/rebase) → re-bootstrap if
needed → push. See [BOOTSTRAP.md](BOOTSTRAP.md). A `git core.hooksPath` points at
`install/git-hooks/`, so the secret-guard `pre-commit` runs on every commit.

## Secrets

Tracked files reference secrets by env var; real values live in untracked
`~/.bash_tokens` etc. The `.gitignore` plus the pre-commit guard are the two
independent lines of defence. See [CONVENTIONS.md](CONVENTIONS.md).
