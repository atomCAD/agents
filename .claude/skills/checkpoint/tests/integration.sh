#!/bin/bash
# End-to-End Workflow Integration Tests
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

CLEAR_SCRIPT="$SCRIPT_DIR/scripts/clear.sh"
CREATE_SCRIPT="$SCRIPT_DIR/scripts/create.sh"
COMPARE_SCRIPT="$SCRIPT_DIR/scripts/compare.sh"
DROP_SCRIPT="$SCRIPT_DIR/scripts/drop.sh"
RESTORE_SCRIPT="$SCRIPT_DIR/scripts/restore.sh"

### WORKFLOW 1: Experiment with Automatic Cleanup ###

# Test: Complete experiment workflow (create → modify → compare → drop)
test_workflow_experiment_success() {
    setup_test_env

    # Create checkpoint before experimenting
    echo "original" > file.txt
    local checkpoint
    checkpoint=$("$CREATE_SCRIPT" "before-experiment")

    # Make experimental changes
    echo "experimental" > file.txt
    echo "new feature" > feature.txt

    # Compare to see changes
    local diff_output
    diff_output=$("$COMPARE_SCRIPT" "$checkpoint")
    assert_success "echo \"$diff_output\" | grep -F >/dev/null 'experimental'" "Compare shows experiment changes"

    # Keep changes and drop checkpoint
    "$DROP_SCRIPT" "$checkpoint"
    assert_failure "git stash list --format='%H' | grep -F >/dev/null \"$checkpoint\"" "Checkpoint dropped"
    assert_success "[ -f feature.txt ]" "Experimental changes kept"

}

### WORKFLOW 2: Restore with Dirty Working Tree ###

# Test: Restore checkpoint when working tree is dirty (create temp → clear → restore → drop temp)
test_workflow_restore_dirty_tree() {
    setup_test_env

    # Create original checkpoint
    echo "original" > file.txt
    local original
    original=$("$CREATE_SCRIPT" "original")

    # Make changes
    echo "current work" > file.txt

    # Create temporary checkpoint of current state
    local temp
    temp=$("$CREATE_SCRIPT" "temp-before-restore")

    # Clear working tree (only works because temp matches current state)
    "$CLEAR_SCRIPT" "$temp"
    # Restore original checkpoint
    "$RESTORE_SCRIPT" "$original"
    local content
    content=$(cat file.txt)
    assert_equals "original" "$content" "Original state restored"

    # Drop temporary checkpoint
    "$DROP_SCRIPT" "$temp"
    assert_failure "git stash list --format='%H' | grep -F >/dev/null \"$temp\"" "Temp checkpoint dropped"

}

### WORKFLOW 3: Abandon Experiment and Revert ###

# Test: Create bad experiment → checkpoint bad state → clear → restore original
test_workflow_abandon_experiment() {
    setup_test_env

    # Create original checkpoint
    echo "original" > file.txt
    local original
    original=$("$CREATE_SCRIPT" "original")

    # Make bad experimental changes
    echo "bad experiment" > file.txt
    echo "bug" > bug.txt

    # Create checkpoint of bad state for reference
    local bad_state
    bad_state=$("$CREATE_SCRIPT" "failed-experiment")

    # Clear the bad state
    "$CLEAR_SCRIPT" "$bad_state"
    # Restore original checkpoint
    "$RESTORE_SCRIPT" "$original"
    local content
    content=$(cat file.txt)
    assert_equals "original" "$content" "Original restored after abandoning experiment"
    assert_failure "[ -f bug.txt ]" "Bad experiment files removed"

    # Drop both checkpoints
    "$DROP_SCRIPT" "$bad_state"
    "$DROP_SCRIPT" "$original"
    # Verify stash is empty (both checkpoints cleaned up)
    local stash_count
    stash_count=$(git stash list | wc -l | xargs)
    assert_equals "0" "$stash_count" "All checkpoints dropped"

}

### MULTIPLE CHECKPOINT MANAGEMENT ###

