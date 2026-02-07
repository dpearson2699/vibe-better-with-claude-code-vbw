#!/bin/bash
# TeammateIdle hook: Verify teammate's work has a corresponding commit
# Exit 2 = block (keep working), Exit 0 = allow idle

INPUT=$(cat)
TASK_DESC=$(echo "$INPUT" | jq -r '.task.subject // .task.description // ""')

if [ -z "$TASK_DESC" ]; then
  # No task info available, allow idle
  exit 0
fi

# Check recent git log for a commit related to this task
RECENT_COMMITS=$(git log --oneline -10 2>/dev/null)

if [ -z "$RECENT_COMMITS" ]; then
  echo "Task appears incomplete -- no recent commits found in git log" >&2
  exit 2
fi

# Search for task-related keywords in recent commits
TASK_KEYWORDS=$(echo "$TASK_DESC" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '\n' | head -5)

FOUND=false
for keyword in $TASK_KEYWORDS; do
  if [ ${#keyword} -gt 3 ] && echo "$RECENT_COMMITS" | grep -qi "$keyword"; then
    FOUND=true
    break
  fi
done

if [ "$FOUND" = false ]; then
  echo "Task appears incomplete -- no commit found matching task description" >&2
  exit 2
fi

exit 0
