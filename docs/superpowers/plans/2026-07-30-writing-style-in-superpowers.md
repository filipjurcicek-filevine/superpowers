# Writing Style in superpowers-cc Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a `writing-clearly-and-concisely` skill in this plugin, wire the six skills that author human-read prose to it, and add an opt-in session-start pointer to it.

**Architecture:** One new skill directory with a short `SKILL.md` and two reference files. `hooks/session-start` gains a constant routing pointer behind `SUPERPOWERS_WRITING_STYLE` — it injects the routing rule, never the rules themselves, so no rule is stated twice and the hook reads no additional file. Six existing skills gain a `REQUIRED SUB-SKILL` marker at the instruction where they author prose. Task 5 micro-tests the skill's wording before Task 6 releases it.

**Tech Stack:** Markdown skill files, bash 3.2-compatible hook script, the existing Node-based bash test harness in `tests/hooks/`, the Agent tool for the micro-test dispatches.

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
- **Exactly three files ship.** The source directory has six. Do not copy `01-introductory.md` (three lines of preamble, no rules), `02-elementary-rules-of-usage.md` (seven grammar rules Opus 5 already follows), `04-a-few-matters-of-form.md` (1918 manuscript typography — ruled paper, syllabication, underscoring for italics), or `05-words-and-expressions-commonly-misused.md` (prescribes against singular *they*, which the harness requires, plus *shall* by person, *data* as plural, and entries for **Student Body** and **Thanking You in Advance**). The spec's "Content decisions" records the reasoning; copying them back is a regression.
- Version: release as `6.2.1-cc.4`. The leading `6.2.1` names the upstream base and does not change (`README.md:147-149`).
- The spec's commit plan lists four commits. This plan uses six: the skill splits into Task 1 (`SKILL.md` + Strunk) and Task 2 (the distillation) because a reviewer can reject the 44KB→14KB distillation while approving the skill, and the micro-test the spec requires is its own task because it can send work back to Task 1.

---

### Task 1: The skill, with the Strunk reference

**Files:**
- Create: `skills/writing-clearly-and-concisely/SKILL.md`
- Create: `skills/writing-clearly-and-concisely/elements-of-style/03-elementary-principles-of-composition.md`
- Read-only source (outside this repo, untracked): `/Users/filip.jurcicek/Projects/scratch/.claude/skills/writing-clearly-and-concisely/elements-of-style/03-elementary-principles-of-composition.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the skill directory `skills/writing-clearly-and-concisely/`, invocable as `superpowers:writing-clearly-and-concisely`. Task 2 appends one bullet and edits the `## Reference` section of this `SKILL.md`. Tasks 3, 4, and 5 depend only on the directory name and this file's body text.

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
grep -c 'ai-writing-tells' skills/writing-clearly-and-concisely/SKILL.md || true
```

Expected: the description line at or under 165 bytes — that count includes the
`description: ` prefix, a trailing newline, and an em dash that costs 3 bytes, so
the 150-character constraint holds; body under 500 words; the Strunk file present;
and `grep -c` prints `0`, because nothing may reference a file that does not exist
yet.

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
and keywords only. Wording is micro-tested in a later commit on this branch."
```

---

### Task 2: The distilled AI-writing tells

**Files:**
- Create: `skills/writing-clearly-and-concisely/ai-writing-tells.md`
- Modify: `skills/writing-clearly-and-concisely/SKILL.md` — the `## Reference` section
- Read-only source (outside this repo, untracked): `/Users/filip.jurcicek/Projects/scratch/.claude/skills/writing-clearly-and-concisely/signs-of-ai-writing.md` — 901 lines, 94,774 bytes

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
wc -l -c /tmp/retained.md
```

Expected: exactly 464 lines, 44107 bytes. That is the input to Step 2, not the output.

- [ ] **Step 2: Rename all 21 headings to imperative prohibitions**

Every retained `###` heading is rewritten. The mapping is fixed — do not improvise
one, and do not leave a source heading in place:

