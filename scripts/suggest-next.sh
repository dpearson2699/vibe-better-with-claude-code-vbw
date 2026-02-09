#!/usr/bin/env bash
# suggest-next.sh — Context-aware Next Up suggestions (ADP-03)
#
# Usage: suggest-next.sh <command> [result]
#   command: the VBW command that just ran (implement, qa, plan, execute, fix, etc.)
#   result:  optional outcome (pass, fail, partial, complete, skipped)
#
# Output: Formatted ➜ Next Up block with 2-3 contextual suggestions.
# Called by commands during their output step.

set -eo pipefail

CMD="${1:-}"
RESULT="${2:-}"
PLANNING_DIR=".vbw-planning"

# --- State detection ---
has_planning=false
has_project=false
phase_count=0
next_unplanned=""
next_unbuilt=""
all_done=false
last_qa_result=""
map_exists=false

if [ -d "$PLANNING_DIR" ]; then
  has_planning=true

  # Resolve phases directory (milestone-aware)
  PHASES_DIR="$PLANNING_DIR/phases"
  if [ -f "$PLANNING_DIR/ACTIVE" ]; then
    ACTIVE=$(tr -d '[:space:]' < "$PLANNING_DIR/ACTIVE")
    if [ -d "$PLANNING_DIR/milestones/$ACTIVE/phases" ]; then
      PHASES_DIR="$PLANNING_DIR/milestones/$ACTIVE/phases"
    fi
  fi

  # Check PROJECT.md exists and isn't template
  if [ -f "$PLANNING_DIR/PROJECT.md" ] && ! grep -q '{project-name}' "$PLANNING_DIR/PROJECT.md" 2>/dev/null; then
    has_project=true
  fi

  # Scan phases
  if [ -d "$PHASES_DIR" ]; then
    for dir in "$PHASES_DIR"/*/; do
      [ -d "$dir" ] || continue
      phase_count=$((phase_count + 1))
      phase_num=$(basename "$dir" | sed 's/[^0-9].*//')

      plans=$(find "$dir" -maxdepth 1 -name '*-PLAN.md' 2>/dev/null | wc -l | tr -d ' ')
      summaries=$(find "$dir" -maxdepth 1 -name '*-SUMMARY.md' 2>/dev/null | wc -l | tr -d ' ')

      if [ "$plans" -eq 0 ] && [ -z "$next_unplanned" ]; then
        next_unplanned="$phase_num"
      elif [ "$plans" -gt 0 ] && [ "$summaries" -lt "$plans" ] && [ -z "$next_unbuilt" ]; then
        next_unbuilt="$phase_num"
      fi
    done

    # All done if phases exist and nothing is unplanned/unbuilt
    if [ "$phase_count" -gt 0 ] && [ -z "$next_unplanned" ] && [ -z "$next_unbuilt" ]; then
      all_done=true
    fi

    # Find most recent QA result
    for dir in "$PHASES_DIR"/*/; do
      [ -d "$dir" ] || continue
      for vf in "$dir"/*-VERIFICATION.md; do
        [ -f "$vf" ] || continue
        r=$(grep -m1 '^result:' "$vf" 2>/dev/null | sed 's/result:[[:space:]]*//' | tr '[:upper:]' '[:lower:]')
        [ -n "$r" ] && last_qa_result="$r"
      done
    done
  fi

  # Check map
  [ -d "$PLANNING_DIR/codebase" ] && map_exists=true
fi

# Use explicit result if provided, fall back to detected QA result
effective_result="${RESULT:-$last_qa_result}"

# --- Output ---
echo "➜ Next Up"

suggest() {
  echo "  $1"
}

case "$CMD" in
  init)
    suggest "/vbw:implement -- Define your project and start building"
    ;;

  implement|execute)
    case "$effective_result" in
      fail)
        suggest "/vbw:fix -- Fix the failing checks"
        suggest "/vbw:qa -- Re-run verification after fixing"
        ;;
      partial)
        suggest "/vbw:fix -- Address partial failures"
        if [ "$all_done" != true ]; then
          suggest "/vbw:implement -- Continue to next phase"
        fi
        ;;
      *)
        if [ "$all_done" = true ]; then
          suggest "/vbw:archive -- Archive completed work"
          suggest "/vbw:qa -- Run final verification"
        elif [ -n "$next_unbuilt" ] || [ -n "$next_unplanned" ]; then
          suggest "/vbw:implement -- Continue to next phase"
        fi
        if [ "$RESULT" = "skipped" ]; then
          suggest "/vbw:qa -- Verify completed work"
        fi
        ;;
    esac
    ;;

  plan)
    suggest "/vbw:implement -- Execute the planned phase"
    ;;

  qa)
    case "$effective_result" in
      pass)
        if [ "$all_done" = true ]; then
          suggest "/vbw:archive -- Archive completed work"
        else
          suggest "/vbw:implement -- Continue to next phase"
        fi
        ;;
      fail)
        suggest "/vbw:fix -- Fix the failing checks"
        ;;
      partial)
        suggest "/vbw:fix -- Address partial failures"
        suggest "/vbw:implement -- Continue despite warnings"
        ;;
      *)
        suggest "/vbw:implement -- Continue building"
        ;;
    esac
    ;;

  fix)
    suggest "/vbw:qa -- Verify the fix"
    suggest "/vbw:implement -- Continue building"
    ;;

  debug)
    suggest "/vbw:fix -- Apply the fix"
    suggest "/vbw:implement -- Continue building"
    ;;

  config)
    if [ "$has_project" = true ]; then
      suggest "/vbw:status -- View project state"
    else
      suggest "/vbw:implement -- Define your project and start building"
    fi
    ;;

  archive)
    suggest "/vbw:implement -- Start new work"
    ;;

  status)
    if [ "$all_done" = true ]; then
      suggest "/vbw:archive -- Archive completed work"
    elif [ -n "$next_unbuilt" ] || [ -n "$next_unplanned" ]; then
      suggest "/vbw:implement -- Continue building"
    else
      suggest "/vbw:implement -- Start building"
    fi
    ;;

  map)
    suggest "/vbw:implement -- Start building"
    suggest "/vbw:status -- View project state"
    ;;

  discuss|assumptions)
    suggest "/vbw:plan -- Plan this phase"
    suggest "/vbw:implement -- Plan and execute in one flow"
    ;;

  resume)
    suggest "/vbw:implement -- Continue building"
    suggest "/vbw:status -- View current progress"
    ;;

  *)
    # Fallback for help, whats-new, update, etc.
    if [ "$has_project" = true ]; then
      suggest "/vbw:implement -- Continue building"
      suggest "/vbw:status -- View project progress"
    else
      suggest "/vbw:implement -- Start a new project"
    fi
    ;;
esac

# Map staleness hint (skip for map/init/help commands)
case "$CMD" in
  map|init|help|update|whats-new|uninstall) ;;
  *)
    if [ "$has_project" = true ] && [ "$map_exists" = false ] && [ "$phase_count" -gt 0 ]; then
      suggest "/vbw:map -- Map your codebase for better planning"
    fi
    ;;
esac
