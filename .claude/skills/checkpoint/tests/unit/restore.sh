#!/bin/bash
# Tests for restore.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC1091
source "$(dirname "$0")/../common.sh"

CREATE_SCRIPT="$SCRIPT_DIR/scripts/create.sh"
RESTORE_SCRIPT="$SCRIPT_DIR/scripts/restore.sh"
CLEAR_SCRIPT="$SCRIPT_DIR/scripts/clear.sh"

# Restore refuses to run with dirty working tree
test_restore_refuses_dirty_tree() {
    setup_test_env

    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    echo "new changes" > file.txt

    "$RESTORE_SCRIPT" "$hash" 2>/dev/null
    local exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Refuses to restore with dirty working tree"

}

# Restore succeeds with clean working tree
test_restore_succeeds_clean_tree() {
    setup_test_env

    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    "$CLEAR_SCRIPT" "$hash" >/dev/null 2>&1
    "$RESTORE_SCRIPT" "$hash" >/dev/null 2>&1
    local exit_code=$?

    assert_equals "0" "$exit_code" "Restores successfully with clean tree"

    local content
    content=$(cat file.txt)
    assert_equals "checkpoint" "$content" "Working tree content restored"

}

# Restore refuses when HEAD has changed
test_restore_refuses_head_changed() {
    setup_test_env

    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    "$CLEAR_SCRIPT" "$hash" >/dev/null 2>&1

    echo "new commit" > another.txt
    git add another.txt >/dev/null 2>&1
    git commit -m "new commit" >/dev/null 2>&1

    "$RESTORE_SCRIPT" "$hash" 2>/dev/null
    local exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Refuses to restore when HEAD changed"

}

# Restore captures both working tree and staging area
test_restore_preserves_staging() {
    setup_test_env

    echo "unstaged" > file.txt
    echo "staged" > staged.txt
    git add staged.txt >/dev/null 2>&1

    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # After stash, working tree is clean, so we can restore directly
    "$RESTORE_SCRIPT" "$hash" >/dev/null 2>&1

    local unstaged
    unstaged=$(cat file.txt)
    assert_equals "unstaged" "$unstaged" "Working tree restored"

    # CRITICAL: Staging area must be restored exactly to maintain commit readiness
    assert_success "git diff --staged --name-only | grep -qF 'staged.txt'" "Staging area restored"

}

# Restore fails with invalid hash
test_restore_invalid_hash() {
    setup_test_env

    "$RESTORE_SCRIPT" "abc123fake" 2>/dev/null
    local exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Fails with invalid hash"

}

# Restore preserves checkpoint in stash
test_restore_preserves_checkpoint() {
    setup_test_env

    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    "$CLEAR_SCRIPT" "$hash" >/dev/null 2>&1
    "$RESTORE_SCRIPT" "$hash" >/dev/null 2>&1

    assert_success "git stash list --format='%H' | grep -qF \"$hash\"" "Checkpoint preserved in stash after restore"

}

# Restore refuses dirty tree with ONLY untracked files
test_restore_refuses_untracked_only() {
    setup_test_env

    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # After create, tree is clean. Add only untracked files (no modifications to tracked files)
    echo "untracked content" > newfile.txt

    "$RESTORE_SCRIPT" "$hash" 2>/dev/null
    local exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Refuses to restore with untracked files in working tree"

}

# Restore fails with missing arguments
test_restore_missing_arg() {
    setup_test_env

    "$RESTORE_SCRIPT" 2>/dev/null
    local exit_code=$?

    assert_equals "$EXIT_USAGE_ERROR" "$exit_code" "Exits with usage error when missing argument"

}

# Restore checkpoint without patch file (unstaged-only checkpoint)
test_restore_unstaged_only_checkpoint() {
    setup_test_env

    # Create checkpoint with only unstaged changes (no staged changes)
    echo "unstaged content" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "unstaged-only" 2>/dev/null)

    # Verify no patch file in the checkpoint
    assert_failure "git ls-tree -r \"$hash^3\" --name-only 2>/dev/null | grep -qF '.checkpoint-index.patch'" "No patch file in checkpoint"

    # Working tree is now clean (stash cleared it), so we can restore
    "$RESTORE_SCRIPT" "$hash" >/dev/null 2>&1

    local content
    content=$(cat file.txt)
    assert_equals "unstaged content" "$content" "Unstaged-only checkpoint restored"

    # Verify staging area is still empty (no patch was applied)
    assert_success "git diff --staged --quiet" "Staging area empty after restore"

}

