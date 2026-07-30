# Writing Style in superpowers-cc Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a `writing-clearly-and-concisely` skill in this plugin, wire the six skills that author human-read prose to it, and add an opt-in session-start pointer to it.

**Architecture:** One new skill directory with a short `SKILL.md` and two reference files. `hooks/session-start` gains a constant routing pointer behind `SUPERPOWERS_WRITING_STYLE` — it injects the routing rule, never the rules themselves, so no rule is stated twice and the hook reads no additional file. Six existing skills gain a `REQUIRED SUB-SKILL` marker at the instruction where they author prose.

**Tech Stack:** Markdown skill files, bash 3.2-compatible hook script, the existing Node-based bash test harness in `tests/hooks/`.

**Spec:** `docs/superpowers/specs/2026-07-30-writing-style-in-superpowers-design.md`

## Global Constraints

- Skill directory name, used verbatim in the hook constant, all six references, and the tests: `writing-clearly-and-concisely`.
- Cross-reference form, exactly: `**REQUIRED SUB-SKILL:** Use superpowers:writing-clearly-and-concisely`. An unmarked reference is a defect per `skills/writing-skills/SKILL.md:268-271`.
- Injected block tag: `<superpowers-writing-style>` … `</superpowers-writing-style>`.
- Env var: `SUPERPOWERS_WRITING_STYLE`. Enabled only when its lowercased value is `1`, `true`, `yes`, or `on`. Everything else, including unset and empty, is off.
- `SKILL.md` frontmatter `description`: at or under 150 characters, triggering conditions and symptom keywords only, no provenance. It is injected into every session whether the skill is used or not.
- **Do not compress `SKILL.md` for token cost.** `skills/writing-skills/SKILL.md:220-224` measures body length as run-to-run noise. Compress only what repeats.
- `ai-writing-tells.md`: at or under 14336 bytes, and it keeps its CC BY-SA 4.0 header. The package is MIT (`.claude-plugin/plugin.json:11`); this one file is not.
- Hook rules from `CLAUDE.md`: fail open on every path, emit one valid JSON object always, match narrowly. The env var is the kill switch; add no second one.
- Every commit leaves the skill self-consistent: no `SKILL.md` reference to a file that does not exist yet, and no file in the directory that `SKILL.md` never mentions.
- **Exactly three files ship.** The source directory has six. Do not copy `01-introductory.md` (three lines of preamble, no rules), `02-elementary-rules-of-usage.md` (seven grammar rules Opus 5 already follows), `04-a-few-matters-of-form.md` (1918 manuscript typography — ruled paper, syllabication, underscoring for italics), or `05-words-and-expressions-commonly-misused.md` (prescribes against singular *they*, which the harness requires, plus *shall* by person, *data* as plural, and entries for **Student Body** and **Thanking You in Advance**). The spec's "Content decisions" section records the full reasoning; copying them back is a regression, not an improvement.
- The spec's commit plan lists four commits. This plan uses five: the skill splits into Task 1 (`SKILL.md` + the Strunk reference) and Task 2 (the distillation), because a reviewer can reject the 46.7KB→14KB distillation while approving the skill, and both commits leave the skill self-consistent.
- Version: release as `6.2.1-cc.4`. The leading `6.2.1` names the upstream base and does not change (`README.md:147-149`).

---

### Task 1: The skill, with the Strunk reference

**Files:**
- Create: `skills/writing-clearly-and-concisely/SKILL.md`
- Create: `skills/writing-clearly-and-concisely/elements-of-style/03-elementary-principles-of-composition.md`
- Read-only source (outside this repo, untracked): `/Users/filip.jurcicek/Projects/scratch/.claude/skills/writing-clearly-and-concisely/elements-of-style/03-elementary-principles-of-composition.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the skill directory `skills/writing-clearly-and-concisely/`, invocable as `superpowers:writing-clearly-and-concisely`. Task 2 appends one bullet and edits one line in this `SKILL.md`. Tasks 3 and 4 depend only on the directory name.

This task's `SKILL.md` mentions exactly one reference file, because `ai-writing-tells.md` does not exist until Task 2. Do not forward-reference it.

- [ ] **Step 1: Copy the Strunk section verbatim**

```bash
mkdir -p skills/writing-clearly-and-concisely/elements-of-style
cp "/Users/filip.jurcicek/Projects/scratch/.claude/skills/writing-clearly-and-concisely/elements-of-style/03-elementary-principles-of-composition.md" \
   skills/writing-clearly-and-concisely/elements-of-style/03-elementary-principles-of-composition.md
