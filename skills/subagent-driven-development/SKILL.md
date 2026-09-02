---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute a plan by dispatching a fresh implementer subagent per task, a task
review (spec compliance + code quality) after each, and a broad whole-branch
review at the end.

**Why subagents:** each task gets a reader who has not already rationalized the
code into existence, working from context you constructed deliberately rather
than inheriting your session's history. You stay the coordinator: you hold the
plan, the cross-task interfaces, and the decisions.

**Core principle:** fresh subagent per task + task review (spec + quality) +
broad final review = high quality, fast iteration

**Narration:** between tool calls, narrate at most one short line — the ledger
and the tool results carry the record.

**Continuous execution:** do not pause to check in between tasks. Execute every
task in the plan. The only reasons to stop are the four below, or all tasks
complete. "Should I continue?" prompts and progress summaries waste the user's
time — they asked you to execute the plan, so execute it.

**Rulings, not stalls.** A running plan does not wait on the user. Decide the
conflicts, the ambiguities, the plan defects, and the caps you would otherwise
have asked to exceed. The spec is the binding authority, the plan is its
argument, and your judgment settles what neither answers. Record every decision
in the ledger as `Ruling: <what you decided> — <why> — <cost if wrong>`, then
carry on. Every ruling takes that form, wherever it is written: a preflight
table row, a parked finding, a breaker adjudication. A wrong ruling costs rework
the user can see and undo; a session parked on a question costs the user a day
and buys nothing.

Four things stop you, and only these:

- an irreversible or destructive operation
- a security-sensitive action
- a side effect outside this worktree that norms say you ask about first — a
  merge, a push to a shared branch, a publish
- a plan so broken that every path forward is a guess

## When to Use

| Condition | Route |
|-----------|-------|
| Plan exists, tasks mostly independent | This skill |
| Plan exists, tasks tightly coupled | superpowers:executing-plans (inline) |
| The user wants to watch and steer each step | superpowers:executing-plans (inline) |
| No plan yet | superpowers:brainstorming, then superpowers:writing-plans |

## Setup

Ensure the work happens in an isolated workspace: use
superpowers:using-git-worktrees to create one or verify the existing one. Never
start implementation on a main/master branch without the user's explicit consent.

**The ledger.** Track progress in a file, not only in your task list. Context is
summarized as a session grows, and a controller that lost its place has
re-dispatched entire completed task sequences — the single most expensive failure
observed. The ledger is the resume point across both summarization and session
restart, neither of which a task list survives. Use it alongside the task list,
not instead of it.

- Each plan owns a workspace: at skill start, run this skill's
  `scripts/sdd-workspace PLAN_FILE` — it prints the plan's git-ignored directory
  (`<repo-root>/.superpowers/sdd/<plan-basename>/`), home to every artifact for
  THIS plan: ledger, briefs, reports, review packages. Another plan's directory
  is never yours to read or write.
- Check for this plan's ledger at `<workspace>/progress.md`. If its first line
  names your plan file, tasks with a `Task <N>: complete` line are DONE — do not
  re-dispatch them; resume at the first task without one. A task whose last line
  is a fix round is mid-loop: resume the loop at the next round. A ledger whose
  first line names a different plan file — or a stray ledger at the old flat path
  `.superpowers/sdd/progress.md` — is another plan's progress: leave it in place
  and start your own, fresh.
- Create the ledger with its identity as the first line:
  `# SDD ledger — plan: <plan file path>`.
- The commits the ledger names exist in git even when your context no longer
  holds them. Trust the ledger and `git log` over recollection.
