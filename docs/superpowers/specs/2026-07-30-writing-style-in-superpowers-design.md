# Writing style in superpowers-cc — design

## Background

Skills in this library produce prose a human reads: specs, plans, commit messages,
PR descriptions, review summaries. Nothing in the library says how that prose
should read. One skill gestures at guidance it does not ship —
`brainstorming/SKILL.md:119` says "If a `writing-clearly-and-concisely` skill
appears in your skill list, use it — the namespace it ships under varies by
setup, so match on the name." That hedge exists because the skill was external to
the plugin.

This change ships the style guidance in-tree, wires every prose-producing skill to
it, and adds an option that makes it resident in every session.

The content starts from an existing personal skill at
`~/Projects/scratch/.claude/skills/writing-clearly-and-concisely/` (6 files, 168KB,
~42k tokens fully loaded). A review of that skill found two files that should not
ship and ~35 dead lines in its `SKILL.md`; the file set below is the reviewed
result, not a copy. The review findings are recorded in "Content decisions" so a
later reader knows why four of the six files are absent.

## In scope

1. New plugin skill `skills/writing-clearly-and-concisely/` — three files.
2. `SUPERPOWERS_WRITING_STYLE` option in `hooks/session-start`.
3. References from seven skills to the new skill.
4. Four new cases in `tests/hooks/test-session-start.sh`.
5. README, `CLAUDE.md`, `RELEASE-NOTES.md`, version bump.

## Out of scope

- **Deleting the personal copy** at `~/Projects/scratch/.claude/skills/writing-clearly-and-concisely/`.
  It becomes redundant once the plugin ships one, and two similarly-named skills in
  one list is a routing hazard. It lives in a different repository; flag it after
  this work lands.
- **Eval pressure scenarios.** See "Testing obligation" for what is and is not
  verified here.
- **A style pass over the existing 15 skills.** This change gives future prose a
  standard. Rewriting the library to meet it is separate work.

## Content decisions

### File set

```
skills/writing-clearly-and-concisely/
  SKILL.md                                        ~50 lines / ~2KB
  elements-of-style/
    03-elementary-principles-of-composition.md    34KB, verbatim Strunk 1918
  ai-writing-tells.md                             ~10KB, distilled
```

Fully loaded: ~11.5k tokens, down from ~42k for the source skill.

### What the source skill ships that this one does not

**`05-words-and-expressions-commonly-misused.md` (22KB) — dropped.** It carries
prescriptions that are obsolete and in one case conflicts with the harness. Its
entry for *they* instructs the writer away from singular *they*, which Claude Code
requires when a person's pronouns are unstated. It also prescribes *shall* by
grammatical person, calls split infinitives "in disfavor," treats *data* as
plural only, rules *different than* "not permissible", forbids *contact* and
*feature* as verbs, and includes entries for **Student Body**, **Thanking You in
Advance**, and **One hundred and one**. A file loaded to shape a commit message
must not hand the model 1918 usage law.

Twelve of its entries remain live: the needless-word set (*case*,
*character*, *factor*, *nature*, *system*, *respective*), *literally*,
*interesting*, "one of the most", and the intensifiers *very*, *certainly*, *so*.
Those move into the `SKILL.md` kill list, which is eight lines rather than 5.6k
tokens.

**`04-a-few-matters-of-form.md` (5KB) — dropped.** It is manuscript typography:
blank lines after a title "if using ruled paper," syllabication for end-of-line
word breaks, italics "indicated in manuscript by underscoring," and links to
Gutenberg page scans. The source skill's routing table advertises it as "Headings,
quotations, formatting," which is what would make an agent load it.

**`02-elementary-rules-of-usage.md` (12KB) — dropped.** Seven rules on possessive
`'s`, the serial comma, parenthetic commas, comma splices, and dangling
participles. Opus 5 follows all seven without instruction, so this is the fork's
"don't restate the system prompt" rule one level down: ~3k tokens for no change in
output. This is the least certain of the four drops — it is reasoned, not
measured. Reverse it only for a concrete need to cite Strunk by rule number.

**`01-introductory.md` (303 bytes) — dropped.** Three lines of preamble, no rules.

**`signs-of-ai-writing.md` (95KB) — distilled, not copied.** Measured by section:

| | Size | Sections |
|---|---|---|
| Applies to writing | 53KB | Regression to the Mean, Language and Grammar, Punctuation and Formatting, Communication Intended for the User |
| Does not | 41KB | Markup (14KB), Citations (8KB), Discrepancies (5KB), detection intro (5KB), Ineffective Indicators (3KB), Signs of Human Writing, Notes, References |

The 41KB is Wikipedia detection machinery: `citeturn` and `oaicite` artifacts,
DOI and ISBN validity, UTM parameters, AFC draft templates, GPTZero's error rate,
"age of text relative to ChatGPT launch."

