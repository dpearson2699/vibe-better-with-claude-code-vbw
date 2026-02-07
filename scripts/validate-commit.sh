#!/bin/bash
# PostToolUse hook: Validate git commit message format
# Non-blocking feedback only (always exit 0)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only check git commit commands
if ! echo "$COMMAND" | grep -q "git commit"; then
  exit 0
fi

# Extract commit message from -m flag
MSG=$(echo "$COMMAND" | grep -oP '(?<=-m\s["\x27]).*?(?=["\x27])' || echo "$COMMAND" | grep -oP '(?<=-m\s)\S+')

if [ -z "$MSG" ]; then
  exit 0
fi

# Validate format: {type}({scope}): {desc}
VALID_TYPES="feat|fix|test|refactor|perf|docs|style|chore"
if ! echo "$MSG" | grep -qE "^($VALID_TYPES)\(.+\): .+"; then
  jq -n --arg msg "$MSG" '{
    "hookSpecificOutput": {
      "additionalContext": ("Commit message does not match format {type}({scope}): {desc}. Got: " + $msg)
    }
  }'
fi

exit 0
