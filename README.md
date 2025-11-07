# Automated Engineering Workflow

This repository implements a complete automated development workflow using Claude Code. The system can execute complex project plans by implementing discrete tasks, running validation, and creating atomic commits without human intervention.

## What's Implemented

### Safety Architecture

Claude Code runs inside a sandboxed devcontainer environment that provides isolation and security hardening:

- Isolated container environment prevents host system access
- Resource limits (8GB RAM, 2 CPU cores) prevent resource exhaustion
- Security hardening with `--cap-drop=ALL` and `--security-opt=no-new-privileges`
- Docker-in-Docker support for Claude Code's analysis tools

This allows the system to run with `--dangerously-skip-permissions` safely for fully automated workflows.

### Development Best Practices

The workflow enforces software engineering best practices through structured automation:

- Git operations are restricted to specific, validated workflows
- All changes go through mandatory validation pipelines
- Operations are atomic (complete success or clean failure)
- Working tree state is preserved across all operations

### The Slash Command System

Nine specialized workflows handle the entire development lifecycle:

#### `/plan [directive]` - Plan Management

```bash
/plan implement user authentication    # Create new plan
/plan                                  # Review and improve existing plan
/plan add task to implement OAuth      # Extend existing plan
```

Creates and manages PLAN.md documents with atomic task decomposition following GTD Natural Planning Model. Transforms feature requests into executable tasks with clear outcomes and dependencies.

#### `/next [directive]` - Task Selection

```bash
/next                          # Select next available task
/next focus on database tasks  # Filter by preference
```

Analyzes PLAN.md and selects the optimal next task based on completion status, dependencies, and priority. Provides task identifier and selection reasoning.

#### `/task [directive]` - Task Implementation

```bash
/task                          # Implement next available task
/task password validation      # Implement specific task from PLAN.md
/task Add email validation to registration with min 6 chars and special character requirement    # Implement ad-hoc task
```

Implements tasks from PLAN.md or fully-specified ad-hoc tasks following TDD practices (red-green-refactor cycle). Writes tests, implements functionality, refactors for quality, and updates PLAN.md when applicable.

#### `/fix [directive]` - Automated Trivial Issue Resolution

```bash
/fix                           # Conservative mode - only safe fixes
/fix convert var to let/const  # Context-aware mode
```

Iteratively identifies and fixes trivial issues (formatting, linting, simple type errors) until only serious problems remain.

#### `/check [scope]` - Comprehensive Code Review

```bash
/check staged           # Review staged changes
/check src/auth         # Review specific directory
/check                  # Smart scope detection
```

Runs parallel analysis by specialized critic agents. Validates findings and generates actionable reports.

#### `/split [directive]` - Change Decomposition

```bash
/split                                 # Decompose all unstaged changes
/split focus on authentication         # Filter decomposition
```

Analyzes unstaged changes and decomposes them into semantic atomic changes suitable for separate commits. Generates precise staging commands for each change.

#### `/stage <description>` - Intelligent Change Staging

```bash
/stage authentication fixes
/stage typo corrections in README
/stage database migration logic
```

Selectively stages changes matching the description from mixed working trees. Applies LLM-generated patches to `git apply --cached` rather than adding whole files or hunks, allowing for the careful staging of overlapping change sets.

#### `/message` - Smart Commit Messages

```bash
/message    # Analyzes staged changes, generates proper commit message
```

Analyzes staged changes and generates commit messages following project conventions.

#### `/commit [directive]` - Safe Git Commits

```bash
/commit    # Uses existing commit message, runs validation, creates commit
```

Validates code, verifies commit message, creates commit. Stashes unstaged work during validation.

## Usage

### Setup

#### Devcontainer Setup (Recommended for Full Automation)

For fully automated workflows, which require the aptly named `--dangerously-skip-permissions`:

**Prerequisites:** Docker is required (Podman or other containerization solutions may work but are untested).