# Test: Managing multiple checkpoints simultaneously
test_workflow_multiple_checkpoints() {
    setup_test_env

    # Create first checkpoint
    echo "state1" > file.txt
    local cp1
    cp1=$("$CREATE_SCRIPT" "checkpoint1")

    # Create second checkpoint
    echo "state2" > file.txt
    local cp2
    cp2=$("$CREATE_SCRIPT" "checkpoint2")

    # Create third checkpoint
    echo "state3" > file.txt
    local cp3
    cp3=$("$CREATE_SCRIPT" "checkpoint3")

    # Verify all exist
    assert_success "git stash list --format='%H' | grep -F >/dev/null \"$cp1\"" "Checkpoint 1 exists"
    assert_success "git stash list --format='%H' | grep -F >/dev/null \"$cp2\"" "Checkpoint 2 exists"
    assert_success "git stash list --format='%H' | grep -F >/dev/null \"$cp3\"" "Checkpoint 3 exists"

    # Drop middle checkpoint
    "$DROP_SCRIPT" "$cp2"
    # Verify cp1 and cp3 still exist, cp2 removed
    assert_success "git stash list --format='%H' | grep -F >/dev/null \"$cp1\"" "Checkpoint 1 still exists"
    assert_failure "git stash list --format='%H' | grep -F >/dev/null \"$cp2\"" "Checkpoint 2 removed"
    assert_success "git stash list --format='%H' | grep -F >/dev/null \"$cp3\"" "Checkpoint 3 still exists"

}

### COMPLEX RESTORE SCENARIOS ###

# Test: Create and restore workflow with mixed staged/unstaged changes
test_workflow_create_restore_mixed_staging() {
    setup_test_env

    # Create complex state: staged and unstaged changes
    echo "unstaged content" > file.txt
    echo "staged content" > staged.txt
    git add staged.txt
    local checkpoint
    checkpoint=$("$CREATE_SCRIPT" "complex-state")

    # Clear working tree to test restore from clean state
    git reset --hard HEAD
    git clean -fd
    # Restore
    "$RESTORE_SCRIPT" "$checkpoint"
    # Verify working tree
    local unstaged
    unstaged=$(cat file.txt)
    assert_equals "unstaged content" "$unstaged" "Unstaged changes restored"

    # Verify staging area
    assert_success "git diff --staged --name-only | grep -F >/dev/null 'staged.txt'" "Staged file in index"

    local staged
    staged=$(git show :staged.txt)
    assert_equals "staged content" "$staged" "Staged content correct"

}

### UNTRACKED FILES HANDLING ###

# Test: Untracked files are restored correctly
test_workflow_untracked_files_restoration() {
    setup_test_env

    # Create checkpoint with untracked files
    echo "tracked modified" > file.txt
    echo "untracked content" > newfile.txt
    echo "another untracked" > another.txt

    local checkpoint
    checkpoint=$("$CREATE_SCRIPT" "with-untracked")

    # Verify untracked files were captured in third parent (^3)
    assert_success "git ls-tree -r \"$checkpoint^3^{tree}\" --name-only | grep -F >/dev/null 'newfile.txt'" "First untracked file captured"
    assert_success "git ls-tree -r \"$checkpoint^3^{tree}\" --name-only | grep -F >/dev/null 'another.txt'" "Second untracked file captured"

    # Clear working tree to test restore from clean state
    git reset --hard HEAD
    git clean -fd
    # Restore the checkpoint
    "$RESTORE_SCRIPT" "$checkpoint"
    # Verify all files are restored
    assert_success "[ -f file.txt ]" "Tracked file restored"
    assert_success "[ -f newfile.txt ]" "First untracked file restored"
    assert_success "[ -f another.txt ]" "Second untracked file restored"

    # Verify content is correct
    local content
    content=$(cat newfile.txt)
    assert_equals "untracked content" "$content" "Untracked file content correct"

    content=$(cat another.txt)
    assert_equals "another untracked" "$content" "Second untracked file content correct"

}

