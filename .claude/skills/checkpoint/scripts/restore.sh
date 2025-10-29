#!/bin/bash
# Restore from a checkpoint
# Usage: restore.sh <stash-hash>
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <stash-hash>" >&2
    exit 2
fi

STASH_HASH="$1"

# Verify working tree is completely clean before restoring
# Check for any changes (staged, unstaged, or untracked)
if ! git diff --quiet HEAD || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    cat >&2 <<EOF
Error: Working tree is not clean. Cannot restore checkpoint.

Current changes detected:
$(git status --short)

CALLING AGENT: Checkpoint restore requires a clean working tree to prevent data loss.

To restore this checkpoint, the user must:
1. Create a safety checkpoint: TEMP=\$(create.sh "temp-before-restore")
2. Clear working tree: clear.sh "\$TEMP"
3. Restore desired checkpoint: restore.sh "$STASH_HASH"
4. Drop temporary checkpoint: drop.sh "\$TEMP"

Alternatively, if they want to keep current changes:
- Commit them: /commit
- Or create a permanent checkpoint: create.sh "descriptive-name"
EOF
    exit 1
fi

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

# Verify HEAD hasn't changed since checkpoint creation
CHECKPOINT_BASE=$(git rev-parse "$STASH_HASH^1")
CURRENT_HEAD=$(git rev-parse HEAD)

if [ "$CHECKPOINT_BASE" != "$CURRENT_HEAD" ]; then
    cat >&2 <<EOF
Error: HEAD has changed since checkpoint was created.

Checkpoint was created at commit: $CHECKPOINT_BASE
Current HEAD is at commit:       $CURRENT_HEAD

This checkpoint cannot be restored because the base commit has changed.
This may have happened due to:
- New commits made after checkpoint creation
- Git rebase or commit amendment
- Branch switching
- Git reset operations

CALLING AGENT: Checkpoints are scoped to specific commits and cannot be restored after HEAD changes.

If the user wants to restore this checkpoint's changes:
1. They must first return to the original commit: git checkout $CHECKPOINT_BASE
2. Then restore the checkpoint: restore.sh "$STASH_HASH"

Alternatively, create a new checkpoint at the current HEAD instead of restoring the old one.
EOF
    exit 1
fi

# Count how many times this hash appears
COUNT_BEFORE=$(echo "$MATCHING_ENTRIES" | wc -l)

# Get the first (most recent) stash@{N} identifier for this hash
STASH_ID=$(echo "$MATCHING_ENTRIES" | head -n1 | awk '{print $1}')

PATCH_FILE=".checkpoint-index.patch"

# Discard all current changes (working tree and staging area)
git reset --hard HEAD

# Restore the checkpoint (working tree and untracked files)
# Note: git stash apply puts NEW files into the staging area automatically
git stash apply "$STASH_ID"

# Unstage everything (git stash apply stages new files but not edits to tracked files)
git reset HEAD >/dev/null 2>&1

# If staging area patch exists, restore it and clean up
if [ -f "$PATCH_FILE" ]; then
    # Apply the patch to restore the correct staging area state
    git apply --cached "$PATCH_FILE"
    # Clean up the patch file
    rm "$PATCH_FILE"
fi

# Verify the apply succeeded by checking the count stayed the same
STASH_LIST_AFTER=$(git stash list --format="%H")
COUNT_AFTER=$(echo "$STASH_LIST_AFTER" | grep -cF "$STASH_HASH" || true)

if [ "$COUNT_AFTER" -ne "$COUNT_BEFORE" ]; then
    cat >&2 <<EOF
CRITICAL ERROR: Checkpoint restore failed verification.

Expected hash '$STASH_HASH' to appear $COUNT_BEFORE times after restore.
Before restore: $COUNT_BEFORE occurrences
After restore: $COUNT_AFTER occurrences

The git stash apply command may have failed unexpectedly.

CALLING AGENT: Do NOT continue automated operations. Report this error to the user immediately
and recommend manual inspection with 'git stash list'.
EOF
    exit 1
fi
