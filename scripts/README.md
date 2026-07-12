# scripts/

Hand-authored, portable helper scripts that get symlinked into `~/.local/bin/`
by `bootstrap.sh` (add them to the symlink table in `install/bootstrap.sh`).

## Not included

- **`kubectl-shell`** (was in `~/.local/bin`) — a ~933 KB *installed tool*, not
  hand-authored config. Installed tools are reinstalled per-host, never versioned here.

Drop new scripts in this directory, make them executable, and register them in the
bootstrap symlink table.
