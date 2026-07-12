#!/usr/bin/env bash
# update.sh — on-demand foreground full sync (pull/commit/push). Thin wrapper.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync.sh" "$@"
