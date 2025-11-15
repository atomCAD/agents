#!/bin/bash
# Tests for restore.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC1091
source "$(dirname "$0")/../common.sh"

CLEAR_SCRIPT="$SCRIPT_DIR/scripts/clear.sh"
CREATE_SCRIPT="$SCRIPT_DIR/scripts/create.sh"
RESTORE_SCRIPT="$SCRIPT_DIR/scripts/restore.sh"

### RESTORE TESTS ###

# Restore refuses to run with dirty working tree
test_restore_refuses_dirty_tree() {
    setup_test_env

    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test")

    echo "new changes" > file.txt

    local exit_code=0
    "$RESTORE_SCRIPT" "$hash" || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Refuses to restore with dirty working tree"

}

# Restore succeeds with clean working tree
test_restore_succeeds_clean_tree() {
    setup_test_env

    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test")

    "$CLEAR_SCRIPT" "$hash"
    assert_success "git diff --quiet HEAD" "Working tree is clean after clear"

    "$RESTORE_SCRIPT" "$hash"
    assert_success "[ -f file.txt ]" "file.txt restored"

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

    "$CLEAR_SCRIPT" "$hash" || exit_code=$?
    assert_success "git diff --quiet HEAD" "Working tree is clean after clear"

    echo "new commit" > another.txt
    git add another.txt >/dev/null 2>&1
    git commit -m "new commit" >/dev/null 2>&1

    local exit_code=0
    "$RESTORE_SCRIPT" "$hash" || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Refuses to restore when HEAD changed"

}

# Restore captures both working tree and staging area
test_restore_preserves_staging() {
    setup_test_env

    echo "unstaged" > file.txt
    echo "staged" > staged.txt
    git add staged.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Clear working tree to test restore from clean state
    git reset --hard HEAD
    git clean -fd
    # Restore
    "$RESTORE_SCRIPT" "$hash"
    local unstaged
    unstaged=$(cat file.txt)
    assert_equals "unstaged" "$unstaged" "Working tree restored"

    # CRITICAL: Staging area must be restored exactly to maintain commit readiness
    assert_success "git diff --staged --name-only | grep -qF 'staged.txt'" "Staging area restored"

}

# Restore fails with invalid hash
test_restore_invalid_hash() {
    setup_test_env

    local exit_code=0
    "$RESTORE_SCRIPT" "abc123fake" || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Fails with invalid hash"

}

# Restore preserves checkpoint in stash
test_restore_preserves_checkpoint() {
    setup_test_env

    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    "$CLEAR_SCRIPT" "$hash"
    assert_success "git diff --quiet HEAD" "Working tree is clean after clear"

    "$RESTORE_SCRIPT" "$hash"
    assert_success "[ -f file.txt ]" "file.txt restored"

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

    local exit_code=0
    "$RESTORE_SCRIPT" "$hash" || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Refuses to restore with untracked files in working tree"

}

# Restore fails with missing arguments
test_restore_missing_arg() {
    setup_test_env

    local exit_code=0
    "$RESTORE_SCRIPT" || exit_code=$?

    assert_equals "$EXIT_USAGE_ERROR" "$exit_code" "Exits with usage error when missing argument"

}

# Restore checkpoint with unstaged-only changes
test_restore_unstaged_only_checkpoint() {
    setup_test_env

    # Create checkpoint with only unstaged changes (no staged changes)
    echo "unstaged content" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "unstaged-only" 2>/dev/null)

    # Verify index tree matches HEAD (no staged changes were captured)
    local index_tree head_tree
    index_tree=$(git rev-parse "$hash^2^{tree}")
    head_tree=$(git rev-parse "HEAD^{tree}")
    assert_equals "$head_tree" "$index_tree" "Index tree matches HEAD for unstaged-only"

    # Clear working tree to test restore from clean state
    git reset --hard HEAD
    git clean -fd
    # Restore
    "$RESTORE_SCRIPT" "$hash"
    local content
    content=$(cat file.txt)
    assert_equals "unstaged content" "$content" "Unstaged-only checkpoint restored"

    # Verify staging area is still empty (nothing was staged in checkpoint)
    assert_success "git diff --staged --quiet" "Staging area empty after restore"

}