| Source line | Source heading | New heading |
|---|---|---|
| 27 | Undue emphasis on symbolism, legacy, and importance | Do not inflate significance |
| 55 | Undue emphasis on notability, attribution, and media coverage | Do not certify importance by citation |
| 83 | Superficial analyses | Do not analyze without saying anything |
| 105 | Promotional and advertisement-like language | Do not sell |
| 123 | Didactic, editorializing disclaimers | Do not lecture the reader |
| 137 | Summaries and conclusions | Do not append a summary that adds nothing |
| 147 | Outline-like conclusions about challenges and future prospects | Do not close with challenges and future prospects |
| 185 | Overused "AI vocabulary" words | Do not use AI vocabulary |
| 205 | Negative parallelisms | Do not write "not just X, but Y" |
| 219 | Outlines of negatives | Do not define a thing by what it is not |
| 247 | Rule of three | Do not force triples |
| 255 | Vague attributions of opinion | Do not attribute opinions vaguely |
| 271 | Excessive synonym variance / elegant variation | Do not vary a term for variety's sake |
| 285 | False ranges | Do not write false ranges |
| 297 | Title case in section headings | Do not use title case in headings |
| 319 | Excessive use of boldface | Do not bold for emphasis |
| 331 | Inline-header vertical lists | Do not write inline-header bullet lists |
| 349 | Emojis | Do not decorate with emoji |
| 479 | Knowledge-cutoff disclaimers and speculation about gaps in sources | Do not hedge about your knowledge cutoff |
| 503 | Prompt refusals | Do not leak refusal language |
| 515 | Phrasal templates and placeholder text | Do not ship placeholder text |

Keep the source's two-level structure: `##` for the four retained groups, `###` per
subsection, in source order.

- [ ] **Step 3: Reduce each subsection to at most three things**

Per subsection, the output is:

1. The new heading from Step 2.
2. Its **Words to watch** list, verbatim, with footnote markers (`[^a]`, `[^8]`)
   stripped — two lists carry them. **Eleven of the 21 subsections have such a
   list; the other ten do not. Invent none.**
3. One sentence stating the rule as a prohibition, in the imperative.

Delete everything else in the subsection: the explanatory paragraphs, every
example, every Wikipedia link, every footnote reference, the screenshots.

Worked example — source lines 27–54 reduce to:

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

Worked example of a subsection with no watch list — source lines 205–218 reduce to:

```markdown
### Do not write "not just X, but Y"

Do not build a sentence on the negation of a smaller claim — "it is not just a
refactor, it is a rethink" — because the negated half is filler.
```

This is the one step in the plan that is not a mechanical edit, so it carries an
explicit reviewer check: pick any three subsections, open the source at their line
ranges, and confirm the output kept the watch list intact where one exists and
dropped everything else. A subsection that still carries a paragraph of explanation
has not been transformed.

- [ ] **Step 4: Resolve the revision permalink for the retrieval date**

The local source copy was retrieved 2026-01-31. The permalink must name the revision
current **on that date**, not the latest one:

```bash
curl -s --max-time 20 \
  "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=Wikipedia:Signs_of_AI_writing&rvlimit=1&rvdir=older&rvstart=2026-01-31T23:59:59Z&rvprop=ids|timestamp&format=json" \
  | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8"));const p=Object.values(d.query.pages)[0];const r=p.revisions[0];console.log(`https://en.wikipedia.org/w/index.php?title=Wikipedia:Signs_of_AI_writing&oldid=${r.revid} (revision of ${r.timestamp})`)'
```

Expected: a URL whose timestamp is on or before 2026-01-31. Paste it into the
`Revision:` line in Step 5.

On failure — no network, API change, non-zero exit, or a timestamp after
2026-01-31 — replace the whole `Revision:` line with:

```
     Revision: not resolved; the local source copy carries no revision id.
```

Do not retry, and do not substitute the latest revision: naming a revision the text
did not come from is worse than naming none. CC BY-SA attribution is satisfied by
the page URL, the license, and the change notice.

- [ ] **Step 5: Write the attribution header**

The file opens with this block, before any heading, with `<permalink>` replaced per Step 4:

```markdown
<!-- Adapted from the Wikipedia project page "Wikipedia:Signs of AI writing"
     (https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing).
     Source copy retrieved 2026-01-31.
     Revision: <permalink>
     Licensed CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/).
     This file remains CC BY-SA 4.0; the rest of this plugin is MIT.
     Adapted: reframed from detection signs into prohibitions; explanatory prose,
     examples, and Wikipedia-process sections removed. -->