wc -c skills/writing-clearly-and-concisely/elements-of-style/03-elementary-principles-of-composition.md
```

Expected: 33622 bytes. The text is verbatim public-domain Strunk; do not edit its prose.

- [ ] **Step 2: Add the provenance header to the Strunk file**

Insert these three lines at the very top of the file, above the existing `## III. Elementary Principles Of Composition` heading, followed by a blank line:

```markdown
<!-- The Elements of Style, William Strunk Jr., 1918 — public domain.
     Section III, verbatim. Text derived from Project Gutenberg ebook #37134
     (https://www.gutenberg.org/files/37134/). -->
```

- [ ] **Step 3: Write SKILL.md**

Create `skills/writing-clearly-and-concisely/SKILL.md` with exactly this content:

```markdown
---
name: writing-clearly-and-concisely
description: Use when authoring prose a human will read — spec, plan, PR description, review summary, report, error message, UI text, docs
---

# Writing Clearly and Concisely

Six rules from Strunk's *Elements of Style*, plus the word patterns a language
model reaches for by default. These are the ones that fight the defaults; the rest
of Strunk you already follow.

## Scope

This governs prose you **author**: specs, plans, PR descriptions, review summaries,
error messages, UI text. Not conversational turns. Never rewrite a quoted string
another skill mandates — the consent question in superpowers:using-git-worktrees
and the review-gate sentence in superpowers:brainstorming are decided wording, not
drafts.

## The Six Rules

| Rule | Before → after |
|---|---|
| Use the active voice | "A retry was added by the fix" → "The fix adds a retry" |
| Put statements in positive form | "does not have any tests" → "is untested" |
| Use definite, specific, concrete language | "improves performance" → "cuts p99 latency from 400ms to 90ms" |
| Omit needless words | "in order to", "the question as to whether" → "to", "whether" |
| Keep related words together | "The hook reads the file that fails open on error" → "The hook, which fails open on error, reads the file" |
| Place the emphatic word last | "This runs at high effort, because a gate cannot think less" → "Because a gate cannot think less, this runs at high effort" |

## Do Not Write

**Puffery:** pivotal, crucial, vital, testament, enduring legacy, robust, seamless,
groundbreaking, cutting-edge.

**Empty `-ing` tails** — a clause that adds a claim instead of a fact: ensuring
reliability, showcasing X, highlighting Y, underscoring Z.

**AI vocabulary:** delve, leverage, multifaceted, foster, realm, tapestry,
landscape, navigate.

**Words that carry a condition.** The word is fine; one use of it is not.

- *case* meaning "an instance of": "in the case of a timeout" → "on timeout". "Test case" is fine.
- *character*, *nature*, *system*, *factor*, *respective* used as filler: "of a technical character" → "technical".
- *literally* propping up a metaphor.
- *interesting* as an announcement: say the thing instead.
- "one of the most" opening a paragraph.
- *very*, *certainly*, *so* as intensifiers: "so much faster" → give the number. *So* as a conjunction is fine.

## Reference

- `elements-of-style/03-elementary-principles-of-composition.md` — Strunk's full
  text on the six rules above, with his examples. Load when editing someone else's
  draft, or when a rule's boundary is unclear.

Strunk 1918 is public domain; see that file's header for provenance.
```

- [ ] **Step 4: Verify the description budget and the no-dangling-reference rule**

```bash
grep '^description:' skills/writing-clearly-and-concisely/SKILL.md | wc -c
wc -w skills/writing-clearly-and-concisely/SKILL.md
ls skills/writing-clearly-and-concisely/elements-of-style/
grep -c 'ai-writing-tells' skills/writing-clearly-and-concisely/SKILL.md
```

Expected: description line at or under 150 characters (the `wc -c` count includes the
`description: ` prefix and the trailing newline, so at or under 165 here); body
comfortably under 500 words; the Strunk file present; and `grep -c` prints `0` —
nothing references a file that does not exist yet.

- [ ] **Step 5: Verify the plugin still validates**

Run: `claude plugin validate .`
Expected: passes.

- [ ] **Step 6: Commit**

```bash
git add skills/writing-clearly-and-concisely
git commit -m "feat(skills): add writing-clearly-and-concisely with the Strunk reference

Six operative rules with before/after rewrites, a kill list whose entries carry
their defect condition rather than banning tokens, and a scope section that
exempts conversational turns and the quoted strings other skills mandate.

Description is 16th in the library's always-resident set, so it carries triggers
and keywords only."
```

---

### Task 2: The distilled AI-writing tells

