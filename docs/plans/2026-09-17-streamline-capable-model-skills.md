# Streamline skills for capable models

## Status

Implementation, offline validation, and the approved Sol/Astra decision comparisons
are complete. Full implementation-level pressure tests and Opus/Fable runs remain unrun.
See [validation report](../skill-streamlining-validation.md) for evidence and limits.

## Goal and scope

Use one shared prompt set for Opus/Fable, Sol, and Astra-class models. Keep the
existing Claude Code tools, hooks, agent definitions, and plugin packaging.
This work does not add a Codex harness adapter or select models automatically.

The user approved both the plan and its execution on 2026-09-17. No further
design or execution-choice gate is needed. Leave unrelated workspace edits intact.

## Constraints

- Preserve user authorization, project checks, explicit verification gates,
  worktree ownership, and protection of uncommitted work.
- Preserve task briefs, review packages, bounded recovery, and progress records.
- Keep review findings subject to source verification and record material decisions.
- Change behavior deliberately; word count alone is not a quality measure.
- Leave historical plans and evaluation records unchanged.
- Keep all model evaluation artifacts outside the shipped plugin tree.

## Task 1: Capture the baseline and define validation

- [x] Save current skills and agent prompts outside the repository.
- [x] Review script interfaces and existing test suites before changing contracts.
- [x] Complete five current/revised repetitions on both Sol and Astra after payload approval.
- [x] Run five no-guidance Sol probes and freeze scenarios and scoring criteria.
- [x] Record unavailable models and execution limits without claiming a behavioral pass.

Acceptance: baseline prompts remain available; probes test decisions rather than
matching the wording of skill files. Include valid and stale test evidence,
confirmed and disproved review findings, authorized small changes, and TDD pressure.

## Task 2: Revise the shared workflow

- [x] Replace blanket clarification and approval rules with scope-sensitive decisions.
- [x] Bind verification evidence to code state and environment rather than message age.
- [x] Let controllers adjudicate findings before dispatching fixes; bound stalled loops.
- [x] Write plans as task contracts with acceptance checks and exact interfaces where needed.
- [x] Simplify TDD, debugging, review, and skill-authoring instructions without losing safeguards.
- [x] Remove repeated examples and rationalization tables that restate the contract.
- [x] Correct reviewer permission claims and keep agent output focused on findings.
- [x] Align supporting live guidance and plugin metadata with the model-class scope.

Acceptance: callers and agent roles agree about verification, stopping, review,
and handoff. Existing script parsers still accept the plan format. No unsupported
claim of structural read-only protection remains.

## Task 3: Validate and report

- [x] Review the final diff independently for lost constraints and contradictory instructions.
- [x] Run offline infrastructure suites and applicable pre-commit checks.
- [x] Check skill metadata and local reference paths.
- [x] Record behavior results, limitations, and before/after prompt sizes.
- [x] Bump both plugin version fields consistently.

Acceptance: report static checks separately from behavior evidence. Leave changes
reviewable in the checkout; do not push, publish, or alter plugin installations.
