#!/bin/bash
# Safe Clearing Operations Tests
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC1091
source "$(dirname "$0")/../common.sh"

CREATE_SCRIPT="$SCRIPT_DIR/scripts/create.sh"
CLEAR_SCRIPT="$SCRIPT_DIR/scripts/clear.sh"

### CLEAR TESTS ###

# Test: Clear succeeds when checkpoint matches current state
test_clear_matching_state() {
    setup_test_env

    # Make changes and checkpoint them
    echo "modified" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Recreate the same state (create.sh stashed it, so working tree is clean now)
    echo "modified" > file.txt

    local exit_code=0
    "$CLEAR_SCRIPT" "$hash" >/dev/null 2>&1 || exit_code=$?

    assert_equals "$EXIT_SUCCESS" "$exit_code" "Clear succeeds with matching state"

    # CRITICAL: Working tree must be clean after clear to prevent accidental commits
    assert_success "git diff --quiet" "Working tree cleared"

}

# Test: Clear fails when checkpoint doesn't match current state
test_clear_non_matching_state() {
    setup_test_env

    # Create checkpoint of state A
    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Create different state B (after stash, tree is clean, so make new changes)
    echo "different changes" > file.txt

    local exit_code=0
    "$CLEAR_SCRIPT" "$hash" 2>/dev/null || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Clear fails with non-matching state"

    # Note: clear.sh creates temp checkpoint during verification, which stashes
    # the "different changes", so tree ends up clean. This is expected behavior.

}

# Test: Clear fails with invalid hash
test_clear_invalid_hash() {
    setup_test_env

    echo "modified" > file.txt

    local exit_code=0
    "$CLEAR_SCRIPT" "abc123fake" 2>/dev/null || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Fails with invalid hash"

}

# Test: Clear fails with missing argument
test_clear_missing_arg() {
    setup_test_env

    echo "modified" > file.txt

    local exit_code=0
    "$CLEAR_SCRIPT" 2>/dev/null || exit_code=$?

    assert_equals "$EXIT_USAGE_ERROR" "$exit_code" "Exits with usage error when missing argument"

}

# Test: Clear removes untracked files
test_clear_removes_untracked() {
    setup_test_env

    echo "untracked" > newfile.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Recreate the same state (create.sh stashed it, so working tree is clean now)
    echo "untracked" > newfile.txt

    "$CLEAR_SCRIPT" "$hash" >/dev/null 2>&1

    assert_failure "[ -f newfile.txt ]" "Untracked files removed"

}

# Test: Clear removes staged changes
test_clear_removes_staged() {
    setup_test_env

    # Create staged changes and checkpoint
    echo "staged" > staged.txt
    git add staged.txt >/dev/null 2>&1
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Recreate same staged state (after stash, tree is clean)
    echo "staged" > staged.txt
    git add staged.txt >/dev/null 2>&1

    "$CLEAR_SCRIPT" "$hash" >/dev/null 2>&1

    # CRITICAL: Staging area must be cleared to prevent accidental commits of wrong changes
    assert_success "git diff --staged --quiet" "Staging area cleared"

}

