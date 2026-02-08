# VBW Structured Handoff Schemas

Single source of truth for structured agent-to-agent SendMessage communication. Referenced by agent definitions and orchestrating skills.

## Overview

When agents communicate findings via SendMessage, they use JSON-structured messages with a `type` discriminator. This enables reliable parsing by receiving agents and consistent cross-agent communication.

**Backward compatibility:** Receiving agents should `JSON.parse` the message content first. If parsing fails, fall back to treating the content as plain markdown. This ensures older agent versions and manual messages still work.

## Schema Types

### `scout_findings`

**Sender:** Scout | **Receiver:** Map Lead

Structured research findings from a Scout teammate investigating a specific domain.

```json
{
  "type": "scout_findings",
  "domain": "tech-stack | architecture | quality | concerns",
  "documents": [
    {
      "name": "STACK.md",
      "content": "## Tech Stack\n..."
    }
  ],
  "cross_cutting": [
    {
      "target_domain": "architecture",
      "finding": "Monorepo workspace config affects architecture mapping",
      "relevance": "high | medium | low"
    }
  ],
  "confidence": "high | medium | low",
  "confidence_rationale": "Brief justification for confidence level"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | yes | Always `"scout_findings"` |
| `domain` | yes | The Scout's assigned investigation domain |
| `documents` | yes | Array of document objects with `name` and `content` |
| `cross_cutting` | no | Findings relevant to other Scouts' domains |
| `confidence` | yes | Overall confidence in findings |
| `confidence_rationale` | yes | Brief justification |

### `dev_progress`

**Sender:** Dev | **Receiver:** Execute Lead

Status update after a Dev teammate completes a task.

```json
{
  "type": "dev_progress",
  "task": "03-01/task-3",
  "plan_id": "03-01",
  "commit": "abc1234",
  "status": "complete | partial | failed",
  "concerns": [
    "Interface changed from plan — downstream plans may need update"
  ]
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | yes | Always `"dev_progress"` |
| `task` | yes | Task identifier (plan-id/task-name) |
| `plan_id` | yes | Plan this task belongs to |
| `commit` | yes | Git commit hash (short form) |
| `status` | yes | Task completion status |
| `concerns` | no | Array of concerns affecting other plans or the phase |

### `dev_blocker`

**Sender:** Dev | **Receiver:** Execute Lead

Escalation when a Dev teammate is blocked and cannot proceed.

```json
{
  "type": "dev_blocker",
  "task": "03-02/task-1",
  "plan_id": "03-02",
  "blocker": "Dependency module from plan 03-01 not yet committed",
  "needs": "03-01 to complete first",
  "attempted": [
    "Checked git log for 03-01 commits — none found"
  ]
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | yes | Always `"dev_blocker"` |
| `task` | yes | Task identifier where the block occurred |
| `plan_id` | yes | Plan this task belongs to |
| `blocker` | yes | Description of what is blocking progress |
| `needs` | yes | What is needed to unblock |
| `attempted` | no | Array of steps already tried to resolve |

### `qa_result`

**Sender:** QA | **Receiver:** Lead (Execute or QA skill)

Structured verification results from a QA agent.

```json
{
  "type": "qa_result",
  "tier": "quick | standard | deep",
  "result": "PASS | FAIL | PARTIAL",
  "checks": {
    "passed": 18,
    "failed": 2,
    "total": 20
  },
  "failures": [
    {
      "check": "CONVENTIONS.md link integrity",
      "expected": "All cross-references resolve",
      "actual": "references/missing-file.md not found",
      "evidence": "grep output showing broken link at line 42"
    }
  ],
  "body": "## Must-Have Checks\n| # | Truth | Status | Evidence |\n..."
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | yes | Always `"qa_result"` |
| `tier` | yes | Verification depth tier |
| `result` | yes | Overall verification result |
| `checks` | yes | Object with `passed`, `failed`, `total` counts |
| `failures` | no | Array of failure detail objects (empty if PASS) |
| `body` | yes | Full markdown verification report |

### `debugger_report`

**Sender:** Debugger | **Receiver:** Debug Lead

Investigation findings from a Debugger teammate in competing hypotheses mode.

```json
{
  "type": "debugger_report",
  "hypothesis": "Race condition in session middleware causes intermittent 401s",
  "evidence_for": [
    "Mutex not held during token refresh (src/middleware/auth.ts:45)",
    "Reproduction shows 401s only under concurrent requests"
  ],
  "evidence_against": [
    "Token TTL is 30min — unlikely to expire mid-request in normal flow"
  ],
  "confidence": "high | medium | low",
  "recommended_fix": "Add mutex lock around token refresh in auth middleware, or 'Insufficient evidence' if confidence is low"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | yes | Always `"debugger_report"` |
| `hypothesis` | yes | The hypothesis that was investigated |
| `evidence_for` | yes | Specific findings supporting the hypothesis |
| `evidence_against` | yes | Specific findings contradicting the hypothesis |
| `confidence` | yes | Confidence level in this hypothesis |
| `recommended_fix` | yes | Minimal fix description if high confidence, or "Insufficient evidence" |
