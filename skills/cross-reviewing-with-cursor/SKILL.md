---
name: cross-reviewing-with-cursor
description: Use when an outside review is requested or consequential uncertainty warrants a second model
---

# Cross-Reviewing With Cursor

Use an outside review for a spec, plan, or completed branch when requested or when
its likely value justifies the extra work. Routine task review does not need a
second reviewer automatically. An installed CLI alone is not a reason to run it.

Read [cli-reference.md](cli-reference.md) for availability, model resolution,
read-only invocation, output capture, and tree fingerprint checks. Cursor is the
only review CLI. Run it only when the CLI, active paid access, and remaining
plan allowance are established. Free accounts, unavailable access, exhausted
allowance, or unknown eligibility mean skip. Do not use a billable probe to check.
Report the reason once and continue without claiming a review occurred. Never install
a tool just to satisfy this skill.

## Review inputs

Give the reviewer the artifact, its source requirements, and the repository context
needed to judge it. Pass large diffs as files. Use a stable revision or artifact
snapshot so the review remains attributable to the version reviewed.

| Artifact | Questions |
|---|---|
| Spec | Are requirements ambiguous, contradictory, infeasible, or missing a consequential decision? |
| Plan | Does every requirement have a task? Do interfaces and dependencies agree? Are acceptance checks meaningful? |
| Branch | Does the code meet requirements without regressions, unsafe behavior, or broken contracts? |

Request actionable findings with location, impact, and evidence. Exclude unrequested
features and style preferences. A plan need not contain full implementation code
to be executable. Review uncertainty should identify the missing evidence.

## Verify and route findings

Use `superpowers:receiving-code-review` to classify each finding as confirmed,
refuted, out of scope, or unresolved. Agreement between models is not proof.
Rejudge severity against actual impact and project requirements.

Record each outcome and its evidence in the SDD ledger or review report. Confirmed
findings that conflict with approved outcomes need the appropriate user decision;
an outside opinion does not expand authorization.

For a branch review, independent reviewers can work concurrently against the same
stable range. Deduplicate their findings before dispatching fixes. Use the SDD
fix loop when in that workflow; do not start a separate loop for each reviewer.

## Report

Report the model actually used, reviewed scope/revision, exit status, result, tree
check, and counts of confirmed/refuted/out-of-scope/unresolved findings. Include
artifact and log paths plus material findings. Empty output and startup errors
mean review incomplete, never no findings. If the tree changed, inspect and report
the difference without reverting work automatically.
