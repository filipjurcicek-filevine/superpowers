---
name: writing-skills
description: Use when creating, changing, or evaluating a reusable skill
---

# Writing Skills

A skill supplies context, operational constraints, and decision rules that a capable
model needs for a recurring task. It should preserve user intent and leave routine
implementation choices to the model.

This fork targets Opus/Fable, Sol, and Astra-class models with shared guidance.
Keep Claude Code tool names in this package. Do not infer model-specific behavior
from a single run or add model routing to compensate for an unmeasured problem.

## Design the contract

Define the trigger, intended outcome, necessary inputs, important constraints,
verification, and stopping conditions. Include only instructions that change a
useful decision or prevent an observed failure.

Use positive output contracts for shape and completeness. Use conditionals for
behavior that depends on an observable state. Reserve absolute prohibitions for
real boundaries. A safety rule and its explanation belong together, once.

Match detail to risk. Fragile commands and recovery procedures need precision;
ordinary development advice rarely needs a tutorial. Preserve explicit user
choices and existing authorization. Ask only when missing information changes
scope, outcomes, or required permission.

## Structure and discovery

Each directory contains `SKILL.md` with YAML `name` and `description`. Use lowercase
letters, digits, and hyphens for names. Describe the trigger precisely in one short
sentence. Do not put a compressed execution checklist in the description.

Keep the essential contract in the entrypoint. Move substantial conditional
reference material and runnable mechanics into linked files. State when each is
needed. A short skill does not need a router or extra directories.

Plugin skills live in `skills/`; personal and project Claude Code skills live in
`~/.claude/skills/` and `.claude/skills/`. Use
`superpowers:writing-clearly-and-concisely` for human-facing prose.

## Validate behavior

Treat edits as behavior changes. Before rewriting, preserve the current prompt and
freeze realistic cases and success criteria. Include counterexamples where the
skill should not trigger or where a shorter path is correct.

Compare no-guidance, current, and proposed guidance in fresh contexts. For wording
probes, use at least five repetitions per variant and inspect every scored failure.
If the control already behaves correctly, do not add guidance for that imagined
failure. Existing operational contracts still need maintenance even when the model
knows the underlying technique.

Keep model, effort, harness, task, and permissions constant within each comparison.
Test target models separately; do not pool their results into a model-wide claim.
Evaluate outcomes, scope preservation, unnecessary questions, repeated checks,
review loops, elapsed time, and tokens. Smaller prompts are not automatically better.

Decision probes test stated choices. For TDD, completion claims, and skill routing,
also run implementation-level pressure scenarios with observable tool actions.
See [testing-skills-with-subagents.md](testing-skills-with-subagents.md) for scenario
construction and [../../docs/testing.md](../../docs/testing.md) for the harness.
Keep live artifacts outside the plugin tree. Respect sandbox and authorization
boundaries. If a target or harness cannot run, record the gap and label the change
unvalidated for that target; static checks cannot replace behavioral evidence.

For broad revisions, isolate contract changes so failures can be attributed.
Retest interactions after individual contracts work. Fix demonstrated regressions
without accumulating generic warnings or repeated rationalization tables.

## Check and release

- Validate metadata, local links, script callers, and required output fields.
- Run checks for changed executable mechanics; avoid tests that match prompt wording.
- Review whether callers and worker roles agree on authorization, evidence, and scope.
- Measure both entrypoint size and actual workflow cost. Descriptions load early;
  bodies cost context after invocation. There is no universal 25x multiplier.
- Record before/after results and limitations with the change.
- Bump both plugin version fields for a release candidate. Publish or update an
  installed plugin only when that action is authorized.

Use [anthropic-best-practices.md](anthropic-best-practices.md) for detailed authoring
reference. For a non-obvious branching diagram, see `graphviz-conventions.dot` and
use `render-graphs.js` to render it. Examples should resolve a real ambiguity;
one precise example is usually enough.
