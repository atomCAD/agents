#!/bin/bash
# Clear working tree after verifying it matches a checkpoint
# Usage: clear.sh <stash-hash>
# Only succeeds if the provided stash exactly matches current working tree state
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <stash-hash>" >&2
    exit 2
fi

VERIFY_HASH="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Verify the provided stash exists
STASH_LIST=$(git stash list --format="%H %gs")
if ! echo "$STASH_LIST" | grep -qF "$VERIFY_HASH"; then
    cat >&2 <<EOF
Error: Checkpoint not found with hash '$VERIFY_HASH'

Recent checkpoint hashes:
$(echo "$STASH_LIST" | head -n5)

CALLING AGENT: The provided checkpoint hash is invalid or has been dropped.
Verify the hash with 'git stash list'.
EOF
    exit 1
fi

# Verify we can parse the tree hash BEFORE creating temp checkpoint
# This prevents clearing the working tree if the checkpoint is corrupted
if ! VERIFY_TREE=$(git rev-parse "$VERIFY_HASH^{tree}" 2>/dev/null); then
    cat >&2 <<EOF
Error: Cannot parse tree from checkpoint '$VERIFY_HASH'

This may indicate a corrupted git object database.

CALLING AGENT: The checkpoint exists but its tree cannot be accessed.
Try running 'git fsck' to check for corruption.
EOF
    exit 1
fi

# Create temporary checkpoint of current state for comparison
TEMP_NAMESPACE="clear-verify-$(date +%s)"
if ! TEMP_HASH=$("$SCRIPT_DIR/create.sh" "$TEMP_NAMESPACE" 2>/dev/null); then
    cat >&2 <<EOF
Error: Failed to create verification checkpoint.

This may indicate no changes exist in the working tree, or a git error occurred.

CALLING AGENT: Cannot verify working tree state. Check git status and try again.
EOF
    exit 1
fi

# Compare the two stashes by comparing their tree contents
# Git stashes with --include-untracked have three parents:
# - Main tree (^{tree}): The merged state of working tree and index
# - Index tree (^2^{tree}): The state of the staging area
# - Untracked tree (^3^{tree}): The untracked files (may not exist if no untracked files)
CURRENT_TREE=$(git rev-parse "$TEMP_HASH^{tree}")

# Compare index trees (staging area state)
VERIFY_INDEX=$(git rev-parse "$VERIFY_HASH^2^{tree}" 2>/dev/null || echo "")
CURRENT_INDEX=$(git rev-parse "$TEMP_HASH^2^{tree}" 2>/dev/null || echo "")

# Compare untracked trees (may not exist if no untracked files)
VERIFY_UNTRACKED=$(git rev-parse "$VERIFY_HASH^3^{tree}" 2>/dev/null || echo "")
CURRENT_UNTRACKED=$(git rev-parse "$TEMP_HASH^3^{tree}" 2>/dev/null || echo "")

if [ "$VERIFY_TREE" != "$CURRENT_TREE" ] || \
   [ "$VERIFY_INDEX" != "$CURRENT_INDEX" ] || \
   [ "$VERIFY_UNTRACKED" != "$CURRENT_UNTRACKED" ]; then
    # Trees don't match - restore working tree from temp checkpoint and clean up
    "$SCRIPT_DIR/restore.sh" "$TEMP_HASH" >/dev/null 2>&1
    "$SCRIPT_DIR/drop.sh" "$TEMP_HASH" >/dev/null 2>&1

    cat >&2 <<EOF
Error: Checkpoint does not match current working tree state.

The provided checkpoint hash does not represent the current state of your working tree.

Provided checkpoint: $VERIFY_HASH
Current tree:        $CURRENT_TREE (differs)

CALLING AGENT: The checkpoint verification failed. The user must:
1. Create a NEW checkpoint of current state: create.sh "temp-before-clear"
2. Use that checkpoint hash with clear.sh

This safety check prevents accidentally clearing the wrong working tree state.
EOF
    exit 1
else
    # Verification passed - drop the temp checkpoint
    "$SCRIPT_DIR/drop.sh" "$TEMP_HASH" >/dev/null 2>&1
fi

# Working tree is now clean (temp checkpoint creation stashed all changes)
