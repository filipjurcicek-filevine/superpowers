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

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do. 

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest. 

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY. 

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for your agent to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers.

## Commercial Services

If you're using Superpowers in enterprise and could benefit from commercial support, additional tooling, or managed spending, please don't hesitate to drop us a line at sales@primeradiant.com.

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

### Updating after you edit the fork

**Editing the working tree changes nothing on its own.** The plugin runs from a
version-keyed cache under `~/.claude/plugins/cache/superpowers-cc/`, and
`claude plugin update` compares versions — with the version unchanged it reports
"already at the latest version" and keeps serving the old copy. Verified: a probe
line added to a tracked file did not reach the cache until the version moved.

So bump the version, then update:

```bash
scripts/bump-version.sh 6.2.1-cc.2        # writes package.json + both manifests
claude plugin marketplace update superpowers-cc
claude plugin update superpowers@superpowers-cc
# then restart Claude Code
```

Version convention for this fork: `<upstream-version>-cc.<N>`, so `6.2.1-cc.2`
reads as "ahead of upstream 6.2.0, fork revision 2". `bump-version.sh --check`
reports drift; `--audit` greps the repo for stragglers.

### Verify what is actually live

```bash
claude plugin details superpowers@superpowers-cc
```

That prints the running version and a component inventory. This fork should show
**15 skills**, **4 agents** (`code-reviewer`, `sdd-implementer`,
`sdd-task-reviewer`, `sdd-re-reviewer`), and **2 hooks** (SessionStart,
PreToolUse). If `agents` is 0 or `cross-reviewing-with-codex` is missing from the
skill list, you are on a stale cache — bump and update.

`claude plugin validate .` checks the manifests before you commit a change to them.

### Optional capabilities

| Feature | Enable | Effect |
|---|---|---|
| Native task management | `CLAUDE_CODE_ENABLE_TASKS=1` | `blockedBy` dependency enforcement and a live task panel; activates the user-gate hook |
| Codex cross-review | [Codex CLI](https://github.com/openai/codex) on PATH | Spec, plan, and branch cross-review. Confirm it runs: `codex exec -s read-only -o /tmp/m "Reply OK" </dev/null` — a 400 about the model means the configured default is unusable, so pin one with `-c model=<name>` |

### Other harnesses

Not supported. Upstream ships integrations for Antigravity, Codex, Cursor,
Factory Droid, Gemini CLI, Copilot CLI, Kimi Code, OpenCode, and Pi; this fork
has removed all of them — the plugin manifests, the tool-mapping references, the
per-harness docs, and their tests. The skills name Claude Code's tools directly.
Install [upstream](https://github.com/obra/superpowers) for those harnesses.

## Hooks

Two `PreToolUse` gates ship registered in [`hooks/hooks.json`](hooks/hooks.json).
Both fail open on any error and both have a kill switch.

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

### Native task management (optional)

`TaskCreate` / `TaskUpdate` / `TaskList` give dependency enforcement via
`blockedBy` and a live task view in the IDE. They sit behind
`CLAUDE_CODE_ENABLE_TASKS`, so they are off by default. With them enabled,
subagent-driven-development mirrors the plan into tasks and the user-gate hook
becomes active; the progress ledger stays the resume mechanism either way.

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

Read [the original release announcement](https://blog.fsck.com/2025/10/09/superpowers/).

## Contributing

This is a single-harness fork; changes here are not sent upstream. Contribute portable improvements to [upstream](https://github.com/obra/superpowers) instead. Within this fork, treat skill edits as behavior changes: follow the `writing-skills` skill, and measure before and after rather than assuming a rewording is an improvement.

Skill-behavior tests use the drill eval harness from [superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/), cloned into `evals/` — see `evals/README.md` for setup. Plugin-infrastructure tests live at `tests/` and run via the relevant `run-*.sh` or `npm test`.

See `skills/writing-skills/SKILL.md` for the complete guide.

## Updating

Nothing here auto-updates: this fork installs from a local checkout, so you pull
and then bump-and-update. See
[Updating after you edit the fork](#updating-after-you-edit-the-fork).

## License

MIT License - see LICENSE file for details

## Telemetry

None. Upstream's only phone-home was the logo on brainstorming's visual
companion; this fork removed the companion, so nothing here contacts a network
service.

## Community

Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of the folks at [Prime Radiant](https://primeradiant.com).

- **Discord**: [Join us](https://discord.gg/35wsABTejz) for community support, questions, and sharing what you're building with Superpowers
- **Issues**: https://github.com/obra/superpowers/issues
- **Release announcements**: [Sign up](https://primeradiant.com/superpowers/) to get notified about new versions
