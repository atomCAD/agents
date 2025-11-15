#!/bin/bash
# Test helpers for checkpoint tests
set -uo pipefail

# Exit code constants (matching script conventions)
# Used by all test files that source this common.sh
# shellcheck disable=SC2034
readonly EXIT_SUCCESS=0
# shellcheck disable=SC2034
readonly EXIT_ERROR=1
# shellcheck disable=SC2034
readonly EXIT_USAGE_ERROR=2

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get caller location for error reporting
_get_caller_location() {
    echo "${BASH_SOURCE[2]##*/}:${BASH_LINENO[1]}"
}

# Setup a fresh git repository for testing
setup_test_repo() {
    local repo_dir
    repo_dir=$(mktemp -d "/tmp/checkpoint-test-$$-XXXXXX")
    cd "$repo_dir" || exit 1

    git init >/dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create initial commit
    echo "initial" > file.txt
    git add file.txt
    git commit -m "initial commit" >/dev/null 2>&1

    echo "$repo_dir"
}

# Cleanup test repository
cleanup_test_repo() {
    local repo_dir="$1"
    if [ -n "$repo_dir" ] && [ -d "$repo_dir" ]; then
        rm -rf "$repo_dir"
    fi
}

# Setup test environment with automatic cleanup
# This function creates a test repository, changes to it, and stores
# the path for cleanup. Cleanup must be handled by the test runner.
#
# Usage: Call this at the start of each test function
# Example:
#   test_my_feature() {
#       setup_test_env
#       echo "test" > file.txt
#       # ... test logic ...
#   }
#
# The test repo path is stored in TEST_REPO_STACK for cleanup by finalize_test.
setup_test_env() {
    local repo
    repo=$(setup_test_repo)
    cd "$repo" || return 1

    # Store repo path for cleanup
    export TEST_REPO="$repo"
    TEST_REPO_STACK+=("$repo")

    # Set up trap to cleanup on exit (for run_test subshell)
    trap 'finalize_test' EXIT
}

# Finalize current test - clean up the test repository
# This is called after each test completes
finalize_test() {
    if [ -n "${TEST_REPO:-}" ]; then
        cleanup_test_repo "$TEST_REPO"
        unset TEST_REPO
    fi
}

# Initialize test repo tracking
TEST_REPO_STACK=()

# Assert command succeeds
assert_success() {
    local cmd="$1"
    local desc="$2"

    if eval "$cmd" >/dev/null 2>&1; then
        return 0
    else
        echo "$(_get_caller_location): FAIL: $desc - Command failed: $cmd"
        return 1
    fi
}

# Assert command fails
assert_failure() {
    local cmd="$1"
    local desc="$2"

    if ! eval "$cmd" >/dev/null 2>&1; then
        return 0
    else
        echo "$(_get_caller_location): FAIL: $desc - Command should have failed: $cmd"
        return 1
    fi
}

# Assert equals
assert_equals() {
    local expected="$1"
    local actual="$2"
    local desc="$3"

    if [ "$expected" = "$actual" ]; then
        return 0
    else
        echo "$(_get_caller_location): FAIL: $desc - Expected: $expected, Actual: $actual"
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local desc="$2"

    if [ -f "$file" ]; then
        return 0
    else
        echo "$(_get_caller_location): FAIL: $desc - File does not exist: $file"
        return 1
    fi
}

# Assert file does not exist
assert_file_not_exists() {
    local file="$1"
    local desc="$2"

    if [ ! -f "$file" ]; then
        return 0
    else
        echo "$(_get_caller_location): FAIL: $desc - File should not exist: $file"
        return 1
    fi
}

# Run a test function in a subshell with errexit enabled
# This ensures command failures cause the test to fail without killing the test runner
# Usage: run_test test_name [arg1 arg2 ...]
run_test() {
    local test_name=$1
    shift  # Remove test_name from arguments, leaving optional parameters

    # Build display name with args if present
    local display_name="$test_name"
    if [ $# -gt 0 ]; then
        display_name+="($*)"
    fi

    TESTS_RUN=$((TESTS_RUN + 1))

    # Run test in subshell with set -e so any command failure fails the test
    # CRITICAL: Subshell must be standalone command (not part of if/||/&&) to preserve set -e
    # Capture output to show on failure
    set +e  # Temporarily disable errexit so subshell failure doesn't kill parent
    local test_output
    test_output=$( (set -e; "$test_name" "$@") 2>&1 )
    local exit_code=$?
    set -e  # Re-enable errexit (though parent script may not have it enabled)

    if [ $exit_code -eq 0 ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "$display_name: FAIL"
        [ -n "$test_output" ] && echo "$test_output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Return test status based on failure count
return_test_status() {
    if [ $TESTS_FAILED -gt 0 ]; then
        return 1
    fi
    return 0
}

# Unit tests for this file (only run when executed directly, not when sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Test: _get_caller_location returns correct format
    test_get_caller_location_format() {
        local location
        location=$(_get_caller_location)

        # Should be in format: filename:lineno
        assert_success "echo \"$location\" | grep -q '^[^:]*:[0-9]*$'" "Location format is filename:lineno"
    }

    # Test: _get_caller_location returns basename not full path
    test_get_caller_location_basename() {
        local location
        location=$(_get_caller_location)

        local filename="${location%%:*}"

        # Should not contain directory separator
        assert_failure "echo \"$filename\" | grep -q '/'" "Filename has no directory separators"
    }

    # Test: _get_caller_location returns correct filename
    test_get_caller_location_filename() {
        local location
        location=$(_get_caller_location)

        local filename="${location%%:*}"

        assert_equals "common.sh" "$filename" "Filename matches caller"
    }

    # Test: _get_caller_location returns valid line number
    test_get_caller_location_lineno() {
        local location
        location=$(_get_caller_location)

        local lineno="${location##*:}"

        # Line number should be positive integer
        assert_success "[ \"$lineno\" -gt 0 ]" "Line number is positive"
    }

    # Test: _get_caller_location works through call chain
    test_get_caller_location_through_function() {
        # Test through a wrapper to verify call stack works correctly
        _test_wrapper() {
            _get_caller_location
        }

        local loc
        loc=$(_test_wrapper)

        # Should return this file and a valid line number
        assert_success "echo \"$loc\" | grep -q '^common.sh:[0-9]*$'" "Location through wrapper is valid"
    }

    # Run unit tests
    test_get_caller_location_format
    test_get_caller_location_basename
    test_get_caller_location_filename
    test_get_caller_location_lineno
    test_get_caller_location_through_function

    return_test_status
fi
