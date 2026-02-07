---
description: Investigate a bug using the Debugger agent's scientific method protocol.
argument-hint: "<bug description or error message>"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch
---

# VBW Debug: $ARGUMENTS

## Context

Working directory: `!`pwd``

Current state:
```
!`cat .vbw-planning/STATE.md 2>/dev/null || echo "No state found"`
```

Recent commits:
```
!`git log --oneline -10 2>/dev/null || echo "No git history"`
```

## Guard

1. **Not initialized:** If .vbw-planning/ doesn't exist, STOP: "Run /vbw:init first."
2. **Missing bug description:** If $ARGUMENTS is empty, STOP: "Usage: /vbw:debug \"description of the bug or error message\""

## Steps

### Step 1: Parse and resolve effort

The entire $ARGUMENTS string is the bug description.

Read effort from config or --effort flag. Map per `${CLAUDE_PLUGIN_ROOT}/references/effort-profiles.md`:

| Profile  | DEBUGGER_EFFORT |
|----------|-----------------|
| Thorough | high            |
| Balanced | medium          |
| Fast     | medium          |
| Turbo    | low             |

### Step 2: Spawn Debugger agent

Spawn vbw-debugger as a subagent via the Task tool with thin context:

```
Bug investigation. Effort: {DEBUGGER_EFFORT}.
Bug report: {description}.
Working directory: {pwd}.
Follow protocol: reproduce, hypothesize, gather evidence, diagnose, fix, verify, document.
If you apply a fix, commit with: fix({scope}): {description}.
```

### Step 3: Present investigation summary

```
┌──────────────────────────────────────────┐
│  Bug Investigation Complete              │
└──────────────────────────────────────────┘

  Issue:      {one-line summary}
  Root Cause: {from report}
  Fix:        {commit hash and message, or "No fix applied"}

  Files Modified: {list}

➜ Next: /vbw:status -- View project status
```

## Output Format

Follow @${CLAUDE_PLUGIN_ROOT}/references/vbw-brand.md:
- Single-line box for investigation banner
- Metrics Block for issue/root cause/fix
- Next Up Block for navigation
- No ANSI color codes
