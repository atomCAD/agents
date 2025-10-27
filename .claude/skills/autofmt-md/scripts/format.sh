#!/bin/bash
set -euo pipefail

# Auto-format markdown files using markdownlint-cli2

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file1.md> [file2.md ...]"
    echo "Example: $0 README.md docs/**/*.md"
    exit 2
fi

# Check if markdownlint-cli2 is installed
if ! command -v markdownlint-cli2 &> /dev/null; then
    echo "Error: markdownlint-cli2 is not installed"
    echo "Install it with: npm install -g markdownlint-cli2"
    exit 2
fi

# Format each file
echo "Formatting markdown files..."
code=0
for file in "$@"; do
    if [ ! -f "$file" ]; then
        echo "Error: $file not found; skipping" >&2
        code=2
        continue
    fi

    echo "Formatting: $file"
    if ! markdownlint-cli2 --fix "$file"; then
        echo "Error: Some issues in $file could not be auto-fixed" >&2
        code=2
    fi
done

exit $code
