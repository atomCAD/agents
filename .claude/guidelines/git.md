# Git Operations and Security Guidelines

<!-- SECURITY CRITICAL: This file MUST be loaded for ANY git operation -->
<!-- For commit message guidelines, also load: git-commit-messages.md -->

This document defines security requirements and safe practices for all git operations.
All git-related agents and workflows MUST reference these guidelines.

## Security Requirements and Input Validation

### CRITICAL: Command Injection Prevention

**MANDATORY SECURITY PROTOCOL**: All git commands MUST be executed with validated and sanitized inputs to prevent command injection attacks. This is NON-NEGOTIABLE and supersedes any efficiency or convenience considerations.

### Input Validation Requirements

Before executing ANY git command with dynamic parameters, you MUST:

#### 1. Commit Hash Validation

**Pattern**: `^[a-f0-9]{7,40}$`

- **MUST** validate ALL commit hashes, refs, and SHAs match this exact pattern
- **MUST** reject any input containing characters outside lowercase hex (a-f, 0-9)
- **MUST** verify length is between 7 and 40 characters
- **NEVER** accept branch names, tags, or symbolic refs when a hash is expected
- **NEVER** use user-supplied strings directly in git commands without validation

**Safe execution pattern**:

```bash
# VALIDATE FIRST
if [[ ! "$commit_hash" =~ ^[a-f0-9]{7,40}$ ]]; then
    echo "ERROR: Invalid commit hash format"
    exit 1
fi
# ONLY THEN execute
git show "$commit_hash"
```

#### 2. Scope Parameter Validation

**Allowed values**: EXACTLY `new` or `amend` (case-sensitive)

- **MUST** reject any scope value not in the explicit allowlist
- **MUST** use exact string matching, not pattern matching
- **NEVER** interpolate scope values into commands without validation

**Safe validation**:

```bash
if [[ "$scope" != "new" && "$scope" != "amend" ]]; then
    echo "ERROR: Invalid scope. Must be 'new' or 'amend'"
    exit 1
fi
```

#### 3. File Path Sanitization

When processing file paths from diffs or file listings:

- **MUST** reject paths containing shell metacharacters: `;|&$()<>\`!`
- **MUST** reject paths with directory traversal sequences: `../`, `./`, `//`
- **MUST** quote ALL file paths in commands: `"$filepath"`
- **NEVER** use glob expansion on user-influenced paths
- **ALWAYS** use `--` separator before file arguments to prevent option injection

**Dangerous metacharacters to reject**:

