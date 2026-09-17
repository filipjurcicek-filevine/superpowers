# Superpowers

Superpowers is a complete software development methodology for your coding agents, built on top of a set of composable skills and some initial instructions that make sure your agent uses them.

> **Shared prompts for Opus/Fable, Sol, and Astra-class models.** Packaging still
> targets Claude Code — the CLI and VS Code extension. This is a prompt-design
> scope, not a claim of verified model parity or a cross-harness adapter.
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

The SessionStart hook injects `using-superpowers`, which routes development work
to the appropriate skill. Read-only questions need no process ceremony.

**Design and plan.** Bounded, authorized changes proceed after relevant inspection.
Architectural work records decisions and acceptance criteria in a spec and plan.
Questions resolve consequential uncertainty; they do not repeat prior approval.
Plans describe task contracts, shared interfaces, and verification, with code only
where exact implementation detail is necessary.

**Implement and review.** Substantial independent tasks use fresh implementers and
independent reviewers. Coupled or small work can execute inline. Agent definitions
retain fixed effort defaults and inherit the selected model. Reviewers prohibit
mutation but retain Bash, so the role itself is not a filesystem sandbox.

**Resolve findings.** Controllers verify findings before fixing them and can reject
a disproved claim immediately. Confirmed blockers stay open until resolved.
Bounded fix loops stop repeated unsuccessful approaches. A ledger preserves task
state and evidence across context summarization.

**Verify and integrate.** Checks cover affected behavior and project requirements.
Valid evidence can be reused for unchanged inputs. Whole-branch review checks
integration; outside-model review is conditional on risk or an explicit request.
Integration follows the user's authorization, with ownership-aware cleanup.

See [the work plan](docs/plans/2026-09-17-streamline-capable-model-skills.md) for
this revision's scope and [validation report](docs/skill-streamlining-validation.md)
for measured results and remaining gaps.

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
0 or `cross-reviewing-with-cursor` is missing, the manifests are wrong, not the
cache.

To confirm an edit reached what runs, grep the cache for it:

```bash
grep -rl "<a phrase you just added>" ~/.claude/plugins/cache/superpowers-cc/
```

No match means bump-and-update has not taken effect yet — and it will not until
you restart Claude Code.

`claude plugin validate .` checks the manifests before you commit a change to them.

### Required setting

```json
{ "env": { "CLAUDE_CODE_ENABLE_TASKS": "1" } }
```

In `~/.claude/settings.json`. The skills track work with `TaskCreate` /
`TaskUpdate`, which this flag exposes; it also activates the user-gate hook.
Without it those tools are absent and the tracking instructions have nothing to
call. The progress ledger is the resume mechanism either way.

### Optional capabilities

| Feature | Enable | Effect |
|---|---|---|
| Writing style pointer | `SUPERPOWERS_WRITING_STYLE=1` | Adds a ~30-word pointer to `writing-clearly-and-concisely` to every session's context. Also accepts `true`, `yes`, and `on`, in any case. The skill's rules are not injected — the pointer routes to them |
| Cross-review | [Cursor Agent CLI](https://docs.cursor.com/en/cli/overview) on PATH | Spec, plan, and branch cross-review on the latest Grok model at high effort. Confirm it runs: `cursor-agent -p --output-format json --mode ask --sandbox enabled --trust "Reply OK" </dev/null` — plain text instead of JSON means bad auth or a bad model id |

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

## Cross-review (optional)

At three points — the spec, the plan, and the finished branch — a second model
reads the artifact and reports what it thinks is wrong. Every finding is then
verified against the artifact or the code, and only confirmed ones are applied;
refuted and out-of-scope findings get a recorded ruling rather than silent
deletion. A finding that objects to something the spec deliberately decided goes to
you, not into the spec.

The reviewer is the [Cursor Agent CLI](https://docs.cursor.com/en/cli/overview) on
the latest Grok model at high effort. Review requires the CLI, active paid access,
and remaining plan allowance. Missing access, a free plan, exhausted allowance,
or unknown eligibility means skip. Each call site states the reason and continues — it is an enhancement, never a
gate. See
[cross-reviewing-with-cursor](skills/cross-reviewing-with-cursor/SKILL.md).

## Native task management

`TaskCreate` / `TaskUpdate` / `TaskList` are how the skills track work:
subagent-driven-development mirrors the plan into tasks, executing-plans creates
one per plan task, and any skill with a checklist creates one per item.
`blockedBy` enforces dependency order and the task panel shows the user progress
without their reading agent output.

They require `CLAUDE_CODE_ENABLE_TASKS` — see [Required setting](#required-setting).
Enabling it also activates the user-gate hook. The progress ledger remains the
resume mechanism: it survives context summarization and session restart, which a
task list does not.

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

1. **brainstorming** resolves consequential design choices. Bounded authorized
   work proceeds directly; architectural work records a spec.
2. **using-git-worktrees** detects existing isolation, honors workspace preferences,
   checks the base, and establishes relevant baseline evidence.
3. **writing-plans** defines independently testable task outcomes, shared interfaces,
   constraints, and acceptance checks.
4. **subagent-driven-development** coordinates substantial independent tasks and
   their reviews. **executing-plans** handles coupled or small work inline.
5. **test-driven-development** establishes red/green behavioral evidence. Existing
   implementation is preserved and validated retrospectively when tests came later.
6. **requesting-code-review** obtains an independent review for substantial changes.
   Findings are checked before fixing; disproved claims can be rejected immediately.
7. **finishing-a-development-branch** verifies readiness, honors an authorized
   integration choice or asks for one, and preserves work during cleanup.

Outside-model review is conditional on risk or a user request. Explicit project
checks and user verification gates remain binding throughout the workflow.

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

**Debugging**
- **systematic-debugging** - Evidence-led root cause investigation (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration** 
- **brainstorming** - Socratic design refinement
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Inline execution for tightly coupled tasks
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Dispatching an independent reviewer
- **cross-reviewing-with-cursor** - Second-model review of a spec, plan, or branch, with every finding verified before it is applied
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

Skill-behavior tests use the quorum eval harness from [superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/), cloned to `~/Projects/superpowers-evals` — outside this checkout, because `claude plugin install` copies the source directory wholesale. It is a Bun project, so `brew install oven-sh/bun/bun && cd ~/Projects/superpowers-evals && bun install`. [docs/testing.md](docs/testing.md) has the full setup and the safety notes for live runs. Plugin-infrastructure tests live in `tests/`; each suite is a standalone script you run directly (`bash tests/hooks/test-session-start.sh`), and [docs/testing.md](docs/testing.md) lists them all. There is no `npm test` — `package.json` declares no scripts.

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
