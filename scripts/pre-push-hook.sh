#!/usr/bin/env bash
set -euo pipefail
# VBW pre-push hook — delegates to the latest cached plugin script.
# Installed by VBW install-hooks.sh. Remove with: rm .git/hooks/pre-push
SCRIPT=$(ls -1 "$HOME"/.claude/plugins/cache/vbw-marketplace/vbw/*/scripts/pre-push-hook.sh 2>/dev/null | sort -V | tail -1)
if [ -n "$SCRIPT" ] && [ -f "$SCRIPT" ]; then
  exec bash "$SCRIPT" "$@"
fi
# Plugin not cached — skip silently
exit 0
