#!/usr/bin/env bash
# Tests for the pre-agent-effort-pin PreToolUse hook.
#
# The gate must fire only on SDD dispatches (a prompt carrying an
# .superpowers/sdd/ artifact path) that name no effort-pinned agent type, and
# must fail open everywhere else.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/pre-agent-effort-pin"

failures=0

pass() { echo "  [PASS] $1"; }
fail() {
    echo "  [FAIL] $1"
    failures=$((failures + 1))
}

# assert_decision <description> <expected: allow|block> <hook stdin JSON>
assert_decision() {
    local description="$1" expected="$2" payload="$3"
    local output status

    output=$(printf '%s' "$payload" | bash "$HOOK" 2>/dev/null)
    status=$?

    if [ "$expected" = "allow" ]; then
        if [ "$status" -eq 0 ] && echo "$output" | grep -q '"permissionDecision": "allow"'; then
            pass "$description"
        else
            fail "$description (exit $status, output: $output)"
        fi
    else
        if [ "$status" -eq 2 ]; then
            pass "$description"
        else
            fail "$description (expected exit 2, got $status)"
        fi
    fi
}

# assert_stderr_contains <description> <needle> <hook stdin JSON>
assert_stderr_contains() {
    local description="$1" needle="$2" payload="$3" err

    err=$(printf '%s' "$payload" | bash "$HOOK" 2>&1 >/dev/null)
    if echo "$err" | grep -q "$needle"; then
        pass "$description"
    else
        fail "$description (stderr lacked '$needle')"
    fi
}

sdd_prompt='Read your task brief first: /repo/.superpowers/sdd/my-plan/task-1-brief.md'

echo "pre-agent-effort-pin hook tests"

assert_decision "non-Agent tool passes untouched" allow \
    '{"tool_name":"Bash","tool_input":{"command":"ls"}}'

assert_decision "Agent call with no SDD artifact path passes" allow \
    '{"tool_name":"Agent","tool_input":{"prompt":"Investigate the flaky test in src/queue.test.ts"}}'

assert_decision "SDD dispatch on sdd-implementer is allowed" allow \
    "{\"tool_name\":\"Agent\",\"tool_input\":{\"subagent_type\":\"sdd-implementer\",\"prompt\":\"$sdd_prompt\"}}"

assert_decision "SDD dispatch on namespaced sdd-task-reviewer is allowed" allow \
    "{\"tool_name\":\"Agent\",\"tool_input\":{\"subagent_type\":\"superpowers:sdd-task-reviewer\",\"prompt\":\"$sdd_prompt\"}}"

assert_decision "SDD dispatch on sdd-re-reviewer is allowed" allow \
    "{\"tool_name\":\"Agent\",\"tool_input\":{\"subagent_type\":\"sdd-re-reviewer\",\"prompt\":\"$sdd_prompt\"}}"

assert_decision "SDD dispatch on code-reviewer is allowed" allow \
    "{\"tool_name\":\"Agent\",\"tool_input\":{\"subagent_type\":\"code-reviewer\",\"prompt\":\"$sdd_prompt\"}}"

assert_decision "SDD dispatch with no subagent_type is blocked" block \
    "{\"tool_name\":\"Agent\",\"tool_input\":{\"prompt\":\"$sdd_prompt\"}}"

assert_decision "SDD dispatch on general-purpose is blocked" block \
    "{\"tool_name\":\"Agent\",\"tool_input\":{\"subagent_type\":\"general-purpose\",\"prompt\":\"$sdd_prompt\"}}"

assert_decision "SDD dispatch on an unrelated custom type is blocked" block \
    "{\"tool_name\":\"Agent\",\"tool_input\":{\"subagent_type\":\"Explore\",\"prompt\":\"$sdd_prompt\"}}"

assert_stderr_contains "block message names the four roles" "superpowers:sdd-re-reviewer" \
    "{\"tool_name\":\"Agent\",\"tool_input\":{\"prompt\":\"$sdd_prompt\"}}"

assert_stderr_contains "block message names the kill switch" "SUPERPOWERS_EFFORT_GUARD=0" \
    "{\"tool_name\":\"Agent\",\"tool_input\":{\"prompt\":\"$sdd_prompt\"}}"

# Kill switch and fail-open behavior.
if output=$(printf '%s' "{\"tool_name\":\"Agent\",\"tool_input\":{\"prompt\":\"$sdd_prompt\"}}" |
    SUPERPOWERS_EFFORT_GUARD=0 bash "$HOOK" 2>/dev/null) &&
    echo "$output" | grep -q '"allow"'; then
    pass "SUPERPOWERS_EFFORT_GUARD=0 disables the gate"
else
    fail "SUPERPOWERS_EFFORT_GUARD=0 disables the gate"
fi

assert_decision "malformed JSON fails open" allow 'not json at all'

assert_decision "empty stdin fails open" allow ''

# A prompt mentioning the workspace across a newline still counts: the field is
# flattened before matching, so a multi-line dispatch cannot slip past.
assert_decision "multi-line SDD prompt is still recognized" block \
    '{"tool_name":"Agent","tool_input":{"prompt":"Task 3 context.\nRead /repo/.superpowers/sdd/plan/task-3-brief.md first."}}'

echo
if [ "$failures" -eq 0 ]; then
    echo "STATUS: PASSED"
    exit 0
fi
echo "STATUS: FAILED ($failures failure(s))"
exit 1
