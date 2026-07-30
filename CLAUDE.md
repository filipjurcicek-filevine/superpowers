# Superpowers — Fork Guidelines

Retuned for **Claude Code on Opus 5 only** — CLI and VS Code extension. Nothing
here goes upstream.

Two upstreams are tracked, both pull-only:

- [obra/superpowers](https://github.com/obra/superpowers) — core methodology and
  skill content.
- [pcvelz/superpowers](https://github.com/pcvelz/superpowers) — Claude-Code-native
  mechanics upstream won't take for cross-platform reasons: hook gates, native
  task management, and live findings about Opus 5's verbosity. Take its
  session-grounded findings; leave its model-tier routing, which contradicts the
  single-model invariant below.

## Fork Invariants

These are the decisions that make this fork what it is. Do not undo them
incidentally.

**One harness.** Skills name Claude Code's tools directly: `EnterWorktree` /
`ExitWorktree`, `AskUserQuestion`, `Artifact`, `TodoWrite`, `SendMessage`,
`Workflow`, `Explore`. Do not reintroduce harness-abstraction hedging ("a tool
with a name like…"), per-harness tool-mapping references, or plugin manifests for
other harnesses — all of that has been removed, not merely disabled.

**One model, varying effort.** Subagent roles live in `agents/` as agent
definitions with `model: inherit` and a fixed `effort:` tier. Do not add
model-tier selection logic ("use the cheapest model that can…") — it produces
dispatches this fork does not want. Per-call effort is not settable through the
Agent tool; when a single dispatch needs a different tier, that is what the
`Workflow` tool is for.

**Two tiers, and the predicate for a third.** Authors and task-scoped gates run
`high`; the whole-branch gate runs `xhigh`. The distinction is breadth of
judgment, and it is the only one with a basis — an earlier four-role, three-tier
gradient was inherited from the model-tier scheme it replaced, where the tiers
tracked *price*. Effort is not a price axis, so the gradient carried no meaning
across.

A lower tier qualifies only when all three hold:

1. The work is mechanical rather than a judgment call.
2. It is high-volume or latency-sensitive enough for the saving to matter.
3. Something downstream verifies it.

**A gate never qualifies** — a gate *is* the downstream check, and one that thinks
less is one that agrees more. That disqualifies every reviewer here, including the
scoped re-reviewer: it looks narrow, but ruling on whether a defect survived
someone's attempt to fix it is subtler than reviewing fresh code.

Note where the mechanical work actually went: `task-brief`, `review-package`, and
`sdd-workspace` are shell scripts. Deterministic work belongs in code, where it
beats every effort tier at every price — which is why no agent here runs below
`high`. `medium` and `low` are for `Workflow` pipeline stages (per-item transforms
with a verify stage after them) if such a flow is ever added.

**Roles are agent definitions, not paste-in templates.** A dispatch carries
variables (file paths, constraints, findings), never the role's instructions.
Reviewer agents have no file-editing tools, so read-only review is structural
rather than instructed. Keep it that way: a constraint the agent cannot negotiate
with beats a sentence telling it not to.

**Hooks are the strongest form of that.** `pre-agent-effort-pin` and
`pre-taskupdate-user-gate` enforce what prose can only request. Rules for any hook
added here: fail open on every error path, carry a documented kill-switch env var,
match narrowly enough that a false positive is close to impossible, and ship with
a test suite that covers the fail-open paths. A hook that wedges a session is
worse than the drift it was catching.

**Native tasks are optional, the ledger is not.** `TaskCreate`/`TaskUpdate` sit
behind `CLAUDE_CODE_ENABLE_TASKS`, so the progress ledger stays the resume
mechanism and task instructions stay in one clearly-marked optional section. Do
not spread task assumptions through the skills.

**The writing style ships in-tree, and the option is a pointer.** Strunk's rules
live in `skills/writing-clearly-and-concisely/`, and six skills invoke it with
`REQUIRED SUB-SKILL` markers where they author prose. `SUPERPOWERS_WRITING_STYLE`
injects a routing pointer to that skill — never the rules themselves. Injecting the
rules would put the same text in the hook and in `SKILL.md`, two copies drifting
apart, against "say each rule once" below. Do not compress that `SKILL.md` for
token cost either; body length is measured noise.

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
cloned into `evals/` — see `docs/testing.md` for setup. quorum drives real Claude
Code sessions and judges compliance with an LLM verifier. Plugin-infrastructure
tests live in `tests/`.

**Known gap:** the Opus 5 retune has not been eval-verified. The Tier 1 changes
(worktree tooling, agent definitions) are factual repairs and safe. The
compression of discipline scaffolding is reasoned, not measured. Baseline it
before trusting it under pressure.

## Repo Conventions

- **No required runtime dependencies.** Skills use the harness's tools and the
  project's own toolchain. An *optional* external tool is allowed only when the
  skill checks for it (`command -v`), skips in one line when it is absent, and
  never asks the user to install it — `cross-reviewing-with-codex` is the one such
  skill, and the pattern it uses is the bar for any other.
- **An outside model's findings are claims.** Any skill that brings in a review
  from another model must verify each finding against the artifact or the code
  before acting on it, and must record a ruling for every finding — confirmed,
  refuted, or out of scope. Never wire in a reviewer whose output gets applied
  unverified; a second model has no access to what this project decided or why.
- Supporting files exist for reusable tools and heavy reference only. An
  unreferenced file in a skill directory is dead weight — delete it or wire it in.
- One concern per commit.
- Historical plan and spec documents under `docs/` are a record, not live
  instructions; leave them as they are even when they describe removed code.
