---
name: brainstorming
description: Use before any creative work — creating a feature, building a component, adding functionality, or changing behavior
---

# Brainstorming Ideas Into Designs

Turn an idea into a design and a written spec through collaborative dialogue.

Classify how much process the request needs, work that path, then present the
design and get approval.

<HARD-GATE>
Do not write code, scaffold a project, invoke an implementation skill, or take
any other implementation action until you have presented what you intend to do
and the user has approved it. This holds on every path below, including the
requests that look too simple to need it — those are where unexamined
assumptions cost the most. The ceremony scales with the task; the approval gate
never does. The design can be three sentences; it still gets presented and
approved.
</HARD-GATE>

## Three Paths

Classify the request before your first question, and name the path you picked so
the user can override it: "this looks bounded, so I will present a short design
here instead of writing a spec".

| Path | The request | What it produces |
|------|-------------|------------------|
| **Spike** | a feasibility question — "can we", "is it possible", "quick and dirty is fine" | an answer, not code you keep |
| **Bounded** | a well-scoped change to a flow that already exists in this repo: a flag, a small endpoint, a one-file fix | a short design in chat, then implementation |
| **Architectural** | a new project, a new subsystem, or a change that restructures how components fit together or alters interfaces others depend on | approaches, a design, a committed spec, then writing-plans |

When two paths both fit, take the heavier one. The ratchet is one-way: hidden
complexity found mid-task upgrades the path — stop, say so, and step up. Nothing
downgrades mid-task, and each new request gets its own classification.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll call it bounded and skip the spec" | Reaching for the lighter label is the doubt itself. Take the heavier path. |
| "I know this kind of app, so it's bounded" | Bounded measures the repo, not your familiarity. No existing flow to read means architectural. |
| "The design is obvious — I'll start while they read it" | The gate is the approval, not the design's length. Present it, then stop until you hear yes. |
| "The spike works, so I'll keep the code" | A spike produces an answer. Keeping the code is a new request; classify it. |
| "It grew, but I'm nearly done — no need to re-classify" | Hidden complexity upgrades the path mid-task. Stop and say so. |

## Checklists

`TaskCreate` one task per item on your path and complete them in order.

**Spike:**

1. **Explore project context** — enough to frame the probe
2. **Present the question and the probe** — 2-3 sentences
3. **Get approval** — a nod is enough
4. **Investigate** — as cheaply as correctness allows
5. **Report findings** — a recommendation; label anything you built as throwaway

**Bounded:**

1. **Explore project context** — files, docs, recent commits
2. **Ask the clarifying questions that matter** — one topic at a time
3. **Present a short design in chat** — approach, files touched, testing
4. **Get approval** — stop and wait for an explicit yes
5. **Implement** — the normal development workflow, TDD included; no spec file, no plan document

**Architectural:**

