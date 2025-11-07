#!/bin/bash

# Automated Task Implementation Script
#
# This script provides an automated workflow for implementing tasks from a PLAN.md file.
# It validates implementation status, identifies the next unfinished task, implements it,
# validates the implementation, and commits the changes.
#
# Prerequisites:
# - Claude Code must be installed and configured
# - User must be logged in with Claude Max subscription or have provided an API key
#
# Exit codes:
# - 0: Success (all tasks completed or single task implemented)
# - 1: Error (validation failed, max attempts reached, etc.)
# - 130: Script interrupted by user

# Enable strict error handling and cleanup on interruption
set -euo pipefail
trap 'echo "Script interrupted by user"; exit 130' INT TERM

# ===== PHASE 1: TASK SELECTION =====
# Use /next to select the optimal next task from PLAN.md

echo "Determining next task..."
attempt=0
max_attempts=5
while true; do
    attempt=$((attempt + 1))
    if [[ $attempt -gt $max_attempts ]]; then
        echo "Error: Maximum attempts ($max_attempts) reached while trying to select task" >&2
        exit 1
    fi

    # Use /next slash command to select the optimal next task
    task=$(
        claude --dangerously-skip-permissions -p "/next" | tail -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
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
# Route to appropriate workflow based on task type

echo "Implementing task: ${task}"

# Determine if this is a planning task or implementation task
task_type=$(
    claude --dangerously-skip-permissions -p "Analyze the following task and determine if it is a planning task or an implementation task. Planning tasks involve updating PLAN.md, adding new tasks, or revising the plan structure. Implementation tasks involve writing code, tests, or documentation, or anything else not related to project planning or solely confined to maintenance of the PLAN.md document. Print exactly 'PLAN' for planning tasks or 'TASK' for implementation tasks. Do not output anything else. Task: \"$task\"" | tail -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
)

# Route to appropriate slash command based on task type
case $task_type in
    "PLAN")
        echo "Routing to /plan workflow..."
        claude --dangerously-skip-permissions -p "/plan perform planning action: ${task}"
        ;;
    "TASK")
        echo "Routing to /task workflow..."
        claude --dangerously-skip-permissions -p "/task ${task}"
        ;;
    *)
        echo "Error: Could not determine task type: ${task_type}" >&2
        exit 1
        ;;
esac

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
    report=$(claude --dangerously-skip-permissions -p "/check staged")
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
