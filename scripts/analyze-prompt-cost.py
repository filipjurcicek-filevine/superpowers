#!/usr/bin/env python3
"""Size the injected context in quorum eval runs, to find what prompt text costs.

Reads run directories produced by the quorum harness (see docs/testing.md) and
reports, per run and per arm:

  * always-on injections — the skill listing, agent listing, deferred-tool listing
    and SessionStart bootstrap. These enter context before turn 1 of every session
    whether a skill is invoked or not, and are re-read on every later turn.
  * per-skill injected bodies — the SKILL.md text a Skill call actually pastes in,
    attributed to the skill that pulled it.
  * turns, peak context, output tokens, cost, and the tool-call mix.
  * redundancy — the same file Read twice, or the same skill loaded twice.

Why this exists: cost is context size multiplied by turn count, so a character of
`description` (present from turn 1, always) is worth roughly 25 characters of
SKILL.md body (present only after invocation) on a typical ~25-turn run. Guessing
which is which produced a wrong answer once already; this measures it.

Related but different: tests/claude-code/analyze-token-usage.py attributes tokens
to individual subagents within ONE session transcript. This script sizes injected
prompt text across MANY runs. Neither subsumes the other.

Usage:
  analyze-prompt-cost.py <results-dir> [--glob PATTERN] [--turns N] [--json]
  analyze-prompt-cost.py <single-run-dir> [--json]

Exit: 0 report produced | 1 no analyzable runs | 2 usage error
"""

from __future__ import annotations

import argparse
import json
import os
import re
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

# A skill body arrives as a plain user-message text block opening with this line.
SKILL_BODY_MARKER = "Base directory for this skill:"
SKILL_BODY_RE = re.compile(r"Base directory for this skill:\s*(\S+)")

# Attachment types that carry always-on injected context, mapped to the field
# holding their payload. Payloads are sometimes a str and sometimes a list of
# str — see char_size().
ALWAYS_ON_FIELDS = {
    "skill_listing": "content",
    "agent_listing_delta": "addedLines",
    "deferred_tools_delta": "addedLines",
    "hook_additional_context": "content",
}

# Default turn count for the re-read multiplier. Overridable; the reported
# medians make the real number visible per run.
DEFAULT_TURNS = 25


def char_size(value) -> int:
    """Character cost of an injected payload.

    The harness stores some payloads as a string and others as a list of strings
    (`hook_additional_context.content`, `*_delta.addedLines`). Calling len() on
    the list form counts ELEMENTS, which undercounts by orders of magnitude — a
    2109-character bootstrap reads as 1. Join list forms the way they are
    rendered so both shapes yield characters.
    """
    if value is None:
        return 0
    if isinstance(value, str):
        return len(value)
    if isinstance(value, (list, tuple)):
        return len("\n".join(str(v) for v in value))
    return len(str(value))


def iter_jsonl(path: Path):
    """Yield parsed records, skipping malformed lines rather than aborting.

    A truncated final line is normal in a killed run; one bad line must not cost
    the whole run's analysis.
    """
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    yield json.loads(line)
                except json.JSONDecodeError:
                    continue
    except OSError:
        return


def session_log(run: Path) -> Path | None:
    """The agent-under-test's transcript: largest jsonl under the isolated home."""
    root = run / "home" / ".claude" / "projects"
    if not root.is_dir():
        return None
    logs = [p for p in root.rglob("*.jsonl") if p.is_file()]
    if not logs:
        return None
    return max(logs, key=lambda p: p.stat().st_size)


def content_blocks(rec: dict):
    """Yield dict content blocks of a message record, if any."""
    msg = rec.get("message")
    if not isinstance(msg, dict):
        return
    content = msg.get("content")
    if not isinstance(content, list):
        return
    for block in content:
        if isinstance(block, dict):
            yield block


def classify_arm(skill_root: str) -> str:
    """Label which checkout a run exercised, for A/B grouping.

    quorum points --plugin-dir at SUPERPOWERS_ROOT, so the skill's base directory
    identifies the tree under test.
    """
    if not skill_root:
        return "unknown"
    low = skill_root.lower()
    for marker in ("upstream", "baseline"):
        if marker in low:
            return marker
    return "fork"