# Restore correctly restores staging area from index tree
test_restore_staging_from_index_tree() {
    setup_test_env

    # Create checkpoint with staged changes
    echo "staged" > staged.txt
    git add staged.txt
    local hash
    hash=$("$CREATE_SCRIPT" "with-staging" 2>/dev/null)

    # Verify index tree contains staged.txt
    assert_success "git ls-tree -r \"$hash^2^{tree}\" --name-only | grep -qF 'staged.txt'" "Index tree contains staged file"

    # Working tree still has changes - clear it first
    "$CLEAR_SCRIPT" "$hash"
    assert_success "git diff --quiet HEAD" "Working tree is clean after clear"

    # Now restore
    "$RESTORE_SCRIPT" "$hash"
    assert_success "[ -f staged.txt ]" "staged.txt restored in working tree"

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

    # Verify index tree matches HEAD (no staged changes)
    local index_tree head_tree
    index_tree=$(git rev-parse "$hash^2^{tree}")
    head_tree=$(git rev-parse "HEAD^{tree}")
    assert_equals "$head_tree" "$index_tree" "Index tree matches HEAD (no staged changes)"

    # Clear working tree to test restore from clean state
    git reset --hard HEAD
    git clean -fd
    # Restore
    "$RESTORE_SCRIPT" "$hash"
    # Verify untracked file exists
    assert_success "[ -f untracked.txt ]" "Untracked file restored"

    # CRITICAL: Untracked files must remain untracked - staging them would alter user intent
    assert_failure "git diff --staged --name-only | grep -qF 'untracked.txt'" "Untracked file is NOT staged"

    # CRITICAL: File must be in untracked state, not just unstaged
    assert_success "git ls-files --others --exclude-standard | grep -qF 'untracked.txt'" "File is untracked"

}

# Restore untracked directories correctly
test_restore_untracked_directory() {
    setup_test_env

    # Create untracked directory structure
    mkdir -p untracked_dir/nested/deep
    echo "file1" > untracked_dir/file1.txt
    echo "file2" > untracked_dir/nested/file2.txt
    echo "file3" > untracked_dir/nested/deep/file3.txt
    echo "root" > root_untracked.txt

    local hash
    hash=$("$CREATE_SCRIPT" "test-untracked-dirs" 2>/dev/null)

    # Verify index tree matches HEAD (no staged changes)
    local index_tree head_tree
    index_tree=$(git rev-parse "$hash^2^{tree}")
    head_tree=$(git rev-parse "HEAD^{tree}")
    assert_equals "$head_tree" "$index_tree" "Index tree matches HEAD (no staged changes)"

    # Clear working tree to test restore from clean state
    git reset --hard HEAD
    git clean -fd
    # Restore
    "$RESTORE_SCRIPT" "$hash"
    # Verify all untracked files and directories exist
    assert_success "[ -d untracked_dir ]" "Untracked directory restored"
    assert_success "[ -d untracked_dir/nested ]" "Nested directory restored"
    assert_success "[ -d untracked_dir/nested/deep ]" "Deep nested directory restored"
    assert_success "[ -f untracked_dir/file1.txt ]" "File in untracked dir restored"
    assert_success "[ -f untracked_dir/nested/file2.txt ]" "File in nested dir restored"
    assert_success "[ -f untracked_dir/nested/deep/file3.txt ]" "File in deep nested dir restored"
    assert_success "[ -f root_untracked.txt ]" "Root untracked file restored"

    # Verify content
    local content
    content=$(cat untracked_dir/nested/deep/file3.txt)
    assert_equals "file3" "$content" "Deep nested file has correct content"

    # CRITICAL: All untracked files must remain untracked
    assert_failure "git diff --staged --name-only | grep -qF 'untracked_dir'" "Untracked dir files NOT staged"
    assert_success "git ls-files --others --exclude-standard | grep -qF 'untracked_dir/file1.txt'" "Files remain untracked"
    assert_success "git ls-files --others --exclude-standard | grep -qF 'untracked_dir/nested/file2.txt'" "Nested files remain untracked"

}

# Exact staging area state is preserved (staged vs unstaged)
test_restore_exact_staging_state() {
    setup_test_env

    # Create complex state with both staged and unstaged changes
    echo "staged content" > staged.txt
    echo "unstaged content" > unstaged.txt
    echo "also staged" > another_staged.txt

    git add staged.txt another_staged.txt
    # Capture the exact staging area state before checkpoint
    local staged_before
    staged_before=$(git diff --staged)

    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Manually clear working tree to test restore from clean state
    git reset --hard HEAD
    git clean -fd
    # Verify working tree and index are actually empty
    assert_success "git diff --quiet HEAD" "Working tree is clean after reset"
    assert_success "git diff --staged --quiet" "Index is empty after reset"
    assert_success "[ -z \"\$(git ls-files --others --exclude-standard)\" ]" "No untracked files after clean"

    # Restore
    "$RESTORE_SCRIPT" "$hash"
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

### RUN ALL TESTS ###

run_test test_restore_refuses_dirty_tree
run_test test_restore_succeeds_clean_tree
run_test test_restore_refuses_head_changed
run_test test_restore_preserves_staging
run_test test_restore_invalid_hash
run_test test_restore_preserves_checkpoint
run_test test_restore_refuses_untracked_only
run_test test_restore_missing_arg
run_test test_restore_unstaged_only_checkpoint
run_test test_restore_staging_from_index_tree
run_test test_restore_untracked_not_staged
run_test test_restore_untracked_directory
run_test test_restore_exact_staging_state

return_test_status
