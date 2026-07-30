# Superpowers

Superpowers is a complete software development methodology for your coding agents, built on top of a set of composable skills and some initial instructions that make sure your agent uses them.

> **This fork targets Claude Code on Opus 5 only** — the CLI and the VS Code
> extension. Nothing here is written to degrade gracefully on another harness or
> another model.
>
> **Optimized for Claude Code.** Every skill names Claude Code's own tools rather
> than describing them abstractly: `EnterWorktree` / `ExitWorktree` for isolation,
> `AskUserQuestion` for design questions, `Artifact` for mockups and diagrams,
> `Explore` and `Workflow` for fan-out, `SendMessage` to resume a subagent.
> Subagent roles are agent definitions in [`agents/`](agents/) with pinned
> reasoning-effort tiers instead of model tiers, since one model runs everything.
> Two `PreToolUse` [hooks](hooks/) make rules structural rather than advisory. In
> the extension, findings are relayed as clickable workspace-relative links, and
> the open file and selection are treated as context.
>
> **Upstreams tracked.** Both are pulled from and neither is pushed to:
>
> | Upstream | What we take |
> |---|---|
> | [obra/superpowers](https://github.com/obra/superpowers) | The core methodology and skill content — brainstorm → spec → plan → subagent execution → review. |
> | [pcvelz/superpowers](https://github.com/pcvelz/superpowers) | Claude-Code-native mechanics that fall outside upstream's cross-platform scope: hook-based gates, native task management, and hard-won findings about Opus 5's verbosity in ledgers and fix reports. |
>
> Local changes are deliberately not upstreamable to either.

## Quickstart

```bash
git clone https://github.com/filipjurcicek-filevine/superpowers.git ~/Projects/superpowers
claude plugin marketplace add ~/Projects/superpowers
claude plugin install superpowers@superpowers-cc
```

Restart Claude Code — CLI or VS Code extension, same install. Full detail,
including how to pick up your own edits, under [Installation](#installation).

## How it works

The SessionStart hook inlines the `using-superpowers` bootstrap into every
session, so when a turn is about to write code the agent invokes a skill before
acting instead of starting to type. From there the work runs through four
approval gates, and the gates are the point — each one is a place the process
stops for you rather than guessing.

**Brainstorm → spec.** Instead of jumping to code, the agent asks what you are
actually building, proposes two or three approaches with real trade-offs, and
presents the design in sections short enough to read. The spec is written to
`docs/superpowers/specs/`, self-reviewed, and — if the Codex CLI is on PATH —
cross-reviewed by a second model before you see it. *Gate 1: you approve the
spec.*

**Spec → plan.** The plan is written for an engineer with no project context and
an aversion to testing: exact file paths, real code in every step, red/green TDD,
YAGNI, DRY. Codex then checks the plan against the spec, whose highest-value
finding is a requirement no task implements. *Gate 2: you approve the plan and
pick how to execute it.*

**Plan → implementation.** Subagent-driven development dispatches a fresh
implementer per task and an independent reviewer after each one, on pinned
effort tiers, with reviewers that have no file-editing tools. A five-round fix
loop with a circuit breaker handles findings; a ledger on disk survives context
summarization, so a long run resumes instead of re-doing finished work. *Gate 3:
the loop stops for you on a plan contradiction or a load-bearing finding it
cannot resolve.*

**Implementation → integration.** A whole-branch review at `xhigh` effort, plus a
Codex branch review, then one fix wave. *Gate 4: you choose merge, PR, or keep.*

Every finding from an outside model is a claim until it is checked against the
artifact, and every ruling gets recorded — confirmed, refuted, or out of scope.
Nothing a second model says is applied unverified.

## Installation

**This fork is not on any public marketplace.** Installing `superpowers` from the
official or `obra/superpowers-marketplace` marketplaces gets you upstream, not this.
Install it from a checkout instead.

Every command below is a `claude` CLI invocation; the `/plugin ...` slash-command
equivalents work identically inside a session. Both the CLI and the VS Code
extension read the same plugin config, so you install once.

### 1. Get a checkout

Either a standalone clone:

```bash
git clone https://github.com/filipjurcicek-filevine/superpowers.git ~/Projects/superpowers
```

Or pinned as a submodule, which is how this workspace does it — the pinned commit
becomes part of the parent repo's history:

```bash
git submodule add https://github.com/filipjurcicek-filevine/superpowers.git superpowers
```

### 2. Register it as a directory marketplace and install

```bash
claude plugin marketplace add ~/Projects/superpowers    # or ./superpowers
claude plugin install superpowers@superpowers-cc
```

The marketplace name is `superpowers-cc`, from
[`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). Add
`--scope project` or `--scope local` to `install` to scope it to one repo instead
of your user account (default is `user`).

**Restart Claude Code.** Plugin changes apply on restart.

### 3. Remove upstream Superpowers if you have it

Both publish skills under the `superpowers:` namespace, so running both means two
`superpowers:brainstorming` skills and no way to tell which one answered:

```bash
claude plugin list                                       # see what is installed
claude plugin uninstall superpowers@claude-plugins-official
```

### Updating, after your own edits or a pull

Nothing here auto-updates. This fork installs from a local checkout, so both
paths are the same: get the commits (`git pull`, or your own edit), then
bump-and-update.

**Editing the working tree changes nothing on its own.** The plugin runs from a
version-keyed cache under `~/.claude/plugins/cache/superpowers-cc/`, and
`claude plugin update` compares versions — with the version unchanged it reports
"already at the latest version" and keeps serving the old copy. Verified: a probe
line added to a tracked file did not reach the cache until the version moved.

So bump the version, then update:

```bash
scripts/bump-version.sh <next-version>    # writes package.json + both manifests
claude plugin marketplace update superpowers-cc
claude plugin update superpowers@superpowers-cc
# then restart Claude Code
```

`--check` prints the current version if you need to know what to increment from.

Version convention for this fork: `<upstream-version>-cc.<N>`, so `6.2.1-cc.2`
reads as "based on upstream 6.2.1, fork revision 2". `bump-version.sh --check`
reports drift; `--audit` greps the repo for stragglers.

**`-cc.N` is a semver prerelease, so it sorts *below* the upstream release it
names.** `6.2.1-cc.2` precedes `6.2.1`. That is harmless here because the only
comparison that ever happens is fork-to-fork — one marketplace, one plugin, and
successive `-cc.N` bumps do order correctly. Do not read the version as "ahead of
upstream", and do not install this alongside upstream and expect this one to win
(see step 3 above, which tells you to remove upstream).

### Verify what is actually live

**The two commands disagree, and only one of them answers this question.**

```bash
claude plugin list      # the INSTALLED version — this is what your sessions run
claude plugin details superpowers@superpowers-cc   # reads the marketplace manifest
```

`details` reports the version in `.claude-plugin/marketplace.json`, which for a
directory marketplace is your working tree. Bump the version and it says the new
one immediately — before any cache has been updated and before any session sees
the change. Measured: with the working tree at `6.2.1-cc.2` and the plugin not yet
updated, `details` printed `6.2.1-cc.2` while `list` printed `6.2.1-cc.1`, and the
edits were absent from `~/.claude/plugins/cache/superpowers-cc/`. Trust `list`.

`details` is still the right tool for the **component inventory**, which does come
from the manifest and the tree. This fork should show **16 skills**, **4 agents**
(`code-reviewer`, `sdd-implementer`, `sdd-task-reviewer`, `sdd-re-reviewer`), and
**2 hooks** (SessionStart, PreToolUse — two events, three scripts). If `agents` is
0 or `cross-reviewing-with-codex` is missing, the manifests are wrong, not the
cache.

To confirm an edit reached what runs, grep the cache for it:

```bash
grep -rl "<a phrase you just added>" ~/.claude/plugins/cache/superpowers-cc/
```

No match means bump-and-update has not taken effect yet — and it will not until
you restart Claude Code.

`claude plugin validate .` checks the manifests before you commit a change to them.

### Optional capabilities

| Feature | Enable | Effect |
|---|---|---|
| Native task management | `CLAUDE_CODE_ENABLE_TASKS=1` | `blockedBy` dependency enforcement and a live task panel; activates the user-gate hook |
| Writing style pointer | `SUPERPOWERS_WRITING_STYLE=1` | Adds a ~30-word pointer to `writing-clearly-and-concisely` to every session's context. Also accepts `true`, `yes`, and `on`, in any case. The skill's rules are not injected — the pointer routes to them |
| Codex cross-review | [Codex CLI](https://github.com/openai/codex) on PATH | Spec, plan, and branch cross-review. Confirm it runs: `codex exec -s read-only -o /tmp/m "Reply OK" </dev/null` — a 400 about the model means the configured default is unusable, so pin one with `-c model=<name>` |

### Other harnesses

Not supported. Upstream ships integrations for Antigravity, Codex, Cursor,
Factory Droid, Gemini CLI, Copilot CLI, Kimi Code, OpenCode, and Pi; this fork
has removed all of them — the plugin manifests, the tool-mapping references, the
per-harness docs, and their tests. The skills name Claude Code's tools directly.
Install [upstream](https://github.com/obra/superpowers) for those harnesses.

## Hooks

Three hooks ship registered in [`hooks/hooks.json`](hooks/hooks.json), across two
events — which is why `claude plugin details` reports "Hooks (2)". All of them
fail open on any error.

### SessionStart — the one that makes the rest fire

[`hooks/session-start`](hooks/session-start) inlines
`skills/using-superpowers/SKILL.md` into every session's context as a
`<superpowers-bootstrap>` block, on `startup`, `clear`, and `compact`. That
bootstrap is what tells the agent to invoke a skill before acting; without it the
other fifteen skills are installed but nothing routes to them. It has no kill
switch because disabling it disables the library.

Two consequences worth knowing:

- **`using-superpowers` is the only skill whose full text is always resident.**
  Everything it says is paid for in every session — which is why it is the
  shortest skill in the library and should stay that way.
- **Editing `using-superpowers` changes every session, not just the ones that
  invoke it.** Re-check the always-on token cost in `claude plugin details` after
  any edit to it.

With `SUPERPOWERS_WRITING_STYLE` enabled, a second block follows the bootstrap: a
~30-word pointer to `writing-clearly-and-concisely`. The pointer is a constant in
the hook, not a file read, and the skill's **body is not resident** — so
`using-superpowers` remains the only skill whose full text is always in context,
and the warning above still names one file.

### PreToolUse — two gates

Both match narrowly, fail open, and carry a kill switch.

| Hook | Fires on | Blocks | Disable |
|---|---|---|---|
| [`pre-agent-effort-pin`](hooks/pre-agent-effort-pin) | `Agent` | A subagent-driven-development dispatch (its prompt carries a `.superpowers/sdd/` artifact path) that names no effort-pinned agent type — it would run at session effort, with no role contract and full write tools, so a reviewer could edit the code under review. | `SUPERPOWERS_EFFORT_GUARD=0` |
| [`pre-taskupdate-user-gate`](hooks/pre-taskupdate-user-gate) | `TaskUpdate` | Closing a task marked `"userGate": true` whose `verifyCommand` never ran in the session. Catches gates closed by declaring them verified inline. **Dormant** unless native tasks are enabled. | `SUPERPOWERS_USERGATE_GUARD=0` |

## Codex cross-review (optional)

At three points — the spec, the plan, and the finished branch — a second model
reads the artifact and reports what it thinks is wrong. Every finding is then
verified against the artifact or the code, and only confirmed ones are applied;
refuted and out-of-scope findings get a recorded ruling rather than silent
deletion. A finding that objects to something the spec deliberately decided goes to
you, not into the spec.

Requires the [Codex CLI](https://github.com/openai/codex) on PATH. Without it, each
call site says so in one line and continues — it is an enhancement, never a gate.
See [cross-reviewing-with-codex](skills/cross-reviewing-with-codex/SKILL.md).

## Native task management (optional)

`TaskCreate` / `TaskUpdate` / `TaskList` give dependency enforcement via
`blockedBy` and a live task view in the IDE. They sit behind
`CLAUDE_CODE_ENABLE_TASKS`, so they are off by default. With them enabled,
subagent-driven-development mirrors the plan into tasks and the user-gate hook
becomes active; the progress ledger stays the resume mechanism either way.

## Writing style (optional)

`skills/writing-clearly-and-concisely/` carries six rules from Strunk's *Elements
of Style* and the word patterns a language model reaches for by default. Six skills
invoke it where they author prose a human reads: the spec, the plan, the PR
description, skill prose, the findings relay, and the review response.

`SUPERPOWERS_WRITING_STYLE=1` additionally puts a routing pointer in every
session, for prose written outside those six flows. It injects the pointer, not the
rules — the rules stay in the skill body, so no rule is stated twice and nothing is
resident that a session might never use. An agent that ignores the pointer gets no
style guidance; the six call sites, not the option, are what make this reliable.

`ai-writing-tells.md` is adapted from Wikipedia's "Signs of AI writing" and is
licensed **CC BY-SA 4.0**, not MIT. Its header carries the attribution and change
notice. One file under a different license does not relicense this package.

## The Basic Workflow

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Saves a design document, cross-reviewed by Codex before you read it.

2. **using-git-worktrees** - Activates after design approval. Creates isolated workspace on new branch, runs project setup, verifies clean test baseline.

3. **writing-plans** - Activates with approved design. Breaks work into bite-sized tasks (2-5 minutes each). Every task has exact file paths, complete code, verification steps. Cross-reviewed against the spec, so a requirement with no task surfaces before execution starts.

4. **subagent-driven-development** or **executing-plans** - Activates with plan. Dispatches a fresh implementer per task, each gated by an independent review of spec compliance and code quality — or, when tasks are tightly coupled, executes them inline in this session.

5. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.

6. **requesting-code-review** - Activates between tasks. Reviews against plan, reports issues by severity. Critical issues block progress.

7. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, asks how to integrate (merge / PR / keep), cleans up the worktree it created.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

**Debugging**
- **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration** 
- **brainstorming** - Socratic design refinement
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Inline execution for tightly coupled tasks
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Dispatching an independent reviewer
- **cross-reviewing-with-codex** - Second-model review of a spec, plan, or branch, with every finding verified before it is applied
- **receiving-code-review** - Responding to feedback
- **using-git-worktrees** - Parallel development branches
- **finishing-a-development-branch** - Merge/PR decision workflow
- **subagent-driven-development** - Fresh implementer per task, independent review after each, whole-branch review at the end

**Meta**
- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **using-superpowers** - Introduction to the skills system

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

## Contributing

This is a single-harness fork; changes here are not sent upstream. Contribute portable improvements to [upstream](https://github.com/obra/superpowers) instead. Within this fork, treat skill edits as behavior changes: follow the `writing-skills` skill, and measure before and after rather than assuming a rewording is an improvement.

Skill-behavior tests use the quorum eval harness from [superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/), cloned into `evals/` — a Bun project, so `brew install oven-sh/bun/bun && cd evals && bun install`. [docs/testing.md](docs/testing.md) has the full setup and the safety notes for live runs. Plugin-infrastructure tests live in `tests/`; each suite is a standalone script you run directly (`bash tests/hooks/test-session-start.sh`), and [docs/testing.md](docs/testing.md) lists them all. There is no `npm test` — `package.json` declares no scripts.

See `skills/writing-skills/SKILL.md` for the complete guide.

## License

MIT License - see LICENSE file for details

## Telemetry

None. Upstream's only phone-home was the logo on brainstorming's visual
companion; this fork removed the companion, so nothing here contacts a network
service.

## Credits

Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of
the folks at [Prime Radiant](https://primeradiant.com). This is a private
Claude-Code-only fork of their work; the MIT copyright in
[LICENSE](LICENSE) is theirs. Read
[the original release announcement](https://blog.fsck.com/2025/10/09/superpowers/)
for the methodology's own account of itself.

**Where to report what:**

| Issue | Where |
|---|---|
| Something in this fork — a skill, a hook, the retune | This repo's issues |
| Something that reproduces on upstream too | [obra/superpowers](https://github.com/obra/superpowers/issues), where it can be fixed for everyone |
| Questions about the upstream methodology | Upstream's [Discord](https://discord.gg/35wsABTejz) |

Do not file fork-specific bugs upstream. None of the changes here are
upstreamable, so an issue about them has no fix path there.
