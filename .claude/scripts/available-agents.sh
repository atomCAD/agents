#!/bin/bash

# Available Agents Detection Script
# Purpose: List available analysis agents while filtering out meta-agents
#
# Meta-agents are orchestration/coordination agents that:
#   - Don't perform actual code analysis
#   - Coordinate or manage other agents
#   - Provide infrastructure support
#
# This script outputs agents with their descriptions in the format:
# agent-name: "description from agent file"

# Configuration: Meta-agents to exclude
# These agents are for orchestration and team composition, not actual analysis
META_AGENTS=(
    "analyst-roster"      # Team composition specialist (selects other agents)
    "scope-analyzer"      # Scope determination specialist (determines what to analyze)
)

# Base directory for agent definitions
AGENTS_DIR="$(dirname "$0")/../agents"

# Check if agents directory exists
if [ ! -d "$AGENTS_DIR" ]; then
    echo "Error: Agents directory not found at $AGENTS_DIR" >&2
    exit 1
fi

# Build grep exclusion pattern from META_AGENTS array
# This creates a pattern like: (analyst-roster|scope-analyzer)
EXCLUDE_PATTERN=$(IFS='|'; echo "${META_AGENTS[*]}")

# Use a temp file to track if we found any agents
temp_file=$(mktemp)
# shellcheck disable=SC2064
trap "rm -f '$temp_file'" EXIT

# Output YAML frontmatter start
echo "---"

# Process each agent file (including in subdirectories)
find "$AGENTS_DIR" -name "*.md" -type f | while read -r agent_file; do
    # Extract agent name from filename (without path and extension)
    agent_name=$(basename "$agent_file" .md)

    # Skip if it's a meta-agent
    if echo "$agent_name" | grep -qE "^($EXCLUDE_PATTERN)$"; then
        continue
    fi

    # Extract description from the YAML frontmatter
    # The format is: description: "actual description text"
    description=$(grep '^description: ' "$agent_file" | head -n1 | sed 's/^description: "//' | sed 's/"$//')

    # Output in the format: agent-name: "description"
    if [ -n "$description" ]; then
        echo "${agent_name}: \"${description}\""
    else
        echo "${agent_name}"
    fi

    # Mark that we found at least one agent
    echo "found" > "$temp_file"
done | sort

# Output YAML frontmatter end
echo "---"

# Check if we found any agents
if [ ! -s "$temp_file" ]; then
    echo ""
    echo "No agents found."
    exit 1
fi

# Exit with success
exit 0
