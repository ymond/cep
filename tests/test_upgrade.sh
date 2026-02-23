#!/usr/bin/env bash
# Tests for `cep upgrade` — version comparison, reassembly, preservation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CEP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CEP_BIN="$CEP_DIR/bin/cep"

source "$SCRIPT_DIR/test_harness.sh"

# Helper: init a project at a given "old" version by temporarily faking VERSION
_init_at_version() {
    local path="$1"
    local name="$2"
    local version="$3"
    "$CEP_BIN" init "$path" "$name" >/dev/null 2>&1
    # Backdate the version to simulate an older install
    echo "$version" > "$path/.cep/version"
}

# --- Tests ---

test_upgrade_updates_version() {
    _init_at_version "$_TEST_TMPDIR" "testproj" "0.1.0"

    "$CEP_BIN" upgrade "$_TEST_TMPDIR" >/dev/null 2>&1
    local expected_version
    expected_version="$(cat "$CEP_DIR/VERSION")"
    local actual_version
    actual_version="$(cat "$_TEST_TMPDIR/.cep/version")"
    assert_equals "$expected_version" "$actual_version" "Version should be updated to current"
}

test_upgrade_reassembles_claude_md() {
    _init_at_version "$_TEST_TMPDIR" "testproj" "0.1.0"

    # Tamper with CLAUDE.md to simulate old template output
    echo "OLD CONTENT" > "$_TEST_TMPDIR/CLAUDE.md"

    "$CEP_BIN" upgrade "$_TEST_TMPDIR" >/dev/null 2>&1
    assert_file_contains "$_TEST_TMPDIR/CLAUDE.md" "CEP v"
    assert_file_not_contains "$_TEST_TMPDIR/CLAUDE.md" "OLD CONTENT"
}

test_upgrade_preserves_local_content() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    # Customize local
    echo "## Preserved During Upgrade" > "$_TEST_TMPDIR/.cep/CLAUDE.local.md"
    # Backdate version to trigger upgrade
    echo "0.1.0" > "$_TEST_TMPDIR/.cep/version"

    "$CEP_BIN" upgrade "$_TEST_TMPDIR" >/dev/null 2>&1
    assert_file_contains "$_TEST_TMPDIR/CLAUDE.md" "Preserved During Upgrade"
    assert_file_contains "$_TEST_TMPDIR/.cep/CLAUDE.local.md" "Preserved During Upgrade"
}

test_upgrade_exits_when_current() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    # Already at current version — upgrade should exit cleanly
    local output
    output="$("$CEP_BIN" upgrade "$_TEST_TMPDIR" 2>&1)"
    # Should contain "up to date" or "Already"
    if [[ "$output" != *"Already"* && "$output" != *"up to date"* ]]; then
        _fail "Expected 'already up to date' message, got: $output"
    fi
}

test_upgrade_creates_new_directories() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    # Remove blog/ and guidebook/ to simulate older version that didn't have them
    rmdir "$_TEST_TMPDIR/.cep/blog" "$_TEST_TMPDIR/.cep/guidebook"
    echo "0.1.0" > "$_TEST_TMPDIR/.cep/version"

    "$CEP_BIN" upgrade "$_TEST_TMPDIR" >/dev/null 2>&1
    assert_dir_exists "$_TEST_TMPDIR/.cep/blog"
    assert_dir_exists "$_TEST_TMPDIR/.cep/guidebook"
}

test_upgrade_on_non_cep_project_fails() {
    local non_cep_dir
    non_cep_dir="$(mktemp -d)"
    assert_exit_code 1 "$CEP_BIN" upgrade "$non_cep_dir"
    rm -rf "$non_cep_dir"
}

# --- Run ---

run_tests \
    test_upgrade_updates_version \
    test_upgrade_reassembles_claude_md \
    test_upgrade_preserves_local_content \
    test_upgrade_exits_when_current \
    test_upgrade_creates_new_directories \
    test_upgrade_on_non_cep_project_fails
