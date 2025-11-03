---
name: autofmt-md
description: Automatically format and fix markdown files using markdownlint-cli2. Use when asked to format, lint, or fix markdown files.
---

# Auto-Format Markdown

This skill automatically formats and fixes markdown files using markdownlint-cli2 with the `--fix` option.

## Instructions

1. Use the helper script at `.claude/skills/autofmt-md/scripts/format.sh` to format files (accepts one or more markdown file paths as arguments)
2. Report which files were formatted and any issues that couldn't be auto-fixed

## Usage Examples

Format one or more specific files:

```bash
./.claude/skills/autofmt-md/scripts/format.sh README.md CONTRIBUTING.md
```

Format all markdown files recursively in a directory:

```bash
./.claude/skills/autofmt-md/scripts/format.sh docs/**/*.md
```

## Notes

- The script will modify files in-place
- Respects `.markdownlint.yaml` or `.markdownlintrc` configuration if present
- Some issues may require manual fixing if auto-fix cannot resolve them