1. **Open the directory in Visual Studio Code**
   Use the VS Code interface to open the directory containing this README, or run:

   ```bash
   code .
   ```

2. **Install devcontainer plugin** (if prompted)
   VS Code may prompt you to install the Dev Containers extension - click "Install"

3. **Reopen in Container**
   VS Code will show a prompt to "Reopen in Container" - click this prompt

4. **Wait for container setup**
   The container will build and configure automatically. This may take a few minutes on first run.

5. **Open Claude Code**
   Click the Claude Code icon in the VS Code interface.
   This opens Claude Code in an embedded terminal window within the container.

6. **Provide login credentials**
   You'll be prompted for your Anthropic login credentials. These are saved in `.git/.config/claude` and persist across container rebuilds.

7. **Launch a new terminal within the devcontainer**
   You have several options depending on where you want to interact with the command-line tools:
   - **Bottom Pane**: Terminal -> New Terminal in VS Code (opens a terminal on the bottom pane)
   - **Side Pane**: Click the Claude Code icon, then hit Ctrl+C twice to exit `claude` and get a bash prompt (opens a terminal on the side pane)
   - **External**: Run `devcontainer exec --workspace-folder .` from any terminal emulator at the project root (requires installing devcontainer-cli)

8. **Start Claude Code with permissions flag**
   From the terminal, run:

   ```bash
   claude --dangerously-skip-permissions
   ```

   This allows automated workflows to execute without interactive permission prompts.

**Why devcontainer for automation?**

The devcontainer provides the secure, isolated environment, allowing Claude Code to safely run in so-called "YOLO mode." This is required to support fully automated workflows where the user is not present to respond to interactive permission prompts.

### Manual Workflow

#### Planning Phase

Start by creating a plan for your project:

```bash
# Create initial plan with desired outcomes
/plan implement user authentication with OAuth and password support

# Review and refine the plan
/plan

# Extend the plan with additional features
/plan add password reset functionality

# Continue refining until plan is complete
# Review PLAN.md document after each iteration
# At some point, the plan will stabilize and no further changes will be suggested
/plan
```

#### Implementation Phase

Execute tasks from the plan:

```bash
# Implement the next task in PLAN.md
/task

# Or:

# Select next task to work on
/next focus on authentication tasks
/task \[name of task suggested by /next\]

# Or implement a specific task
/task password validation
```

#### Review Phase

Validate and fix issues:

```bash
# Fix trivial issues identified by ./check.sh
/fix

# Review changes for quality and correctness
/check
# If any issues identified, have claude address them & return to /fix
```

#### Commit Phase

If you have mixed changes that should be separated into multiple commits, decompose them first:

```bash
# Analyze unstaged changes and suggest atomic groupings
/split

# Review the suggested decomposition and staging directives
```

Stage and commit your changes:

```bash
# Stage specific changes relevant to task
/stage password validation implementation

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

Most core slash commands are stable and work reliably:

- **Planning workflow**: `/plan`, `/next`, `/task` - Plan management, task selection, and TDD-based implementation
- **Quality workflow**: `/fix`, `/split` - Automated fixes and change decomposition
- **Commit workflow**: `/stage`, `/message`, `/commit` - Intelligent staging, message generation, and safe commits

**Note on `/check`**: The `/check` command is currently unstable and unreliable. It works, but requires user oversight. It is sometimes better to just tell Claude to "call a few specialists to review, and report the results." It is anticipated that the `/check` command will be split into multiple specialized commands with an on-disk system for tracking review data and findings, which is expected to work more reliably.

The `examples/task.sh` automation script is an experimental integration demonstrating one possible route to full automation. This script is expected to be fragile and may require significant debugging and refinement for practical use. It is not meant as anything more than a proof of concept.

### Known Issues

Many specialized agent definition files are missing from the `.claude/agents/` directory. The slash commands currently fall back to general-purpose agents when domain-specific agents are unavailable. This works but may produce less optimal results than specialized agents would provide.
