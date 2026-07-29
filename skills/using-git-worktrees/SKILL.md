---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from the current workspace, or before executing an implementation plan
---

# Using Git Worktrees

Ensure work happens in an isolated workspace. Claude Code owns worktree
creation through `EnterWorktree` and `ExitWorktree`; this skill decides
whether a worktree is needed and gets consent to create one.

**Core principle:** Detect existing isolation first. Then get consent. Then
use `EnterWorktree`. Never `git worktree add`.

## Step 0: Detect Existing Isolation

Before creating anything, check whether you are already isolated.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside a submodule.

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` and not a submodule:** you are already in a
linked worktree. Skip to Step 2. Do not create another one.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` or in a submodule:** you are in a normal checkout.
Continue to Step 1.

## Step 1: Get Consent, Then Enter

`EnterWorktree` may only be used when the user or the project's instructions
asked for a worktree. The consent question below is what supplies that
authorization — a yes to it is an explicit request.

If CLAUDE.md, AGENTS.md, or memory already declares a worktree preference,
honor it without asking. Otherwise ask:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

**On yes:** call `EnterWorktree` with a `name` describing the work
(`add-retry-logic`). It creates the worktree under `.claude/worktrees/`, puts
it on a new branch, and switches the session into it.

**Check the base ref before you start.** `EnterWorktree` branches from
`origin/<default-branch>` by default (the `worktree.baseRef: fresh` setting).
If this work builds on local commits that are not pushed, a fresh base
silently omits them. When the plan or the conversation depends on local
history, confirm the base is what you need before implementing — and tell the
user if it isn't, rather than working from the wrong base.

**On no:** work in place and skip to Step 2. Never fall back to
`git worktree add` — a manual worktree is state the harness cannot see,
`ExitWorktree` will not clean it up, and cleanup at finish time silently
becomes a no-op.

**Already in an `EnterWorktree` session:** you cannot create a second one.
Use the existing workspace, or pass `path` to switch into another worktree of
this repository.

### In the IDE, the editor does not follow you

`EnterWorktree` moves the session's working directory. It does not move the
editor. The VS Code workspace root stays the original checkout, which has two
consequences worth stating once:

- **File references need the worktree prefix.** A path relative to the worktree
  root (`src/auth.ts`) resolves against the *workspace* root when the user clicks
  it, opening the original, unmodified copy. Write
  `.claude/worktrees/<name>/src/auth.ts` instead — the worktree lives inside the
  workspace, so that link opens the file you actually changed.
- **The open file and selection are from the other copy.** IDE context points at
  the original checkout, not your worktree. Treat it as a pointer to *which* code
  the user means, never as the current state of the file you are editing — read
  your own copy before acting on it.

Say which workspace you are in when you report back, so the user knows whether
their editor is showing your work.

## Step 2: Project Setup

Run **this project's** documented setup, in this order of precedence:

1. **What the project says.** CLAUDE.md, AGENTS.md, README, or a `Makefile` /
   `justfile` target. A project that documents its setup is the source of truth,
   and it is the only place a private registry, a required env var, or a
   pre-install step will be written down.
2. **What the lockfile says**, when nothing is documented. The lockfile names the
   tool: `pnpm-lock.yaml` → `pnpm install`, `yarn.lock` → `yarn`,
   `package-lock.json` → `npm ci`, `uv.lock` → `uv sync`, `poetry.lock` →
   `poetry install`, `Cargo.lock` → `cargo build`, `go.sum` → `go mod download`.
3. **Ask**, when a manifest exists with no lockfile and no docs. Guessing the
   installer is how you get a second, conflicting environment — a `pip install`
   in a `uv` project resolves different versions than the project ships.

Do not run two installers for one language because two manifests exist. In a
worktree the dependency directory is usually fresh and not shared with the
original checkout, so setup does have to run — but confirm before a long install
whether the project expects a symlink or a shared store instead.

## Step 3: Verify Clean Baseline

Run the project's tests so the workspace starts from a known state
(`npm test` / `cargo test` / `pytest` / `go test ./...`).

**If tests fail:** report the failures and ask whether to proceed or
investigate. Proceeding past a dirty baseline is the user's call.

**If tests pass:** report ready.

```
Worktree ready at <full-path> on branch <name> (based on <base-ref>)
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in a linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Normal checkout, no declared preference | Ask for consent, then `EnterWorktree` |
| Preference declared in CLAUDE.md / memory | `EnterWorktree` without asking |
| Consent declined | Work in place |
| Already in an `EnterWorktree` session | Use it; `path` to switch, never a second `name` |
| Work depends on unpushed local commits | Confirm the base ref before implementing |
| Baseline tests fail | Report failures + ask |
| Setup undocumented, lockfile present | Use the lockfile's tool |
| Manifest present, no lockfile, no docs | Ask which installer |

Cleanup happens at finish time via `ExitWorktree` — see
superpowers:finishing-a-development-branch.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'm obviously not in a worktree — no need to check" | Run Step 0. Harness-created isolation and submodules both fool eyeballing; the detection commands settle it. |
| "`git worktree add` is quicker" | It creates state the harness cannot see, and it makes finish-time cleanup a silent no-op. `EnterWorktree` or work in place. |
| "The user obviously wants isolation" | `EnterWorktree` needs an explicit request. Ask, or find the declared preference. |
| "The base ref doesn't matter" | A fresh base drops unpushed local commits. Check it whenever the work builds on them. |
| "The workspace is fresh — baseline tests can wait" | A dirty baseline makes every later failure ambiguous. Run them now. |
