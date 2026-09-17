# Skill streamlining validation

Date: 2026-09-17. Candidate version: `6.2.1-cc.10`.

## Status

The prompt and documentation changes are implemented and statically checked.
The approved no-guidance/current/revised decision comparisons completed on Sol and
Astra, with five repetitions per variant and model. The revised prompts remove
three measured forms of process interference in this targeted battery. Full
implementation-level pressure tests did not run; general task-quality improvement
and Opus/Fable behavior remain unverified.
No plugin installation, publication, or push occurred during validation.

The prompt scope covers Opus/Fable, Sol, and Astra-class models. Claude Code
packaging, tools, hooks, inherited models, and existing effort defaults remain.
No Codex adapter or model router was added. Opus/Fable identifiers were not guessed.

## Changes

- Reuse authorization and ask only about consequential unresolved decisions.
- Write outcome-based task contracts with exact shared interfaces where needed.
- Bind verification to the source and environment, not the message containing it.
- Adjudicate review claims before fixing them; preserve unresolved correctness blockers.
- Preserve implementation written before tests and validate regression sensitivity.
- Keep recovery ledgers and evidence through review and integration.
- Correct the claim that reviewer Bash access is structurally read-only.
- Remove repeated examples, rationalization tables, and required review praise.
- Align live references, agent contracts, README, and plugin metadata.

Cross-review CLI recipes moved into a conditional reference. They were not converted
into a new executable helper in this revision: keeping their mechanics unchanged
separates prompt changes from CLI behavior changes. Future helper extraction needs
its own runtime tests. `writing-clearly-and-concisely` was retained unchanged.

## Offline checks

All eight suites exited successfully:

- `bash tests/hooks/test-session-start.sh`
- `bash tests/hooks/test-pre-agent-effort-pin.sh`
- `bash tests/hooks/test-pre-taskupdate-user-gate.sh`
- `bash tests/claude-code/test-sdd-workspace.sh`
- `bash tests/systematic-debugging/test-find-polluter.sh`
- `bash tests/shell-lint/test-lint-shell.sh`
- `bash tests/writing-skills/test-render-graphs.sh`
- `bash tests/prompt-cost/test-analyze-prompt-cost.sh`

The graph suite passed three checks and skipped actual rendering because Graphviz
was unavailable. These suites validate infrastructure, not model behavior.

The skill-creator `quick_validate.py` passed for all 16 skills. Concrete local
Markdown links in the entrypoints resolve; example paths inside inline code were
excluded. Both plugin version fields match. `git diff --check` passed.

Pre-commit ran with its repository configuration. All three hooks skipped because
they apply only to Python under `evals/`; no changed file matched. PyYAML and
pre-commit were provisioned in a temporary uv cache, without project dependency edits.

Independent review found stale README and testing-reference instructions, an
outside-diff blocker conflict, and ambiguous precedence for brief corrections.
All were corrected and independently rechecked. Implementer self-review and final
verification now precede the commit used by the review-package script.

## Model probes

The user explicitly approved transmission of the frozen private skill text and
six scenarios to Sol and Astra after an earlier automatic approval rejection.
All 30 sessions completed with exit 0 and nonempty answers: two models, three
variants, five fresh repetitions each. Five no-guidance Sol runs came from the
initial stage; the other 25 ran after approval. No new permission workaround was used.

Artifacts remain outside the plugin at `/tmp/superpowers-prompt-evals/`: frozen
prompts, source hashes, scenarios, rubric, full responses, logs, per-run metadata,
`SOL-SCORES.md`, `ASTRA-SCORES.md`, and `comparison-manifest.json`. This temporary
path is local evidence, not a permanent archive. All responses were read manually;
Astra scoring used an independent reviewer. The rubric was unchanged after results.

The tested guidance includes five skill entrypoints: verification-before-completion,
subagent-driven-development, brainstorming, receiving-code-review, and
test-driven-development. The revised source hashes match the working files.
The other skills and agent definitions were not exercised by these probes.

### Design and results

Each session answered the same six cases, with tools explicitly forbidden and
scenario facts treated as established. These are stated decisions, not observed
code changes or actual verification commands. Post-prompt logs contain no model
tool-call markers.

Pass counts per case, out of five repetitions:

| Model and variant | A | B | C | D | E | F |
|---|---:|---:|---:|---:|---:|---:|
| Sol, no guidance | 5 | 5 | 5 | 5 | 5 | 1 |
| Sol, original | 0 | 5 | 0 | 5 | 0 | 5 |
| Sol, revised | 5 | 5 | 5 | 5 | 5 | 5 |
| Astra, no guidance | 5 | 5 | 5 | 5 | 5 | 5 |
| Astra, original | 0 | 5 | 0 | 5 | 0 | 5 |
| Astra, revised | 5 | 5 | 5 | 5 | 5 | 4 |

Cases and criteria:

- **A:** Reuse passing tests when source, dependencies, command, and environment
  remain identical; a new turn alone does not require another run.
