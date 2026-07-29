#!/usr/bin/env bash
# Tests for the pre-taskupdate-user-gate PreToolUse hook.
#
# The gate must block closing a task marked "userGate" whose verifyCommand never
# ran in the session, allow it once the command appears, and stay out of the way
# for every other TaskUpdate.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/pre-taskupdate-user-gate"

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

failures=0

pass() { echo "  [PASS] $1"; }
fail() {
    echo "  [FAIL] $1"
    failures=$((failures + 1))
}

# write_transcript <file> <metadata json> [evidence command]
# Builds a minimal transcript: one TaskCreate with its result (native id 7),
# optionally followed by a Bash tool_result carrying the evidence command.
write_transcript() {
    local out="$1" metadata="$2" evidence="${3:-}"
    local description

    description=$(printf '**Goal:** Prove the pipeline works.\n\n```json:metadata\n%s\n```' "$metadata")

    python3 - "$out" "$description" "$evidence" <<'PY'
import json, sys

out, description, evidence = sys.argv[1], sys.argv[2], sys.argv[3]

lines = [
    {"type": "assistant", "message": {"content": [
        {"type": "tool_use", "id": "tu_1", "name": "TaskCreate",
         "input": {"subject": "Gate: end-to-end run", "description": description}},
    ]}},
    {"type": "user", "message": {"content": [
        {"type": "tool_result", "tool_use_id": "tu_1",
         "content": "Task #7 created successfully"},
    ]}},
]

if evidence:
    lines.append({"type": "assistant", "message": {"content": [
        {"type": "tool_use", "id": "tu_2", "name": "Bash",
         "input": {"command": evidence}},
    ]}})
    lines.append({"type": "user", "message": {"content": [
        {"type": "tool_result", "tool_use_id": "tu_2",
         "content": "3 passed, 0 failed"},
    ]}})

with open(out, "w") as fh:
    for entry in lines:
        fh.write(json.dumps(entry) + "\n")
PY
}

# assert_decision <description> <expected: allow|block> <payload>
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

payload_for() {
    local transcript="$1" status="${2:-completed}" task_id="${3:-7}"
    printf '{"tool_name":"TaskUpdate","tool_input":{"taskId":"%s","status":"%s"},"transcript_path":"%s"}' \
        "$task_id" "$status" "$transcript"
}

echo "pre-taskupdate-user-gate hook tests"

GATE_META='{"userGate": true, "verifyCommand": "npm test -- e2e", "acceptanceCriteria": ["pipeline green"]}'
PLAIN_META='{"verifyCommand": "npm test -- e2e", "acceptanceCriteria": ["pipeline green"]}'
TAGGED_META='{"tags": ["user-gate"], "verifyCommand": "./verify.sh --full"}'
NOCMD_META='{"userGate": true, "acceptanceCriteria": ["pipeline green"]}'

assert_decision "non-TaskUpdate tool passes untouched" allow \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m x"}}'

t="$TMPDIR_TEST/gate-no-evidence.jsonl"
write_transcript "$t" "$GATE_META"
assert_decision "userGate close without the verifyCommand is blocked" block "$(payload_for "$t")"

assert_decision "a non-completed status on the same task passes" allow \
    "$(payload_for "$t" in_progress)"

t="$TMPDIR_TEST/gate-with-evidence.jsonl"
write_transcript "$t" "$GATE_META" "npm test -- e2e"
assert_decision "userGate close after the verifyCommand ran is allowed" allow "$(payload_for "$t")"

t="$TMPDIR_TEST/gate-similar-evidence.jsonl"
write_transcript "$t" "$GATE_META" "npm test -- unit"
assert_decision "a different command is not evidence" block "$(payload_for "$t")"

t="$TMPDIR_TEST/tagged-no-evidence.jsonl"
write_transcript "$t" "$TAGGED_META"
assert_decision "user-gate tag alone arms the gate" block "$(payload_for "$t")"

t="$TMPDIR_TEST/plain-task.jsonl"
write_transcript "$t" "$PLAIN_META"
assert_decision "an unmarked task closes freely" allow "$(payload_for "$t")"

t="$TMPDIR_TEST/gate-no-command.jsonl"
write_transcript "$t" "$NOCMD_META"
assert_decision "userGate with no verifyCommand has nothing checkable" allow "$(payload_for "$t")"

t="$TMPDIR_TEST/gate-other-id.jsonl"
write_transcript "$t" "$GATE_META"
assert_decision "closing a different task id is unaffected" allow "$(payload_for "$t" completed 9)"

t="$TMPDIR_TEST/gate-no-evidence.jsonl"
if output=$(printf '%s' "$(payload_for "$t")" |
    SUPERPOWERS_USERGATE_GUARD=0 bash "$HOOK" 2>/dev/null) &&
    echo "$output" | grep -q '"allow"'; then
    pass "SUPERPOWERS_USERGATE_GUARD=0 disables the gate"
else
    fail "SUPERPOWERS_USERGATE_GUARD=0 disables the gate"
fi

err=$(printf '%s' "$(payload_for "$t")" | bash "$HOOK" 2>&1 >/dev/null)
if echo "$err" | grep -q "npm test -- e2e"; then
    pass "block message quotes the verifyCommand"
else
    fail "block message quotes the verifyCommand"
fi

assert_decision "missing transcript fails open" allow \
    '{"tool_name":"TaskUpdate","tool_input":{"taskId":"7","status":"completed"},"transcript_path":"/nonexistent/x.jsonl"}'

assert_decision "malformed JSON fails open" allow 'not json'

t="$TMPDIR_TEST/corrupt.jsonl"
printf 'not json\n\xff\xfe binary\n' > "$t"
assert_decision "unparseable transcript lines fail open" allow "$(payload_for "$t")"

echo
if [ "$failures" -eq 0 ]; then
    echo "STATUS: PASSED"
    exit 0
fi
echo "STATUS: FAILED ($failures failure(s))"
exit 1
