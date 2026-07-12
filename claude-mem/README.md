# claude-mem/ — deferred (settings.json carries a live secret)

`~/.claude-mem/settings.json` was going to be versioned, but the audit found it
contains a **live secret** (`CLAUDE_MEM_OPENROUTER_API_KEY: sk-or-…`) plus
machine-specific values (`CLAUDE_MEM_DATA_DIR`, signup metadata). Committing it as-is
would leak the key, so it's deferred alongside the Claude dedicated pass.

## Intended approach (when we do it)

- Commit a **sanitized template** (`settings.example.json`) with the API key blanked
  and `CLAUDE_MEM_DATA_DIR` set to `${HOME}/.claude-mem`.
- Inject the real key at runtime (from `~/.bash_tokens`) or have bootstrap merge it in
  without ever writing the secret into the repo.
- Never symlink over an existing live `settings.json` that holds the real key.

## Never version

- `claude-mem.db` (+ `-shm`/`-wal`), `chroma/`, `corpora/`, `backups/`, `logs/`,
  `observer-sessions/`, runtime files — the ~827 MB of data/cache.