# Test: Untracked directories with complex nested structures
test_workflow_untracked_directories() {
    setup_test_env

    # Create complex untracked directory structure with mixed tracked and untracked
    echo "modified tracked" > file.txt
    mkdir -p untracked_dir/nested/deep
    mkdir -p another_untracked/sub
    echo "untracked1" > untracked_dir/file1.txt
    echo "untracked2" > untracked_dir/nested/file2.txt
    echo "untracked3" > untracked_dir/nested/deep/file3.txt
    echo "another1" > another_untracked/file.txt
    echo "another2" > another_untracked/sub/file.txt

    # Add staged changes to mix things up
    echo "staged content" > staged.txt
    git add staged.txt

    local checkpoint
    checkpoint=$("$CREATE_SCRIPT" "complex-untracked-dirs")

    # Verify all untracked files were captured in third parent
    assert_success "git ls-tree -r \"$checkpoint^3^{tree}\" --name-only | grep -F >/dev/null 'untracked_dir/file1.txt'" "Untracked dir file captured"
    assert_success "git ls-tree -r \"$checkpoint^3^{tree}\" --name-only | grep -F >/dev/null 'untracked_dir/nested/file2.txt'" "Nested file captured"
    assert_success "git ls-tree -r \"$checkpoint^3^{tree}\" --name-only | grep -F >/dev/null 'untracked_dir/nested/deep/file3.txt'" "Deep nested file captured"
    assert_success "git ls-tree -r \"$checkpoint^3^{tree}\" --name-only | grep -F >/dev/null 'another_untracked/file.txt'" "Another untracked dir captured"
    assert_success "git ls-tree -r \"$checkpoint^3^{tree}\" --name-only | grep -F >/dev/null 'another_untracked/sub/file.txt'" "Another nested file captured"

    # Clear working tree
    git reset --hard HEAD
    git clean -fd

    # Restore the checkpoint
    "$RESTORE_SCRIPT" "$checkpoint"

    # Verify all directory structures are restored
    assert_success "[ -d untracked_dir/nested/deep ]" "Deep directory structure restored"
    assert_success "[ -d another_untracked/sub ]" "Another directory structure restored"

    # Verify all files are restored with correct content
    assert_success "[ -f untracked_dir/file1.txt ]" "Untracked file restored"
    assert_success "[ -f untracked_dir/nested/file2.txt ]" "Nested file restored"
    assert_success "[ -f untracked_dir/nested/deep/file3.txt ]" "Deep nested file restored"
    assert_success "[ -f another_untracked/file.txt ]" "Another untracked file restored"
    assert_success "[ -f another_untracked/sub/file.txt ]" "Another nested file restored"

    local content
    content=$(cat untracked_dir/nested/deep/file3.txt)
    assert_equals "untracked3" "$content" "Deep nested file content correct"

    # Verify staged changes were also restored correctly
    assert_success "git diff --staged --name-only | grep -F >/dev/null 'staged.txt'" "Staged file in index"
    content=$(git show :staged.txt)
    assert_equals "staged content" "$content" "Staged content correct"

    # Verify tracked modified file is unstaged
    assert_failure "git diff --staged --name-only | grep -F >/dev/null 'file.txt'" "Modified file NOT staged"
    content=$(cat file.txt)
    assert_equals "modified tracked" "$content" "Modified tracked file content correct"

    # Verify untracked files remain untracked
    assert_success "git ls-files --others --exclude-standard | grep -F >/dev/null 'untracked_dir/file1.txt'" "Untracked files remain untracked"

}

### RUN ALL TESTS ###

# Workflow 1: Experiment success
run_test test_workflow_experiment_success

# Workflow 2: Restore with dirty tree
run_test test_workflow_restore_dirty_tree

# Workflow 3: Abandon experiment
run_test test_workflow_abandon_experiment

# Multiple checkpoint management
run_test test_workflow_multiple_checkpoints

# Complex restore scenarios
run_test test_workflow_create_restore_mixed_staging

# Untracked files handling
run_test test_workflow_untracked_files_restoration
run_test test_workflow_untracked_directories

return_test_status
