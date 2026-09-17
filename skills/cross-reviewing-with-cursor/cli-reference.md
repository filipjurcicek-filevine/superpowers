# Cross-review CLI invocation

Read this only when a cross-review is warranted. These recipes preserve the
existing CLI behavior; they are not a guarantee of sandbox enforcement.

## Availability

Cursor review is optional. Run `command -v cursor-agent`; skip if it is absent.
Before resolving a model or launching a review, establish active paid access and
remaining plan allowance from current account evidence. Use a documented read-only
status command if available, or current account information supplied by the user.
CLI installation, successful login, and model listings do not establish eligibility.

Skip if the account is free, access is unavailable, allowance is exhausted, or
eligibility cannot be established. Do not launch a billable request to discover
whether the account qualifies. Do not install a CLI, ask for an upgrade, enable
paid overage, switch accounts or models, or fall back to another review provider.

If a run reports an authentication, subscription, quota, or usage-limit error,
stop and skip without retrying. Remember the reason for this task; recheck only
when access changes or the user asks. Rechecking never authorizes a bypass.

Say once: `Cursor review skipped: <reason>.` Continue the main workflow and its
local checks. If the review was the entire request, report the skip and stop.
A skipped review is not a passing review or evidence of no findings.

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
   review. Retry at most once for a transient network failure while paid access
   and allowance remain valid. Explain why. Access or quota errors are skips.
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
