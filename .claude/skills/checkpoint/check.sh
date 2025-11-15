#!/bin/bash
# Run all checkpoint tests with caching based on scripts content hash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_SRC="$SCRIPT_DIR/scripts"
TESTS_DIR="$SCRIPT_DIR/tests"
CACHE_FILE="$SCRIPT_DIR/.test-cache"

# Compute hash of all scripts and tests
compute_scripts_hash() {
    # Find all files in scripts and tests directories, compute their content hash
    # Use shasum (perl-based, available on Linux, macOS, and Windows Git Bash)
    {
        find "$SCRIPTS_SRC" -type f -exec shasum -a 256 {} \;
        find "$TESTS_DIR" -type f -exec shasum -a 256 {} \;
    } | sort | shasum -a 256 | cut -d' ' -f1
}

# Check if cached results are valid
current_hash=$(compute_scripts_hash)

if [ -f "$CACHE_FILE" ]; then
    cached_hash=$(cat "$CACHE_FILE" 2>/dev/null || echo "")
    if [ "$current_hash" = "$cached_hash" ]; then
        # Hash matches - tests already passed for this version
        exit 0
    fi
fi

# Hash doesn't match or no cache - run tests
failed=0

# Run unit tests
for test_file in "$TESTS_DIR"/unit/*.sh; do
    # Skip if no files exist
    [ -e "$test_file" ] || continue

    # Check if file is executable
    if [ ! -x "$test_file" ]; then
        echo "Error: Test file is not executable: $test_file" >&2
        echo "Run: chmod +x \"$test_file\"" >&2
        exit 1
    fi

    # Run the test
    if ! "$test_file"; then
        failed=1
    fi
done

# Run integration and state tests
for test_file in "$TESTS_DIR"/*.sh; do
    # Skip if no files exist
    [ -e "$test_file" ] || continue

    # Skip common.sh (helper file, not a test suite)
    [ "$(basename "$test_file")" = "common.sh" ] && continue

    # Check if file is executable
    if [ ! -x "$test_file" ]; then
        echo "Error: Test file is not executable: $test_file" >&2
        echo "Run: chmod +x \"$test_file\"" >&2
        exit 1
    fi

    # Run the test
    if ! "$test_file"; then
        failed=1
    fi
done

# If all tests passed, cache the hash
if [ $failed -eq 0 ]; then
    echo "$current_hash" > "$CACHE_FILE"
fi

exit $failed
