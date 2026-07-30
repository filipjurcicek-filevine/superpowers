#!/usr/bin/env bash
# Tests for scripts/analyze-prompt-cost.py against synthetic quorum run dirs.
#
# Every assertion is on a NUMBER the script computed from a fixture whose correct
# answer is known by construction — not on the presence of a string in its
# output. A fixture is built with, say, a 40-character bootstrap payload, and the
# test asserts the script reports 40.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ANALYZE="${REPO_ROOT}/scripts/analyze-prompt-cost.py"

PASS=0
FAIL=0
pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; echo "         $2"; FAIL=$((FAIL + 1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# mkrun <root> <name> <final> <skill-base-dir> -- builds a minimal analyzable run.
# Payload sizes are deliberate and asserted below.
mkrun() {
    local root=$1 name=$2 final=$3 skillroot=$4
    local run="$root/$name"
    local proj="$run/home/.claude/projects/p"
    mkdir -p "$proj"
    cat > "$run/verdict.json" <<JSON
{"final": "$final",
 "economics": {"coding_agent": {"model": "claude-opus-5", "est_cost_usd": 0.5}}}
JSON
    python3 - "$proj/session.jsonl" "$skillroot" <<'PY'
import json, sys
out, skillroot = sys.argv[1], sys.argv[2]
# bootstrap payload as a LIST of one 40-char string (the shape that broke the
# prototype: len() on the list returns 1, not 40)
boot = "B" * 40
# skill listing as a plain string, 100 chars
listing = "L" * 100
# agent listing as a list of two 25-char strings -> 25+1+25 = 51 chars joined
agents = ["A" * 25, "C" * 25]
# skill body: marker line + padding. Total length asserted by the test.
body = f"Base directory for this skill: {skillroot}\n" + "S" * 200
recs = [
    {"type": "attachment",
     "attachment": {"type": "hook_additional_context", "content": [boot]}},
    {"type": "attachment",
     "attachment": {"type": "skill_listing", "content": listing}},
    {"type": "attachment",
     "attachment": {"type": "agent_listing_delta", "addedLines": agents}},
    # two assistant turns: output 10 + 5, context peaks at 300+700=1000
    {"type": "assistant", "message": {"usage": {
        "output_tokens": 10, "cache_read_input_tokens": 100,
        "cache_creation_input_tokens": 100}, "content": [
        {"type": "tool_use", "name": "Skill", "input": {"skill": "superpowers:writing-plans"}}]}},
    {"type": "user", "message": {"content": [{"type": "text", "text": body}]}},
    {"type": "assistant", "message": {"usage": {
        "output_tokens": 5, "cache_read_input_tokens": 300,
        "cache_creation_input_tokens": 700}, "content": [
        {"type": "tool_use", "name": "Read", "input": {"file_path": "/w/a.py"}},
        {"type": "tool_use", "name": "Read", "input": {"file_path": "/w/a.py"}},
        {"type": "tool_use", "name": "Bash", "input": {"command": "ls"}}]}},
    {"type": "user", "message": {"content": [
        {"type": "tool_result", "content": "R" * 30}]}},
]
with open(out, "w") as fh:
    for r in recs:
        fh.write(json.dumps(r) + "\n")
    fh.write('{"type": "assistant", "message": {"usage":\n')  # truncated line
PY
}

jq_get() { python3 -c "import json,sys;d=json.load(sys.stdin);print(eval(sys.argv[1]))" "$1"; }

echo "Test: always-on payloads are measured in characters, not list elements"
R1="$TMP/r1"; mkdir -p "$R1"; mkrun "$R1" run-a pass /repo/skills/writing-plans
OUT="$($ANALYZE "$R1" --json 2>/dev/null)"
if [ -z "$OUT" ]; then
    fail "script produced JSON" "empty output"
else
    boot=$(printf '%s' "$OUT" | jq_get "d['always_on']['by_source']['hook_additional_context']")
    lst=$(printf '%s' "$OUT" | jq_get "d['always_on']['by_source']['skill_listing']")
    agt=$(printf '%s' "$OUT" | jq_get "d['always_on']['by_source']['agent_listing_delta']")
    [ "$boot" = "40" ] && pass "list-shaped bootstrap counts 40 chars (not 1 element)" \
        || fail "list-shaped bootstrap counts 40 chars" "got '$boot'"
    [ "$lst" = "100" ] && pass "string-shaped skill listing counts 100 chars" \
        || fail "string-shaped skill listing counts 100 chars" "got '$lst'"
    [ "$agt" = "51" ] && pass "list of two 25-char lines counts 51 chars (joined)" \
        || fail "list of two 25-char lines counts 51 chars" "got '$agt'"
    tot=$(printf '%s' "$OUT" | jq_get "d['always_on']['total_chars']")
    [ "$tot" = "191" ] && pass "always-on total sums to 191 chars" \
        || fail "always-on total sums to 191" "got '$tot'"
fi

echo "Test: turn/context/output aggregation"
turns=$(printf '%s' "$OUT" | jq_get "d['per_run'][0]['turns']")
ctx=$(printf '%s' "$OUT" | jq_get "d['per_run'][0]['context_peak']")
out=$(printf '%s' "$OUT" | jq_get "d['per_run'][0]['output_tokens']")
[ "$turns" = "2" ] && pass "counts 2 usage-bearing turns" || fail "counts 2 turns" "got '$turns'"
[ "$ctx" = "1000" ] && pass "context peak is max(cache_read+cache_create) = 1000" \
    || fail "context peak 1000" "got '$ctx'"
[ "$out" = "15" ] && pass "output tokens sum to 15" || fail "output tokens 15" "got '$out'"

echo "Test: skill body attributed to the skill that pulled it"
key=$(printf '%s' "$OUT" | jq_get "sorted(d['skill_bodies'])[0]")
chars=$(printf '%s' "$OUT" | jq_get "d['skill_bodies'][sorted(d['skill_bodies'])[0]]['median_chars']")
case "$key" in
    *"superpowers:writing-plans") pass "body attributed to superpowers:writing-plans" ;;
    *) fail "body attributed to the Skill call" "got '$key'" ;;
