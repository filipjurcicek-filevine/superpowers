# Testing Superpowers

Two distinct kinds of tests, each in its own directory:

- **`tests/`** — does the plugin's non-LLM code work? Bash, node, and python
  tests over the hooks, the SDD workspace scripts, and the analysis utilities.
- **`evals/`** — do agents behave correctly in real sessions? A harness launching
  real Claude Code sessions, with an LLM actor and verifier judging skill
  compliance. quorum orchestrates and prices the run; **gauntlet** supplies the QA
  actor and verifier and drives the agent through **tmux**. Both are required for
  a live run — see the prerequisites below.

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
reading them — an LLM suite here, or a quorum scenario.

**Every new hook needs a test suite**, and it must cover the fail-open paths
(malformed JSON, missing transcript, unparseable input) as well as the blocking
ones. A hook that wedges a session is worse than the drift it was catching.

## Skill behavior evals

Live in `evals/`, cloned from
[superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/) and
gitignored here. The harness is **quorum** (formerly `drill`), a Bun/TypeScript
project — not Python. Each scenario is a directory under `evals/scenarios/<name>/`
holding `story.md`, `setup.sh`, and `checks.sh`; 81 ship today.

**quorum is not self-contained.** It shells out to **gauntlet**, a separate repo
that supplies the QA actor and the LLM verifier, and gauntlet drives the
agent-under-test through **tmux**. Missing either one fails a run late, after
provisioning, with an error that does not name the setup step you skipped:

| Missing | Symptom |
|---|---|
| `gauntlet` on PATH | `quorum error (unknown): Executable not found in $PATH: "gauntlet"` |
| `tmux` | `no Claude transcript appeared under isolated .../home/.claude/projects` — the real cause is `Executable not found in $PATH: "tmux"`, visible only in `<run>/gauntlet-agent/results/*/run.jsonl` |

Full setup, verified 2026-07-30 on Bun 1.3.14, gauntlet at
`prime-radiant-inc/gauntlet`, tmux 3.7b:

```bash
brew install oven-sh/bun/bun     # quorum needs >=1.3.13, gauntlet needs >=1.3.14
brew install tmux                # gauntlet's cli/tui adapter drives the SUT through tmux

git clone https://github.com/prime-radiant-inc/gauntlet.git ~/Projects/gauntlet
cd ~/Projects/gauntlet && bun install && bun link   # puts it in ~/.bun/bin
export PATH="$HOME/.bun/bin:$PATH"                  # add to your shell profile
                                                    # (or set GAUNTLET_ROOT instead)

cd <superpowers>/evals && bun install
bun run check                    # static gates: biome + tsc + bun test. No API calls.
bun run quorum check             # validates every scenario definition
```

Both `bun run check` and `quorum check` pass **without** gauntlet or tmux — they
never launch an agent. So a green static suite is not evidence that a live run
will work.

### Cost data

**obol ships no bundled rate table, so this step is not optional if you want
dollar figures.** Without it every model reads as unpriced and every run reports
`est_cost_usd: null` — which looks like "this model is too new to be priced" and
is actually "no pricing table exists on this machine". quorum never refreshes on
your behalf.

```bash
cd evals
bun -e 'const{refresh}=await import("@primeradianthq/obol");
        console.log(JSON.stringify(await refresh(new Date().toISOString().slice(0,10))))'
# → {"models":2546,"as_of":"...","written_to":"~/.local/share/obol/current.json"}
```

obol reads that path by default; `OBOL_PRICING_DIR` overrides it. The table is
machine-local, not part of either repo, and `pricing_as_of` freezes at the refresh
date — so re-run it when rates change or a new model appears. Under Bun, set
`OBOL_PRICING_DIR` before launching the process: a runtime `process.env` write
does not reach obol's FFI (use its `setPricingDir` helper instead).

A model with no row is reported in `unpriced_models` with its tokens preserved,
so absent pricing degrades the dollar column without corrupting token counts.

Rates after a 2026-07-30 refresh, per MTok:

| Credential | Model | Input | Output | Cache read | Cache write |
|---|---|---|---|---|---|
| `opus5` | `claude-opus-5` | $5.00 | $25.00 | $0.50 | $6.25 |
| `opus` | `claude-opus-4-8` | $5.00 | $25.00 | $0.50 | $6.25 |

