---
name: vibe
description: "The one command. Detects state, parses intent, routes to any lifecycle mode -- bootstrap, scope, plan, execute, discuss, archive, and more."
argument-hint: "[intent or flags] [--plan] [--execute] [--discuss] [--assumptions] [--scope] [--add] [--insert] [--remove] [--archive] [--yolo] [--effort=level] [--skip-qa] [--skip-audit] [--plan=NN] [N]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch
disable-model-invocation: true
---

# VBW Vibe: $ARGUMENTS

## Context

Working directory: `!`pwd``

Pre-computed state (via phase-detect.sh):
```
!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/phase-detect.sh 2>/dev/null || echo "phase_detect_error=true"`
```

Config:
```
!`cat .vbw-planning/config.json 2>/dev/null || echo "No config found"`
```
