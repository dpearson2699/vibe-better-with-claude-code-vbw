# VBW Lead Agent Memory

## Project Context
- VBW is a Claude Code plugin: 6 agents, 30 commands, 18 hooks, file-based state machine
- Single external dependency: jq. Everything else is bash + markdown
- 4 version files must stay in sync: VERSION, plugin.json, marketplace.json x2
- All hooks use version-sorted cache resolution: `ls | sort -V | tail -1`

## Planning Patterns Learned

### Phase 1 Decomposition
- session-start.sh jq guard (lines 6-9) already exits 0 correctly -- the issue is message severity, not control flow
- validate-commit.sh is ALWAYS non-blocking (exit 0) -- never say "blocks" for this hook
- pre-push-hook.sh IS blocking (exit 1) -- different design from PostToolUse hooks
- Marketplace staleness is already handled by session-start.sh auto-sync (lines 96-123)
- File conflict avoidance: group by script ownership, not by concern category

### Plan Quality
- Always verify existing code before claiming bugs -- session-start.sh exit 0 was correct
- Truths must match the hook's blocking/non-blocking nature (exit 0 vs exit 1)
- `contains` field in artifacts should be a literal string that grep will find
- Context rationale should explain trade-offs and what was considered but excluded

## Codebase File Map (Phase 1 relevant)
- scripts/session-start.sh: SessionStart hook, jq check, update check, marketplace sync
- scripts/detect-stack.sh: Stack detection, no jq guard, uses jq for JSON parsing
- scripts/validate-commit.sh: PostToolUse Bash, commit format + version bump warning
- scripts/bump-version.sh: Version sync, --verify flag checks 4-file consistency
- scripts/pre-push-hook.sh: Git pre-push, blocks push without VERSION in changes
- scripts/validate-frontmatter.sh: Does not exist yet (Plan 01-03 creates it)
- hooks/hooks.json: 17 hook entries across 8 event types
- commands/init.md: /vbw:init flow, no jq guard currently
