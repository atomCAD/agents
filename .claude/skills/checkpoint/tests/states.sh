#!/bin/bash
# Combinatorial State Testing for Checkpoint Restore
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

CREATE_SCRIPT="$SCRIPT_DIR/scripts/create.sh"
CLEAR_SCRIPT="$SCRIPT_DIR/scripts/clear.sh"
RESTORE_SCRIPT="$SCRIPT_DIR/scripts/restore.sh"

# Test a specific combination of git states
test_state_combination() {
    local has_staged_new=$1
    local has_untracked=$2
    local has_unstaged_mod=$3
    local has_staged_mod=$4
    local has_mixed_file=$5
    local has_staged_del=$6
    local has_unstaged_del=$7

    setup_test_env

    # Setup: Create files that will be deleted
    if [ "$has_staged_del" = "1" ] || [ "$has_unstaged_del" = "1" ]; then
        echo "to-be-deleted" > deleteme.txt
        git add deleteme.txt
        git commit -m "add deleteme"
    fi

    if [ "$has_mixed_file" = "1" ]; then
        echo "both-modified" > both.txt
        git add both.txt
        git commit -m "add both.txt"
    fi

    if [ "$has_staged_mod" = "1" ]; then
        echo "staged-mod" > staged_mod.txt
        git add staged_mod.txt
        git commit -m "add staged_mod"
    fi

    if [ "$has_unstaged_mod" = "1" ]; then
        echo "unstaged-mod" > unstaged_mod.txt
        git add unstaged_mod.txt
        git commit -m "add unstaged_mod"
    fi

    # Create the test state
    if [ "$has_staged_new" = "1" ]; then
        echo "new staged content" > staged_new.txt
        git add staged_new.txt
    fi

    if [ "$has_untracked" = "1" ]; then
        echo "untracked content" > untracked.txt
    fi

    if [ "$has_unstaged_mod" = "1" ]; then
        echo "modified unstaged" > unstaged_mod.txt
    fi

    if [ "$has_staged_mod" = "1" ]; then
        echo "modified staged" > staged_mod.txt
        git add staged_mod.txt
    fi

    if [ "$has_mixed_file" = "1" ]; then
        echo "staged version" > both.txt
        git add both.txt
        echo "unstaged version" > both.txt
    fi

    if [ "$has_staged_del" = "1" ]; then
        git rm deleteme.txt
    fi

    if [ "$has_unstaged_del" = "1" ]; then
        rm deleteme.txt
    fi

    # Capture state before checkpoint
    local status_before
    status_before=$(git status --porcelain)
    local staged_before
    staged_before=$(git diff --staged)

    # If working tree is completely clean, just verify create fails
    if [ -z "$status_before" ] && [ -z "$staged_before" ]; then
        # Create should fail when there's nothing to checkpoint
        if "$CREATE_SCRIPT" "combo-test" >/dev/null 2>&1; then
            echo "FAIL: create.sh should fail on clean working tree"
            return 1
        fi
        return 0
    fi

    # Create checkpoint
    local hash
    hash=$("$CREATE_SCRIPT" "combo-test")

    # Clear working tree
    "$CLEAR_SCRIPT" "$hash"
    assert_success "git diff --quiet HEAD" "Working tree cleared successfully"
    assert_success "git diff --staged --quiet" "Staging area cleared successfully"
    assert_success "[ -z \"\$(git ls-files --others --exclude-standard)\" ]" "No untracked files after clear"

    # Restore checkpoint
    "$RESTORE_SCRIPT" "$hash"

    # Capture state after restore
    local status_after
    status_after=$(git status --porcelain)
    local staged_after
    staged_after=$(git diff --staged)

    # Verify exact state match
    local combo_desc="staged_new=$has_staged_new untracked=$has_untracked unstaged_mod=$has_unstaged_mod staged_mod=$has_staged_mod mixed_file=$has_mixed_file staged_del=$has_staged_del unstaged_del=$has_unstaged_del"

    assert_equals "$status_before" "$status_after" "Status matches for: $combo_desc"
    assert_equals "$staged_before" "$staged_after" "Staging area matches for: $combo_desc"

}

# Generate and test all valid combinations
COMBINATIONS_TESTED=0

# Iterate through all 2^7 = 128 combinations
for staged_new in 0 1; do
for untracked in 0 1; do
for unstaged_mod in 0 1; do
for staged_mod in 0 1; do
for mixed_file in 0 1; do
for staged_del in 0 1; do
for unstaged_del in 0 1; do
    # Skip invalid combinations
    # Can't have both staged and unstaged deletion
    if [ "$staged_del" = "1" ] && [ "$unstaged_del" = "1" ]; then
        continue
    fi

    COMBINATIONS_TESTED=$((COMBINATIONS_TESTED + 1))
    run_test test_state_combination "$staged_new" "$untracked" "$unstaged_mod" "$staged_mod" "$mixed_file" "$staged_del" "$unstaged_del"
done
done
done
done
done
done
done

return_test_status