1. **Explore project context** — files, docs, recent commits
2. **Ask clarifying questions** — purpose, constraints, success criteria
3. **Propose 2-3 approaches** — trade-offs, and your recommendation
4. **Present the design** — in sections scaled to their complexity, approved section by section
5. **Write the design doc** — `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, committed
6. **Self-review the spec** — placeholders, contradictions, ambiguity, scope
7. **Cross-review the spec** — superpowers:cross-reviewing-with-cursor, if a cross-review CLI is installed
8. **User reviews the written spec**
9. **Hand off** — invoke superpowers:writing-plans

**The terminal state follows the path.** Architectural ends by invoking
writing-plans — not frontend-design, not mcp-builder, not any other
implementation skill. Bounded ends in implementation, with no plan document. A
spike ends in a reported recommendation.

The sections below serve bounded and architectural work. **Exploring Approaches**
onward is architectural depth: for bounded work, context plus a few questions
plus a short design in chat is the whole process. A spike uses none of it — once
its probe is approved, it investigates and reports.

## Asking Questions

**Use `AskUserQuestion`.** It renders the options, records the answer, and lets
the user pick "Other" when your options miss.

- **One topic per call**, up to four related questions in that topic. Don't
  serialize four calls when the questions belong together, and don't mix
  unrelated topics into one call to save a round trip.
- **Lead with your recommendation** — put it first and label it "(Recommended)".
  You have read the codebase; say what you would do.
- **Use `preview`** when the choice is easier to see than to read: an ASCII
  layout sketch, two code shapes side by side, competing config examples.
- **Ask open-ended in prose** when the answer is a paragraph, not a choice
  ("what does this need to do at month six?").

**Start from what the user is looking at.** In the IDE, the open file and any
selected code arrive as context. When they do, treat them as the likely subject
and confirm rather than re-deriving it: "You've got `retry.ts` open with the
backoff block selected — is that what this is about?" Getting that wrong early
costs several questions.

**Assess scope before the details.** If the request describes several independent
subsystems ("a platform with chat, file storage, billing, and analytics"), say so
immediately. Don't spend questions refining a project that needs decomposing
first — help the user split it into pieces, decide the order, then brainstorm the
first piece through this flow. Each piece gets its own spec → plan → implementation
cycle.

## Exploring Approaches

- Propose 2-3 approaches with real trade-offs, not one plan and two strawmen
- Lead with the recommended option and say why
- YAGNI ruthlessly — cut unnecessary features from every approach

## Presenting the Design

- Scale each section to its complexity: a few sentences when it's straightforward,
  up to 200-300 words when it's genuinely nuanced
- Check after each section that it looks right so far
- Cover architecture, components, data flow, error handling, testing
- Go back and re-clarify when something doesn't hold up

**Design for isolation and clarity:**

- Break the system into units with one clear purpose each, communicating through
  well-defined interfaces, understandable and testable independently
- For each unit, you should be able to say what it does, how to use it, and what
  it depends on
- Can someone understand a unit without reading its internals? Can you change the
  internals without breaking its consumers? If not, the boundaries need work
- Smaller, well-bounded units are also easier for you: you reason better about
  code you can hold in context at once, and your edits are more reliable when
  files are focused. A file that keeps growing is usually doing too much

**In existing codebases:**

- Explore the current structure before proposing changes; follow existing patterns
- Where existing problems affect this work — a file grown too large, tangled
  responsibilities — include targeted improvements, the way a good developer
  improves code they're working in
- Don't propose unrelated refactoring

## Showing Instead of Describing

When a question is genuinely visual — a layout, a diagram, competing screen
designs — build it rather than describing it.

- **Small comparisons:** `AskUserQuestion` previews, inline ASCII mockups
- **Anything richer:** the `Artifact` tool — a self-contained HTML page with the
  mockups, diagrams, or side-by-side designs, published to a private URL the user
  opens. Mermaid renders natively, so architecture and flow diagrams cost a code
  fence. Update the same file path to redeploy to the same URL as the design
  evolves.

A question about a UI *topic* is not automatically a visual question. "What does
personality mean here?" is conceptual — just ask it. "Which of these two wizard
layouts?" is visual — show it.

## After the Design (architectural)

**Write the spec** to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` (user
preferences for location override this). **REQUIRED SUB-SKILL:** Use
superpowers:writing-clearly-and-concisely. Commit the spec.

**Self-review it** with fresh eyes:

1. **Placeholders:** any "TBD", "TODO", unfinished section, or vague requirement? Fix.
2. **Internal consistency:** do any sections contradict? Does the architecture match the feature descriptions?
3. **Scope:** focused enough for one implementation plan, or does it need decomposing?
4. **Ambiguity:** could any requirement be read two ways? Pick one and make it explicit.

Fix inline and move on — no second review pass.

**Then cross-review it.** Use superpowers:cross-reviewing-with-cursor, site 1. A
second model reading the spec cold finds the ambiguities you can't see, because you
wrote them. Confirmed findings get fixed in the spec now; the skill's verification
gate decides which findings are real, and no unverified suggestion touches the
spec. If no cross-review CLI is installed, say so in one line and carry on.

**Then the user's review gate:**

> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."

When a cross-review ran, add one line naming what it changed — the user is
reviewing an amended spec and should know it.

Wait for their response. Changes requested → make them and re-run the self-review.
Only proceed on approval.

**Then hand off:** invoke superpowers:writing-plans. No other skill.
