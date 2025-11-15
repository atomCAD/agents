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

# Verify the checkpoint has the expected structure with exactly three parents:
# - Main tree (^{tree}): Working tree (staged + unstaged, excluding untracked)
# - Index tree (^2^{tree}): The state of the staging area
# - Untracked tree (^3^{tree}): Untracked files
if ! VERIFY_TREE=$(git rev-parse "$VERIFY_HASH^{tree}") || \
   ! VERIFY_INDEX=$(git rev-parse "$VERIFY_HASH^2^{tree}") || \
   ! VERIFY_UNTRACKED=$(git rev-parse "$VERIFY_HASH^3^{tree}"); then
    cat >&2 <<EOF
Error: The provided hash does not appear to be a checkpoint created by create.sh

Checkpoints have a specific structure with index state tracking.
The hash you provided may be a regular git stash or commit.

CALLING AGENT: Verify this is a checkpoint hash from create.sh, not a regular stash.
Use 'git stash list' to see checkpoint hashes with their namespaces.
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

# Get tree & index & untracked hashes from temporary checkpoint
CURRENT_TREE=$(git rev-parse "$TEMP_HASH^{tree}")
CURRENT_INDEX=$(git rev-parse "$TEMP_HASH^2^{tree}")
CURRENT_UNTRACKED=$(git rev-parse "$TEMP_HASH^3^{tree}")

# No further need for temp checkpoint
"$SCRIPT_DIR/drop.sh" "$TEMP_HASH" >/dev/null 2>&1

# Verify all three components match (main tree, index, and untracked)
if [ "$VERIFY_TREE" != "$CURRENT_TREE" ] || \
   [ "$VERIFY_INDEX" != "$CURRENT_INDEX" ] || \
   [ "$VERIFY_UNTRACKED" != "$CURRENT_UNTRACKED" ]; then
    cat >&2 <<EOF
Error: Checkpoint does not match current working tree state.

The provided checkpoint hash does not represent the current state of your working tree.

Provided checkpoint: $VERIFY_HASH
Current tree:        $CURRENT_TREE (differs)

CALLING AGENT: The checkpoint verification failed. The user must:
1. Create a NEW checkpoint of current state: create.sh "stash-namespace"
2. Use that checkpoint hash with clear.sh

This safety check prevents accidentally clearing the wrong working tree state.
EOF
    exit 1
fi

# Actually clear the workspace now that verification passed
git reset --hard HEAD  # Clear staged and unstaged changes
git clean -fd          # Remove untracked files & directories
