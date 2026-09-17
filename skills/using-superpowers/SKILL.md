---
name: using-superpowers
description: Use at conversation start to route development work to the relevant skill
---

# Using Superpowers

For code changes, debugging, multi-step plans, or skill edits, load the matching
skill before starting that workflow. Read-only questions and reviews need no
process skill. Dispatched workers follow their assigned role instead of this router.

- New or changed behavior: `superpowers:brainstorming`.
- Bugs and failing tests: `superpowers:systematic-debugging`.
- An existing plan: `superpowers:subagent-driven-development` for independent
  tasks, or `superpowers:executing-plans` for coupled work or requested inline execution.
- Skill changes: `superpowers:writing-skills`.

Announce the chosen skill once. Track meaningful deliverables with native tasks;
checklist substeps do not each need a task. Stop using a skill that does not fit.

User instructions and project rules take precedence over skills. Preserve prior
authorization; do not ask the user to approve the same scope again.

If the turn starts in plan mode, use its plan file as the deliverable. Avoid a
second spec or approval gate for the same decision. Otherwise, use plan mode only
when it adds a needed planning boundary.
