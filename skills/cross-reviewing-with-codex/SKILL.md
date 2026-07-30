---
name: cross-reviewing-with-codex
description: Use when a spec, an implementation plan, or a finished branch is ready for an outside opinion
---

# Cross-Reviewing With Codex

A second model reads the artifact and reports what it thinks is wrong. Every
finding is then verified against the artifact or the code before anything changes.

**Core principle:** Codex is a peer reviewer, not an authority. Its value is
seeing what you stopped being able to see; its findings are claims until you
check them.

**Why a different model at all:** your own review of your own spec shares the
assumptions that produced it. A reviewer trained differently, reading cold,
misses different things than you do — which is exactly the point, and also why a
chunk of what it reports will be wrong for this project.

## Availability

Run `command -v codex`. Not on PATH → **skip the cross-review, say so in one
line, and continue.** This is an enhancement, never a gate:

> "Codex isn't installed, so no cross-review of the spec — continuing."

Never install it, never ask the user to, never block on its absence.

**Installed is not the same as working.** The model comes from
`~/.codex/config.toml` unless you pin one, and a configured model the CLI or the
account cannot serve fails every run. Both signatures are HTTP 400 in the log:

```
The '<model>' model requires a newer version of Codex.       → CLI too old for it
The '<model>' model is not supported when using Codex with a ChatGPT account.
```

Either one means the configured model is unusable. **Do not retry, and do not try
to guess a replacement model** — report it once and continue without the
cross-review:

> "Codex is installed but its configured model (`<name>`) returns 400: `<message>`.
> Skipping the cross-review. Pin a working model with `-c model=<name>` to enable it."

Model names the CLI knows are listed in `~/.codex/models_cache.json`. Pinning
belongs to the project, not to this skill: models change faster than skills, and a
hardcoded name here becomes a silent breakage later.

## The Three Call Sites

| Called from | Artifact | Runs |
|---|---|---|
| superpowers:brainstorming | the written spec | After your own spec self-review, before the user's review gate |
| superpowers:writing-plans | the plan, against the spec | After your own plan self-review, before the execution handoff |
| superpowers:subagent-driven-development | the finished branch | In the final review, alongside `superpowers:code-reviewer` |

Each site passes different inputs and asks different questions. Sections below.

## Invocation Contract

These runs take minutes and print a long transcript before the answer. Four rules
keep that from being misread:

1. **Capture, don't watch.** Redirect the transcript to a log file; for
   `codex exec`, put the clean answer in `-o`. Use the scratchpad directory, or
   the plan's SDD workspace when one exists.
2. **Record the exit code immediately** — `echo "exit=$?"`.
3. **Reviews are read-only.** `codex exec` gets `-s read-only`; it reports, it
   never edits. Incorporating findings is your job, under the verification gate
   below.
4. **Never re-run on findings.** Exit 0 with a list of problems is a *successful*
   review. Re-run only for a transient cause visible in the log (network, auth),
   at most once, and say why.

**Always redirect stdin from `/dev/null`.** Both commands read stdin; without the
redirect a non-interactive run can hang or silently absorb piped noise. This is
the most common way a working run looks broken.

```bash
SP="<scratchpad-or-sdd-workspace>"
LOG="$SP/codex-<site>.log"; MSG="$SP/codex-<site>.msg"
```

**Artifact review** (spec, plan) — `codex exec`, read-only:

```bash
codex exec -c model_reasoning_effort="high" -s read-only -o "$MSG" \
  "<the prompt for this call site>" </dev/null >"$LOG" 2>&1; echo "exit=$?"
cat "$MSG"        # the answer; empty means it produced none
tail -60 "$LOG"   # only when $MSG is empty or exit != 0
```

**Branch review** — `codex review`, which has no `-o`, so the review is on stdout:

```bash
codex review -c model_reasoning_effort="high" --base "<base-branch>" \
  </dev/null >"$LOG" 2>&1; echo "exit=$?"
awk '/^codex$/{cap=1; buf=""; next} cap{buf=buf $0 "\n"} END{printf "%s", buf}' "$LOG"
```

A scope flag (`--base`, `--uncommitted`, `--commit`) cannot be combined with a
custom prompt — that exits 2. Pick one.

If a project pins a model, add `-c model="<name>"` (`codex review` has no `-m`).

## The Verification Gate

**No finding is acted on until it is confirmed against the source of truth.** This
is the whole reason the step is safe to automate: the outside model gets to be
wrong without costing anything.

For each finding, in order:

1. **Is the claim checkable?** It must name a location and a defect. "Error
   handling could be more robust" names neither — discard it as unactionable.
2. **Check it at that location.** Spec and plan findings: read the artifact text.
   Code findings: read the code, and run the command if one settles it. Never
   verify a claim by re-reading the finding.
3. **Rule on it:**
   - **CONFIRMED** — the defect exists as described. Incorporate it.
   - **REFUTED** — not true of this artifact or codebase. Record the evidence that
     refutes it.
   - **OUT OF SCOPE** — true, but not this artifact's job: a feature nobody asked
     for, a concern the spec deliberately deferred, a convention this project
     doesn't follow. Record why.
