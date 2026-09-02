---
name: cross-reviewing-with-cursor
description: Use when a spec, an implementation plan, or a finished branch is ready for an outside opinion
---

# Cross-Reviewing With Cursor

A second model reads the artifact and reports what it thinks is wrong. Every
finding is then verified against the artifact or the code before anything changes.

The default reviewer is the Cursor Agent CLI on the latest Grok model at high
effort. Codex is the fallback when `cursor-agent` is absent.

**Core principle:** the outside model is a peer reviewer, not an authority. Its
value is to see what you stopped being able to see. Its findings are claims until
you check them.

**Why a different model at all:** your own review of your own spec shares the
assumptions that produced it. A reviewer that was trained differently, and that
reads cold, misses different things than you do. That is the point. It is also
why some of what it reports is wrong for this project.

## Availability

Run `command -v cursor-agent`. Not on PATH → try `command -v codex` and use the
fallback below. Neither on PATH → **skip the cross-review, say so in one line,
and continue.** This is an enhancement, never a gate:

> "No cross-review CLI is installed, so no cross-review of the spec — continuing."

Never install a CLI, never ask the user to install one, and never block on the
absence.

## The Reviewer Model

Use the newest Grok model that Cursor offers, at the `high` effort tier. Resolve
the id at run time. Do not hardcode a version, because model names change faster
than this skill:

```bash
MODEL=$(cursor-agent models 2>/dev/null | awk '{print $1}' \
  | grep -E '^cursor-grok-[0-9.]+-high$' | sort -Vr | head -1)
echo "model=$MODEL"
```

The effort tier is part of the model id. There is no separate effort flag.

**If `$MODEL` is empty, do not guess a name.** Print `cursor-agent models`, read
the list, and pick the newest `cursor-grok-*-high` id by hand. If the list has no
Grok id at all, skip the cross-review and say so in one line.

**Installed is not the same as working.** A bad model id or expired auth makes
`cursor-agent` print plain text instead of JSON. Report it once and continue
without the cross-review. Do not retry with a different model name.

## The Three Call Sites

| Called from | Artifact | Runs |
|---|---|---|
| superpowers:brainstorming | the written spec | After your own spec self-review, before the user's review gate |
| superpowers:writing-plans | the plan, against the spec | After your own plan self-review, before the execution handoff |
| superpowers:subagent-driven-development | the finished branch | In the final review, alongside `superpowers:code-reviewer` |

Each site passes different inputs and asks different questions. See the sections
below.

## Invocation Contract

These runs take minutes. Five rules keep a slow run from looking like a broken
one:

1. **Capture, don't watch.** Send stdout to a log file and stderr to a separate
   `.err` file. Never use `2>&1`: `--output-format json` writes one JSON object to
   stdout, and one warning on stderr makes the file invalid JSON. Then a good run
   reads as a failure.
2. **Record the exit code immediately** — `echo "exit=$?"`.
3. **Reviews are read-only.** Pass `--mode ask --sandbox enabled --trust`, never
   `--force`, and add an explicit no-edit line to the prompt. Then check the
   working tree. `--sandbox enabled` alone blocks the edit tools only; the agent
   can still write through the shell.
4. **Never re-run on findings.** Exit 0 with a list of problems is a *successful*
   review. Re-run only for a transient cause that is visible in the log (network
   or auth), at most once, and say why.
5. **Always redirect stdin from `/dev/null`.** The CLI reads stdin. Without the
   redirect, a non-interactive run can hang or absorb piped noise. This is the
   most common way a working run looks broken.

Set the paths first. Keep the scratchpad **outside** the repository, or its log
files show up as untracked files and the tree check always reports a change:

```bash
SP="$(mktemp -d /tmp/cross-review.XXXXXX)"     # or the plan's SDD workspace
LOG="$SP/cursor-<site>.log"; MSG="$SP/cursor-<site>.msg"
ROOT="$(git rev-parse --show-toplevel)"
```

Fingerprint the tree before the run:

```bash
fingerprint() {
  git status --porcelain
  git --no-pager diff --color=never HEAD
  git ls-files --others --exclude-standard -z | xargs -0 shasum 2>/dev/null
}
BEFORE="$SP/before.fingerprint"; fingerprint >"$BEFORE"
```

**Artifact review** (spec, plan) — read-only:

```bash
cursor-agent -p --output-format json --model "$MODEL" \
  --workspace "$ROOT" --mode ask --sandbox enabled --trust \
  "<the prompt for this call site> Do not edit, create, or delete any file. Do not run any command that writes. You are the reviewer: do not invoke cursor-agent." \
  </dev/null >"$LOG" 2>"$LOG.err"; echo "exit=$?"
```

