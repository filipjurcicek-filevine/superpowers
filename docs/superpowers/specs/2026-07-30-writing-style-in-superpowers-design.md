# Writing style in superpowers-cc — design

## Background

Skills in this library author prose a human reads: specs, plans, PR descriptions,
review summaries. Nothing in the library says how that prose should read. One skill
gestures at guidance it does not ship — `brainstorming/SKILL.md:119` says "If a
`writing-clearly-and-concisely` skill appears in your skill list, use it — the
namespace it ships under varies by setup, so match on the name." That hedge exists
because the skill was external to the plugin.

This change ships the style guidance in-tree, wires the six skills that author
such prose to it, and adds an option that makes the routing rule resident in every
session.

**The wiring criterion:** a skill gets a reference when it instructs the agent to
*author* prose a human will read. Two things are exempt. Conversational turns are
not authored artifacts. Fixed quoted strings the skills mandate — the consent
question at `using-git-worktrees/SKILL.md:51`, the review-gate sentence at
`brainstorming/SKILL.md:140` — are already-decided wording, and a style skill must
not license an agent to rewrite them. That exemption is load-bearing; see
"Scope of the skill" below.

The content starts from an existing personal skill at
`~/Projects/scratch/.claude/skills/writing-clearly-and-concisely/` (6 files, 168KB).
A review of that skill found two files that should not ship, two that buy nothing
here, and one that needs distilling. The file set below is that reviewed result,
not a copy; "Content decisions" records why four of the six source files are
absent, so a later reader does not restore them.

## In scope

1. New plugin skill `skills/writing-clearly-and-concisely/` — three files.
2. `SUPERPOWERS_WRITING_STYLE` option in `hooks/session-start`.
3. References from six skills to the new skill.
4. New cases in `tests/hooks/test-session-start.sh`.
5. README, `CLAUDE.md`, `RELEASE-NOTES.md`, version bump.

## Out of scope

- **Deleting the personal copy** at `~/Projects/scratch/.claude/skills/writing-clearly-and-concisely/`.
  It becomes redundant once the plugin ships one, and two similarly-named skills in
  one list is a routing hazard. It lives in a different repository; flag it after
  this work lands.
- **A user-facing report step in `subagent-driven-development`.** Its Finish step
  delegates to `finishing-a-development-branch` (`SKILL.md:368–371`) and authors no
  report of its own. Wiring it would mean adding a step, which this change does not
  do.
- **Commit messages.** Nothing in the library instructs an agent to author one:
  `grep -rn 'commit message' skills/ agents/` returns only example content in
  `writing-skills/anthropic-best-practices.md` and a passing mention at
  `agents/code-reviewer.md:37`. Commit-message wording is the harness's and
  `CLAUDE.md`'s business, not this library's.
- **Eval pressure scenarios**, beyond the micro-test obligation below.
- **A style pass over the existing 15 skills.** This gives future prose a standard.
  Rewriting the library to meet it is separate work.

## Content decisions

### File set

```
skills/writing-clearly-and-concisely/
  SKILL.md
  elements-of-style/
    03-elementary-principles-of-composition.md    34KB, verbatim Strunk 1918
  ai-writing-tells.md                             ≤14KB, distilled
```

### What the source skill ships that this one does not

**`05-words-and-expressions-commonly-misused.md` (22KB) — dropped.** It carries
prescriptions that are obsolete, and one that conflicts with the harness. Its entry
for *they* instructs the writer away from singular *they*, which Claude Code
requires when a person's pronouns are unstated. It also prescribes *shall* by
grammatical person, calls split infinitives "in disfavor," treats *data* as plural
only, rules *different than* "not permissible," forbids *contact* and *feature* as
verbs, and carries entries for **Student Body**, **Thanking You in Advance**, and
**One hundred and one**. A file loaded to shape a PR description must not hand the
model 1918 usage law.

