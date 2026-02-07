---
description: Display all available VBW commands with descriptions and usage examples.
argument-hint: [command-name]
allowed-tools: Read, Glob
---

# VBW Help $ARGUMENTS

## Behavior

### No arguments: Display complete command reference

Show all VBW commands grouped by lifecycle stage. Mark all commands with ✓.

### With argument: Display detailed command help

Read `${CLAUDE_PLUGIN_ROOT}/commands/{name}.md` and display: name, description, usage, arguments, related commands.

## Command Reference

### Lifecycle (init -> plan -> build -> ship)

| Status | Command        | Description                                          |
|--------|----------------|------------------------------------------------------|
| ✓      | /vbw:init      | Initialize project with .vbw-planning directory      |
| ✓      | /vbw:plan      | Plan a phase via Lead agent subagent                 |
| ✓      | /vbw:build     | Execute phase via Agent Teams with Dev teammates     |
| ✓      | /vbw:ship      | Archive milestone, tag repo, merge branch            |

### Monitoring

| Status | Command        | Description                                          |
|--------|----------------|------------------------------------------------------|
| ✓      | /vbw:status    | Progress dashboard with Agent Teams task view        |
| ✓      | /vbw:qa        | Deep verification (continuous QA handled by hooks)   |

### Quick Actions

| Status | Command        | Description                                          |
|--------|----------------|------------------------------------------------------|
| ✓      | /vbw:fix       | Quick fix with commit discipline (turbo mode)        |
| ✓      | /vbw:debug     | Systematic bug investigation via Debugger agent      |
| ✓      | /vbw:todo      | Add item to persistent backlog                       |

### Session Management

| Status | Command        | Description                                          |
|--------|----------------|------------------------------------------------------|
| ✓      | /vbw:pause     | Save session context (Agent Teams not resumable)     |
| ✓      | /vbw:resume    | Restore context, create NEW team from saved state    |

### Codebase & Research

| Status | Command        | Description                                          |
|--------|----------------|------------------------------------------------------|
| ✓      | /vbw:map       | Analyze codebase with parallel Scout teammates       |
| ✓      | /vbw:discuss   | Gather context before planning                       |
| ✓      | /vbw:assumptions | Surface Claude's assumptions                       |
| ✓      | /vbw:research  | Standalone research task                             |

### Milestones & Phases

| Status | Command           | Description                                       |
|--------|-------------------|---------------------------------------------------|
| ✓      | /vbw:milestone    | Start new milestone with isolated state            |
| ✓      | /vbw:switch       | Switch active milestone (checks uncommitted work)  |
| ✓      | /vbw:audit        | Audit milestone for shipping readiness             |
| ✓      | /vbw:add-phase    | Add phase to end of roadmap                        |
| ✓      | /vbw:insert-phase | Insert urgent phase with renumbering               |
| ✓      | /vbw:remove-phase | Remove future phase with renumbering               |

### Configuration & Meta

| Status | Command        | Description                                          |
|--------|----------------|------------------------------------------------------|
| ✓      | /vbw:config    | View/modify settings and skill-hook wiring           |
| ✓      | /vbw:help      | This help guide                                      |
| ✓      | /vbw:whats-new | View changelog and recent updates                    |
| ✓      | /vbw:update    | Update VBW to latest version                         |

## Architecture Notes

**Agent Teams:** /vbw:build creates a team with Dev teammates for parallel plan execution. /vbw:map creates a team with Scout teammates for parallel codebase analysis. The session IS the team lead.

**Hooks:** Continuous verification runs automatically via PostToolUse, TaskCompleted, and TeammateIdle hooks. /vbw:qa is for deep, on-demand verification only.

**Git Branches:** /vbw:milestone --branch creates `milestone/{slug}` branches. /vbw:ship merges back. /vbw:switch checks for uncommitted changes.

**Skill-Hook Wiring:** Use /vbw:config to map skills to hook events (e.g., lint-fix on file writes).

## Getting Started

➜ Quick Start
  /vbw:init "My project" -- Set up your project
  /vbw:map -- Analyze codebase (brownfield) or skip (greenfield)
  /vbw:plan 1 -- Plan your first phase
  /vbw:build 1 -- Execute with Agent Teams
  /vbw:qa 1 -- Deep verify (hooks already ran continuous checks)
  /vbw:ship -- Archive and tag

Run `/vbw:help <command>` for detailed help on any command.

## Output Format

Follow @${CLAUDE_PLUGIN_ROOT}/references/vbw-brand.md:
- Double-line box for help header
- ✓ for available commands
- ➜ for Getting Started steps
- No ANSI color codes
