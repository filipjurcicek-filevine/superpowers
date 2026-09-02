# Superpowers — Fork Guidelines

Tuned for **Claude Code on Opus 5 only** — CLI and VS Code extension. Nothing
here goes upstream.

This fork tracks two upstreams. Both are pull-only:

- [obra/superpowers](https://github.com/obra/superpowers) — core methodology and
  skill content.
- [pcvelz/superpowers](https://github.com/pcvelz/superpowers) — mechanics that
  are native to Claude Code. Upstream does not take them, because upstream must
  work on many harnesses. These mechanics are hook gates, native task
  management, and live findings about the verbosity of Opus 5. Take the findings
  that come from real sessions. Leave the model-tier routing. It contradicts the
  single-model rule below.

## Fixed Rules for This Fork

These decisions make the fork what it is. Do not remove them by accident.

**One harness.** Skills name the tools of Claude Code directly: `EnterWorktree` /
`ExitWorktree`, `AskUserQuestion`, `Artifact`, `TaskCreate` / `TaskUpdate`,
`SendMessage`, `Workflow`, `Explore`. Do not add vague text that hides these
names, for example "use a tool with a name like EnterWorktree". Do not add
references that map tools for each harness. Do not add plugin manifests for
other harnesses. We removed all of that. We did not only disable it.

**One model, different effort.** Subagent roles live in `agents/` as agent
definitions. Each definition sets `model: inherit` and one fixed `effort:` tier.
Do not add logic that selects a model tier, for example "use the cheapest model
that can do the work". Such logic starts agents that this fork does not want.
The Agent tool accepts a `model` value for each call. It does not accept an
`effort` value for each call. For this reason the tier must live in the
definition. The definition is the only place where a call cannot lose it without
notice. If one call really needs a different tier, use the `Workflow` tool.

**Two tiers: one for judgment, one for execution.** Planning and every gate run
`medium`. Code implementation runs `low`. Ask one question: does the role decide
something, or does it do work that someone already decided? A reviewer decides
whether the work is correct. Therefore a reviewer gets the higher tier. This
includes the scoped re-reviewer. The scoped re-reviewer looks narrow, but it
must decide whether a defect survived a fix. The implementer works from a task
brief. The brief already names the files and the code. A gate checks everything
that the implementer produces. Therefore the implementer runs `low`.

Look at where the mechanical work moved. `task-brief`, `review-package`, and
`sdd-workspace` are shell scripts. Deterministic work belongs in code. Code is
faster and cheaper than any effort tier.

**Roles are agent definitions, not templates that you paste.** A dispatch sends
variables: file paths, constraints, and findings. A dispatch never sends the
instructions of the role. Reviewer agents have no tools that edit files.
Therefore the tools make the review read-only. Text does not. Keep it this way.
A limit that the agent cannot break is better than a sentence that asks it not
to.

**Hooks give the strongest control.** `pre-agent-effort-pin` and
`pre-taskupdate-user-gate` make the rules that text can only ask for. Follow
these rules for every new hook:

- Fail open on every error path.
- Carry a kill-switch environment variable, and document it.
- Match a very narrow pattern, so a false match is almost impossible.
- Ship a test suite that covers the fail-open paths.

A hook that blocks a session is worse than the drift that it catches.

**Use native tasks to track work. Use the ledger to resume work.** Skills track
work with `TaskCreate` and `TaskUpdate`. Older text called these an optional
upgrade over `TodoWrite`, for sessions without `CLAUDE_CODE_ENABLE_TASKS`. That
fallback has no value now. When the flag is set, `TodoWrite` is not in the tool
surface. The fallback branch named a tool that nobody can call. Also, a branch
on a tool that is present or absent is the harness abstraction that the first
rule forbids.

The ledger stays the main record. It survives context summarization and a
session restart. A task list does not survive them. Also, `blockedBy` enforces
order. A task list only records what happened.

**The writing style ships in the repository. The option is only a pointer.** The
rules of Strunk live in `skills/writing-clearly-and-concisely/`. Six skills call
it with `REQUIRED SUB-SKILL` markers where they write prose.
`SUPERPOWERS_WRITING_STYLE` adds a pointer to that skill. It never adds the
rules themselves. If it added the rules, the same text would live in the hook
and in `SKILL.md`. The two copies would become different over time. This is
against the rule "Say each rule once" below. Also, do not make that `SKILL.md`
shorter to save tokens. Measurements show that the length of the body does not
change behavior.

**Say each rule once.** The upstream corpus stated key rules in four forms: a
principle, a list of prohibitions, a table of excuses, and a list of red flags.
This fork keeps one statement for each rule. It uses the form that matches the
failure mode. See `skills/writing-skills/SKILL.md`, section "Match the Form to
the Failure". When you add guidance, delete the text that it replaces.

**Do not repeat the system prompt.** Opus 5 already reports results correctly.
It does not flatter the user. It finishes what it starts. Guidance that repeats
this costs tokens. It also teaches the reader that these files repeat
themselves. Skills carry what the harness does not carry: protocols, sequences,
and the failure modes that we observed.

## Skill Changes Are Behavior Changes

Skills are not prose. They change behavior. If you change the content of a
skill:

- Use `superpowers:writing-skills` to develop and test the change.
- Micro-test the wording against a control that has no guidance. Do this before
  you write a full pressure scenario. Run 5 or more repetitions. Read every
  flagged match by hand.
- Run the pressure scenarios for the discipline skills: TDD,
  verification-before-completion, and using-superpowers. If you cut the
  scaffolding, compliance can get worse. Weeks can pass before you see it.
- Report the results before and after the change in the commit message. "Read
  better to me" is not a result.

The evals for skill behavior live in
[superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/).
Clone them to `~/Projects/superpowers-evals`. Keep them outside this repository,
because `claude plugin install` copies the whole source directory. See
`docs/testing.md` for the setup. `quorum` runs real Claude Code sessions. An LLM
verifier judges compliance. The tests for the plugin infrastructure live in
`tests/`.

**Known gap:** nobody verified the changes for Opus 5 with evals. The Tier 1
changes (worktree tooling, agent definitions) fix facts. They are safe. We
reasoned about the shorter discipline text. We did not measure it. Measure a
baseline before you trust it under pressure.

## Repo Conventions

- **No required runtime dependencies.** Skills use the tools of the harness and
  the tools of the project. An optional external tool is allowed only if the
  skill does all of these:
  - The skill checks for the tool with `command -v`.
  - The skill skips the step in one line when the tool is absent.
  - The skill never asks the user to install the tool.

  `cross-reviewing-with-cursor` is the one skill that uses an optional tool. Its
  pattern is the standard for every other skill.
- **Findings from an outside model are claims.** A skill can bring in a review
  from another model. The skill must check each finding against the artifact or
  the code before it acts. The skill must record a decision for each finding:
  confirmed, refuted, or out of scope. Never add a reviewer if the system
  applies its output without a check. A second model does not know what this
  project decided, or why.
- **Supporting files are for reusable tools and large reference material only.**
  A file in a skill directory with no reference has no use. Delete it, or link
  to it.
- **One concern per commit.**
- **Historical documents are a record.** The plan and spec documents under
  `docs/` are not live instructions. Leave them as they are, also when they
  describe code that we removed.