```

- [ ] **Step 6: Verify the budget and the counts**

```bash
F=skills/writing-clearly-and-concisely/ai-writing-tells.md
wc -c "$F"
grep -c '^### ' "$F"
grep -c 'Words to watch' "$F"
grep -c 'en.wikipedia.org/wiki/Wikipedia:' "$F"
grep -c '\[\^' "$F" || true
grep -c '^### Do not ' "$F"
```

Expected, in order: at or under 14336 bytes; `21` subsections; `11` watch lists;
`1` Wikipedia link, the one in the header; `0` footnote markers; and `21` headings
beginning "Do not " — every heading renamed. Over 14336 bytes means Step 3's
deletions were not applied; cut the explanatory prose, never the watch lists.

- [ ] **Step 7: Wire it into SKILL.md**

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

- [ ] **Step 8: Verify no file is unreferenced**

```bash
for f in ai-writing-tells.md 03-elementary-principles-of-composition.md; do
  grep -q "$f" skills/writing-clearly-and-concisely/SKILL.md && echo "OK $f" || echo "UNREFERENCED $f"
done
```

Expected: `OK` for both. An unreferenced file in a skill directory is dead weight
per `CLAUDE.md`.

- [ ] **Step 9: Commit**

```bash
git add skills/writing-clearly-and-concisely
git commit -m "feat(skills): add distilled ai-writing-tells reference

Adapted from Wikipedia's 'Signs of AI writing' (CC BY-SA 4.0, attribution and
change notice in the file header): 44,107 bytes of writing-relevant sections
reduced to 21 imperative headings, the 11 watch lists that exist, and one
prohibition each.

Excludes its em-dash, curly-quote, and Markdown advice, which is Wikipedia house
style and would have agents strip formatting this harness renders. Excludes its
collaborative-communication list, which watches phrasing this library mandates
verbatim at using-git-worktrees:51 and brainstorming:140."
```

---

### Task 3: The SUPERPOWERS_WRITING_STYLE option

**Files:**
- Modify: `hooks/session-start` — insert after line 27
- Modify: `tests/hooks/test-session-start.sh` — add a helper after line 120, cases after line 188

**Interfaces:**
- Consumes: the skill directory name from Task 1. Nothing else.
- Produces: the `<superpowers-writing-style>` block and the env var contract. Task 6's release notes cite the assertion count, which is 13.

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
  console.error(`context tail was: ${JSON.stringify(context.slice(-160))}`);
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

Insert after the `legacy_home` block (after line 188), before the `if [[ "$FAILURES" -gt 0 ]]` check. Thirteen assertions:

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

# Enabled: assert BOTH blocks, in order. Asserting only the style block would pass
# a hook that replaced the bootstrap instead of appending to it.
style_on_index=0
for value in 1 true yes on TRUE On; do
    style_on_index=$((style_on_index + 1))
    style_on_home="$(make_home "writing-style-on-$style_on_index")"
    assert_context_matches \
        "both blocks present, in order, for SUPERPOWERS_WRITING_STYLE=$value" \
        '^<superpowers-bootstrap>[\s\S]*</superpowers-bootstrap>\n<superpowers-writing-style>[\s\S]*writing-clearly-and-concisely[\s\S]*</superpowers-writing-style>$' \
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
# can break the pointer silently. `|| true` is required: with pipefail set, the
# grep finds nothing during the RED run and would abort the suite before it
# reports.
pointer_ref="$(grep -o 'superpowers:[a-z][a-z-]*' "$HOOK_UNDER_TEST" | grep -v 'using-superpowers' | head -1 || true)"
pointer_skill="${pointer_ref#superpowers:}"
if [[ -n "$pointer_skill" && -d "$REPO_ROOT/skills/$pointer_skill" ]]; then
    pass "writing-style pointer names an existing skill ($pointer_skill)"
else
    fail "writing-style pointer names an existing skill (got '${pointer_skill:-<none>}')"
fi
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `bash tests/hooks/test-session-start.sh`

Expected: `STATUS: FAILED (7 failure(s))`. The six enabled cases fail because no
`<superpowers-writing-style>` block is emitted, and the skill-name check fails
because the hook contains no `superpowers:writing-clearly-and-concisely` reference.
The default, off-value, and unchanged-payload cases pass already — they assert
current behavior. If the suite aborts instead of printing `STATUS: FAILED`, the
`|| true` in the `pointer_ref` assignment is missing.

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
Expected: `STATUS: PASSED`, with all thirteen new assertions passing.

- [ ] **Step 6: Verify both paths by eye**

```bash
CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/session-start | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(JSON.stringify(d.hookSpecificOutput.additionalContext.slice(-80)))'
SUPERPOWERS_WRITING_STYLE=1 CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/session-start | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(JSON.stringify(d.hookSpecificOutput.additionalContext.slice(-260)))'
```

Expected: the first ends at `</superpowers-bootstrap>`; the second ends at
`</superpowers-writing-style>` and contains the pointer sentence with its em
dashes intact.

- [ ] **Step 7: Run the full hook suite and the shell linter**

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
fail-open path. Thirteen new assertions cover the enable predicate
(1/true/yes/on, case-insensitive), the negative values, that an enabled session
carries both blocks in order, that the default payload is the bootstrap and
nothing else, and that the skill the pointer names exists."
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
- Produces: `REQUIRED SUB-SKILL` markers in exactly those six files. Task 6's README prose depends on the count being six.

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

Insert this paragraph immediately before it, followed by a blank line:

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

- [ ] **Step 7: Verify the six files, the marker, and the removed hedge**

Two of the six markers wrap across lines, so count files rather than matching a
single-line pattern:

```bash
for f in brainstorming writing-plans finishing-a-development-branch writing-skills \
         requesting-code-review receiving-code-review; do
  if grep -q 'superpowers:writing-clearly-and-concisely' "skills/$f/SKILL.md" \
     && grep -q 'REQUIRED SUB-SKILL' "skills/$f/SKILL.md"; then
    echo "OK   $f"
  else
    echo "MISS $f"
  fi
