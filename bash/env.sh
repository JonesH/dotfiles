# env.sh — portable environment variables + history config
# Sourced by bash (~/.config/bash/env.sh) and zsh. Keep POSIX-safe (no bashisms
# beyond what zsh also accepts). Platform-specific env lives in bash/os/*.sh.

# --- History ---------------------------------------------------------------
export HISTSIZE=1000000
export HISTFILESIZE=10000000
export HISTCONTROL=ignoreboth
export HISTIGNORE='ls:ll:ls -alh:pwd:clear:history'
export HISTTIMEFORMAT='%F %T '

# --- Editor ----------------------------------------------------------------
export EDITOR=vim
export VISUAL=vim

# --- Preferred models (OpenRouter ids; consumed by AI-tool aliases) --------
export FAV_CLAUDE=openrouter:anthropic/claude-haiku-4-5
export FAV_GROK=openrouter:x-ai/grok-4.1-fast
export FAV_GPT=openrouter:openai/gpt-5.1-codex-mini
export FAV_GEMINI=openrouter:google/gemini-3-flash-preview
export FAV_MODEL="$FAV_GROK"

# --- Misc tooling env ------------------------------------------------------
export COMPOSE_BAKE=true
export OLLAMA_API_BASE=http://localhost:11343
export SKILLS_DIR="${HOME}/skills"

# Claude Desktop config path (macOS location; harmless if absent elsewhere)
export CLAUDE_CONFIG="${HOME}/Library/Application Support/Claude/claude_desktop_config.json"
