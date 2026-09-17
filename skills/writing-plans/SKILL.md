---
name: writing-plans
description: Use when requirements need a multi-step implementation plan before execution
---

# Writing Plans

Write task contracts that a capable developer can execute without the surrounding
conversation. Make dependencies, constraints, and acceptance criteria explicit.
Use `superpowers:writing-clearly-and-concisely` for the prose.

Inspect the code before naming files and interfaces. Follow existing structure.
Split tasks at independently testable outcomes; include setup and documentation
with the deliverable they support. Batch mechanical edits of the same kind.

Save to `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`, unless another
location is requested. Use this structure; the task headings feed `task-brief`:

```markdown
# [Feature] Implementation Plan

**Goal:** [intended outcome]
**Architecture:** [approach and key decisions]
**Spec:** [source requirements, path or self-contained description]

## Global Constraints

[Binding requirements with exact values, compatibility limits, and scope boundaries.]

### Task 1: [independently testable outcome]

**Goal:** [observable behavior]
**Files:** [verified paths to create, modify, and test]
**Dependencies:** [earlier task numbers, or none]
**Interfaces:** [exact shared signatures, formats, and values that other tasks need]

- [ ] Implement [behavior and important edge cases].
- [ ] Verify [acceptance cases, relevant commands, and expected outcomes].
- [ ] Review the diff and commit the completed task when the workflow calls for commits.
```

Specify exact contracts where tasks meet. Include code for a fragile algorithm,
required literal, migration sequence, or unfamiliar API when it prevents ambiguity.
Routine implementation belongs to the implementer; complete code blocks and
minute-by-minute steps are not required. A test plan needs concrete behavior and
expected results, not necessarily test source code.

Do not leave unresolved product decisions disguised as implementation steps.
Record assumptions that remain within authorization. Ask about decisions that
change user outcomes or expand scope; continue independent planning meanwhile.

Before handoff, check requirement coverage, interface consistency, dependency order,
and whether each acceptance check can distinguish correct from incorrect behavior.
Use `superpowers:cross-reviewing-with-cursor` when requested or when substantial
risk or uncertainty warrants it. Confirm findings against the requirements.

## Execution handoff

Honor an execution route the user already chose. If execution is authorized but
no route was chosen, use `superpowers:subagent-driven-development` for substantial
independent tasks and `superpowers:executing-plans` for coupled or small work.
Explain the choice briefly. Ask only when the choice changes scope, cost, or the
user's intended involvement materially. A plan-only request ends with the plan.
