---
name: receiving-code-review
description: Use when evaluating review feedback before changing code
---

# Receiving Code Review

Treat findings as claims. Check each against the requirements, source, and
supported environments before applying it.

For each finding, record one outcome:

- **Confirmed:** identify the defect and fix it within scope.
- **Refuted:** cite the code, test, or requirement that disproves it.
- **Out of scope:** explain the boundary and retain it for appropriate follow-up.
- **Unresolved:** name the missing evidence or decision; investigate or ask.

Agreement between reviewers does not prove a finding. A reviewer preference does
not override an approved requirement. If a confirmed defect conflicts with that
requirement, explain the conflict and obtain any needed scope decision.

An unclear item blocks only work that depends on it. Continue independent,
understood fixes while clarifying the rest. Batch related fixes when they share a
meaningful verification boundary; prioritize correctness and security defects.

Check actual use and external contracts before removing apparently unused code.
Repository search alone does not establish that a public endpoint has no consumers.

Use `superpowers:verification-before-completion` to verify fixes and report their
scope. Use `superpowers:writing-clearly-and-concisely` for human-facing responses.
Lead with findings and evidence; praise and generic recommendations are optional.
If authorized to reply on GitHub, reply to an inline comment in its own thread
(`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`).