**Files:**
- Create: `skills/writing-clearly-and-concisely/ai-writing-tells.md`
- Modify: `skills/writing-clearly-and-concisely/SKILL.md` — the `## Reference` section
- Read-only source (outside this repo, untracked): `/Users/filip.jurcicek/Projects/scratch/.claude/skills/writing-clearly-and-concisely/signs-of-ai-writing.md` (901 lines, 94519 bytes)

**Interfaces:**
- Consumes: `skills/writing-clearly-and-concisely/SKILL.md` from Task 1.
- Produces: `ai-writing-tells.md`, referenced by name from `SKILL.md`. No later task touches it.

The source is a Wikipedia detection guide. The output is a prescriptive writing
reference. That reframing is the work; a copy with sections deleted is not the
deliverable.

- [ ] **Step 1: Extract only the retained line ranges**

Source line ranges, verified against the source's heading map:

| Keep | Lines | What |
|---|---|---|
| ✅ | 19–168 | *Regression to the Mean*, minus its Wikipedia-lists subsection |
| ✅ | 183–316 | *Language and Grammar*, all of it, including title case in headings |
| ✅ | 319–330 | Excessive use of boldface |
| ✅ | 331–348 | Inline-header vertical lists |
| ✅ | 349–410 | Emojis |
| ✅ | 479–502 | Knowledge-cutoff disclaimers |
| ✅ | 503–514 | Prompt refusals |
| ✅ | 515–566 | Phrasal templates and placeholder text |
| ❌ | 1–18 | Detection-policy intro, G15, GPTZero |
| ❌ | 169–182 | Wikipedia lists as proper nouns |
| ❌ | 411–436 | Overuse of em dashes |
| ❌ | 437–446 | Curly quotation marks |
| ❌ | 447–458 | Subject lines |
| ❌ | 461–478 | Collaborative communication |
| ❌ | 567–901 | Markup, Citations, Discrepancies, Signs of Human Writing, Ineffective Indicators, Notes, References |

Two exclusions are load-bearing, not housekeeping:

- **Em dashes and curly quotes (411–446)** are flagged there because Wikipedia's
  manual of style forbids them. This library uses em dashes throughout, and the
  harness renders Markdown. Keeping them would have the skill tell agents to strip
  formatting the harness relies on.
- **Collaborative communication (461–478)** watches *Would you like…*, *let me
  know*, *Certainly!*. Two of those are mandated verbatim at
  `skills/using-git-worktrees/SKILL.md:51` and `skills/brainstorming/SKILL.md:140`,
  and `brainstorming` is one of the skills wired to this one in Task 4. Keeping the
  list would have the skill contradict its own caller.

Working extraction, for reference while editing:

```bash
SRC="/Users/filip.jurcicek/Projects/scratch/.claude/skills/writing-clearly-and-concisely/signs-of-ai-writing.md"
for range in 19,168 183,316 319,330 331,348 349,410 479,502 503,514 515,566; do
  sed -n "${range}p" "$SRC"
done > /tmp/retained.md
wc -c /tmp/retained.md
```

Expected: about 46730 bytes. That is the input to Step 2, not the output.

- [ ] **Step 2: Apply the transform, per subsection**

For each retained `###` subsection, the output is exactly two things:

1. Its **Words to watch** list, verbatim — except that footnote markers (`[^a]`,
   `[^8]`) are stripped. Two lists carry them, so "verbatim" without this exception
   cannot be satisfied.
2. One sentence stating the rule as a prohibition, in the imperative.

Delete everything else in the subsection: the explanatory paragraphs, every
example, every Wikipedia link, every footnote reference, the screenshots.

Worked example. The source subsection at lines 27–54 reduces to:

```markdown
### Do not inflate significance

**Words to watch:** *stands/serves as*, *is a testament/reminder*, *plays a
vital/significant/crucial/pivotal role*, *underscores/highlights its
importance/significance*, *reflects broader*, *symbolizing its ongoing/enduring/lasting
impact*, *key turning point*, *indelible mark*, *deeply rooted*, *profound heritage*,
*steadfast dedication*

Do not tell the reader that something matters; state what it does and let the fact
carry the weight.
```

Keep the source's two-level structure: `##` for the four retained groups, `###` per
subsection.

This is the one step in the plan that cannot be reduced to a mechanical edit, so it
is also the one with an explicit reviewer check: pick any three retained
subsections, open the source at their line ranges, and confirm the output kept the
watch list intact and dropped everything else. A subsection that still carries a
paragraph of explanation has not been transformed.

- [ ] **Step 3: Write the attribution header**

The file opens with this block, before any heading. Fill `<permalink>` per Step 4.

