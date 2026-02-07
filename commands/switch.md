---
description: Switch the active milestone context for all subsequent VBW commands.
argument-hint: <milestone-name>
allowed-tools: Read, Write, Bash, Glob, Grep
---

# VBW Switch: $ARGUMENTS

## Context

Working directory: `!`pwd``

Active milestone:
```
!`cat .planning/ACTIVE 2>/dev/null || echo "No active milestone"`
```

Available milestones:
```
!`ls -d .planning/*/ROADMAP.md 2>/dev/null || echo "No milestone directories"`
```

## Guard

1. **Not initialized:** If `.planning/` directory doesn't exist, STOP: "Run /vbw:init first."

2. **No milestones:** If `.planning/ACTIVE` does not exist, STOP: "No milestones configured. Use /vbw:milestone <name> to create one."

3. **Missing milestone name:** If `$ARGUMENTS` is empty, display available milestones and prompt:

   List all milestone directories under `.planning/` that contain a `ROADMAP.md`. Mark the currently active one (from `.planning/ACTIVE`) with ◆ and others with ○:

   ```
   Available milestones:
     ◆ {active-slug} (active)
     ○ {other-slug}
     ○ {other-slug}

   Usage: /vbw:switch <milestone-name>
   ```

   Then STOP.

4. **Invalid milestone:** If `.planning/{slug}/` does not exist or does not contain a `ROADMAP.md`, STOP: "Milestone '{name}' not found." followed by the available milestones list (same format as condition 3).

## Steps

### Step 1: Parse arguments

- Extract milestone name or slug from `$ARGUMENTS`
- Normalize to slug format: lowercase, replace spaces with hyphens, strip special characters except hyphens
  - Example: "Mobile App" normalizes to "mobile-app"
- Validate that `.planning/{slug}/` exists and contains `ROADMAP.md`

### Step 2: Read current state

- Read `.planning/ACTIVE` to get the current active milestone slug
- If the target slug matches the current active slug, display: "Already on milestone '{name}'." and STOP
- Read `.planning/{slug}/STATE.md` to get the target milestone's current position:
  - Phase number and total phases
  - Plan count and progress percentage
  - Progress bar data

### Step 3: Update ACTIVE pointer

Write the new milestone slug to `.planning/ACTIVE` (overwrite existing content):

```
{slug}
```

### Step 4: Optional git branch switch

Check if a git branch named `milestone/{slug}` exists:

- Use `git branch --list milestone/{slug}` to check
- If the branch exists: switch to it with `git checkout milestone/{slug}` and display: "✓ Switched to branch milestone/{slug}"
- If no matching branch exists: skip silently (no message)

### Step 5: Present summary

Display using brand formatting from @${CLAUDE_PLUGIN_ROOT}/references/vbw-brand.md:

```
╔═══════════════════════════════════════════╗
║  Switched to: {milestone-name}            ║
╚═══════════════════════════════════════════╝

  Previous: {old-slug}
  Active:   {new-slug}

  Milestone State:
    Phase:    {current-phase}/{total-phases}
    Progress: {progress-bar} {percent}%

➜ Next Up
  /vbw:status -- View milestone progress
  /vbw:plan {N} -- Plan the next phase
```

If git branch was switched in Step 4, add after the Active line:

```
  Branch:   milestone/{slug}
```

## Output Format

Follow @${CLAUDE_PLUGIN_ROOT}/references/vbw-brand.md for all visual formatting:
- Use the **Phase Banner** template (double-line box) for the switch confirmation banner
- Use the **Metrics Block** template for the previous/active and milestone state display
- Progress bar: 10 characters wide using █ for filled, ░ for empty, paired with percentage
- Use the **Next Up Block** template for navigation (➜ header, indented commands with --)
- No ANSI color codes
- Keep lines under 80 characters inside boxes
