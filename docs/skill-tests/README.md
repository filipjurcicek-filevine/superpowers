# Skill Test Records

Baseline and pressure scenarios recorded while developing a skill — the RED-phase
artifacts `writing-skills` asks for.

These are a **record, not live instructions**, and not a runnable suite. They live
here rather than inside their skill's directory for two reasons: an unreferenced
file in a skill directory is dead weight by this repo's conventions, and these
ship to every install of the plugin for no benefit if left there.

The runnable equivalents live elsewhere:

- `tests/` — plugin infrastructure (hooks, scripts). Offline, seconds.
- `evals/` — skill *behavior* in real sessions, via the drill harness. Cloned from
  [superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/);
  gitignored here.

When you develop a new skill and want to keep its baseline transcripts, add them
under `docs/skill-tests/<skill-name>/`.
