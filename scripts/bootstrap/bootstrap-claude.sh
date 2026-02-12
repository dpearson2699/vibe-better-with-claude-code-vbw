#!/usr/bin/env bash
set -euo pipefail

# bootstrap-claude.sh — Generate or update CLAUDE.md with VBW sections
#
# Usage: bootstrap-claude.sh OUTPUT_PATH PROJECT_NAME CORE_VALUE [EXISTING_PATH]
#   OUTPUT_PATH    Path to write CLAUDE.md
#   PROJECT_NAME   Name of the project
#   CORE_VALUE     One-line core value statement
#   EXISTING_PATH  (Optional) Path to existing CLAUDE.md to preserve non-VBW content

if [[ $# -lt 3 ]]; then
  echo "Usage: bootstrap-claude.sh OUTPUT_PATH PROJECT_NAME CORE_VALUE [EXISTING_PATH]" >&2
  exit 1
fi

OUTPUT_PATH="$1"
PROJECT_NAME="$2"
CORE_VALUE="$3"
EXISTING_PATH="${4:-}"

# VBW-managed section headers (order matters for generation)
VBW_SECTIONS=(
  "## Active Context"
  "## VBW Rules"
  "## Key Decisions"
  "## Installed Skills"
  "## Project Conventions"
  "## Commands"
  "## Plugin Isolation"
)

# Ensure parent directory exists
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Generate VBW-managed content
generate_vbw_sections() {
  cat <<'VBWEOF'
## Active Context

**Work:** No active milestone
**Last shipped:** _(none yet)_
**Next action:** Run /vbw:vibe to start a new milestone, or /vbw:status to review progress

## VBW Rules

- **Always use VBW commands** for project work. Do not manually edit files in `.vbw-planning/`.
- **Commit format:** `{type}({scope}): {description}` — types: feat, fix, test, refactor, perf, docs, style, chore.
- **One commit per task.** Each task in a plan gets exactly one atomic commit.
- **Never commit secrets.** Do not stage .env, .pem, .key, credentials, or token files.
- **Plan before building.** Use /vbw:vibe for all lifecycle actions. Plans are the source of truth.
- **Do not fabricate content.** Only use what the user explicitly states in project-defining flows.
- **Do not bump version or push until asked.** Never run `scripts/bump-version.sh` or `git push` unless the user explicitly requests it. Commit locally and wait.

## Key Decisions

| Decision | Date | Rationale |
|----------|------|-----------|

## Installed Skills

_(Run /vbw:skills to list)_

## Project Conventions

_(To be defined during project setup)_

## Commands

Run /vbw:status for current progress.
Run /vbw:help for all available commands.

## Plugin Isolation

- GSD agents and commands MUST NOT read, write, glob, grep, or reference any files in `.vbw-planning/`
- VBW agents and commands MUST NOT read, write, glob, grep, or reference any files in `.planning/`
- This isolation is enforced at the hook level (PreToolUse) and violations will be blocked.
VBWEOF
}

# Check if a line is a VBW-managed section header
is_vbw_section() {
  local line="$1"
  for header in "${VBW_SECTIONS[@]}"; do
    if [[ "$line" == "$header" ]]; then
      return 0
    fi
  done
  return 1
}

# If existing file provided and it exists, preserve non-VBW content
if [[ -n "$EXISTING_PATH" && -f "$EXISTING_PATH" ]]; then
  # Extract non-VBW sections from existing file
  NON_VBW_CONTENT=""
  IN_VBW_SECTION=false
  FOUND_NON_VBW=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Check if this line starts a VBW section
    if is_vbw_section "$line"; then
      IN_VBW_SECTION=true
      continue
    fi

    # Check if this line starts a new non-VBW section (any ## header not in VBW list)
    if [[ "$line" =~ ^##\  ]] && ! is_vbw_section "$line"; then
      IN_VBW_SECTION=false
    fi

    # Also detect top-level heading (# Project Name) — skip it, we regenerate it
    if [[ "$line" =~ ^#\  ]] && [[ ! "$line" =~ ^##\  ]]; then
      continue
    fi

    # Skip lines starting with **Core value:** — we regenerate it
    if [[ "$line" =~ ^\*\*Core\ value:\*\* ]]; then
      continue
    fi

    if [[ "$IN_VBW_SECTION" == false ]]; then
      NON_VBW_CONTENT+="${line}"$'\n'
      FOUND_NON_VBW=true
    fi
  done < "$EXISTING_PATH"

  # Write: header + core value + preserved content + VBW sections
  {
    echo "# ${PROJECT_NAME}"
    echo ""
    echo "**Core value:** ${CORE_VALUE}"
    echo ""
    if [[ "$FOUND_NON_VBW" == true ]]; then
      # Trim leading/trailing blank lines from preserved content
      echo "$NON_VBW_CONTENT" | sed '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
      echo ""
    fi
    generate_vbw_sections
  } > "$OUTPUT_PATH"
else
  # New file: generate fresh
  {
    echo "# ${PROJECT_NAME}"
    echo ""
    echo "**Core value:** ${CORE_VALUE}"
    echo ""
    generate_vbw_sections
  } > "$OUTPUT_PATH"
fi

exit 0
