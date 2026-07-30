---
name: writing-clearly-and-concisely
description: Use when authoring prose a human will read — spec, plan, PR description, review summary, report, error message, UI text, docs
---

# Writing Clearly and Concisely

Six rules from Strunk's *Elements of Style*, plus the word patterns a language
model reaches for by default. These are the ones that fight the defaults; the rest
of Strunk you already follow.

## Scope

This governs prose you **author**: specs, plans, PR descriptions, review summaries,
error messages, UI text. Not conversational turns. Never rewrite a quoted string
another skill mandates — the consent question in superpowers:using-git-worktrees
and the review-gate sentence in superpowers:brainstorming are decided wording, not
drafts.

## The Six Rules

| Rule | Before → after |
|---|---|
| Use the active voice | "A retry was added by the fix" → "The fix adds a retry" |
| Put statements in positive form | "does not have any tests" → "is untested" |
| Use definite, specific, concrete language | "improves performance" → "cuts p99 latency from 400ms to 90ms" |
| Omit needless words | "in order to", "the question as to whether" → "to", "whether" |
| Keep related words together | "The hook reads the file that fails open on error" → "The hook, which fails open on error, reads the file" |
| Place the emphatic word last | "This runs at high effort, because a gate cannot think less" → "Because a gate cannot think less, this runs at high effort" |

## Do Not Write

**Puffery:** pivotal, crucial, vital, testament, enduring legacy, robust, seamless,
groundbreaking, cutting-edge.

**Empty `-ing` tails** — a clause that adds a claim instead of a fact: ensuring
reliability, showcasing X, highlighting Y, underscoring Z.

**AI vocabulary:** delve, leverage, multifaceted, foster, realm, tapestry,
landscape, navigate.

**Words that carry a condition.** The word is fine; one use of it is not.

- *case* meaning "an instance of": "in the case of a timeout" → "on timeout". "Test case" is fine.
- *character*, *nature*, *system*, *factor*, *respective* used as filler: "of a technical character" → "technical".
- *literally* propping up a metaphor.
- *interesting* as an announcement: say the thing instead.
- "one of the most" opening a paragraph.
- *very*, *certainly*, *so* as intensifiers: "so much faster" → give the number. *So* as a conjunction is fine.

## Reference

- `elements-of-style/03-elementary-principles-of-composition.md` — Strunk's full
  text on the six rules above, with his examples. Load when editing someone else's
  draft, or when a rule's boundary is unclear.

Strunk 1918 is public domain; see that file's header for provenance.
