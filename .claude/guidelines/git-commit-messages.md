# Git Commit Message Guidelines

<!-- REQUIRES: git.md must be loaded first for security context -->
<!-- This file contains ONLY commit message formatting guidelines -->

## CRITICAL: Commit Analysis Requirements

**MANDATORY: Before writing ANY commit message, you MUST:**

1. **Examine the ENTIRE diff** - Choose the appropriate command:
   - **For amending existing commits**: Use BOTH `git show HEAD` (shows what's already in the commit) AND `git diff --staged` (shows new changes being added to it)
   - **For new commits from staged changes**: Use `git diff --staged` or `git diff --cached`
   - **For reviewing after commit**: Use `git diff HEAD~1 HEAD`
   - DO NOT look at only the first 100 lines
   - DO NOT examine files individually
   - DO NOT write a message based on partial information
   - Review ALL changed files in their entirety (even if thousands of lines)

2. **Read the complete implementation** - Understand what was actually built
   - Every new type, function, and method
   - All test cases and what they validate
   - Error handling changes and edge cases
   - Performance implications of the actual code

3. **Verify accuracy** - The commit message MUST accurately reflect the code
   - Do not guess at design decisions - derive them from the code
   - Do not assume implementation details - verify them in the diff
   - Do not describe features that weren't implemented
   - Include ALL significant changes, not just the main feature

**FAILURE TO EXAMINE THE COMPLETE CHANGES IS UNACCEPTABLE.**

A commit message based on incomplete analysis is worse than no message at all. It misleads future developers and destroys trust in the version history.

## Core Philosophy

Write commit messages in the style of Linux kernel commits or technical blog posts. Each message should serve as a valuable technical document for future developers who encounter it during debugging, code archaeology, or git bisect.

## Message Structure

### First Line

- Format: `component: action-oriented description` (72 chars max)
- Use lowercase for component name
- Be specific about what changed and its purpose

The component prefix is your first and most important piece of debugging information. Make it count.

Examples:

- `source: introduce Span type for zero-copy position tracking`
- `parser: implement recursive descent for expression parsing`
- `error: add context propagation without allocations`

#### CRITICAL: Component Means Codebase Module, NOT Change Type

The `component:` prefix identifies **WHERE** in the codebase the change occurred, not WHAT TYPE of change it was. This is a deliberate design choice that makes our commit history vastly more useful for debugging and code archaeology.

**Component = The actual module/subsystem/part of your codebase:**

- `parser:` - Changes to the parser module
- `cache:` - Changes to the caching subsystem
- `auth:` - Changes to authentication code
- `database:` - Changes to database layer
- `api:` - Changes to API endpoints
- `cli:` - Changes to command-line interface

**Why location-based prefixes are superior:**

1. **Debugging**: When something breaks, you need to know WHERE to look, not what type of change it was
2. **Git bisect**: When bisecting, knowing which component introduced a bug is immediately actionable
3. **Code archaeology**: `git log --grep="^cache:"` shows all cache-related changes - invaluable when investigating performance issues
4. **Team navigation**: New developers can quickly find all commits touching the subsystem they're working on
5. **Architectural understanding**: The commit history reveals how each component evolved over time

**Explicitly rejected: Conventional Commits style.**

We do NOT use type-based prefixes like `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`, etc. These tell you nothing about WHERE in the codebase to look when debugging. Knowing something is a "fix" doesn't help you when production is down and you need to find which subsystem is responsible.

**Bad examples (DO NOT USE):**

- `feat: add user authentication` - Where in the codebase?
- `fix: resolve memory leak` - Which component is leaking?
- `refactor: improve performance` - Performance of what subsystem?

**Good examples (USE THESE):**

- `auth: add JWT-based user authentication`
- `cache: fix memory leak in LRU eviction`
- `parser: optimize recursive descent performance`

### Message Body Structure

```text
component: concise description of the change and its purpose

Opening paragraph explaining the problem this solves or the capability it adds. Focus on the user-visible impact or the architectural need that motivated this change.

Technical description of the solution, explaining the key design decisions and trade-offs. This should help future developers understand not just what was done, but why this approach was chosen.

Key design decisions:

1. First major design decision: Explanation of the choice and its benefits. Include specific technical reasons.

2. Second major design decision: Similar explanation with rationale.

3. Additional decisions as needed, each with clear justification.

Code examples showing usage (when relevant):

    // Example of how the new feature/API is used
    let example = NewType::create();
    example.process(data);

Performance/memory implications if relevant. Explain any benchmarks or measurements that influenced the design.

Future implications or follow-up work that will build on this change. This helps readers understand how this fits into the larger picture.
```

## Detailed Analysis Requirements

After examining the COMPLETE commit (see CRITICAL section above), consider the following aspects **only when they are relevant to understanding the change**. For the most trivial changes, most or all of these may not apply:

1. **Architectural Impact**
   - How does this change fit into the overall system architecture?
   - What components are affected?
   - Are there any new patterns or abstractions introduced?
   - **Derive from actual code structure, not assumptions**

2. **Design Decisions**
   - What alternatives were considered? (infer from the chosen approach)
   - Why was this approach chosen? (deduce from implementation patterns)
   - What trade-offs were made? (visible in the code choices)
   - **Extract from the actual implementation, not from speculation**

3. **Performance Characteristics**
   - Time complexity (O(1), O(n), etc.) - analyze actual algorithms
   - Space complexity and memory usage - check data structures used
   - Any benchmarks or measurements - look for test cases
   - **Calculate from real code, not theoretical possibilities**

4. **Error Handling**
   - How are errors handled? (examine Result/Option usage, panic sites)
   - What invariants are maintained? (check assertions, validations)
   - Recovery strategies (look at error return paths)
   - **Document what the code actually does, not what it should do**

5. **API Contracts**
   - What guarantees does the code provide? (check documentation, tests)
   - Pre/post conditions (examine validation code)
   - Thread safety considerations (look for sync primitives)
   - **Describe the implemented API, not the ideal API**

## Writing Guidelines

### DO

- **READ THE ENTIRE COMMIT FIRST**

Apply these guidelines when they are relevant to understanding the change. Not all items apply to every commit:

- Explain both WHAT changed and WHY
- Document design decisions with technical rationale FROM THE CODE
- Include code examples DIRECTLY FROM THE DIFF when illustrative
- Describe performance implications based on ACTUAL IMPLEMENTATION
- Connect changes to broader system architecture
- Write as if explaining to a future developer debugging this code
- Use present tense, focusing on the change's purpose
- Provide enough context for someone unfamiliar with recent work
- Document bug fixes found along the way (e.g., unwrap() replacements)
- Reference issue numbers when fixing bugs: "Fixes #123" or "Closes #456"
- Cross-reference related issues or PRs: "Related to #789" or "See PR #234"

### DON'T

These are prohibited in all commit messages regardless of change complexity:

- Write a message without reading the complete diff
- Reference development steps ("Step 1", "Step 2", etc.)
- Use temporal language ("now", "previously", "will be")
- Reference TODO.md or other planning documents
- Include automated signatures, emoji, or tool advertisements (e.g., "Generated with Claude Code")
- Be vague ("fix bug", "update code", "improve performance")
- Assume the reader has context from recent commits
- Make up design rationales - extract them from the code
- Skip "minor" changes - every change matters

**IMPORTANT: No Advertisements in Commit Messages.**

Commit messages must NEVER include tool advertisements, automated signatures, or promotional content. This includes phrases like "Generated with [tool name]", "Created by [AI assistant]", or any form of attribution to development tools. The commit message should focus solely on documenting the change itself, not the tools used to create it.

## Message Examples by Complexity

### Trivial Change - Documentation Fix

Context: Removing an unsubstantiated percentage claim from documentation. The diff shows exactly what was removed. The only question a reader might have is "why remove it?" so the message briefly answers that.

```text
agents: remove unverified token savings claim from formatting tip

The "~30%" percentage was not based on measurement and could mislead users about actual savings.
```

### Simple Change - Bug Fix

Context: Fixing a timeout bug. Someone debugging session issues needs to know what was broken and how the fix works. The message explains the old behavior (timer never reset), the user impact (spurious logouts), and the new behavior (timer resets on activity).

```text
auth: fix session timeout not resetting on user activity

The session timer was only set on login and never reset, causing active users to be logged out after 30 minutes regardless of activity. Instead update the expiration timestamp on each authenticated request to keep active sessions alive.
```

### Medium Change - Refactoring

Context: Moving code between files without changing functionality. Future readers need to understand why this reorganization happened, what changed, and that it's safe (no behavior changes). The message addresses the motivation (navigation/organization), confirms it's a pure refactor, and reassures about API compatibility.

```text
parser: extract expression parsing into separate module

Move expression parsing logic from parser.rs into new expr.rs module to improve code organization. The 400-line expression parser was dominating parser.rs, making navigation difficult and obscuring the main parsing flow.

This is a pure code reorganization with no functional changes. The public API remains identical - parse_expression() is now re-exported from the new module. All existing tests pass without modification.
```

### Complex Change - New Feature

Context: Adding foundational infrastructure that other code will depend on. Future developers need to understand the design decisions (why byte offsets? why half-open intervals?), how it fits into the larger system, and what operations it provides. Code examples help show intended usage patterns.

```text
source: introduce Span type for zero-copy position tracking in parser

Add a lightweight Span type that tracks byte positions within source text without copying the underlying data. This forms the foundation for accurate error reporting and source mapping throughout the parser pipeline.

The Span struct represents a contiguous range of bytes using start and end offsets, providing O(1) position tracking without string allocations. This design choice allows the parser to maintain precise source locations for every AST node while keeping memory overhead minimal - critical for processing large workflow files.

Key design decisions:

1. Byte offsets instead of line/column: Avoids expensive newline scanning during parsing. Line/column conversion happens only when formatting errors for display.

2. Half-open intervals [start, end): Matches Rust's standard range semantics and simplifies empty span handling (start == end).

3. Separate creation methods for different use cases:
   - new(): Direct construction with validation
   - point(): Zero-width spans for insertion points
   - empty(): Canonical empty span at position 0

The implementation provides core operations needed by the parser:

    // Track token position
    let span = Span::new(10, 15);

    // Combine spans when building AST nodes
    let combined = identifier_span.union(&args_span);

    // Check containment for error recovery
    if parent_span.contains(&error_span) {
        // Localized error handling
    }

Display formatting shows the familiar start..end syntax matching Rust's range notation, while Debug output provides the internal representation for parser debugging.

This commit only introduces the Span type itself. Integration with the lexer and parser will follow, allowing every token and AST node to carry precise source location information for error reporting.
```

## Bad Examples and Anti-Patterns

Each example below demonstrates common mistakes that make commit messages unhelpful for future developers. These are based on real scenarios that cause confusion during debugging, code archaeology, and maintenance.

### 1. Too Vague - No Actionable Information

**Scenario**: A developer fixed a critical bug in the authentication system where tokens were expiring 1 hour early due to timezone miscalculation. The fix involved updating the JWT validation logic to properly handle UTC conversions.

**Actual changes made**: Modified 3 files, added timezone conversion, updated tests, fixed edge cases for daylight saving time transitions.

```text
Fixed the bug
```

**Why this is problematic**:

- Provides zero context about what was broken
- Doesn't indicate which component was affected
- Future developers won't know if this is the auth bug they're investigating
- Impossible to determine the scope or risk of reverting
- No indication of what testing was done or what edge cases were considered

**Better approach would**: Specify the component (auth), the issue (JWT timezone bug), and the impact (tokens expiring early). Include enough detail that someone experiencing similar symptoms can find this fix.

### 2. References Development Steps Instead of Changes

**Scenario**: The developer is implementing a source tracking system as part of a larger parser project. They've just completed adding the Span type, SourceManager, and FileId abstractions with comprehensive tests.

**Actual changes made**: Created 5 new modules with ~800 lines of code implementing a complete source tracking system with position mapping, multi-file support, and error context extraction.

```text
Step 4: Implement source tracking
```

**Why this is problematic**:

- References an external planning document that may not exist in 6 months
- "Step 4" is meaningless without the other steps
- Doesn't describe what source tracking actually does or why it's needed
- Future developers have no idea what problems this solves
- Treats the commit history like a task list instead of technical documentation

**Better approach would**: Describe the actual capability added (zero-copy source position tracking), its purpose (accurate error reporting), and key design decisions made in the implementation.

### 3. Temporal Language That Ages Poorly

**Scenario**: After months of user complaints, the error display system was overhauled to show context lines, syntax highlighting, and helpful suggestions. The changes touch the error formatter, diagnostic renderer, and terminal output modules.

**Actual changes made**: Complete rewrite of error formatting, added ANSI color support, implemented context extraction, created suggestion engine, ~1200 lines changed across 8 files.

```text
Now errors display correctly
```

**Why this is problematic**:

- "Now" is meaningless when reading this commit in 2 years
- "Correctly" is subjective - what was incorrect before?
- Doesn't explain what changed in the display
- No indication of the scope of changes
- Future readers won't understand what problem this solved

**Better approach would**: Describe the specific improvements (context lines, syntax highlighting, suggestions) and what user problem they address (unclear error messages).

### 4. No Context or Rationale

**Scenario**: Adding a critical Span type that will be used throughout the parser for tracking source positions. This is a foundational piece that enables accurate error reporting, source maps, and IDE integrations.

**Actual changes made**: Implemented Span with byte-offset tracking, union/intersection operations, display formatting, comprehensive tests, and documentation.

```text
feat: Add source span type
```

**Why this is problematic**:

- Doesn't explain why spans are needed
- No indication of design decisions (why byte offsets vs line/column?)
- Doesn't connect to the larger system architecture
- Future developers won't understand the role this plays
- Misses the opportunity to document important trade-offs

**Better approach would**: Explain that Span enables zero-copy position tracking for error reporting, document the byte-offset design decision, and describe how it fits into the parser pipeline.

### 5. Implementation Details Without Purpose

**Scenario**: Creating the Span type as the foundation for source-aware error reporting throughout the compiler pipeline. The design prioritizes memory efficiency and O(1) operations.

**Actual changes made**: Span struct with carefully chosen primitives, methods for union/intersection/containment, Display/Debug implementations, and extensive property-based tests.

```text
Added Span struct with start and end fields
```

**Why this is problematic**:

- Describes the "what" but not the "why"
- Any developer can see there are start/end fields by reading the code
- Doesn't explain the purpose or use cases
- No documentation of design decisions
- Treats the commit message like a redundant code comment

**Better approach would**: Focus on the purpose (position tracking for errors), the design philosophy (zero-copy, O(1) operations), and the architectural role (foundation for source mapping).

### 6. Written Without Reading the Full Commit

**Scenario**: A large commit adding comprehensive source tracking infrastructure including SourceManager for multi-file support, FileId for file identification, FileSpan for cross-file positions, and extensive caching optimizations.

**Actual changes made**: 1500+ lines across 6 new files, but the developer only examined the first 100 lines showing the beginning of SourceManager.

<bad-example>
source: Add SourceManager for multi-file support

Implement a SourceManager that can track multiple source files for better error reporting across module boundaries.
</bad-example>

**Why this is problematic**:

- Completely misses FileId, FileSpan, and caching implementations
- Doesn't mention the 500+ lines of tests that define behavior
- Ignores critical design decisions visible in later code
- Provides incomplete documentation for future maintainers
- Creates false impression of a simple change when it's actually complex

**Better approach would**: Use `git show HEAD` or `git diff --staged` to review ALL changes, then document every significant component added and their relationships.

### 7. Parroting Without Verification

**Scenario**: Amending an existing commit that claimed to implement feature flags, but the actual code is a completely different configuration management system using environment variables.

**Actual changes made**: Environment-based configuration with validation, type coercion, and fallback defaults - no feature flags in sight.

<bad-example>
source: Implement feature as described

Add the feature flag system as outlined in the previous commit message with support for runtime toggling and A/B testing capabilities.
</bad-example>

**Why this is problematic**:

- Blindly trusts the previous message without verification
- Describes features that don't exist in the code
- Will thoroughly confuse anyone trying to use these "feature flags"
- Demonstrates failure to analyze the actual implementation
- Perpetuates incorrect documentation

**Better approach would**: Read the actual code to understand what was really implemented, then write an accurate message describing the environment-based configuration system.

### 8. Ignoring Significant Secondary Changes

**Scenario**: While adding a FileId type, the developer also implemented SourceManager, FileSpan, fixed 3 panicking unwrap() calls, added comprehensive tests, and created builder patterns for better ergonomics.

**Actual changes made**: 800+ lines including core types, manager implementation, safety improvements, and extensive test coverage.

<bad-example>
source: Add FileId type

Introduce FileId as a unique identifier for source files in the compilation pipeline.
</bad-example>

**Why this is problematic**:

- Mentions only 1 of 5 significant components added
- Ignores critical bug fixes that prevent panics
- Doesn't document the SourceManager that actually uses FileId
- Misses the FileSpan type that enables cross-file position tracking
- Under-represents the scope and impact of the change

**Better approach would**: List all major components added, mention the safety improvements, and describe how they work together as a cohesive system.

### 9. Using Wrong Diff Command for Context

**Scenario**: Amending an existing commit that adds parser infrastructure. The developer uses `git diff` which shows unstaged changes instead of `git show HEAD` which would show the actual commit being amended.

**Actual changes made**: The commit contains parser infrastructure, but `git diff` shows unrelated formatting changes.

<bad-example>
source: Update source tracking

Improve code formatting and fix indentation issues for better readability across the source tracking module.
</bad-example>

**Why this is problematic**:

- Describes formatting changes that aren't in the commit
- Used wrong command to inspect changes
- Actual parser infrastructure goes undocumented
- Creates completely incorrect historical record
- Will confuse anyone investigating parser issues

**Better approach would**: Use `git show HEAD` when amending to see the actual commit content, AND `git diff --staged` to see what's being added to it, then describe the complete parser infrastructure changes.

### 10. Incomplete Review of Staged Changes

**Scenario**: Creating a new commit with expression parsing. Developer uses `git diff` (unstaged) instead of `git diff --staged`, missing most of the actual changes that will be committed.

**Actual changes made**: Complete expression parser with precedence climbing, operator handling, and error recovery - all staged for commit.

<bad-example>
parser: Add expression parsing

Add basic struct for expression parsing preparation.
</bad-example>

**Why this is problematic**:

- Misses the actual parser implementation that's staged
- Describes only minor preparatory changes
- Wrong command led to incomplete analysis
- Future developers won't find this when searching for expression parsing
- Severely under-documents a complex feature

**Better approach would**: Use `git diff --staged` or `git diff --cached` to review what will actually be committed, then document the complete expression parsing implementation.

## Special Considerations

### For Refactoring Commits

Focus on:

- What motivated the refactoring
- How the new structure improves maintainability
- Performance impact (if any)
- Migration path for dependent code

### For Bug Fix Commits

Include:

- What was broken and how users experienced it
- Root cause analysis
- Why the bug occurred (missing validation, race condition, etc.)
- How the fix prevents recurrence

### For Performance Commits

Document:

- Baseline measurements
- Optimization technique used
- New measurements and improvement percentage
- Any trade-offs (memory vs speed, complexity vs performance)

### For New Features

Explain:

- User need or use case
- Design philosophy
- Integration with existing features
- Example usage scenarios

### For Merge Commits

Document:

- **Conflict resolution decisions**: Explain how conflicting changes were reconciled
  - Which approach was chosen when both branches modified the same code
  - Why one implementation was preferred over another
  - Any hybrid solutions that combine aspects from both branches
- **Semantic conflicts**: Document when code merges cleanly but logic conflicts
  - Functions that now have overlapping responsibilities
  - Data structures that need reconciliation despite no textual conflicts
  - API changes that affect the merged code's assumptions
- **Breaking changes introduced**: List any compatibility impacts from the merge
  - APIs that changed signature or behavior
  - Configuration changes required
  - Migration steps for downstream code
- **Review commands before merging**:
  - Use `git log --merge` to review all commits being merged from both branches
  - Use `git show --first-parent <merge-commit>` after merging to view the actual changes introduced
  - Include output from `git diff <base>...<branch>` to understand the full scope

Example merge commit message:

```text
merge: integrate feature-auth with performance optimizations from main

Merge the new authentication system with recent performance improvements to the request pipeline. This merge required careful reconciliation of the middleware chain to preserve both security and speed benefits.

Conflict resolutions:

1. middleware/auth.rs: Chose feature-auth's token validation approach but retained main's caching strategy for validated tokens. This combination provides both the new OAuth2 support and the performance gains from caching.

2. middleware/pipeline.rs: Restructured the middleware ordering to run authentication before rate limiting (from feature-auth) while keeping the new async pipeline from main. This ensures auth failures don't consume rate limit quota.

Semantic conflicts addressed:

- The new RateLimiter in main assumed all requests had user context, but feature-auth allows anonymous requests. Added conditional rate limiting based on authentication state.

- Both branches added different metrics collectors. Merged into a unified MetricsCollector that captures both auth events and performance timings.

Breaking changes:
- Middleware::new() now requires an AuthConfig parameter
- Anonymous requests now have different rate limits (see config changes)
- The /health endpoint moved outside the auth middleware

The merged authentication system provides stronger security guarantees while maintaining backward compatibility for authenticated requests. The breaking changes are limited to initialization code and anonymous request handling, which should minimize migration effort for most consumers. Teams using the middleware will need to update their initialization code to provide auth configuration, but the actual request handling interface remains unchanged.
```

### For Revert Commits

Follow git's standard revert format:

- First line: `Revert "Original commit's first line"`
- Second line: Empty (blank line)
- Third line: `This reverts commit <full-40-character-sha>.`
- Fourth line: Empty (blank line)
- Then add detailed explanation

Document:

- **Use standard git revert format**: Follow the conventional structure
  - First line must be: `Revert "exact text of original commit's first line"`
  - Include the standard line: `This reverts commit <full-sha>.`
  - After the standard header, add your detailed explanation
- **Reason for reversion**: Explain what broke and how it manifested
  - Specific symptoms users or systems experienced
  - Test failures, performance regressions, or production incidents
  - Why the issue wasn't caught before merge
- **Manual adjustments during revert**: Document any conflicts or additional changes
  - Files that required manual conflict resolution
  - Additional fixes needed to restore working state
  - Any code that couldn't be cleanly reverted and why
- **Impact on dependent features**: List what functionality is affected
  - Features that depended on the reverted code
  - APIs or interfaces that are changing back
  - Any temporary workarounds now required
- **Path forward**: Describe the plan for properly implementing the feature
  - Will it be re-implemented with a different approach?
  - What additional testing or validation is needed?
  - Timeline or conditions for reintroduction

Example revert commit message:

<good-example>
Revert "pipeline: implement async request processing with connection pooling"

This reverts commit 3a4f5b6c8d9e2f1a5b7c4d8e9f2a3b4c5d6e7f8a.

This optimization introduced a subtle memory leak that accumulates under high load, causing OOM crashes in production after ~6 hours of operation.

The reverted commit introduced connection pooling with async request processing to improve throughput. However, the implementation fails to properly clean up connection contexts when requests are cancelled mid-flight. The leak occurs because:

1. Cancelled requests leave dangling references in the pool's tracking map due to missing cleanup in the cancellation handler
2. The async cleanup task races with new connection acquisition, occasionally orphaning connection objects
3. Error paths in process_async() don't trigger connection return

Manual adjustments made during revert:

- src/pipeline/mod.rs: Manually resolved conflicts with the recent error handling refactor (commit 8b9c1d2e). Kept the new error types but removed async-specific error variants.

- tests/integration/pipeline_test.rs: Removed the async performance benchmarks entirely as they depend on the removed infrastructure. The synchronous benchmarks remain and pass.

Impact on dependent features:

- WebSocket support reverts to synchronous mode, reducing concurrent connection capacity from 10K to ~1K
- The new batch API endpoints lose parallel processing, increasing latency from ~50ms to ~200ms for large batches
- Monitoring dashboards will show throughput regression of ~40%

The async pipeline will be re-implemented after addressing the fundamental lifecycle issues. The new approach will:

1. Use RAII guards for connection lifecycle management
2. Implement proper cancellation tokens that ensure cleanup
3. Add memory leak detection tests to the CI pipeline

Expected timeline for reintroduction: 2-3 weeks after proper design review and stress testing. In the meantime, users requiring high throughput should use the load balancer configuration documented in docs/scaling.md as a workaround.
</good-example>

### For Partial Reverts

In exceptional cases, you may need to revert only specific parts of a commit while keeping other changes intact. This is more complex than a full revert and requires careful documentation.

**When partial reverts are necessary:**

- One component of a multi-part commit caused issues while others work correctly
- A commit mixed unrelated changes and only some need reverting
- Performance optimizations that broke edge cases but core functionality is sound
- Security fixes that need selective rollback due to compatibility issues

**Important considerations:**

- You cannot use the standard `Revert "..."` format since this isn't a full revert
- The process is manual - no automatic `git revert` command applies
- Future developers must understand exactly what was kept vs. reverted

**Format the commit message as:**

```text
component: revert [specific aspect] from [original commit reference]

Brief statement of what specific part is being reverted and why only that portion needs reverting while the rest remains valuable.

Original commit <sha> introduced [list main changes]. This partially reverts [specific component/file/function] because [specific issue] while preserving [what remains].

Changes reverted:
- Specific file/function/component and why
- Another specific part and rationale

Changes preserved:
- Part that remains and why it's still valuable
- Other preserved components

[Technical explanation of how the partial revert was accomplished and any manual adjustments required]
```

**Example partial revert:**

<good-example>
cache: revert LRU eviction optimization from connection pooling changes

Selectively revert the aggressive LRU eviction strategy introduced in commit 3a4f5b6c while keeping the async connection pooling that significantly improves throughput.

Original commit 3a4f5b6c added both async request processing with connection pooling AND an optimized LRU cache eviction algorithm. The eviction optimization causes cache thrashing under high load, but the connection pooling works excellently.

Changes reverted:

- cache/lru.rs: Restored conservative eviction (evict at 90% capacity instead of 75%) to prevent thrashing
- cache/metrics.rs: Removed aggressive preemptive eviction metrics

Changes preserved:

- All async connection pooling in pipeline/pool.rs
- WebSocket upgrade handling improvements
- Connection health checking mechanisms

The partial revert required manually extracting the LRU changes from the original diff and applying inverse patches while ensuring the connection pool's cache integration points remained functional. Cache performance returns to baseline but connection throughput improvements (~40%) are retained.
</good-example>

### For Cherry-Pick Commits

**DEFAULT BEHAVIOR** - Preserve the original commit message unchanged

Most cherry-picks should keep the original commit message exactly as it was:

```bash
git cherry-pick <commit-sha>
```

**EXCEPTIONAL CASES** - When to modify the commit message

Only modify the original message in these specific circumstances:

1. **Conflicts that change behavior**: When conflict resolution alters the original functionality
2. **Partial cherry-pick**: When only selecting some changes from the original commit
3. **Target branch incompatibility**: When the change's purpose or context differs significantly in the target branch
4. **Missing critical context**: When the original message lacks information essential for understanding the change in the new branch
5. **Dependencies not included**: When related commits were NOT cherry-picked and this affects understanding

**What to document when modification IS necessary:**

- Why this specific commit was cherry-picked (urgent fix, feature backport, etc.)
- Which branch it came from if not obvious
- Detailed explanation of conflict resolution changes
- Semantic adjustments for the target branch's codebase
- Functionality intentionally excluded or modified
- Dependencies or related commits that were NOT cherry-picked

**Example of an EXCEPTIONAL CASE requiring message modification:**

<good-example>
auth: fix JWT validation bypass in expired token check

Validates token expiration before checking signature to prevent timing attacks that could extend token lifetime. The validation order was allowing attackers to use expired tokens during the signature verification window.

This security fix is critical for all 2.x deployments still using the legacy auth middleware. Backported to 2.x branch for immediate production deployment.

Modifications during cherry-pick:

- Adapted to use older jwt-simple library (v0.5) instead of jwt-compact (v0.7)
- Removed telemetry calls not available in 2.x branch
- Adjusted error types to match 2.x error handling patterns

Note: The refactored auth module from commits b5c6d7e8 and c6d7e8f9 was NOT cherry-picked as it would break API compatibility in the 2.x release line.
</good-example>

**Remember:** The above example shows an exceptional case. Most cherry-picks retain the original commit message unchanged.

### For Fixup and Squash Commits

These are temporary commits used during local development that will be combined with earlier commits during interactive rebase. **Never push these to shared branches.**

**Format:**

```text
f 'original commit's first line exactly'

Detailed message describing this specific fix/change
```

**Key points:**

- Use `f` as the prefix for both fixup and squash operations
- The original commit's first line must be in single quotes
- Always include a blank line after the first line
- Always write a detailed message explaining what this specific change does
- During `git rebase -i`, the rebasing agent will decide how to update the original commit message
- Clean up with `git rebase -i` before merging to main
- These commits indicate work-in-progress and should never appear in main branch history

**Example:**

```text
f 'parser: implement recursive descent for expression parsing'

Fixed operator precedence handling for comparison operators. The original implementation incorrectly gave == and != higher precedence than < and >, which violated language specifications.

Also added test cases for complex nested comparisons to prevent regression.
```

### For Vendor or Generated Code

Vendor updates and code generated from deterministic sources (e.g., protobuf compilers, lex/yacc parsers, OpenAPI generators, database schema generators, GraphQL code generators) often produce large diffs with minimal semantic change. Focus your message on the motivation and impact rather than listing changed files.

**Important distinction**: This section applies only to deterministic, tool-generated code (automatic stub generation, parser generators, etc.). AI-authored code is considered equivalent to human-authored code and must be documented with the same level of detail as any other implementation, following all standard guidelines in this document.

**Document the "why", not the "what":**

- **Purpose of the update**: Security fixes, new features needed, compatibility requirements
- **Version changes**: From version X to Y (be specific)
- **Breaking changes or risks**: API changes, deprecated features, migration requirements
- **Trigger for the update**: What necessitated this change now
- **Testing performed**: How you validated the update works correctly

**When to summarize vs detail:**

- **Summarize**: Routine dependency bumps, regenerated code from unchanged specs
- **Detail**: Updates that change APIs, fix critical bugs, or alter behavior
- **Never**: List every changed vendor file - the diff shows this

**Example vendor update commit:**

<good-example>
deps: update bundled tokio from 1.32.0 to 1.35.1 for task cancellation safety

Upgrade tokio to resolve task cancellation edge cases that could cause resource leaks in our connection pool implementation. The newer version includes critical fixes for async drop handling that we rely on for proper cleanup.

This update was triggered by intermittent test failures in the stress test suite where connections weren't being returned to the pool after abrupt task cancellation. The issue manifested as connection exhaustion after ~1000 rapid connect/cancel cycles.

Key changes affecting our codebase:

- tokio::select! now properly propagates cancellation to all branches
- JoinHandle::abort() guarantees resource cleanup before returning
- Runtime shutdown waits for all spawned tasks to complete cleanup

Validated with:

- Full test suite passes including previously flaky stress tests
- Connection leak detector shows zero leaks over 10K cycles
- Production canary deployment showed no regressions

The update includes minor performance improvements (~5% faster spawning) but no breaking API changes. All existing tokio usage remains compatible.
</good-example>

### For Breaking Changes

Breaking changes require special attention as they impact existing users and dependent systems. These changes must be clearly marked and thoroughly documented to ensure smooth migration.

**Format:**

- Include "BREAKING CHANGE:" in the commit body (not the first line)
- Document what breaks, why it was necessary, and how to migrate
- Provide clear before/after examples when API or interfaces change
- List all affected components and the scope of impact

**Structure for breaking change documentation:**

```text
component: description of change

[Regular commit message explaining the change and rationale]

BREAKING CHANGE: Clear statement of what breaks

The old behavior/API that users might depend on is changing. This section must explain:

1. What specifically is breaking:
   - API signatures that changed
   - Configuration formats that are incompatible
   - Behavioral changes that affect existing code
   - Removed features or deprecated functionality

2. Why this breaking change is necessary:
   - Technical debt that couldn't be addressed otherwise
   - Security vulnerabilities that required API redesign
   - Performance bottlenecks that needed architectural changes
   - Consistency with broader system architecture

3. Migration path:
   - Step-by-step instructions for updating code
   - Tools or scripts available to help migration
   - Temporary compatibility flags if available
   - Timeline for removing deprecated features

Before (old API):
    client.connect(host, port, { timeout: 5000 })
    client.on('data', (data) => process(data))

After (new API):
    const connection = await client.connect({
        host: host,
        port: port,
        timeoutMs: 5000
    })
    connection.subscribe((data) => process(data))

The new API provides better error handling and async/await support but requires updating all client initialization code.
```

**Example breaking change commit:**

<good-example>
auth: replace session-based authentication with JWT tokens

Migrate the authentication system from server-side sessions to stateless JWT tokens to improve scalability and enable horizontal scaling without sticky sessions.

The new JWT-based system eliminates the need for centralized session storage, reducing database load and improving response times. Each token is self-contained with user claims and expiration, validated using RSA signatures.

Key architectural changes:

1. Token generation: Auth server issues signed JWTs containing user ID, roles, and expiration timestamp. Tokens are signed with RS256 using the server's private key.

2. Validation: Each service validates tokens independently using the public key, eliminating auth server round-trips for every request.

3. Refresh mechanism: Short-lived access tokens (15 min) paired with longer refresh tokens (7 days) balance security and user experience.

Security improvements:

- No session fixation vulnerabilities
- Automatic expiration without server-side cleanup
- Cryptographic integrity verification
- Support for token revocation via blacklist

BREAKING CHANGE: Session-based authentication is removed entirely

All API clients must update to use JWT token authentication. The changes affect both the authentication flow and request authorization:

1. Authentication endpoint changes:
   - Old: POST /api/login returns session cookie
   - New: POST /api/auth/token returns JWT in response body

2. Request authorization changes:
   - Old: Include session cookie with requests
   - New: Include JWT in Authorization header: "Bearer <token>"

3. Session management removed:
   - /api/logout endpoint removed (clients discard token)
   - Session timeout configuration no longer applies
   - Server-side session storage APIs deprecated

Migration steps:

1. Update login flow:
   Before:
     const response = await fetch('/api/login', {
       method: 'POST',
       credentials: 'include',  // Send cookies
       body: JSON.stringify({ username, password })
     })

   After:
     const response = await fetch('/api/auth/token', {
       method: 'POST',
       body: JSON.stringify({ username, password })
     })
     const { accessToken, refreshToken } = await response.json()
     // Store tokens securely (not in localStorage for sensitive apps)

2. Update authenticated requests:
   Before:
     fetch('/api/data', { credentials: 'include' })

   After:
     fetch('/api/data', {
       headers: { 'Authorization': `Bearer ${accessToken}` }
     })

3. Implement token refresh (new requirement):
   // When access token expires (401 response)
   const newTokens = await fetch('/api/auth/refresh', {
     method: 'POST',
     body: JSON.stringify({ refreshToken })
   })

4. Remove session-related code:
   - Delete session timeout handlers
   - Remove cookie parsing/management
   - Update error handling for 401 responses

Compatibility notes:

- Old session cookies are ignored (not validated)
- Transition period: Both auth methods work until <date>
- Session data migration tool available at tools/migrate-sessions

Teams should plan migration by <date> when session support ends.
Contact auth-team@ for migration assistance or special requirements.
</good-example>

## Total Message Length

Write what's needed to understand the commit. For the most trivial changes, the subject line may be sufficient. Usually a body will be present to explain WHY the change was made, to summarize the changes for larger commits, or to provide context that isn't obvious from reading the diff.

Remember: A commit message that seems too long today will be invaluable context for someone debugging an issue six months from now.

## Line Wrapping

Wrap commit message lines at 72 characters to ensure proper display in git tools and terminal interfaces. This includes both the subject line and body text.

**Exceptions to the 72-character limit:**

- URLs cannot be broken across lines
- Code blocks and command examples where breaking would affect readability
- File paths that are inherently long
- Technical identifiers like commit SHAs, function signatures, or error messages
- Configuration keys or structured data that must remain intact

When wrapping is not possible, prefer readability over strict adherence to the character limit. The goal is clear communication, not rigid formatting compliance.

**Manual verification commands:**

To verify line lengths in your commit message:

```bash
# Find all lines exceeding 72 characters
awk 'length($0) > 72 {print NR": "length($0)" chars - "$0}' .git/COMMIT_EDITMSG

# Display maximum line length
awk '{len=length($0); if(len>max) max=len} END {print "Maximum line length: "max" chars"}' .git/COMMIT_EDITMSG
```

If the first command produces no output, all lines are within the limit.

## List Formatting

When including lists in commit messages, follow consistent indentation rules to ensure readability in all git tools:

### Numbered Lists

Continuation lines must align with the first character of list item text using 3-space indentation for numbers 1-9:

```text
Changes appear in three locations:

1. file1.rs: Added new function for user authentication with support
   for both OAuth and traditional login methods, including proper
   error handling and token validation.

2. file2.rs: Updated existing user session management to integrate
   with the new authentication system, maintaining backward
   compatibility with existing session tokens.
```

For numbers 10-99, use 4-space indentation.

### Bullet Point Lists

Continuation lines must align with the first character after the dash using 2-space indentation:

```text
Key improvements include:

- Enhanced security: JWT tokens provide stateless authentication
  without server-side session storage, reducing attack surface
  and improving scalability for distributed deployments.

- Better error handling: Comprehensive error types distinguish
  between network failures, credential validation, and token
  expiration to enable appropriate user experience responses.
```

### Nested Lists

For nested lists, maintain proper alignment at each level:

```text
Authentication changes:

1. Token generation:
   - Create signed JWT with user claims
   - Include expiration timestamp (15 minutes)
   - Use RS256 algorithm with server private key

2. Validation process:
   - Verify signature using server public key
   - Check expiration timestamp against current time
   - Extract user ID and permissions from claims
```

## Enforcement Checklist

Before submitting a commit message, verify:

### For ALL Commits

- [ ] I read EVERY line of EVERY changed file
- [ ] I understand what each new type/function/method does
- [ ] I examined all test cases to understand usage
- [ ] I identified and documented ALL design decisions from the code
- [ ] I noted any bug fixes or safety improvements
- [ ] I described actual implementation, not theoretical design
- [ ] I included code examples from the actual diff
- [ ] I documented performance characteristics from real code
- [ ] My message accurately reflects what was built, not planned
- [ ] I verified line numbers and content match between Read output and git diff
- [ ] I cross-referenced that any mentioned functions/variables exist in the actual code
- [ ] I confirmed that described behavior matches actual implementation (not assumed behavior)
- [ ] I checked that examples in commit message are copied from real code, not synthesized
- [ ] I ensured no design patterns are mentioned unless explicitly visible in code structure
- [ ] I verified that performance claims are based on actual code analysis, not assumptions

### For Standard Commits (New Changes)

- [ ] I used `git diff --staged` to view the COMPLETE set of staged changes
- [ ] I verified all staged changes are intentional
- [ ] I re-read files and re-ran git diff (not relying on memory or previous analysis)

### For Amending Commits

- [ ] I used BOTH commands to see the complete picture:
  - [ ] `git show HEAD` to review the existing commit being amended
  - [ ] `git diff --staged` to review new changes being added to it
- [ ] I updated the commit message to reflect ALL changes (original + amendments)

### For Creating Merge Commits

- [ ] I used `git log --merge` to review commits from both branches being merged
- [ ] I documented how conflicts were resolved (if any)
- [ ] I explained the integration approach and testing performed
- [ ] I verified the merge preserves intended functionality from both branches

### For Reviewing Existing Merge Commits

- [ ] I used `git show --first-parent` to see what the merge introduced to the main branch

### For Reverting Commits

- [ ] I followed the standard format: `Revert "Original commit's first line"`
- [ ] I documented why the revert was necessary
- [ ] I explained the specific issues or failures that prompted the revert
- [ ] I included plans for fixing and reintroducing the changes (if applicable)

**If you cannot check all applicable boxes, DO NOT write the commit message.**

## AI Agent-Specific Reminders

When creating commit messages, AI agents must avoid common pitfalls that stem from making assumptions or inventing details not present in the actual code or requirements.

### Critical Rules for AI Agents

**Always verify file contents before describing changes.**

DO: Read every file mentioned in the commit before writing about it
DO NOT: Assume file contents based on filenames or previous context

Example violation:
<bad-example>
"Updated database schema to include user preferences"
(Without actually reading the schema file to confirm what was added)
</bad-example>

Correct approach:
<good-example>
Added preference_theme and preference_language columns to users table

- preference_theme VARCHAR(20) with default 'light'
- preference_language VARCHAR(10) with default 'en'
</good-example>

**Never trust previous analysis without re-verification.**

DO: Re-read files and re-run git diff for every commit message
DO NOT: Rely on memory or previous analysis from earlier in the conversation

Example violation:
<bad-example>
"As discussed earlier, this implements the caching strategy..."
(Assuming previous discussion is still accurate without re-checking)
</bad-example>

Correct approach:
<good-example>
Implemented Redis caching for API responses

- Cache key format: 'api:endpoint:params_hash'
- TTL: 300 seconds (defined in config.py line 42)
</good-example>

**Avoid hallucinating design decisions not present in code.**

DO: Describe only what the code actually does
DO NOT: Invent architectural decisions or patterns you think should be there

Example violation:
<bad-example>
"Implemented repository pattern with dependency injection"
(When the code just has simple direct database calls)
</bad-example>

Correct approach:
<good-example>
Added direct database queries for user operations

New functions in user_service.py:

- get_user_by_id(): Uses direct SQL query with psycopg2
- update_user(): Executes UPDATE statement with parameter binding
</good-example>

**Be explicit about actual vs potential changes.**

DO: Clearly distinguish between what WAS changed and what MIGHT need changing
DO NOT: Mix completed work with future recommendations in the same context

Example violation:
<bad-example>
"Updated error handling across all modules"
(When only auth.py was actually modified)
</bad-example>

Correct approach:
<good-example>
Added try-catch blocks to authentication functions

Modified error handling in auth.py:

- login(): Catches DatabaseError and returns 503
- verify_token(): Catches TokenExpiredError and returns 401

Note: Similar error handling may be needed in other modules but was not implemented in this commit
</good-example>

**Never invent rationales not explicitly stated.**

DO: State only confirmed reasons for changes
DO NOT: Assume or create justifications based on what seems logical

Example violation:
<bad-example>
"Removed deprecated function to improve performance"
(When no performance issue was mentioned or measured)
</bad-example>>

Correct approach:
<good-example>
Removed unused calculate_score() function

- Function had no callers in codebase
- No deprecation notice was present
</good-example>

### Red Flags That Indicate Assumption-Making

Stop and re-verify if your commit message contains:

- "Should improve..." (without measurement)
- "Probably fixes..." (without confirming root cause)
- "Updated various files..." (without listing each one specifically)
- "Standard implementation of..." (unless pattern is explicitly documented in code)
- "As intended..." (without evidence of original intent)
- "Obviously..." or "Clearly..." (these often mask assumptions)
- References to files you have not read in this session
- Descriptions of code behavior you have not traced through

Remember: Every statement in a commit message must be traceable to specific lines of code you have actually read and verified. When in doubt, read the file again.
