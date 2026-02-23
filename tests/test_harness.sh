#!/usr/bin/env bash
# Test harness for CEP CLI
# Provides assertion functions and temp directory management.
# Source this file from test scripts, then call run_tests at the end.

set -euo pipefail

# --- State ---
_TESTS_RUN=0
_TESTS_PASSED=0
_TESTS_FAILED=0
_FAILURES=()
_TEST_TMPDIR=""

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Setup / Teardown ---

# Creates a fresh temp directory for each test. Call at the start of each test function.
setup() {
    _TEST_TMPDIR="$(mktemp -d)"
}

# Removes the temp directory. Call at the end of each test function (or rely on run_tests).
teardown() {
    if [[ -n "$_TEST_TMPDIR" && -d "$_TEST_TMPDIR" ]]; then
        rm -rf "$_TEST_TMPDIR"
        _TEST_TMPDIR=""
    fi
}

# --- Assertions ---

# assert_equals <expected> <actual> [message]
# Compares two string values.
assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-Expected '$expected', got '$actual'}"
    if [[ "$expected" != "$actual" ]]; then
        _fail "$msg"
        return 1
    fi
    return 0
}

# assert_not_equals <unexpected> <actual> [message]
assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local msg="${3:-Expected value to differ from '$unexpected'}"
    if [[ "$unexpected" == "$actual" ]]; then
        _fail "$msg"
        return 1
    fi
    return 0
}

# assert_file_exists <path> [message]
assert_file_exists() {
    local path="$1"
    local msg="${2:-File does not exist: $path}"
    if [[ ! -f "$path" ]]; then
        _fail "$msg"
        return 1
    fi
    return 0
}

# assert_dir_exists <path> [message]
assert_dir_exists() {
    local path="$1"
    local msg="${2:-Directory does not exist: $path}"
    if [[ ! -d "$path" ]]; then
        _fail "$msg"
        return 1
    fi
    return 0
}

# assert_file_contains <path> <pattern> [message]
# Pattern is a grep extended regex.
assert_file_contains() {
    local path="$1"
    local pattern="$2"
    local msg="${3:-File '$path' does not contain pattern '$pattern'}"
    if ! grep -qE "$pattern" "$path" 2>/dev/null; then
        _fail "$msg"
        return 1
    fi
    return 0
}

# assert_file_not_contains <path> <pattern> [message]
assert_file_not_contains() {
    local path="$1"
    local pattern="$2"
    local msg="${3:-File '$path' unexpectedly contains pattern '$pattern'}"
    if grep -qE "$pattern" "$path" 2>/dev/null; then
        _fail "$msg"
        return 1
    fi
    return 0
}

# assert_exit_code <expected_code> <command...>
# Runs a command and checks its exit code.
assert_exit_code() {
    local expected="$1"
    shift
    local actual
    set +e
    "$@" >/dev/null 2>&1
    actual=$?
    set -e
    if [[ "$actual" -ne "$expected" ]]; then
        _fail "Expected exit code $expected, got $actual for: $*"
        return 1
    fi
    return 0
}

# --- Test Runner ---

# _fail <message>
# Records a failure. Called by assertions.
_fail() {
    local msg="$1"
    _FAILURES+=("$_CURRENT_TEST: $msg")
}

_CURRENT_TEST=""

# run_test <test_function_name>
# Runs a single test function with setup/teardown.
run_test() {
    local test_name="$1"
    _CURRENT_TEST="$test_name"
    _TESTS_RUN=$((_TESTS_RUN + 1))

    local failed_before=${#_FAILURES[@]}

    setup
    # Run the test; capture failures but don't exit on them
    set +e
    "$test_name"
    local test_exit=$?
    set -e
    teardown

    local failed_after=${#_FAILURES[@]}

    if [[ "$failed_after" -gt "$failed_before" || "$test_exit" -ne 0 ]]; then
        _TESTS_FAILED=$((_TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} $test_name"
    else
        _TESTS_PASSED=$((_TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} $test_name"
    fi
}

# run_tests <test_function_names...>
# Runs all listed test functions and prints a summary.
run_tests() {
    local test_file="${BASH_SOURCE[1]:-unknown}"
    echo ""
    echo "Running: $(basename "$test_file")"
    echo "─────────────────────────────────"

    for test_name in "$@"; do
        run_test "$test_name"
    done

    echo ""
    echo "─────────────────────────────────"
    echo -e "Tests: $_TESTS_RUN  Passed: ${GREEN}$_TESTS_PASSED${NC}  Failed: ${RED}$_TESTS_FAILED${NC}"

    if [[ ${#_FAILURES[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failures:${NC}"
        for failure in "${_FAILURES[@]}"; do
            echo "  - $failure"
        done
        echo ""
        return 1
    fi

    echo ""
    return 0
}
