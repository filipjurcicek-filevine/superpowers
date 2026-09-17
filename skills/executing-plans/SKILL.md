---
name: executing-plans
description: Use when executing a plan inline because tasks are coupled or inline work was requested
---

# Executing Plans Inline

Read the plan and its source requirements. Check dependencies, interfaces, and
acceptance criteria. Resolve routine gaps from the code; ask about consequential
ambiguity or scope changes before dependent work. Continue independent tasks.

Use `superpowers:using-git-worktrees` to check isolation and follow the user's
workspace preference. Never implement on main/master without explicit consent.
Track one native task per deliverable, with dependencies where needed.

For each task:

1. Mark it in progress and implement its agreed outcome.
2. Use `superpowers:test-driven-development` for new behavior and bug fixes.
3. Run the task's checks at the point they provide useful evidence.
4. Inspect the diff and mark complete only when its acceptance criteria hold.

Follow meaningful constraints, not stale implementation details contradicted by
new evidence. Record material deviations and their reasons. Stop dependent work
when requirements cannot be resolved within scope or a verification failure leaves
correctness unknown. Report the evidence and the missing decision.

After the tasks, use `superpowers:requesting-code-review` for a substantial change.
Use `superpowers:verification-before-completion`, then
`superpowers:finishing-a-development-branch`. Reuse valid verification evidence.
