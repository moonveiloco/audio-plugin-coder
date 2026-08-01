#!/usr/bin/env bash
# ACP Config Contract Tests (macOS/Linux)
#
# Verifies the behavior contract of scripts/acp-config.sh:
#   - plugins-dir / juce-dir exit 1 + stderr when value is null/empty
#   - is-setup exits 1 when setup_complete != true, 0 when true
#   - get <key> stays permissive (exit 0, empty stdout) for null values
#   - set writes values that plugins-dir then returns
#
# Isolation: uses a throwaway XDG_CONFIG_HOME so the real
# ~/.config/acp/config.json is never touched.
#
# Usage: bash scripts/test-acp-config.sh
# Exit: 0 = all tests passed, 1 = at least one failed

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACP_CONFIG="$SCRIPT_DIR/acp-config.sh"

PASS=0
FAIL=0
TMP=""

cleanup() {
    [[ -n "$TMP" && -d "$TMP" ]] && rm -rf "$TMP"
}
trap cleanup EXIT

assert() {
    local desc="$1" expected_exit="$2" expected_out="$3" actual_exit="$4" actual_out="$5"
    if [[ "$actual_exit" == "$expected_exit" && "$actual_out" == "$expected_out" ]]; then
        PASS=$((PASS + 1))
        printf "  ok  %s\n" "$desc"
    else
        FAIL=$((FAIL + 1))
        printf "  FAIL %s\n" "$desc"
        printf "      expected exit=%s out=<%s>\n" "$expected_exit" "$expected_out"
        printf "      actual   exit=%s out=<%s>\n" "$actual_exit" "$actual_out"
    fi
}

# Isolate: redirect config to a temp dir
TMP="$(mktemp -d)"
export XDG_CONFIG_HOME="$TMP"

echo "ACP Config Contract Tests"
echo "=========================="

# --- Test 1: config file absent -> plugins-dir exits 1, no stdout ---
rc=0; out="$(bash "$ACP_CONFIG" plugins-dir 2>/dev/null)" || rc=$?
assert "config absent: plugins-dir exit 1" 1 "" "$rc" "$out"

rc=0; out="$(bash "$ACP_CONFIG" juce-dir 2>/dev/null)" || rc=$?
assert "config absent: juce-dir exit 1" 1 "" "$rc" "$out"

rc=0; bash "$ACP_CONFIG" is-setup >/dev/null 2>&1 || rc=$?
assert "config absent: is-setup exit 1" 1 "" "$rc" ""

# --- Test 2: init creates default config (setup_complete=false) ---
bash "$ACP_CONFIG" init >/dev/null 2>&1
rc=0; out="$(bash "$ACP_CONFIG" get setup_complete)" || rc=$?
assert "init: setup_complete=false" 0 "false" "$rc" "$out"

rc=0; bash "$ACP_CONFIG" is-setup >/dev/null 2>&1 || rc=$?
assert "init: is-setup still 1" 1 "" "$rc" ""

# --- Test 3: plugins-dir / juce-dir still fail when null (but config exists) ---
rc=0; out="$(bash "$ACP_CONFIG" plugins-dir 2>/dev/null)" || rc=$?
assert "null plugins_dir: plugins-dir exit 1" 1 "" "$rc" "$out"

rc=0; out="$(bash "$ACP_CONFIG" juce-dir 2>/dev/null)" || rc=$?
assert "null juce_dir: juce-dir exit 1" 1 "" "$rc" "$out"

# --- Test 4: get stays permissive for null value ---
rc=0; out="$(bash "$ACP_CONFIG" get juce_dir)" || rc=$?
assert "get juce_dir permissive (empty, exit 0)" 0 "" "$rc" "$out"

rc=0; out="$(bash "$ACP_CONFIG" get nonexistent_key)" || rc=$?
assert "get unknown key permissive (empty, exit 0)" 0 "" "$rc" "$out"

# --- Test 5: set + read back ---
bash "$ACP_CONFIG" set plugins_dir "$TMP/myplugins" >/dev/null 2>&1
rc=0; out="$(bash "$ACP_CONFIG" plugins-dir 2>/dev/null)" || rc=$?
assert "after set plugins_dir: plugins-dir exit 0 + value" 0 "$TMP/myplugins" "$rc" "$out"

bash "$ACP_CONFIG" set juce_dir "$TMP/juce" >/dev/null 2>&1
rc=0; out="$(bash "$ACP_CONFIG" juce-dir 2>/dev/null)" || rc=$?
assert "after set juce_dir: juce-dir exit 0 + value" 0 "$TMP/juce" "$rc" "$out"

# --- Test 6: setup_complete=true flips is-setup ---
bash "$ACP_CONFIG" set setup_complete true >/dev/null 2>&1
rc=0; bash "$ACP_CONFIG" is-setup >/dev/null 2>&1 || rc=$?
assert "setup_complete=true: is-setup exit 0" 0 "" "$rc" ""

# --- Test 7: plugins-dir exits 1 if value set to empty string ---
bash "$ACP_CONFIG" set plugins_dir "" >/dev/null 2>&1
rc=0; out="$(bash "$ACP_CONFIG" plugins-dir 2>/dev/null)" || rc=$?
assert "empty plugins_dir: plugins-dir exit 1" 1 "" "$rc" "$out"

# --- Test 8: path command prints the isolated config path ---
rc=0; out="$(bash "$ACP_CONFIG" path)" || rc=$?
assert "path command prints XDG path" 0 "$TMP/acp/config.json" "$rc" "$out"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0