4. **Severity, for confirmed findings only.** Codex marks `[P1]`/`[P2]`/`[P3]`;
   treat them as P1 → Critical, P2 → Important, P3 → Minor, then re-judge against
   the artifact. Its severities are calibrated to its own assumptions, not the
   spec's.

**Record every ruling.** Confirmed-and-fixed, refuted-with-evidence, and
out-of-scope-with-reason all get written down — in the ledger during
subagent-driven-development, in your summary to the user otherwise. A finding that
vanishes without a ruling is indistinguishable from one you didn't want to deal
with.

**A confirmed finding that contradicts an approved decision is the user's call,
not yours.** When the spec or plan deliberately chose what Codex is objecting to,
present the finding beside that decision and ask which governs. Do not quietly
redesign an approved spec because a second model disagreed with it.

### Predictable false positives

Codex has no access to what this project decided or why. Expect these, and check
them against the artifact rather than the abstract merit of the advice:

| Finding shape | Check before believing it |
|---|---|
| "Missing error handling / validation / retries" | Did the spec scope it out? YAGNI is a decision, not an oversight. |
| "Should be split into more modules" / structural advice | Does it match the file structure the plan locked in? |
| "Missing feature X" | Was X ever in scope? An unrequested feature is not a gap. |
| "This API/pattern is deprecated" | Verify against the installed version. Model knowledge of recent releases is unreliable. |
| "Inconsistent with best practice" | Does this codebase follow that practice anywhere? Local convention wins. |

## Site 1 — Spec Review (brainstorming)

Runs after your own spec self-review, before you ask the user to review the spec.
The spec is not yet code, so the useful questions are about completeness and
whether it can actually be built here.

Prompt Codex with the spec path, the repository root, and these criteria:

> Review the spec at `<path>`. This is a design document that an implementation
> plan will be written from. Report: requirements that are ambiguous enough to be
> implemented two different ways; internal contradictions; decisions the spec
> assumes but never states; anything infeasible or already solved differently in
> this codebase. For each, give the location in the spec and what specifically is
> underspecified. Do not propose features the spec does not ask for.

Confirmed findings get fixed in the spec before the user sees it. Mention in the
review-gate message that a cross-review ran and what it changed, so the user is
reviewing the amended spec knowingly.

## Site 2 — Plan Review (writing-plans)

Runs after your own plan self-review, before the execution handoff. The plan will
be executed task-by-task by implementers who see only their own task, so the
failure modes are coverage and consistency.

> Review the implementation plan at `<path>` against the spec at `<spec-path>`.
> Each task will be executed by a separate engineer who sees only that task.
> Report: spec requirements no task implements; types, function names, or
> signatures that disagree between tasks; tasks whose steps cannot be followed as
> written; file paths that do not exist and are not created by an earlier task;
> steps that describe an outcome without saying how. Give the task number and step
> for each.

Confirmed findings get fixed in the plan. A finding that the plan is *missing a
task* is the highest-value output of this site — that is the class of defect that
otherwise surfaces halfway through execution.

## Site 3 — Branch Review (subagent-driven-development)

Runs in the Final Review, as a second opinion beside `superpowers:code-reviewer`.
Dispatch our own reviewer first, then run `codex review --base <merge-base>` while
it works — they are independent, so the wall-clock cost overlaps.

Then merge the two finding sets:

- **Both flagged it** → confirmed by agreement, but still check the location
  before fixing. Two models can share a wrong assumption.
- **Only Codex flagged it** → the verification gate decides. This is where its
  value shows up, and also where most of its false positives live.
- **Only our reviewer flagged it** → unchanged; Codex not raising something is not
  evidence of anything.

Deduplicate by file and line before fixing, then route everything confirmed
through the existing single fix wave and its one scoped re-review. Do not open a
second fix wave for the Codex set.

## Reporting

After every run, whatever happened:

```
## Codex cross-review — <spec | plan | branch>
- Command: <the exact invocation>
- Exit: <n>
- Outcome: <N findings | no findings | empty output | error>
- Verified: <C confirmed, R refuted, O out of scope>

<per finding: one line, its ruling, and the evidence for that ruling>
```

Empty output and errors are reported too, with the log tail as evidence. Silence
about a run that happened is the one outcome that isn't allowed.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Codex found problems, so the run failed" | Exit 0 with findings is a successful review. Re-running wastes minutes and changes nothing. |
| "Codex is a strong model — I'll just apply its findings" | It cannot see what this project decided or why. Unverified findings have rewritten approved specs and added features nobody wanted. |
| "This finding is obviously wrong, I'll drop it silently" | Every finding gets a recorded ruling. A silent discard reads identically to avoidance. |
| "Codex says the spec should include X, so I'll add X" | If the spec deliberately excluded X, that is the user's decision to revisit, not yours. |
| "The run is taking minutes — something is stuck" | Minutes is normal. Wait for the exit code, then read the answer file. |
| "The model 400'd — I'll try a different model name" | Guessing model names burns minutes per attempt. Report the 400 and skip; pinning a working model is the project's job. |
| "Codex found nothing, so the artifact is clean" | It read cold, without the spec's context. No findings is weak evidence, not a verdict. |
| "codex isn't installed — I should ask the user to install it" | Skip the cross-review, say so in one line, continue. It is never a gate. |
