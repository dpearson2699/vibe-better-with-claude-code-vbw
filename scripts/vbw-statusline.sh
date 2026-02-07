#!/bin/bash
# VBW Status Line for Claude Code
# Line 1: [VBW] Phase N/M │ milestone │ effort │ 🌿 branch
# Line 2: ▓▓▓░░░░░░░ 30% │ $0.42 │ 12m 34s │ +156 -23

input=$(cat)

# Colors
C='\033[36m' G='\033[32m' Y='\033[33m' R='\033[31m'
D='\033[2m' B='\033[1m' X='\033[0m'

# Session data
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DUR=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# VBW state (cached 5s to stay fast)
CF="/tmp/vbw-sl-cache"
NOW=$(date +%s)
MT=$(stat -f %m "$CF" 2>/dev/null || stat -c %Y "$CF" 2>/dev/null || echo 0)

if [ ! -f "$CF" ] || [ $((NOW - MT)) -gt 5 ]; then
  PH=""; TT=""; MS=""; EF="balanced"; BR=""
  if [ -f ".vbw-planning/STATE.md" ]; then
    PH=$(grep -m1 "^Phase:" .vbw-planning/STATE.md | grep -oE '[0-9]+' | head -1)
    TT=$(grep -m1 "^Phase:" .vbw-planning/STATE.md | grep -oE '[0-9]+' | tail -1)
    MS=$(grep -m1 "^Status:" .vbw-planning/STATE.md | sed 's/^Status: *//')
  fi
  [ -f ".vbw-planning/config.json" ] && \
    EF=$(jq -r '.effort // "balanced"' .vbw-planning/config.json 2>/dev/null)
  git rev-parse --git-dir >/dev/null 2>&1 && BR=$(git branch --show-current 2>/dev/null)
  printf '%s\n' "${PH:-0}|${TT:-0}|${MS}|${EF}|${BR}" > "$CF"
fi

IFS='|' read -r PH TT MS EF BR < "$CF"

# Context bar with threshold colors
[ "$PCT" -ge 90 ] && BC="$R" || { [ "$PCT" -ge 70 ] && BC="$Y" || BC="$G"; }
FL=$((PCT * 10 / 100)); EM=$((10 - FL))
BAR=""; [ "$FL" -gt 0 ] && BAR=$(printf "%${FL}s" | tr ' ' '▓')
[ "$EM" -gt 0 ] && BAR="${BAR}$(printf "%${EM}s" | tr ' ' '░')"

# Duration
MINS=$((DUR / 60000)); SECS=$(((DUR % 60000) / 1000))

# Line 1: VBW project state
if [ -d ".vbw-planning" ]; then
  L1="${C}${B}[VBW]${X}"
  [ "$TT" -gt 0 ] 2>/dev/null && L1="$L1 Phase ${PH}/${TT}" || L1="$L1 Phase ${PH:-?}"
  [ -n "$MS" ] && L1="$L1 ${D}│${X} $MS"
  L1="$L1 ${D}│${X} $EF"
else
  MDL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
  L1="${C}${B}[VBW]${X} ${D}no project${X} ${D}│${X} $MDL"
fi
[ -n "$BR" ] && L1="$L1 ${D}│${X} 🌿 $BR"

# Line 2: context + cost + duration + diff
L2="${BC}${BAR}${X} ${PCT}%"
L2="$L2 ${D}│${X} ${Y}$(printf '$%.2f' "$COST")${X}"
L2="$L2 ${D}│${X} ${MINS}m ${SECS}s"
L2="$L2 ${D}│${X} ${G}+${ADDED}${X} ${R}-${REMOVED}${X}"

echo -e "$L1"
echo -e "$L2"