done
grep -rl 'superpowers:writing-clearly-and-concisely' skills/ \
  | grep -v '^skills/writing-clearly-and-concisely/' | wc -l
grep -rn 'varies by setup' skills/ || echo "hedge removed"
grep -rn 'writing-clearly-and-concisely' skills/subagent-driven-development/ || echo "sdd correctly unwired"
```

Expected: six `OK` lines, the count `6`, `hedge removed`, and `sdd correctly
unwired`. Any `MISS` means that file's marker or its skill reference is absent.

- [ ] **Step 8: Verify nothing else changed**

Run: `git diff --stat`
Expected: six files. The insertions are markers only — no existing instruction
rewritten except the brainstorming hedge replacement in Step 1.

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
pressure scenario was run."
```

---

### Task 5: Micro-test the skill's wording

**Files:**
- Create: `/tmp/microtest/` — scratch only, committed nowhere
- Modify (only if the bar fails): `skills/writing-clearly-and-concisely/SKILL.md`
- Read-only: `/Users/filip.jurcicek/Projects/scratch/.claude/skills/writing-clearly-and-concisely/SKILL.md` — the source form, arm B

**Interfaces:**
- Consumes: the shipped `SKILL.md` from Tasks 1-2.
- Produces: a tally table and a verdict. Task 6's release-notes entry states the result, so this task must finish before it.

`CLAUDE.md` requires behavior-shaping wording to be micro-tested against a
no-guidance control, 5+ reps, every flagged match read by hand. This task
discharges that. It answers one question: does the shipped `SKILL.md` produce
prose at least as clean as the source skill's longer form?

- [ ] **Step 1: Write the three arm prefixes**

```bash
mkdir -p /tmp/microtest
: > /tmp/microtest/arm-a-control.txt
cp "/Users/filip.jurcicek/Projects/scratch/.claude/skills/writing-clearly-and-concisely/SKILL.md" /tmp/microtest/arm-b-source.txt
cp skills/writing-clearly-and-concisely/SKILL.md /tmp/microtest/arm-c-shipped.txt
wc -c /tmp/microtest/arm-*.txt
```

Arm A is empty by design — it is the no-guidance control.

- [ ] **Step 2: Write the three prompts**

```bash
cat > /tmp/microtest/prompt-1-spec.txt <<'EOF'
Write one paragraph for a design spec explaining why a session-start hook injects a
routing pointer to a skill instead of the skill's full text. Prose only, no headings.
EOF
cat > /tmp/microtest/prompt-2-pr.txt <<'EOF'
Write a PR description for a two-commit change that adds an opt-in environment
variable to a shell hook and its test cases. Prose only, no headings.
EOF
cat > /tmp/microtest/prompt-3-review.txt <<'EOF'
Write a review summary reporting three findings to a colleague: a missing test case,
a stale byte count in a doc, and a grep whose regex does not match what it claims.
Prose only, no headings.
EOF
```

