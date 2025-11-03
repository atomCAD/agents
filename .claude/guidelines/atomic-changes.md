# Atomic Changes

This guideline defines the fundamental concept of **atomic changes** - the smallest meaningful units of work that can be independently completed, tested, and delivered. Atomic changes are the foundation for multiple workflows including task planning in PLAN.md documents and decomposing mixed changesets into separate commits.

## Scope of This Document

This guideline specifies **what atomic changes are and how to identify them**. It provides the foundational concepts used by multiple tools and workflows:

- **`/plan` workflow**: Uses atomic changes as tasks in PLAN.md documents
- **`/split` workflow**: Uses atomic changes to decompose mixed diffs into separate commits
- **Code review**: Uses atomic changes to evaluate commit granularity
- **Feature planning**: Uses atomic changes to break down work

### In Scope

1. **Atomic Change Definition** - What makes a change atomic
2. **Change Categories** - Feature, Move-only, and Refactor types
3. **Atomicity Verification** - Tests to determine if a change is properly atomic
4. **Decomposition Principles** - How to break work into atomic units
5. **Location Independence** - Why file/hunk boundaries don't determine atomicity
6. **Semantic Decomposition** - Protocol for identifying distinct logical changes
7. **Calibration Heuristics** - Guidelines for appropriate change granularity
8. **Examples** - Well-formed and malformed atomic changes

### Out of Scope

1. **Delivery Mechanisms** - How atomic changes are represented in PLAN.md, commits, or other formats
2. **Workflow-Specific Details** - `/plan`, `/split`, or other tool-specific procedures
3. **Document Formats** - Markdown syntax, checkbox formats, or file structures
4. **Development Methodology** - TDD cycles, testing frameworks, or language-specific practices
5. **Project Management** - Tracking progress, updating status, or archiving completed work

## Key Terminology

This document uses specific terms with precise meanings:

### Atomic Change

An atomic change is the smallest meaningful modification to a system that can be independently completed, tested, and delivered. It represents the quantum unit of work - you cannot decompose it further without losing atomicity.

**Key characteristics:**

- Completable as a single unit of delivery (one commit, one task, etc.)
- Does precisely one thing
- Adds, moves, or refactors the smallest meaningful capability
- Has clear pass/fail validation
- Leaves the codebase in a working state

**Example:** Adding password validation logic to a registration endpoint is atomic. Implementing an entire user authentication system is not - it must be decomposed into multiple atomic changes.

**Related concept**: An atomic change represents a "minimal increment" in the sense that it cannot be decomposed further while remaining atomic. However, "minimal" when used elsewhere in this document refers to the property of being as small as possible, not as a synonym for "atomic change" itself.

## Change Categories

Every atomic change must be categorized as one of three types:

1. **Feature** - Implements new features, bug fixes, or any behavior change to the program

   **Allowed in feature changes:**
   - Adding new functionality or capabilities to the system
   - Fixing bugs that change program behavior
   - Modifying existing behavior to meet new requirements
   - Adding new tests for new or changed behavior
   - Creating new files, classes, functions, or modules for new features
   - Updating existing code to support new functionality

   **NOT allowed (use Move-only or Refactor instead):**
   - Relocating code without behavior changes (use Move-only)
   - Improving code structure without changing behavior (use Refactor)
   - Renaming variables/functions without functional changes (use Refactor)
   - Extracting duplicated code without adding features (use Refactor)
   - Moving files or modules without adding features (use Move-only)

   **Decision criteria**: If adding new behavior, fixing broken behavior, or changing how the program responds to inputs, it's a feature. If only changing code organization or quality without behavior changes, use Move-only or Refactor.

2. **Move-only** - Relocates code with minimal changes

   **Allowed in move-only changes:**
   - Moving functions, classes, or modules to different files
   - Reordering function/class definitions within a file
   - Adding module definitions, imports, exports required for new location
   - Updating import paths in files using the moved code
   - Minimal formatting changes to fit new context

   **NOT allowed (use Refactor instead):**
   - Changing function signatures or interfaces
   - Modifying internal logic or algorithms
   - Renaming beyond what's required for new location
   - Combining/splitting functions

   **Purpose**: Move-only changes isolate code relocation from logic changes. Movement diffs are large and difficult to review - the reviewer should only need to verify the code is identical in the new location. Never mix movement with refactoring in the same change, as it makes review significantly harder.

   **"Minimal changes" defined**: Only modifications strictly necessary for code to function in new location:
   - Indentation adjustments to match new location's style
   - Import path updates (changing relative paths)
   - Namespace or module wrapper additions required by new location
   - Export/visibility keywords required by language (e.g., `pub`, `export`)
   - Location-specific comment references (e.g., file names in docstrings)
   - Line wrapping adjustments to match new location's line length conventions
   - Qualified name updates when moving between namespaces
   - Re-exports in original location when needed to maintain temporary backward compatibility

   **NOT minimal (use Refactor instead):**
   - Rewriting or improving documentation content
   - Reformatting code style beyond what's needed for new context
   - Renaming variables, functions, or parameters
   - Changing logic, algorithms, or control flow

   **Boundary with Refactor**: If improving *how the code works* (not just *where it lives*), use Refactor instead. Ask: "Would this change be needed if the code stayed in its original location?" If yes, it's a refactor.

   **Decision criteria**: If improving how code works (not just where it lives), it's a refactor.

