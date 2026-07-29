# Testing Superpowers

Two distinct kinds of tests, each in its own directory:

- **`tests/`** — does the plugin's non-LLM code work? Bash, node, and python
  tests over the hooks, the SDD workspace scripts, and the analysis utilities.
- **`evals/`** — do agents behave correctly in real sessions? A harness driving
  real tmux sessions of Claude Code, with an LLM actor and verifier judging skill
  compliance.

## Plugin tests

Live in `tests/`. Every suite here runs offline and in seconds:

- `tests/hooks/test-session-start.sh` — SessionStart injects the bootstrap in
  Claude Code's payload shape.
- `tests/hooks/test-pre-agent-effort-pin.sh` — the Agent gate blocks SDD
  dispatches that name no effort-pinned agent type, and fails open otherwise.
- `tests/hooks/test-pre-taskupdate-user-gate.sh` — the TaskUpdate gate blocks
  closing a `userGate` task whose `verifyCommand` never ran, and fails open
  otherwise.
- `tests/claude-code/test-sdd-workspace.sh` — `sdd-workspace`, `task-brief`, and
  `review-package` resolve per-plan directories and stay invisible to git.
- `tests/systematic-debugging/test-find-polluter.sh` — `find-polluter.sh` pattern
  matching.
- `tests/shell-lint/test-lint-shell.sh` — the lint wrapper itself (needs
  `shellcheck` and `shfmt` on PATH to lint for real).

Slower, LLM-driven suites that are not part of a normal run:

- `tests/claude-code/test-subagent-driven-development-integration.sh` — executes a
  real plan end to end (10-30 minutes, spawns Claude Code sessions).
- `tests/claude-code/test-worktree-native-preference.sh` — RED/GREEN/PRESSURE
  baselines for whether the agent reaches for `EnterWorktree` or invents
  `git worktree add` back. Phases run against different installed skill versions,
  so the operator switches them; its recorded numbers predate the Opus 5 retune.
- `tests/explicit-skill-requests/` — multi-turn and skill-name-prompted tests.

Run a suite directly with `bash tests/<dir>/<test>.sh`.

**No grep-the-skill tests.** A test asserting that a skill file contains an exact
line proves only that the source is the source: it fires on every intentional
rewrite and sleeps through behavior regressions. `writing-good-tests.md` rules
this out, and a policy test that asserted the old `.worktrees/` wording was
deleted for exactly this reason. Skills are tested by the behavior of the agent
reading them — an LLM suite here, or a drill scenario.

**Every new hook needs a test suite**, and it must cover the fail-open paths
(malformed JSON, missing transcript, unparseable input) as well as the blocking
ones. A hook that wedges a session is worse than the drift it was catching.

## Skill behavior evals

Live in `evals/`, cloned from
[superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/).
Scenarios live at `evals/scenarios/*.yaml`. See `evals/README.md` for setup.

```bash
cd evals
uv sync --extra dev
export ANTHROPIC_API_KEY=sk-...
uv run drill run triggering-test-driven-development -b claude
```

Scenarios are slow (3-30+ minutes each) and run real sessions, so they are not in
CI. They are the only thing that tells you whether a skill edit changed behavior
in the direction you intended — see `CLAUDE.md`, "Skill Changes Are Behavior
Changes".

## Baseline records

`docs/skill-tests/<skill-name>/` holds the RED-phase transcripts and pressure
scenarios recorded while a skill was developed. Not runnable, not shipped in the
plugin — a record of what the baseline behavior was. See
`docs/skill-tests/README.md`.