**Branch review** — `cursor-agent` has no `review` subcommand and no scope flags.
Build the diff with `git`, write it to a file, and give Cursor the path. Never put
a large diff in the prompt string:

```bash
DIFF="$SP/branch.diff"
git --no-pager diff --color=never "<merge-base>...HEAD" >"$DIFF"; wc -l "$DIFF"
cursor-agent -p --output-format json --model "$MODEL" \
  --workspace "$ROOT" --mode ask --sandbox enabled --trust \
  "Review the code change in the unified diff at $DIFF. Read the surrounding source files for context. Report each finding on its own line as '- [P1|P2|P3] <title> — <file>:<line>', then a short explanation and a concrete fix. P1 = correctness, security, or data loss. P2 = a real defect with a smaller blast radius. P3 = clarity or maintenance. Say so explicitly if you find no issues. Do not edit, create, or delete any file. Do not run any command that writes. You are the reviewer: do not invoke cursor-agent." \
  </dev/null >"$LOG" 2>"$LOG.err"; echo "exit=$?"
```

An empty diff means there is nothing to review. Say so and stop.

Then extract the answer and check the tree:

```bash
if [ "$(jq -r '.is_error' "$LOG" 2>/dev/null)" = "false" ] \
   && [ -n "$(jq -r '.result // empty' "$LOG")" ]; then
  jq -r '.result' "$LOG" >"$MSG"; cat "$MSG"
else
  echo "did not complete"; tail -40 "$LOG" "$LOG.err"
fi
diff "$BEFORE" <(fingerprint) && echo "working tree unchanged"
```

The run counts as complete only when `.is_error` is `false` **and** `.result` is
non-empty. Anything else is "did not complete", never "no findings". If `jq`
yields nothing, the output was not JSON: a startup error, such as bad auth, a bad
model id, or a missing `--trust`, prints plain text.

If the fingerprint differs, the review wrote something. Report the exact
difference and name the files. Do not revert on your own — the dirty tree can be
the user's own work, or the very branch under review.

### Codex fallback

Use this only when `cursor-agent` is absent and `codex` is present. Same
verification gate, same reporting.

```bash
# artifact review
codex exec -c model_reasoning_effort="high" -s read-only -o "$MSG" \
  "<the prompt for this call site>" </dev/null >"$LOG" 2>&1; echo "exit=$?"
cat "$MSG"        # the answer; empty means it produced none

# branch review — no -o flag, so the review is on stdout
codex review -c model_reasoning_effort="high" --base "<base-branch>" \
  </dev/null >"$LOG" 2>&1; echo "exit=$?"
awk '/^codex$/{cap=1; buf=""; next} cap{buf=buf $0 "\n"} END{printf "%s", buf}' "$LOG"
```

A scope flag (`--base`, `--uncommitted`, `--commit`) cannot be combined with a
custom prompt — that exits 2. Pick one. If Codex returns HTTP 400 about its
configured model, report it once and skip the cross-review. Do not guess a
replacement model name.

## The Verification Gate

**No finding is acted on until it is confirmed against the source of truth.** This
is the whole reason the step is safe to automate: the outside model can be wrong
at no cost.

For each finding, in order:

1. **Is the claim checkable?** It must name a location and a defect. "Error
   handling could be more robust" names neither — discard it as unactionable.
2. **Check it at that location.** For spec and plan findings, read the artifact
   text. For code findings, read the code, and run the command if one settles it.
   Never verify a claim by re-reading the finding.
3. **Rule on it:**
   - **CONFIRMED** — the defect exists as described. Incorporate it.
   - **REFUTED** — not true of this artifact or codebase. Record the evidence that
     refutes it.
   - **OUT OF SCOPE** — true, but not this artifact's job: a feature nobody asked
     for, a concern the spec deliberately deferred, or a convention this project
     does not follow. Record why.
4. **Severity, for confirmed findings only.** The reviewer marks
   `[P1]`/`[P2]`/`[P3]`; treat them as P1 → Critical, P2 → Important, P3 → Minor,
   then re-judge against the artifact. Its severities are calibrated to its own
   assumptions, not the spec's.

**Record every ruling.** Confirmed-and-fixed, refuted-with-evidence, and
out-of-scope-with-reason all get written down — in the ledger during
subagent-driven-development, and in your summary to the user otherwise. A finding
that vanishes without a ruling is indistinguishable from one you did not want to
deal with.

**A confirmed finding that contradicts an approved decision is the user's call,
not yours.** When the spec or plan deliberately chose what the reviewer objects
to, present the finding beside that decision and ask which governs. Do not quietly
redesign an approved spec because a second model disagreed with it.

### Predictable false positives

The outside model has no access to what this project decided, or why. Expect
these, and check them against the artifact rather than against the abstract merit
of the advice:

