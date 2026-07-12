# functions.sh — portable shell functions (shared by bash + zsh)

# Create directory (and parents) then cd into it
mkcd() { mkdir -p "$@" && cd "$_" || return; }

# Extract almost any archive by extension
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.rar)     unrar x "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.Z)       uncompress "$1" ;;
      *.7z)      7z x "$1" ;;
      *)         echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Quick recursive filename search
f() { find . -iname "*$1*" 2>/dev/null; }

# Print each file with a header (handy for pasting code into prompts)
showfile() {
  for file in "$@"; do
    echo -e "# $file \n" && cat "$file" && echo -e "\n"
  done
}

# showfile every .py under the given path(s)
showpath() {
  find "$@" -type f -name '*.py' | while read -r file; do
    showfile "$file"
  done
}

# Resolve the most recent Jupyter ipykernel connection file for this repo
currentkernel() {
  local p; p="$(git rev-parse --show-toplevel)/tmp/ipykernel"
  echo "${p}/$(ls -1t "$p" | head -1)"
}

# Launch a Jupyter console in the local uv project venv, installing a kernel first
ipyvenv() {
  if ! command -v uv >/dev/null 2>&1; then
    echo "Error: uv is not installed"; return 1
  fi
  if [ ! -f "pyproject.toml" ] && [ ! -f "requirements.txt" ]; then
    echo "Error: No Python project found (no pyproject.toml or requirements.txt)"; return 1
  fi
  local project_name; project_name="$(basename "$(pwd)")"
  if ! uv run python -c "import ipykernel" 2>/dev/null; then
    echo "📦 Installing ipykernel..."; uv add --dev ipykernel || return 1
  fi
  echo "🔧 Setting up Jupyter kernel: $project_name"
  uv run python -m ipykernel install --user \
    --name "$project_name" --display-name "Python ($project_name)" || return 1
  echo "🚀 Launching Jupyter console..."
  uv run jupyter console --kernel="$project_name"
}
