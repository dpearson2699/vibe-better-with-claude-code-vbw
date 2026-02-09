---
name: release
description: Bump version, finalize changelog, commit, and push a release to GitHub.
argument-hint: "[--dry-run] [--no-push] [--major] [--minor]"
allowed-tools: Read, Edit, Bash, Glob, Grep
---

# VBW Release $ARGUMENTS

## Context

Working directory: `!`pwd``

Current version:
```
!`cat VERSION 2>/dev/null || echo "No VERSION file"`
```

Git status:
```
!`git status --short 2>/dev/null || echo "Not a git repository"`
```

## Guard

1. **Not a VBW repo:** If `VERSION` does not exist, STOP: "No VERSION file found. This command must be run from the VBW plugin root."
2. **Dirty working tree:** If `git status --porcelain` shows uncommitted changes (excluding .claude/ and CLAUDE.md), WARN: "Uncommitted changes detected. They will NOT be included in the release commit. Continue?" Wait for confirmation.
3. **No changelog [Unreleased] section:** If CHANGELOG.md does not contain `## [Unreleased]`, WARN: "No [Unreleased] section in CHANGELOG.md. The release commit will only bump version files. Continue?"
4. **Version sync check:** Run `bash scripts/bump-version.sh --verify`. If files are out of sync, WARN but proceed (the bump will fix them).

## Steps

### Step 1: Parse arguments

- **--dry-run**: Show what would happen without making changes. Display the planned version, changelog rename, files to commit, and exit.
- **--no-push**: Bump, commit, but do not push. Useful for reviewing before pushing.
- **--major**: Bump major version (1.0.70 -> 2.0.0) instead of patch.
- **--minor**: Bump minor version (1.0.70 -> 1.1.0) instead of patch.

If no flags: bump patch version (default behavior of `bump-version.sh`).

### Step 2: Bump version

If **--major** or **--minor**:
1. Read current version from `VERSION`
2. Compute new version:
   - `--major`: increment major, reset minor and patch to 0
   - `--minor`: increment minor, reset patch to 0
3. Write new version to all 4 files manually (same files as `bump-version.sh`):
   - `VERSION`
   - `.claude-plugin/plugin.json` (`.version`)
   - `.claude-plugin/marketplace.json` (`.plugins[0].version`)
   - `marketplace.json` (`.plugins[0].version`)

If neither flag: run `bash scripts/bump-version.sh` (auto-increments patch).

Capture the new version number for subsequent steps.

### Step 3: Update CHANGELOG header

If CHANGELOG.md contains `## [Unreleased]`:
1. Replace `## [Unreleased]` with `## [{new-version}] - {YYYY-MM-DD}` (today's date)
2. Display "✓ CHANGELOG.md: [Unreleased] -> [{new-version}] - {date}"

If no `[Unreleased]` section: display "○ CHANGELOG.md: no [Unreleased] section to rename"

### Step 4: Verify version sync

Run `bash scripts/bump-version.sh --verify` to confirm all 4 files are now in sync at the new version. If this fails, STOP: "Version sync failed after bump. This should not happen -- investigate manually."

### Step 5: Commit

Stage the following files individually (only if they were modified):
- `VERSION`
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `marketplace.json`
- `CHANGELOG.md` (only if [Unreleased] was renamed)

Commit with message:
```
chore: release v{new-version}
```

Display "✓ Committed: chore: release v{new-version}"

### Step 6: Push

If **--no-push**: display "○ Push skipped (--no-push). Run `git push` when ready."

Otherwise:
1. `git push`
2. `git push --tags` (if any tags exist for this commit)
3. Display "✓ Pushed to {remote}/{branch}"

### Step 7: Present summary

Display using VBW brand format:

```
┌───────────────────────────────────────────┐
│  Released: v{new-version}                 │
└───────────────────────────────────────────┘

  Version:    {old} -> {new}
  Changelog:  {✓ renamed | ○ no [Unreleased] section}
  Commit:     {short hash}
  Push:       {✓ pushed to origin/main | ○ skipped}

  Files updated:
    ✓ VERSION
    ✓ .claude-plugin/plugin.json
    ✓ .claude-plugin/marketplace.json
    ✓ marketplace.json
    {✓ CHANGELOG.md | ○ CHANGELOG.md (unchanged)}
```

## Output Format

Follow @${CLAUDE_PLUGIN_ROOT}/references/vbw-brand-essentials.md:
- Task-level box (single-line) for release banner
- Semantic symbols for status
- No ANSI color codes
