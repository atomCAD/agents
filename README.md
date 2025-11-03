# Automated Engineering Workflow

This repository implements a complete automated development workflow using Claude Code. The system can implement multi-file features, run validation, and commit changes without human intervention.

## What's Implemented

### Safety Architecture

The core constraint is that AI agents cannot execute git state-changing commands directly. Instead, five specialized workflows handle all repository modifications:

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

Runs parallel analysis by specialized agents (syntax, style, security, complexity, best practices). Validates findings and generates actionable reports.

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

Iteratively identifies and fixes trivial issues (formatting, linting, simple type errors) until only serious problems remain.

#### `/commit [directive]` - Safe Git Commits

```bash
/commit    # Uses existing commit message, runs validation, creates commit
```

Validates code, verifies commit message, creates commit. Stashes unstaged work during validation.

## Usage

### Setup

#### Devcontainer Setup (Recommended for Full Automation)

For fully automated workflows, which require the aptly named `--dangerously-skip-permissions`:

**Prerequisites:** Docker is required (Podman may work but is untested).

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
   You'll be prompted for your Claude credentials. These are saved in `.git/.config/claude` and persist across container rebuilds.

7. **Launch a new terminal within the devcontainer**
   You have several options depending on where you want to interact with the command-line tools:
   - **Bottom Pane**: Terminal -> New Terminal in VS Code (opens a terminal on the bottom pane)
   - **Side Pane**: Click the Claude Code icon, then hit Ctrl+C twice to exit claude and get a bash prompt (opens a terminal on the side pane)
   - **External**: Run `devcontainer exec --workspace-folder .` from any terminal emulator at the project root (requires installing devcontainer-cli)

8. **Create task plan**
   Create a `PLAN.md` file with a listing of discrete, atomic commits to be generated in sequence.

9. **Run automation**
   From the terminal in the devcontainer, run the automated task script:

   ```bash
   ./examples/task.sh
   ```

**Why devcontainer for automation?**

The devcontainer provides a secure, isolated environment where Claude can safely run with `--dangerously-skip-permissions`. This flag is required for fully automated workflows like `examples/task.sh` that need to execute slash commands using the command-line API, which lacks interactive permission prompts.

**Security benefits:**

- Isolated container environment prevents host system access
- Resource limits (8GB RAM, 2 CPU cores) prevent resource exhaustion
- Security hardening with `--cap-drop=ALL` and `--security-opt=no-new-privileges`
- Docker-in-Docker support for Claude Code's analysis tools

### Manual Workflow

Simply run the slash commands in sequence as needed. For example, to implement a bug fix:

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

The five core slash commands (`/check`, `/stage`, `/message`, `/fix`, `/commit`) and their associated subagents are stable and work reliably.

The `examples/task.sh` automation script is an experimental integration demonstrating one possible route to full automation. This script is expected to be fragile and may require significant debugging and refinement for practical use. It is not meant as anything more than a proof of concept.

### Known Issues

Many specialized agent definition files are missing from the `.claude/agents/` directory. The slash commands currently fall back to general-purpose agents when domain-specific agents are unavailable. This works but may produce less optimal results than specialized agents would provide.
