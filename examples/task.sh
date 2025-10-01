#!/bin/bash

# Automated Task Implementation Script
#
# This script provides an automated workflow for implementing tasks from a PLAN.md file.
# It validates implementation status, identifies the next unfinished task, implements it,
# validates the implementation, and commits the changes.
#
# Prerequisites:
# - Claude CLI must be installed and configured
# - PLAN.md file must exist in the project root
# - Project must have /fix, /stage, /check, /message, and /commit workflows
#
# Exit codes:
# - 0: Success (all tasks completed or single task implemented)
# - 1: Error (validation failed, max attempts reached, etc.)
# - 130: Script interrupted by user

# Enable strict error handling and cleanup on interruption
set -euo pipefail
trap 'echo "Script interrupted by user"; exit 130' INT TERM

# ===== PHASE 1: TASK IDENTIFICATION =====
# Analyze PLAN.md to find the next unfinished task by validating actual implementation
# status against the codebase and git history, not just checkboxes in the plan.

echo "Determining next task..."
attempt=0
max_attempts=5
while true; do
    attempt=$((attempt + 1))
    if [[ $attempt -gt $max_attempts ]]; then
        echo "Error: Maximum attempts ($max_attempts) reached while trying to validate current project status" >&2
        exit 1
    fi

    # Query Claude to identify the next unfinished task from PLAN.md
    # This validates actual implementation status, not just plan checkboxes
    task=$(
        claude -p "$(cat <<'EOF'
## Goal
Validate PLAN.md implementation status and identify next task.

## Validation Process
1. Do NOT trust progress statements or checkboxes in PLAN.md
2. Actually verify against:
   - Codebase implementation
   - Git commit log

## Task Classification
- Unimplemented: No code exists
- Partially implemented: Code exists but incomplete
- Implemented but uncommitted: Code complete but not committed
- Fully implemented: Code complete and already committed

## Output Requirements
- Print ONLY a single line identifying the first unfinished task (unimplemented/partially implemented/implemented but uncommitted)
- No other output or explanations
- If ALL tasks are complete: output exactly 'All tasks completed'

## Examples

### Task Status Scenarios
1. **Unimplemented**:
   - PLAN.md shows "[ ] Add user authentication"
   - No auth code exists in codebase
   - Output: "Add user authentication"

2. **Partially Implemented**:
   - PLAN.md shows "[x] Implement database layer"
   - Some DB code exists but missing key functions
   - Output: "Implement database layer"

3. **Implemented but Uncommitted**
   - PLAN.md shows "[x] Fix login validation bug"
   - Code is complete and working
   - BUT `git diff` shows the fix is in uncommitted changes
   - Status: UNFINISHED - needs commit
   - Output: "Fix login validation bug"

4. **Fully Complete**:
   - All tasks implemented AND committed
   - No uncommitted changes related to PLAN.md tasks
   - Output: "All tasks completed"

## Important Notes
- Tasks completed but not committed = UNFINISHED
- Return the FIRST task that needs work
- Check `git diff` to catch uncommitted implementations
EOF
)" | tail -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
    )

    # Validate that the returned task string is either a valid task name or "All tasks completed"
    task_is_valid=$(
        claude --dangerously-skip-permissions -p "The following string should be either be a string that uniquely identifies a task from the PLAN.md file in the project root, or the phrase 'All tasks completed'. After performing these verification checks, print one of 'VALID', 'FINISHED', or 'UNKNOWN'. Do not output anything else. The string is: \"$task\"" | tail -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
    )

    # Handle the validation result to determine next action
    case $task_is_valid in
        "VALID")
            # Task name is valid, proceed to implementation
            break
            ;;
        "FINISHED")
            # All tasks are complete, exit successfully
            echo "All tasks completed"
            exit 0
            ;;
        "UNKNOWN")
            # Task validation failed, retry
            echo "Error: Validity of task could not be determined: ${task}" >&2
            continue
            ;;
        *)
            # Totally unexpected validation response, retry
            echo "Error: Unexpected task status: ${task_is_valid}" >&2
            continue
            ;;
    esac
done

# ===== PHASE 2: TASK IMPLEMENTATION =====
# Implement the identified task using Claude

echo "Implementing task: ${task}"
# Instruct Claude to implement the task if not already complete
claude --dangerously-skip-permissions -p "Validate the implementation status of this task as specified in the project's PLAN.md document. If finished and all validation criteria met, do nothing. If not finished, complete it now. Task: ${task}"

# ===== PHASE 3: VALIDATION LOOP =====
# Validate implementation, fix issues, stage changes

attempt=0
max_attempts=5
while true; do
    attempt=$((attempt + 1))
    if [[ $attempt -gt $max_attempts ]]; then
        echo "Error: Maximum attempts ($max_attempts) reached while trying to validate task completion" >&2
        exit 1
    fi

    # Step 1: Apply automated fixes for trivial issues (formatting, linting, etc.)
    echo "Auto-fixing trivial issues..."
    claude --dangerously-skip-permissions -p "/fix"

    # Step 2: Stage all changes related to the current task
    # This selectively stages only changes relevant to the current task
    echo "Staging changes..."
    staging=$(claude --dangerously-skip-permissions -p "/stage ${task}")
    echo "$staging"

    # Step 3: Run comprehensive validation using the project's /check workflow
    # Validates code quality, style, security, and functionality
    echo "Validating change set..."
    report=$(claude --dangerously-skip-permissions -p "/check ${task}")
    echo "$report"

    # Analyze validation report to determine if task is complete and ready for commit
    status=$(
        claude --dangerously-skip-permissions -p "The following is a validation report indicating whether the task \"$task\" has been fully completed and staged for commit. If the task is fully complete and staged, with no in-scope & do-able issues found, print exactly 'COMPLETE'. If not, print exactly 'RETRY'. Do not output anything else. Here is the report: \"$report\"" | tail -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
    )

    # Handle validation results and take appropriate action
    case $status in
        "COMPLETE")
            # Task is fully implemented and all validations pass
            echo "Task \"$task\" is complete and ready for commit."
            break
            ;;
        "RETRY")
            # Task needs additional work, apply fixes and retry
            echo "Task \"$task\" is not yet complete. Applying fixes..."
            claude --dangerously-skip-permissions -p "Based on the following validation report, fix any outstanding issues to fully complete the task \"$task\": $report"
            continue
            ;;
        *)
            # Unexpected validation response, retry
            echo "Error: Unexpected status: ${status}" >&2
            continue
            ;;
    esac
done

# ===== PHASE 4: COMMIT =====
# Generate commit message and commit the validated changes

echo "Writing commit message..."
claude --dangerously-skip-permissions -p "/message"

echo "Committing changes..."
claude --dangerously-skip-permissions -p "/commit"

echo "Task implementation complete."

# EOF
