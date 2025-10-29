#!/bin/bash
# End-to-End Workflow Integration Tests
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

CREATE_SCRIPT="$SCRIPT_DIR/scripts/create.sh"
COMPARE_SCRIPT="$SCRIPT_DIR/scripts/compare.sh"
DROP_SCRIPT="$SCRIPT_DIR/scripts/drop.sh"
CLEAR_SCRIPT="$SCRIPT_DIR/scripts/clear.sh"
RESTORE_SCRIPT="$SCRIPT_DIR/scripts/restore.sh"

### WORKFLOW 1: Experiment with Automatic Cleanup ###

# Test: Complete experiment workflow (create → modify → compare → drop)
test_workflow_experiment_success() {
    setup_test_env

    # Create checkpoint before experimenting
    echo "original" > file.txt
    local checkpoint
    checkpoint=$("$CREATE_SCRIPT" "before-experiment" 2>/dev/null)

    # Make experimental changes
    echo "experimental" > file.txt
    echo "new feature" > feature.txt

    # Compare to see changes
    local diff_output
    diff_output=$("$COMPARE_SCRIPT" "$checkpoint" 2>/dev/null)
    assert_success "echo \"$diff_output\" | grep -F >/dev/null 'experimental'" "Compare shows experiment changes"

    # Keep changes and drop checkpoint
    "$DROP_SCRIPT" "$checkpoint" >/dev/null 2>&1

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
    original=$("$CREATE_SCRIPT" "original" 2>/dev/null)

    # Make changes
    echo "current work" > file.txt

    # Create temporary checkpoint of current state
    local temp
    temp=$("$CREATE_SCRIPT" "temp-before-restore" 2>/dev/null)

    # Clear working tree (only works because temp matches current state)
    "$CLEAR_SCRIPT" "$temp" >/dev/null 2>&1

    # Restore original checkpoint
    "$RESTORE_SCRIPT" "$original" >/dev/null 2>&1

    local content
    content=$(cat file.txt)
    assert_equals "original" "$content" "Original state restored"

    # Drop temporary checkpoint
    "$DROP_SCRIPT" "$temp" >/dev/null 2>&1

    assert_failure "git stash list --format='%H' | grep -F >/dev/null \"$temp\"" "Temp checkpoint dropped"

}

### WORKFLOW 3: Abandon Experiment and Revert ###

# Test: Create bad experiment → checkpoint bad state → clear → restore original
test_workflow_abandon_experiment() {
    setup_test_env

    # Create original checkpoint
    echo "original" > file.txt
    local original
    original=$("$CREATE_SCRIPT" "original" 2>/dev/null)

    # Make bad experimental changes
    echo "bad experiment" > file.txt
    echo "bug" > bug.txt

    # Create checkpoint of bad state for reference
    local bad_state
    bad_state=$("$CREATE_SCRIPT" "failed-experiment" 2>/dev/null)

    # Clear the bad state
    "$CLEAR_SCRIPT" "$bad_state" >/dev/null 2>&1

    # Restore original checkpoint
    "$RESTORE_SCRIPT" "$original" >/dev/null 2>&1

    local content
    content=$(cat file.txt)
    assert_equals "original" "$content" "Original restored after abandoning experiment"
    assert_failure "[ -f bug.txt ]" "Bad experiment files removed"

    # Drop both checkpoints
    "$DROP_SCRIPT" "$bad_state" >/dev/null 2>&1
    "$DROP_SCRIPT" "$original" >/dev/null 2>&1

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
    cp1=$("$CREATE_SCRIPT" "checkpoint1" 2>/dev/null)

    # Create second checkpoint
    echo "state2" > file.txt
    local cp2
    cp2=$("$CREATE_SCRIPT" "checkpoint2" 2>/dev/null)

    # Create third checkpoint
    echo "state3" > file.txt
    local cp3
    cp3=$("$CREATE_SCRIPT" "checkpoint3" 2>/dev/null)

    # Verify all exist
    assert_success "git stash list --format='%H' | grep -F >/dev/null \"$cp1\"" "Checkpoint 1 exists"
    assert_success "git stash list --format='%H' | grep -F >/dev/null \"$cp2\"" "Checkpoint 2 exists"
    assert_success "git stash list --format='%H' | grep -F >/dev/null \"$cp3\"" "Checkpoint 3 exists"

    # Drop middle checkpoint
    "$DROP_SCRIPT" "$cp2" >/dev/null 2>&1

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
    git add staged.txt >/dev/null 2>&1

    local checkpoint
    checkpoint=$("$CREATE_SCRIPT" "complex-state" 2>/dev/null)

    # After stash, tree is clean, so we can restore immediately
    "$RESTORE_SCRIPT" "$checkpoint" >/dev/null 2>&1

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
    checkpoint=$("$CREATE_SCRIPT" "with-untracked" 2>/dev/null)

    # Verify untracked files were captured
    assert_success "git ls-tree -r \"$checkpoint^3\" --name-only | grep -F >/dev/null 'newfile.txt'" "First untracked file captured"
    assert_success "git ls-tree -r \"$checkpoint^3\" --name-only | grep -F >/dev/null 'another.txt'" "Second untracked file captured"

    # Working tree is now clean - restore the checkpoint
    "$RESTORE_SCRIPT" "$checkpoint" >/dev/null 2>&1

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

### RUN ALL TESTS ###

# Workflow 1: Experiment success
test_workflow_experiment_success

# Workflow 2: Restore with dirty tree
test_workflow_restore_dirty_tree

# Workflow 3: Abandon experiment
test_workflow_abandon_experiment

# Multiple checkpoint management
test_workflow_multiple_checkpoints

# Complex restore scenarios
test_workflow_create_restore_mixed_staging

# Untracked files handling
test_workflow_untracked_files_restoration

print_results