- [ ] **Step 3: Run 45 dispatches**

**This task runs in the controller session, not in an implementer subagent** — it
dispatches 45 agents, and nested dispatch is not reliably available to a subagent.
It is measurement, not implementation.

For each arm (A, B, C) × prompt (1, 2, 3) × rep (1-5), dispatch one `Agent`
(`subagent_type: general-purpose`) whose prompt is the arm prefix file's contents
followed by the prompt file's contents, plus this instruction:

> Write your answer to `/tmp/microtest/<arm>-<prompt>-<rep>.md` and reply with the
> single word `done`. Do not print the prose in your reply.

Having each agent write its own file keeps 45 prose samples out of the controller's
context, which is the whole reason artifacts move by file in this skill. For arm A,
send the prompt with no prefix. Dispatch the five reps of one arm+prompt cell
concurrently; never reuse an agent across cells, and never let one dispatch see
another's output.

```bash
ls /tmp/microtest/*.md | wc -l   # 45
```

- [ ] **Step 4: First-pass flag with grep, then read every hit by hand**

```bash
cd /tmp/microtest
grep -n -i -E 'pivotal|crucial|vital|testament|enduring|robust|seamless|groundbreaking|cutting-edge|delve|leverage|multifaceted|foster|realm|tapestry|landscape|navigate|ensuring |showcasing|highlighting|underscoring|one of the most|literally|very |certainly |in order to' *.md > flagged.txt
wc -l flagged.txt
```

The grep is a first pass, not the count. Read each hit and keep only real defects —
`leverage` as a noun in "leverage ratio" is not a hit; *system* in "the hook system"
is not a hit. Then read every file for the three patterns grep cannot see: a passive
construction where an actor exists, a hedge that adds no information, and a claim
where a fact belongs.

- [ ] **Step 5: Fill the tally**

| Arm | prompt-1 | prompt-2 | prompt-3 | total |
|---|---|---|---|---|
| A — control | | | | |
| B — source form | | | | |
| C — shipped | | | | |

Each cell is flagged matches summed across that cell's 5 reps.

- [ ] **Step 6: Apply the bar**

- **C ≤ B on every prompt, and both clearly below A** → the compression held. Record
  the table and continue to Task 6.
- **C > B on any prompt** → the cut removed something load-bearing. Diff arm B's
  `SKILL.md` against arm C's, restore the guidance the regressed prompt needed, and
  re-run Steps 3-5 for that prompt only. Commit the restoration before Task 6.
- **A ≤ C** → the skill is not earning its place. Stop and report to the user
  rather than releasing it; this is a design question, not a wording fix.

- [ ] **Step 7: Record the result**

Write the filled table and the verdict into the commit message. If Step 6 required a
restoration:

```bash
git add skills/writing-clearly-and-concisely/SKILL.md
git commit -m "fix(skills): restore <what> after micro-test regression

Arm C regressed against arm B on prompt <n> (<count> vs <count> flagged matches
over 5 reps). Restored <what> and re-ran that prompt: <new counts>."
```

If no restoration was needed, there is nothing to commit — carry the table into
Task 6's release notes.

---

### Task 6: Documentation and release

**Files:**
- Modify: `README.md:175`, `README.md:196`, `README.md:219`, `README.md:213-229`, and a new section before line 261
- Modify: `CLAUDE.md` — after the "Native tasks are optional" paragraph at line 71
- Modify: `RELEASE-NOTES.md` — new section after line 1
- Modify: `package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` via script

**Interfaces:**
- Consumes: everything from Tasks 1-5, including Task 5's tally.
- Produces: the released state.

- [ ] **Step 1: Fix the skill count in both places**

`README.md:175`: `**15 skills**` → `**16 skills**`. That count is a
manifest-sanity check, so a stale number reads as a broken manifest.

`README.md:219`: the SessionStart section says "without it the other fourteen
skills are installed but nothing routes to them" → "the other fifteen skills".

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

- [ ] **Step 4b: Note the license exception in LICENSE**