| Finding shape | Check before believing it |
|---|---|
| "Missing error handling / validation / retries" | Did the spec scope it out? YAGNI is a decision, not an oversight. |
| "Should be split into more modules" / structural advice | Does it match the file structure the plan locked in? |
| "Missing feature X" | Was X ever in scope? An unrequested feature is not a gap. |
| "This API/pattern is deprecated" | Verify against the installed version. Model knowledge of recent releases is unreliable. |
| "Inconsistent with best practice" | Does this codebase follow that practice anywhere? Local convention wins. |

## Site 1 — Spec Review (brainstorming)

Runs after your own spec self-review, before you ask the user to review the spec.
The spec is not yet code, so the useful questions are about completeness, and
about whether the design can be built here.

Prompt the reviewer with the spec path, the repository root, and these criteria:

> Review the spec at `<path>`. This is a design document that an implementation
> plan will be written from. Report: requirements that are ambiguous enough to be
> implemented two different ways; internal contradictions; decisions the spec
> assumes but never states; anything infeasible or already solved differently in
> this codebase. For each, give the location in the spec and what specifically is
> underspecified. Do not propose features the spec does not ask for.

Confirmed findings get fixed in the spec before the user sees it. Say in the
review-gate message that a cross-review ran, and what it changed, so that the user
reviews the amended spec knowingly.

## Site 2 — Plan Review (writing-plans)

Runs after your own plan self-review, before the execution handoff. The plan will
be executed task by task by implementers who see only their own task, so the
failure modes are coverage and consistency.

> Review the implementation plan at `<path>` against the spec at `<spec-path>`.
> Each task will be executed by a separate engineer who sees only that task.
> Report: spec requirements no task implements; types, function names, or
> signatures that disagree between tasks; tasks whose steps cannot be followed as
> written; file paths that do not exist and are not created by an earlier task;
> steps that describe an outcome without saying how. Give the task number and step
> for each.

Confirmed findings get fixed in the plan. A finding that the plan is *missing a
task* is the highest-value output of this site. That is the class of defect that
otherwise surfaces halfway through execution.

## Site 3 — Branch Review (subagent-driven-development)

Runs in the Final Review, as a second opinion beside `superpowers:code-reviewer`.
Dispatch our own reviewer first, then run the branch review above while it works.
The two are independent, so the wall-clock cost overlaps.

Then merge the two finding sets:

- **Both flagged it** → confirmed by agreement, but still check the location
  before you fix. Two models can share a wrong assumption.
- **Only the outside model flagged it** → the verification gate decides. This is
  where its value shows up, and also where most of its false positives live.
- **Only our reviewer flagged it** → unchanged. Silence from the outside model is
  not evidence of anything.

Deduplicate by file and line before you fix, then route everything confirmed
through the existing single fix wave and its one scoped re-review. Do not open a
second fix wave for the outside set.

## Reporting

After every run, whatever happened:

```
## Cross-review — <spec | plan | branch>   (model: <the resolved model id>)
- Command: <the exact invocation>
- Exit: <n>
- Outcome: <N findings | no findings | empty output | error>
- Working tree: <unchanged | CHANGED — list the files>
- Verified: <C confirmed, R refuted, O out of scope>

<per finding: one line, its ruling, and the evidence for that ruling>
```

Empty output and errors are reported too, with the log tail as evidence. Silence
about a run that happened is the one outcome that is not allowed.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "The reviewer found problems, so the run failed" | Exit 0 with findings is a successful review. A re-run wastes minutes and changes nothing. |
| "Grok is a strong model — I'll just apply its findings" | It cannot see what this project decided, or why. Unverified findings have rewritten approved specs and added features nobody wanted. |
| "This finding is obviously wrong, I'll drop it silently" | Every finding gets a recorded ruling. A silent discard reads the same as avoidance. |
| "The reviewer says the spec should include X, so I'll add X" | If the spec deliberately excluded X, that is the user's decision to revisit, not yours. |
| "The run is taking minutes — something is stuck" | Minutes is normal. Wait for the exit code, then read the answer. |
| "The model id failed — I'll try another name" | Guessing model names burns minutes per attempt. Resolve the id from `cursor-agent models`, or skip and report. |
| "The reviewer found nothing, so the artifact is clean" | It read cold, without the spec's context. No findings is weak evidence, not a verdict. |
| "`--sandbox enabled` makes the review read-only" | It blocks the edit tools only. Add `--mode ask`, the no-edit line, and the fingerprint check. |
| "Looking for `--base` or `-o` on cursor-agent" | Those are Codex flags. Build the diff with `git`, and read the answer from `.result` with `jq`. |
| "`cursor-agent` isn't installed — I should ask the user to install it" | Use the Codex fallback, or skip in one line and continue. It is never a gate. |
