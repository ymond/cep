#!/usr/bin/env bash
# Tests for `cep init` — scaffolding, assembly, and re-init behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CEP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CEP_BIN="$CEP_DIR/bin/cep"

source "$SCRIPT_DIR/test_harness.sh"

# --- Tests ---

test_init_creates_cep_directory() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    assert_dir_exists "$_TEST_TMPDIR/.cep"
    assert_dir_exists "$_TEST_TMPDIR/.cep/logs"
    assert_dir_exists "$_TEST_TMPDIR/.cep/decisions"
    assert_dir_exists "$_TEST_TMPDIR/.cep/blog"
    assert_dir_exists "$_TEST_TMPDIR/.cep/guidebook"
}

test_init_creates_version_marker() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    assert_file_exists "$_TEST_TMPDIR/.cep/version"
    local expected_version
    expected_version="$(cat "$CEP_DIR/VERSION")"
    local actual_version
    actual_version="$(cat "$_TEST_TMPDIR/.cep/version")"
    assert_equals "$expected_version" "$actual_version" "Version marker should match CEP VERSION"
}

test_init_creates_claude_local() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    assert_file_exists "$_TEST_TMPDIR/.cep/CLAUDE.local.md"
    assert_file_contains "$_TEST_TMPDIR/.cep/CLAUDE.local.md" "testproj"
}

test_init_creates_mikado_yaml() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    assert_file_exists "$_TEST_TMPDIR/.cep/mikado.yaml"
    assert_file_contains "$_TEST_TMPDIR/.cep/mikado.yaml" "testproj"
    assert_file_contains "$_TEST_TMPDIR/.cep/mikado.yaml" "status: active"
}

test_init_assembles_claude_md() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    assert_file_exists "$_TEST_TMPDIR/CLAUDE.md"
    # Check placeholder substitution
    assert_file_contains "$_TEST_TMPDIR/CLAUDE.md" "Project: testproj"
    assert_file_contains "$_TEST_TMPDIR/CLAUDE.md" "CEP v"
    # Check no raw placeholders remain (except in prose about the template system)
    assert_file_not_contains "$_TEST_TMPDIR/CLAUDE.md" "\{\{CEP_VERSION\}\}"
    assert_file_not_contains "$_TEST_TMPDIR/CLAUDE.md" "\{\{PROJECT_NAME\}\}"
    assert_file_not_contains "$_TEST_TMPDIR/CLAUDE.md" "\{\{UPGRADE_DATE\}\}"
    assert_file_not_contains "$_TEST_TMPDIR/CLAUDE.md" "\{\{PROJECT_SPECIFIC\}\}"
}

test_init_injects_local_content() {
    # Pre-create a CLAUDE.local.md with known content
    mkdir -p "$_TEST_TMPDIR/.cep"
    echo "## My Custom Section" > "$_TEST_TMPDIR/.cep/CLAUDE.local.md"
    echo "This is custom project content." >> "$_TEST_TMPDIR/.cep/CLAUDE.local.md"

    # Pipe 'y' because .cep/ already exists, triggering re-init prompt
    echo "y" | "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    assert_file_contains "$_TEST_TMPDIR/CLAUDE.md" "My Custom Section"
    assert_file_contains "$_TEST_TMPDIR/CLAUDE.md" "This is custom project content"
}

test_init_preserves_existing_local_on_reinit() {
    # First init
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    # Customize the local file
    echo "## Preserved Content" > "$_TEST_TMPDIR/.cep/CLAUDE.local.md"

    # Re-init (non-interactive, so we pipe 'y')
    echo "y" | "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    assert_file_contains "$_TEST_TMPDIR/.cep/CLAUDE.local.md" "Preserved Content"
}

test_init_preserves_existing_mikado_on_reinit() {
    # First init
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    # Customize the mikado
    echo "project: testproj" > "$_TEST_TMPDIR/.cep/mikado.yaml"
    echo "custom: preserved" >> "$_TEST_TMPDIR/.cep/mikado.yaml"

    # Re-init
    echo "y" | "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    assert_file_contains "$_TEST_TMPDIR/.cep/mikado.yaml" "custom: preserved"
}

test_init_registers_project() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    assert_file_exists "$CEP_DIR/.registry/projects"
    assert_file_contains "$CEP_DIR/.registry/projects" "$_TEST_TMPDIR"
}

test_init_deduplicates_registry() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    echo "y" | "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1

    local count
    count=$(grep -c "$_TEST_TMPDIR" "$CEP_DIR/.registry/projects")
    assert_equals "1" "$count" "Registry should not contain duplicate entries"
}

test_init_copies_mikado_spec() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    assert_file_exists "$_TEST_TMPDIR/.cep/mikado-spec.md"
    diff -q "$CEP_DIR/templates/mikado-spec.md" "$_TEST_TMPDIR/.cep/mikado-spec.md" >/dev/null 2>&1 \
        || { _fail "mikado-spec.md should match the source template"; return 1; }
}

test_init_no_leftover_assembled_file() {
    "$CEP_BIN" init "$_TEST_TMPDIR" "testproj" >/dev/null 2>&1
    if [[ -f "$_TEST_TMPDIR/.cep/CLAUDE.md.assembled" ]]; then
        _fail "Temporary .cep/CLAUDE.md.assembled should be cleaned up"
        return 1
    fi
}

# --- Run ---

run_tests \
    test_init_creates_cep_directory \
    test_init_creates_version_marker \
    test_init_creates_claude_local \
    test_init_creates_mikado_yaml \
    test_init_assembles_claude_md \
    test_init_injects_local_content \
    test_init_preserves_existing_local_on_reinit \
    test_init_preserves_existing_mikado_on_reinit \
    test_init_copies_mikado_spec \
    test_init_registers_project \
    test_init_deduplicates_registry \
    test_init_no_leftover_assembled_file
