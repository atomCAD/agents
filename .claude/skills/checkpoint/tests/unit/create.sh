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
    git add staged.txt >/dev/null 2>&1

    local hash
    hash=$("$CREATE_SCRIPT" "test-staged" 2>/dev/null)

    assert_success "[ -n \"$hash\" ]" "Checkpoint with staged changes created"
    assert_success "git stash list --format='%H' | grep -qF \"$hash\"" "Checkpoint exists"
}

# Test: Create checkpoint with mixed staged and unstaged changes
test_create_mixed() {
    setup_test_env

    echo "staged" > staged.txt
    git add staged.txt >/dev/null 2>&1
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

    # Verify untracked file was captured by checking if it's in the stash's untracked commit
    assert_success "git ls-tree -r \"$hash^3\" --name-only | grep -qF 'newfile.txt'" "Untracked file captured"
}

# Test: Create checkpoint captures .checkpoint-index.patch for staged changes
test_create_index_patch() {
    setup_test_env

    echo "staged" > staged.txt
    git add staged.txt >/dev/null 2>&1

    local hash
    hash=$("$CREATE_SCRIPT" "test-patch" 2>/dev/null)

    # Verify .checkpoint-index.patch is in the stash's untracked files commit
    assert_success "git ls-tree -r \"$hash^3\" --name-only | grep -qF '.checkpoint-index.patch'" "Index patch file captured"
}

# Test: Create fails with missing namespace argument
test_create_missing_arg() {
    setup_test_env

    echo "modified" > file.txt

    local exit_code=0
    "$CREATE_SCRIPT" 2>/dev/null || exit_code=$?

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
    "$CREATE_SCRIPT" "clean-tree-test" 2>/dev/null || exit_code=$?

    # Git stash refuses to stash when there are no changes
    # This should fail (exit non-zero)
    assert_failure "[ \$exit_code -eq 0 ]" "Create fails with clean working tree"
}

# Test: Verify NO patch file created when only unstaged changes exist
test_create_no_patch_unstaged_only() {
    setup_test_env

    # Make only unstaged changes (no git add)
    echo "unstaged only" > file.txt

    local hash
    hash=$("$CREATE_SCRIPT" "unstaged-only" 2>/dev/null)

    # Verify checkpoint was created
    assert_success "[ -n \"$hash\" ]" "Checkpoint created"

    # Verify .checkpoint-index.patch is NOT in the stash's untracked files
    # The untracked commit is the ^3 parent of the stash
    assert_failure "git ls-tree -r \"$hash^3\" --name-only 2>/dev/null | grep -qF '.checkpoint-index.patch'" "No patch file for unstaged-only changes"
}

### RUN ALL TESTS ###

run_test test_create_unstaged
run_test test_create_staged
run_test test_create_mixed
run_test test_create_untracked
run_test test_create_index_patch
run_test test_create_missing_arg
run_test test_create_message_format

# Edge case tests
run_test test_create_clean_tree
run_test test_create_no_patch_unstaged_only

print_results