```markdown
<!-- Adapted from the Wikipedia project page "Wikipedia:Signs of AI writing"
     (https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing).
     Source copy retrieved 2026-01-31. Revision: <permalink>
     Licensed CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/).
     This file remains CC BY-SA 4.0; the rest of this plugin is MIT.
     Adapted: reframed from detection signs into prohibitions; explanatory prose,
     examples, and Wikipedia-process sections removed. -->
```

- [ ] **Step 4: Resolve the revision permalink, with a fallback**

```bash
curl -s --max-time 20 \
  "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=Wikipedia:Signs_of_AI_writing&rvlimit=1&rvprop=ids|timestamp&format=json" \
  | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8"));const p=Object.values(d.query.pages)[0];const r=p.revisions[0];console.log(`https://en.wikipedia.org/w/index.php?title=Wikipedia:Signs_of_AI_writing&oldid=${r.revid} (revision current ${r.timestamp})`)'
```

On success, paste the printed URL into `<permalink>`. On failure — no network, API
change, non-zero exit — replace the whole `Revision:` line with:

```
     Revision: not recorded; the local source copy carries no revision id.
```

Do not retry, and do not guess a revision id. CC BY-SA attribution is satisfied by
the page URL, license, and change notice; the permalink is precision, not a
requirement.

- [ ] **Step 5: Verify the budget**

```bash
wc -c skills/writing-clearly-and-concisely/ai-writing-tells.md
grep -c 'Words to watch' skills/writing-clearly-and-concisely/ai-writing-tells.md
grep -c 'en.wikipedia.org/wiki/Wikipedia:' skills/writing-clearly-and-concisely/ai-writing-tells.md
grep -c '\[\^' skills/writing-clearly-and-concisely/ai-writing-tells.md || true
```

Expected: at or under 14336 bytes; one `Words to watch` line per retained
subsection; exactly `1` Wikipedia link, the one in the attribution header; and `0`
footnote markers. Over 14336 bytes means Step 2's deletions were not applied —
cut the explanatory prose, not the watch lists.

- [ ] **Step 6: Wire it into SKILL.md**

In `skills/writing-clearly-and-concisely/SKILL.md`, replace the `## Reference`
section written in Task 1 with:

```markdown
## Reference

- `elements-of-style/03-elementary-principles-of-composition.md` — Strunk's full
  text on the six rules above, with his examples. Load when editing someone else's
  draft, or when a rule's boundary is unclear.
- `ai-writing-tells.md` — the full watch lists. Load when a draft reads generic and
  you cannot say why.

Strunk 1918 is public domain. `ai-writing-tells.md` is CC BY-SA 4.0, not MIT — see
its header.
```

- [ ] **Step 7: Verify no file is unreferenced**

```bash
for f in ai-writing-tells.md elements-of-style/03-elementary-principles-of-composition.md; do
  grep -q "$(basename "$f")" skills/writing-clearly-and-concisely/SKILL.md && echo "OK $f" || echo "UNREFERENCED $f"
done
```

Expected: `OK` for both. An unreferenced file in a skill directory is dead weight
per `CLAUDE.md`.

- [ ] **Step 8: Commit**

```bash
git add skills/writing-clearly-and-concisely
git commit -m "feat(skills): add distilled ai-writing-tells reference

Adapted from Wikipedia's 'Signs of AI writing' (CC BY-SA 4.0, retained in the
file header): 46.7KB of writing-relevant sections reduced to watch lists plus one
prohibition each, reframed from detection to prescription.

Excludes its em-dash, curly-quote, and Markdown advice, which is Wikipedia
house style and would have agents strip formatting this harness renders. Excludes
its collaborative-communication list, which watches phrasing this library mandates
verbatim at using-git-worktrees:51 and brainstorming:140."
```

---

### Task 3: The SUPERPOWERS_WRITING_STYLE option

**Files:**
- Modify: `hooks/session-start` — insert after line 27
- Modify: `tests/hooks/test-session-start.sh` — add a helper after line 120, cases after line 188

**Interfaces:**
- Consumes: the skill directory name from Task 1. Nothing else.
- Produces: the `<superpowers-writing-style>` block and the env var contract. No later task depends on it.

Tests first: the harness exists, so every case below can be written and watched to
fail before the hook changes.

- [ ] **Step 1: Add the regex-matching assert helper**

In `tests/hooks/test-session-start.sh`, insert after the closing `}` of
`assert_command_output` (after line 120):

