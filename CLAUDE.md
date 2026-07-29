# Superpowers — Fork Guidelines

This is a fork of [obra/superpowers](https://github.com/obra/superpowers),
retuned for **Claude Code on Opus 5 only**. Nothing here goes upstream.

## Fork Invariants

These are the decisions that make this fork what it is. Do not undo them
incidentally.

**One harness.** Skills name Claude Code's tools directly: `EnterWorktree` /
`ExitWorktree`, `AskUserQuestion`, `Artifact`, `TodoWrite`, `SendMessage`,
`Workflow`, `Explore`. Do not reintroduce harness-abstraction hedging ("a tool
with a name like…") or per-harness tool-mapping references. The multi-harness
scaffolding still in `.codex-plugin/`, `.cursor-plugin/`, `.kimi-plugin/`,
`.opencode/`, and `.pi/` is inert; the skills do not adapt to it.

**One model, varying effort.** Subagent roles live in `agents/` as agent
definitions with `model: inherit` and a fixed `effort:` tier. Do not add
model-tier selection logic ("use the cheapest model that can…") — it produces
dispatches this fork does not want. Per-call effort is not settable through the
Agent tool; when a single dispatch needs a different tier, that is what the
`Workflow` tool is for.

**Roles are agent definitions, not paste-in templates.** A dispatch carries
variables (file paths, constraints, findings), never the role's instructions.
Reviewer agents have no file-editing tools, so read-only review is structural
rather than instructed. Keep it that way: a constraint the agent cannot negotiate
with beats a sentence telling it not to.

**Say each rule once.** The upstream corpus stated key rules four ways — a
principle, a prohibition list, a rationalization table, and a red-flags list.
This fork keeps one statement per rule, in the form that matches its failure mode
(see `skills/writing-skills/SKILL.md`, "Match the Form to the Failure"). When you
add guidance, delete the copy it replaces.

**Don't restate the system prompt.** Opus 5 already reports outcomes faithfully,
avoids sycophancy, and finishes what it starts. Guidance that duplicates that
costs tokens and teaches the reader that these files repeat themselves. Skills
carry what the harness does not: protocols, sequences, and the failure modes we
have actually observed.

## Skill Changes Are Behavior Changes

Skills are not prose — they shape behavior. If you modify skill content:

- Use `superpowers:writing-skills` to develop and test the change.
- Micro-test wording against a no-guidance control before writing a full pressure
  scenario: 5+ reps, and read every flagged match by hand.
- For discipline skills (TDD, verification-before-completion, using-superpowers),
  run the pressure scenarios. Cutting scaffolding can regress compliance in ways
  that take weeks to notice.
- Report before/after results in the commit message. "Read better to me" is not a
  result.

Skill-behavior evals live in
[superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/),
cloned into `evals/` — see `evals/README.md` for setup. Drill drives real Claude
Code sessions and judges compliance with an LLM verifier. Plugin-infrastructure
tests live in `tests/`.

**Known gap:** the Opus 5 retune has not been eval-verified. The Tier 1 changes
(worktree tooling, agent definitions) are factual repairs and safe. The
compression of discipline scaffolding is reasoned, not measured. Baseline it
before trusting it under pressure.

## Repo Conventions

- Zero runtime dependencies. Skills use the harness's tools and the project's own
  toolchain, nothing else.
- Supporting files exist for reusable tools and heavy reference only. An
  unreferenced file in a skill directory is dead weight — delete it or wire it in.
- One concern per commit.
- Historical plan and spec documents under `docs/` are a record, not live
  instructions; leave them as they are even when they describe removed code.
