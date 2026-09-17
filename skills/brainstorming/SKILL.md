---
name: brainstorming
description: Use when new behavior needs design decisions before implementation
---

# From Request to Design

Establish the intended behavior, constraints, and acceptance criteria. Scale the
process to the decisions the task needs, using the existing code and conversation.

## Choose the smallest sufficient path

| Request | Path |
|---|---|
| Feasibility question or disposable experiment | Investigate a bounded probe and report evidence; label disposable code |
| Clear change to existing behavior | Inspect relevant code, state the approach briefly, then implement within authorization |
| New subsystem or material interface or architecture change | Compare viable approaches, resolve consequential choices, and write a spec |

Reassess when new evidence changes scope. Complexity can increase or decrease.
An existing approved design or explicit instruction to plan and execute supplies
authorization for that scope; do not require another yes for the same work.

Ask before choosing between materially different user outcomes, expanding scope,
or taking an action that requires new authorization. Resolve routine implementation
details from project conventions. While an answer is pending, continue independent work.

## Gather and resolve context

Read the relevant implementation, project guidance, and prior decisions. Treat
IDE selection as a pointer; verify it against the working copy before editing.
Ask only questions whose answers change the result and cannot be inferred.

Use `AskUserQuestion` for choices. Group related questions and lead with a
recommended option and its trade-off. Use prose for open-ended questions.
For a visual choice, show a preview or an `Artifact` instead of describing layout
at length. Conceptual questions do not require a visual artifact.

For architectural work, present viable alternatives when there is a real trade-off.
State the recommended approach, boundaries, interfaces, data flow, error handling,
and verification. Follow existing patterns and exclude unrelated improvements.
Get a decision on unresolved consequential choices before dependent implementation.
Do not require separate approval for every section of an already approved design.

## Record and hand off

Bounded work needs no separate spec or plan unless requested. Proceed through the
relevant implementation and verification skills.

For architectural work, save the spec to
`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, unless the user chose another
location. Use `superpowers:writing-clearly-and-concisely` for its prose.
Include scope, decisions, constraints, and observable acceptance criteria.
Check for contradictions, missing requirements, and unresolved placeholders.

Use `superpowers:cross-reviewing-with-cursor` when requested or when consequential
uncertainty warrants another review. Confirm findings before changing the spec.
Present the spec and any unresolved choices. Wait only for decisions not already
authorized, then use `superpowers:writing-plans` if a multi-step plan is needed.