Twelve of its entries remain live and move into the `SKILL.md` kill list, each
keeping the *condition* that makes it a defect rather than becoming a banned token.
See "Kill-list semantics."

**`04-a-few-matters-of-form.md` (5KB) — dropped.** Manuscript typography: blank
lines after a title "if using ruled paper," syllabication for end-of-line word
breaks, italics "indicated in manuscript by underscoring," links to Gutenberg page
scans. The source skill's routing table advertises it as "Headings, quotations,
formatting," which is what would make an agent load it.

**`02-elementary-rules-of-usage.md` (12KB) — dropped.** Seven rules on possessive
`'s`, the serial comma, parenthetic commas, comma splices, and dangling participles.
Opus 5 follows all seven without instruction, so this is the fork's "don't restate
the system prompt" rule one level down. This is the least certain of the four drops
— reasoned, not measured. Reverse it only for a concrete need to cite Strunk by
rule number.

**`01-introductory.md` (303 bytes) — dropped.** Three lines of preamble, no rules.

**`signs-of-ai-writing.md` (95KB) — distilled, not copied.** Measured by section:

| | Size | Sections |
|---|---|---|
| Applies to authoring prose | 53KB | Regression to the Mean, Language and Grammar, Punctuation and Formatting, Communication Intended for the User |
| Does not | 41KB | Markup (14KB), Citations (8KB), Discrepancies (5KB), detection intro (5KB), Ineffective Indicators (3KB), Signs of Human Writing, Notes, References |

The 41KB is Wikipedia detection machinery: `citeturn` and `oaicite` artifacts, DOI
and ISBN validity, UTM parameters, AFC draft templates, GPTZero's error rate, "age
of text relative to ChatGPT launch."

Two parts of the remainder are actively wrong for this use. The file is a detection
guide and says so — "This list is *descriptive*, not *prescriptive*… some
signs—particularly those involving punctuation and formatting—may not apply in a
non-Wikipedia context." And its formatting section flags em dashes, boldface, and
Markdown as AI tells. Claude Code output *is* terminal Markdown, and the skills in
this library use bold and em dashes throughout, so an agent that loads that section
mid-task will strip formatting the harness relies on.

### `ai-writing-tells.md` — distillation criteria

The source is 901 lines and 94,774 bytes. The retained ranges measure **44,107
bytes** across **21 subsections**, of which **11 carry a Words-to-watch list** and
10 do not. Reaching ≤14KB is a 68% cut, so the transform rules below are what
produce it — not incidental trimming. The rules are fixed here because the edit is
judgment-heavy.

**Retain, as subsections:**

- All of *Regression to the Mean* except "Leads treating Wikipedia lists or broad
  article titles as proper nouns."
- All of *Language and Grammar*.
- From *Punctuation and Formatting*: title case in headings, boldface density,
  inline-header vertical lists, emoji decoration.
- From *Communication Intended for the User*: knowledge-cutoff disclaimers, prompt
  refusals leaking into output, placeholder and phrasal-template text.

**Drop:** everything in the 41KB column above; the em-dash and
curly-quotation-mark subsections; "Subject lines"; and the *collaborative
communication* subsection. That last one's watch list is *Would you like…*, *let me
know*, *Certainly!* — phrases whose defect on Wikipedia is appearing inside an
article, not existing. Two of them are mandated verbatim by this library
(`using-git-worktrees/SKILL.md:51`, `brainstorming/SKILL.md:140`), and
`brainstorming` is one of the wired call sites. Shipping that list prescriptively
would have the skill contradict the skills that invoke it.

**Transform, per retained subsection:**

1. Rewrite its heading as an imperative prohibition. "Undue emphasis on symbolism,
   legacy, and importance" becomes "Do not inflate significance."
2. Keep its **Words to watch** list, verbatim except that footnote markers
   (`[^a]`, `[^8]`) are dropped — two such lists carry them, so "verbatim" without
   this exception is unsatisfiable. **Ten subsections have no such list; invent
   none.**
