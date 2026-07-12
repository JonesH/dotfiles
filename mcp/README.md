# mcp/ — deferred (needs a secret-safe extraction strategy)

MCP server configuration currently lives inside **`~/.claude.json`**, which also
holds project history **and secrets/tokens** (e.g. the Hetzner API token). That file
must never be committed, so MCP config can't be versioned by simply symlinking it.

## Intended approach (when we do it)

1. Extract just the `mcpServers` definitions from `~/.claude.json`.
2. Replace any inline token/env value with a `${ENV_VAR}` reference resolved from
   `~/.bash_tokens` at launch.
3. Version the sanitized server list here; document how each server is re-registered
   on a new host.

Until then, MCP setup is per-machine and lives only in `~/.claude.json` (untracked).
