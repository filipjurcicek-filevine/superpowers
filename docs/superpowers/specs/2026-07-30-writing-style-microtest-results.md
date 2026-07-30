# Micro-test results — writing-clearly-and-concisely (2026-07-30)

Three arms x three prompts x five reps = 45 independent dispatches, each agent
writing its own sample file. Flagged matches counted by hand after a grep first
pass.

| Arm | prompt-1 spec | prompt-2 PR | prompt-3 review | total |
|---|---|---|---|---|
| A — no style skill | 9 | 4 | 9 | 22 |
| B — source form (514 words) | 0 | 3 | 3 | 6 |
| C — tested form (452 words) | 0 | 0 | 1 | 1 |

**Verdict: the compression held.** C is at or below B on every prompt, and both
are far below the control. The shipped 429-word form outperformed the 514-word
source it was cut from, so no guidance was restored.

Verbosity, same samples: control 3825 words, source form 2676, shipped 2574.

## What counted as a flagged match

A passive construction where an actor exists, a hedge that adds no information, a
kill-list term used in its defect condition, or a claim where a fact belongs.

Three grep artifacts were rejected on hand review, and each would have inverted
the result:

- `very` matched inside **every** ("every session"), inflating all three arms.
- Participial adjectives (`is untested`, `is unanchored`, `is unescaped`,
  `is unchanged`, `is untouched`) are not passives with a suppressed actor.
- Every `rather` hit was `rather than` — a comparison both prompts invite, not a
  hedge.

Before those were removed the raw counts read A 44 / B 20 / C 18, which would
have failed C against B on prompt 1. The hand-read requirement is what produced
the correct answer.

## Limitation: the control is not guidance-free

This workspace's `CLAUDE.md` imports `docs/rules/sumarization.md` ("No filler
phrases, vague statements, buzzwords, or jargon") and
`docs/rules/direct-communication.md`. Arm A therefore ran with anti-puffery
guidance already in context, which is why the kill list fired once in 45 samples
(`literally`, arm B).

**The kill list is unmeasured, not validated.** What this test measured is the
six rules — active voice, positive form, concrete language, omitting needless
words — where the effect is large and consistent. In a workspace without those
imported rules the kill list may carry more weight; nothing here shows that it
does or does not.

## Post-test change

The final review found the kill list stated as bare token bans, which the spec
forbade. Fixing that reworded `SKILL.md` after this test ran: the tested form is
452 words, the shipped form is 497. The rewording touched only the kill list,
which fired once across all 45 samples, so the measured result — the six rules,
arm C at or below arm B on every prompt — is unaffected. The kill list is
untested in both forms.
