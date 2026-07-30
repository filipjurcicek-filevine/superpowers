#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_UNDER_TEST="$REPO_ROOT/hooks/session-start"
WRAPPER_UNDER_TEST="$REPO_ROOT/hooks/run-hook.cmd"

FAILURES=0
TEST_ROOT="$(mktemp -d)"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

pass() {
    echo "  [PASS] $1"
}

fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

make_home() {
    local name="$1"
    local home="$TEST_ROOT/$name/home"
    mkdir -p "$home"
    printf '%s\n' "$home"
}

assert_command_output() {
    local description="$1"
    local shape="$2"
    local contains="$3"
    local not_contains="$4"
    local home="$5"
    shift 5

    local output
    if ! output="$(env -i PATH="${PATH:-}" HOME="$home" "$@" 2>&1)"; then
        fail "$description"
        echo "    hook exited non-zero"
        echo "$output" | sed 's/^/      /'
        return
    fi

    if printf '%s' "$output" | \
        EXPECT_SHAPE="$shape" \
        EXPECT_CONTAINS="$contains" \
        EXPECT_NOT_CONTAINS="$not_contains" \
        node -e '
const fs = require("fs");

const input = fs.readFileSync(0, "utf8");
let payload;
try {
  payload = JSON.parse(input);
} catch (error) {
  console.error(`invalid JSON: ${error.message}`);
  process.exit(1);
}

function hasOwn(object, key) {
  return Object.prototype.hasOwnProperty.call(object, key);
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

const shape = process.env.EXPECT_SHAPE;
let context;

if (shape === "nested") {
  if (!hasOwn(payload, "hookSpecificOutput")) {
    fail("missing hookSpecificOutput");
  }
  if (hasOwn(payload, "additional_context") || hasOwn(payload, "additionalContext")) {
    fail("nested output also included a top-level context field");
  }
  const hookOutput = payload.hookSpecificOutput;
  if (!hookOutput || typeof hookOutput !== "object" || Array.isArray(hookOutput)) {
    fail("hookSpecificOutput is not an object");
  }
  if (hookOutput.hookEventName !== "SessionStart") {
    fail(`unexpected hookEventName: ${hookOutput.hookEventName}`);
  }
  context = hookOutput.additionalContext;
} else {
  fail(`unknown expected shape: ${shape}`);
}

if (typeof context !== "string" || context.trim() === "") {
  fail("injected context was empty");
}

const expectedText = process.env.EXPECT_CONTAINS || "";
if (expectedText && !context.includes(expectedText)) {
  fail(`context did not contain expected text: ${expectedText}`);
}

const forbiddenTexts = (process.env.EXPECT_NOT_CONTAINS || "")
  .split("\u001f")
  .filter(Boolean);
for (const forbiddenText of forbiddenTexts) {
  if (context.includes(forbiddenText)) {
    fail(`context contained forbidden text: ${forbiddenText}`);
  }
}
'; then
        pass "$description"
    else
        fail "$description"
        echo "    output:"
        echo "$output" | sed 's/^/      /'
    fi
}

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

echo "SessionStart hook output tests"

# Registration shape: the hook must declare shell:"bash" so Claude Code on
# Windows dispatches via Git Bash (or fails with an actionable error) instead
# of PowerShell/cmd.exe, whose parsers break on the quoted command string
# (PowerShell ParserError; cmd.exe quote-stripping on paths with metacharacters).
if node -e '
const hooks = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
const entry = hooks.hooks.SessionStart[0].hooks[0];
if (entry.shell !== "bash") {
  console.error(`SessionStart hook shell is ${JSON.stringify(entry.shell)}, expected "bash"`);
  process.exit(1);
}
if (!/run-hook\.cmd" session-start$/.test(entry.command)) {
  console.error(`unexpected SessionStart command shape: ${entry.command}`);
  process.exit(1);
}
' "$REPO_ROOT/hooks/hooks.json"; then
    pass "hooks.json registers SessionStart with shell:bash dispatch"
else
    fail "hooks.json registers SessionStart with shell:bash dispatch"
fi

claude_home="$(make_home claude-code)"
assert_command_output \
    "Claude Code emits nested SessionStart additionalContext" \
    "nested" \
    "" \
    "" \
    "$claude_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$HOOK_UNDER_TEST"

wrapper_home="$(make_home run-hook-wrapper)"
assert_command_output \
    "run-hook.cmd wrapper dispatches to the named session-start script" \
    "nested" \
    "" \
    "" \
    "$wrapper_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$WRAPPER_UNDER_TEST" session-start

# This fork emits Claude Code's shape unconditionally: other harnesses' env
# vars must not change the payload.
foreign_home="$(make_home foreign-harness-env)"
assert_command_output \
    "Claude Code shape is emitted even with other harnesses' env vars set" \
    "nested" \
    "" \
    "" \
    "$foreign_home" \
    CURSOR_PLUGIN_ROOT="$REPO_ROOT" \
    COPILOT_CLI=1 \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$HOOK_UNDER_TEST"

legacy_home="$(make_home legacy-warning-removed)"
mkdir -p "$legacy_home/.config/superpowers/skills"
assert_command_output \
    "SessionStart omits obsolete legacy custom-skill warning" \
    "nested" \
    "" \
    "Superpowers now uses"$'\037'"~/.config/superpowers/skills"$'\037'"~/.claude/skills"$'\037'"legacy" \
    "$legacy_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$HOOK_UNDER_TEST"

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

if [[ "$FAILURES" -gt 0 ]]; then
    echo "STATUS: FAILED ($FAILURES failure(s))"
    exit 1
fi

echo "STATUS: PASSED"
