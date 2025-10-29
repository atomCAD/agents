# Untestable Code Paths

This document describes code paths in the checkpoint scripts that are defensive
error handling for exceptional conditions that cannot be reliably tested in a
bash integration test environment.

## 1. create.sh: Stash Verification Failure (lines 28-43)

**Code path:**

```bash
git stash push --include-untracked -m "$CHECKPOINT_MESSAGE" >&2

STASH_INFO=$(git stash list --format="%H %gs" | grep -F "$CHECKPOINT_MESSAGE" | head -n1)

if [ -z "$STASH_INFO" ]; then
    cat >&2 <<EOF
CRITICAL ERROR: Checkpoint creation failed verification.
...
EOF
    exit 1
fi
```

**Why untestable:**
This path is only triggered when `git stash push` succeeds (exit 0) but the
stash cannot be found in `git stash list`. This can only occur due to:

- Git internal bugs
- Race conditions (another process modifying stash list)
- Filesystem corruption
- Git database corruption

**Why these can't be tested:**

- Git doesn't provide hooks for stash operations
- Mocking git commands requires complex wrapper scripts
- Intentional corruption is unreliable and dangerous
- Race conditions are non-deterministic

**Recommendation:**
This is defensive programming that protects against catastrophic failures. The
error message correctly instructs the calling agent to stop and report the
error. Manual code review confirms the logic is correct.

## 2. restore.sh: Pop Verification Failure (lines 109-123)

**Code path:**

```bash
git stash pop "$STASH_ID"

# Verify the pop succeeded by checking the count decreased by exactly 1
STASH_LIST_AFTER=$(git stash list --format="%H")
COUNT_AFTER=$(echo "$STASH_LIST_AFTER" | grep -cF "$STASH_HASH" || true)

if [ "$COUNT_AFTER" -ne $((COUNT_BEFORE - 1)) ]; then
    cat >&2 <<EOF
CRITICAL ERROR: Checkpoint restore failed verification.
...
EOF
    exit 1
fi
```

**Why untestable:**
This requires `git stash pop` to succeed but the stash count not decrease by
exactly 1. This is impossible in normal git operation and would indicate:

- Multiple stashes with identical hashes (git corruption)
- Stash not actually removed despite pop success (git bug)
- Concurrent modification of stash list

**Why these can't be tested:**
Same reasons as #1, plus the additional complexity that git's stash hash
uniqueness is cryptographically guaranteed.

**Recommendation:**
Defensive programming for impossible edge cases. The verification logic is
correct by inspection.

## 3. drop.sh: Drop Verification Failure (lines 45-59)

**Code path:**

```bash
git stash drop "$STASH_ID"

# Verify the drop succeeded by checking the count decreased by exactly 1
STASH_LIST_AFTER=$(git stash list --format="%H")
COUNT_AFTER=$(echo "$STASH_LIST_AFTER" | grep -cF "$STASH_HASH" || true)

if [ "$COUNT_AFTER" -ne $((COUNT_BEFORE - 1)) ]; then
    cat >&2 <<EOF
CRITICAL ERROR: Checkpoint drop failed verification.
...
EOF
    exit 1
fi
```

**Why untestable:**
Same as #2 - requires drop to succeed but count not decrease correctly.

**Why these can't be tested:**
Same reasons as #1 and #2.

**Recommendation:**
Defensive programming. Logic is correct by inspection.

## Summary

All three untestable code paths are:

1. **Defensive error handling** for exceptional conditions
2. **Correctly implemented** (verified by code review)
3. **Properly documented** with clear error messages
4. **Instruct the calling agent** to stop and report errors

These paths exist to catch the impossible edge cases and git failures. They
provide safety guarantees that make the checkpoint system robust against
catastrophic failures.
