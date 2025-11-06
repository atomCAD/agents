# PLAN.md Format and Structure

PLAN.md documents guide incremental feature development through test-driven development (TDD). Each plan breaks down a feature into atomic tasks, where each task represents a single commit developed using the red-green-refactor cycle.

**Prerequisite**: This document assumes familiarity with atomic changes. See [atomic-changes.md](atomic-changes.md) for the foundational concepts of what makes a change atomic, change categories (Feature/Move-only/Refactor), atomicity verification tests, and the location-independence principle. This document focuses on how to represent atomic changes in PLAN.md format.

## File Location

The active PLAN.md file lives in the repository root directory. Only one active PLAN.md should exist in the root at any time. When a plan is completed, it is archived to `.attic/plans/PLAN-YYYY-MM-DD-topic.md` and committed to version control.

## Scope of This Document

This guideline specifies **how to create and maintain PLAN.md documents**. It is for PLAN.md **authors** (those creating and maintaining the document), not PLAN.md **consumers** (developers executing the plan).

### In Scope

1. **Document Structure** - What sections exist, how they're formatted
2. **Content Format** - Syntax for tasks, checklists, categories, descriptions
3. **Sub-requirement Format** - How to break down tasks into testable steps
4. **Outcome Tracking** - When and how to document multi-task outcomes
5. **TDD Integration** - How feature tasks should be structured to follow red-green-refactor
6. **Update Protocol** - How to correctly modify the document over time
7. **Document Lifecycle** - How PLAN.md files are created, used, and completed
8. **Task-Commit Alignment** - The 1:1 relationship between tasks and commits

**Note**: Foundational concepts about atomic changes, change categories, atomicity verification, and decomposition principles are covered in [atomic-changes.md](atomic-changes.md). This document focuses on PLAN.md-specific formatting and workflow.

### Out of Scope

