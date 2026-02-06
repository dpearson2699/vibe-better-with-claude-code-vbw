<!-- VBW SUMMARY TEMPLATE (ARTF-02) -- Generated after plan execution -->
---
phase: {phase-id}
plan: {plan-number}
title: {plan-title}
status: {complete|partial|failed}
tokens_consumed: {number}
deviations:
  - "{deviation-description}"
compaction_count: {number}
duration: {time-string}
completed: {YYYY-MM-DD}
subsystem: {category}
tags:
  - {tech-keyword}
dependency_graph:
  requires: [{prior-phases}]
  provides: [{what-was-delivered}]
  affects: [{future-phases}]
tech_stack:
  added: [{new-libraries}]
  patterns: [{architectural-patterns}]
key_files:
  created: [{file-paths}]
  modified: [{file-paths}]
---

# Phase {X} Plan {Y}: {Title} Summary

<!-- One-liner: Substantive summary, not generic. -->
<!-- Good: "JWT auth with refresh rotation using jose library" -->
<!-- Bad: "Authentication implemented" -->
{one-line-substantive-summary}

## What Was Built

<!-- 3-5 bullet points describing deliverables -->
- {deliverable-1}
- {deliverable-2}

## Files Modified

| File | Action | Purpose |
|------|--------|---------|
| {file-path} | {created/modified/deleted} | {why} |

## Deviations from Plan

<!-- Document ALL deviations using deviation rules -->
<!-- Format: [Rule N - Type] Description -->
<!-- If none: "None -- plan executed exactly as written." -->
{deviations-or-none}

## Key Decisions

<!-- Decisions made during execution that affect future work -->
| Decision | Rationale | Impact |
|----------|-----------|--------|
| {decision} | {why} | {what-it-affects} |

## Next Steps

<!-- What the next plan or phase should know -->
- {next-step-1}
- {next-step-2}