esac
# Derive the expected length the same way the fixture builds it, rather than
# hardcoding a hand-counted constant — the first version of this test was off by
# one because the marker line's trailing newline was miscounted.
EXPECT_BODY=$(python3 -c "print(len('Base directory for this skill: /repo/skills/writing-plans\n') + 200)")
[ "$chars" = "$EXPECT_BODY" ] && pass "skill body measured at $EXPECT_BODY chars (marker line + 200)" \
    || fail "skill body $EXPECT_BODY chars" "got '$chars'"

echo "Test: arm inferred from the skill base directory"
R2="$TMP/r2"; mkdir -p "$R2"
mkrun "$R2" fork-run pass /Users/x/superpowers/skills/writing-plans
mkrun "$R2" up-run   pass /tmp/sp-upstream/skills/writing-plans
OUT2="$($ANALYZE "$R2" --json 2>/dev/null)"
arms=$(printf '%s' "$OUT2" | jq_get "sorted(d['arms'])")
[ "$arms" = "['fork', 'upstream']" ] && pass "groups runs into fork and upstream arms" \
    || fail "arms are fork+upstream" "got '$arms'"

echo "Test: always-on is reported per arm, not maxed across arms"
# fork and upstream fixtures carry identical payloads here, so each arm must
# report its own 191-char total rather than one merged figure.
fork_tot=$(printf '%s' "$OUT2" | jq_get "d['always_on_by_arm']['fork']['total_chars']")
up_tot=$(printf '%s' "$OUT2" | jq_get "d['always_on_by_arm']['upstream']['total_chars']")
[ "$fork_tot" = "191" ] && pass "fork arm reports its own always-on total" \
    || fail "fork arm always-on total 191" "got '$fork_tot'"