```bash
assert_context_matches() {
    local description="$1"
    local pattern="$2"
    local home="$3"
    shift 3

    local output
    if ! output="$(env -i PATH="${PATH:-}" HOME="$home" "$@" 2>&1)"; then
        fail "$description"
        echo "    hook exited non-zero"
        echo "$output" | sed 's/^/      /'
        return
    fi

    if printf '%s' "$output" | EXPECT_PATTERN="$pattern" node -e '
const input = require("fs").readFileSync(0, "utf8");
let payload;
try {
  payload = JSON.parse(input);
} catch (error) {
  console.error(`invalid JSON: ${error.message}`);
  process.exit(1);
}
const context = payload.hookSpecificOutput && payload.hookSpecificOutput.additionalContext;
if (typeof context !== "string") {
  console.error("missing additionalContext");
  process.exit(1);
}
if (!new RegExp(process.env.EXPECT_PATTERN).test(context)) {
  console.error(`context did not match /${process.env.EXPECT_PATTERN}/`);
  console.error(`context tail was: ${JSON.stringify(context.slice(-120))}`);
  process.exit(1);
}
'; then
        pass "$description"
    else
        fail "$description"
    fi
}
```

- [ ] **Step 2: Add the failing test cases**

Insert after the `legacy_home` block (after line 188), before the `if [[ "$FAILURES" -gt 0 ]]` check:

```bash
# Writing-style pointer: off unless SUPERPOWERS_WRITING_STYLE names a truthy
# value. The pointer is a constant in the hook, so there is no file-read path to
# fail open on — only the enable predicate and the JSON shape.
style_default_home="$(make_home writing-style-default)"
assert_command_output \
    "writing-style pointer is absent by default" \
    "nested" \
    "" \
    "<superpowers-writing-style>" \
    "$style_default_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$HOOK_UNDER_TEST"

style_on_index=0
for value in 1 true yes on TRUE On; do
    style_on_index=$((style_on_index + 1))
    style_on_home="$(make_home "writing-style-on-$style_on_index")"
    assert_command_output \
        "writing-style pointer is present for SUPERPOWERS_WRITING_STYLE=$value" \
        "nested" \
        "<superpowers-writing-style>" \
        "" \
        "$style_on_home" \
        CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
        SUPERPOWERS_WRITING_STYLE="$value" \
        bash "$HOOK_UNDER_TEST"
done

style_off_index=0
for value in 0 false maybe ""; do
    style_off_index=$((style_off_index + 1))
    style_off_home="$(make_home "writing-style-off-$style_off_index")"
    assert_command_output \
        "writing-style pointer is absent for SUPERPOWERS_WRITING_STYLE='$value'" \
        "nested" \
        "" \
        "<superpowers-writing-style>" \
        "$style_off_home" \
        CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
        SUPERPOWERS_WRITING_STYLE="$value" \
        bash "$HOOK_UNDER_TEST"
done

# With the option off, the payload is the bootstrap and nothing else. This is the
# regression guard for "the default session is unchanged".
style_unchanged_home="$(make_home writing-style-unchanged)"
assert_context_matches \
    "disabled payload contains the bootstrap and nothing after it" \
    '^<superpowers-bootstrap>[\s\S]*</superpowers-bootstrap>$' \
    "$style_unchanged_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$HOOK_UNDER_TEST"

# The skill name lives in both the hook constant and the skills tree, so a rename
# can break the pointer silently.
pointer_ref="$(grep -o 'superpowers:[a-z][a-z-]*' "$HOOK_UNDER_TEST" | grep -v 'using-superpowers' | head -1)"
pointer_skill="${pointer_ref#superpowers:}"
if [[ -n "$pointer_skill" && -d "$REPO_ROOT/skills/$pointer_skill" ]]; then
    pass "writing-style pointer names an existing skill ($pointer_skill)"
else
    fail "writing-style pointer names an existing skill (got '${pointer_skill:-<none>}')"
fi
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `bash tests/hooks/test-session-start.sh`

Expected: FAILED. Specifically, the six enabled cases fail because no
`<superpowers-writing-style>` block is emitted, and the skill-name check fails
because the hook contains no `superpowers:writing-clearly-and-concisely` reference.
The default, off-value, and unchanged-payload cases should already pass — they
assert current behavior.

- [ ] **Step 4: Implement the option in the hook**

In `hooks/session-start`, insert after the `session_context=` assignment (line 27), before the output comment block:

```bash

# Optional writing-style routing pointer, off unless SUPERPOWERS_WRITING_STYLE
# names a truthy value. The pointer is a constant, so this reads no file and adds
# no failure path: an unset, empty, or unrecognized value simply emits nothing.
case "$(printf '%s' "${SUPERPOWERS_WRITING_STYLE:-}" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|on)
        writing_style_pointer="Prose you author for a human to read — a spec, a plan, a PR description, a report — goes through superpowers:writing-clearly-and-concisely. Invoke it before writing, not as a cleanup pass afterward."
        session_context="${session_context}\n<superpowers-writing-style>\n$(escape_for_json "$writing_style_pointer")\n</superpowers-writing-style>"
        ;;