1. **Atomic Change Fundamentals** - Covered in [atomic-changes.md](atomic-changes.md) (definitions, categories, verification tests, decomposition principles)
2. **Slash Commands/Tools** - References to `/message`, `/commit`, or other external tooling
3. **Promotional Content** - "Benefits" section explaining why PLAN.md is good
4. **Generic Development Philosophy** - Anti-patterns that aren't specifically about PLAN.md task structure
5. **Strategic Architecture Advice** - General advice about when to use patterns (unless it's about how to represent them as tasks)
6. **Content that teaches how to use an existing PLAN.md effectively, rather than how to create and maintain the PLAN.md document itself**

## Key Terminology

This document uses specific terms with precise meanings:

### Sub-requirement

A sub-requirement is a bulleted item beneath a task checkbox that specifies one discrete aspect of the task's implementation or validation. Sub-requirements break down what needs to be done within a single atomic task.

**Common types of sub-requirements:**

- Test criteria (what behavior to verify)
- Implementation details (specific code to write)
- Validation steps (how to confirm completion)
- Dependencies (prerequisite tasks or resources)

#### Example: Task with Sub-requirements

The following shows how sub-requirements break down a task's implementation:

```markdown
- [ ] Add email validation to user registration
  - Write tests for valid email formats          <- sub-requirement (test criteria)
  - Implement validation function with regex     <- sub-requirement (implementation)
```

### Atomic Task

An atomic task in PLAN.md is an [atomic change](atomic-changes.md#atomic-change) represented as a checkbox item in the Tasks section. Each task becomes exactly one git commit when implemented.

**See [atomic-changes.md](atomic-changes.md) for**: Definition, key characteristics, change categories, atomicity verification tests, and decomposition principles.

### Outcome

An outcome is a desired result that requires either multiple tasks to achieve OR explicit validation of critical requirements. Outcomes represent "what" needs to be accomplished (the end state) while tasks represent "how" to get there (the specific actions). In GTD (Getting Things Done) terminology, outcomes correspond to "projects" - meaningful capabilities that cannot be completed in a single action.

**GTD Natural Planning Model characteristics:**

- **Purpose-driven**: Outcomes define WHY we're doing the work and WHAT success looks like
- **Vision-focused**: Describe the desired end state, not the implementation path
- **Multi-step by nature**: Require multiple tasks to complete
- **Measurable completion**: Clear criteria for when the outcome is achieved
- **Observable end states**: Results that can be objectively verified
- **User-facing value**: Meaningful capabilities or deliverables
- **Success criteria orientation**: Define "done" before starting implementation

**Key characteristics:**

- Multi-step results requiring multiple tasks, OR single critical requirements needing explicit validation
- Observable end states with measurable completion
- User-facing value or capabilities
- Success criteria that define "done"

**When to use**: For complex features that span multiple atomic tasks, list explicit outcomes with their success criteria in an Outcomes section. For simple features accomplishable in 1-2 tasks, outcomes can be omitted and success criteria specified at the plan level instead (see Optional Elements). Single-task outcomes should be used sparingly - primarily for critical requirements (performance, security, compliance) that need explicit tracking and validation.

**Example**: "Users can reset forgotten passwords" (outcome requiring multiple tasks) vs. "Add password reset endpoint" (task that contributes to that outcome). Single-task example: "API responds within 500ms" (critical performance requirement with explicit validation needs).

## Document Structure

### Metadata Section

#### Example: Basic PLAN.md structure

Every PLAN.md document should start with this header structure:

```markdown
# Plan: [Feature Name]

[Brief overview of the work being planned - 1-3 sentences describing the goal]

## Outcomes

[List of desired outcomes/projects - each outcome is a result requiring multiple actions and/or explicit validation]

## Tasks
```

### Required Elements

- **Title**: Clear, concise feature name prefixed with "Plan:"
- **Overview**: Brief description of what this plan implements and why
- **Outcomes section**: List of desired outcomes/projects (GTD-style)
- **Tasks section**: Ordered list of checkbox tasks (next actions)

### Outcomes Section Format

The Outcomes section lists **desired results** (projects in GTD terminology) - things that typically require more than one action to complete, or critical requirements needing explicit validation. Each outcome represents a meaningful capability or deliverable that emerges from completing one or more tasks.

#### Outcome Characteristics

- **Multi-step results**: Each outcome typically requires multiple tasks to achieve
- **Observable end states**: Describes what "done" looks like, not how to get there
- **User-facing value**: Focus on capabilities and benefits, not implementation details
- **Measurable completion**: Clear criteria for when the outcome is achieved

#### Single-Task Outcomes

While most outcomes require multiple tasks, some critical requirements warrant explicit tracking as outcomes even if implementable in a single task. Use single-task outcomes sparingly and only when:

**Valid use cases:**

- **Performance requirements**: "API responds within 500ms" - simple to implement but critical to verify
- **Security requirements**: "All API endpoints require authentication" - may be one task but needs explicit validation
- **Compliance requirements**: "GDPR data export completes within 30 days" - hard requirement needing verification
- **Critical constraints**: "System handles 10,000 concurrent users" - requires explicit load testing validation

**When NOT to use single-task outcomes:**

- Simple features without critical validation needs - use plan-level success criteria instead
- Internal refactoring or code organization - doesn't need outcome-level tracking
- Routine bug fixes - track as tasks unless they address critical security/performance issues
- Tasks that are already part of a larger outcome - avoid redundant tracking

**Guideline**: If a single-task item is important enough that its validation deserves explicit documentation separate from the task itself, it can be an outcome. Otherwise, keep it as a task.

#### Outcome Format

Outcomes can use either checkboxes or standard bullet points, with sub-requirements for success criteria, principles, and constraints. Checkboxes are useful for tracking when an outcome has been fully achieved and verified:

```markdown
## Outcomes

- [ ] Users can securely authenticate with the system
  - Success criteria:
    - Login works
    - Sessions persist
    - Logout clears session
  - Security principle: Use OAuth 2.0 for authentication
  - Constraint: Support SSO integration with existing providers

- [ ] Shopping cart persists across sessions
  - Success criteria:
    - Cart survives browser refresh
    - Cart survives logout/login cycle
  - Constraint: Must persist for minimum 30 days
  - Performance: Cart operations complete < 500ms

- [ ] Search results are filtered and ranked by relevance
  - Success criteria:
    - Filters apply correctly
    - Ranking algorithm works
  - Performance: Results return in < 2 seconds
  - Principle: Use existing search infrastructure
```

#### Relationship to Tasks

Each outcome will typically have multiple tasks associated with it. Tasks are the concrete next actions that move toward achieving the outcomes:

```markdown
## Outcomes

- [ ] Users can reset forgotten passwords
  - Success criteria:
    - Reset link sent
    - Token expires
    - Password updates
  - Security constraint: Token valid for 24 hours only
  - Principle: One-time use tokens, no token reuse

## Tasks

- [ ] Add password reset request endpoint
- [ ] Implement secure token generation
- [ ] Create password reset email template
- [ ] Add password update endpoint with token validation
- [ ] Implement token expiration (24 hours)
```

#### Validating Outcomes

Apply these questions to verify outcome quality according to GTD Natural Planning Model principles:

1. **Outcome test**: Does this require 2+ tasks OR explicit validation of a critical requirement?
   - If no: This is a single task, not an outcome
   - If single-task: Is this a critical requirement (performance, security, compliance) that warrants explicit tracking?

2. **End-state test**: Does this describe WHAT (result), not HOW (implementation)?
   - If describing implementation: Refocus on the desired end state and user value
   - Should answer: "What would success look like?"

3. **Measurability test**: Can completion be objectively determined?
   - If no: Add or clarify specific, objective success criteria
   - Can someone else verify completion based on the criteria?

4. **Value test**: Does this represent meaningful capability or deliverable?
   - If purely internal/technical: Consider whether it needs to be an explicit outcome
   - Focus on user-facing value and business capability

5. **Scope test**: Is this focused enough to guide planning?
   - Too broad: "Build the entire authentication system" or "Implement all user features" - spans multiple distinct capabilities
   - Right scope: "Users can reset forgotten passwords" - requires multiple tasks but focuses on one specific capability

**GTD validation criteria:**

- **Clear outcome statement**: Describes the desired end state, not the path to get there
- **Specific success criteria**: Objective, measurable indicators of completion
- **Appropriate scope**: Meaningful outcome requiring multiple tasks, not single task
- **Value-focused**: Emphasizes capability delivered, not technical implementation details

**Common mistakes:**

- Outcome is too granular (completable as single task without critical validation needs)
- Outcome describes approach/implementation rather than desired result
- Success criteria are subjective, vague, or unmeasurable
- Outcome scope spans entire plan (needs splitting into focused outcomes)
- Missing WHY context - unclear purpose or value proposition

### Optional Elements

- **Dependencies**: External libraries, APIs, or prerequisite features
- **Success Criteria**: How to verify the feature is complete (use this for simple plans; for complex multi-task features, specify success criteria within the Outcomes section instead)
- **Technical Notes**: Architecture decisions, design patterns, or constraints

### Task List Format

Tasks use markdown checkbox syntax:

- `[ ]` - Pending task (not yet started or in progress)
- `[x]` - Completed task (implemented, tested, and committed to git)

#### Task Ordering

1. Tasks are ordered by dependency (prerequisite tasks come first)
2. Each task builds incrementally on previous tasks
3. Each task must accomplish something meaningful on its own - avoid purely preparatory work that only adds
   dependencies or infrastructure for future tasks
4. Each task adds exactly one feature/capability

#### Documenting Task Dependencies

When tasks have explicit dependencies, document them as sub-requirements (see "Sub-requirement" in Key Terminology). Use explicit "Depends on:" notation when the dependency is not immediately obvious from task content or ordering, or when the dependency provides important implementation context:

##### Example: Task with explicit dependency

```markdown
- [ ] Implement user profile caching
  - Depends on: Task "Create cache infrastructure"
  - Implement Redis-backed cache for user profile data
  - Test: Cache hit/miss metrics
```

#### Task Description Format

**Feature task format** (no category prefix):

```markdown
- [ ] [Action verb] [what] [optional: where/how]
  - [Sub-requirement 1: test criteria]
  - [Sub-requirement 2: implementation detail]
```

**Move-only task format**:

```markdown
- [ ] Move-only: [Action verb] [what] [optional: where/how]
  - [Sub-requirement: description of code being moved]
  - [Sub-requirement: verification steps]
```

**Refactor task format**:

```markdown
- [ ] Refactor: [Action verb] [what] [optional: where/how]
  - [Sub-requirement: refactoring steps]
  - [Sub-requirement: verification steps]
```

## Task Decomposition Principles

**See [atomic-changes.md](atomic-changes.md) for**: Change categories (Feature, Move-only, Refactor), atomicity verification tests, calibration heuristics, and decomposition principles.

### Foundational Principle: Task-Commit Relationship

**The 1:1 task-commit relationship is not aspirational - it's definitional.** A "task" in PLAN.md means "an atomic task that becomes exactly one commit."

This is not a goal to work toward - it defines what a task IS. If something requires multiple commits, it's not one task. If multiple "tasks" fit in one commit, they're not properly decomposed.

### Task Category Labels

Tasks must be labeled with their category (see [atomic-changes.md](atomic-changes.md#change-categories) for definitions):

**Feature tasks** (no category prefix):

```markdown
- [ ] Add email validation to user registration
```

**Move-only tasks** (prefix with "Move-only:"):

```markdown
- [ ] Move-only: Extract authentication logic to separate module
```

**Refactor tasks** (prefix with "Refactor:"):

```markdown
- [ ] Refactor: Simplify user validation logic
```

#### TDD Requirement for Feature Tasks

All feature tasks must follow test-driven development with tests implemented first. See the "Development Methodology Requirements" section for details on the TDD cycle.

## Development Methodology Requirements

### Test-Driven Development Integration

Feature tasks follow the TDD cycle:

1. **Red**: Write failing test(s) that define the expected behavior
2. **Green**: Write minimal code to make the test(s) pass
3. **Refactor**: Clean up the implementation while keeping tests green

### Requirements by Task Category

#### Requirements for Feature Tasks

- Must include test criteria in task description
- Specify what behavior is being tested
- Define expected inputs and outputs
- Clarify edge cases to handle
- Tasks without clear test requirements are not well-defined and should be refined before inclusion

#### Requirements for Move-Only Tasks

- Run existing tests before and after to verify no behavior changes
- The diff should be primarily moved code with minimal integration code (imports, exports)

#### Requirements for Refactor Tasks

- Verify all existing tests pass after refactoring
- No new features or behavior changes

## Practical Guidance

### Good Task Examples

#### Example 1: Feature task (API endpoint)

```markdown
- [ ] Implement GET /api/users endpoint
  - Write tests for successful retrieval (200 status, array of users)
  - Write tests for empty database case (200 status, empty array)
  - Write tests for authentication failure (401 status)
  - Implement endpoint handler with database query
  - Add authentication middleware
```

#### Example 2: Feature task (UI component)

```markdown
- [ ] Create UserCard component
  - Write tests for rendering with valid user data
  - Write tests for handling missing optional fields
  - Write tests for click interaction triggering callback
  - Implement component with props interface
  - Add basic styling following design system
```

#### Example 3: Feature task (data validation)

```markdown
- [ ] Add email validation to user registration
  - Write tests for valid email formats
  - Write tests for invalid formats (missing @, invalid domain, etc.)
  - Write tests for edge cases (empty, null, very long strings)
  - Implement validation function with regex
  - Integrate into registration form with error messages
```

#### Example 4: Move-only task

```markdown
- [ ] Move-only: Extract authentication logic to separate module
  - Move auth functions from app.js to auth/index.js
  - Add module exports for public functions
  - Update imports in files that use auth functions
  - Verify all tests still pass with no behavior changes
```

#### Example 5: Refactor task

```markdown
- [ ] Refactor: Simplify user validation logic
  - Extract common validation patterns into reusable functions
  - Replace duplicated validation code with extracted functions
  - Verify all existing tests still pass
```

### Bad Task Examples

#### Example 1: Too Broad (Multiple Features)

```markdown
- [ ] Implement user authentication system
```

**Why**: This encompasses login, logout, session management, password reset, etc. Should be broken into multiple atomic tasks.

#### Example 2: Too Vague (No Test Criteria)

```markdown
- [ ] Make the UI look better
```

**Why**: No measurable success criteria, no clear scope, not testable.

#### Example 3: Purely Preparatory Work

```markdown
- [ ] Add lodash dependency
```

**Why**: Each task must accomplish something meaningful. Adding a dependency without using it leaves the repository in a "dangling" state where the dependency appears unnecessary. Instead, add dependencies when they're actually used:

**Better:**

```markdown
- [ ] Implement array sorting utility
  - Add lodash dependency
  - Create sortBy helper function using lodash
  - Write tests for sorting behavior
  - Use in user list component
```

#### Example 4: Not Incremental (Requires Multiple Steps)

```markdown
- [ ] Refactor entire authentication module and add OAuth support
```

**Why**: Combines refactoring with new features. Should be separate tasks:

```markdown
- [ ] Refactor: Simplify authentication module structure
- [ ] Add OAuth 2.0 support
```

#### Example 5: Missing Test Criteria

```markdown
- [ ] Add sorting to user list
  - Implement sort function
  - Update UI
```

**Why**: No specification of test cases, expected behavior, or validation steps.

**Better:**

```markdown
- [ ] Add sorting to user list
  - Write tests for ascending/descending sort by name
  - Write tests for sort by date registered
  - Write tests for maintaining sort across pagination
  - Implement sort function with multiple sort criteria
  - Update UI with sort controls and indicators
  - Verify sort state persists across page refreshes
```

## Structuring Tasks for Common Scenarios

This section provides guidance for PLAN.md authors on how to structure tasks for different types of work.

### Layered Infrastructure

#### Example: Infrastructure decomposed by layer

When documenting layered infrastructure, structure it as separate tasks where each layer can be independently tested:

```markdown
- [ ] Add User model with email validation
  - Write tests for valid/invalid email formats
  - Write tests for required fields (name, email, password)
  - Implement User model with validation rules

- [ ] Create database repository for User persistence
  - Write tests for creating users in database
  - Write tests for finding users by email
  - Write tests for handling duplicate email errors
  - Implement UserRepository with database operations

- [ ] Add POST /api/users registration endpoint
  - Write tests for successful user creation (201 response)
  - Write tests for duplicate email rejection (409 response)
  - Write tests for invalid input validation (400 response)
  - Implement registration controller using UserRepository
```

### Cross-Component Features

When a feature requires changes across multiple components, **decompose it into atomic tasks per layer**, each testable independently:

**WRONG (not minimal - spans multiple layers):**

```markdown
- [ ] Add user avatar upload feature
  - Write integration test for complete upload flow (UI -> API -> DB -> retrieval)
  - Add avatar_url column to users table with migration
  - Implement POST /api/users/:id/avatar endpoint with file
    validation
  - Create AvatarUpload component with preview and error states
  - Add avatar display to UserProfile component
```

**Why wrong**: This task spans data layer, API layer, and UI layer. It's multiple atomic tasks combined and would require multiple meaningful commits.

**CORRECT (atomic tasks):**

```markdown
- [ ] Implement POST /api/users/:id/avatar endpoint
  - Add avatar_url column to users table (nullable string)
  - Add multer dependency for file uploads
  - Write tests for file upload validation (image types, 5MB size limit)
  - Write tests for successful upload (200 status, file stored, URL returned)
  - Write tests for error cases (400 invalid file, 404 invalid user, 500 storage failure)
  - Implement endpoint with file storage and database update

- [ ] Create AvatarUpload component
  - Write tests for file selection and preview
  - Write tests for upload progress and error states
  - Write tests for API integration with POST /api/users/:id/avatar
  - Implement component with file selection UI
  - Add preview and error state displays
  - Integrate with avatar upload endpoint

- [ ] Add avatar display to UserProfile component
  - Write tests for avatar display with valid URL
  - Write tests for fallback image when avatar_url is null
  - Update UserProfile to fetch and display avatar
  - Verify display works in various states (loading, success, fallback)
```

**Note for authors**: Each task is atomic and complete: one layer, fully tested, independently valuable. The complete "feature" emerges from the series of atomic tasks.

### Bug Fixes

#### Example: Bug fix with regression tests

When documenting bug fixes, structure the task to include regression tests:

```markdown
- [ ] Fix UserProfile crash when user has no avatar
  - Write failing test for null avatar_url
  - Add null/undefined check in UserProfile.render()
  - Write tests for related edge cases (empty string, malformed URL)
  - Refactor avatar display logic to use fallback helper
  - Verify all tests pass
```

### Refactoring Work

#### Example: Refactoring with test verification

When documenting refactoring, structure the task to verify behavior preservation:

```markdown
- [ ] Refactor: Extract password validation into reusable helper
  - Verify password validation in registration and reset handlers has test coverage
  - Verify all existing tests pass (baseline)
  - Extract duplicated password validation logic from both handlers
  - Create validatePassword() helper with existing validation rules
  - Update registration and reset handlers to use helper
  - Verify all tests still pass
```

## Update Protocol

**IMPORTANT**: PLAN.md and ChangeLog.md are tracked in version control throughout development. All updates to the plan are logged in a separate ChangeLog.md file. When a plan is completed, both files are concatenated and archived to `.attic/plans/` for permanent record.

### ChangeLog.md Format

Changes to PLAN.md are appended to ChangeLog.md using shell redirection to avoid reading the entire file:

```bash
cat >> "ChangeLog.md" <<'EOF'

## YYYY-MM-DD - [Brief description of change]

[Detailed explanation of what changed and why]
EOF
```

#### ChangeLog Requirements

- New entries appended to the end of the file (chronological order, oldest first)
- ISO 8601 date format (YYYY-MM-DD)
- Brief description in the header
- Detailed explanation in the body
- Each update creates a new entry
- Use `cat >>` to append without reading the entire file
- Spacing: When appending entries, include a blank line at the start of the heredoc (after `<<'EOF'`) to separate from the previous entry. Do not include a blank line before the closing `EOF`.

### Initial Plan Creation

When creating a new PLAN.md for the first time, create an initial ChangeLog.md entry documenting the plan's creation. This establishes context for the plan's evolution and helps track the overall development approach.

#### Required Elements for Initial Entry

- Date of plan creation (ISO 8601 format)
- Feature or goal this plan addresses
- High-level approach or strategy
- Key assumptions, constraints, or architectural decisions (if applicable)

#### Example of Initial Entry

Create ChangeLog.md with the initial entry:

```bash
cat >> "ChangeLog.md" <<'EOF'

## 2025-10-08 - Initial plan created

Created plan for user authentication system. Decomposed into 8 tasks following TDD approach with focus on security best practices. Starting with data model, then authentication logic, then API endpoints to ensure solid foundation. Assumes bcrypt for password hashing and JWT for session management.
EOF
```

### Marking Tasks Complete

When a task is completed and committed:

1. Change `[ ]` to `[x]` for the completed task in PLAN.md

**ChangeLog Decision Criteria:**

**NO ChangeLog entry needed when:**

- Task completed exactly as described
- No adjustments to approach or scope during implementation
- No sub-requirements added, removed, or modified

**When no ChangeLog entry is needed:** The task completion is finished after marking the checkbox. No further updates to PLAN.md are required.

**REQUIRES ChangeLog entry when:**

- Implementation approach changed (e.g., switched libraries, changed architecture)
- Sub-requirements added, removed, or modified during work
- Scope adjusted due to discovered constraints or blockers
- Technical decisions deviated from original plan
- Task was split, combined, or reordered relative to original plan

#### Example ChangeLog Entry (Modified Task)

This example shows logging a change made during implementation:

```bash
cat >> "ChangeLog.md" <<'EOF'

## 2025-10-09 - Update email validation requirements

Modified task "Add email validation to user registration" during implementation. Originally planned to use regex validation, but discovered the email-validator library provides better internationalization support. Updated sub-requirements to reflect library-based approach instead of custom regex.
EOF
```

### Task-Commit Alignment

Each task in PLAN.md has a strict 1:1 relationship with a single git commit. This is a fundamental principle:

- **One task = One commit**: Every task becomes exactly one commit when completed
- **Never split tasks across commits**: If implementation requires multiple commits, the original task was incorrectly scoped
- **Never combine tasks in one commit**: Each task should be minimal and atomic enough to stand alone

#### Task Descriptions Guide Commit Scope

Task descriptions define the *planned* work scope as atomic tasks. Sub-requirements break down what needs to be implemented and tested within that single atomic unit. The task provides clear direction for what belongs in one commit.

#### When Task Scoping Was Wrong

During implementation, you may discover that your task scoping doesn't match the 1:1 task-commit principle. The most common issue is **tasks that are too large** (requiring multiple commits). Less frequently, you may find tasks that are too small (multiple tasks fit in one commit). Both indicate planning errors that should be corrected.

**If you discover during implementation that a task needs multiple commits:**

**Common Planning Error:** This indicates the **original planning was incorrect**. The task was not truly atomic (see "Atomic Task" in Key Terminology). To fix this:

1. **Stop implementation** of the oversized task
2. **Return to planning**: Decompose the task into properly-scoped atomic tasks
3. **Update PLAN.md**: Replace the oversized task with 2+ properly-scoped tasks
4. **Add ChangeLog entry** explaining the rescoping:

   ```bash
   cat >> "ChangeLog.md" <<'EOF'

   ## YYYY-MM-DD - Rescope oversized task

   Discovered task "[Original task]" was not atomic during implementation - it required multiple commits. Decomposed into [N] atomic tasks:

   - [New task 1]
   - [New task 2]
   - [New task N]
   EOF
   ```

5. **Resume implementation** with correctly-scoped tasks

**Why this matters:** Oversized tasks break atomic commit principles, make code review difficult, and can leave the codebase in incomplete states between commits. Catching and rescoping them preserves the value of incremental development.

##### Less Common: Over-Granular Tasks

Occasionally, you may discover during implementation that multiple tasks could be combined into one commit without violating atomicity. This is less common than oversized tasks but still indicates planning that was too granular.

**If you discover multiple tasks could be combined into one commit:**

This indicates the **original planning was too granular**. The tasks were not truly atomic. To fix this:

1. **Stop implementation** before creating fragmented commits
2. **Return to planning**: Combine the tasks into a single atomic task
3. **Update PLAN.md**: Replace multiple tasks with one properly-scoped task
4. **Add ChangeLog entry** explaining the consolidation
5. **Resume implementation** with correctly-scoped task

**Why this matters:** Over-granular tasks break atomicity by creating intermediate committed states where the codebase violates project invariants. For example, splitting "Add feature X" into "Add dependency" and "Implement feature X" creates a commit with dangling, unused code. Each commit must leave the codebase in a valid, working state in compliance with project guidelines (passing tests, linting, no unused dependencies or dead code, etc.).

**Example of Over-Granular Tasks:**

**Over-granular (should be combined):**

```markdown
- [ ] Add avatar_url column to users table
- [ ] Write migration for avatar_url column
- [ ] Write tests for avatar_url column constraints
```

These three items represent a single atomic change (adding a database column) that should be one commit.

**Better (atomic and right-sized):**

```markdown
- [ ] Add avatar_url column to users table
  - Write migration to add avatar_url column with constraints
  - Write tests for column constraints and defaults
  - Verify migration runs and rolls back cleanly
```

This combines the work into a single atomic task with sub-requirements, matching the 1:1 task-commit principle.

#### The Core Principle

**The plan should reflect the actual atomic tasks needed to build the feature** (see "Atomic Task" in Key Terminology for full definition). Follow the plan as written - it exists to guide implementation.

**When to update the plan:** Only when it becomes clear the task as written is impossible or relies on false assumptions (e.g., "Integrate with API endpoint /users" but that endpoint doesn't exist, or "Use library X for feature Y" but library X doesn't support the needed functionality), or is poorly scoped. Implementation difficulty alone is not a reason to change the plan. The threshold is high: the plan should only be changed when the task cannot be completed as specified, not merely because it's harder than expected.

**Task decomposition principle:** Break tasks down as much as possible, but no further. Tasks should be decomposed until further breakdown would violate project invariants - creating commits with dead code, unused dependencies, or leaving the codebase in a non-compliant state. When tasks are correctly scoped at this level, they naturally map 1:1 to commits without adjustment.

**In practice:** Most planning errors lean toward tasks that are too large rather than too small. When in doubt during planning, favor smaller, more focused atomic tasks.

### Adding New Tasks

When new requirements or tasks are discovered:

1. Add tasks in dependency order
2. Maintain atomic task principles
3. Update task list without changing completed tasks
4. Add ChangeLog entry explaining the additions

#### Example ChangeLog Entry (Adding Tasks)

This example shows how to document newly-discovered requirements:

```bash
cat >> "ChangeLog.md" <<'EOF'

## 2025-10-10 - Add password reset tasks

Discovered requirement for password reset flow during authentication implementation. Added 3 new tasks covering email validation, token generation, and reset UI.
EOF
```

### Reordering Tasks

When dependencies change or better ordering is discovered:

1. Preserve completed task status
2. Move tasks to correct dependency position
3. Ensure no task depends on uncompleted future tasks
4. Add ChangeLog entry explaining the reordering

#### Example ChangeLog Entry (Reordering Tasks)

This example shows documenting a dependency-based reordering:

```bash
cat >> "ChangeLog.md" <<'EOF'

## 2025-10-12 - Reorder database migration tasks

Moved schema migration task before API implementation to resolve dependency issue. Cannot implement API endpoints without the database schema in place.
EOF
```

### Removing Tasks

If a task becomes unnecessary:

1. Remove the checkbox formatting from the task
2. Move the task description to the ChangeLog entry
3. Add ChangeLog entry explaining why it wasn't needed

#### Example ChangeLog Entry (Removing Tasks)

This example shows documenting a removed task:

```bash
cat >> "ChangeLog.md" <<'EOF'

## 2025-10-13 - Remove password strength indicator task

Removed task: Add visual password strength indicator to registration form
  - [Sub-requirements preserved verbatim]

Reason: Discovered the form validation library already provides this functionality built-in. No additional implementation needed.
EOF
```

### Reopening or Rolling Back Completed Tasks

**When a completed task needs to be rolled back:**

1. **Revert the commit** (if appropriate):

   ```bash
   git revert <commit-hash>
   ```

2. **Update task status** from [x] back to [ ]:

   ```markdown
   - [ ] Original task description
     - Original sub-requirements
   ```

3. **Add ChangeLog entry**:

   ```bash
   cat >> "ChangeLog.md" <<'EOF'

   ## YYYY-MM-DD - Rolled back task "Task description"

   Discovered issue: [specific problem]. Reverted commit abc123.
   Will re-implement with different approach: [new approach].
   EOF
   ```

**When requirements change after completion:**

1. **Keep original task marked [x]** (it was completed correctly at the time)
2. **Add new task** for updated requirements
3. **Add ChangeLog entry** explaining the requirement change

## Plan Completion

When all tasks are completed and committed:

1. **Verify completion**:
   - All tasks marked [x]
   - All commits referenced in task history
   - No pending items

2. **Add final ChangeLog entry**:

   ```bash
   cat >> "ChangeLog.md" <<'EOF'

   ## YYYY-MM-DD - Plan completed

   All tasks implemented and committed. Feature [Feature Name] is complete.
   EOF
   ```

3. **Archive the plan**:

   ```bash
   # Ensure archive directory exists
   mkdir -p .attic/plans

   # Concatenate ChangeLog to the end of PLAN.md
   cat "ChangeLog.md" >> "PLAN.md" && \

   # Move PLAN.md to archive with timestamped name
   mv "PLAN.md" ".attic/plans/PLAN-$(date +%Y-%m-%d)-short-topic-description.md" && \

   # Remove ChangeLog (contents already in archived PLAN.md)
   rm "ChangeLog.md"
   ```

   **Important**: Replace `short-topic-description` with a brief, hyphenated description of what was implemented (e.g., `user-authentication`, `avatar-upload`, `search-optimization`).

4. **Repository is ready for next plan**: Working directory contains no PLAN.md or ChangeLog.md files.

## Summary

PLAN.md documents follow a structured format implementing GTD (Getting Things Done) Natural Planning Model:

- **Header with metadata**: Title, overview, and section structure
- **Outcomes section**: Required section listing desired results/projects following GTD principles
  - Multi-step results that require multiple tasks to achieve
  - Observable end states with measurable completion criteria
  - Success criteria, principles, and constraints for each outcome
  - Clear outcome-to-task relationship mapping
- **Tasks section**: Ordered list of atomic tasks using markdown checkboxes
  - `[ ]` for pending tasks, `[x]` for completed tasks
  - Three task categories: feature (default), move-only, and refactor
  - Task descriptions with action verb, what, and optional where/how
  - Sub-requirements specifying test criteria, implementation details, and validation
- **Change management**: Separate ChangeLog.md file documenting all plan modifications
- **Update protocol**: Procedures for marking complete, adding, reordering, and removing tasks
- **Archival process**: Archive completed plans to `.attic/plans/` with concatenated changelog, committed to version control

The outcomes-first approach ensures that all atomic tasks contribute toward meaningful, measurable results while maintaining the strict 1:1 task-commit relationship for incremental development.
