---
name: checkpoint
description: Manage git checkpoints for safe code experimentation with automatic rollback. Use when you need to try risky changes, refactorings, or experiments that might need reverting.
---

# Git Checkpoint Management

This skill provides checkpoint operations for safely experimenting with code changes using git stash to create
restore points that capture both working tree and staging area state.

## Instructions

Use the helper scripts in `scripts` to manage checkpoints:

### 1. Create a checkpoint before risky changes

```bash
CHECKPOINT_HASH=$(scripts/create.sh "checkpoint-namespace")
```

Outputs the stash hash (e.g., `abc123def456...`) which you use for subsequent operations.

**What gets saved:**

- All working tree changes (staged and unstaged)
- All untracked files
- Staging area state

**Namespace convention:** Use a namespace that identifies which workflow or agent created the checkpoint (e.g.,
"fix-workflow", "commit-validation", "refactoring-agent"). This helps identify the source when debugging stash
entries.

### 2. Compare current state with checkpoint

```bash
scripts/compare.sh "$CHECKPOINT_HASH"
```

Shows the diff between current code and the checkpoint.

### 3. Drop checkpoint (discard checkpoint, keep current state)

```bash
scripts/drop.sh "$CHECKPOINT_HASH"
```

Removes the checkpoint from the stash stack. Use when changes are successful and you no longer need to revert.

### 4. Clear working tree (verified destructive operation)

```bash
scripts/clear.sh "$CHECKPOINT_HASH"
```

Clears the working tree with safety verification. Only succeeds if the provided checkpoint hash exactly matches
the current working tree state (verified by comparing tree objects).

**Safety guarantee:** Cannot clear the wrong state - prevents accidental data loss.

### 5. Restore from checkpoint (requires clean working tree)

```bash
scripts/restore.sh "$CHECKPOINT_HASH"
```

Restores both working tree and staging area to the checkpointed state.

**Safety guarantees:**

- Refuses to run if working tree is not completely clean (no staged, unstaged, or untracked changes)
- Refuses to run if HEAD has changed since checkpoint creation (prevents rebase/commit conflicts)
- Checkpoint remains in stash after restore

## Typical Workflows

### Workflow 1: Experiment with automatic cleanup

Create a checkpoint before attempting risky changes:

```bash
CHECKPOINT=$(scripts/create.sh "before-refactoring")
```

Make experimental changes. This might involve invoking an agent to attempt a
refactoring, running a complex transformation script, or manually editing files.

Once changes are complete, review them:

```bash
scripts/compare.sh "$CHECKPOINT"
```

Evaluate whether the changes accomplish the goal. Consider correctness,
completeness, and any unintended side effects.

If changes didn't work out, restore the checkpoint:

```bash
scripts/restore.sh "$CHECKPOINT"
```

Once restoration is no longer needed, cleanup the checkpoint:

```bash
scripts/drop.sh "$CHECKPOINT"
```

### Workflow 2: Restore checkpoint with dirty working tree

When you need to restore a checkpoint but have uncommitted changes:

```bash
# Create safety checkpoint of current state
TEMP=$(scripts/create.sh "temp-before-restore")

# Clear working tree (only succeeds if TEMP matches current state)
scripts/clear.sh "$TEMP"

# Restore desired checkpoint
scripts/restore.sh "$ORIGINAL_CHECKPOINT"

# Drop temporary checkpoint
scripts/drop.sh "$TEMP"
```

### Workflow 3: Abandon experiment and revert

```bash
# After experimenting, decide changes are not good
# Create checkpoint of bad state for reference
BAD_STATE=$(scripts/create.sh "failed-experiment")

# Clear the bad state
scripts/clear.sh "$BAD_STATE"

# Restore original checkpoint
scripts/restore.sh "$ORIGINAL_CHECKPOINT"

# Optionally drop both checkpoints
scripts/drop.sh "$BAD_STATE"
scripts/drop.sh "$ORIGINAL_CHECKPOINT"
```

## Safety Guarantees

**Non-destructive by default:**

- `create.sh` - Captures state, never modifies working tree
- `compare.sh` - Read-only operation
- `drop.sh` - Removes checkpoint from stash, never touches working tree
- `restore.sh` - Refuses to run unless working tree is completely clean

**Verified destructive operations:**

- `clear.sh` - Only destructive operation, requires checkpoint hash verification

**Forced explicit workflow:**

- Cannot accidentally restore over uncommitted work
- Must consciously create safety checkpoint before clearing
- Tree comparison ensures checkpoint actually represents current state
- Checkpoints scoped to specific commits - cannot restore after HEAD changes

## Implementation Details

**Checkpoint contents:**

- Created with `git stash push --include-untracked`
- Staging area saved to `.checkpoint-index.patch` (included in stash as untracked file)
- Namespace + ISO timestamp used for stash message
- Returns commit hash for reliable identification

**Verification:**

- All operations validate stash exists before proceeding
- Duplicate hash detection via occurrence counting
- Tree object comparison in `clear.sh` ensures exact state match
- HEAD verification in `restore.sh` prevents cross-commit restoration
- Post-operation verification confirms stash manipulation succeeded

**Error handling:**

- Exit code 2: Usage errors (missing/invalid arguments)
- Exit code 1: Operation failures (validation errors, git errors)
- Exit code 0: Success
- All errors include "CALLING LLM:" instructions for recovery
