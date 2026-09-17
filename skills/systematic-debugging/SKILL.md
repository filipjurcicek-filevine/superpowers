---
name: systematic-debugging
description: Use when investigating a bug, failing test, or unexpected behavior before fixing it
---

# Systematic Debugging

Find evidence for the cause before changing behavior. The process can be brief
for a clear defect; uncertain or cross-component failures need deeper investigation.

## Investigate

Read the error and relevant code. Reproduce the issue or collect enough evidence
to distinguish plausible causes. Check recent changes when they can explain the
failure. Treat IDE selection as a starting point, not proof of the cause.

Trace the bad value or state to its source. At a component boundary, inspect inputs,
outputs, configuration, and state relevant to the failure. Add targeted diagnostics
when existing evidence cannot locate it. Avoid logging secrets or unrelated payloads.

Read [root-cause-tracing.md](root-cause-tracing.md) for deep call chains. Compare a
working implementation when it helps distinguish hypotheses; read enough surrounding
code to understand the relevant contract and side effects.

## Test a hypothesis

State a concrete cause and the observation that would confirm or refute it.
Run the smallest discriminating check. Keep experimental changes separate so the
result identifies which hypothesis held. Remove failed experiments before proceeding.

If the hypothesis fails, use the new evidence to revise it. Repeated failures,
new symptoms across components, or fixes that require unrelated restructuring are
reasons to reconsider the model of the system. A fixed attempt count alone does
not prove an architectural defect.

When attempts repeat without new evidence, stop the loop, summarize what is known,
and change the investigative approach. Ask when a consequential design choice or
unavailable information blocks progress. Continue independent investigations.

## Fix and verify

Use `superpowers:test-driven-development` to capture the defect when an executable
regression check is feasible. Fix the cause with a scoped change. Avoid unrelated
refactoring. Verify the original reproduction and affected behavior, then apply
`superpowers:verification-before-completion` before claiming success.

If evidence points to an environmental, timing, or external cause, document that
evidence and validate the proposed handling. An unreproduced issue remains uncertain;
it does not automatically justify retries or timeouts.

## Conditional references

- [condition-based-waiting.md](condition-based-waiting.md): replace arbitrary waits
  when readiness can be observed.
- [defense-in-depth.md](defense-in-depth.md): add justified boundary checks after
  identifying the cause.
- `find-polluter.sh`: isolate order-dependent test pollution; inspect its usage
  before running it against the project's test command.