[ "$up_tot" = "191" ] && pass "upstream arm reports its own always-on total" \
    || fail "upstream arm always-on total 191" "got '$up_tot'"
arm_keys=$(printf '%s' "$OUT2" | jq_get "sorted(d['always_on_by_arm'])")
[ "$arm_keys" = "['fork', 'upstream']" ] && pass "always_on_by_arm has one entry per arm" \
    || fail "always_on_by_arm keyed by arm" "got '$arm_keys'"

echo "Test: redundancy detection"
reads=$(printf '%s' "$OUT" | jq_get "d['redundancy'][0]['reads']['/w/a.py']")
[ "$reads" = "2" ] && pass "flags the same file Read twice" || fail "repeat Read flagged" "got '$reads'"

echo "Test: malformed trailing line does not abort the run"
# The fixture ends with a truncated JSON line; if it aborted, turns would be < 2.
[ "$turns" = "2" ] && pass "truncated final line skipped, run still analyzed" \
    || fail "truncated line tolerated" "turns=$turns"

echo "Test: tool mix counted"
bash_n=$(printf '%s' "$OUT" | jq_get "d['tools']['Bash']")
[ "$bash_n" = "1" ] && pass "counts 1 Bash call" || fail "Bash count 1" "got '$bash_n'"

echo "Test: turn multiplier flows into the token-reads estimate"
OUT3="$($ANALYZE "$R1" --turns 10 --json 2>/dev/null)"
tr=$(printf '%s' "$OUT3" | jq_get "d['always_on']['token_reads_per_run_est']")
# 191 chars // 4 = 47 tok; 47 * 10 = 470
[ "$tr" = "470" ] && pass "--turns 10 yields 470 token-reads (47 tok x 10)" \
    || fail "--turns multiplier applied" "got '$tr'"

echo "Test: a single run dir is accepted directly"
$ANALYZE "$R1/run-a" >/dev/null 2>&1
[ $? -eq 0 ] && pass "single run dir accepted (exit 0)" || fail "single run dir accepted" "nonzero exit"

echo "Test: exit codes"
EMPTY="$TMP/empty"; mkdir -p "$EMPTY"
$ANALYZE "$EMPTY" >/dev/null 2>&1
[ $? -eq 1 ] && pass "no analyzable runs exits 1" || fail "empty dir exits 1" "wrong code"
$ANALYZE "$TMP/does-not-exist" >/dev/null 2>&1
[ $? -eq 2 ] && pass "missing path exits 2" || fail "missing path exits 2" "wrong code"
$ANALYZE "$R1" --turns 0 >/dev/null 2>&1
[ $? -eq 2 ] && pass "--turns 0 rejected with exit 2" || fail "--turns 0 rejected" "wrong code"

echo "Test: a run missing verdict.json is skipped, not fatal"
R4="$TMP/r4"; mkdir -p "$R4"
mkrun "$R4" good pass /repo/skills/writing-plans
mkdir -p "$R4/bad/home/.claude/projects/p"; echo '{}' > "$R4/bad/home/.claude/projects/p/s.jsonl"
OUT4="$($ANALYZE "$R4" --json 2>/dev/null)"
n=$(printf '%s' "$OUT4" | jq_get "d['runs']")
[ "$n" = "1" ] && pass "incomplete run skipped, complete one still reported" \
    || fail "skips incomplete run" "runs=$n"

echo "Test: table mode renders without error"
$ANALYZE "$R1" >/dev/null 2>&1
[ $? -eq 0 ] && pass "table output exits 0" || fail "table output" "nonzero exit"

echo
if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: PASSED ($PASS assertions)"
    exit 0
fi
echo "STATUS: FAILED ($FAIL failed, $PASS passed)"
exit 1
