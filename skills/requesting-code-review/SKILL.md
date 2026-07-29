---
name: requesting-code-review
description: Use when a task or feature is complete, or before merging, to check the work against its requirements
---

# Requesting Code Review

Dispatch the `superpowers:code-reviewer` agent to review completed work.

**Why dispatch instead of reading the diff yourself:** independence. You wrote
the code, or you coordinated the agent that did, and you already believe it is
right — the same reasoning that produced the code will bless it. A reviewer with
no stake in those decisions reads what the diff actually says. Independence, not
context economy, is the reason; a fresh reader is worth the dispatch even when
your context has room to spare.

## When to Request

**Dispatch a reviewer:**
- After each task in subagent-driven development
- After completing a feature
- Before merging to main
- After a complex bug fix

**Inline self-review is enough:** a few lines, a typo, a mechanical rename, a
change you can fully verify by rereading it. Don't dispatch a reviewer for a
one-line diff.

**Worth it when stuck:** a review of work-in-progress often finds the thing you
have stopped being able to see.

## How to Request

**1. Get the range:**
```bash
BASE_SHA=$(git merge-base main HEAD)   # or the task's recorded base
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch `superpowers:code-reviewer`** with:
- what was implemented (one or two lines)
- the requirements it should satisfy — a plan file path, task text, or the spec
- the range, and a diff file if you have one (in subagent-driven development,
  `scripts/review-package` writes it; the reviewer then reads one file instead of
  re-deriving the diff)

The agent definition carries the review rubric, the severity calibration, and the
output format, and it has no file-editing tools — the review is read-only by
construction. Do not restate the rubric in your dispatch, and do not tell it what
not to flag.

**3. Act on the findings:**
- Critical: fix before anything else
- Important: fix before proceeding
- Minor: record them; triage before merge
- Wrong: push back with technical reasoning — see superpowers:receiving-code-review

**Surfacing findings to the user.** When the user asked for the review, relay the
findings — the reviewer's report goes to you, not to them. If the host renders
typed findings via `ReportFindings`, use it instead of pasting the report, and
rank by severity.

In the VS Code extension, write each location as a markdown link rather than bare
text — `[auth.ts:42](src/auth.ts#L42)`, path relative to the workspace root — so
the user can jump straight to it. The reviewer reports plain `file:line`;
converting it is your job when relaying.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll review the diff myself — I have the context for it" | Having the context is the problem: you already concluded this code is correct. Dispatch a reader who hasn't. |
| "The reviewer needs my session history to understand the change" | Hand it the requirements and the diff. Your thought process is what you want it not to inherit. |
| "It's simple, skip the review" | Task gates, features, and pre-merge get a review regardless. Size decides the reviewer's scope, not whether one happens. |
| "I'll tell the reviewer that finding would be a false positive" | That is pre-judging. Let it raise the finding and adjudicate afterward. |