3. Add one sentence stating the rule as a prohibition: what not to write, in the
   imperative.
4. Delete everything else: the explanatory paragraphs, every example gallery, all
   Wikipedia links, all footnotes.

A heading, an optional watch list, and one sentence per subsection is the whole
file. A result above 14KB means step 4 was not applied.

### Provenance and licensing

The personal source directory is untracked and carries no revision metadata, so it
is not a reproducible input. The implementer records provenance from the upstream
sources at copy time:

- **Strunk.** *The Elements of Style*, William Strunk Jr., 1918 — public domain.
  The local text derives from Project Gutenberg ebook #37134 (its sibling file `04`
  carries `gutenberg.org/files/37134` links). Name that in a header comment in
  `elements-of-style/03-elementary-principles-of-composition.md`.
- **`ai-writing-tells.md`.** Adapted from the Wikipedia project page
  "Wikipedia:Signs of AI writing," licensed **CC BY-SA 4.0**. Its header carries:
  the page title, the permalink of the revision current **on the retrieval date**
  (resolvable through the MediaWiki API with `rvstart`, so "the latest revision" is
  not a substitute; if the API is unreachable, the header says the revision was not
  resolved rather than naming the wrong one), the retrieval date, the license name
  and URL, and a change notice — "adapted: reframed as
  prohibitions; examples, explanatory prose, and Wikipedia-process sections
  removed." CC BY-SA requires attribution and share-alike, so this file stays CC
  BY-SA even though `.claude-plugin/plugin.json:11` declares the package MIT. State
  that boundary in the file header and in the README section: one file under a
  different license does not relicense the package, and the file's own license
  travels with it when it is loaded alone.

### `SKILL.md` — content

**Frontmatter.** `name: writing-clearly-and-concisely`. The `description` is the
expensive part of this skill: `writing-skills/SKILL.md:209–216` measures a
description character at ~25x a body character, because it sits in every session
from turn 1 whether the skill is invoked or not, across ~25 context re-reads per
run. The library's 15 descriptions total ~1.6k characters; this is the 16th. So the
description carries triggering conditions and symptom keywords only — no
provenance, no mention of Strunk or of which skills call it — and stays at or under
~150 characters.

**Body,** in order:

1. **Opening, two sentences.** What this is, and that the rules below are the ones
   that fight the model's defaults. No `## Overview` heading — banned by
   `writing-skills`, and the title already says it.
2. **Scope.** See "Scope of the skill" below. Three lines.
3. **Six operative rules, one line of before → after each.** Active voice;
   positive form; definite, specific, concrete language; omit needless words; keep
   related words together; emphatic word last. Each example rewrites a sentence of
   the kind this library actually produces, not Strunk's 1918 examples — under
   concrete language, "improves performance" → "cuts p99 latency from 400ms to
   90ms."
4. **Kill list.** See "Kill-list semantics."
5. **One routing line** to the two reference files, naming when each is worth
   loading.
6. **Attribution line** for the two reference files.

**Omit:** `## When to Use This Skill` (the frontmatter routes; the body loads after
routing succeeded), `## Bottom Line`, any closing recap — the last two are banned
by `writing-skills`. Omit the source skill's "Limited Context Strategy," which
prescribes a subagent round-trip to avoid loading a 34KB file; that is rarely the
right trade at 1M context, and the dispatch decision belongs to
`dispatching-parallel-agents` if anywhere.

Each rule appears once, in one form. `SKILL.md` restates nothing from
`03-elementary-principles-of-composition.md` beyond the one-line summary plus
example that makes the rule actionable without a load.

### Scope of the skill

