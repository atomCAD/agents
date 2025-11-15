#!/bin/bash
# Unit tests for drop.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC1091
source "$(dirname "$0")/../common.sh"

CREATE_SCRIPT="$SCRIPT_DIR/scripts/create.sh"
DROP_SCRIPT="$SCRIPT_DIR/scripts/drop.sh"

### DROP TESTS ###

# Test: Drop removes checkpoint from stash
test_drop_success() {
    setup_test_env

    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    "$DROP_SCRIPT" "$hash"
    assert_failure "git stash list --format='%H' | grep -qF \"$hash\"" "Checkpoint removed from stash"
}

# Test: Drop fails with invalid hash
test_drop_invalid_hash() {
    setup_test_env

    local exit_code=0
    "$DROP_SCRIPT" "abc123fake" || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Fails with invalid hash"
}

# Test: Drop fails with missing argument
test_drop_missing_arg() {
    setup_test_env

    local exit_code=0
    "$DROP_SCRIPT" || exit_code=$?

    assert_equals "$EXIT_USAGE_ERROR" "$exit_code" "Exits with usage error when missing argument"
}

# Test: Drop preserves working tree changes
test_drop_preserves_working_tree() {
    setup_test_env

    echo "checkpoint" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    echo "current work" > file.txt

    "$DROP_SCRIPT" "$hash"
    local content
    content=$(cat file.txt)
    assert_equals "current work" "$content" "Working tree unchanged after drop"
}

### RUN ALL TESTS ###

run_test test_drop_success
run_test test_drop_invalid_hash
run_test test_drop_missing_arg
run_test test_drop_preserves_working_tree

return_test_status