3. **Refactor** - Changes code structure without changing behavior

   **Allowed in refactor changes:**
   - Renaming variables, functions, classes, or modules for clarity
   - Extracting duplicated code into reusable functions or modules
   - Simplifying complex functions or logic while preserving behavior
   - Updating code style or formatting for consistency
   - Breaking down large functions into smaller, more focused ones

   **NOT allowed (use Feature or Move-only instead):**
   - Changing program behavior or outputs (use Feature)
   - Adding new functionality or capabilities (use Feature)
   - Relocating code (use Move-only)
   - Fixing bugs that change behavior (use Feature)

   **Decision criteria**: If the program's external behavior remains identical (same inputs produce same outputs), it's a refactor. If changing what the program does or where code lives, use Feature or Move-only.

## Decomposition Principles

### Atomic Changes Are Indivisible

Each change must be **atomic** (see "Atomic Change" in Key Terminology) - the smallest meaningful modification to the system.

**Critical principle**: Changes should be as **simple as possible** while still remaining atomic. If a change can be broken down further without losing atomicity, it should be. Atomic changes are definitional, not aspirational - if you discover during work that something requires multiple units of delivery, the original decomposition was incorrect.

### Verifying Change Atomicity

Apply these tests in order to verify a change is properly atomic:

1. **Single Sentence Test**: Can you describe the change in one sentence without using "and"?
   - PASS: "Add email validation to registration"
   - FAIL: "Add email validation and password strength checking"

2. **Single Unit Test**: Can this be completed in exactly one unit of delivery?
   - If you anticipate multiple commits/tasks/PRs, decompose further

3. **Focused Validation Test**: Can completion be verified with one focused testing approach?
   - PASS: "Test password validation with valid/invalid inputs"
   - FAIL: "Test entire authentication flow end-to-end"

4. **Minimal Test**: Can this change be meaningfully smaller while remaining useful?
   - If yes, decompose further

**Red flags indicating non-atomic changes:**

- Description exceeds one sentence
- Work spans multiple unrelated concerns
- Multiple distinct validation approaches needed

If ANY test fails, decompose further before proceeding.

### Calibration Heuristics

These guidelines help calibrate change granularity. They are heuristics, not rigid rules.

**Scope indicators** (consider splitting if):

- Changes span 5+ files with different concerns
- Expected lines of change exceed 100-150
- Creates complex dependency chains across components

**Complexity indicators** (consider splitting if):

- Requires multiple significant architectural decisions
- Contains unknown unknowns requiring exploration
- Involves cross-cutting concerns affecting multiple subsystems
- Requires significant context switching between domains
- Validation approach is complex or multi-faceted

**Verification indicators** (consider splitting if):

- "Done" criteria requires a paragraph to explain
- No single clear test approach exists
- Partial rollback would be difficult or non-atomic

**Calibration questions**:

1. Can I describe this in one sentence without "and"?
2. If interrupted halfway, would partial work be coherent (code compiles, tests pass, no broken functionality)?
3. Does this have a single clear validation approach?
4. Would a code reviewer understand this as one logical change?

**Context adaptations**:

- Exploratory work: Smaller changes help navigate uncertainty
- Well-understood domains: Slightly larger changes may be appropriate
- Emergency fixes: Focus on minimal fix scope

**Examples**:

- Too granular: "Update import statement in auth.rs" (too mechanical)
- Too broad: "Implement user authentication system" (needs decomposition)
- Well-calibrated: "Add password validation logic to registration endpoint" (clear, testable, atomic)

### Location Independence

**Critical principle: Location in code does not determine atomicity. Semantic meaning does.**

When identifying atomic changes, **ignore** where modifications appear in the codebase:

