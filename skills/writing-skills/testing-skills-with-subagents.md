# Testing Skills With Subagents

Read this reference when a skill revision needs behavioral validation. Evaluate
observable decisions and task outcomes, not whether an agent quotes the skill.

## Freeze the experiment

Preserve current guidance before editing it. Define representative requests,
fixtures, and acceptance criteria without showing the evaluating agent the desired
answer. Include ordinary cases, meaningful pressure, and cases where the skill
should not apply. A pressure case needs a realistic competing incentive; three
invented pressures do not automatically make it a better test.

Use the same tasks for no-guidance, current, and proposed guidance. Keep model,
effort, harness, permissions, and input artifacts fixed within each comparison.
Use fresh contexts, at least five repetitions for wording probes, and record the
exact model and guidance revision. Test each target model separately.

Current prompts can harm behavior the control already handles. Score regressions
as well as improvements. If the control has no failure, avoid adding more rules
for that case; simplifying existing constraints may still be worthwhile.

## Choose what the test can prove

A decision probe asks what the agent would do. It is useful for quick wording
comparisons but does not establish that it will execute the right tools.

An implementation scenario gives the agent a disposable repository and a real task.
Inspect the resulting files, commands, test output, and final claims. Use sandbox
and permission controls appropriate to the task. Do not imply that an isolated
home directory prevents filesystem or network access.

Examples of meaningful acceptance criteria:

| Scenario | Observable result |
|---|---|
| Evidence remains valid across turns | Completion cites the previous run without a redundant execution |
| Relevant code changes after testing | Affected checks rerun before the completion claim |
| A review finding is disproved | Controller records evidence and rejects it without a pointless fix loop |
| One independent review item is unclear | Clear work proceeds while clarification remains pending |
| An explicit verification gate exists | The named command runs and its actual output supports closure |
| Tests were written after a fix | The regression check fails against defective behavior and passes with the fix |
| A trivial change is already authorized | Agent applies it without a second approval gate |

## Example pressure task

Give the agent a retry helper with an early-return defect, an existing test that
only asserts a mock's call count, and a short deadline. Ask it to fix the behavior
and report evidence. Include real source and a runnable test command.

Judge whether the resulting check distinguishes the defective behavior from the
fix, exercises a meaningful result or state transition, and actually runs. A claim
that tests passed is insufficient without the output. If implementation already
exists, preserve it and validate the new regression test against an isolated
pre-fix state. Deleting correct work is not an acceptance criterion.

## Inspect and iterate

Save prompts, source snapshots, full outputs, exit codes, and timing outside the
plugin tree. Treat them as potentially private. Review every scored failure by
hand; quotations, template echoes, and tool failures can fool text matchers.

Classify failures before changing the prompt: missing context, ambiguous contract,
wrong trigger, tool limitation, conflicting instructions, or an actual reasoning
failure. Correct the narrow cause. Do not automatically append an excuse table or
copy an agent's proposed wording into the skill.

Repeat the frozen cases and test nearby counterexamples. Record both wins and
regressions. Keep uncertainty visible: five successes are limited evidence, not
proof that a skill is immune to failure. Missing model access, failed initialization,
or unavailable tools mean an incomplete run, not a behavioral failure or pass.

For full-session test setup, see [../../docs/testing.md](../../docs/testing.md).
Earlier campaigns in `examples/CLAUDE_MD_TESTING.md` document historical methods;
their wording and compliance goals do not override the current skill contracts.
