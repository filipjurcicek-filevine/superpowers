---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing — before committing, pushing, or creating a PR
---

# Verification Before Completion

## Overview

**Core principle:** evidence before claims, always. A claim you have not run the
command for in this message is a guess wearing a result's clothing.

## The Gate

Before stating any status:

1. **Identify** the command that proves the claim.
2. **Run** it fresh and complete — not a subset, not a previous run.
3. **Read** the full output: exit code, failure count, warnings.
4. **State** the claim with that evidence, or state the actual status with it.

## What Each Claim Requires

| Claim | Requires | Not sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | A previous run, "should pass" |
| Linter clean | Linter output: 0 errors | A partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs looking fine |
| Bug fixed | The original symptom retested: passes | Code changed, fix assumed |
| Regression test works | Red-green verified by reverting the fix | The test passing once |
| Subagent completed | The VCS diff shows the changes | The agent's success report |
| Requirements met | Line-by-line checklist against the spec | Tests passing |

## Two Protocols Worth Spelling Out

**Regression tests.** A test that passes against fixed code has not been shown to
catch anything:

```
Write test → run (passes) → revert the fix → run (MUST FAIL) → restore fix → run (passes)
```

Without the revert step, you have a test that agrees with the current code.

**Subagent reports.** A subagent reporting success is a claim about the
repository, not an observation of it. Check `git status` / `git diff` for the
changes before you repeat the claim upward. Subagents report success for work
they abandoned, work they only described, and work they wrote to the wrong path.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Should work now" | Run the verification. |
| "Linter passed" | The linter doesn't compile or run anything. |
| "Partial check is enough" | A subset proves the subset. |
| "The agent said it succeeded" | Check the diff. |
