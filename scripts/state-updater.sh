#!/bin/bash
set -u
# PostToolUse hook: Auto-update execution state when SUMMARY.md is written
# Non-blocking, fail-open (always exit 0)
#
# Two triggers:
#   1. PLAN.md write: Updates STATE.md plan count and progress percentage
#   2. SUMMARY.md write: Updates .execution-state.json plan status AND STATE.md progress
#
# Manual test (PLAN.md):
#   echo '{"tool_input":{"file_path":".vbw-planning/phases/01-foo/01-01-PLAN.md"}}' | bash scripts/state-updater.sh
#
# Manual test (SUMMARY.md):
#   echo '{"tool_input":{"file_path":".vbw-planning/phases/01-foo/01-01-SUMMARY.md"}}' | bash scripts/state-updater.sh

update_state_md() {
  local phase_dir="$1"
  local state_md=".vbw-planning/STATE.md"

  [ -f "$state_md" ] || return 0

  local plan_count summary_count pct
  plan_count=$(ls -1 "$phase_dir"/*-PLAN.md 2>/dev/null | wc -l | tr -d ' ')
  summary_count=$(ls -1 "$phase_dir"/*-SUMMARY.md 2>/dev/null | wc -l | tr -d ' ')

  if [ "$plan_count" -gt 0 ]; then
    pct=$(( (summary_count * 100) / plan_count ))
  else
    pct=0
  fi

  local tmp="${state_md}.tmp.$$"
  sed "s/^Plans: .*/Plans: ${summary_count}\/${plan_count}/" "$state_md" | \
    sed "s/^Progress: .*/Progress: ${pct}%/" > "$tmp" 2>/dev/null && \
    mv "$tmp" "$state_md" 2>/dev/null || rm -f "$tmp" 2>/dev/null
}

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)

# --- PLAN.md detection: update STATE.md with plan count ---
if echo "$FILE_PATH" | grep -qE 'phases/[^/]+/[0-9]+-[0-9]+-PLAN\.md$'; then
  update_state_md "$(dirname "$FILE_PATH")"
fi

# Only act on *-SUMMARY.md files in a phases directory
if ! echo "$FILE_PATH" | grep -qE 'phases/.*-SUMMARY\.md$'; then
  exit 0
fi

STATE_FILE=".vbw-planning/.execution-state.json"

# Guard: only act if execution state exists
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Check the SUMMARY.md file exists
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Parse frontmatter from SUMMARY.md for phase, plan, status
PHASE=""
PLAN=""
STATUS=""
IN_FRONTMATTER=0

while IFS= read -r line; do
  if [ "$line" = "---" ]; then
    if [ "$IN_FRONTMATTER" -eq 0 ]; then
      IN_FRONTMATTER=1
      continue
    else
      break
    fi
  fi
  if [ "$IN_FRONTMATTER" -eq 1 ]; then
    key=$(echo "$line" | cut -d: -f1 | tr -d ' ')
    val=$(echo "$line" | cut -d: -f2- | sed 's/^ *//')
    case "$key" in
      phase) PHASE="$val" ;;
      plan) PLAN="$val" ;;
      status) STATUS="$val" ;;
    esac
  fi
done < "$FILE_PATH"

# Need at least phase and plan to update state
if [ -z "$PHASE" ] || [ -z "$PLAN" ]; then
  exit 0
fi

# Default status to "completed" if SUMMARY exists but no status in frontmatter
STATUS="${STATUS:-completed}"

# Update execution state via jq
TEMP_FILE="${STATE_FILE}.tmp"
jq --arg phase "$PHASE" --arg plan "$PLAN" --arg status "$STATUS" '
  if .phases[$phase] and .phases[$phase][$plan] then
    .phases[$phase][$plan].status = $status
  else
    .
  end
' "$STATE_FILE" > "$TEMP_FILE" 2>/dev/null && mv "$TEMP_FILE" "$STATE_FILE" 2>/dev/null

# Also update STATE.md progress when SUMMARY.md is written
update_state_md "$(dirname "$FILE_PATH")"

exit 0
