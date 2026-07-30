---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing any suggestion — especially if it is unclear or looks technically wrong
---

# Receiving Code Review

Review feedback is a set of technical claims. Evaluate each one against the
codebase before acting on it.

**Core principle:** verify before implementing. Ask before assuming.

## The Response Contract

1. **Read** the complete feedback.
2. **Understand** each item — restate the requirement in your own words, or ask.
3. **Verify** each item against the codebase as it actually is.
4. **Evaluate** whether it is technically sound for this codebase.
5. **Respond** with a technical acknowledgment or reasoned pushback.
   **REQUIRED SUB-SKILL:** Use superpowers:writing-clearly-and-concisely.
6. **Implement** one item at a time, testing each.

## Unclear Items Block the Whole Batch

If any item is unclear, ask about it before implementing *any* of them. Items are
often related, and partial understanding produces the wrong implementation.

```
The user: "Fix 1-6"
You understand 1, 2, 3, 6. Unclear on 4, 5.

❌ Implement 1,2,3,6 now, ask about 4,5 later
✅ "I understand items 1, 2, 3, 6. Need clarification on 4 and 5 before implementing."
```

## By Source

**From the user:** trusted. Implement once you understand it; still ask when the
scope is unclear.

**From an external reviewer:** check before implementing.

- Is it technically correct for *this* codebase?
- Does it break existing functionality?
- Is there a reason the current implementation is the way it is?
- Does it hold on every platform and version this project supports?
- Does the reviewer have the full context?

When a suggestion looks wrong, push back with technical reasoning. When you
cannot verify it, say so: "I can't verify this without [X]. Should I investigate,
ask, or proceed?" When it conflicts with a decision the user already made, raise
that before doing anything.

## YAGNI Check on "Do It Properly" Feedback

When a reviewer asks you to implement something properly, grep for its actual
usage first.

- Unused → "Nothing calls this endpoint. Remove it (YAGNI)?"
- Used → implement it properly.

## Implementation Order

1. Clarify anything unclear.
2. Blocking issues first (breakage, security).
3. Then simple fixes (typos, imports).
4. Then complex fixes (refactoring, logic).
5. Test each fix individually; verify no regressions.

## When to Push Back

Push back when the suggestion breaks existing functionality, the reviewer lacks
context, it violates YAGNI, it is wrong for this stack, legacy or compatibility
reasons exist, or it conflicts with the user's architectural decisions.

Push back with technical reasoning and specifics: reference the tests or code
that settle it, ask a precise question, and involve the user when the question is
architectural. If you pushed back and were wrong, say what you checked and what
it showed, then implement.

## Examples

**Verify before implementing:**
```
Reviewer: "Remove this legacy code"
✅ "Checked: build target is 10.15+, this API needs 13+. The legacy path is
   needed for backward compat. The current impl does have the wrong bundle ID —
   fix that, or drop pre-13 support?"
```

**YAGNI:**
```
Reviewer: "Implement proper metrics tracking with database, date filters, CSV export"
✅ "Grepped the codebase — nothing calls this endpoint. Remove it (YAGNI)? Or is
   there usage I'm missing?"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Implementing before verifying | Check against the codebase first |
| Assuming the reviewer is right | Check whether it breaks anything |
| Batching fixes without testing | One at a time, test each |
| Implementing part of an unclear batch | Clarify every item first |
| Proceeding on something you can't verify | State the limitation, ask for direction |
| Avoiding pushback | Technical correctness over comfort |

## GitHub Thread Replies

Reply to inline review comments in their thread
(`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a
top-level PR comment.
