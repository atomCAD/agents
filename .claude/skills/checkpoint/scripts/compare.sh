#!/bin/bash
# Compare current state with a checkpoint
# Usage: compare.sh <stash-hash>
# Outputs: diff between current state and checkpoint
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <stash-hash>" >&2
    exit 2
fi

STASH_HASH="$1"

# Get all stashes once
STASH_LIST=$(git stash list --format="%H %gs")

# Validate stash exists by hash
if ! echo "$STASH_LIST" | grep -qF "$STASH_HASH"; then
    cat >&2 <<EOF
Error: Checkpoint not found with hash '$STASH_HASH'

Most recent checkpoint hashes:
$(echo "$STASH_LIST" | head -n5)

CALLING AGENT: This checkpoint hash is invalid or the checkpoint was already dropped.
Verify the hash and check 'git stash list' for available checkpoints.
EOF
    exit 1
fi

### Show comprehensive comparison between checkpoint and current state

# When called from a tty, disable git pager for direct output
export GIT_PAGER=cat

# Cleanup function to remove temporary files
cleanup() {
    if [[ -n "${TEMP_INDEX_WORK:-}" ]]; then
        rm -f "$TEMP_INDEX_WORK"
    fi
    if [[ -n "${TEMP_INDEX_UNTRACKED:-}" ]]; then
        rm -f "$TEMP_INDEX_UNTRACKED"
    fi
}

# Set trap to ensure cleanup on exit
trap cleanup EXIT

# First output doesn't require a newline; subsequent sections do
have_output=0

## Section 1: Index (staging area) comparison
# Compare checkpoint's index (^2) with current index
INDEX_DIFF=$(git diff --cached "$STASH_HASH^2" 2>/dev/null)
if [[ -n "$INDEX_DIFF" ]]; then
    have_output=1
    echo "# Changes between checkpoint's staged state and current staged state:"
    echo ""
    echo "$INDEX_DIFF"
fi

## Section 2: Working tree comparison (staged + unstaged tracked files)
# Create a temporary commit of current working tree state (tracked files only)
TEMP_INDEX_WORK=$(mktemp)
export GIT_INDEX_FILE="$TEMP_INDEX_WORK"

# Copy current index
git read-tree HEAD

# Stage all tracked file changes (mimics what create.sh does)
git add -u 2>/dev/null || true

CURRENT_WORK_TREE=$(git write-tree)

# Restore original index
unset GIT_INDEX_FILE

# Compare checkpoint's working tree with current
WORK_TREE_DIFF=$(git diff "$STASH_HASH" "$CURRENT_WORK_TREE" 2>/dev/null)
if [[ -n "$WORK_TREE_DIFF" ]]; then
    if [[ $have_output -ne 0 ]]; then
        echo ""
    fi
    have_output=1
    echo "# Changes between checkpoint's working tree and current working tree:"
    echo ""
    echo "$WORK_TREE_DIFF"
fi

## Section 3: Untracked files comparison
# Get current untracked files
CURRENT_UNTRACKED=$(git ls-files --others --exclude-standard)

# Create temporary index for current untracked files
TEMP_INDEX_UNTRACKED=$(mktemp)
export GIT_INDEX_FILE="$TEMP_INDEX_UNTRACKED"

git read-tree --empty

if [[ -n "$CURRENT_UNTRACKED" ]]; then
    echo "$CURRENT_UNTRACKED" | xargs git add --force 2>/dev/null || true
fi

CURRENT_UNTRACKED_TREE=$(git write-tree)

# Restore original index
unset GIT_INDEX_FILE

# Compare checkpoint's untracked files (^3) with current
UNTRACKED_DIFF=$(git diff "$STASH_HASH^3" "$CURRENT_UNTRACKED_TREE" 2>/dev/null)
if [[ -n "$UNTRACKED_DIFF" ]]; then
    if [[ $have_output -ne 0 ]]; then
        echo ""
    fi
    have_output=1
    echo "# Changes between checkpoint's untracked files and current untracked files:"
    echo ""
    echo "$UNTRACKED_DIFF"
fi