esac
```

Three things this deliberately does not do: read a file, define a second kill
switch, or register a hook. It rides the existing `SessionStart` entry in
`hooks/hooks.json` and its `startup|clear|compact` matcher, so the pointer returns
after a `/clear` and after a compaction.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tests/hooks/test-session-start.sh`
Expected: `STATUS: PASSED`, with all twelve new assertions passing.

- [ ] **Step 6: Verify both paths by eye**

```bash
CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/session-start | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(JSON.stringify(d.hookSpecificOutput.additionalContext.slice(-80)))'
SUPERPOWERS_WRITING_STYLE=1 CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/session-start | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(JSON.stringify(d.hookSpecificOutput.additionalContext.slice(-260)))'
```

Expected: the first ends at `</superpowers-bootstrap>`; the second ends at
`</superpowers-writing-style>` and contains the pointer sentence with its em
dashes intact.

- [ ] **Step 7: Run the full hook test suite**

```bash
bash tests/hooks/test-session-start.sh
bash tests/hooks/test-pre-agent-effort-pin.sh
bash tests/hooks/test-pre-taskupdate-user-gate.sh
bash scripts/lint-shell.sh
```

Expected: all pass. `lint-shell.sh` covers the hook you just edited.

- [ ] **Step 8: Commit**

```bash
git add hooks/session-start tests/hooks/test-session-start.sh
git commit -m "feat(hooks): add SUPERPOWERS_WRITING_STYLE routing pointer

Injects a ~35-word pointer to superpowers:writing-clearly-and-concisely, not the
rules themselves: the rules stay in the skill body, which costs nothing until
invoked, and no rule ends up stated twice.

The pointer is a string constant, so the option reads no file and adds no
fail-open path. Twelve new assertions cover the enable predicate (1/true/yes/on,
case-insensitive), the negative values, that the default payload is the bootstrap
and nothing else, and that the skill the pointer names exists."
```

---

### Task 4: Wire the six call sites

**Files:**
- Modify: `skills/brainstorming/SKILL.md:118-121`
- Modify: `skills/writing-plans/SKILL.md:14-15`
- Modify: `skills/finishing-a-development-branch/SKILL.md:140-143`
- Modify: `skills/writing-skills/SKILL.md:86`
- Modify: `skills/requesting-code-review/SKILL.md:63-66`
- Modify: `skills/receiving-code-review/SKILL.md:19`

**Interfaces:**
- Consumes: the skill name from Task 1.
- Produces: six `REQUIRED SUB-SKILL` markers. Task 5's README grep count depends on there being exactly six.

Each edit attaches a marker to an instruction that already exists. Add no step to
any sequence, and change no existing instruction's meaning. `subagent-driven-development`
is deliberately not on this list: its Finish step delegates to
`finishing-a-development-branch` and authors no prose of its own.

- [ ] **Step 1: brainstorming — the spec**

Replace lines 118-121:

```markdown
**Write the spec** to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` (user
preferences for location override this). If a `writing-clearly-and-concisely`
skill appears in your skill list, use it — the namespace it ships under varies by
setup, so match on the name. Commit the spec.
```

with:

```markdown
**Write the spec** to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` (user
preferences for location override this). **REQUIRED SUB-SKILL:** Use
superpowers:writing-clearly-and-concisely. Commit the spec.
```

The hedge goes because the namespace no longer varies — the skill ships here.

- [ ] **Step 2: writing-plans — the plan document**

After line 15 (`- (User preferences for plan location override this default)`), insert a blank line and:

```markdown
**REQUIRED SUB-SKILL:** Use superpowers:writing-clearly-and-concisely for the
plan's prose — its goal, architecture, and step descriptions are read by a human.
```

- [ ] **Step 3: finishing-a-development-branch — the PR description**

Replace lines 140-143:

```markdown
Then create the pull/merge request against <base-branch> with the forge's
tooling — its CLI if one is available, or the creation URL most forges
print when you push — following the repo's PR template and conventions if
present, and report the URL to the user.
```

with:

```markdown
Then create the pull/merge request against <base-branch> with the forge's
tooling — its CLI if one is available, or the creation URL most forges
print when you push — following the repo's PR template and conventions if
present, and report the URL to the user. **REQUIRED SUB-SKILL:** Use
superpowers:writing-clearly-and-concisely for the PR description.
```

- [ ] **Step 4: writing-skills — skill prose**

Line 86 currently begins the body guidance:

