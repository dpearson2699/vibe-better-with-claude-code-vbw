---
description: Start a new milestone cycle with isolated state and phase numbering.
argument-hint: <milestone-name> [--branch]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# VBW Milestone: $ARGUMENTS

## Context

Working directory: `!`pwd``

Active milestone:
```
!`cat .planning/ACTIVE 2>/dev/null || echo "No active milestone (single-milestone mode)"`
```

Existing milestones:
```
!`ls -d .planning/*/ 2>/dev/null || echo "No milestone directories"`
```

Config:
```
!`cat .planning/config.json 2>/dev/null || echo "No config found"`
```

## Guard

1. **Not initialized:** If `.planning/` directory doesn't exist, STOP: "Run /vbw:init first."

2. **Missing milestone name:** If `$ARGUMENTS` doesn't include a milestone name (only flags or empty), STOP: "Usage: /vbw:milestone <milestone-name> [--branch]"

3. **Milestone exists:** If `.planning/{slug}/` already exists (where `{slug}` is the slugified milestone name), STOP: "Milestone '{name}' already exists. Use /vbw:switch {name} to activate it."

4. **First milestone migration:** If `.planning/ACTIVE` does not exist AND `.planning/ROADMAP.md` exists at the top level (single-milestone mode with existing work), this is a migration scenario. The command must handle migrating existing state into a "default" milestone before creating the new one. Display: "Existing work detected. Migrating current state to 'default' milestone before creating '{name}'." Then perform migration in Step 2.

## Steps

### Step 1: Parse arguments

Extract from `$ARGUMENTS`:
- **Milestone name:** First non-flag argument (everything except `--branch`)
- **Slug generation:** Lowercase the name, replace spaces with hyphens, strip special characters except hyphens
  - Example: "v2.0 Launch" becomes "v2-0-launch"
  - Example: "Mobile App" becomes "mobile-app"
- **--branch flag:** If present, enable git branch integration (Step 5)

### Step 2: Handle first-milestone migration (if needed)

Only runs if Guard condition 4 triggered (single-milestone mode with existing work).

1. Create `.planning/default/` directory
2. Move existing milestone-scoped files into `.planning/default/`:
   - Move `.planning/ROADMAP.md` to `.planning/default/ROADMAP.md`
   - Move `.planning/STATE.md` to `.planning/default/STATE.md`
   - Move `.planning/phases/` to `.planning/default/phases/`
3. Write `.planning/ACTIVE` with content: `default`
4. Display: "✓ Migrated existing work to 'default' milestone"

Files that stay at `.planning/` root (shared across all milestones):
- `.planning/PROJECT.md` -- project-level, shared
- `.planning/config.json` -- project-level, shared
- `.planning/REQUIREMENTS.md` -- project-level, shared (milestones reference requirements from here)
- `.planning/codebase/` -- shared mapping data (if exists)

### Step 3: Create milestone directory

1. Create `.planning/{slug}/` directory
2. Create `.planning/{slug}/ROADMAP.md` by reading the ROADMAP template from `${CLAUDE_PLUGIN_ROOT}/templates/ROADMAP.md` and writing a fresh milestone-scoped roadmap with:
   - Title: `# Roadmap: {milestone-name}`
   - Empty phase list (user will add phases via /vbw:plan or /vbw:add-phase)
   - Phase numbering note: "Phase numbering starts at 01 for this milestone."
3. Create `.planning/{slug}/STATE.md` by reading the STATE template from `${CLAUDE_PLUGIN_ROOT}/templates/STATE.md` and writing a fresh milestone-scoped state with:
   - Current milestone name in the header
   - Phase 0 of 0 (no phases yet)
   - Empty decisions table
   - Empty concerns section
4. Create `.planning/{slug}/phases/` directory (use `mkdir -p`)

### Step 4: Update ACTIVE pointer

Write the milestone slug to `.planning/ACTIVE` (plain text file, single line, no trailing newline padding):

```
{slug}
```

This file is the single source of truth for which milestone is active. All VBW commands read this file to determine milestone context.

### Step 5: Optional git branch integration

If `--branch` flag is present:
1. Create a new git branch named `milestone/{slug}` from the current branch
2. Switch to that branch: `git checkout -b milestone/{slug}`
3. Display: "✓ Created and switched to branch milestone/{slug}"

If `--branch` flag is NOT present:
- Display: "○ Git branch integration skipped (use --branch to create a dedicated branch)"

### Step 6: Present summary

Display using brand formatting from @${CLAUDE_PLUGIN_ROOT}/references/vbw-brand.md.

If migration happened in Step 2, prepend this warning line before the banner:

```
  ⚠ Migrated existing work to 'default' milestone
```

Then display the milestone creation banner and details:

```
╔═══════════════════════════════════════════╗
║  Milestone Created: {milestone-name}      ║
║  Slug: {slug}                             ║
╚═══════════════════════════════════════════╝

  ✓ .planning/{slug}/ROADMAP.md
  ✓ .planning/{slug}/STATE.md
  ✓ .planning/{slug}/phases/
  ✓ .planning/ACTIVE -> {slug}

  Shared (project-level):
    PROJECT.md, config.json, REQUIREMENTS.md

➜ Next Up
  /vbw:add-phase {phase-name} -- Add a phase to this milestone
  /vbw:discuss 1 -- Start defining your first phase
```

## Output Format

Follow @${CLAUDE_PLUGIN_ROOT}/references/vbw-brand.md for all visual formatting:
- Use the **Phase Banner** template (double-line box) for the milestone creation banner
- Use the **File Checklist** template for the created files list (✓ prefix)
- Use the **Next Up Block** template for navigation (➜ header, indented commands with --)
- ○ for pending/skipped items
- Keep lines under 80 characters inside boxes
- No ANSI color codes
