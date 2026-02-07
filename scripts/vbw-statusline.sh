#!/bin/bash
# VBW Status Line for Claude Code — 4/5-Line Dashboard
# Line 1: [VBW] Phase N/M │ Plans: done/total (N this phase) │ Effort: X │ QA: pass │ Branch: main
# Line 2: ▓▓▓▓▓▓▓▓░░░░░░░░░░░░ 42% │ Tokens: 15.2K in  1.2K out │ Cache: 5.0K write  2.0K read
# Line 3: Session: ██░░░░░░░░  6% resets 2h 13m │ Weekly: ███░░░░░░░ 35% resets Thu 04:00 │ Opus: ░░░░░░░░░░  0%
# Line 4: Model: Opus │ Cost: $1.42 │ Time: 12m 34s (API: 23s) │ Diff: +156 -23 │ CC 1.0.11
# Line 5: Team: build-team │ researcher ◆ │ tester ○ │ dev-1 ✓ │ Tasks: 3/5  (conditional)

input=$(cat)

# Colors
C='\033[36m' G='\033[32m' Y='\033[33m' R='\033[31m'
D='\033[2m' B='\033[1m' X='\033[0m'

# --- Cached platform info ---
_UID=$(id -u)
_OS=$(uname)

# --- Helpers ---

# Single awk call for all formatting: mode tok|cost|dur, value
fmt() {
  awk -v mode="$1" -v val="$2" 'BEGIN {
    v = val + 0
    if (mode == "tok") {
      if (v >= 1000000)      printf "%.1fM", v/1000000
      else if (v >= 1000)    printf "%.1fK", v/1000
      else                   printf "%d", v
    } else if (mode == "cost") {
      if (v >= 100)       printf "$%.0f", v
      else if (v >= 10)   printf "$%.1f", v
      else                printf "$%.2f", v
    } else if (mode == "dur") {
      s = int(v / 1000)
      if (s >= 3600) { h=int(s/3600); m=int((s%3600)/60); printf "%dh %dm", h, m }
      else if (s >= 60) { m=int(s/60); r=s%60; printf "%dm %ds", m, r }
      else printf "%ds", s
    }
  }'
}

# Check if a cache file is still fresh (within TTL seconds)
# Usage: cache_fresh <file> <ttl_seconds>
cache_fresh() {
  local cf="$1" ttl="$2"
  [ ! -f "$cf" ] && return 1
  local mt
  if [ "$_OS" = "Darwin" ]; then
    mt=$(stat -f %m "$cf" 2>/dev/null || echo 0)
  else
    mt=$(stat -c %Y "$cf" 2>/dev/null || echo 0)
  fi
  [ $((NOW - mt)) -le "$ttl" ]
}

# Build a progress bar: progress_bar <percent> <width>
# Returns colored bar string
progress_bar() {
  local pct="$1" width="$2"
  local filled=$((pct * width / 100))
  [ "$filled" -gt "$width" ] && filled="$width"
  local empty=$((width - filled))
  local color
  if [ "$pct" -ge 80 ]; then color="$R"
  elif [ "$pct" -ge 50 ]; then color="$Y"
  else color="$G"
  fi
  local bar=""
  [ "$filled" -gt 0 ] && bar=$(printf "%${filled}s" | tr ' ' '█')
  [ "$empty" -gt 0 ] && bar="${bar}$(printf "%${empty}s" | tr ' ' '░')"
  printf '%b%s%b' "$color" "$bar" "$X"
}

# --- Session data: single jq call ---

