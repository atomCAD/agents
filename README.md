# Automated Engineering Workflow

This repository implements a complete automated development workflow using Claude Code. The system can implement
multi-file features, run validation, and commit changes without human intervention.

## What's Implemented

### Safety Architecture

The core constraint is that AI agents cannot execute git state-changing commands directly. Instead, five
specialized workflows handle all repository modifications:

- Git operations are restricted to specific, validated workflows
- All changes go through mandatory validation pipelines
- Operations are atomic (complete success or clean failure)
- Working tree state is preserved across all operations

### The Slash Command System

Five specialized workflows handle the entire development lifecycle:

#### `/check [scope]` - Comprehensive Code Review

```bash
/check staged           # Review staged changes
/check src/auth/        # Review specific directory
/check                  # Smart scope detection
```

Runs parallel analysis by specialized agents (syntax, style, security, complexity, best practices). Validates
findings and generates actionable reports.

#### `/stage <description>` - Intelligent Change Staging

```bash
/stage authentication fixes
/stage typo corrections in README
/stage database migration logic
```

Selectively stages changes matching the description from mixed working trees. Uses `git apply --cached` for precision.

#### `/message` - Smart Commit Messages

```bash
/message    # Analyzes staged changes, generates proper commit message
```

Analyzes staged changes and generates commit messages following project conventions.

#### `/fix [directive]` - Automated Trivial Issue Resolution

```bash
/fix                           # Conservative mode - only safe fixes
/fix convert var to let/const  # Context-aware mode
```

Iteratively identifies and fixes trivial issues (formatting, linting, simple type errors) until only serious
problems remain.

#### `/commit [directive]` - Safe Git Commits

```bash
/commit    # Uses existing commit message, runs validation, creates commit
```

Validates code, verifies commit message, creates commit. Stashes unstaged work during validation.

## Usage

### Setup

```bash
# Copy workflow files to your project
cp -r .claude/ /path/to/your/project/
cp CLAUDE.md /path/to/your/project/
cp check.sh /path/to/your/project/

# Create task plan
echo "- [ ] Your first task" > PLAN.md

# Run automation
./examples/task.sh
```

Example `PLAN.md`:

```markdown
- [ ] Create user model with validation
- [ ] Implement registration endpoint
- [ ] Add password hashing
- [ ] Write tests
```

### Manual Workflow

```bash
# Make changes in your codebase
"Fix auth bug described as follows..."

# Fix trivial issues identified by ./check.sh
/fix

# Stage specific changes relevant to task
/stage auth bug fix

# Review changes
/check
# If any issues identified, have claude address them & return to /fix

# Generate commit message
/message

# Commit
/commit
```

### Automated Task Implementation

The [`examples/task.sh`](examples/task.sh) script demonstrates one possible, albeit incomplete route towards full automation:

1. Reads `PLAN.md` and validates actual implementation status against codebase
2. Identifies next unfinished task
3. Delegates implementation to Claude with full project context
4. Runs validation pipeline and automated fixes
   - Runs /check to identify any "In-Scope and Doable" issues
   - Calls claude to fix any in-scope issues
   - Runs /fix to get ./check.sh passing
   - Stages fixes with /stage
   - Repeat until no "In-Scope and Doable" issues remain
5. Creates atomic commit

## Current Status

The five core slash commands (`/check`, `/stage`, `/message`, `/fix`, `/commit`) and their associated
subagents are stable and work reliably.

The `examples/task.sh` automation script is an experimental integration demonstrating one possible route to
full automation. This script is expected to be fragile and may require significant debugging and refinement for
practical use. It is not meant as anything more than a proof of concept.

### Known Issues

Many specialized agent definition files are missing from the `.claude/agents/` directory. The slash commands
currently fall back to general-purpose agents when domain-specific agents are unavailable. This works but may
produce less optimal results than specialized agents would provide.
