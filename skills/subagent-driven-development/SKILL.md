---
name: subagent-driven-development
description: Use when executing a plan with substantial independent tasks in the current session
---

# Subagent-Driven Development

Coordinate task implementers and independent reviewers. Keep requirements, shared
interfaces, and recovery state in the controller; hand workers scoped task briefs.
For tightly coupled or small work, use `superpowers:executing-plans` instead.

Continue authorized work without repeated permission questions. Resolve routine
implementation gaps against the requirements and existing code. Ask before changing
approved outcomes, expanding scope, or taking an action that needs new permission.
If a missing decision blocks one task, continue independent work.

## Setup and recovery

Use `superpowers:using-git-worktrees` to verify isolation or honor the user's
workspace choice. Never implement on main/master without explicit consent.
Read the plan, its source spec, and Global Constraints. Check task interfaces,
dependencies, and acceptance criteria; record conflicts and their resolutions.
A separate table of every clean task pair is unnecessary.

Run `scripts/sdd-workspace PLAN_FILE` from this skill's directory. It prints the
plan's git-ignored workspace at `<repo-root>/.superpowers/sdd/<plan-basename>/`.
Use it for `progress.md`, briefs, reports, and review packages. Do not touch a
workspace belonging to another plan.

The ledger starts with `# SDD ledger — plan: <plan file path>`. On resume, verify
its plan identity and recorded commits against git before continuing. Resume the
last unfinished task or fix round; do not redispatch completed work. If the plan
changed, identify affected tasks rather than trusting old completion lines blindly.

Keep entries short: task, state, commit range, evidence/report path, and outstanding
findings. Record material decisions as `Ruling: <decision> — <reason> — <cost if wrong>`.
Append entries with `cat >> progress.md`; avoid resending the growing file through
an Edit call. Git-ignored artifacts are vulnerable to `git clean -fdx`; preserve
needed evidence before cleanup. Git history alone does not contain these reports.

Use `TaskCreate` for deliverables, with `blockedBy` for real dependencies.
When a normal task completes, shrink its description to its goal and ledger path.

For an explicitly ordered user verification, create a separate gate task with a
`json:metadata` fence containing `"userGate": true` and the exact `"verifyCommand"`.
Run that command after creating the gate, inspect its output, and preserve the
full description on completion. Do not replace it with an easier check.

## Roles and handoffs

| Role | Agent type | Effort |
|---|---|---|
| Implementation and fixes | `superpowers:sdd-implementer` | low |
| Task review | `superpowers:sdd-task-reviewer` | medium |
| Scoped fix review | `superpowers:sdd-re-reviewer` | medium |
| Whole-branch review | `superpowers:code-reviewer` | medium |

Use these defined types for SDD workspace artifacts; the effort-pin hook checks
this dispatch contract. Roles inherit the selected model. Effort values are
existing Claude Code defaults, not measured optima for every model. Do not add
model-tier routing or unsupported per-call Agent effort fields.

Role definitions carry the instructions. Dispatch only task context, constraints,
artifact paths, and expected report locations. Reviewers retain Bash for inspection;
their no-mutation contract is not a filesystem sandbox. Use available permission
controls when a hard read-only boundary is required.

Batch small same-shape changes into one implementer and one review. Keep substantial
tasks separate. Serialize implementations in a shared checkout. Parallel independent
investigation or review is appropriate when it cannot race with edits to its inputs.

## Task loop

1. Record the task's `BASE` commit before implementation. Run
   `scripts/task-brief PLAN_FILE N` for each included task. The command reports
   the brief path; pass that path to the implementer, not its contents.
2. Supply the brief, binding Global Constraints, relevant prior interfaces or
   decisions, workspace, and report path. Exact requirements remain in the brief;
   update the plan and regenerate affected briefs after an authorized correction. Do not paste session history.
3. Inspect the worker's status. `DONE` proceeds to review. For `DONE_WITH_CONCERNS`,
   resolve correctness concerns or give them to the reviewer explicitly.
   For `NEEDS_CONTEXT` or `BLOCKED`, supply missing context, split the task, or
   revise the approach. Redispatch only after something relevant changes.
4. Once the worker finishes, inspect the diff and report. Generate
   `scripts/review-package PLAN_FILE BASE HEAD`; it reports the package path.
   Use the recorded BASE, not `HEAD~1`, so multi-commit tasks remain in scope.
5. Dispatch the task reviewer with the brief, report, package, and binding
   constraints. Require both spec-compliance and quality verdicts. The reviewer
   checks source evidence; it does not rerun valid tests merely to repeat them.
6. Evaluate every finding against the source and requirements before ordering fixes.
   Resolve requirements marked unverified using controller context or a focused check.

Do not coach a reviewer to suppress a suspected finding. Once it reports, adjudicate
on evidence immediately; independence does not require treating a false claim as true.

## Findings and fix rounds

Classify findings as confirmed, refuted, out of scope, or unresolved. Record the
reason and source evidence. Confirmed correctness gaps and Important/Critical
findings block completion. Record minor improvements for final triage.
A finding mandated by the plan still deserves evaluation; obtain a user decision
if fixing it changes an approved outcome. The plan cannot justify a known defect.

Batch confirmed related findings into one fix dispatch. Resume the implementer
with `SendMessage` when its context remains useful. Use a fresh implementer when
an approach stalls; include prior attempts and the remaining evidence gap.

Each round consists of a fix, affected checks, and a scoped re-review:

- Record `FIX_BASE` before the fix. The implementer appends the change and test
  evidence to its report, without repeating earlier unchanged output.
- Generate `scripts/review-package PLAN_FILE FIX_BASE HEAD` after the fix finishes.
- Send findings, brief, report, and new package to `superpowers:sdd-re-reviewer`.
- Re-review the fixes and new breakage they introduce. Broader observations go to
  final triage unless they reveal a concrete blocker to dependent work.
- Ledger `Task N: fix round R/5 — addressed/open findings; commits BASE..HEAD`.

Five rounds is a maximum, not a target or a wait before adjudication. Stop a
repeated unsuccessful approach earlier when it produces no new evidence. Refute
a disproved finding at any round. Change the investigative approach or ask for the
missing decision when a real blocker remains. At the cap, report remaining blockers;
do not label unfinished correctness work complete or silently defer it.

Mark complete only when acceptance checks hold and blocking findings are resolved.
Ledger `Task N: complete (commits BASE..HEAD; evidence: REPORT)` plus any explicitly
accepted deferrals, then update its native task.

## Whole-branch review and finish

Record the branch's starting base during setup. After task reviews, generate a
package from that base to HEAD and dispatch `superpowers:code-reviewer`. Include
requirements and the ledger's deferred findings. This review checks integration
across tasks, not just each task in isolation.

Use `superpowers:cross-reviewing-with-cursor` when requested or when substantial
risk or uncertainty warrants an outside review. Both reviewers can run concurrently
against the same stable range. Verify and deduplicate findings before fixing them.

Batch confirmed final findings into a fix wave and scoped re-review. Apply the
same bounded loop and completion conditions as above. A fixed wave count never
makes a remaining blocker acceptable.

Use `superpowers:verification-before-completion` and then
`superpowers:finishing-a-development-branch`. Report material rulings, accepted
deferrals, unresolved checks, and the evidence locations. Keep the plan workspace
through review and integration. Remove only this plan's disposable artifacts after
needed decisions and evidence are preserved and cleanup is authorized.
