---
description: Update VBW to the latest version.
argument-hint: "[--check]"
allowed-tools: Read, Bash, Glob
---

# VBW Update $ARGUMENTS

## Context

Current version:
```
!`cat ${CLAUDE_PLUGIN_ROOT}/VERSION 2>/dev/null || echo "unknown"`
```

## Steps

### Step 1: Read current version

Read `${CLAUDE_PLUGIN_ROOT}/VERSION`. Store as `old_version`.

### Step 2: Handle --check

If --check: display version and update instructions, then STOP.

```
╔═══════════════════════════════════════════╗
║  VBW Version Check                        ║
╚═══════════════════════════════════════════╝

  Current version: {old_version}

  To update: claude plugin update vbw
```

### Step 3: Attempt update

Run: `claude plugin update vbw`

If fails, show manual instructions:
```
⚠ Automatic update not available

  1. Visit the VBW repository
  2. Pull latest version
  3. Re-install: claude plugin install
```

### Step 4: Verify and display

Read VERSION again for `new_version`.

If changed:
```
╔═══════════════════════════════════════════╗
║  VBW Updated                              ║
╚═══════════════════════════════════════════╝

  ✓ Updated: {old_version} -> {new_version}

➜ Next Up
  /vbw:whats-new {old_version} -- See what changed
```

If unchanged:
```
✓ VBW is already up to date ({new_version}).

➜ Next Up
  /vbw:help -- View all commands
```

## Output Format

Follow @${CLAUDE_PLUGIN_ROOT}/references/vbw-brand.md:
- Double-line box for header
- ✓ success, ⚠ fallback warning
- Next Up Block
- No ANSI color codes