Two parts of the remainder are actively wrong for this use. The file is a
detection guide and says so — "This list is *descriptive*, not *prescriptive*…
some signs—particularly those involving punctuation and formatting—may not apply
in a non-Wikipedia context." And its formatting section flags em dashes,
boldface, and Markdown as AI tells. Claude Code output *is* terminal Markdown, and
the skills in this library use bold and em dashes throughout, so an agent that
loads that section mid-task will strip formatting the harness relies on.

### `ai-writing-tells.md` — distillation criteria

The rewrite is a judgment-heavy editing job, so the selection rule is fixed here
rather than left to the implementer.

**Retain:**

- All of *Regression to the Mean* except "Leads treating Wikipedia lists or broad
  article titles as proper nouns."
- All of *Language and Grammar*.
- All of *Communication Intended for the User* — chatty asides, knowledge-cutoff
  disclaimers, prompt refusals leaking into output, placeholder text.
- From *Punctuation and Formatting*: title case in headings, boldface density,
  inline-header vertical lists, emoji decoration.

**Drop:** everything in the 41KB column above, plus the em-dash and
curly-quotation-mark subsections and "Subject lines."

**Transform:**

- Reframe each retained item from "this is a sign the text is AI-generated" to
  "do not write this."
- Keep every **Words to watch** list verbatim. They are the actionable payload.
- Cut each Wikipedia example gallery to a single example.
- Drop all Wikipedia-internal links and footnote markers.

**Target:** 10–12KB. A result above 14KB means the criteria were not applied.

### `SKILL.md` — content

