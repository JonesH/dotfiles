#!/usr/bin/env bash
# Full unattended dress rehearsal of the dotfiles bootstrap on a fresh Debian.
# Mirrors the real host: non-root user `jones` with passwordless sudo, uv present.
# Key trick: the whole bootstrap runs with stdin from /dev/null under `timeout`,
# so ANY interactive prompt fails immediately instead of hanging (= unattended proof).
#
# Usage: ./test-full-bootstrap.sh [amd64|arm64]   (default: host arch)
set -euo pipefail
REPO="${REPO:-$HOME/dotfiles}"
ARCH="${1:-}"; PLATFORM=""
[ "$ARCH" = amd64 ] && PLATFORM="--platform=linux/amd64"
[ "$ARCH" = arm64 ] && PLATFORM="--platform=linux/arm64"

exec docker run --rm -i $PLATFORM \
  --tmpfs /work:exec,size=3g \
  -v "$REPO":/repo:ro \
  debian:stable-slim bash -euo pipefail -s <<'INNER'
export DEBIAN_FRONTEND=noninteractive
echo "== fresh $(. /etc/os-release; echo "$PRETTY_NAME") $(uname -m) =="

# Base tools a real cloud image ships with + sudo, and a passwordless-sudo user.
apt-get update -qq && apt-get install -y -qq sudo git curl ca-certificates >/dev/null
useradd -m -s /bin/bash jones
echo 'jones ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/jones && chmod 440 /etc/sudoers.d/jones

# Give jones the repo (in tmpfs) + uv (the real host had it).
cp -a /repo /work/dotfiles && chown -R jones:jones /work/dotfiles
git config --system --add safe.directory /work/dotfiles

# Run the ACTUAL bootstrap as jones, stdin closed, hard 10-min ceiling.
# If anything prompts, `timeout`/EOF makes it fail — that's the whole test.
su - jones -c '
  set -e
  export PATH="$HOME/.local/bin:$PATH"
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
  echo "uv -> $(uv --version)"
  echo "== bootstrap.sh --packages (stdin closed, unattended) =="
  timeout 600 /work/dotfiles/install/bootstrap.sh --packages </dev/null
  echo "== bootstrap exit code: $? =="
' && BOOT_RC=0 || BOOT_RC=$?

echo "== verifying results =="
fail=0
check() { if eval "$2"; then echo "  ok   $1"; else echo "  FAIL $1"; fail=1; fi; }
H=/home/jones
check ".bashrc symlink"        "[ -L $H/.bashrc ]"
check "aliases module linked"  "[ -L $H/.config/bash/aliases.sh ]"
check "linux os module linked" "[ -L $H/.config/bash/os/linux.sh ]"
check ".bash_tokens seeded"    "[ -f $H/.bash_tokens ]"
check "apt tool git present"   "command -v git >/dev/null"
check "apt tool jq present"    "sudo -u jones bash -lc 'command -v jq' >/dev/null 2>&1 || command -v jq >/dev/null"
check "ripgrep present"        "command -v rg >/dev/null"
check "batcat present"         "command -v batcat >/dev/null"
check "aider installed"        "[ -x $H/.local/bin/aider ]"
check "interactive shell loads" "sudo -u jones bash -ic 'true' >/dev/null 2>&1"

echo "== VERDICT =="
if [ "$BOOT_RC" = 0 ] && [ "$fail" = 0 ]; then
  echo "PASS: full bootstrap finished unattended (exit 0) and all checks passed"
else
  echo "FAIL: bootstrap rc=$BOOT_RC checks_failed=$fail"; exit 1
fi
INNER
