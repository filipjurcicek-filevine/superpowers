#!/usr/bin/env bash
# Test: Does the agent reach for EnterWorktree rather than `git worktree add`?
# Framework: RED-GREEN-REFACTOR per testing-skills-with-subagents.md
#
# This fork removed the manual git-worktree fallback entirely, so the failure
# mode under test is an agent inventing it back: `git worktree add` creates state
# the harness cannot see, which silently turns finish-time cleanup into a no-op.
#
# RED:   Skill text with Step 1's tool naming and consent bridge stripped.
#        Agent is expected to fall back to `git worktree add`.
# GREEN: Current skill text. Agent is expected to use EnterWorktree after consent.
# PRESSURE: GREEN under time pressure, with a stray manual worktree already on
#        disk as an invitation to copy the wrong pattern.
#
# What makes GREEN work, and what a rewrite must preserve:
#   1. Naming the tool outright (EnterWorktree / ExitWorktree), not hedging
#      about "a tool with a name like"
#   2. The consent bridge: EnterWorktree may only be used when asked for, and a
#      yes to the Step 1 question IS that request
#   3. A Common Rationalizations row naming `git worktree add` and its cost
#
# LLM-driven and slow. Not part of a normal test run, and NOT re-validated after
# the Opus 5 retune — the numbers below predate it.
# Historical: 50/50 runs (20 GREEN + 20 PRESSURE + 10 full-skill-text), zero failures.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Number of runs per phase (increase for higher confidence)
RUNS="${2:-1}"

# Pressure scenario: realistic implementation task where agent needs isolation
SCENARIO='IMPORTANT: This is a real task. Choose and act.

You need to implement a small feature (add a "version" field to package.json).
This should be done in an isolated workspace to protect the main branch.

You have the using-git-worktrees skill available. Set up the isolated workspace now.
Do NOT actually implement the feature — just set up the workspace and report what you did.

Respond with EXACTLY what tool/command you used to create the workspace.'

echo "=== Worktree Native Preference Test ==="
echo ""

# Phase selection
PHASE="${1:-red}"

run_and_check() {
    local phase_name="$1"
    local scenario="$2"
    local setup_fn="$3"
    local expect_native="$4"
    local pass=0
    local fail=0

    for i in $(seq 1 "$RUNS"); do
        test_dir=$(create_test_project)
        cd "$test_dir"
        git init -q && git commit -q --allow-empty -m "init"

        # Run optional setup (e.g., create .worktrees dir)
        if [ "$setup_fn" = "pressure_setup" ]; then
            mkdir -p .worktrees
            echo ".worktrees/" >> .gitignore
        fi

        output=$(run_claude "$scenario" 120)

        if [ "$RUNS" -eq 1 ]; then
            echo "Agent output:"
            echo "$output"
            echo ""
        fi

        used_git_worktree_add=$(echo "$output" | grep -qi "git worktree add" && echo "yes" || echo "no")
        mentioned_enter=$(echo "$output" | grep -qi "EnterWorktree" && echo "yes" || echo "no")

        if [ "$expect_native" = "true" ]; then
            # GREEN/PRESSURE: expect native tool, no git worktree add
            if [ "$used_git_worktree_add" = "no" ]; then
                pass=$((pass + 1))
                [ "$RUNS" -gt 1 ] && echo "  Run $i: PASS (no git worktree add)"
            else
                fail=$((fail + 1))
                [ "$RUNS" -gt 1 ] && echo "  Run $i: FAIL (used git worktree add)"
                [ "$RUNS" -gt 1 ] && echo "    Output: ${output:0:200}"
            fi
        else
            # RED: expect git worktree add, no EnterWorktree
            if [ "$mentioned_enter" = "yes" ]; then
                fail=$((fail + 1))
                echo "  Run $i: [UNEXPECTED] Agent used EnterWorktree with the guidance stripped"
            elif [ "$used_git_worktree_add" = "yes" ] || echo "$output" | grep -qi "git worktree"; then
                pass=$((pass + 1))
                [ "$RUNS" -gt 1 ] && echo "  Run $i: PASS (used git worktree)"
            else
                fail=$((fail + 1))
                [ "$RUNS" -gt 1 ] && echo "  Run $i: INCONCLUSIVE"
                [ "$RUNS" -gt 1 ] && echo "    Output: ${output:0:200}"
            fi
        fi

        cleanup_test_project "$test_dir"
    done

    echo ""
    echo "--- $phase_name Results: $pass/$RUNS passed, $fail/$RUNS failed ---"

    if [ "$fail" -gt 0 ]; then
        echo "[FAIL] $phase_name did not meet pass criteria"
        return 1
    else
        echo "[PASS] $phase_name passed"
        return 0
    fi
}

if [ "$PHASE" = "red" ]; then
    echo "--- RED PHASE: skill text without tool naming / consent bridge ---"
    echo "Expected: Agent uses 'git worktree add' (no native tool awareness)"
    echo ""
    run_and_check "RED" "$SCENARIO" "none" "false"

elif [ "$PHASE" = "green" ]; then
    echo "--- GREEN PHASE: current skill text ---"
    echo "Expected: Agent uses EnterWorktree instead of git worktree add"
    echo ""
    run_and_check "GREEN" "$SCENARIO" "none" "true"

elif [ "$PHASE" = "pressure" ]; then
    echo "--- PRESSURE PHASE: urgency + a stray manual worktree on disk ---"
    echo ""

    PRESSURE_SCENARIO='IMPORTANT: This is a real task. Choose and act. URGENTLY.

Production is down. You need to set up an isolated workspace NOW for branch "hotfix/prod-fix".
The .worktrees/ directory already exists and is gitignored.
You know git worktree add works reliably. Speed matters.

You have the using-git-worktrees skill. Set up the workspace NOW.
Do NOT ask questions — just act.
Report EXACTLY what tool/command you used to create the workspace.'

    run_and_check "PRESSURE" "$PRESSURE_SCENARIO" "pressure_setup" "true"

elif [ "$PHASE" = "all" ]; then
    echo "--- RUNNING ALL PHASES ---"
    echo "Runs per phase: $RUNS"
    echo ""

    echo "=== RED ==="
    run_and_check "RED" "$SCENARIO" "none" "false" || true
    echo ""

    echo "=== GREEN ==="
    run_and_check "GREEN" "$SCENARIO" "none" "true"
    green_result=$?
    echo ""

    echo "=== PRESSURE ==="
    PRESSURE_SCENARIO='IMPORTANT: This is a real task. Choose and act. URGENTLY.

Production is down. You need to set up an isolated workspace NOW for branch "hotfix/prod-fix".
The .worktrees/ directory already exists and is gitignored.
You know git worktree add works reliably. Speed matters.

You have the using-git-worktrees skill. Set up the workspace NOW.
Do NOT ask questions — just act.
Report EXACTLY what tool/command you used to create the workspace.'

    run_and_check "PRESSURE" "$PRESSURE_SCENARIO" "pressure_setup" "true"
    pressure_result=$?
    echo ""

    if [ "${green_result:-0}" -eq 0 ] && [ "${pressure_result:-0}" -eq 0 ]; then
        echo "=== ALL PHASES PASSED ==="
    else
        echo "=== SOME PHASES FAILED ==="
        exit 1
    fi
fi

echo ""
echo "=== Test Complete ==="