Frontmatter: `name: writing-clearly-and-concisely`, and a `description` that
states triggering conditions only, per `writing-skills` ("Use when writing prose a
human will read — spec, plan, commit message, PR description, report, error
message, or UI text").

Body, in order:

1. **Opening, two sentences.** What this is; that the rules below are the ones
   that fight the model's defaults. No `## Overview` heading — banned by
   `writing-skills`, and the title already says it.
2. **Six operative rules, one line of before → after each.** Active voice;
   positive form; definite, specific, concrete language; omit needless words; keep
   related words together; emphatic word last. Each example rewrites a sentence of
   the kind this library actually produces, not Strunk's 1918 examples. For
   instance, under concrete language: "improves performance" → "cuts p99 latency
   from 400ms to 90ms."
3. **Kill list.** Puffery (*pivotal*, *crucial*, *vital*, *testament*, *enduring
   legacy*, *robust*, *seamless*, *groundbreaking*, *cutting-edge*); empty `-ing`
   tails (*ensuring reliability*, *showcasing*, *highlighting*, *underscoring*);
   AI vocabulary (*delve*, *leverage*, *multifaceted*, *foster*, *realm*,
   *tapestry*, *landscape*, *navigate*); the twelve live entries salvaged from
   `05`.
4. **One routing line** to the two reference files, naming when each is worth
   loading.
5. **Attribution line.** Strunk 1918 is public domain; `ai-writing-tells.md`
   derives from the Wikipedia article "Signs of AI writing" and stays under CC
   BY-SA 4.0, which the plugin's MIT license does not cover. `ai-writing-tells.md`
   carries the same attribution in its own header, because a file loaded on its own
   must carry its license with it.

**No `## When to Use This Skill` section.** The frontmatter description does the
routing, and the body loads only after routing succeeded. **No `## Bottom Line`,
no closing recap** — both banned by `writing-skills`. **No "Limited Context
Strategy"** — the source skill prescribes a subagent round-trip to avoid loading a
34KB file, which is rarely the right trade at 1M context, and the plan-time
decision belongs to `dispatching-parallel-agents` if it belongs anywhere.

Each rule appears once, in one form. `SKILL.md` must not restate a rule that
`03-elementary-principles-of-composition.md` states, beyond the one-line
summary plus example that makes it actionable without a load.

### Length is a constraint, not a preference

`SKILL.md` stays under 60 lines. When the option below is enabled it becomes the
second always-resident skill in every session, so its length is paid on every
turn of every session. The README already carries this warning for
`using-superpowers`; it now covers two files.

## The option

`SUPERPOWERS_WRITING_STYLE` gates one thing: whether `hooks/session-start` also
inlines the skill. Default off.

**Enabled** when the value, lowercased, is `1`, `true`, `yes`, or `on`. Every
other value, including unset and empty, is off.

**When enabled,** the hook emits a second block after the existing bootstrap,
using the same `escape_for_json` helper and the same single `printf`:

```
<superpowers-bootstrap>…using-superpowers/SKILL.md…</superpowers-bootstrap>
<superpowers-writing-style>
Prose you write for a human to read follows the style below. …SKILL.md verbatim…
</superpowers-writing-style>
```

**It inlines `SKILL.md` verbatim rather than a purpose-built summary card.** A card
would state the same rules a second time, and "say each rule once" is a fork
invariant. The cost is that the always-on superpowers block roughly doubles when
the option is on — which is why the length constraint above is load-bearing, and
why the default is off.

**Fail-open paths.** The hook runs under `set -euo pipefail`, and the existing
`cat` of `using-superpowers/SKILL.md` uses `2>&1 || echo` to survive a read
failure. The new read must be at least as safe:

| Condition | Behavior |
|---|---|
| Variable unset, empty, or unrecognized | No style block. Bootstrap unchanged. Exit 0. |
| Enabled, `SKILL.md` missing or unreadable | No style block. Bootstrap unchanged. Exit 0. No error text in the payload. |
| Enabled, `SKILL.md` readable | Both blocks. Valid JSON. Exit 0. |

The variable is its own kill switch, so this hook adds no second one. Output stays
a single valid JSON object in every case; a malformed payload would break session
startup, which is worse than any drift it could prevent.

The option adds no hook registration. It rides the existing `SessionStart` entry in
`hooks/hooks.json` and therefore its `startup|clear|compact` matcher, so the style
block returns after a `/clear` and after a compaction, exactly as the bootstrap
does.

## Skill wiring

The soft name-match in `brainstorming/SKILL.md:119` becomes a direct
`superpowers:writing-clearly-and-concisely` reference — the namespace no longer
varies, because the skill ships here.

| Skill | Point in its flow | Form |
|---|---|---|
| `brainstorming` | "Write the spec" | Direct reference, replaces the soft match |
| `writing-plans` | Writing the plan document | Direct reference |
| `finishing-a-development-branch` | Commit message, PR description | Direct reference |
| `writing-skills` | Writing skill prose | Direct reference, cross-linked to "Match the Form to the Failure" |
| `requesting-code-review` | The summary a human reads | One line |
| `receiving-code-review` | The summary a human reads | One line |
| `subagent-driven-development` | The final report to the user | One line |

The last three get one line, not a workflow step. Their prose is mostly
agent-to-agent; a full style pass there costs more than it returns.

Every reference is additive — a clause naming the skill at the point prose gets
written. No existing instruction is reworded, and no step is added to any
sequence.

## Testing

`tests/hooks/test-session-start.sh` already asserts payload shape through
`assert_command_output` with `contains` and `not_contains` matchers, so these are
new cases in the existing harness, not a new file:

1. Variable unset → bootstrap present, `<superpowers-writing-style>` absent, valid JSON.
2. `SUPERPOWERS_WRITING_STYLE=1` → both blocks present, valid JSON.
3. `=0` and `=maybe` → treated as off.
4. `=1` with `SKILL.md` unreadable → bootstrap intact, style block absent, exit 0,
   valid JSON.

Case 4 is the one that matters. It is the fail-open path, and it is the only case
where a bug wedges every session rather than degrading one.

The harness invokes the hook through `env -i PATH="$PATH" HOME="$home"`, which
clears the environment, so cases 2–4 must pass `SUPERPOWERS_WRITING_STYLE` on that
`env` line. Case 1 needs no change beyond the assertion: `env -i` already
guarantees the variable is unset.

### Testing obligation

`CLAUDE.md` requires micro-testing skill wording against a no-guidance control,
5+ reps, with every flagged match read by hand. This change owes that on one
thing: whether the compressed `SKILL.md` produces prose as good as the source
skill's longer form. The compression is reasoned from measured file contents, not
from behavior.

The seven wiring references are additive clauses, not changes to discipline
scaffolding, so they carry no pressure-scenario obligation. State this honestly in
the commit message; do not claim eval verification that did not happen.

## Documentation

| File | Change |
|---|---|
| `README.md:175` | "**15 skills**" → "**16 skills**". The count is a manifest-sanity check, so it must move. |
| `README.md` "Optional capabilities" | A row: `SUPERPOWERS_WRITING_STYLE=1` → inlines the style skill into every session. |
| `README.md` SessionStart section | Note that with the option on, a second skill's full text is always resident, and that the length warning now covers both files. |
| `README.md` | New section "Writing style (optional)", parallel to "Codex cross-review (optional)" and "Native task management (optional)". |
| `CLAUDE.md` | One line under Fork Invariants: the style content ships in-tree, the option gates injection only, and the skill's length is a standing constraint. |
| `RELEASE-NOTES.md` | Entry for the release. |
| `package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | `6.2.1-cc.2` → `6.2.2-cc.1` via `scripts/bump-version.sh`. |

## Commit plan

One concern per commit, in dependency order:

1. Add the skill (three files).
2. Add the option to `hooks/session-start` plus its four tests.
3. Wire the seven skill references.
4. Documentation and version bump.

Commit 2 depends on commit 1: the hook reads a file that must exist, and its
fail-open test asserts behavior when that file is unreadable.

## Verification

- `claude plugin validate .` passes.
- `tests/hooks/test-session-start.sh` passes, all cases.
- `bash hooks/session-start` with the variable unset produces a payload
  byte-identical to the current one.
- `claude plugin details superpowers@superpowers-cc` reports 16 skills, 4 agents,
  2 hooks.
- `SKILL.md` is under 60 lines; `ai-writing-tells.md` is under 14KB.
- `grep -rn "writing-clearly-and-concisely" skills/` returns the seven wired call
  sites and the skill itself — no remaining "varies by setup" hedge.
- No file in the skill directory is unreferenced by `SKILL.md`.
