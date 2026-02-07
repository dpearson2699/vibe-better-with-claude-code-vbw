#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FILES=(
  "$ROOT/VERSION"
  "$ROOT/.claude-plugin/plugin.json"
  "$ROOT/.claude-plugin/marketplace.json"
  "$ROOT/marketplace.json"
)

CURRENT=$(cat "$ROOT/VERSION" | tr -d '[:space:]')

# No argument — show current version and exit
if [[ $# -eq 0 ]]; then
  echo "Current version: $CURRENT"
  exit 0
fi

NEW="$1"

# Validate semver format
if ! [[ "$NEW" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: '$NEW' is not valid semver (expected X.Y.Z)" >&2
  exit 1
fi

if [[ "$NEW" == "$CURRENT" ]]; then
  echo "Version is already $CURRENT — nothing to do."
  exit 0
fi

echo "Bumping version: $CURRENT -> $NEW"

# Update all files — bail on first failure
printf '%s\n' "$NEW" > "$ROOT/VERSION"

jq --arg v "$NEW" '.version = $v' "$ROOT/.claude-plugin/plugin.json" > "$ROOT/.claude-plugin/plugin.json.tmp" \
  && mv "$ROOT/.claude-plugin/plugin.json.tmp" "$ROOT/.claude-plugin/plugin.json"

jq --arg v "$NEW" '.plugins[0].version = $v' "$ROOT/.claude-plugin/marketplace.json" > "$ROOT/.claude-plugin/marketplace.json.tmp" \
  && mv "$ROOT/.claude-plugin/marketplace.json.tmp" "$ROOT/.claude-plugin/marketplace.json"

jq --arg v "$NEW" '.plugins[0].version = $v' "$ROOT/marketplace.json" > "$ROOT/marketplace.json.tmp" \
  && mv "$ROOT/marketplace.json.tmp" "$ROOT/marketplace.json"

# Summary
echo ""
echo "Updated 4 files:"
for f in "${FILES[@]}"; do
  echo "  ${f#$ROOT/}"
done
echo ""
echo "Version is now $NEW"
