---
name: dispatching-parallel-agents
description: Use when facing 2+ independent tasks that can be worked without shared state or sequential dependencies
---

# Dispatching Parallel Agents

## Overview

Independent problems investigated one after another waste wall-clock time. Give
each its own agent, with context you construct rather than context it inherits.

**Core principle:** one agent per independent problem domain, dispatched together.

## When to Fan Out

**Yes:**
- Several test files failing with different root causes
- Multiple subsystems broken independently
- Each problem understandable without the others
- No shared state between the investigations

**No:**
- Failures are related — fixing one may fix the rest, so investigate together
- Understanding requires seeing the whole system at once
- You don't know what's broken yet (explore first, then fan out)
- The agents would collide (same files, same ports, same fixtures)

## Pick the Vehicle

| Need | Vehicle |
|------|---------|
| Independent work, each agent decides its own steps | Multiple `Agent` calls in one message |
| Broad read-only search across many files or naming conventions | `Explore` agents — they return conclusions, not file dumps |
| Parallel edits that would conflict on disk | `Agent` with `isolation: "worktree"` |
| Deterministic fan-out: per-item pipelines, barriers, verify-each-finding, loop-until-dry | The `Workflow` tool |

`Workflow` needs the user's explicit opt-in. When the shape genuinely calls for
it, say what it would do and roughly what it costs, and let them choose.

## Constructing the Dispatches

Each agent gets:

- **One scope** — a single test file, subsystem, or question
- **Self-contained context** — the error messages, test names, and file paths it
  needs; it cannot see your conversation
- **Explicit constraints** — what it must not touch ("fix the tests, not the
  production code")
- **A named return** — what you want back, and in what form

```markdown
Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:

1. "should abort tool with partial output capture" — expects 'interrupted at' in message
2. "should handle mixed completed and aborted tools" — fast tool aborted instead of completed
3. "should properly track pendingToolCount" — expects 3 results but gets 0

These look like timing or race issues.

1. Read the test file and understand what each test verifies
2. Identify the root cause — timing, or an actual bug?
3. Fix it: replace arbitrary timeouts with event-based waiting, fix bugs in the
   abort implementation, or correct test expectations if the behavior changed

Do NOT just increase timeouts — find the real issue.

Return: the root cause and what you changed.
```

**Failure modes:** "fix all the tests" (agent gets lost); "fix the race
condition" with no location; no constraints (agent refactors everything); no
named return (you can't tell what changed).

## After They Return

1. **Read each result** — what changed, and why.
2. **Check for conflicts** — did two agents touch the same code?
3. **Run the full suite** — the fixes have to work together, not just separately.
4. **Spot-check the diffs** — agents make systematic errors, and a success report
   is a claim, not evidence (superpowers:verification-before-completion).
