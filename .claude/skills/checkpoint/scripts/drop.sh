#!/bin/bash
# Drop a checkpoint (keep current changes)
# Usage: drop.sh <stash-hash>
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <stash-hash>" >&2
    exit 2
fi

STASH_HASH="$1"

# Get all stashes once
STASH_LIST=$(git stash list --format="%gd %H %gs")

# Get all entries matching this hash
MATCHING_ENTRIES=$(echo "$STASH_LIST" | grep -F "$STASH_HASH")

if [ -z "$MATCHING_ENTRIES" ]; then
    cat >&2 <<EOF
Error: Checkpoint not found with hash '$STASH_HASH'

Recent checkpoint hashes:
$(echo "$STASH_LIST" | cut -d' ' -f2- | head -n5)

CALLING AGENT: This checkpoint hash is invalid or the checkpoint was already dropped.
Verify the hash and check 'git stash list' for available checkpoints.
EOF
    exit 1
fi

# Count how many times this hash appears
COUNT_BEFORE=$(echo "$MATCHING_ENTRIES" | wc -l)

# Get the first (most recent) stash@{N} identifier for this hash
STASH_ID=$(echo "$MATCHING_ENTRIES" | head -n1 | awk '{print $1}')

# Drop the stash
git stash drop "$STASH_ID"

# Verify the drop succeeded by checking the count decreased by exactly 1
STASH_LIST_AFTER=$(git stash list --format="%H")
COUNT_AFTER=$(echo "$STASH_LIST_AFTER" | grep -cF "$STASH_HASH" || true)

if [ "$COUNT_AFTER" -ne $((COUNT_BEFORE - 1)) ]; then
    cat >&2 <<EOF
CRITICAL ERROR: Checkpoint drop failed verification.

Expected hash '$STASH_HASH' to appear $((COUNT_BEFORE - 1)) times after drop.
Before drop: $COUNT_BEFORE occurrences
After drop: $COUNT_AFTER occurrences

The git stash drop command may have failed or dropped the wrong entry.

CALLING AGENT: Do NOT continue automated operations. Report this error to the user immediately
and recommend manual inspection with 'git stash list'.
EOF
    exit 1
fi