- **B:** Rerun affected checks after production validation behavior changes.
- **C:** Reject a conclusively disproved review finding immediately, with evidence.
- **D:** Apply an already-approved one-line documentation correction without another gate.
- **E:** Fix an understood parser defect while clarifying an independent dashboard request.
- **F:** Test the retry helper's real behavior, with expected failure on defective
  behavior and success on the fix; do not rely on mock call count or urgency.

The original prompts produced the predicted interference on A, C, and E in every
run of both models. Answers explicitly cited the supplied rules: earlier-turn
results were called stale, disproved findings were kept in the five-round review
loop, and the unrelated dashboard question blocked the parser fix. Revised prompts
passed all three cases in all runs. B and D passed throughout; no improvement on
those cases was observed.

Sol's revised responses also all required explicit red/green evidence. Four of its
control answers omitted an explicit failing run of the new regression test; three
still requested old-defect evidence and real assertions. All five control responses
rejected mock call count alone. The F score therefore does not mean four mock-only
tests or four unsupported success claims.

Astra revised repetition 3 failed F by reversing the scenario: it proposed a test
for returning after early success, instead of preventing return before the third
attempt. It did require red/green evidence. This is a scenario-interpretation error,
not a missing verification contract. The ambiguous retry wording limits attribution
to the prompt. The failure remains scored; the scenario and rubric were not changed.

For convenience, totals are Sol 26/30 control, 15/30 original, 30/30 revised;
Astra 30/30 control, 15/30 original, 29/30 revised. These correlated decisions are
not independent software tasks or a general quality score. Astra's perfect control
also means revised guidance has no demonstrated advantage over no guidance here.

### Reproduction and limits

- Models: `gpt-5.6-sol` and `gpt-6-astra`, provider `openai`.
- Codex CLI: `0.153.4`; no explicit effort override. Headers report effort `none`,
  which is recorded as CLI metadata, not a verified backend reasoning setting.
- Flags: `--ephemeral --ignore-user-config --sandbox read-only --skip-git-repo-check`.
- Original source commit: `3ece76eabce7bf3ad45248175b0f1b83efef7a05`.
- Original combined prompt SHA-256:
  `e298aef72797ccb8ddd5ed3121091ff0e6d0492bd7bd5a706e9d0f14a23ba1d8`.
- Revised combined prompt SHA-256:
  `a8678dd654d51786ca22d596ae2340fc419a04ed43f208917cb2042be69ab342`.
- Scenario/control SHA-256:
  `074ca132358a014362fedb233b54f8faed44e90781e5449f01147ba6914c0cc6`.

The frozen runner is `run-probes.py --variant <no-guidance|baseline|revised>
--model <gpt-5.6-sol|gpt-6-astra>`. It defaults to five repetitions, stops on a
failed command, and refuses to overwrite prior artifacts. Repeats need a separate
artifact directory with the same frozen inputs.

The cases target known conflicts and supply conclusive evidence; they do not test
whether an agent can discover that evidence. All five skills are supplied together,
so this is not a natural skill-discovery test or an ablation of individual rules.
CLI system instructions remain a confound. Runs were not randomized, the control
Sol runs occurred earlier, and variant batches ran concurrently. Timing and token
logs therefore do not establish speed or cost gains. Five repeats are a small sample.

## Remaining evaluation

Run sandboxed implementation-level scenarios for TDD, completion claims, skill
routing, explicit verification gates, and failure recovery. Include counterexamples
and tasks beyond the conflicts this revision targeted. Test Opus/Fable separately
once supported identifiers and a usable harness are established. Current results
support the targeted prompt changes, not cross-model parity or deployment readiness.

## Prompt inventory

Counts below use whitespace-delimited words and include frontmatter. They measure
entrypoint size only, not total loaded context, runtime tokens, or cost. Conditional
references and worker definitions are additional context when used.

| Skill | Before | After |
|---|---:|---:|
| brainstorming | 1,607 | 418 |
| cross-reviewing-with-cursor | 2,575 | 396 |
| dispatching-parallel-agents | 628 | 630 |
| executing-plans | 384 | 189 |
| finishing-a-development-branch | 1,679 | 1,377 |
| receiving-code-review | 647 | 218 |
| requesting-code-review | 641 | 505 |
| subagent-driven-development | 4,555 | 1,185 |
| systematic-debugging | 1,463 | 374 |
| test-driven-development | 1,087 | 355 |
| using-git-worktrees | 1,162 | 925 |
| using-superpowers | 329 | 175 |
| verification-before-completion | 387 | 360 |
| writing-clearly-and-concisely | 497 | 497 |
| writing-plans | 1,257 | 374 |
| writing-skills | 4,045 | 632 |
| **Total** | **22,943** | **8,610** |

Entrypoint reduction: **62.5%**. This is not a runtime cost estimate.

## Cursor-only review follow-up

Subsequent user requests removed the Codex review fallback and made Cursor review
optional when the CLI, paid access, or remaining allowance is unavailable. Unknown
eligibility also skips review; access and quota errors are not retried. These
routing changes passed local metadata, link, and diff checks. The model probes
above did not exercise account availability or billing behavior.
