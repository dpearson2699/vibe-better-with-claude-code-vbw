#!/bin/bash
# SessionStart hook: Detect VBW project state and inject context

PLANNING_DIR=".vbw-planning"

if [ ! -d "$PLANNING_DIR" ]; then
  jq -n '{
    "hookSpecificOutput": {
      "additionalContext": "No .vbw-planning/ directory found. Run /vbw:init to set up the project."
    }
  }'
  exit 0
fi

CONFIG_FILE="$PLANNING_DIR/config.json"
EFFORT="balanced"
if [ -f "$CONFIG_FILE" ]; then
  EFFORT=$(jq -r '.effort // "balanced"' "$CONFIG_FILE")
fi

STATE_FILE="$PLANNING_DIR/STATE.md"
STATE_INFO="no STATE.md found"
if [ -f "$STATE_FILE" ]; then
  PHASE=$(grep -m1 "^## Current Phase" "$STATE_FILE" | sed 's/## Current Phase: *//')
  STATE_INFO="current phase: ${PHASE:-unknown}"
fi

jq -n --arg effort "$EFFORT" --arg state "$STATE_INFO" '{
  "hookSpecificOutput": {
    "additionalContext": ("VBW project detected. Effort: " + $effort + ". State: " + $state)
  }
}'

exit 0
