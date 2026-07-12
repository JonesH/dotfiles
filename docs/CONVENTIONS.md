# Conventions for adding configuration

## Where does new config go?

| Kind | Put it in | Then |
|---|---|---|
| Shell alias / env / function | the matching shared module (`bash/aliases.sh`, `env.sh`, `functions.sh`) | it's picked up by bash *and* zsh automatically |
| PATH entry | `bash/paths.sh` (portable) or `bash/os/<plat>.sh` (platform-only) | guard with `[ -d ]` / `command -v` |
| Platform-specific behaviour | `bash/os/{darwin,linux,wsl}.sh` | never fork a whole config |
| A new dotfile | author it under the relevant dir | add it to the symlink table in `install/bootstrap.sh` |
| A `~/.local/bin` script | `scripts/` (executable) | add to the symlink table |
| A CLI tool (needs installing) | a row in `packages/tools.tsv` (binary ⇥ macos ⇥ debian ⇥ notes) | `install/install-tools.sh` installs it per-OS |
| A uv/uvx tool | `packages/uv-tools.txt` (`install <pkg>` or `uvx <name> <cmd>`) | installer runs `uv tool install` / writes a wrapper |
| A secret / token | **`~/.bash_tokens`** (untracked) | reference it as `$VAR`; add the name to `secrets.example/bash_tokens.example` |
| Anything machine-specific | a `*.local` file (`~/.bashrc.local`, `~/.ssh/config.local`, `~/.gitconfig.local`) | it's sourced if present, never tracked |

## Rules

1. **No secrets in tracked files, ever.** Reference env vars; keep values in
   `~/.bash_tokens` / `*.local`. The pre-commit guard will block a leak, but don't rely
   on it — it's the backstop, not the plan.
2. **Shared modules stay POSIX-safe** (no bash-only syntax) so zsh can source them.
   bash-only constructs (`shopt`, `PROMPT_COMMAND`, `\[..\]` prompt escapes) belong in
   `bash/bashrc` / `bash/prompt.sh`.
3. **Guard, don't branch-by-hostname.** Prefer `command -v tool` / `[ -d path ]` over
   hardcoding a machine. Real per-host needs go in `*.local`.
4. **No hardcoded version paths.** Use `$(brew --prefix <keg>)`, `$NVM_DIR`, etc.
5. **Register new files in the bootstrap symlink table** — an unlinked file isn't applied.
6. After adding config, run `~/dotfiles/install/bootstrap.sh` (idempotent) to link it,
   and `dfsync` to propagate. Everything else self-syncs.

## Deferred areas

`claude/`, `mcp/`, `claude-mem/`, and `zed/settings.json` are intentionally not versioned
yet — see each directory's README for the reason and the intended approach.
