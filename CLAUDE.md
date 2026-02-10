# VBW — Vibe Better with Claude Code

A Claude Code plugin that adds structured development workflows — planning, execution, and verification — using specialized agent teams.

**Core value:** Replace ad-hoc AI coding with repeatable, phased workflows.

## Active Context

**Work:** No active work — all milestones complete
**Last completed:** GSD Isolation (archived 2026-02-10, tag: milestone/gsd-isolation)
**Next action:** /vbw:implement to start new work

## VBW Rules

- **Always use VBW commands** for project work. Do not manually edit files in `.vbw-planning/`.
- **Commit format:** `{type}({scope}): {description}` — types: feat, fix, test, refactor, perf, docs, style, chore.
- **One commit per task.** Each task in a plan gets exactly one atomic commit.
- **Never commit secrets.** Do not stage .env, .pem, .key, credentials, or token files.
- **Plan before building.** Use /vbw:plan before /vbw:execute. Plans are the source of truth.
- **Do not fabricate content.** Only use what the user explicitly states in project-defining flows.
- **Do not bump version or push until asked.** Never run `scripts/bump-version.sh` or `git push` unless the user explicitly requests it. Commit locally and wait.

## Key Decisions

| Decision | Date | Rationale |
|----------|------|-----------|
| 3-phase roadmap: failures → polish → docs | 2026-02-09 | Risk-ordered, concerns-first |
| `/vbw:implement` as single primary command | 2026-02-09 | Users confused by command overlap |
| Milestones become internal concept | 2026-02-09 | Solo devs don't need the abstraction |
| `/vbw:ship` → `/vbw:archive` | 2026-02-09 | Clearer verb for wrapping up work |
| Remove `/vbw:new`, `/vbw:milestone`, `/vbw:switch` | 2026-02-09 | Absorbed into implement/plan |
| Performance optimization: 3 phases | 2026-02-09 | Context diet → script offloading → agent cost controls |
| Three-layer GSD isolation | 2026-02-10 | CLAUDE.md + project CLAUDE.md + PreToolUse hard block |
| Two marker files (.active-agent + .vbw-session) | 2026-02-10 | Avoids conflict with cost attribution; separate concerns |
| GSD detection before consent prompt | 2026-02-10 | No noise for non-GSD users |

## Installed Skills

13 global skills installed (run /vbw:skills to list).

## Learned Patterns

- `disable-model-invocation: true` is the highest-impact token optimization for plugins
- Scout→haiku, QA→sonnet gives 40-60% cost reduction without quality loss
- Two-marker isolation: `.active-agent` for subagents, `.vbw-session` for commands — avoids false-positive blocking after subagent stop

## Compact Instructions

When compacting context, follow these priorities:

**Always preserve:**
- Active plan file content (current task number, remaining tasks, file paths)
- Commit hashes and messages from this session's work
- Deviation decisions and their rationale
- Current phase number, name, and status
- File paths that were modified (exact paths, not summaries)
- Any error messages or test failures being debugged

**Safe to discard:**
- Tool output details already processed (file contents, grep results, git diffs)
- Planning exploration that led to the current plan (keep only the final plan)
- Reference file contents and phase summaries already written to disk

**After compaction:** Re-read your assigned plan file and STATE.md from disk to restore working context.

## State

- Planning directory: `.vbw-planning/`
- Codebase map: `.vbw-planning/codebase/`

## Project Conventions

These conventions are enforced during planning and verified during QA.

- Commands are kebab-case .md files in commands/ [file-structure]
- Agents named vbw-{role}.md in agents/ [naming]
- Scripts are kebab-case .sh files in scripts/ [naming]
- Phase directories follow {NN}-{slug}/ pattern [naming]
- Plan files named {NN}-{MM}-PLAN.md, summaries {NN}-{MM}-SUMMARY.md [naming]
- Commits follow {type}({scope}): {desc} format, one commit per task [style]
- Stage files individually with git add, never git add . or git add -A [style]
- Shell scripts use set -u minimum, set -euo pipefail for critical scripts [style]
- Use jq for all JSON parsing, never grep/sed on JSON [tooling]
- YAML frontmatter description must be single-line (multi-line breaks discovery) [style]
- No prettier-ignore comment before YAML frontmatter, use .prettierignore instead [style]
- All hooks route through hook-wrapper.sh for graceful degradation (DXP-01) [patterns]
- Zero-dependency design: no package.json, npm, or build step [patterns]
- All scripts target bash, not POSIX sh [tooling]
- Plugin cache resolution via ls | sort -V | tail -1, never glob expansion [patterns]

## Commands

Run /vbw:status for current progress.
Run /vbw:help for all available commands.
