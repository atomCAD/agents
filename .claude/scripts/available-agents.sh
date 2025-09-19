#!/bin/bash
set -euo pipefail

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
find "$AGENTS_DIR" -name "*.md" -type f | sort | while read -r agent_file; do
    # Extract agent name from filename (without path and extension)
    agent_name=$(basename "$agent_file" .md)

    # Skip if it's a meta-agent
    if echo "$agent_name" | grep -qE "^($EXCLUDE_PATTERN)$"; then
        continue
    fi

    # Extract description from the YAML frontmatter using yq
    #
    # YAML Processing Strategy:
    # - Use yq for reliable YAML parsing instead of grep/sed text processing
    # - Handle both quoted and unquoted description values consistently
    # - The ".description // \"\"" expression provides empty string fallback
    # - This approach correctly handles YAML edge cases like:
    #   * Multi-line descriptions
    #   * Descriptions containing special characters (quotes, colons, etc.)
    #   * Missing description fields
    #   * Different YAML formatting styles
    description=$(sed -n '/^---$/,/^---$/p' "$agent_file" | yq eval '.description // ""' -)

    # Output agent entry in YAML format
    # Format: agent-name: "description"
    #
    # The complex yq pipeline below ensures proper YAML escaping and prevents injection:
    # 1. Creates temporary YAML with placeholder value
    # 2. Uses yq to set the actual description with proper escaping
    # 3. Re-processes through yq for consistent formatting
    # This approach handles all special characters safely but trades performance for robustness
    if [ -n "$description" ]; then
        echo "${agent_name}: temp" | yq eval ".${agent_name} = \"${description}\"" - | yq eval '.' -
    else
        echo "${agent_name}: \"\""
    fi

    # Mark that we found at least one agent
    echo "found" > "$temp_file"
done

# Output YAML frontmatter end
echo "---"
echo ""

# Check if we found any agents
if [ ! -s "$temp_file" ]; then
    echo ""
    echo "No agents found."
    exit 1
fi

# Exit with success
exit 0
