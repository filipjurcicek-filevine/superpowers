---
name: verification-before-completion
description: Use before claiming work is complete, fixed, or passing, or preparing integration
---

# Verification Before Completion

Support each completion claim with evidence for the code and environment being
reported. A report of success is a claim until its evidence is inspected.

## Evidence contract

Record the command or check, its scope, result, and code state. For committed
work, name the revision. Include relevant uncommitted changes and environment
changes when deciding whether evidence still applies.

Reuse a recorded result when its inputs remain unchanged. A new message or a
handoff does not invalidate it. Changes to relevant source, tests, dependencies,
configuration, or runtime do. If validity is uncertain, run the affected check.

Run checks that cover the changed behavior and all required project checks.
A focused check proves only its scope; do not describe it as a full-suite pass.
Broaden testing for integration risk, failures, or a specific unresolved concern.
Once sufficient checks pass, continue toward completion.

An explicit user verification gate still requires its named command and captured
output. Do not substitute another check or waive the gate silently.

## Match the evidence to the claim

| Claim | Evidence |
|---|---|
| Tests pass | Named test command, passing result, and stated scope |
| Lint or build passes | That check's successful output; one does not prove the other |
| Bug fixed | Original reproduction now passes, with a regression check when feasible |
| Regression test detects the defect | Failure on defective behavior and success on the fix |
| Worker completed | Inspect its diff, requirements, and recorded checks |
| Requirements met | Compare the delivered behavior with acceptance criteria |

For a regression test written after the fix, demonstrate failure against the
pre-fix behavior in an isolated copy or with a reversible patch. Preserve user
changes. Existing recorded red/green evidence already satisfies this check.

Read failures and warnings. Fix regressions introduced by this work; distinguish
pre-existing failures and relevant warnings from unrelated output noise.
If a check cannot run, name the missing evidence and its effect on confidence.
Never turn an unavailable check into a passing claim.
