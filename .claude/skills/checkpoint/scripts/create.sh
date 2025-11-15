#!/bin/bash
# Create a checkpoint of current working tree and staging area
# Usage: create.sh <checkpoint-namespace>
# Outputs: stash hash
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <checkpoint-namespace>" >&2
    exit 2
fi

CHECKPOINT_NAMESPACE="$1"
CHECKPOINT_MESSAGE="$CHECKPOINT_NAMESPACE-$(date -Iseconds -u)"

# Check if we have anything to stash
if git diff --quiet HEAD >/dev/null 2>&1 && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    cat >&2 <<EOF
Error: No changes to create checkpoint from.

Working tree is clean (no staged, unstaged, or untracked changes).
Cannot create checkpoint without changes.

CALLING AGENT: Checkpoint creation requires changes to stash.
Ensure there is at least one of the following:
- Staged changes
- Unstaged changes to tracked files
- Untracked (but not ignored) files

Check 'git status' to verify changes exist.
EOF
    exit 1
fi

# Cleanup function to restore index and working tree
cleanup() {
    if [ -n "${ORIGINAL_INDEX:-}" ]; then
        git read-tree "$ORIGINAL_INDEX" 2>/dev/null || true
    fi
    if [ -n "${UNTRACKED_REMOVAL_NEEDED:-}" ]; then
        # Remove any untracked files we temporarily added to index
        git clean -fd 2>/dev/null || true
    fi
}

# Set trap to ensure cleanup on exit
trap cleanup EXIT

# Save current HEAD
HEAD=$(git rev-parse HEAD)

# Save original index state
ORIGINAL_INDEX=$(git write-tree)
INDEX_TREE="$ORIGINAL_INDEX"

# Create index commit (^2 parent - staged changes only)
INDEX_COMMIT=$(echo "index on $(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD"): $(git rev-parse --short HEAD) $(git log -1 --format=%s HEAD)" | \
    git commit-tree "$INDEX_TREE" -p "$HEAD")

if [ -z "$INDEX_COMMIT" ]; then
    cat >&2 <<EOF
Error: Failed to create index commit.

CALLING AGENT: Report this error to the user.
EOF
    exit 1
fi

# Check for untracked files
UNTRACKED_FILES=$(git ls-files --others --exclude-standard)

# Always create untracked files commit (^3 parent) to match git stash behavior
# Use a temporary index file
TEMP_INDEX=$(mktemp)
export GIT_INDEX_FILE="$TEMP_INDEX"

# Initialize empty index
git read-tree --empty

# Add untracked files if any exist
if [ -n "$UNTRACKED_FILES" ]; then
    echo "$UNTRACKED_FILES" | xargs git add --force
fi

UNTRACKED_TREE=$(git write-tree)

# Restore original index
unset GIT_INDEX_FILE
rm -f "$TEMP_INDEX"

UNTRACKED_COMMIT=$(echo "untracked files on $(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD"): $(git rev-parse --short HEAD) $(git log -1 --format=%s HEAD)" | \
    git commit-tree "$UNTRACKED_TREE" -p "$HEAD")

if [ -z "$UNTRACKED_COMMIT" ]; then
    cat >&2 <<EOF
Error: Failed to create untracked files commit.

CALLING AGENT: Report this error to the user.
EOF
    exit 1
fi

# Create working tree (staged + unstaged, but NOT untracked)
# Stage all tracked file changes
git add -u

# Capture the full working tree
WORK_TREE=$(git write-tree)

# Restore original index
git read-tree "$ORIGINAL_INDEX"

# Create main stash commit
# - Tree: Working tree (staged + unstaged modifications, excluding untracked)
# - ^1: HEAD
# - ^2: Index commit (staged only)
# - ^3: Untracked commit (always present to match git stash behavior)
STASH_HASH=$(echo "$CHECKPOINT_MESSAGE" | \
    git commit-tree "$WORK_TREE" -p "$HEAD" -p "$INDEX_COMMIT" -p "$UNTRACKED_COMMIT")

if [ -z "$STASH_HASH" ]; then
    cat >&2 <<EOF
Error: Failed to create checkpoint.

CALLING AGENT: Report this error to the user.
EOF
    exit 1
fi

# Store in stash reflog
git stash store -m "$CHECKPOINT_MESSAGE" "$STASH_HASH"

# Output the hash
echo "$STASH_HASH"
