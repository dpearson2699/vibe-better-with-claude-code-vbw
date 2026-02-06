# Vibe Better with Claude Code (VBW)

## What This Is

VBW is an AI-native development framework for Claude Code, distributed as an npm package (`vibe-better-cc`). It provides a structured lifecycle — scope, plan, build, ship — through Claude Code skill files, agent definitions, and templates. It replaces GSD (Get Shit Done) with a leaner architecture designed for Opus 4.6's capabilities: context compaction, adaptive thinking, effort parameter, persistent memory, and enhanced subagents.

## Core Value

The complete development lifecycle — from project initialization through verified, shipped milestones — works end-to-end with real-world team role names, structured visual output, and fewer agent spawns through compaction-assisted merged sessions.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] 5+1 agent system (Scout, Architect, Lead, Dev, QA, Debugger) with tool permissions and compaction profiles
- [ ] Developer-friendly commands (`/vbw init`, `/vbw plan`, `/vbw build`, `/vbw ship`, etc.)
- [ ] Orchestrator as skill-file recipes — no central router, each command is a standalone `.md` file
- [ ] Effort profiles replacing model matrix (Thorough, Balanced, Fast, Turbo)
- [ ] Context strategy: compaction-assisted 200K window, 3-5 tasks per plan
- [ ] Structured visual feedback: semantic symbols, Unicode box-drawing, progress indicators
- [ ] Three-tier verification pipeline (Quick, Standard, Deep) with goal-backward methodology
- [ ] Continuous hooks (PostCommit, PostWrite, OnStop) for real-time quality feedback
- [ ] Persistent memory architecture (project scope + session scope)
- [ ] Skills integration: discover installed, suggest from skills.sh, auto-install on approval
- [ ] Concurrent milestones with isolated directories, ACTIVE pointer, `/vbw switch`
- [ ] Codebase mapping with synthesis (INDEX.md, PATTERNS.md), cross-validation, staleness tracking
- [ ] Monorepo awareness (per-package mapping, cross-package index)
- [ ] Concerns-as-constraints pipeline feeding from CONCERNS.md into Lead planning
- [ ] Convention verification in QA (check new code against CONVENTIONS.md)
- [ ] Resilience: agent failure recovery, session continuity, idempotent operations, API resilience
- [ ] Observability: token tracking, compaction events, agent lifecycle metrics
- [ ] Pattern learning in persistent memory (what works/fails across phases)
- [ ] npm distribution via `npx vbw` with `bin/install.js` installer
- [ ] PLAN.md with YAML frontmatter (effort_override, skills_used, depends_on fields)
- [ ] SUMMARY.md with tokens_consumed and deviations fields
- [ ] VERIFICATION.md with tier field (quick/standard/deep)
- [ ] Prompt engineering: declarative over procedural, no "think carefully", effort-aware, compaction-resilient
- [ ] Brownfield detection and smart codebase mapping suggestions
- [ ] Incremental codebase map refresh (git diff since last hash)
- [ ] Milestone lifecycle: archive, evolve, tag, clear milestone-scoped memory
- [ ] Deviation handling: auto-fix minor, auto-add critical, auto-resolve blocking, checkpoint architectural

### Out of Scope

- Agent teams integration — experimental, defer until GA
- npm publishing — separate decision, not part of framework architecture build
- Community docs (CONTRIBUTING.md) — post-v1.0 milestone
- IDE integrations — post-v1.0 milestone
- Web dashboard — terminal-first, no web UI
- GSD migration tooling — clean break, VBW v1.0 is a new project

## Context

VBW is a ground-up rebuild of GSD (Get Shit Done), taking GSD's proven workflow design — phase-based decomposition, goal-backward verification, atomic commits, requirements traceability — and implementing it fresh for Opus 4.6. The masterplan document (`a_non_prod_files/masterplan.md`) is the authoritative scope document (v3.0, 2026-02-06).

Key architectural decisions from the masterplan:
- **Agent consolidation:** 9 GSD agent types reduced to 6 (Scout, Architect, Lead, Dev, QA, Debugger). Lead merges researcher + planner + plan-checker into one compaction-extended session.
- **Commands mirror developer vernacular:** `/vbw plan`, `/vbw build`, `/vbw ship` instead of internal jargon.
- **Orchestrator is recipe-based:** Each command is a skill `.md` file. No central router. Adding a command = adding a file.
- **Effort replaces model matrix:** Four profiles (Thorough/Balanced/Fast/Turbo) control cost/quality via effort parameter, not model selection.
- **Context strategy:** 200K window + compaction = moderately larger plans (3-5 tasks up from 2-3), merged research+planning sessions, ~50-80% longer agent lifetimes.
- **File structure:** `commands/vbw/`, `agents/`, `references/`, `templates/`, `config/`, `bin/`

The build will use GSD for bootstrapping (Phases 1-2), then VBW eats its own dog food from Phase 3 onward.

All Opus 4.6 features (compaction API, effort parameter, persistent memory, enhanced subagents, 128K output) are available today.

## Constraints

- **Platform**: Claude Code CLI only — all visual output must render in Claude Code's React+Ink terminal
- **Context Window**: 200K tokens in Claude Code (not the 1M API window) — compaction extends but does not remove this constraint
- **Distribution**: npm package (`vibe-better-cc`) installed via `npx vbw`
- **License**: MIT
- **Visual rendering**: No ANSI colors in model output, no Nerd Font glyphs. Unicode box-drawing + semantic symbols only.
- **No runtime code**: VBW is `.md` skill files, agent definitions, templates, and a thin JS installer — not a runtime framework
- **Masterplan adherence**: Follow masterplan closely, flag deviations for user approval before committing
- **GitHub practices**: Proper .gitignore, LICENSE, README, branch strategy from day 1

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Full masterplan as v1.0 scope (all 9 phases) | User wants the complete vision, not a reduced MVP | — Pending |
| Mirror masterplan's 9-phase structure for roadmap | Masterplan already has a well-thought-out build order | — Pending |
| npm distribution via npx vbw | Standard package manager distribution, copies files into Claude Code directories | — Pending |
| MIT license | Open source, permissive, aligned with ecosystem | — Pending |
| Follow masterplan closely, flag deviations | Masterplan is authoritative, not just guidance | — Pending |
| GitHub-ready from day 1 | .gitignore, LICENSE, README, branch strategy established at project init | — Pending |
| GSD bootstrap for Phases 1-2, self-hosting from Phase 3 | Build the tool with the predecessor, then switch to the tool itself | — Pending |

---
*Last updated: 2026-02-06 after initialization*
