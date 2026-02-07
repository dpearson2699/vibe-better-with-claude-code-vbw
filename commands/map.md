---
description: Analyze existing codebase with parallel Scout teammates to produce structured mapping documents.
argument-hint: [--incremental] [--package=name]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch
---

# VBW Map: $ARGUMENTS

## Context

Working directory: `!`pwd``

Existing mapping:
```
!`ls .vbw-planning/codebase/ 2>/dev/null || echo "No codebase mapping found"`
```

Current META.md:
```
!`cat .vbw-planning/codebase/META.md 2>/dev/null || echo "No META.md found"`
```

Project files:
```
!`ls package.json pyproject.toml Cargo.toml go.mod *.sln Gemfile build.gradle pom.xml 2>/dev/null || echo "No standard project files found"`
```

Git HEAD:
```
!`git rev-parse HEAD 2>/dev/null || echo "no-git"`
```

## Guard

1. **Not initialized:** If .vbw-planning/ doesn't exist, STOP: "Run /vbw:init first."
2. **No git repo:** If not a git repo, WARN: "Not a git repo -- incremental mapping disabled." Continue in full mode.
3. **Empty project:** If no source files detected, STOP: "No source code found to map."

## Steps

### Step 1: Parse arguments and detect mode

- **--incremental**: force incremental refresh
- **--package=name**: scope to a single monorepo package

**Mode detection:**
1. If META.md exists and git repo: compare `git_hash` from META.md to HEAD. If <20% files changed: incremental. Otherwise: full.
2. If no META.md or no git: full mode.

Store `MAPPING_MODE` (full|incremental) and `CHANGED_FILES` (list, empty if full).

### Step 2: Detect monorepo

Check for: lerna.json, pnpm-workspace.yaml, packages/ or apps/ with sub-package.json, root package.json workspaces field.

If monorepo: enumerate packages. If `--package=name`: scope mapping to that package only.

### Step 3: Create mapping team with 4 Scout teammates

Create an Agent Team with 4 Scout teammates. Each gets a task in the shared task list with thin context:

**Scout 1 -- Tech Stack:**
```
Map tech stack. Write STACK.md and DEPENDENCIES.md to .vbw-planning/codebase/.
Mode: {MAPPING_MODE}. {If incremental: "Changed files: {list}"}
{If monorepo: "Packages: {list}"}
```

**Scout 2 -- Architecture:**
```
Map architecture. Write ARCHITECTURE.md and STRUCTURE.md to .vbw-planning/codebase/.
Mode: {MAPPING_MODE}. {If incremental: "Changed files: {list}"}
{If monorepo: "Packages: {list}"}
```

**Scout 3 -- Quality:**
```
Map quality signals. Write CONVENTIONS.md and TESTING.md to .vbw-planning/codebase/.
Mode: {MAPPING_MODE}. {If incremental: "Changed files: {list}"}
{If monorepo: "Packages: {list}"}
```

**Scout 4 -- Concerns:**
```
Map concerns. Write CONCERNS.md to .vbw-planning/codebase/.
Mode: {MAPPING_MODE}. {If incremental: "Changed files: {list}"}
{If monorepo: "Packages: {list}"}
```

Security enforcement is handled by the PreToolUse hook -- no inline exclusion lists needed.

Wait for all teammates to complete. Verify all 7 documents exist.

### Step 4: Synthesize INDEX.md and PATTERNS.md

After all teammates complete, read all 7 mapping documents and produce:

**INDEX.md:** Cross-referenced index with key findings and cross-references per document. Add a "Validation Notes" section flagging any contradictions between mapper outputs.

**PATTERNS.md:** Recurring patterns extracted across documents: architectural, naming, quality, concern, and dependency patterns.

### Step 5: Create META.md and present summary

Write META.md with: mapped_at timestamp, git_hash, file_count, document list, mode, monorepo flag.

Display using `${CLAUDE_PLUGIN_ROOT}/references/vbw-brand.md`:

```
╔══════════════════════════════════════════╗
║  Codebase Mapped                         ║
║  Mode: {full | incremental}              ║
╚══════════════════════════════════════════╝

  ✓ STACK.md          -- Tech stack and frameworks
  ✓ DEPENDENCIES.md   -- Dependency graph and versions
  ✓ ARCHITECTURE.md   -- Code organization and data flow
  ✓ STRUCTURE.md      -- Directory tree and file patterns
  ✓ CONVENTIONS.md    -- Naming rules and code style
  ✓ TESTING.md        -- Test framework and coverage
  ✓ CONCERNS.md       -- Technical debt and risks
  ✓ INDEX.md          -- Cross-referenced index
  ✓ PATTERNS.md       -- Recurring codebase patterns

  Key Findings:
    ◆ {finding from INDEX.md}
    ◆ {finding from INDEX.md}
    ◆ {finding from INDEX.md}

➜ Next Up
  /vbw:plan {next-phase} -- Plan with codebase context
```

## Output Format

Follow @${CLAUDE_PLUGIN_ROOT}/references/vbw-brand.md:
- Phase Banner (double-line box) for completion
- File Checklist (✓ prefix) for documents
- ◆ for key findings, ⚠ for validation warnings
- Next Up Block for navigation
- No ANSI color codes
