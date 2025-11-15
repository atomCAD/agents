#!/bin/bash
# Unit tests for create.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC1091
source "$(dirname "$0")/../common.sh"

CREATE_SCRIPT="$SCRIPT_DIR/scripts/create.sh"

### CREATE TESTS ###

# Test: Create checkpoint with unstaged changes
test_create_unstaged() {
    setup_test_env

    echo "modified" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test-unstaged" 2>/dev/null)

    assert_success "[ -n \"$hash\" ]" "Returns non-empty hash"
    assert_success "git stash list --format='%H' | grep -qF \"$hash\"" "Checkpoint exists in stash"
}

# Test: Create checkpoint with staged changes
test_create_staged() {
    setup_test_env

    echo "staged" > staged.txt
    git add staged.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test-staged" 2>/dev/null)

    assert_success "[ -n \"$hash\" ]" "Checkpoint with staged changes created"
    assert_success "git stash list --format='%H' | grep -qF \"$hash\"" "Checkpoint exists"
}

# Test: Create checkpoint with mixed staged and unstaged changes
test_create_mixed() {
    setup_test_env

    echo "staged" > staged.txt
    git add staged.txt
    echo "unstaged" > file.txt

    local hash
    hash=$("$CREATE_SCRIPT" "test-mixed" 2>/dev/null)

    assert_success "[ -n \"$hash\" ]" "Checkpoint with mixed changes created"
    assert_success "git stash list --format='%gs' | grep -qF 'test-mixed'" "Message contains namespace"
}

# Test: Create checkpoint with untracked files
test_create_untracked() {
    setup_test_env

    echo "untracked" > newfile.txt

    local hash
    hash=$("$CREATE_SCRIPT" "test-untracked" 2>/dev/null)

    assert_success "[ -n \"$hash\" ]" "Checkpoint with untracked files created"

    # Verify untracked file was captured in third parent (^3)
    assert_success "git rev-parse \"$hash^3^{tree}\" >/dev/null 2>&1" "Untracked tree exists in third parent"
    assert_success "git ls-tree -r \"$hash^3^{tree}\" --name-only | grep -qF 'newfile.txt'" "Untracked file captured"
}

# Test: Create checkpoint with untracked directories
test_create_untracked_directory() {
    setup_test_env

    mkdir -p untracked_dir/nested
    echo "content1" > untracked_dir/file1.txt
    echo "content2" > untracked_dir/nested/file2.txt
    echo "root_untracked" > root_file.txt

    local hash
    hash=$("$CREATE_SCRIPT" "test-untracked-dir" 2>/dev/null)

    assert_success "[ -n \"$hash\" ]" "Checkpoint with untracked directories created"

    # Verify untracked tree exists
    assert_success "git rev-parse \"$hash^3^{tree}\" >/dev/null 2>&1" "Untracked tree exists in third parent"

    # Verify all untracked files were captured
    assert_success "git ls-tree -r \"$hash^3^{tree}\" --name-only | grep -qF 'untracked_dir/file1.txt'" "Untracked dir file captured"
    assert_success "git ls-tree -r \"$hash^3^{tree}\" --name-only | grep -qF 'untracked_dir/nested/file2.txt'" "Nested untracked file captured"
    assert_success "git ls-tree -r \"$hash^3^{tree}\" --name-only | grep -qF 'root_file.txt'" "Root untracked file captured"
}

# Test: Create checkpoint captures index tree in second parent
test_create_index_structure() {
    setup_test_env

    echo "staged" > staged.txt
    git add staged.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test-structure" 2>/dev/null)

    # Verify checkpoint has second parent with index tree
    assert_success "git rev-parse \"$hash^2^{tree}\" >/dev/null 2>&1" "Index tree exists in second parent"

    # Verify staged.txt is in the index tree
    assert_success "git ls-tree -r \"$hash^2^{tree}\" --name-only | grep -qF 'staged.txt'" "Staged file in index tree"
}

# Test: Create fails with missing namespace argument
test_create_missing_arg() {
    setup_test_env

    echo "modified" > file.txt

    local exit_code=0
    "$CREATE_SCRIPT" || exit_code=$?

    assert_equals "$EXIT_USAGE_ERROR" "$exit_code" "Exits with usage error when missing argument"
}

# Test: Checkpoint message includes timestamp
test_create_message_format() {
    setup_test_env

    echo "modified" > file.txt

    local hash
    hash=$("$CREATE_SCRIPT" "test-format" 2>/dev/null)
    local message
    message=$(git stash list --format="%gs" | head -n1)

    assert_success "echo \"$message\" | grep -q 'test-format-20'" "Message contains namespace and timestamp"
}

### EDGE CASE TESTS ###

# Test: Create with completely clean working tree (no changes)
test_create_clean_tree() {
    setup_test_env

    # Working tree is clean after setup_test_repo (just has initial commit)
    # Verify tree is actually clean
    assert_success "git diff --quiet HEAD" "Working tree is clean"
    assert_success "[ -z \"\$(git ls-files --others --exclude-standard)\" ]" "No untracked files"

    # Try to create checkpoint with clean tree
    local exit_code=0
    "$CREATE_SCRIPT" "clean-tree-test" || exit_code=$?

    # Git stash refuses to stash when there are no changes
    # This should fail (exit non-zero)
    assert_equals "$EXIT_ERROR" "$exit_code" "Create fails with clean working tree"
}

# Test: Verify index tree is empty when only unstaged changes exist
test_create_empty_index_unstaged_only() {
    setup_test_env

    # Make only unstaged changes (no git add)
    echo "unstaged only" > file.txt

    local hash
    hash=$("$CREATE_SCRIPT" "unstaged-only" 2>/dev/null)

    # Verify checkpoint was created
    assert_success "[ -n \"$hash\" ]" "Checkpoint created"

    # Verify index tree matches HEAD (no staged changes)
    local index_tree head_tree
    index_tree=$(git rev-parse "$hash^2^{tree}")
    head_tree=$(git rev-parse "HEAD^{tree}")
    assert_equals "$head_tree" "$index_tree" "Index tree matches HEAD for unstaged-only changes"
}

### RUN ALL TESTS ###

run_test test_create_unstaged
run_test test_create_staged
run_test test_create_mixed
run_test test_create_untracked
run_test test_create_untracked_directory
run_test test_create_index_structure
run_test test_create_missing_arg
run_test test_create_message_format

# Edge case tests
run_test test_create_clean_tree
run_test test_create_empty_index_unstaged_only

return_test_status
