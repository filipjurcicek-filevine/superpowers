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

Give your agent Superpowers: [Claude Code](#claude-code) (CLI or VS Code extension).

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do. 

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest. 

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY. 

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for your agent to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers.

## Commercial Services

If you're using Superpowers in enterprise and could benefit from commercial support, additional tooling, or managed spending, please don't hesitate to drop us a line at sales@primeradiant.com.

## Installation

This fork installs as a Claude Code plugin.

### Claude Code

Superpowers is available via the [official Claude plugin marketplace](https://claude.com/plugins/superpowers)

#### Official Marketplace

- Install the plugin from Anthropic's official marketplace:

  ```bash
  /plugin install superpowers@claude-plugins-official
  ```

#### Superpowers Marketplace

The Superpowers marketplace provides Superpowers and some other related plugins for Claude Code.

- Register the marketplace:

  ```bash
  /plugin marketplace add obra/superpowers-marketplace
  ```

- Install the plugin from this marketplace:

  ```bash
  /plugin install superpowers@superpowers-marketplace
  ```

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

Superpowers updates are somewhat coding-agent dependent, but are often automatic.

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
