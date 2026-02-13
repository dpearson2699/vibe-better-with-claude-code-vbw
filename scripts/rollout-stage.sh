#!/usr/bin/env bash
set -u

# rollout-stage.sh [check|advance|status] [--stage=N] [--dry-run]
# Manages V3 flag rollout through 3 stages based on completed phase count.
# Stage 1 (observability): v3_event_log, v3_metrics -- threshold 0
# Stage 2 (optimization): v3_delta_context, v3_context_cache -- threshold 2
# Stage 3 (full): all remaining v3_ flags -- threshold 5
# Exit 0 always -- rollout must never block execution.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLANNING_DIR=".vbw-planning"
CONFIG_PATH="${PLANNING_DIR}/config.json"
EVENTS_FILE="${PLANNING_DIR}/.events/event-log.jsonl"
STAGES_PATH="${SCRIPT_DIR}/../config/rollout-stages.json"

# --- Argument parsing ---
ACTION="check"
FORCE_STAGE=""
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    check|advance|status)
      ACTION="$arg"
      ;;
    --stage=*)
      FORCE_STAGE="${arg#--stage=}"
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --help|-h)
      echo "Usage: rollout-stage.sh [check|advance|status] [--stage=N] [--dry-run]"
      echo ""
      echo "Actions:"
      echo "  check    Report current stage without modifying anything (default)"
      echo "  advance  Enable flags for the next eligible stage"
      echo "  status   Show all flags and their current values"
      echo ""
      echo "Options:"
      echo "  --stage=N   Force a specific stage (1, 2, or 3)"
      echo "  --dry-run   Show what would change without writing"
      exit 0
      ;;
  esac
done

# --- Prerequisites check ---
if [ ! -f "$CONFIG_PATH" ]; then
  echo '{"error":"config.json not found","action":"'"$ACTION"'"}' 2>/dev/null || true
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo '{"error":"jq not found","action":"'"$ACTION"'"}' 2>/dev/null || true
  exit 0
fi

if [ ! -f "$STAGES_PATH" ]; then
  echo '{"error":"rollout-stages.json not found","action":"'"$ACTION"'"}' 2>/dev/null || true
  exit 0
fi

# --- Count completed phases ---
COMPLETED_PHASES=0
REQUIRE_CLEAN=$(jq -r '.advancement.require_clean_phases // true' "$STAGES_PATH" 2>/dev/null || echo "true")
COUNT_EVENT=$(jq -r '.advancement.count_event // "phase_end"' "$STAGES_PATH" 2>/dev/null || echo "phase_end")

if [ -f "$EVENTS_FILE" ]; then
  if [ "$REQUIRE_CLEAN" = "true" ]; then
    COMPLETED_PHASES=$(jq -s "[.[] | select(.event == \"${COUNT_EVENT}\") | select(.data.error == null)] | length" "$EVENTS_FILE" 2>/dev/null || echo "0")
  else
    COMPLETED_PHASES=$(jq -s "[.[] | select(.event == \"${COUNT_EVENT}\")] | length" "$EVENTS_FILE" 2>/dev/null || echo "0")
  fi
fi

# --- Determine current stage ---
CURRENT_STAGE=0
CURRENT_LABEL=""
NEXT_STAGE=""
NEXT_THRESHOLD=""
ELIGIBLE_STAGES="[]"

STAGE_COUNT=$(jq '.stages | length' "$STAGES_PATH" 2>/dev/null || echo "0")

ELIGIBLE_LIST=""
for i in $(seq 0 $((STAGE_COUNT - 1))); do
  STAGE_NUM=$(jq -r ".stages[$i].stage" "$STAGES_PATH" 2>/dev/null || echo "0")
  THRESHOLD=$(jq -r ".stages[$i].phases_required" "$STAGES_PATH" 2>/dev/null || echo "999")
  LABEL=$(jq -r ".stages[$i].label" "$STAGES_PATH" 2>/dev/null || echo "")

  if [ "$COMPLETED_PHASES" -ge "$THRESHOLD" ]; then
    CURRENT_STAGE=$STAGE_NUM
    CURRENT_LABEL="$LABEL"
    if [ -n "$ELIGIBLE_LIST" ]; then
      ELIGIBLE_LIST="${ELIGIBLE_LIST},${STAGE_NUM}"
    else
      ELIGIBLE_LIST="${STAGE_NUM}"
    fi
  else
    if [ -z "$NEXT_STAGE" ]; then
      NEXT_STAGE=$STAGE_NUM
      NEXT_THRESHOLD=$THRESHOLD
    fi
  fi
done

ELIGIBLE_STAGES="[${ELIGIBLE_LIST}]"

# --- Action: check ---
if [ "$ACTION" = "check" ]; then
  NEXT_JSON="null"
  [ -n "$NEXT_STAGE" ] && NEXT_JSON=$NEXT_STAGE
  jq -n \
    --argjson current "$CURRENT_STAGE" \
    --argjson phases "$COMPLETED_PHASES" \
    --argjson eligible "$ELIGIBLE_STAGES" \
    --argjson next "$NEXT_JSON" \
    '{current_stage: $current, completed_phases: $phases, eligible_stages: $eligible, next_stage: $next}' 2>/dev/null \
    || echo "{\"current_stage\":${CURRENT_STAGE},\"completed_phases\":${COMPLETED_PHASES}}"
  exit 0
fi
