#!/usr/bin/env bash
# Tests for `cep diff` — preview upgrade changes without applying.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CEP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CEP_BIN="$CEP_DIR/bin/cep"

source "$SCRIPT_DIR/test_harness.sh"

# --- Tests ---

test_diff_no_output_when_current() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    local output
    output="$("$CEP_BIN" diff "$_TEST_TMPDIR" 2>&1)"
    assert_equals "" "$output" "Diff should produce no output when project is current"
}

test_diff_shows_changes_when_outdated() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    # Tamper with the assembled CLAUDE.md
    echo "MODIFIED CONTENT" >> "$_TEST_TMPDIR/CLAUDE.md"

    local output
    output="$("$CEP_BIN" diff "$_TEST_TMPDIR" 2>&1)"
    if [[ -z "$output" ]]; then
        _fail "Diff should show changes when CLAUDE.md has been modified"
    fi
}

test_diff_does_not_modify_claude_md() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    echo "ADDED LINE" >> "$_TEST_TMPDIR/CLAUDE.md"

    # Record the content before diff
    local before
    before="$(cat "$_TEST_TMPDIR/CLAUDE.md")"

    "$CEP_BIN" diff "$_TEST_TMPDIR" >/dev/null 2>&1

    local after
    after="$(cat "$_TEST_TMPDIR/CLAUDE.md")"
    assert_equals "$before" "$after" "Diff should not modify CLAUDE.md"
}

test_diff_does_not_modify_version() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    echo "0.0.1" > "$_TEST_TMPDIR/.cep/version"

    "$CEP_BIN" diff "$_TEST_TMPDIR" >/dev/null 2>&1

    local version_after
    version_after="$(cat "$_TEST_TMPDIR/.cep/version")"
    assert_equals "0.0.1" "$version_after" "Diff should not update version marker"
}

test_diff_on_non_cep_project_fails() {
    local non_cep_dir
    non_cep_dir="$(mktemp -d)"
    assert_exit_code 1 "$CEP_BIN" diff "$non_cep_dir"
    rm -rf "$non_cep_dir"
}

# --- Run ---

run_tests \
    test_diff_no_output_when_current \
    test_diff_shows_changes_when_outdated \
    test_diff_does_not_modify_claude_md \
    test_diff_does_not_modify_version \
    test_diff_on_non_cep_project_fails
