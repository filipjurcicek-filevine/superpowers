# Cross-review CLI invocation

Read this only when a cross-review is warranted. The `read-only` sandbox blocks
writes from model shell commands. Still check the tree after each run.

## Availability

Codex review is optional. Run `command -v codex`; skip if it is absent.
Before resolving a model or launching a review, establish active paid access and
remaining plan allowance from current account evidence. `codex login status`
shows the login method only. It does not show plan or remaining allowance. Use
current account information supplied by the user for those.

Skip if the account is free, access is unavailable, allowance is exhausted, or
eligibility cannot be established. Do not launch a billable request to discover
whether the account qualifies. Do not install a CLI, ask for an upgrade, enable
paid overage, switch accounts or models, or fall back to another review provider.

If a run reports an authentication, subscription, quota, or usage-limit error,
stop and skip without retrying. Remember the reason for this task; recheck only
when access changes or the user asks. Rechecking never authorizes a bypass.

Say once: `Codex review skipped: <reason>.` Continue the main workflow and its
local checks. If the review was the entire request, report the skip and stop.
A skipped review is not a passing review or evidence of no findings.

## The Reviewer Model

Use the newest Astra model that Codex offers, at `medium` reasoning effort.
Resolve the id at run time. Do not hardcode a version, because model names
change faster than this skill:

```bash
MODEL=$(codex debug models 2>/dev/null | jq -r '.models[].slug' \
  | grep -E '^gpt-[0-9.]+-astra$' | sort -Vr | head -1)
echo "model=$MODEL"
```

Pass the effort with `-c model_reasoning_effort='"medium"'` on every run. Do not
rely on `~/.codex/config.toml`, because the user can change it.

**If `$MODEL` is empty, do not guess a name.** Print the slugs from
`codex debug models`, read the list, and pick the newest `gpt-*-astra` id by
hand. If the list has no Astra id at all, skip the cross-review and say so in
one line.

**Installed is not the same as working.** A bad model id or expired auth makes
`codex exec` exit non-zero and write no final message. Report it once and
continue without the cross-review. Do not retry with a different model name.

## Invocation Contract

These runs take minutes. Five rules keep a slow run from looking like a broken
one:

1. **Capture, don't watch.** Write the final answer with `-o "$MSG"`. Send
   stdout to a log file and stderr to a separate `.err` file.
2. **Record the exit code immediately** — `rc=$?; echo "exit=$rc"`.
3. **Reviews are read-only.** Pass `-s read-only --ignore-rules --ephemeral`.
   Saved `allow` rules can run commands outside the sandbox, so `--ignore-rules`
   is required. Never pass
   `--dangerously-bypass-approvals-and-sandbox`, `--add-dir`, or `--worktree`.
   Add an explicit no-edit line to the prompt. Then check the working tree.
4. **Never re-run on findings.** Exit 0 with a list of problems is a *successful*
   review. Retry at most once for a transient network failure while paid access
   and allowance remain valid. Explain why. Access or quota errors are skips.
5. **Always redirect stdin from `/dev/null`.** `codex exec` appends piped stdin to
   the prompt. Without the redirect, a non-interactive run can hang or absorb
   piped noise. This is the most common way a working run looks broken.

Set the paths first. Keep the scratchpad **outside** the repository, or its log
files show up as untracked files and the tree check always reports a change:

```bash
SP="$(mktemp -d /tmp/cross-review.XXXXXX)"     # or the plan's SDD workspace
LOG="$SP/codex-<site>.log"; MSG="$SP/codex-<site>.msg"
ROOT="$(git rev-parse --show-toplevel)"
CODEX=(codex exec -m "$MODEL" -c model_reasoning_effort='"medium"' \
  -s read-only --ignore-rules --ephemeral -C "$ROOT" -o "$MSG")
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
"${CODEX[@]}" \
  "<the prompt for this call site> Do not edit, create, or delete any file. Do not run any command that writes. You are the reviewer: do not invoke codex." \
  </dev/null >"$LOG" 2>"$LOG.err"; rc=$?; echo "exit=$rc"
```

**Branch review** — build the diff with `git`, write it to a file, and give
Codex the path. This pins the review to a stable range. Never put a large diff
in the prompt string:

```bash
DIFF="$SP/branch.diff"
git --no-pager diff --color=never "<merge-base>...HEAD" >"$DIFF"; wc -l "$DIFF"
"${CODEX[@]}" \
  "Review the code change in the unified diff at $DIFF. Read the surrounding source files for context. Report each finding on its own line as '- [P1|P2|P3] <title> — <file>:<line>', then a short explanation and a concrete fix. P1 = correctness, security, or data loss. P2 = a real defect with a smaller blast radius. P3 = clarity or maintenance. Say so explicitly if you find no issues. Do not edit, create, or delete any file. Do not run any command that writes. You are the reviewer: do not invoke codex." \
  </dev/null >"$LOG" 2>"$LOG.err"; rc=$?; echo "exit=$rc"
```

An empty diff means there is nothing to review. Say so and stop.

Then read the answer and check the tree:

```bash
if [ "$rc" = 0 ] && [ -s "$MSG" ]; then
  cat "$MSG"
else
  echo "did not complete"; tail -40 "$LOG" "$LOG.err"
fi
diff "$BEFORE" <(fingerprint) && echo "working tree unchanged"
```

The run counts as complete only when the exit code is 0 **and** `$MSG` is
non-empty. Anything else is "did not complete", never "no findings". A startup
error, such as bad auth or a bad model id, shows in `$LOG.err`.

If the fingerprint differs, the review wrote something. Report the exact
difference and name the files. Do not revert on your own — the dirty tree can be
the user's own work, or the very branch under review.