- `git clean -fdx` will destroy the workspace (it's git-ignored scratch); if that
  happens, recover from `git log`.
- **The ledger records state, not reasoning.** Entries are the one-line forms in
  this skill — dispatch, fix round, complete, minor, parked, `Ruling:`, BLOCKED.
  One event, one line; only a ruling may run to three. The preflight conflict
  table below is the one multi-line block the ledger holds. No methodology
  narration, no reviewer praise, no self-correction essays, no restating facts
  an earlier entry already holds. Every extra line is re-read on every later
  turn. A lesson about your own process is not state: it goes in your final
  report to the user, because the workspace — this file included — is deleted
  at Finish.
- **Append with a shell append**, `cat >> progress.md <<'EOF'`, not the Edit
  tool. Edit re-sends anchor text that grows with the file and triggers a
  permission prompt for every entry.

Read the plan once, note its context and Global Constraints, and mirror it into
native tasks with `TaskCreate`. When the plan names a **Spec:**, read that too —
the spec is the authority the plan argues from, and a conflict inside the plan
resolves against it. When no spec is reachable, say so in the ledger: rulings
made without one are provisional. The task panel is what the user watches to see
what is done, blocked, and next without reading your output; the ledger is what
you resume from.

- One task per plan task. Keep the subject compact — aim for 60 characters or
  fewer, no trailing detail. Every task's subject is re-injected into your context
  on periodic reminders, so a long one is paid for repeatedly. Detail belongs in
  the description.
- Set `blockedBy` for real dependencies. That is what stops a later task from
  being started before the interface it consumes exists.
- On completion, `TaskUpdate` to `completed` and shrink the description to its
  **Goal:** line plus `Complete — see ledger.` Full descriptions are re-injected
  the same way subjects are, and a finished task's detail survives in the plan,
  its brief, and the ledger.
- **When the user explicitly orders a verification** — "make sure X passes before
  moving on", "don't proceed until Y is proven" — that is a user-thrown gate.
  Create it as its own task, record `"userGate": true` in a `json:metadata` fence
  in the description alongside the exact command that proves it, and keep its full
  description on completion. Close it only after re-running that command and
  capturing the output. Declaring it verified inline, or substituting a cheaper
  check, is the failure this exists to prevent.

Before dispatching Task 1, scan the plan once for conflicts, and write down what
you checked as you check it:

- tasks that contradict each other or the plan's Global Constraints
- anything the plan explicitly mandates that the review rubric treats as a defect
  (a test that asserts nothing, verbatim duplication of a logic block)

The scan's output is a table, not a verdict. One row for every pair of tasks that
share a file or an interface: the two tasks, what one produces against what the
other consumes, and what you found. One row for every task: whether its own text
agrees with itself — the tests it specifies against the code it specifies, the
files it creates against the files it later touches. "The scan is clean" without
those rows is not a scan you ran.

Write the table to the ledger, clean rows included — the rows are the evidence
that the scan happened. Rule on every conflict it surfaces before execution
begins, the spec binding and the plan arguing, record each ruling beside its row
in the form above, and dispatch Task 1. Say nothing to the user about a clean
scan. The review loop remains the net for conflicts that only emerge from
implementation.

## Dispatch Roles

Every role is a defined agent type. Dispatch by type; do not compose role
instructions yourself, and do not paste role templates into prompts.

| Role | Agent type | Effort | Tools |
|------|-----------|--------|-------|
| Implementer — a task, a fix round, or the final fix wave | `superpowers:sdd-implementer` | low | full |
| Task reviewer | `superpowers:sdd-task-reviewer` | medium | read-only |
| Scoped re-reviewer — a task fix round or the final fix wave | `superpowers:sdd-re-reviewer` | medium | read-only |
| Final whole-branch reviewer | `superpowers:code-reviewer` | medium | read-only |

These four are the only agent types that may receive a workspace artifact path.
A dispatch whose prompt carries a `.superpowers/sdd/` path under any other type
is blocked by the `pre-agent-effort-pin` hook, because it would run the role at
session effort with full write tools.

Each definition carries its own contract, effort tier, and tool set. Reviewers
have no file-editing tools, so their reviews are read-only by construction. Your
dispatch supplies only the variables that change per task — file paths, global
constraints, findings — never the role's instructions.

**Effort, not model tier.** One model runs every role; what varies is reasoning
effort, and the agent definitions set it. Per-call effort is not settable through
the Agent tool, so do not try to override it in a dispatch.

Two tiers, on one distinction: judgment versus execution. Every gate runs
`medium` — the task reviewer, the scoped re-reviewer, and the whole-branch
reviewer alike, because each one rules on whether work is correct. The
implementer runs `low`: it works from a task brief that already contains the
file paths and the code, and a gate checks everything it produces.

**Escalation.** Rounds 4-5 of the fix loop escalate by fresh context plus
explicit framing (below), not by a bigger model. When a round genuinely needs a
higher effort tier than its definition carries, drive that one round through the
Workflow tool, where effort is a per-call option.

## The Task Loop

**Batch small same-shape work.** When the plan lists several tasks that are each
a small, independent edit of the same kind — the same one-line fix, constant
change, or field addition repeated across files — do not dispatch one implementer
per task. Compose ONE dispatch listing every file and its change, send the whole
batch to a single implementer, and review its diff as one unit. Keep
one-dispatch-per-task for work that needs its own judgment, its own tests, or its
own review surface.

A batch runs the loop once, not once per task: run `scripts/task-brief PLAN_FILE N`
for every task in the batch and pass every brief path in the one dispatch, review
the whole diff with one task reviewer, then write one ledger line naming the range
(`Tasks <N>-<M>: complete (commits <base7>..<head7>, review clean)`) and
`TaskUpdate` each of those native tasks. Never re-enter the loop for a task the
batch already covered.

Everything you paste into a dispatch prompt — and everything a subagent prints
back — stays resident in your context for the rest of the session and is re-read
on every later turn. Hand artifacts over as files.

### 1. Dispatch the implementer

Record BASE (`git rev-parse HEAD`) before dispatching — the review package and
fix-round diffs need it.

- **Task brief:** run this skill's `scripts/task-brief PLAN_FILE N` — it extracts
  the task's full text to a uniquely named file and prints the path. The brief
  stays the single source of requirements. Your dispatch contains: (1) one line
  on where this task fits in the project; (2) the brief path, introduced as "read
  this first — it is your requirements, with the exact values to use verbatim";
  (3) interfaces and decisions from earlier tasks that the brief cannot know;
  (4) your resolution of any ambiguity you noticed in the brief; (5) the
  report-file path. Exact values (numbers, magic strings, signatures, test cases)
  appear only in the brief. Never make a subagent read the whole plan file.
- **Report file:** name it after the brief (brief `…/task-N-brief.md` → report
  `…/task-N-report.md`) and put the path in the dispatch.
- A dispatch describes one task, not the session's history. Do not paste
  accumulated prior-task summaries ("state after Tasks 1-3") into later
  dispatches — a real session's dispatch hit 42k chars of which 99% was pasted
  history. A fresh subagent needs its task, the interfaces it touches, and the
  global constraints. Nothing else.
- If an earlier task parked a finding in the area this task touches, carry a
  pointer to that ledger entry in the dispatch.
- Record the implementer's agent identity from the dispatch result — fix-loop
  rounds 1-3 resume that agent with SendMessage, which restores its context
  intact.
- Never dispatch multiple implementation subagents in parallel (conflicts).

### 2. Handle the report

**DONE:** generate the review package (`scripts/review-package PLAN_FILE BASE HEAD`,
from this skill's directory — it prints the unique file path it wrote; BASE is the
commit you recorded before dispatching, never `HEAD~1`, which silently drops all
but the last commit of a multi-commit task), then dispatch the task reviewer with
the printed path. Generate it only after the report lands, never while the
implementer is still working — the diff is a moving target, and a package built
early arrives stale.

**DONE_WITH_CONCERNS:** the work is complete but the implementer has doubts. Read
the concerns first. Concerns about correctness or scope get addressed before
review; observations ("this file is getting large") get noted, and review
proceeds.

**NEEDS_CONTEXT:** supply what was missing and re-dispatch.

**BLOCKED:** assess the blocker. A context problem gets more context and a
re-dispatch. A reasoning problem gets a fresh implementer with the escalation
framing. A too-large task gets split. A wrong plan gets a ruling on the
correction, a ledger line, and a re-dispatch that carries the ruling.

Never ignore an escalation, and never re-dispatch unchanged after one. If the
implementer said it was stuck, something has to change.

If an implementer asks questions — before starting or mid-task — answer clearly
and completely, add context if needed, and don't rush it into implementation.

### 3. Review the task

Per-task reviews are task-scoped gates; the broad review happens once, at the
end. Never skip the task review, and never accept a report missing either verdict
— spec compliance AND task quality are both required. Implementer self-review
never replaces the task review.

- **Hand the reviewer its diff as a file:** run
  `scripts/review-package PLAN_FILE BASE HEAD` and pass the printed path (or,
  without bash: `git log --oneline`, `git diff --stat`, and `git diff -U10` for
  the range, redirected to one uniquely named file). The output never enters your
  context, and the reviewer sees the commit list, stat summary, and full diff in
  one Read. Use the BASE you recorded, never `HEAD~1`. Never dispatch a task
  reviewer without a diff file.
- **Reviewer inputs:** the brief file, the report file, the review package, and
  the global constraints that bind the task.
- **The global-constraints block is the reviewer's attention lens.** Copy the
  binding requirements verbatim from the plan's Global Constraints section or the
  spec: exact values, exact formats, and stated relationships between components
  ("same layout as X", "matches Y"). The agent definition already carries the
  process rules (YAGNI, test hygiene, review method) — this block is for what
  THIS project's spec demands.
- Do not add open-ended directives like "check all uses" or "run race tests if
  useful" without a concrete, task-specific reason.
- Do not ask a reviewer to re-run tests the implementer already ran on the same
  code — the report carries the test evidence.
- **Do not pre-judge findings.** Never instruct a reviewer to ignore or not flag
  a specific issue. If you believe a finding would be a false positive, let the
  reviewer raise it and adjudicate it in the loop. If the prompt you are writing
  contains "do not flag", "don't treat X as a defect", "at most Minor", or "the
  plan chose" — stop: you are pre-judging, usually to spare yourself a review
  loop.

The reviewer may report "⚠️ Cannot verify from diff" items — requirements living
in unchanged code or spanning tasks. These do not block the rest of the review,
but you resolve each one yourself before marking the task complete: you hold the
plan and cross-task context the reviewer lacks. A confirmed gap is a failed spec
review and enters the fix loop with the other findings.

### 4. The fix loop

The loop triggers on spec ❌, any Critical or Important finding, or a ⚠️ item you
confirmed as a real gap.

Two routes leave it immediately:

- **Minor findings** get recorded in the ledger as you go
  (`Task <N>: minor (deferred): <one-liner>`), and the final whole-branch review
  is pointed at that list so it can triage what must be fixed before merge. A
  roll-up nobody reads is a silent discard. Minors never enter the loop.
- **Plan-mandated findings** — or any finding that conflicts with what the plan
  requires — are yours to rule on: weigh the finding against the plan text,
  decide with the spec as the binding authority, and ledger the ruling before you
  act on it. Do not dismiss the finding because the plan mandates it, and do not
  dispatch a fix that contradicts the plan without a recorded ruling.

Everything else enters the loop. A round is one fix dispatch plus one scoped
re-review. **Five rounds maximum per task.**

**Rounds 1-3 — resume the original implementer** with SendMessage, sending the
open findings verbatim. Its context is intact: it knows the task, the code, and
its own choices. If the agent can no longer be resumed, dispatch a fresh
`superpowers:sdd-implementer` carrying the brief path, the report-file path, and
the findings — the report file is the persistent memory either way.

**Rounds 4-5 — dispatch a fresh `superpowers:sdd-implementer`** with the brief
path, the report-file path, the open findings, and this framing: "A prior
implementer attempted this task [N] times; you own it now. Read the report file
for what was tried." A loop that survives three resumes usually means the
implementer cannot see its own problem, and fresh context is the lever that
fixes that.

**Every round, either way:** the implementer fixes, re-runs the tests covering
the amended code, appends its fix report to the same report file, and returns the
short contract. Before re-dispatching the reviewer, confirm the fix report
contains the covering tests, the command run, and the output. Name the covering
test files in the fix message — a one-line fix does not need the whole suite.

**The re-review is scoped.** Run `scripts/review-package PLAN_FILE FIX_BASE HEAD`
where FIX_BASE is the head the previous review saw, and dispatch
`superpowers:sdd-re-reviewer` with the findings list, the brief, the report file,
and the printed diff path. It verdicts each finding ADDRESSED or NOT ADDRESSED
and flags new breakage in the fix diff only. New Critical/Important breakage in
the fix diff joins the open findings. Out-of-scope observations go to the ledger
as deferred minors — they never extend the loop.

**After each round,** append to the ledger:
`Task <N>: fix round <R>/5 (<X> addressed, <Y> open — <finding one-liners>; commits <a7>..<b7>)`

Never fix findings yourself in the controller session — your context stays clean
for coordination, and controller fixes skip review.

**The breaker.** When round 5's re-review still leaves findings open, stop
dispatching and adjudicate each open finding yourself — you hold the plan and
cross-task context the reviewer lacks:

- **Reviewer is wrong, or the point is contestable:** park it —
  `Task <N>: parked — <finding> — Ruling: <why the code stands> — <cost if wrong>`.
  The final review sees both sides.
- **Real, but nothing downstream builds on it:** park it the same way, with a
  ruling that says it's real and deferred.
- **Real and load-bearing** — a later task builds on it, or it reveals a plan
  defect: rule on the smallest change that unblocks the dependent work, ledger it
  as `Task <N>: Ruling: <what you decided> — <why> — <cost if wrong>`, and carry
  it into the next task's dispatch. Parking a structural failure silently lets every
  dependent task build on it. Stop only when the defect leaves every path forward
  a guess.

Adjudicate only at the cap. Adjudicating earlier to end a loop is pre-judging
with a different name. Every adjudication is a ledger entry; a silent discard is
forbidden.

### 5. Complete the task

When the review comes back clean — or every open finding at the cap is parked or
ruled and carried forward — append the completion line to the ledger in the same
message as your other bookkeeping:

- `Task <N>: complete (commits <base7>..<head7>, review clean)`
- `Task <N>: complete (commits <base7>..<head7>, <K> parked, <R> ruled)` after a
  tripped breaker

Then `TaskUpdate` it to `completed` and move on. Never move to the next task
while the review has open Critical/Important issues that are neither fixed nor,
at the cap, parked or ruled.

## Final Review

Run `scripts/review-package PLAN_FILE MERGE_BASE HEAD` (MERGE_BASE = the commit
the branch started from, e.g. `git merge-base main HEAD`) and dispatch
`superpowers:code-reviewer` with the printed path, so it reads one file instead
of re-deriving the branch diff. Point it at the ledger's deferred-minor and
parked lines so it can triage which must be fixed before merge.

**Then cross-review the branch while that reviewer works.** Use
superpowers:cross-reviewing-with-cursor, site 3 — the branch review over
`git diff <merge-base>...HEAD`.
The two reviews are independent, so running them concurrently costs little
wall-clock. Merge the finding sets afterward: agreement is evidence but not proof
(two models share assumptions), outside-only findings go through the verification
gate, and our reviewer's findings stand on their own. Deduplicate by file and line.

If the final review returns findings — from either reviewer — dispatch ONE
`superpowers:sdd-implementer` with the complete merged list, not one fixer per
finding and not a second wave for the outside set. Per-finding fixers each rebuild
context and re-run suites; a real session's final-review fix wave cost more than
all its tasks combined. Then run exactly one scoped re-review of the fix wave
(`scripts/review-package PLAN_FILE FIX_BASE HEAD`, `superpowers:sdd-re-reviewer`).
Adjudicate residual findings as in the task loop's breaker: park with rulings, or
rule on the load-bearing ones and ledger what you decided. Only the four stop
classes stop you here. There is no second fix wave — residual load-bearing
findings surface to the user when finishing-a-development-branch presents the
options.

## Finish

Before you delete anything, collect every ledger line that contains `Ruling:` —
preflight rulings, parked findings, breaker adjudications, all of them — into
your final message under "Rulings I made", in the order you made them, each with
what it costs if wrong. The list is exhaustive: if the ledger holds a ruling, the
list holds it. That list is the only place the decisions you took on the user's
behalf reach them, and it is what they use to rework whatever you got wrong. A
ruling that dies with the workspace was a decision made in secret.

When the final review is clean and its fixes are merged, delete this plan's
workspace (`rm -rf <workspace>`) — the git history is the record now. Sibling
directories belong to other plans; leave them alone.

Use superpowers:finishing-a-development-branch.

## Why This Loop Is Prose, Not a Workflow

The Workflow tool would give this loop deterministic control flow and journaled
resume for free. It is deliberately not used here: the loop's quality comes from
judgment at its branches — the preflight conflicts, the plan-mandated findings,
the load-bearing findings at the cap. Each one gets a ruling that reads the spec,
the plan, and the code together, and the four stop classes still take the user's
answer. A script that has to run to completion turns every one of them into a
guess.

Use Workflow for the fan-out shapes inside a task (parallel investigation,
per-item pipelines) and for a single round that needs a different effort tier.
Keep the task loop here.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Close enough on spec compliance" | Reviewer found spec gaps = not done. Fix, or hit the cap and adjudicate — those are the only exits. |
| "I'll fix it myself, dispatching is overhead" | Controller fixes pollute your context and skip review. Resume the implementer. |
| "One more round will converge" | Past the cap, rounds don't converge — the failure is structural. Adjudicate and route. |
| "This finding is obviously wrong, I'll drop it" | You adjudicate only at the cap, and every ruling is a ledger entry. Silent discards are forbidden. |
| "The implementer dispatched its own reviewer — free extra assurance" | It is a duplicate seat on the same diff. The task review is the gate; a worker-spawned review is a defect to flag. |
| "The fix was small, skip the re-review" | Unreviewed fixes are how regressions land. Every round ends with a scoped re-review. |
| "Ledger bookkeeping is overhead" | The ledger is what survives summarization. Controllers without one have re-dispatched entire completed task sequences. |
| "The ledger should capture my reasoning" | It's a recovery map. State goes in one-liners; reasoning is a diary that costs context on every later turn. |
| "I'll note this process lesson in the ledger" | The workspace is deleted at Finish, and the lesson with it. Put it in your final report. |

## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Setup: worktree verified]
[Read plan file once: docs/superpowers/plans/feature-plan.md]
[Resolve workspace: scripts/sdd-workspace <plan> — no ledger inside, fresh start]
[TaskCreate for all plan tasks, with blockedBy for real dependencies]
[Ledger: preflight table — Tasks 1+2 share src/recovery.js: produces/consumes agree; each task self-consistent; no conflicts]

Task 1: Hook installation script

[task-brief for Task 1; dispatch superpowers:sdd-implementer with brief + report paths + context]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.config/superpowers/hooks/)"