The skill governs prose the agent **authors** for a human to read: a spec, a plan,
a PR description, a review summary, an error message, UI text. It does not govern
conversational turns, and it does not license rewriting a quoted string another
skill mandates. `SKILL.md` states this in three lines, because the alternative is
an agent that "improves" the consent question at `using-git-worktrees/SKILL.md:51`
or the review-gate sentence at `brainstorming/SKILL.md:140` — both fixed wording,
both reachable from a wired call site.

### Kill-list semantics

Each entry is a word plus the condition that makes it a defect, never a banned
token. *Case* is a defect when it means "instance of a thing occurring" ("in the
case of a timeout" → "on timeout"), not in "test case." *So* is a defect as an
intensifier ("so much faster"), not as a conjunction. An implementer who reduces
these to a word list produces a skill that mangles technical prose.

Three groups:

- **Puffery:** *pivotal*, *crucial*, *vital*, *testament*, *enduring legacy*,
  *robust*, *seamless*, *groundbreaking*, *cutting-edge*.
- **Empty `-ing` tails:** *ensuring reliability*, *showcasing*, *highlighting*,
  *underscoring* — the clause that adds a claim instead of a fact.
- **AI vocabulary:** *delve*, *leverage*, *multifaceted*, *foster*, *realm*,
  *tapestry*, *landscape*, *navigate*.

Plus the twelve entries salvaged from `05`, each with its condition: the
needless-word set (*case*, *character*, *factor*, *nature*, *system*,
*respective*), *literally* propping up a metaphor, *interesting* as an
announcement, "one of the most" opening a paragraph, and the intensifiers *very*,
*certainly*, *so*.

### Body length is not a cost lever

`writing-skills/SKILL.md:220–224` measures this: compressing two skill bodies by
21–33% moved total run cost by less than run-to-run noise, because the body was
~0.08% of tokens consumed. **Do not compress this `SKILL.md` for cost.** The
compression of the source skill is justified by *repetition* — it said "load `03`"
three times, restated its own frontmatter as a body section, and carried two
banned selling sections — which is the standing rule at
`writing-skills/SKILL.md:232`. An earlier draft of this spec justified the same cut
by token savings and set a 60-line cap; both are withdrawn. The tier convention
still applies: aim under ~500 words of instruction, more only if every line is
load-bearing.

## The option

`SUPERPOWERS_WRITING_STYLE` gates one thing: whether `hooks/session-start` appends
a routing pointer to the session context. Default off.

**Enabled** when the value, lowercased, is `1`, `true`, `yes`, or `on`. Every other
value — unset, empty, `0`, `false`, anything else — is off.

**When enabled,** the hook appends a second block after the existing bootstrap,
built from a string constant in the hook, escaped through the existing
`escape_for_json` helper and emitted by the same single `printf`:

```
<superpowers-writing-style>
Prose you author for a human to read — a spec, a plan, a PR description, a
report — goes through superpowers:writing-clearly-and-concisely. Invoke it
before writing, not as a cleanup pass afterward.
</superpowers-writing-style>
```

**It injects the routing rule, not the rules themselves.** ~35 words, against the
~200-word bootstrap budget at `writing-skills/SKILL.md:200`. Three consequences,
all deliberate:

- **No rule is stated twice.** The rules live in the body, which costs nothing
  until the skill is invoked, and "say each rule once" is a fork invariant.
- **No "already resident, invoke anyway?" ambiguity.** The block is a pointer, so
  invoking the skill is the only way its content ever loads.
- **The option's claim is smaller than it looks.** It makes the routing rule
  resident; it does not make the rules resident. An agent that ignores the pointer
  gets no style guidance — the same failure mode `using-superpowers` already
  carries for all 16 skills, which is why the six explicit call sites matter more
  than the option does.

**The six call sites are the target of this change; the option is a convenience.**
That was decided explicitly, against two alternatives. Injecting the rules
themselves would put them in context unconditionally, but the text would have to
exist in both the hook and `SKILL.md` — the block is absent in a default session,
so the skill must stay self-sufficient — which is two copies drifting
independently. Measured, it would also add ~400 words to the 641 words of
always-resident library text (`using-superpowers` 283 + fifteen descriptions 358).
The other alternative, an `@`-imported rules file in a workspace `CLAUDE.md`, does
give unconditional residency with one copy of the rules, and is the better
mechanism when a single workspace is the scope — but it does not travel with the
plugin, which is what this change is for. Prose authored outside the six flows
therefore goes unstyled unless the agent acts on the pointer. That is the accepted
cost, not an open question.

**Fail-open paths.** The hook runs under `set -euo pipefail`. Because the pointer
is a constant, the option adds no file read and therefore no new failure mode:

| Condition | Behavior |
|---|---|
| Variable unset, empty, or unrecognized | No style block. Payload identical in structure to the current one. Exit 0. |
| Enabled | Both blocks, one valid JSON object. Exit 0. |

The variable is its own kill switch, so this hook adds no second one. A malformed
payload would break session startup, which is worse than any drift it could
prevent, so the tests below assert JSON validity on every path.

The option adds no hook registration. It rides the existing `SessionStart` entry in
`hooks/hooks.json` and its `startup|clear|compact` matcher, so the pointer returns
after a `/clear` and after a compaction, exactly as the bootstrap does.

**The skill name appears in two places** — the hook constant and the skill
directory — so a rename can silently break the pointer. A test asserts the named
directory exists.

## Skill wiring

Every reference uses the repo's requirement-marker convention
(`writing-skills/SKILL.md:268–271`), which marks an unmarked cross-reference as a
defect because the reader cannot tell whether it is required:

```
**REQUIRED SUB-SKILL:** Use superpowers:writing-clearly-and-concisely
```

All six are `REQUIRED SUB-SKILL`. The difference between call sites is where the
marker attaches, not how binding it is — an advisory-versus-mandatory split would
be a second, unstated rule.

| Skill | Attaches to | Verified location |
|---|---|---|
| `brainstorming` | "Write the spec" — replaces the soft name-match | `SKILL.md:119` |
| `writing-plans` | Writing the plan document | plan-writing step |
| `finishing-a-development-branch` | The PR description in Option 2 | `SKILL.md:140–143` |
| `writing-skills` | Writing skill prose; cross-linked to "Match the Form to the Failure" | body |
| `requesting-code-review` | Presenting the reviewer's findings to the user | `SKILL.md:64–70` |
| `receiving-code-review` | Step 5, the acknowledgment or reasoned pushback | `SKILL.md:19` |

`brainstorming:119` loses "the namespace it ships under varies by setup, so match on
the name" — the namespace no longer varies, because the skill ships here.

Each reference attaches to an instruction that already exists. No step is added to
any sequence, and no existing instruction changes meaning.

## Testing

`tests/hooks/test-session-start.sh` already asserts payload shape through
`assert_command_output` with `contains` and `not_contains` matchers and a Node JSON
parse, so these are new cases in the existing harness, not a new file. The harness
invokes the hook through `env -i PATH="$PATH" HOME="$home"`, which clears the
environment, so every enabled case must pass `SUPERPOWERS_WRITING_STYLE` on that
`env` line; `env -i` already guarantees the unset case.

| Case | Executions | Asserts |
|---|---|---|
| Disabled by default | unset | Bootstrap present, `<superpowers-writing-style>` absent, valid JSON |
| Enabled | `1`, `true`, `yes`, `on`, `TRUE`, `On` | Both blocks present, valid JSON |
| Not enabled | `0`, `false`, `maybe`, empty string | Style block absent, valid JSON |
| Disabled payload unchanged | unset | `additionalContext` matches `^<superpowers-bootstrap>[\s\S]*</superpowers-bootstrap>$` — nothing appended |
| Pointer names a real skill | n/a | The directory named in the hook constant exists |

The fourth case replaces a "byte-identical to the current output" check that an
earlier draft specified: the harness has no `diff`, `cmp`, or snapshot helper, and
the old hook cannot be re-run from history because it derives its plugin root from
its own location. Asserting that the disabled payload contains exactly the
bootstrap and nothing after it is what "unchanged" means here, and it is checkable
in the harness as it stands.

### Micro-test obligation

`CLAUDE.md` requires micro-testing skill wording against a no-guidance control, 5+
reps, every flagged match read by hand. This change owes that on one question:
whether the compressed `SKILL.md` produces prose as good as the source skill's
longer form.

- **Arms:** no-guidance control; the source skill's `SKILL.md` verbatim; the
  compressed `SKILL.md`.
- **Prompts:** three, one per output kind this library produces — a spec paragraph
  describing a design decision, a PR description for a two-commit change, a review
  summary of three findings.
- **Reps:** 5 per arm per prompt.
- **Flagged match**, counted by hand per rep: a kill-list hit in its defect
  condition; a passive construction where an actor exists; a hedge that adds no
  information; a puffery adjective.
- **Bar:** the compressed arm's flagged-match count is at or below the source arm's
  on every prompt, and both are clearly below the control. A compressed arm that
  regresses against the source means the cut removed something load-bearing;
  restore it rather than shipping the shorter file.

The six wiring references are additive markers on existing instructions, not
changes to discipline scaffolding, so they carry no pressure-scenario obligation.
Say so in the commit message; claim no eval verification that did not happen.

## Documentation

| File | Change |
|---|---|
| `README.md:175` | "**15 skills**" → "**16 skills**". The count is a manifest-sanity check. |
| `README.md:194–197` | Optional-capabilities row: `SUPERPOWERS_WRITING_STYLE=1` → a routing pointer to the style skill in every session. |
| `README.md:213–229` | SessionStart section: with the option on, a ~35-word pointer joins the bootstrap. Note explicitly that the skill *body* is not resident, so the "always-resident" warning still names one file. |
| `README.md` | New section "Writing style (optional)", parallel to "Codex cross-review (optional)" and "Native task management (optional)". States the CC BY-SA boundary. |
| `CLAUDE.md` | One line under Fork Invariants: the style content ships in-tree, the option gates a routing pointer only, and the injected block never restates the rules. |
| `RELEASE-NOTES.md` | Entry for the release. |
| Version | The tree is at `6.2.1-cc.3` (`bf6c653`). Release this as `6.2.1-cc.4` via `scripts/bump-version.sh`. The leading `6.2.1` stays: per `README.md:147–149` it names the upstream base, and nothing here adopts a new upstream. |

## Commit plan

One concern per commit, in dependency order:

1. Add the skill (three files).
2. Add the option to `hooks/session-start` plus its tests.
3. Wire the six skill references.
4. Documentation and version bump.

Commit 2 depends on commit 1: its skill-name test asserts the directory exists.

## Verification

- `claude plugin validate .` passes.
- `tests/hooks/test-session-start.sh` passes, every execution in the table.
- `claude plugin details superpowers@superpowers-cc` reports 16 skills, 4 agents,
  2 hooks, and the on-invoke and always-on numbers for the new skill.
- `wc -c` on the new `description` is at or under ~150.
- `wc -c ai-writing-tells.md` is at or under 14336.
- `ai-writing-tells.md` header carries the Wikipedia permalink for the retrieval
  date — or an explicit statement that it could not be resolved — plus retrieval date, CC
  BY-SA 4.0 notice, and change notice.
- `grep -rn "writing-clearly-and-concisely" skills/` returns the six wired call
  sites, each with a `REQUIRED SUB-SKILL` marker, plus the skill itself — and no
  remaining "varies by setup" hedge.
- `grep -rn "writing-clearly-and-concisely" hooks/` returns the pointer constant,
  and that directory exists.
- No file in the skill directory is unreferenced by `SKILL.md`.
