---
name: test-driven-development
description: Use when implementing new behavior or fixing a defect with an executable regression check
---

# Test-Driven Development

Use a failing behavioral test to establish what the implementation must change.
A passing test alone does not show that it detects a missing behavior or defect.

## Red, green, refactor

1. Choose an observable behavior and the smallest check that distinguishes correct
   from incorrect behavior. Read [writing-good-tests.md](writing-good-tests.md)
   when designing or changing tests.
2. Run the check before the implementation change. Confirm the failure reflects
   the missing behavior, rather than a broken test setup.
3. Implement the behavior within scope and run the check again.
4. Refactor as needed while keeping the relevant checks green.

Record the red and green commands and results. Use
`superpowers:verification-before-completion` to choose broader checks and report
what the evidence proves. Preserve explicit project requirements for TDD or test scope.

## Test behavior

Assert outputs, state transitions, or externally relevant interactions. A helper
function does not need its own test when existing behavior tests cover it.
Use mocks for costly or inaccessible boundaries; assertions must still detect a
production defect, not merely confirm the configured mock response.

Cover meaningful edge cases and failures. Keep test-only helpers out of production
interfaces. When a test is difficult to write, inspect the interface and fixtures
before adding more mocks or asking the user.

## Existing code and exceptions

If implementation preceded the test, preserve the work. Add a regression test and
show it fails against the defective or pre-feature behavior in an isolated copy
or with a reversible patch. Restore the implementation and verify green. Report
this as retrospective regression validation, not test-first development.

For documentation, generated output, configuration-only changes, and disposable
probes, use an appropriate check rather than manufacturing a behavioral unit test.
Configuration that changes runtime behavior still needs a meaningful validation.
If a user or project requires an exception to be approved, obtain that approval.

Time pressure does not justify claiming unrun tests passed. If reproduction or
execution is unavailable, state the missing evidence, attempt a bounded alternative,
and report the limitation. Do not silently mark required verification complete.
