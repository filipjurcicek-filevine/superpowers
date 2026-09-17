---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work
---

# Finishing a Development Branch

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.

## Step 1: Verify Tests

Use `superpowers:verification-before-completion`: verify affected behavior and
required project checks, reusing valid results for unchanged inputs. Run the full
suite when project policy or integration risk requires it.

**If required checks fail or confirmed blocking findings remain**, report them
and stop integration. Keeping the workspace for investigation remains available:

```
Tests failing (<N> failures). Must fix before completing:

[Show failures]
```

**If required checks pass and blocking findings are resolved:** continue to Step 2.

## Step 2: Detect Environment

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
# Capture now, while still inside the workspace — Option 1 leaves the
# worktree before cleanup needs this value
WORKTREE_PATH=$(git rev-parse --show-toplevel)
BRANCH=$(git branch --show-current)
```

Then determine **who owns this workspace**, which decides how cleanup works:

| State | Owner | Menu | Cleanup |
|-------|-------|------|---------|
| `GIT_DIR == GIT_COMMON` | Normal checkout | Standard 3 options | No worktree to clean up |
| Entered via `EnterWorktree` **this session** | This session | Standard 3 options | `ExitWorktree` (Step 6) |
| Worktree from another session or the host, named branch | The host | Standard 3 options | Leave in place |
| Worktree, detached HEAD | The host | Reduced 2 options (no merge) | Leave in place |

`ExitWorktree` only acts on a worktree this session created with
`EnterWorktree`. Anywhere else it is a no-op — so for host-owned workspaces,
leave them alone and say so.

## Step 3: Determine Base Branch

The base branch is whatever this work forked from — usually named in the
plan, the conversation, or the branch's upstream. If it is not already
known, ask: "This branch split from <your best guess> - is that correct?"
Confirm before merging: merging into the wrong base is expensive to undo.

Note that `EnterWorktree` branches from `origin/<default-branch>` by default,
so a worktree branch's fork point is usually the remote default branch, not
the local HEAD you were on when you started.

## Step 4: Present Options

Honor an integration action already authorized for this work. If none was chosen,
ask with `AskUserQuestion` — one question, `header: "Integration"`. The tool
renders the options as choices and records which one was picked. A hand-typed
numbered menu invites a prose reply you then have to interpret, and invites you to
improvise a different option set.

**Normal checkout and named-branch worktree — exactly these 3 options:**

| Label | Description |
|-------|-------------|
| `Merge to <base> locally` | Merge, verify the merged result, then clean up |
| `Push and open a PR` | Push the branch and open a PR against `<base>` |
| `Keep the branch as-is` | Leave branch and workspace in place |

**Detached HEAD — exactly these 2 options** (no local merge is possible):

| Label | Description |
|-------|-------------|
| `Push as a new branch and open a PR` | Name the branch on the remote, then open a PR |
| `Keep as-is` | Leave the workspace in place |

Question text: "Implementation complete on `<branch>`. How would you like to
integrate it?" — for a detached HEAD, say so in the question so the missing merge
option is explained rather than merely absent.

Take every option from the table above and add none of your own. **Discarding is
not an option in this menu** — it happens only when the user asks for it in so
many words (see below). When asking for a new decision, wait for their answer.

## Step 5: Execute Choice

### Option 1: Merge Locally

Merging requires the base branch's checkout, which is not this worktree — so
this option leaves the worktree first. Choosing it is the request that
authorizes the exit.

**1. Confirm everything is committed** (`git status --short` clean).

**2. Leave the worktree, keeping it on disk:**

- Session worktree (created by `EnterWorktree` this session):
  `ExitWorktree` with `action: "keep"`. The session returns to the original
  checkout, and the worktree and branch stay intact — the merge has not
  happened yet, so nothing is disposable.
- Host-owned worktree: `cd` to the main checkout instead.
  ```bash
  MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
  cd "$MAIN_ROOT"
  ```
- Normal checkout: nothing to leave.

**3. Merge and verify:**

```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
<test command>
```

If tests fail on the merged result: stop, leave the worktree and branch in
place, and investigate — nothing has been pushed, so the merge is local
and recoverable.

**4. Once the merged result is green:** clean up (Step 6), then delete the
branch if it still exists:

```bash
git branch -d <feature-branch>
```

### Option 2: Push and Create PR

```bash
git push -u origin <feature-branch>
# From a detached HEAD, name the new branch on the remote:
# git push origin HEAD:refs/heads/<new-branch>
```

Then create the pull/merge request against <base-branch> with the forge's
tooling — its CLI if one is available, or the creation URL most forges
print when you push — following the repo's PR template and conventions if
present, and report the URL to the user. **REQUIRED SUB-SKILL:** Use
superpowers:writing-clearly-and-concisely for the PR description.

Keep the worktree — the user iterates on PR feedback there. Do not call
`ExitWorktree`; leaving the workspace is theirs to ask for.

### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

### If the user asks to discard the work

This path exists only as a response to an explicit request to throw the
work away. Confirm first — as plain text, **not** `AskUserQuestion`. A
single-click button is too cheap for an irreversible deletion; typing the word is
the point.

```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for that exact confirmation. When it arrives:

- Session worktree: `ExitWorktree` with `action: "remove"` and
  `discard_changes: true` — it deletes the worktree directory and its branch,
  and the flag is required because the branch carries commits the original
  branch does not have.
- Host-owned worktree or normal checkout: `cd` to the main checkout, then
  `git branch -D <feature-branch>`. Leave a host-owned worktree directory in
  place.

## Step 6: Clean Up the Workspace

**Runs for Option 1 (after a green merge) and for confirmed discards.**
Options 2 and 3 always preserve the workspace.

| Owner | Cleanup |
|-------|---------|
| Normal checkout | Nothing to clean up |
| Session worktree, work merged | `git worktree remove "$WORKTREE_PATH"` then `git worktree prune` — you already left it with `ExitWorktree` in Step 5, and its commits are now in the base branch |
| Session worktree, discarded | Already removed by `ExitWorktree` in Step 5 |
| Host-owned worktree | Leave it in place; report where it is |

Never remove a worktree you did not create. Sibling worktrees belong to other
sessions or to the user.

**If removal is refused** (`contains modified or untracked files`), the worktree
holds work that exists nowhere else. Never `--force` on your own initiative.
List what is at stake, split by kind, and ask:

```bash
git -C "$WORKTREE_PATH" status --porcelain -uall
```

```
Worktree removal refused.

Modified, not committed: <tracked file list>
Untracked: <untracked file list>

1. Commit all of it to <branch>, then clean up
2. Move the untracked files into <main checkout path> and revert the modifications
3. Discard all of it (unrecoverable)

Which?
```

Then act on the answer and remove the worktree:

- Option 1: commit the retained work, merge that additional commit into the base,
  and verify the affected behavior before removal. If it should remain separate,
  keep the branch and workspace; do not remove the only reachable copy.
- Option 2: `mv` the untracked files out, `git -C "$WORKTREE_PATH" reset --hard`,
  then `git worktree remove`.
- Option 3: this is a deletion, so it needs the typed word `discard` from Step 5
  first. Then `git worktree remove --force` is the right command.
