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
task in the plan. The only reasons to stop are a BLOCKED status you cannot
resolve, ambiguity that genuinely prevents progress, or all tasks complete.
"Should I continue?" prompts and progress summaries waste the user's time — they
asked you to execute the plan, so execute it.

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

**The ledger.** Track progress in a file, not only in todos. Context is
summarized as a session grows, and a controller that lost its place has
re-dispatched entire completed task sequences — the single most expensive failure
observed. The ledger is the resume point across both summarization and session
restart. Use it alongside TodoWrite, not instead of it.

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
  this skill — dispatch, fix round, complete, minor, parked, BLOCKED. One event,
  one line; only a parked ruling may run to three. No methodology narration, no
  reviewer praise, no self-correction essays, no restating facts an earlier entry
  already holds. Every extra line is re-read on every later turn. A lesson about
  your own process is not state: it goes in your final report to the user,
  because the workspace — this file included — is deleted at Finish.
- **Append with a shell append**, `cat >> progress.md <<'EOF'`, not the Edit
  tool. Edit re-sends anchor text that grows with the file and triggers a
  permission prompt for every entry.

Read the plan once, note its context and Global Constraints, and create a todo
per task.

**If `TaskCreate` is in your tool list**, mirror the plan into native tasks
instead of todos. They add two things todos don't: `blockedBy` dependency
enforcement, which is what actually stops a later task being started before the
interface it consumes exists, and a live task panel in the IDE, so the user can
see what is done, blocked, and next without reading your output. The ledger stays
the resume mechanism either way.

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

Before dispatching Task 1, scan the plan once for conflicts:

- tasks that contradict each other or the plan's Global Constraints
- anything the plan explicitly mandates that the review rubric treats as a defect
  (a test that asserts nothing, verbatim duplication of a logic block)

Present everything you find to the user as one batched question — each finding
beside the plan text that mandates it, asking which governs — before execution
begins, not one interrupt per discovery mid-plan. If the scan is clean, proceed
without comment. The review loop remains the net for conflicts that only emerge
from implementation.

## Dispatch Roles

Every role is a defined agent type. Dispatch by type; do not compose role
instructions yourself, and do not paste role templates into prompts.

| Role | Agent type | Effort | Tools |
|------|-----------|--------|-------|
| Implementer — a task, a fix round, or the final fix wave | `superpowers:sdd-implementer` | high | full |
| Task reviewer | `superpowers:sdd-task-reviewer` | high | read-only |
| Scoped re-reviewer — a task fix round or the final fix wave | `superpowers:sdd-re-reviewer` | high | read-only |
| Final whole-branch reviewer | `superpowers:code-reviewer` | xhigh | read-only |

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

Two tiers, on one distinction: breadth of judgment. Authors and task-scoped gates
run `high`; the whole-branch gate runs `xhigh` because it holds the entire change
and owns merge readiness. Nothing here runs lower. A scoped re-review looks
narrow, but deciding whether a specific defect *still exists* after someone
attempted to remove it is subtler than reviewing fresh code, and it is the last
check before a task is marked clean.

**Escalation.** Rounds 4-5 of the fix loop escalate by fresh context plus
explicit framing (below), not by a bigger model. When a round genuinely needs a
higher effort tier than its definition carries, drive that one round through the
Workflow tool, where effort is a per-call option.

## The Task Loop

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
framing. A too-large task gets split. A wrong plan goes to the user.

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
  requires — are the user's decision, like any plan contradiction: present the
  finding and the plan text, ask which governs. Do not dismiss the finding
  because the plan mandates it, and do not dispatch a fix that contradicts the
  plan without asking.

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
  `Task <N>: parked — <finding> — ruling: <why the code stands>`. The final review
  sees both sides.
- **Real, but nothing downstream builds on it:** park it the same way, with a
  ruling that says it's real and deferred.
- **Real and load-bearing** — a later task builds on it, or it reveals a plan
  defect: STOP. Append `Task <N>: BLOCKED — <reason>` and report to the user with
  the finding, the plan text it collides with, and the fix history. Parking a
  structural failure lets every dependent task build on it and hands the final
  review a problem it cannot fix either.

Adjudicate only at the cap. Adjudicating earlier to end a loop is pre-judging
with a different name. Every adjudication is a ledger entry; a silent discard is
forbidden.

### 5. Complete the task

When the review comes back clean — or every open finding is parked with a ruling
at the cap — append the completion line to the ledger in the same message as your
other bookkeeping:

- `Task <N>: complete (commits <base7>..<head7>, review clean)`
- `Task <N>: complete (commits <base7>..<head7>, <K> parked)` after a tripped breaker

Then mark the todo (or task) complete and move on. Never move to the next task
while the review has open Critical/Important issues that are neither fixed nor
parked-with-ruling at the cap.

## Final Review

Run `scripts/review-package PLAN_FILE MERGE_BASE HEAD` (MERGE_BASE = the commit
the branch started from, e.g. `git merge-base main HEAD`) and dispatch
`superpowers:code-reviewer` with the printed path, so it reads one file instead
of re-deriving the branch diff. Point it at the ledger's deferred-minor and
parked lines so it can triage which must be fixed before merge.

**Then cross-review the branch while that reviewer works.** Use
superpowers:cross-reviewing-with-codex, site 3 — `codex review --base <merge-base>`.
The two reviews are independent, so running them concurrently costs little
wall-clock. Merge the finding sets afterward: agreement is evidence but not proof
(two models share assumptions), Codex-only findings go through the verification
gate, and our reviewer's findings stand on their own. Deduplicate by file and line.

If the final review returns findings — from either reviewer — dispatch ONE
`superpowers:sdd-implementer` with the complete merged list, not one fixer per
finding and not a second wave for the Codex set. Per-finding fixers each rebuild
context and re-run suites; a real session's final-review fix wave cost more than
all its tasks combined. Then run exactly one scoped re-review of the fix wave
(`scripts/review-package PLAN_FILE FIX_BASE HEAD`, `superpowers:sdd-re-reviewer`).
Adjudicate residual findings as in the task loop's breaker: park with rulings, or
stop on load-bearing ones. There is no second fix wave — residual load-bearing
findings surface to the user when finishing-a-development-branch presents the
options.

## Finish

When the final review is clean and its fixes are merged, delete this plan's
workspace (`rm -rf <workspace>`) — the git history is the record now. Sibling
directories belong to other plans; leave them alone.

Use superpowers:finishing-a-development-branch.

## Why This Loop Is Prose, Not a Workflow

The Workflow tool would give this loop deterministic control flow and journaled
resume for free. It is deliberately not used here: this loop stops for the user
at several branches — plan conflicts, plan-mandated findings, load-bearing
findings at the cap — and those gates are where the loop earns its quality. A
script that has to run to completion turns each of them into a guess.

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
[Create todos for all tasks]

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

[Delete this plan's workspace — the record now lives in git]

Done! Using superpowers:finishing-a-development-branch.
```