# Restore cleans up patch file after successful restore
test_restore_cleans_patch_file() {
    setup_test_env

    # Create checkpoint with staged changes (will create patch file)
    echo "staged" > staged.txt
    git add staged.txt >/dev/null 2>&1

    local hash
    hash=$("$CREATE_SCRIPT" "with-staging" 2>/dev/null)

    # Verify patch file is in the checkpoint
    assert_success "git ls-tree -r \"$hash^3\" --name-only 2>/dev/null | grep -qF '.checkpoint-index.patch'" "Patch file in checkpoint"

    # Restore (working tree is clean after create)
    "$RESTORE_SCRIPT" "$hash" >/dev/null 2>&1
    local exit_code=$?

    # Restore should succeed
    assert_success "[ \$exit_code -eq 0 ]" "Restore succeeds"

    # Patch file should be cleaned up
    assert_failure "[ -f .checkpoint-index.patch ]" "Patch file cleaned up after restore"

    # Staging area should be correctly restored
    assert_success "git diff --staged --name-only | grep -qF 'staged.txt'" "Staging area restored correctly"

}

# Untracked files remain unstaged after restore
test_restore_untracked_not_staged() {
    setup_test_env

    # Create untracked file with NO staged changes
    echo "untracked content" > untracked.txt

    local hash
    hash=$("$CREATE_SCRIPT" "test-untracked" 2>/dev/null)

    # Verify no patch file was created (no staged changes)
    assert_failure "git ls-tree -r \"$hash^3\" --name-only 2>/dev/null | grep -qF '.checkpoint-index.patch'" "No patch file created"

    # Restore
    "$RESTORE_SCRIPT" "$hash" >/dev/null 2>&1

    # Verify untracked file exists
    assert_success "[ -f untracked.txt ]" "Untracked file restored"

    # CRITICAL: Untracked files must remain untracked - staging them would alter user intent
    assert_failure "git diff --staged --name-only | grep -qF 'untracked.txt'" "Untracked file is NOT staged"

    # CRITICAL: File must be in untracked state, not just unstaged
    assert_success "git ls-files --others --exclude-standard | grep -qF 'untracked.txt'" "File is untracked"

}

# Exact staging area state is preserved (staged vs unstaged)
test_restore_exact_staging_state() {
    setup_test_env

    # Create complex state with both staged and unstaged changes
    echo "staged content" > staged.txt
    echo "unstaged content" > unstaged.txt
    echo "also staged" > another_staged.txt

    git add staged.txt another_staged.txt >/dev/null 2>&1

    # Capture the exact staging area state before checkpoint
    local staged_before
    staged_before=$(git diff --staged)

    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Restore
    "$RESTORE_SCRIPT" "$hash" >/dev/null 2>&1

    # Capture staging area state after restore
    local staged_after
    staged_after=$(git diff --staged)

    # CRITICAL: Staging area must be byte-for-byte identical to preserve exact commit state
    assert_equals "$staged_before" "$staged_after" "Staging area exactly preserved"

    # Verify staged files are staged
    assert_success "git diff --staged --name-only | grep -qF 'staged.txt'" "staged.txt is staged"
    assert_success "git diff --staged --name-only | grep -qF 'another_staged.txt'" "another_staged.txt is staged"

    # Verify unstaged file is NOT staged
    assert_failure "git diff --staged --name-only | grep -qF 'unstaged.txt'" "unstaged.txt is NOT staged"

    # Verify unstaged file exists in working tree
    assert_success "[ -f unstaged.txt ]" "unstaged.txt exists"
    local content
    content=$(cat unstaged.txt)
    assert_equals "unstaged content" "$content" "unstaged.txt has correct content"

}

# Run all tests
test_restore_refuses_dirty_tree; finalize_test
test_restore_succeeds_clean_tree; finalize_test
test_restore_refuses_head_changed; finalize_test
test_restore_preserves_staging; finalize_test
test_restore_invalid_hash; finalize_test
test_restore_preserves_checkpoint; finalize_test
test_restore_refuses_untracked_only; finalize_test
test_restore_missing_arg; finalize_test
test_restore_unstaged_only_checkpoint; finalize_test
test_restore_cleans_patch_file; finalize_test
test_restore_untracked_not_staged; finalize_test
test_restore_exact_staging_state; finalize_test

print_results
