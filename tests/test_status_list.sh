#!/usr/bin/env bash
# Tests for `cep status` and `cep list`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CEP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CEP_BIN="$CEP_DIR/bin/cep"

source "$SCRIPT_DIR/test_harness.sh"

# --- Status Tests ---

test_status_shows_project_path() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    local output
    output="$("$CEP_BIN" status "$_TEST_TMPDIR" 2>&1)"
    if [[ "$output" != *"$_TEST_TMPDIR"* ]]; then
        _fail "Status should show the project path"
    fi
}

test_status_shows_version() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    local output
    output="$("$CEP_BIN" status "$_TEST_TMPDIR" 2>&1)"
    local version
    version="$(cat "$CEP_DIR/VERSION")"
    if [[ "$output" != *"$version"* ]]; then
        _fail "Status should show the CEP version"
    fi
}

test_status_shows_up_to_date() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    local output
    output="$("$CEP_BIN" status "$_TEST_TMPDIR" 2>&1)"
    if [[ "$output" != *"Up to date"* ]]; then
        _fail "Status should show 'Up to date' for current projects"
    fi
}

test_status_shows_upgrade_available() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    echo "0.0.1" > "$_TEST_TMPDIR/.cep/version"
    local output
    output="$("$CEP_BIN" status "$_TEST_TMPDIR" 2>&1)"
    if [[ "$output" != *"Upgrade available"* ]]; then
        _fail "Status should show 'Upgrade available' for outdated projects"
    fi
}

test_status_shows_session_count() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    local output
    output="$("$CEP_BIN" status "$_TEST_TMPDIR" 2>&1)"
    if [[ "$output" != *"Session logs:"* ]]; then
        _fail "Status should show session log count"
    fi
}

test_status_on_non_cep_project_fails() {
    local non_cep_dir
    non_cep_dir="$(mktemp -d)"
    assert_exit_code 1 "$CEP_BIN" status "$non_cep_dir"
    rm -rf "$non_cep_dir"
}

# --- List Tests ---

test_list_shows_registered_project() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    local output
    output="$("$CEP_BIN" list 2>&1)"
    if [[ "$output" != *"$_TEST_TMPDIR"* ]]; then
        _fail "List should show the registered project path"
    fi
}

test_list_shows_version() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    local output
    output="$("$CEP_BIN" list 2>&1)"
    local version
    version="$(cat "$CEP_DIR/VERSION")"
    if [[ "$output" != *"$version"* ]]; then
        _fail "List should show project version"
    fi
}

# --- Run ---

run_tests \
    test_status_shows_project_path \
    test_status_shows_version \
    test_status_shows_up_to_date \
    test_status_shows_upgrade_available \
    test_status_shows_session_count \
    test_status_on_non_cep_project_fails \
    test_list_shows_registered_project \
    test_list_shows_version
