#!/usr/bin/env bash
# Test the dotfiles install on a throwaway, RAM-backed Debian container.
# - --rm            : container is deleted on exit (ephemeral)
# - --tmpfs /work   : the working copy lives in RAM (tmpfs), nothing hits disk
# - repo mounted RO : we copy it into tmpfs so the test can't mutate your repo
# Reproduces the real host: fresh Debian + uv, but NO C compiler, to prove the
# numpy/aider fix needs no build-essential.
#
# Usage: ./test-bootstrap.sh [amd64|arm64]   (default: host arch)
set -euo pipefail

REPO="${REPO:-$HOME/dotfiles}"
ARCH="${1:-}"
PLATFORM=""
[ "$ARCH" = amd64 ] && PLATFORM="--platform=linux/amd64"
[ "$ARCH" = arm64 ] && PLATFORM="--platform=linux/arm64"

exec docker run --rm -i $PLATFORM \
  --tmpfs /work:exec,size=2g \
  -v "$REPO":/repo:ro \
  debian:stable-slim bash -euo pipefail -s <<'INNER'
echo "== fresh $(. /etc/os-release; echo "$PRETTY_NAME") $(uname -m) =="
# Minimal prereqs a real box would have (git+curl+ca-certs). Deliberately NO gcc.
apt-get update -qq && apt-get install -y -qq git curl ca-certificates >/dev/null
echo "cc present? -> $(command -v cc || echo 'NO (as on the failing host)')"

# Fresh, unprivileged-ish user home under tmpfs
cp -a /repo /work/dotfiles
export HOME=/work/home; mkdir -p "$HOME"

# Install uv (the real host had it; fast-agent wrapper had succeeded)
curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
export PATH="$HOME/.local/bin:$PATH"
echo "uv -> $(uv --version)"

echo "== running install-tools.sh (apt/brew skipped on this probe; focus = uv tools) =="
# Just exercise the uv-tools path — that's where the numpy failure was.
bash /work/dotfiles/install/install-tools.sh --quiet || true

echo "== verdict =="
if "$HOME/.local/bin/aider" --version >/dev/null 2>&1; then
  echo "PASS: aider installed & runs without a C compiler -> $("$HOME/.local/bin/aider" --version 2>&1 | head -1)"
else
  echo "FAIL: aider did not install"; exit 1
fi
INNER
