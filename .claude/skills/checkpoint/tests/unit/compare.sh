#!/bin/bash
# Unit tests for compare.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC1091
source "$(dirname "$0")/../common.sh"

CREATE_SCRIPT="$SCRIPT_DIR/scripts/create.sh"
COMPARE_SCRIPT="$SCRIPT_DIR/scripts/compare.sh"

### COMPARE TESTS ###

# Test: Compare shows diff when changes exist
test_compare_with_changes() {
    setup_test_env

    echo "original" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    echo "modified" > file.txt

    local diff_output
    diff_output=$("$COMPARE_SCRIPT" "$hash" 2>/dev/null)

    assert_success "echo \"$diff_output\" | grep -qF 'modified'" "Compare shows changes"
}

# Test: Compare shows empty diff when current state matches checkpoint
test_compare_no_changes() {
    setup_test_env

    echo "content" > file.txt
    local hash
    hash=$("$CREATE_SCRIPT" "test" 2>/dev/null)

    # Restore the checkpointed state so current matches checkpoint
    echo "content" > file.txt

    local diff_output
    diff_output=$("$COMPARE_SCRIPT" "$hash" 2>/dev/null)

    assert_success "[ -z \"$diff_output\" ]" "Compare shows no changes when states match"
}

# Test: Compare fails with invalid hash
test_compare_invalid_hash() {
    setup_test_env

    local exit_code=0
    "$COMPARE_SCRIPT" "abc123fake" || exit_code=$?

    assert_equals "$EXIT_ERROR" "$exit_code" "Fails with invalid hash"
}

# Test: Compare fails with missing argument
test_compare_missing_arg() {
    setup_test_env

    local exit_code=0
    "$COMPARE_SCRIPT" || exit_code=$?

    assert_equals "$EXIT_USAGE_ERROR" "$exit_code" "Exits with usage error when missing argument"
}

### RUN ALL TESTS ###

run_test test_compare_with_changes
run_test test_compare_no_changes
run_test test_compare_invalid_hash
run_test test_compare_missing_arg

return_test_status