- Semicolon (`;`) - Command separator
- Pipe (`|`) - Command chaining
- Ampersand (`&`) - Background execution
- Dollar sign (`$`) - Variable/command substitution
- Parentheses (`()`) - Subshell execution
- Angle brackets (`<>`) - Redirection
- Backtick (`` ` ``) - Command substitution
- Exclamation (`!`) - History expansion

#### 4. Command Construction Safety

**MANDATORY**: Use parameterized execution, NEVER string concatenation:

**FORBIDDEN** (vulnerable to injection):

```bash
# NEVER DO THIS
git show HEAD~$n
git diff "$commit1..$commit2"
command="git show $user_input"
eval "$command"
```

**REQUIRED** (safe parameterized):

```bash
# ALWAYS DO THIS
git show HEAD~"$n"  # After validating $n is a number
git diff "$commit1" "$commit2"  # After validating both are valid hashes
# Never use eval with user input
```

### Security Validation Checklist

Before EVERY git command execution:

- [ ] **Input Source Verified**: Is this input from a trusted source (git itself) or external?
- [ ] **Pattern Validated**: Does the input match the exact expected pattern?
- [ ] **Length Checked**: Is the input within expected length bounds?
- [ ] **Metacharacters Rejected**: Are shell special characters absent?
- [ ] **Properly Quoted**: Are ALL variables quoted in the command?
- [ ] **Option Injection Protected**: Is `--` used before file arguments?
- [ ] **No String Concatenation**: Is the command built without string interpolation?
- [ ] **No Eval/Exec**: Is the command executed directly without eval or exec?

### Safe Command Templates

Use ONLY these validated command patterns:

```bash
# Viewing changes (READ-ONLY operations)
git show HEAD                          # Safe: no parameters
git show "[VALIDATED_HASH]"            # Safe: after hash validation
git diff --staged                      # Safe: no parameters
git diff --cached                      # Safe: no parameters
git diff "[VALIDATED_HASH1]" "[VALIDATED_HASH2]"  # Safe: after validation
git status                             # Safe: no parameters
git log --oneline -10                  # Safe: no parameters

# File operations (with proper escaping)
git diff -- "[QUOTED_FILEPATH]"        # Safe: quoted and separated
git show HEAD -- "[QUOTED_FILEPATH]"   # Safe: quoted and separated

# NEVER construct dynamic commands like:
# git $operation $parameters            # DANGEROUS
# git show HEAD~$n                      # DANGEROUS without validation
# git $(echo $command)                  # EXTREMELY DANGEROUS
```

### Error Handling for Security Violations

When a security validation fails:

1. **STOP IMMEDIATELY** - Do not attempt to "fix" or "clean" the input
2. **LOG THE VIOLATION** - Record what validation failed and why
3. **RETURN ERROR** - Use the error output format with security-specific message
4. **DO NOT RETRY** - Security failures should never be automatically retried
5. **DO NOT REVEAL** - Never echo back the invalid input in error messages

**Security error output format**:

```yaml
---
status: error
scope: [new or amend]
error: Security validation failed
security_violation: true
---

The requested operation cannot be performed due to security constraints. The input provided does not meet the required validation criteria for safe execution. Please ensure all parameters conform to expected formats:

- Commit hashes: 7-40 character hexadecimal strings (a-f, 0-9)
- Scope: exactly "new" or "amend"
- File paths: no special characters or traversal sequences

Contact your security team if you believe this is a false positive.
```

### Security Principles

1. **Defense in Depth**: Multiple validation layers, don't rely on a single check
2. **Fail Secure**: When in doubt, reject the input rather than risk exploitation
3. **Least Privilege**: Only request/use the minimum git permissions needed
4. **Input Validation First**: Always validate BEFORE using any external input
5. **No Trust Assumption**: Treat ALL external input as potentially malicious
6. **Explicit Allowlists**: Define what's allowed, reject everything else
7. **Avoid Complex Parsing**: Simple validation is less error-prone
8. **Regular Security Review**: These patterns should be reviewed quarterly

### Special Security Considerations

#### For Repository Names and Remote Operations

While this agent doesn't perform remote operations, if extended:

- **MUST** validate repository URLs against strict patterns
- **MUST** use `--` separator: `git clone -- "$url"`
- **NEVER** allow protocol switching (http:// vs git:// vs file://)
- **ALWAYS** validate domain names against allowlist

#### For Interactive Mode Detection

- **MUST** detect and reject interactive git operations
- **MUST** use `--no-pager` flag when appropriate
- **MUST** set `GIT_TERMINAL_PROMPT=0` to prevent credential prompts
- **NEVER** allow operations requiring user interaction

### Security Incident Response

If a potential command injection attempt is detected:

1. Return security error immediately (do not execute anything)
2. Include marker `security_violation: true` in YAML frontmatter
3. Do not include the malicious input in any output or logs
4. Preserve evidence without exposing sensitive details

### Security Testing and Validation

To validate these security measures work correctly, the following malicious inputs should be rejected:

#### Test Cases for Validation

**Commit Hash Injection Tests** (all should be rejected):

- `abc123; rm -rf /` - Command chaining attempt
- `$(cat /etc/passwd)` - Command substitution
- `HEAD~1 && echo hacked` - Logical operator injection
- `../../etc/shadow` - Path traversal attempt
- `main` - Branch name instead of hash

**Scope Parameter Injection Tests** (all should be rejected):

- `new; echo hacked` - Command injection
- `amend && rm -rf /` - Command chaining
- `$(whoami)` - Command substitution
- `NEW` - Wrong case
- `fix` - Invalid scope value

**File Path Injection Tests** (all should be rejected):

- `../../etc/passwd` - Directory traversal
- `file.txt; cat /etc/shadow` - Command chaining
- `file$(date).txt` - Command substitution
- `--version` - Option injection
- `file.txt | grep password` - Pipe injection

**Valid Inputs** (should be accepted):

- Commit hash: `a1b2c3d4e5f6` - Valid short hash
- Commit hash: `1234567890abcdef1234567890abcdef12345678` - Valid full hash
- Scope: `new` - Valid scope
- Scope: `amend` - Valid scope
- File path: `src/main.rs` - Valid path
- File path: `path/to/file.txt` - Valid nested path

## CRITICAL SAFETY WARNING - DANGEROUS GIT COMMANDS

**STOP AND READ THIS BEFORE USING ANY GIT COMMANDS:**

The following git commands can cause **PERMANENT DATA LOSS** or **UNINTENDED CHANGES**:

### NEVER USE THESE COMMANDS

- **`git reset --hard`** - DESTROYS all uncommitted work permanently
- **`git add .` or `git add -A`** - Can stage unintended files
- **`git push --force`** - Can overwrite remote history and destroy others' work
- **`git clean -fd`** - Permanently deletes untracked files without recovery
- **`git checkout .`** - Discards all local modifications without warning
- **`git rebase -i` on shared branches** - Rewrites history that others depend on

### ALWAYS USE SAFE ALTERNATIVES

- Instead of `git reset --hard`: Use `git reset --soft HEAD~1` (preserves changes)
- Instead of `git add` in ANY form: Use `git apply --cached` to stage specific changes from a generated diff
- Instead of `git push --force`: Use `git push --force-with-lease` (checks remote state first)
- Instead of blind operations: ALWAYS verify with `git status` and `git diff` first

### SAFETY PROTOCOL

1. **NO DESTRUCTIVE OPERATIONS**: Never run commands that can destroy work - period
2. **USE STAGED OPERATIONS**: Use `git apply --cached` for precise control over what gets staged
3. **CHECK YOUR DIFF**: Run `git diff` or `git diff --staged` to verify changes before committing
4. **BACKUP WHEN UNCERTAIN**: Before attempting something risky, create a backup:
   `git branch backup-auth-before-rebase`

**Remember**: Every git operation should be followed by verification. When in doubt, ask for help rather than risk data loss.

## Quick Command Reference Table

| Scenario | Command | Purpose |
|----------|---------|---------|
| **Viewing Changes Before Committing** | | |
| View staged changes for new commit | `git diff --staged` | Shows exactly what will be committed from staging area |
| View unstaged changes in working directory | `git diff` | Shows modifications not yet staged |
| View both staged and unstaged changes | `git diff HEAD` | Shows all changes compared to last commit |
| **Amending and Reviewing Commits** | | |
| View current commit when amending | `git show HEAD` | Shows the commit you're about to amend |
| View specific commit by hash | `git show <commit-hash>` | Examines any historical commit |
| View changes between commits | `git diff <commit1> <commit2>` | Compares two specific commits |
| View changes since branch diverged | `git diff main...HEAD` | Shows all changes in current branch |
| **Checking Repository Status** | | |
| Check current status and staged files | `git status` | Shows staged, unstaged, and untracked files |
| List files changed in last commit | `git diff --name-only HEAD~1 HEAD` | Quick list of modified files |
| View recent commit history | `git log --oneline -10` | Shows last 10 commits with messages |
| View detailed recent history | `git log -3 --stat` | Shows last 3 commits with file changes |
| **Creating and Modifying Commits** | | |
| Stage specific changes | `git apply --cached` | Apply a generated diff to staging, then verify with `git diff` that changes are cleanly removed from unstaged |
| Create new commit | `git commit -m "message"` | Commits staged changes with message |
| Amend last commit (keep message) | `git commit --amend --no-edit` | Adds staged changes to last commit |
| Amend last commit (change message) | `git commit --amend -m "new message"` | Updates last commit and its message |
| **Analyzing Changes for Message Writing** | | |
| Count lines changed in staged files | `git diff --staged --stat` | Shows statistics for commit size |
| View staged changes with context | `git diff --staged -U10` | Shows 10 lines of context around changes |
| List all function changes | `git diff --staged --function-context` | Shows complete functions that changed |
| **Verifying Commit Messages** | | |
| View last commit message only | `git log -1 --pretty=%B` | Shows just the message, no metadata |
| Check message before pushing | `git show --no-patch` | Shows commit info without diff |
| Search commits by message | `git log --grep="pattern"` | Finds commits matching pattern |
| **Working with Branches** | | |
| Compare branch to main | `git diff main...` | Shows changes in current branch |
| List branches with recent commits | `git branch -v` | Shows branches with their latest commits |
| View commits not in main | `git log main..HEAD` | Lists commits unique to current branch |
| **Merge Commits** | | |
| Review commits being merged | `git log --merge` | Shows all commits from both branches in a merge |
| View merge commit changes | `git show --first-parent` | Shows changes introduced by the merge |
| See conflicts during merge | `git diff --name-only --diff-filter=U` | Lists files with merge conflicts |
| View 3-way merge differences | `git diff --cc` | Shows combined diff of merge commit |
| **Emergency Recovery** | | |
| Undo last commit (keep changes) | `git reset --soft HEAD~1` | Moves changes back to staging (NEVER use --hard) |
| View reflog for recovery | `git reflog` | Shows history of HEAD changes |

**SAFETY REMINDER:** See the CRITICAL SAFETY WARNING section above for dangerous commands to avoid and safe alternatives to use.

**These rules are non-negotiable and apply to all AI agent interactions within this repository.**

*Last Updated: 2025-08-25*
*Version: 1.0*
