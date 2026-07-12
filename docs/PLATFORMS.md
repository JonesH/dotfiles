# Supported platforms

| Platform | Login shell | Notes |
|---|---|---|
| **macOS** (Apple Silicon) | Homebrew bash 5.x | Primary/dev machine. `os/darwin.sh` handles Homebrew, compile flags, openjdk/python kegs, Homebrew NVM, iTerm2. |
| **Debian** (13 / trixie) | bash | `os/linux.sh`: system bash-completion, `free`/`ss`/`/proc` variants of the info aliases, optional Linuxbrew. |
| **Debian on WSL** | bash | `os/wsl.sh` sources `os/linux.sh` then adds Windows interop (`wslview` as `$BROWSER`, WindowsApps on PATH). Detected via `microsoft` in `/proc/version`. |

## How platform differences are handled

- One dispatch point (in `bash/bashrc` and `zsh/zshrc`):
  ```sh
  case "$(uname -s)" in
    Darwin) . os/darwin.sh ;;
    Linux)  grep -qi microsoft /proc/version && . os/wsl.sh || . os/linux.sh ;;
  esac
  ```
- Everything else in the shared modules is **guarded**, not duplicated: PATH entries use
  `[ -d ]`/`command -v` checks, tool integrations (nvm, pyenv, direnv, cargo, deno) only
  activate if installed. The same `env.sh`/`aliases.sh`/`functions.sh` run everywhere.
- Divergent commands live behind aliases whose bodies differ per OS (e.g. `meminfo` →
  `top` on macOS, `free -h` on Linux).
- SSH portability: `IgnoreUnknown UseKeychain` lets the macOS-only `UseKeychain` option
  coexist with Linux/WSL.

## Adding a platform

Create `bash/os/<name>.sh`, add a branch to the dispatch `case` in `bash/bashrc` and
`zsh/zshrc`, and (if needed) a package list under `packages/`.
