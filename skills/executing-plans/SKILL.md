---
name: executing-plans
description: Use when executing an implementation plan inline in this session, rather than dispatching a subagent per task
---

# Executing Plans Inline

## Overview

Execute a plan yourself, task by task, in this session.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## When This Is the Right Route

Inline execution is the deliberate choice when:

- **The tasks are tightly coupled** — each one depends on the shape of the last,
  so a fresh subagent per task would spend its context rediscovering what you
  already know.
- **The user wants to watch and steer** — they asked to see each step, or the work
  is exploratory enough that direction may change mid-plan.

Otherwise use superpowers:subagent-driven-development: a fresh implementer per
task, a task review after each, and a broad review at the end catch more than
inline execution does, because the reviewer has no stake in the code.

## The Process

### Step 1: Load and Review the Plan

1. Ensure an isolated workspace — superpowers:using-git-worktrees.
2. Read the plan file.
3. Review it critically: contradictions between tasks, requirements with no task,
   types or signatures that don't match across tasks, anything the plan mandates
   that you believe is wrong.
4. Raise what you found with the user before starting.
5. Create a todo per task.

### Step 2: Execute Tasks

For each task: mark it in progress, follow its steps, run the verifications the
plan specifies, mark it complete. Use superpowers:test-driven-development for the
implementation steps.

Do not batch verification to the end. A plan step that says to run the tests is
the point at which you run them.

### Step 3: Complete

After all tasks pass their verifications:

- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** superpowers:finishing-a-development-branch

## When to Stop and Ask

Stop when you hit a blocker (missing dependency, failing test you can't explain,
an instruction you don't understand), when the plan has a gap that prevents
starting, or when verification keeps failing. Ask rather than guessing.

Return to Step 1 when the user updates the plan, or when the approach needs
rethinking rather than the next step.

## Remember

- Review the plan critically before starting, not after it goes wrong
- Follow the plan's steps; run its verifications where it says to
- Invoke the skills the plan names
- Never start implementation on main/master without the user's explicit consent