`LICENSE` declares the repository MIT with no exception, while
`skills/writing-clearly-and-concisely/ai-writing-tells.md` is CC BY-SA 4.0. The
file header and the README section state that boundary; the LICENSE file is where a
packager looks first. Append to `LICENSE`:

```
---

Exception: skills/writing-clearly-and-concisely/ai-writing-tells.md is adapted
from Wikipedia and licensed CC BY-SA 4.0, not MIT. See that file's header for
attribution and the change notice.
```

Task 2's reviewer raised this as a branch-level packaging gap; it is recorded here
rather than in Task 2 because LICENSE is a release artifact.

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

After `# Superpowers Release Notes` (line 1), insert the block below. Replace
`<tally>` with Task 5's filled table and `<verdict>` with its one-line result.

```markdown

## v6.2.1-cc.4 (2026-07-30)

First release-notes entry for a `-cc` fork revision; earlier ones were not logged.

### Writing style

- **`writing-clearly-and-concisely` ships with the plugin.** Six operative rules from Strunk's *Elements of Style* with before/after rewrites, plus a kill list whose entries carry their defect condition rather than banning tokens. Six skills now invoke it with `REQUIRED SUB-SKILL` markers where they author prose a human reads: the spec, the plan, the PR description, skill prose, the findings relay, and the review response. `brainstorming` loses the "namespace varies by setup" hedge it carried while the skill was external.
- **`SUPERPOWERS_WRITING_STYLE=1` adds a routing pointer to every session**, off by default. It injects the pointer, not the rules; the hook reads no file, so the option adds no fail-open path. Thirteen new assertions in `tests/hooks/test-session-start.sh` cover the enable predicate, the negative values, that an enabled session carries both blocks in order, and that the default payload is the bootstrap and nothing else.
- **Two reference files, not five.** The source skill's word-list section prescribed against singular *they*, which the harness requires; its "matters of form" section was 1918 manuscript typography; its seven grammar rules are ones Opus 5 already follows. `ai-writing-tells.md` distills 44,107 bytes of Wikipedia's "Signs of AI writing" into 21 imperative headings with the 11 watch lists that exist, dropping that guide's em-dash, curly-quote, and Markdown advice — Wikipedia house style that would have agents strip formatting this harness renders. It stays CC BY-SA 4.0; the package remains MIT.

**Measured:** the shipped `SKILL.md` was micro-tested against a no-guidance control and against the source skill's longer form — three prompts, five reps per arm, every flagged match read by hand. <verdict>

<tally>
```

- [ ] **Step 7: Bump the version**

```bash
bash scripts/bump-version.sh 6.2.1-cc.4
bash scripts/bump-version.sh --audit
```

Expected: three files updated. The audit reports occurrences of `6.2.1-cc.4` in
`docs/superpowers/specs/2026-07-30-writing-style-in-superpowers-design.md` and
`docs/superpowers/plans/2026-07-30-writing-style-in-superpowers.md`, because
`.version-bump.json` excludes `CHANGELOG.md`, `RELEASE-NOTES.md`, and `README.md`
but not `docs/`. **Those two are expected and correct** — the spec and plan name
the release deliberately, and `CLAUDE.md` treats historical docs as a record.
Anything else the audit names is a real straggler.

- [ ] **Step 8: Verify the manifests and the whole suite**

```bash
claude plugin validate .
bash tests/hooks/test-session-start.sh
bash scripts/lint-shell.sh
claude plugin details superpowers@superpowers-cc
```

Expected: validate passes; tests pass; `details` reports **16 skills**, 4 agents, 2
hooks. Copy the always-on and on-invoke figures it prints for
`writing-clearly-and-concisely` — Step 9's commit message quotes them.

- [ ] **Step 9: Commit**

Replace the two bracketed figures with what Step 8 printed:

```bash
git add README.md CLAUDE.md RELEASE-NOTES.md package.json .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "docs(release): 6.2.1-cc.4 — writing style in-tree

README gains the optional-capabilities row, the SessionStart consequence, and a
Writing style section stating the CC BY-SA boundary. Skill count 15 -> 16 in both
places it appears. CLAUDE.md records the invariant: the option is a pointer, and
injecting the rules would mean two drifting copies.

Measured cost from 'claude plugin details': always-on <N> tokens (the
description), on-invoke <N> tokens (the body). Version stays on the 6.2.1 upstream
base per the fork's convention."
```
