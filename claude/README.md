# claude/ — deferred (dedicated pass)

`~/.claude` is intentionally **not** versioned yet. It is ~90% machine cache
(archive 4.4G, plugins 1.3G, projects 1.0G, …) with a small hand-authored surface
buried inside. It deserves its own careful pass rather than a rushed symlink.

## Intended approach (when we do it)

Version a **curated allowlist** of hand-authored config only, symlinked like the rest:

- `CLAUDE.md`, `AGENT_DNA.md`, `tool-mapping.yaml`
- `settings.json` — **after auditing the `env` block for secrets** (move any literal
  key into `~/.bash_tokens` / a `*.local` include)
- `rules/`, `hooks/` (deduped of `.bak`/`.pre-fix` files), `statusline.sh`,
  `output-styles/`, `recipes.yaml`
- `plugins.yaml` — the **declarative SSOT** for marketplaces + plugins

`bootstrap.sh` would then reinstall marketplaces/plugins from `plugins.yaml`:

```sh
# for each marketplace in plugins.yaml
claude marketplace add <url-or-name>
# for each plugin in plugins.yaml
claude plugin install <name>
```

## Never version

- `~/.claude.json` (MCP configs **+ tokens**, ~249 KB) and the nested `~/.claude/.claude.json`
- `settings.local.json`
- Plugin-provided `agents/`, `commands/`, `skills/` (they come back via `claude plugin install`)
- The multi-GB caches: `archive/`, `plugins/{cache,marketplaces}/`, `projects/`,
  `security/`, `debug/`, `shell-snapshots/`, `history.jsonl`, etc.

## Open question for the dedicated pass

Whether to also version *personal* (non-plugin) custom agents/commands/skills via an
explicit allowlist — needs a provenance pass to separate user-authored from plugin-provided.
