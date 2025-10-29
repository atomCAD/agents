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
PATCH_FILE=".checkpoint-index.patch"

# Save staged changes to patch file if any exist
if ! git diff --staged --quiet >/dev/null 2>&1; then
    git diff --staged > "$PATCH_FILE"
fi

# Create checkpoint using git stash (captures everything including patch file)
# --include-untracked: includes untracked files (including our patch file)
git stash push --include-untracked -m "$CHECKPOINT_MESSAGE" >&2

# Verify the stash was created and extract the hash
STASH_INFO=$(git stash list --format="%H %gs" | grep -F "$CHECKPOINT_MESSAGE" | head -n1)

if [ -z "$STASH_INFO" ]; then
    cat >&2 <<EOF
CRITICAL ERROR: Checkpoint creation failed verification.

The git stash command appeared to succeed but the stash cannot be found.
This indicates an unpredictable failure that may have left the workspace in an inconsistent state.

Expected stash message: $CHECKPOINT_MESSAGE
Current stash list:
$(git stash list --format="%gs" | head -n5)

CALLING AGENT: Do NOT continue automated operations. Report this error to the user immediately
and recommend manual inspection with 'git status' and 'git stash list'.
EOF
    exit 1
fi

STASH_HASH=$(echo "$STASH_INFO" | cut -d' ' -f1)

# Output the hash
echo "$STASH_HASH"