Identical, so opus5-vs-opus comparisons are directly readable as a behavior
delta rather than a price delta. Verified on obol 0.8.0 with a synthetic ATIF
trajectory: 1M input + 1M output priced at `total_usd` 30, `unpriced_models` `[]`.

**The terminal table cannot tell the two apart.** `shortModel` in
`src/cli/render.ts` collapses any id containing "opus" to `opus`, so a
`claude-opus-5` run and a `claude-opus-4-8` run both print a row labelled `opus`.
Read `verdict.json` → `coding_agent.model` for the id that actually ran; the
session log under `<run>/home/.claude/projects/**/*.jsonl` is the independent
confirmation.

### Running a scenario

`bun run check` and `quorum check` are safe and offline. Running a scenario is
not:

```bash
export SUPERPOWERS_ROOT=/path/to/superpowers
export ANTHROPIC_API_KEY=...
bun run quorum run scenarios/triggering-writing-plans --coding-agent claude
bun run quorum show <run-dir>
```

**A live scenario launches Claude Code with `--dangerously-skip-permissions`.**
quorum pins the agent's `HOME` and XDG dirs to a throwaway per-run home so it
never sees your real `~/.claude`, but that narrows the blast radius rather than
sandboxing it. Run these only locally, with only the one API key the run needs in
the environment, and treat `evals/results/` as sensitive. See `evals/README.md`,
"Safety Model".

Scenarios are slow (3-30+ minutes each) and cost real tokens, so they are not in
CI. They are the only thing that tells you whether a skill edit changed behavior
in the direction you intended — see `CLAUDE.md`, "Skill Changes Are Behavior
Changes".

**Acceptance criteria assert tool calls, not prose.** A triggering scenario looks
for a `Skill` invocation in the session log, not for an announcement string. So
rewording a skill's prose does not move these evals; changing whether an agent
loads the skill does.

## Measuring what prompt text costs

`scripts/analyze-prompt-cost.py <results-dir>` sizes the injected context across
finished runs — always-on payloads, per-skill bodies, turns, peak context, tool
mix, and redundancy. It groups by arm (fork / upstream / baseline, inferred from
each run's skill base directory), so an A/B reads directly off it. `--json` for
machine consumption, `--turns N` to change the re-read multiplier.

```bash
python3 scripts/analyze-prompt-cost.py evals/results --glob 'tdd-holds-*'
```

Read it with two facts in mind, both of which produced a wrong answer first time:

- **Cost is context size multiplied by turn count.** A `description` character is
  in context from turn 1 of every session; a SKILL.md body character only after
  invocation. On a ~25-turn run that makes description text worth roughly 25x body
  text, which is why compressing bodies for cost is a waste (see
  `skills/writing-skills/SKILL.md`, Progressive Disclosure).
- **`prompt_tokens` reads as ~2** in these transcripts because nearly everything
  is cached. Context size lives in `cache_read_input_tokens +
  cache_creation_input_tokens`. Optimising off `prompt_tokens` concludes the
  prompts are free.

Measured this way on a fork-vs-upstream A/B, the always-on total splits into three
movable parts — and the fork's biggest win is not where prose review would look:

| Source | fork | upstream |
|---|---|---|
| skill listing (all installed descriptions) | 6,688 ch | 6,879 ch |
| SessionStart bootstrap (`using-superpowers`) | 2,026 ch | 3,276 ch |
| agent listing (this fork adds 4 definitions) | 3,327 ch | 2,304 ch |

The bootstrap compression saves ~1,250 characters; the four effort-pinned agent
definitions cost ~1,023 back. Net ~−418 ch (~−104 tok, ~2,600 token-reads/run).
That agent-listing cost is the previously-unpriced side of the roles-as-agent-
definitions decision — worth knowing, not necessarily worth reversing.

Tests: `tests/prompt-cost/test-analyze-prompt-cost.sh` (synthetic fixtures with
known-correct answers; no API calls).

Related: `tests/claude-code/analyze-token-usage.py` attributes tokens to
individual subagents inside one transcript. Different question, no overlap.

## Baseline records

`docs/skill-tests/<skill-name>/` holds the RED-phase transcripts and pressure
scenarios recorded while a skill was developed. Not runnable, not shipped in the
plugin — a record of what the baseline behavior was. See
`docs/skill-tests/README.md`.