# Test: Clear is idempotent (can run twice safely)
test_clear_idempotent() {
    setup_test_env

    echo "modified" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Recreate the same state (create.sh stashed it, so working tree is clean now)
    echo "modified" > file.txt

    "$CLEAR_SCRIPT" "$hash" >/dev/null 2>&1

    # After first clear, working tree is clean, so create.sh will create clean state checkpoint
    # This second clear attempt should fail because tree states don't match
    local exit_code=0
    "$CLEAR_SCRIPT" "$hash" 2>/dev/null || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Second clear fails (tree doesn't match)"

}

### NEW TESTS - EDGE CASES AND SAFETY ###

# Test: Working tree preserved when verification fails (modified files)
test_clear_preserves_tree_when_verification_fails() {
    setup_test_env

    # Create checkpoint of state A
    echo "checkpoint state" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Create different state B
    echo "different state" > file.txt

    # Try to clear with mismatched checkpoint - should fail
    local exit_code=0
    "$CLEAR_SCRIPT" "$hash" 2>/dev/null || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Clear fails with non-matching state"

    # CRITICAL: Working tree must be preserved when verification fails - no data loss
    assert_success "[ -f file.txt ]" "file.txt still exists"
    local content
    content=$(cat file.txt)
    assert_equals "different state" "$content" "Working tree preserved with original changes"

}

# Test: Untracked files preserved when verification fails
test_clear_preserves_untracked_when_verification_fails() {
    setup_test_env

    # Create checkpoint without untracked file
    echo "tracked" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Add untracked file
    echo "untracked content" > newfile.txt

    # Try to clear - should fail (trees don't match)
    local exit_code=0
    "$CLEAR_SCRIPT" "$hash" 2>/dev/null || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Clear fails with different state"

    # CRITICAL: Untracked files must be preserved on failure - no data loss
    assert_success "[ -f newfile.txt ]" "Untracked file preserved"
    local content
    content=$(cat newfile.txt)
    assert_equals "untracked content" "$content" "Untracked file content intact"

}

# Test: Staged changes preserved when verification fails
test_clear_preserves_staged_when_verification_fails() {
    setup_test_env

    # Create checkpoint of unstaged state
    echo "unstaged" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Create and stage different changes
    echo "staged content" > staged.txt
    git add staged.txt >/dev/null 2>&1

    # Try to clear - should fail (trees don't match)
    local exit_code=0
    "$CLEAR_SCRIPT" "$hash" 2>/dev/null || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Clear fails with different state"

    # CRITICAL: Staged changes should still be staged
    assert_failure "git diff --staged --quiet" "Staged changes still exist"
    assert_success "git diff --staged --name-only | grep -q staged.txt" "staged.txt still staged"

}

# Test: No orphaned temp checkpoints after verification failure
test_clear_no_orphaned_temp_checkpoint() {
    setup_test_env

    # Count initial stashes
    local initial_count
    initial_count=$(git stash list | wc -l | xargs)

    # Create checkpoint
    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Create different state and try to clear
    echo "different" > file.txt
    "$CLEAR_SCRIPT" "$hash" 2>/dev/null || true

    # Count stashes after failed clear
    local final_count
    final_count=$(git stash list | wc -l | xargs)

    # Should only have the original checkpoint, no temp stash left behind
    local expected_count=$((initial_count + 1))
    assert_equals "$expected_count" "$final_count" "No orphaned temp checkpoints"

}

# Test: No orphaned temp checkpoints after successful clear
test_clear_no_orphaned_temp_checkpoint_after_success() {
    setup_test_env

    # Count initial stashes
    local initial_count
    initial_count=$(git stash list | wc -l | xargs)

    # Create checkpoint and matching state
    echo "modified" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Recreate same state
    echo "modified" > file.txt

    # Clear should succeed
    "$CLEAR_SCRIPT" "$hash" >/dev/null 2>&1

    # Count stashes - should only have original checkpoint
    local final_count
    final_count=$(git stash list | wc -l | xargs)
    local expected_count=$((initial_count + 1))

    assert_equals "$expected_count" "$final_count" "No orphaned temp checkpoint after success"

}

# Test: Graceful handling of invalid checkpoint hash during tree parsing
test_clear_handles_corrupted_checkpoint() {
    setup_test_env

    echo "modified" > file.txt
    local original_content="modified"

    # Create a valid checkpoint first
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Recreate the state
    echo "modified" > file.txt

    # Manually corrupt the stash by dropping it, then try to use it
    git stash drop "stash@{0}" >/dev/null 2>&1

    # Try to clear with now-invalid hash
    local exit_code=0
    "$CLEAR_SCRIPT" "$hash" 2>/dev/null || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Clear fails with corrupted checkpoint"

    # Working tree should be preserved
    assert_success "[ -f file.txt ]" "file.txt still exists after error"
    local content
    content=$(cat file.txt)
    assert_equals "$original_content" "$content" "Working tree preserved after error"

}

# Test: Clear fails when working tree is clean (temp checkpoint creation fails)
test_clear_fails_with_clean_tree() {
    setup_test_env

    # Create a checkpoint with changes
    echo "modified" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Now working tree is clean (create.sh stashed the changes)
    # Verify tree is clean
    assert_success "git diff --quiet HEAD" "Working tree is clean"

    # Try to clear - should fail because temp checkpoint can't be created on clean tree
    local exit_code=0
    "$CLEAR_SCRIPT" "$hash" 2>/dev/null || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Clear fails with clean working tree"

}

### RUN ALL TESTS ###

run_test test_clear_matching_state
run_test test_clear_non_matching_state
run_test test_clear_invalid_hash
run_test test_clear_missing_arg
run_test test_clear_removes_untracked
run_test test_clear_removes_staged
run_test test_clear_idempotent

# Edge case and safety tests
run_test test_clear_preserves_tree_when_verification_fails
run_test test_clear_preserves_untracked_when_verification_fails
run_test test_clear_preserves_staged_when_verification_fails
run_test test_clear_no_orphaned_temp_checkpoint
run_test test_clear_no_orphaned_temp_checkpoint_after_success
run_test test_clear_handles_corrupted_checkpoint
run_test test_clear_fails_with_clean_tree

print_results