Implementer: [Later]
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: found I missed --force flag, added it
  - Committed

[review-package PLAN BASE HEAD; dispatch superpowers:sdd-task-reviewer with the printed path]
Task reviewer: Spec ✅ - all requirements met, nothing extra.
  Strengths: good test coverage, clean. Issues: none. Task quality: Approved.

[Ledger: Task 1: complete (commits a1b2c3d..d4e5f6a, review clean)]

Task 2: Recovery modes

[task-brief for Task 2; dispatch superpowers:sdd-implementer]

Implementer: [No questions]
  - Added verify/repair modes
  - 8/8 tests passing
  - Committed

[review-package; dispatch superpowers:sdd-task-reviewer]
Task reviewer: Spec ❌:
  - Missing: progress reporting (spec says "report every 100 items")
  Issues (Important): magic number (100)

[Fix round 1: SendMessage to the implementer with both findings]
Implementer: Added progress reporting, extracted PROGRESS_INTERVAL constant.
  Re-ran test/recovery.test.js — 10/10 passing. Fix report appended.

[review-package FIX_BASE HEAD; dispatch superpowers:sdd-re-reviewer]
Re-reviewer: Missing progress reporting — ADDRESSED (src/recovery.js:41).
  Magic number — ADDRESSED (src/recovery.js:7). New breakage: none.
  Verdict: all findings addressed.

[Ledger: Task 2: fix round 1/5 (2 addressed, 0 open; commits d4e5f6a..b7c8d9e)]
[Ledger: Task 2: complete (commits d4e5f6a..b7c8d9e, review clean)]

...

[After all tasks]
[review-package PLAN MERGE_BASE HEAD; dispatch superpowers:code-reviewer]
Final reviewer: All requirements met. Deferred minors triaged: none block merge.

[Final message: "Rulings I made" — every Ruling: line from the ledger, in order]
[Delete this plan's workspace — the record now lives in git]

Done! Using superpowers:finishing-a-development-branch.
```