def analyze_run(run: Path) -> dict | None:
    """Extract one run's prompt-cost profile, or None if it is not analyzable."""
    verdict_path = run / "verdict.json"
    log = session_log(run)
    if not verdict_path.is_file() or log is None:
        return None
    try:
        verdict = json.loads(verdict_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None

    econ = verdict.get("economics") or {}
    coding = econ.get("coding_agent") or {}

    stats = {
        "run": run.name,
        "final": verdict.get("final"),
        "arm": None,
        "model": coding.get("model"),
        "cost_usd": coding.get("est_cost_usd"),
        "always_on": {},
        "skills": [],
        "tools": Counter(),
        "reads": Counter(),
        "turns": 0,
        "output_tokens": 0,
        "context_peak": 0,
        "tool_result_chars": 0,
    }

    pending_skill = None
    for rec in iter_jsonl(log):
        attachment = rec.get("attachment")
        if isinstance(attachment, dict):
            field = ALWAYS_ON_FIELDS.get(attachment.get("type"))
            if field:
                size = char_size(attachment.get(field))
                key = attachment["type"]
                # Deltas can repeat; keep the largest observed payload.
                stats["always_on"][key] = max(stats["always_on"].get(key, 0), size)

        msg = rec.get("message")
        if isinstance(msg, dict):
            usage = msg.get("usage")
            if isinstance(usage, dict):
                stats["turns"] += 1
                stats["output_tokens"] += usage.get("output_tokens") or 0
                ctx = (usage.get("cache_read_input_tokens") or 0) + (
                    usage.get("cache_creation_input_tokens") or 0
                )
                stats["context_peak"] = max(stats["context_peak"], ctx)

        for block in content_blocks(rec):
            btype = block.get("type")
            if btype == "tool_use":
                name = block.get("name") or "?"
                stats["tools"][name] += 1
                args = block.get("input") if isinstance(block.get("input"), dict) else {}
                if name == "Skill":
                    pending_skill = args.get("skill")
                elif name == "Read":
                    target = args.get("file_path")
                    if isinstance(target, str) and target:
                        stats["reads"][target] += 1
            elif btype == "tool_result":
                stats["tool_result_chars"] += char_size(block.get("content"))
            elif btype == "text":
                text = block.get("text")
                if isinstance(text, str) and text.startswith(SKILL_BODY_MARKER):
                    match = SKILL_BODY_RE.match(text)
                    root = match.group(1) if match else ""
                    if stats["arm"] is None:
                        stats["arm"] = classify_arm(root)
                    name = pending_skill or Path(root).name or "?"
                    stats["skills"].append({"skill": name, "chars": len(text)})
                    pending_skill = None

    if stats["arm"] is None:
        stats["arm"] = "unknown"
    return stats


def median_of(rows, key) -> float:
    values = [r[key] for r in rows if isinstance(r.get(key), (int, float))]
    return statistics.median(values) if values else 0.0


def build_report(rows, turns_multiplier: int) -> dict:
    by_arm = defaultdict(list)
    for row in rows:
        by_arm[row["arm"]].append(row)

    # Always-on payloads are per-tree, and an A/B compares two trees — maxing
    # across every run would report one arm's bootstrap as if both shared it.
    # Group by arm; the overall block stays only as a convenience for
    # single-arm runs.
    always_on_by_arm = {}
    for arm, rs in by_arm.items():
        merged = {}
        for row in rs:
            for key, size in row["always_on"].items():
                merged[key] = max(merged.get(key, 0), size)
        total = sum(merged.values())
        always_on_by_arm[arm] = {
            "by_source": merged,
            "total_chars": total,
            "total_tokens_est": total // 4,
            "token_reads_per_run_est": total // 4 * turns_multiplier,
        }

    always_on = {}
    for row in rows:
        for key, size in row["always_on"].items():
            always_on[key] = max(always_on.get(key, 0), size)
    always_on_total = sum(always_on.values())

    skills = defaultdict(list)
    for row in rows:
        for entry in row["skills"]:
            skills[(row["arm"], entry["skill"])].append(entry["chars"])

    tools = Counter()
    for row in rows:
        tools.update(row["tools"])

    redundancy = []
    for row in rows:
        repeat_reads = {f: c for f, c in row["reads"].items() if c > 1}
        skill_counts = Counter(e["skill"] for e in row["skills"])
        repeat_skills = {s: c for s, c in skill_counts.items() if c > 1}
        if repeat_reads or repeat_skills:
            redundancy.append(
                {"run": row["run"], "reads": repeat_reads, "skills": repeat_skills}
            )

    return {
        "runs": len(rows),
        "turns_multiplier": turns_multiplier,
        "always_on": {
            "by_source": always_on,
            "total_chars": always_on_total,
            "total_tokens_est": always_on_total // 4,
            "token_reads_per_run_est": always_on_total // 4 * turns_multiplier,
        },
        "always_on_by_arm": always_on_by_arm,
        "arms": {
            arm: {
                "runs": len(rs),
                "pass": sum(1 for r in rs if r["final"] == "pass"),
                "median_turns": median_of(rs, "turns"),
                "median_context_peak": median_of(rs, "context_peak"),
                "median_output_tokens": median_of(rs, "output_tokens"),
                "median_cost_usd": median_of(rs, "cost_usd"),
                "median_tool_result_chars": median_of(rs, "tool_result_chars"),
            }
            for arm, rs in sorted(by_arm.items())
        },
        "skill_bodies": {
            f"{arm}/{name}": {
                "median_chars": int(statistics.median(sizes)),
                "tokens_est": int(statistics.median(sizes)) // 4,
                "n": len(sizes),
            }
            for (arm, name), sizes in sorted(
                skills.items(), key=lambda kv: -statistics.median(kv[1])
            )
        },
        "tools": dict(tools.most_common()),
        "redundancy": redundancy,
        "per_run": [
            {
                "run": r["run"],
                "arm": r["arm"],
                "final": r["final"],
                "model": r["model"],
                "turns": r["turns"],
                "context_peak": r["context_peak"],
                "output_tokens": r["output_tokens"],
                "cost_usd": r["cost_usd"],
            }
            for r in rows
        ],
    }


def print_report(report: dict) -> None:
    mult = report["turns_multiplier"]
    print(f"=== {report['runs']} run(s) analyzed ===\n")

    hdr = (
        f"{'run':<48} {'arm':<9} {'final':<14} {'turns':>5} "
        f"{'ctx_peak':>9} {'out_tok':>8} {'$':>6}"
    )
    print(hdr)
    print("-" * len(hdr))
    for r in report["per_run"]:
        cost = f"{r['cost_usd']:.2f}" if isinstance(r["cost_usd"], (int, float)) else "-"
        print(
            f"{r['run'][:48]:<48} {r['arm']:<9} {str(r['final'] or '-'):<14} "
            f"{r['turns']:>5} {r['context_peak']:>9} {r['output_tokens']:>8} {cost:>6}"
        )

    print("\n=== always-on injected context (in context before turn 1, every session) ===")
    for arm, ao in sorted(report["always_on_by_arm"].items()):
        print(f"  [{arm}]")
        for key, size in sorted(ao["by_source"].items(), key=lambda kv: -kv[1]):
            print(f"    {key:<26} {size:>7} ch  (~{size // 4:>5} tok)")
        print(
            f"    {'TOTAL':<26} {ao['total_chars']:>7} ch  (~{ao['total_tokens_est']:>5} tok)"
            f"  -> ~{ao['token_reads_per_run_est']:,} token-reads/run at {mult} turns"
        )

    print("\n=== per-arm medians ===")
    print(
        f"  {'arm':<9} {'n':>3} {'pass':>5} {'turns':>6} {'ctx_peak':>9} "
        f"{'out_tok':>8} {'toolres_ch':>11} {'$':>6}"
    )
    for arm, a in report["arms"].items():
        print(
            f"  {arm:<9} {a['runs']:>3} {a['pass']:>5} {a['median_turns']:>6.0f} "
            f"{a['median_context_peak']:>9.0f} {a['median_output_tokens']:>8.0f} "
            f"{a['median_tool_result_chars']:>11.0f} {a['median_cost_usd']:>6.2f}"
        )

    if report["skill_bodies"]:
        print("\n=== skill bodies injected on invocation (median chars) ===")
        for label, s in report["skill_bodies"].items():
            print(
                f"  {label:<52} {s['median_chars']:>6} ch (~{s['tokens_est']:>5} tok)  n={s['n']}"
            )

    if report["tools"]:
        print("\n=== tool-call mix (summed) ===")
        for name, count in report["tools"].items():
            print(f"  {name:<24} {count:>5}")

    print("\n=== redundancy (same file Read twice / same skill loaded twice) ===")
    if not report["redundancy"]:
        print("  none")
    for item in report["redundancy"]:
        print(f"  {item['run'][:60]}")
        for f, c in sorted(item["reads"].items(), key=lambda kv: -kv[1]):
            print(f"      {c}x Read  {f}")
        for s, c in sorted(item["skills"].items(), key=lambda kv: -kv[1]):
            print(f"      {c}x Skill {s}")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="analyze-prompt-cost.py",
        description="Size injected context across quorum eval runs.",
    )
    ap.add_argument("path", help="a quorum results/ directory, or a single run dir")
    ap.add_argument(
        "--glob", default="*", help="run-name pattern within a results dir (default: *)"
    )
    ap.add_argument(
        "--turns",
        type=int,
        default=DEFAULT_TURNS,
        help=f"turn count for the re-read multiplier (default: {DEFAULT_TURNS})",
    )
    ap.add_argument("--json", action="store_true", help="emit JSON instead of a table")
    args = ap.parse_args(argv)

    root = Path(args.path)
    if not root.is_dir():
        print(f"error: not a directory: {root}", file=sys.stderr)
        return 2
    if args.turns < 1:
        print("error: --turns must be >= 1", file=sys.stderr)
        return 2

    # A single run dir is identified by its own verdict.json.
    if (root / "verdict.json").is_file():
        candidates = [root]
    else:
        candidates = sorted(p for p in root.glob(args.glob) if p.is_dir())

    rows = [r for r in (analyze_run(p) for p in candidates) if r]
    if not rows:
        print(
            f"no analyzable runs under {root} (need verdict.json + "
            f"home/.claude/projects/**/*.jsonl)",
            file=sys.stderr,
        )
        return 1

    report = build_report(rows, args.turns)
    if args.json:
        json.dump(report, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        print_report(report)
    return 0


if __name__ == "__main__":
    sys.exit(main())
