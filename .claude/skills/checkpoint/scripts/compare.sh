#!/bin/bash
# Compare current state with a checkpoint
# Usage: compare.sh <stash-hash>
# Outputs: diff between current state and checkpoint
set -euo pipefail

if [ $# -eq 0 ]; then
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

git diff "$STASH_HASH"