- File boundaries are irrelevant
- Hunks in diffs are irrelevant
- Line numbers are irrelevant
- Directory structure is irrelevant

**The only question**: What distinct logical changes exist?

#### Why Location Doesn't Matter

1. **Multiple files, one change**: A single atomic change might touch authentication logic in `auth.rs`, its tests in `auth_test.rs`, and imports in `main.rs`. This is still one change: "Add password hashing to authentication."

2. **One file, multiple changes**: A single file might contain two unrelated atomic changes: simplifying validation logic (refactor) and adding a new validation rule (feature). These must be separate despite touching the same file.

3. **Adjacent lines, different changes**: Consecutive lines might belong to different atomic changes. Location proximity means nothing - semantic purpose defines the boundary.

#### Decomposition Protocol

When analyzing changes (whether from diffs, feature requests, or work plans):

1. **Read holistically** to understand all modifications
2. **Identify semantic changes** by asking "what concepts/behaviors are being modified?"
3. **Describe each semantic change** in one sentence without "and"
4. **Verify atomicity** using the tests in "Verifying Change Atomicity"
5. **Map changes to affected code** (this is documentation, not decomposition)

### Example: Analyzing a mixed diff

```text
Diff touches:
- auth.rs: simplified password validation logic
- auth.rs: added OAuth token validation
- auth_test.rs: tests for OAuth tokens
- README.md: updated OAuth documentation
```

**Incorrect decomposition** (by file):

- Commit 1: Changes to auth.rs
- Commit 2: Changes to auth_test.rs
- Commit 3: Changes to README.md

**Correct decomposition** (by semantic meaning):

- Change 1 (Refactor): Simplify password validation logic in auth.rs
- Change 2 (Feature): Add OAuth token validation (auth.rs, auth_test.rs, README.md)

## Examples

### Well-Formed Atomic Changes

#### Example 1: Feature change (API endpoint)

**Change**: Implement GET /api/users endpoint

**Why it's atomic**:

- Single purpose: adds one endpoint
- Clear validation: test with expected responses (200 with user array, 401 for unauthed)
- Completable in one unit of work
- Leaves system in working state

#### Example 2: Feature change (UI component)

**Change**: Create UserCard component

**Why it's atomic**:

- Single purpose: adds one component
- Clear validation: renders correctly with valid data, handles missing fields, responds to clicks
- Minimal scope: one component with its tests
- Independent: doesn't require other UI changes

#### Example 3: Feature change (data validation)

**Change**: Add email validation to user registration

**Why it's atomic**:

- Single purpose: validates one field
- Clear validation: accepts valid formats, rejects invalid ones
- Focused scope: registration email field only
- Complete: includes error messaging

#### Example 4: Move-only change

**Change**: Extract authentication logic to separate module

**Why it's atomic**:

- Single purpose: relocates auth code
- Clear validation: all existing tests still pass
- Minimal changes: only imports/exports needed for new location
- No behavior changes

#### Example 5: Refactor change

**Change**: Simplify user validation logic

**Why it's atomic**:

- Single purpose: improves code structure
- Clear validation: all existing tests pass
- No behavior changes: same inputs produce same outputs
- Focused scope: validation logic only

### Malformed Changes

#### Example 1: Too Broad (Multiple Features)

**Change**: Implement user authentication system

**Why it's not atomic**: This encompasses login, logout, session management, password reset, etc. Should be broken into multiple atomic changes.

#### Example 2: Too Vague (No Validation Criteria)

**Change**: Make the UI look better

**Why it's not atomic**: No measurable success criteria, no clear scope, not verifiable.

#### Example 3: Purely Preparatory Work

**Change**: Add lodash dependency

**Why it's not atomic**: Adding a dependency without using it creates a dangling, unused resource. Atomic changes must accomplish something meaningful. Combine dependency addition with its first use.

**Better**: Implement array sorting utility (includes adding lodash, creating sortBy helper, writing tests, and using it in user list component)

#### Example 4: Not Atomic (Combines Multiple Types)

**Change**: Refactor entire authentication module and add OAuth support

**Why it's not atomic**: Combines refactoring with new features. Should be separate changes:

- Refactor: Simplify authentication module structure
- Feature: Add OAuth 2.0 support

#### Example 5: Insufficient Validation Specification

**Change**: Add sorting to user list

**Why it's not atomic**: No specification of what sorting means, edge cases, or validation criteria.

**Better**: Add sorting to user list (specify ascending/descending by name and date, maintaining sort across pagination, persisting sort state)
