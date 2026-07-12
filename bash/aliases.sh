# aliases.sh — portable aliases (shared by bash + zsh)
# Platform-divergent aliases (meminfo/cpuinfo/ports) are defined per-OS in bash/os/*.sh.

# --- Navigation ------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --- Listing ---------------------------------------------------------------
alias ls='ls -p'
alias l='ls'
alias la='ls -a'
alias ll='ls -laht'
alias lh='ls -lh'
alias lt='ls -ltr'
alias lsize='ls -lhS'

# --- Safety nets -----------------------------------------------------------
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# --- Disk usage ------------------------------------------------------------
alias du='du -h'
alias df='df -h'

# --- Git -------------------------------------------------------------------
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# --- Process / network -----------------------------------------------------
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias myps='ps aux | grep $USER'
alias myip='curl -s ifconfig.me'

# --- Docker (only if installed) --------------------------------------------
if command -v docker >/dev/null 2>&1; then
  alias dps='docker ps'
  alias dpsa='docker ps -a'
  alias di='docker images'
  alias dex='docker exec -it'
  alias dlogs='docker logs -f'
fi

# --- Python / Jupyter (uv-based) -------------------------------------------
alias getjupyterports='cat $(currentkernel) | grep port | grep -o "\d+" | tr "\n" ","'
alias getdeps='python3 ~/codebrain/codebrain/depend_anal.py get-best'
alias jlab='uv run jupyter lab'
alias jnb='uv run jupyter notebook'
alias jkernels='jupyter kernelspec list'
alias ipykernel-init='uv run python -m ipykernel install --user --name "$(basename $(pwd))" --display-name "$(basename $(pwd))"'

# --- AI / dev tooling (secrets come from ~/.bash_tokens, never hard-coded) --
alias hcloud='hcloud --no-experimental-warnings'
alias aider='aider --api-key OPENROUTER=$OPENROUTER_API_KEY'
alias clai='OPENROUTER_API_KEY="$OPENROUTER_API_KEY" uvx --with "pydantic-ai-slim[all]" clai -m $FAV_MODEL'
alias search='clai --model "openrouter:openai/gpt-4o-mini-search-preview"'
alias getmodels='curl --no-progress-meter https://openrouter.ai/api/v1/models -H "Authorization: Bearer $OPENROUTER_API_KEY" | jq ".data[] | select(.created >= (now - 31536000)) | .id" | sort'
alias myskills='basename $(dirname $(find ${SKILLS_DIR} -type f -name SKILL.md -depth 2))'
alias fast-agent-mcp='uvx fast-agent-mcp'

# --- dotfiles self-sync ----------------------------------------------------
alias dfsync='"$HOME/dotfiles/install/sync.sh"'

# --- lean-ctx agent wrappers (inject LEAN_CTX_AGENT + BASH_ENV) ------------
alias claude='LEAN_CTX_AGENT=1 BASH_ENV="$HOME/.bashenv" claude'
alias codex='LEAN_CTX_AGENT=1 BASH_ENV="$HOME/.bashenv" codex'
alias gemini='LEAN_CTX_AGENT=1 BASH_ENV="$HOME/.bashenv" gemini'