IFS='|' read -r PCT REM IN_TOK OUT_TOK CACHE_W CACHE_R CTX_SIZE \
               COST DUR_MS API_MS ADDED REMOVED MODEL VER <<< \
  "$(echo "$input" | jq -r '[
    (.context_window.used_percentage // 0 | floor),
    (.context_window.remaining_percentage // 100 | floor),
    (.context_window.current_usage.input_tokens // 0),
    (.context_window.current_usage.output_tokens // 0),
    (.context_window.current_usage.cache_creation_input_tokens // 0),
    (.context_window.current_usage.cache_read_input_tokens // 0),
    (.context_window.context_window_size // 200000),
    (.cost.total_cost_usd // 0),
    (.cost.total_duration_ms // 0),
    (.cost.total_api_duration_ms // 0),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.model.display_name // "Claude"),
    (.version // "?")
  ] | join("|")' 2>/dev/null)"

# Defaults on jq failure
PCT=${PCT:-0}; REM=${REM:-100}; IN_TOK=${IN_TOK:-0}; OUT_TOK=${OUT_TOK:-0}
CACHE_W=${CACHE_W:-0}; CACHE_R=${CACHE_R:-0}; COST=${COST:-0}
DUR_MS=${DUR_MS:-0}; API_MS=${API_MS:-0}; ADDED=${ADDED:-0}; REMOVED=${REMOVED:-0}
MODEL=${MODEL:-Claude}; VER=${VER:-?}

NOW=$(date +%s)

# --- VBW state (cached 5s) ---

VBW_CF="/tmp/vbw-sl-cache-${_UID}"

if ! cache_fresh "$VBW_CF" 5; then
  PH=""; TT=""; ST=""; EF="balanced"; BR=""
  PD=0; PT=0; PPD=0; QA="--"
  if [ -f ".vbw-planning/STATE.md" ]; then
    PH=$(grep -m1 "^Phase:" .vbw-planning/STATE.md | grep -oE '[0-9]+' | head -1)
    TT=$(grep -m1 "^Phase:" .vbw-planning/STATE.md | grep -oE '[0-9]+' | tail -1)
    ST=$(grep -m1 "^Status:" .vbw-planning/STATE.md | sed 's/^Status: *//')
  fi
  [ -f ".vbw-planning/config.json" ] && \
    EF=$(jq -r '.effort // "balanced"' .vbw-planning/config.json 2>/dev/null)
  git rev-parse --git-dir >/dev/null 2>&1 && BR=$(git branch --show-current 2>/dev/null)

  # Plan counting
  if [ -d ".vbw-planning/phases" ]; then
    PT=$(find .vbw-planning/phases -name '*-PLAN.md' 2>/dev/null | wc -l | tr -d ' ')
    PD=$(find .vbw-planning/phases -name '*-SUMMARY.md' 2>/dev/null | wc -l | tr -d ' ')
    # Current phase plans done
    if [ -n "$PH" ] && [ "$PH" != "0" ]; then
      PDIR=$(find .vbw-planning/phases -maxdepth 1 -type d -name "$(printf '%02d' "$PH")-*" 2>/dev/null | head -1)
      [ -n "$PDIR" ] && PPD=$(find "$PDIR" -name '*-SUMMARY.md' 2>/dev/null | wc -l | tr -d ' ')
      [ -n "$PDIR" ] && [ -n "$(find "$PDIR" -name '*VERIFICATION.md' 2>/dev/null | head -1)" ] && QA="pass"
    fi
  fi

  printf '%s\n' "${PH:-0}|${TT:-0}|${ST}|${EF}|${BR}|${PD}|${PT}|${PPD}|${QA}" > "$VBW_CF"
fi

IFS='|' read -r PH TT ST EF BR PD PT PPD QA < "$VBW_CF"

# --- Usage limits (cached 60s) ---

USAGE_CF="/tmp/vbw-usage-cache-${_UID}"
USAGE_LINE=""

if ! cache_fresh "$USAGE_CF" 60; then
  # Try to get OAuth token from macOS Keychain
  OAUTH_TOKEN=""
  if [ "$_OS" = "Darwin" ]; then
    CRED_JSON=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    if [ -n "$CRED_JSON" ]; then
      OAUTH_TOKEN=$(echo "$CRED_JSON" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    fi
  fi

  if [ -n "$OAUTH_TOKEN" ]; then
    USAGE_RAW=$(curl -s --max-time 3 \
      -H "Authorization: Bearer ${OAUTH_TOKEN}" \
      "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

    if [ -n "$USAGE_RAW" ] && echo "$USAGE_RAW" | jq -e '.five_hour' >/dev/null 2>&1; then
      # Parse all usage data in a single jq call, pre-compute epoch + weekly label
      eval "$(echo "$USAGE_RAW" | jq -r '
        def pct: (. * 100 | floor);
        def epoch: gsub("\\.[0-9]+"; "") | gsub("Z$"; "+00:00") | split("+")[0] + "Z" | fromdate;
        def wlabel: gsub("\\.[0-9]+"; "") | gsub("Z$"; "+00:00") | split("+")[0] + "Z" | fromdate |
          strftime("%a %H:%M");
        "FIVE_PCT=" + ((.five_hour.utilization // 0) | pct | tostring),
        "FIVE_EPOCH=" + ((.five_hour.resets_at // "") | if . == "" then "0" else epoch | tostring end),
        "WEEK_PCT=" + ((.seven_day.utilization // 0) | pct | tostring),
        "WEEK_LABEL=" + ((.seven_day.resets_at // "") | if . == "" then "N/A" else wlabel end),
        "OPUS_PCT=" + ((.seven_day_opus.utilization // 0) | pct | tostring)
      ' 2>/dev/null)"

      printf '%s\n' "${FIVE_PCT:-0}|${FIVE_EPOCH:-0}|${WEEK_PCT:-0}|${WEEK_LABEL:-N/A}|${OPUS_PCT:-0}|ok" > "$USAGE_CF"
    else
      printf '%s\n' "0|0|0|N/A|0|fail" > "$USAGE_CF"
    fi
  else
    printf '%s\n' "noauth" > "$USAGE_CF"
  fi
fi

USAGE_DATA=$(cat "$USAGE_CF" 2>/dev/null)

if [ "$USAGE_DATA" != "noauth" ]; then
  IFS='|' read -r FIVE_PCT FIVE_EPOCH WEEK_PCT WEEK_LABEL OPUS_PCT FETCH_OK <<< "$USAGE_DATA"

  if [ "$FETCH_OK" = "ok" ]; then
    # Session countdown: pure bash arithmetic
    FIVE_REM=""
    if [ "${FIVE_EPOCH:-0}" -gt 0 ] 2>/dev/null; then
      DIFF=$((FIVE_EPOCH - NOW))
      if [ "$DIFF" -gt 0 ]; then
        HH=$((DIFF / 3600))
        MM=$(( (DIFF % 3600) / 60 ))
        FIVE_REM="${HH}h ${MM}m"
      else
        FIVE_REM="now"
      fi
    fi

    USAGE_LINE="Session: $(progress_bar "${FIVE_PCT:-0}" 10) ${FIVE_PCT:-0}%"
    [ -n "$FIVE_REM" ] && USAGE_LINE="$USAGE_LINE resets $FIVE_REM"
    USAGE_LINE="$USAGE_LINE ${D}│${X} Weekly: $(progress_bar "${WEEK_PCT:-0}" 10) ${WEEK_PCT:-0}%"
    [ "$WEEK_LABEL" != "N/A" ] && USAGE_LINE="$USAGE_LINE resets $WEEK_LABEL"
    USAGE_LINE="$USAGE_LINE ${D}│${X} Opus: $(progress_bar "${OPUS_PCT:-0}" 10) ${OPUS_PCT:-0}%"
  else
    USAGE_LINE="${D}Limits: fetch failed (retry in 60s)${X}"
  fi
else
  USAGE_LINE="${D}Limits: N/A (using API key)${X}"
fi

# --- Team status (cached 3s) ---

TEAM_CF="/tmp/vbw-team-cache-${_UID}"
TEAM_LINE=""

if ! cache_fresh "$TEAM_CF" 3; then
  TEAM_DATA=""
  # Find active team configs
  TEAM_DIR="$HOME/.claude/teams"
  if [ -d "$TEAM_DIR" ]; then
    for tcfg in "$TEAM_DIR"/*/config.json; do
      [ -f "$tcfg" ] || continue
      TNAME=$(jq -r '.team_name // empty' "$tcfg" 2>/dev/null)
      [ -z "$TNAME" ] && continue

      # Get members list
      MEMBERS=$(jq -r '.members[]?.name // empty' "$tcfg" 2>/dev/null)
      [ -z "$MEMBERS" ] && continue

      # Determine task dir
      TASK_DIR="$HOME/.claude/tasks/${TNAME}"

      # Build member status via single jq across all task files
      MEMBER_STATUS=""
      DONE=0; TOTAL=0
      if [ -d "$TASK_DIR" ]; then
        TASK_DATA=$(jq -s '[.[] | {owner: (.owner // ""), status: (.status // "")}]' "$TASK_DIR"/*.json 2>/dev/null)
        if [ -n "$TASK_DATA" ]; then
          TOTAL=$(echo "$TASK_DATA" | jq 'length' 2>/dev/null)
          DONE=$(echo "$TASK_DATA" | jq '[.[] | select(.status == "completed")] | length' 2>/dev/null)
        fi
      fi

      # Build member indicators
      while IFS= read -r mname; do
        [ -z "$mname" ] && continue
        # Check if member has an in_progress task
        HAS_ACTIVE="false"
        HAS_DONE="false"
        if [ -n "$TASK_DATA" ]; then
          HAS_ACTIVE=$(echo "$TASK_DATA" | jq --arg n "$mname" '[.[] | select(.owner == $n and .status == "in_progress")] | length > 0' 2>/dev/null)
          HAS_DONE=$(echo "$TASK_DATA" | jq --arg n "$mname" '[.[] | select(.owner == $n and .status == "completed")] | length > 0' 2>/dev/null)
        fi
        if [ "$HAS_ACTIVE" = "true" ]; then
          MEMBER_STATUS="$MEMBER_STATUS ${D}│${X} $mname ${C}◆${X}"
        elif [ "$HAS_DONE" = "true" ]; then
          MEMBER_STATUS="$MEMBER_STATUS ${D}│${X} $mname ${G}✓${X}"
        else
          MEMBER_STATUS="$MEMBER_STATUS ${D}│${X} $mname ${D}○${X}"
        fi
      done <<< "$MEMBERS"

      TEAM_DATA="Team: ${C}${TNAME}${X}${MEMBER_STATUS} ${D}│${X} Tasks: ${DONE:-0}/${TOTAL:-0}"
      break  # Show first active team only
    done
  fi
  # Write empty string if no teams
  printf '%s\n' "$TEAM_DATA" > "$TEAM_CF"
fi

TEAM_LINE=$(cat "$TEAM_CF" 2>/dev/null)

# --- Context bar (20 chars wide) ---

[ "$PCT" -ge 90 ] && BC="$R" || { [ "$PCT" -ge 70 ] && BC="$Y" || BC="$G"; }
FL=$((PCT * 20 / 100)); EM=$((20 - FL))
BAR=""; [ "$FL" -gt 0 ] && BAR=$(printf "%${FL}s" | tr ' ' '▓')
[ "$EM" -gt 0 ] && BAR="${BAR}$(printf "%${EM}s" | tr ' ' '░')"

# --- Line 1: VBW project state ---

if [ -d ".vbw-planning" ]; then
  L1="${C}${B}[VBW]${X}"
  [ "$TT" -gt 0 ] 2>/dev/null && L1="$L1 Phase ${PH}/${TT}" || L1="$L1 Phase ${PH:-?}"
  [ "$PT" -gt 0 ] 2>/dev/null && L1="$L1 ${D}│${X} Plans: ${PD}/${PT} (${PPD} this phase)"
  L1="$L1 ${D}│${X} Effort: $EF"
  if [ "$QA" = "pass" ]; then
    L1="$L1 ${D}│${X} ${G}QA: pass${X}"
  else
    L1="$L1 ${D}│${X} ${D}QA: --${X}"
  fi
else
  L1="${C}${B}[VBW]${X} ${D}no project${X}"
fi
[ -n "$BR" ] && L1="$L1 ${D}│${X} Branch: $BR"

# --- Line 2: context window deep metrics ---

L2="${BC}${BAR}${X} ${PCT}%"
L2="$L2 ${D}│${X} Tokens: $(fmt tok "$IN_TOK") in  $(fmt tok "$OUT_TOK") out"
L2="$L2 ${D}│${X} Cache: $(fmt tok "$CACHE_W") write  $(fmt tok "$CACHE_R") read"

# --- Line 3: usage limits ---

L3="$USAGE_LINE"

# --- Line 4: session economy ---

L4="Model: ${D}${MODEL}${X}"
L4="$L4 ${D}│${X} Cost: ${Y}$(fmt cost "$COST")${X}"
L4="$L4 ${D}│${X} Time: $(fmt dur "$DUR_MS") (API: $(fmt dur "$API_MS"))"
L4="$L4 ${D}│${X} Diff: ${G}+${ADDED}${X} ${R}-${REMOVED}${X}"
L4="$L4 ${D}│${X} ${D}CC ${VER}${X}"

# --- Output ---

echo -e "$L1"
echo -e "$L2"
echo -e "$L3"
echo -e "$L4"
# Line 5: team status (only if teams active)
[ -n "$TEAM_LINE" ] && echo -e "$TEAM_LINE"

exit 0
