#!/bin/bash
# TaskCompleted hook: Verify a recent git commit exists for the completed task
# Exit 2 = block completion, Exit 0 = allow

LAST_COMMIT=$(git log --oneline -1 2>/dev/null)

if [ -z "$LAST_COMMIT" ]; then
  echo "No commit found for completed task" >&2
  exit 2
fi

# Verify commit is recent (within last 2 hours)
LAST_TIMESTAMP=$(git log -1 --format=%ct 2>/dev/null)
NOW=$(date +%s)
AGE=$(( NOW - LAST_TIMESTAMP ))
TWO_HOURS=7200

if [ "$AGE" -gt "$TWO_HOURS" ]; then
  echo "No recent commit found for completed task (last commit is over 2 hours old)" >&2
  exit 2
fi

exit 0