```markdown
**Body:** there is no fixed section list. Write the sections this skill's failure
modes need and nothing else. Only two are load-bearing everywhere:
```

Insert a blank line and this paragraph immediately before it:

```markdown
**REQUIRED SUB-SKILL:** Use superpowers:writing-clearly-and-concisely for the
prose itself. It governs the sentences; Match the Form to the Failure below
governs which sections exist.
```

- [ ] **Step 5: requesting-code-review — relaying findings**

Append to the paragraph at lines 63-66, after "rank by severity.":

```markdown
**REQUIRED SUB-SKILL:** Use
superpowers:writing-clearly-and-concisely for the relay.
```

- [ ] **Step 6: receiving-code-review — the response**

Replace line 19:

```markdown
5. **Respond** with a technical acknowledgment or reasoned pushback.
```

with:

```markdown
5. **Respond** with a technical acknowledgment or reasoned pushback. **REQUIRED
   SUB-SKILL:** Use superpowers:writing-clearly-and-concisely.
```

- [ ] **Step 7: Verify the count and the removed hedge**

```bash
grep -rn 'REQUIRED SUB-SKILL:\*\* Use$\|REQUIRED SUB-SKILL:\*\* Use superpowers:writing-clearly-and-concisely' skills/ | wc -l
grep -rn 'writing-clearly-and-concisely' skills/ | grep -v '^skills/writing-clearly-and-concisely/' | wc -l
grep -rn 'varies by setup' skills/ || echo "hedge removed"
grep -rn 'writing-clearly-and-concisely' skills/subagent-driven-development/ || echo "sdd correctly unwired"
```

Expected: six references outside the skill's own directory; `hedge removed`; `sdd
correctly unwired`. The first grep tolerates the two places where the marker wraps
across lines.

- [ ] **Step 8: Verify nothing else changed**

Run: `git diff --stat`
Expected: six files, and the insertions are markers only — no line of existing
instruction rewritten beyond the brainstorming hedge replacement.

- [ ] **Step 9: Commit**

```bash
git add skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md \
        skills/finishing-a-development-branch/SKILL.md skills/writing-skills/SKILL.md \
        skills/requesting-code-review/SKILL.md skills/receiving-code-review/SKILL.md
git commit -m "feat(skills): wire six prose-authoring call sites to the style skill

Each site gets a REQUIRED SUB-SKILL marker on an instruction that already exists:
the spec, the plan, the PR description, skill prose, the findings relay, and the
review response. brainstorming loses its 'varies by setup' hedge — the namespace
no longer varies.

subagent-driven-development is not wired: its Finish step delegates to
finishing-a-development-branch and authors no prose of its own. Commit messages
are not wired either; nothing in this library instructs an agent to author one.

UNMEASURED: these are additive markers, not discipline scaffolding, so no
pressure scenario was run. The micro-test the spec owes covers the skill's own
wording, not these references."
```

---

### Task 5: Documentation and release

**Files:**
- Modify: `README.md:175`, `README.md:196`, `README.md:213-229`, and a new section before line 261
- Modify: `CLAUDE.md` — after the "Native tasks are optional" paragraph at line 71
- Modify: `RELEASE-NOTES.md` — new section after line 1
- Modify: `package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` via script

**Interfaces:**
- Consumes: everything from Tasks 1-4.
- Produces: the released state.

- [ ] **Step 1: Fix the skill count**

In `README.md:175`, change `**15 skills**` to `**16 skills**`. That count is used as
a manifest-sanity check, so a stale number reads as a broken manifest.

- [ ] **Step 2: Add the optional-capabilities row**

After `README.md:196` (the `Native task management` row), add:

```markdown
| Writing style pointer | `SUPERPOWERS_WRITING_STYLE=1` | Adds a ~35-word pointer to `writing-clearly-and-concisely` to every session's context. Also accepts `true`, `yes`, `on`. The skill's rules are not injected — the pointer routes to them |
```

- [ ] **Step 3: Extend the SessionStart section**

In the `### SessionStart` section (lines 213-229), after the two "Two consequences worth knowing" bullets, add:

```markdown
With `SUPERPOWERS_WRITING_STYLE` enabled, a second block follows the bootstrap: a
~35-word pointer to `writing-clearly-and-concisely`. The pointer is a constant in
the hook, not a file read, and the skill's **body is not resident** — so
`using-superpowers` remains the only skill whose full text is always in context,
and the warning above still names one file.
```

- [ ] **Step 4: Add the Writing style section**

Immediately before `## The Basic Workflow` (line 261), add:

```markdown
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
```

- [ ] **Step 5: Add the fork invariant**

In `CLAUDE.md`, after the "Native tasks are optional, the ledger is not." paragraph (line 71 and its continuation), add:

