---
name: using-superpowers
description: Use when starting any conversation - establishes which skill to invoke before acting
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

## The Rule

If this turn will write or change code, debug a failure, plan multi-step work, or create or edit a skill, invoke the matching skill **before acting** — before exploring the codebase, and before asking clarifying questions.

Read-only turns do not need one: answering a question, explaining existing code, reviewing something already written, or reporting on state.

Announce "Using [skill] to [purpose]", then follow it. If it has a checklist, `TaskCreate` one task per item. If the skill turns out to be wrong for the situation, say so and stop using it.

## Skill Priority

Process skills set the approach; implementation skills carry it out.

- "Let's build X" → superpowers:brainstorming, then implementation skills
- "Fix this bug" → superpowers:systematic-debugging, then domain skills
- "Execute this plan" → superpowers:subagent-driven-development

## Plan Mode

Brainstorming approves the design; writing-plans approves the plan and its execution route — the flow gates itself.

- Work is going through that flow → do not call `EnterPlanMode`; it gates the same decision twice.
- The turn *started* in plan mode → the harness's plan file is this turn's deliverable. Do not open a second artifact beside it: either it stands as the spec and writing-plans takes over after `ExitPlanMode`, or say that the Superpowers artifacts supersede it and where they will live.
- Neither → plan mode is the right tool for the work.

## Red Flags

| Thought | Reality |
|---------|---------|
| "Let me explore the codebase first" | Skills tell you how to explore. Invoke first. |
| "I remember this skill" | Skills change. Read the current version. |

## User Instructions

CLAUDE.md, AGENTS.md, and direct requests outrank skills; skills outrank default behavior. Skip a skill's workflow only when the user tells you to.