```markdown
**The writing style ships in-tree, and the option is a pointer.** Strunk's rules
live in `skills/writing-clearly-and-concisely/`, and six skills invoke it with
`REQUIRED SUB-SKILL` markers where they author prose. `SUPERPOWERS_WRITING_STYLE`
injects a routing pointer to that skill — never the rules themselves. Injecting the
rules would put the same text in the hook and in `SKILL.md`, two copies drifting
apart, against "say each rule once" below. Do not compress that `SKILL.md` for
token cost either; body length is measured noise.
```

- [ ] **Step 6: Add the release notes entry**

After `# Superpowers Release Notes` (line 1), insert:

```markdown

## v6.2.1-cc.4 (2026-07-30)

First release-notes entry for a `-cc` fork revision; earlier ones were not logged.

### Writing style

- **`writing-clearly-and-concisely` ships with the plugin.** Six operative rules from Strunk's *Elements of Style* with before/after rewrites, plus a kill list whose entries carry their defect condition rather than banning tokens. Six skills now invoke it with `REQUIRED SUB-SKILL` markers where they author prose a human reads: the spec, the plan, the PR description, skill prose, the findings relay, and the review response. `brainstorming` loses the "namespace varies by setup" hedge it carried while the skill was external.
- **`SUPERPOWERS_WRITING_STYLE=1` adds a routing pointer to every session**, off by default. It injects the pointer, not the rules; the hook reads no file, so the option adds no fail-open path. Twelve new assertions in `tests/hooks/test-session-start.sh` cover the enable predicate, the negative values, and that the default payload is the bootstrap and nothing else.
- **Two reference files, not five.** The source skill's word-list section prescribed against singular *they*, which the harness requires; its "matters of form" section was 1918 manuscript typography; its seven grammar rules are ones Opus 5 already follows. `ai-writing-tells.md` distills 46.7KB of Wikipedia's "Signs of AI writing" into watch lists plus one prohibition each, dropping that guide's em-dash, curly-quote, and Markdown advice — Wikipedia house style that would have agents strip formatting this harness renders. It stays CC BY-SA 4.0; the package remains MIT.

**UNMEASURED:** the skill's wording has not been micro-tested against a no-guidance control. The plan's rubric for that is in `docs/superpowers/plans/2026-07-30-writing-style-in-superpowers.md`.
```

- [ ] **Step 7: Bump the version**

```bash
bash scripts/bump-version.sh 6.2.1-cc.4
bash scripts/bump-version.sh --audit
```

Expected: three files updated; the audit reports no stragglers. The leading `6.2.1`
stays — it names the upstream base, and nothing here adopts a new upstream.

- [ ] **Step 8: Verify the manifests and the whole suite**

```bash
claude plugin validate .
bash tests/hooks/test-session-start.sh
bash scripts/lint-shell.sh
claude plugin details superpowers@superpowers-cc
```

Expected: validate passes; tests pass; `details` reports **16 skills**, 4 agents, 2
hooks. Read the always-on and on-invoke numbers it prints for the new skill and
record them in the commit message — `README.md:174-179` treats those counts as the
manifest check, and the description's always-on cost is the number worth knowing.

- [ ] **Step 9: Commit**

```bash
git add README.md CLAUDE.md RELEASE-NOTES.md package.json .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "docs(release): 6.2.1-cc.4 — writing style in-tree

README gains the optional-capabilities row, the SessionStart consequence, and a
Writing style section stating the CC BY-SA boundary. Skill count 15 -> 16.
CLAUDE.md records the invariant: the option is a pointer, and injecting the rules
would mean two drifting copies.

Version stays on the 6.2.1 upstream base per the fork's convention."
```

---

## Micro-test obligation

`CLAUDE.md` requires behavior-shaping wording to be micro-tested against a
no-guidance control before it is trusted. This plan ships the skill; it does not
discharge that obligation. Run it as follow-up work, before relying on the skill
under pressure:

- **Arms:** no-guidance control; the source skill's longer `SKILL.md` verbatim; the
  shipped `SKILL.md`.
- **Prompts:** three, one per output kind — a spec paragraph describing a design
  decision, a PR description for a two-commit change, a review summary of three
  findings.
- **Reps:** 5 per arm per prompt.
- **Flagged match**, counted by hand per rep: a kill-list hit in its defect
  condition; a passive construction where an actor exists; a hedge that adds no
  information; a puffery adjective.
- **Bar:** the shipped arm is at or below the source arm on every prompt, and both
  are clearly below the control. A shipped arm that regresses against the source
  means the compression removed something load-bearing — restore it.
