# Plan: Enhance Planning System with Task Implementation Workflow

This plan covers enhancements to the PLAN.md planning system, adding GTD-style outcomes support, improving agent capabilities for decomposing feature requests into desired results (outcomes) and concrete actions (tasks), and implementing a /task command that automates the red-green-refactor TDD workflow for executing tasks from PLAN.md.

## Outcomes

- Planning workflows distinguish between desired outcomes and implementation tasks
  - Success criteria: Outcomes section exists in PLAN.md format specification
  - Success criteria: Plan-architect agent can identify and generate outcomes
  - Success criteria: /plan command can manage outcomes alongside tasks
  - Principle: GTD Natural Planning Model guides the planning process

- Agent instructions provide clearer communication protocols
  - Success criteria: Transactional communication protocol defined
  - Success criteria: Natural intelligence leverage guidance documented
  - Principle: Reduce unnecessary social protocols, trust contextual reasoning

- All agent definitions are implemented and available in .claude/agents
  - Success criteria: All 49 agents referenced in analyst-roster.md have definition files
  - Success criteria: All 4 always-required core agents are implemented (complexity-auditor, security-auditor, style-conformist, temporal-reference-critic)
  - Success criteria: All 5 conditionally-required core agents are implemented (architecture-critic, dependency-auditor, documentation-reviewer, commit-message-author, test-inspector)
  - Success criteria: All language-specific nit-checkers are implemented (rust, python, go, java, javascript)
  - Success criteria: All specialized domain experts are implemented (database-optimizer, auth-specialist, crypto-specialist, performance-analyst, etc.)
  - Principle: Complete agent ecosystem enables comprehensive code review coverage

- Task implementation workflow automates TDD-driven feature development
  - Success criteria: /task command can parse task specifiers from PLAN.md
  - Success criteria: /task identifies "next task" when no directive provided
  - Success criteria: Red-green-refactor cycle is automated (tests first, implementation, refactor)
  - Success criteria: Validation passes before and after implementation
  - Success criteria: Task completion updates PLAN.md automatically
  - Principle: Follow test-driven development practices strictly
  - Principle: Ensure repository stays in working state throughout

## Tasks

- [x] [Design] Create task-inference agent definition
  - Write YAML frontmatter with required fields
  - Define agent purpose: bridge scope analysis (WHERE) and quality analysis (WHAT)
  - Specify YAML input/output format for task objective inference
  - Document analysis methodology for determining implementation objectives from file changes
  - Include examples following existing agent templates
  - Save to /workspace/.claude/agents/task-inference.md

- [x] [Implementation] Integrate task-inference into /check workflow
  - Prerequisites: task-inference agent definition must exist
  - Add Step 1.5 calling task-inference agent between scope and team selection
  - Update Step 4c scope logic from file-based to task-objective-based criteria
  - Replace "Is file in analyzed scope?" with "Is fix required to complete task objective?"
  - Add examples demonstrating task-based vs file-based scope decisions
  - Update Step 2 to use task definition for analyst selection
  - Test integration with staged changes for scope categorization
  - Modify file: /workspace/.claude/commands/check.md

- [ ] [Implementation] Modify task-inference.md to run specialist agents in parallel
  - Update validation methodology to use single message with multiple Task tool calls
  - Replace sequential specialist agent calls with parallel execution pattern
  - Follow Claude Code best practice: "make all independent tool calls in parallel"
  - Improve token efficiency and execution speed
  - Test with multiple specialist agents (prompt-engineer, syntax-checker, etc.)
  - Example: Replace 5 separate Task calls with single message containing 5 Task calls
  - Context: Current implementation runs validation agents sequentially, should run in parallel

- [ ] [Implementation] Configure /message workflow to NOT word-wrap git commit messages
  - Add explicit "NO word-wrapping" directive to commit-message-author.md
  - Update .claude/guidelines/git-commit-messages.md with anti-wrapping guidance
  - Verify validation agents don't enforce line length limits
  - Test that long commit message lines remain intact

- [x] [Implementation] Create /task slash command workflow
  - Prerequisites: next-task-selector agent must exist
  - Write YAML frontmatter with required fields
  - Implement 8-step TDD procedure covering prerequisites, task selection, validation
  - Add RED phase: write failing tests, verify failures
  - Add GREEN phase: minimal implementation, verify tests pass
  - Add REFACTOR phase: improve code quality while maintaining passing tests
  - Complete workflow: update PLAN.md and generate implementation report
  - Handle task type variations (Feature/Move-only/Refactor)
  - Include error handling for missing PLAN.md and validation failures
  - Save to /workspace/.claude/commands/task.md

- [x] Remove syntax-checker from core agents system
  - Update analyst-roster.md: change always-required core agents from 5 to 4
  - Update analyst-roster.md: remove syntax-checker from always-required list
  - Update analyst-roster.md: update all agent counts in examples and documentation
  - Update check.md: remove syntax-checker from example agent lists
  - Update check.md: update fallback examples to start with style-conformist
  - Update fix.md: update examples to remove syntax-checker references
  - Verify all cross-references and counts are consistent

- [x] Add exit code reading guidance to /fix command
  - Add "IMPORTANT - Reading Bash Tool Results" section explaining exit code detection
  - Document that error tag presence indicates non-zero exit code
  - Add guidance about not re-running commands just to verify exit code
  - Add "Interpreting Bash tool results" section with decision criteria

- [x] Create next-task-selector agent definition
  - Write YAML frontmatter with name: "next-task-selector", description: "Analyzes PLAN.md to select the optimal next task", color: "blue", model: "claude-sonnet-4-0"
  - Define agent purpose: Analyze PLAN.md task list and select the next task to work on
  - Specify input requirements: PLAN.md contents, optional user directive
  - Define selection criteria: tasks not yet completed, no incomplete dependencies, consider criticality markers
  - Document analysis methodology: parse task list, identify completed tasks, check dependencies, evaluate priority ordering
  - Define output format: YAML frontmatter with status, line_number, reason fields, followed by task identifier
  - Include examples: selecting first uncompleted task with no dependencies, skipping tasks blocked by incomplete prerequisites
  - Save to /workspace/.claude/agents/next-task-selector.md

- [x] Create /next slash command workflow
  - Write YAML frontmatter with name: "next", description: "Selects the next task to work on from PLAN.md", color: "green", model: "claude-sonnet-4-0"
  - Define workflow purpose: Provide users with the next task to work on
  - Specify procedure: check for PLAN.md existence, read PLAN.md, call next-task-selector agent
  - Define error handling: exit with error if no PLAN.md exists
  - Specify output format: single line output with task identifier only (no extra commentary)
  - Document optional user directive parameter for additional guidance
  - Include examples: `/next`, `/next focus on database tasks`, `/next skip investigation tasks`
  - Save to /workspace/.claude/commands/next.md

- [x] [Documentation] Add outcomes section support to PLAN.md format specification
  - Prerequisites: Review existing .claude/guidelines/plan-file.md structure
  - Document Outcomes section format with GTD characteristics and validation criteria
  - Include outcome format examples with success criteria and constraints
  - Explain outcome-to-task relationship and dependency mapping
  - Update required document structure to mandate Outcomes section
  - Revise summary section to reflect outcomes integration

- [ ] [Implementation] Fix list indentation in commit messages
  - Enhance commit-message-author agent instructions:
    - Add explicit markdown list formatting examples showing 3-space indentation
    - Include post-generation self-check for proper list indentation
  - Expand commit-message-format-checker validation:
    - Add list indentation verification to format checker's responsibilities
    - Check that continuation lines align with first character of list item text
  - Modify files: /workspace/.claude/agents/commit-message-author.md, /workspace/.claude/agents/commit-message-format-checker.md

- [ ] [Implementation] Add test evaluation and cleanup to /task command workflow
  - Add final step to /task workflow for evaluating newly-added tests
  - Implement test categorization: keep vs remove based on long-term value
  - Identify fragile tests that test current content expected to change freely
  - Detect tests created solely for TDD red-green-refactor validation
  - Add criteria for test retention: stability, maintainability, business value
  - Generate test cleanup recommendations with rationale for each decision
  - Only evaluate tests added during current task execution, not existing tests
  - Modify file: /workspace/.claude/commands/task.md

- [ ] [Implementation] Make checkpoint skill create.sh non-destructive
  - Modify create.sh script to automatically call restore.sh before returning to caller
  - Ensure working tree and staging area remain unchanged after checkpoint creation
  - Remove unexpected stashing behavior that surprised users expecting non-destructive operation
  - Preserve current git state: only create checkpoint, don't modify workspace
  - Update skill to separate checkpoint creation from workspace stashing operations
  - Context: Users expect create.sh to be read-only operation that doesn't alter git state

- [ ] [Implementation] Enhance plan-architect agent with outcomes identification
  - Prerequisites: Updated PLAN.md format specification must exist
  - Add outcomes identification and decomposition to core responsibilities
  - Update planning process to include GTD-style outcome generation
  - Enhance validation checklist and output format to include outcomes
  - Update success criteria to include outcome-to-task mapping

- [ ] [Implementation] Add /plan command for PLAN.md management workflow
  - Prerequisites: Enhanced plan-architect agent and updated format specification
  - Context: This is the staged /plan command that needs to be committed
  - Create comprehensive planning workflow implementing GTD Natural Planning Model
  - Add progressive elaboration patterns with checkpoint tasks
  - Implement dual task categorization (specialist types + TDD categories)
  - Include dependency management and context requirement documentation
  - Add examples, anti-patterns, and error recovery procedures

- [ ] [Documentation] Add communication protocols to CLAUDE.md
  - Prerequisites: Review existing CLAUDE.md structure and content
  - Implement Transactional Communication Protocol (verification-first approach)
  - Add Leverage Natural Intelligence section (trust contextual reasoning)
  - Include pre-response verification protocol and evidence-based agreement requirements
  - Document subjective term handling guidance

- [ ] [Implementation] Create architecture-critic agent definition file
  - Context: Required for conditionally-required core agents completion
  - Write YAML frontmatter with required fields
  - Define core mission analyzing module boundaries and architectural quality
  - Document inclusion criteria and analysis methodology
  - Specify architectural patterns and anti-patterns to detect
  - Create structured output format with severity classification
  - Include examples and verify file structure matches existing templates
  - Save to /workspace/.claude/agents/architecture-critic.md

- [ ] [Implementation] Create async-flow-reviewer agent definition file
  - Context: Required for specialized domain experts completion
  - Write YAML frontmatter with required fields and async/await focus
  - Implement agent instructions covering promise chains and concurrency patterns
  - Define YAML response format and operating principles for async code review
  - Include validation examples showing good vs problematic async patterns
  - Verify file structure matches existing agent templates
  - Save to /workspace/.claude/agents/async-flow-reviewer.md

- [ ] [Implementation] Create auth-specialist agent definition file
  - Context: Required for specialized domain experts completion
  - Write YAML frontmatter with auth specialist role and OAuth/JWT focus
  - Write agent role definition establishing authentication and authorization expertise
  - Define core responsibilities covering OAuth flows and session management
  - Specify analysis scope including token validation and secure credential management
  - Include common authentication anti-patterns to detect
  - Add examples of authentication issues to identify
  - Specify output format for reporting authentication findings
  - Save to /workspace/.claude/agents/auth-specialist.md

- [ ] [Implementation] Create build-engineer agent definition file
  - Write YAML frontmatter with build engineer role and CI/CD focus
  - Write agent instruction section covering build analysis and CI/CD efficiency
  - Include methodology sections for build performance bottlenecks and optimization
  - Add practical guidance sections with tool usage patterns
  - Verify file follows structure pattern from existing agent files
  - Save to /workspace/.claude/agents/build-engineer.md

- [ ] [Implementation] Create caching-strategist agent definition file
  - Write YAML frontmatter with caching strategist role and performance focus
  - Add Core Philosophy section explaining caching best practices
  - Add Primary Responsibilities section covering cache configuration and TTL strategies
  - Add Implementation Guidelines section with cache analysis and anti-patterns
  - Add Code Analysis Patterns section with grep patterns for caching issues
  - Add Testing and Validation checklist for cache configuration review
  - Verify file follows structure of existing agent files
  - Save to /workspace/.claude/agents/caching-strategist.md

- [ ] [Implementation] Create complexity-auditor agent definition file
  - Context: Required for always-required core agents completion
  - Write YAML frontmatter with complexity auditor role and metrics focus
  - Define core responsibilities covering cyclomatic complexity and function length analysis
  - Add methodology section for measuring and evaluating complexity metrics
  - Include code analysis patterns and validation checklist
  - Verify file structure follows existing agent templates
  - Save to /workspace/.claude/agents/complexity-auditor.md

- [ ] [Planning] Revisit planning after core infrastructure complete
  - Outcome: Assess agent definition batch strategy for remaining 40+ agents
  - Triggers: Consider implementing agents in logical groups (language-specific, domain-specific, etc.)
  - Review: Evaluate if all agent definitions are needed immediately or can be phased

- [ ] [Implementation] Create component-lifecycle-analyst agent definition file
  - Add YAML frontmatter with name, description (component lifecycle and memory leak analysis), color, model (claude-sonnet-4-0), and tools (if needed)
  - Write comprehensive agent instructions covering component mounting/unmounting patterns
  - Include memory leak detection guidance (event listener cleanup, subscription cleanup, DOM reference cleanup)
  - Add component lifecycle testing methodology (useEffect cleanup, componentWillUnmount verification)
  - Define React-specific patterns (hooks dependencies, closure issues, stale closures)
  - Include framework-agnostic lifecycle concepts (initialization, cleanup, resource management)
  - Add code analysis patterns for detecting lifecycle issues
  - Include checklist for common memory leak sources
  - Verify file follows existing agent structure and formatting conventions

- [ ] [Implementation] Create concurrency-analyst agent definition file
  - Context: Required for specialized domain experts completion
  - Create .claude/agents/concurrency-analyst.md with YAML frontmatter (name, description, color, model, tools)
  - Write agent instruction section covering race conditions, deadlocks, and thread safety analysis
  - Include core philosophy, primary responsibilities, testing methodology, and tool usage sections
  - Specify analysis patterns for common concurrency issues (data races, deadlocks, lock ordering)
  - Define reporting structure for concurrency issues with severity classification
  - Verify file follows established agent definition structure (compare to accessibility-auditor.md format)

- [ ] [Implementation] Create config-auditor agent definition file
  - Context: Required for specialized domain experts completion
  - Write YAML frontmatter with name: "config-auditor", description, color, model (claude-sonnet-4-0), and tools fields
  - Write agent instruction section covering configuration security review responsibilities
  - Add environment variable security analysis methodology (secrets detection, credential patterns, exposure risks)
  - Add configuration file validation guidance (permissions, sensitive data, insecure defaults)
  - Add security best practices section (environment variable naming, secret management, separation of concerns)
  - Add common vulnerability patterns detection (hardcoded credentials, exposed API keys, database connection strings)
  - Add reporting format for configuration security findings
  - Verify file follows existing agent structure pattern from /workspace/.claude/agents/accessibility-auditor.md

- [ ] Create container-orchestrator agent definition file
  - Create `/workspace/.claude/agents/container-orchestrator.md` with YAML frontmatter (name, description, color, model, tools)
  - Write comprehensive agent instruction section covering Docker and Kubernetes configuration review responsibilities
  - Include security best practices, resource optimization, networking, and deployment patterns
  - Add validation checklist for container configurations
  - Verify file follows existing agent structure pattern from accessibility-auditor.md

- [ ] Create cors-policy-reviewer agent definition file
  - Add YAML frontmatter with name, description, color (purple), model (claude-sonnet-4-0), and tools fields
  - Write agent instruction section covering CORS configuration review fundamentals
  - Document security validation requirements for origin whitelists and credential handling
  - Specify code analysis patterns for detecting CORS misconfigurations
  - Include testing checklist for preflight requests, credential modes, and header validation
  - Provide examples of secure vs insecure CORS patterns
  - Verify file structure matches existing agent definitions (accessibility-auditor.md, commit-message-author.md)

- [ ] Create crypto-specialist agent definition file
  - Write YAML frontmatter with name: crypto-specialist, description (cryptographic implementations and key management review), color, model: claude-sonnet-4-0, and tools
  - Write Core Philosophy section explaining approach to cryptographic security and implementation
  - Write Primary Responsibilities section covering cryptographic code review, key management assessment, algorithm selection guidance, and vulnerability detection
  - Write Implementation Guidelines section with secure coding patterns, common cryptographic pitfalls, and best practices for encryption/hashing/key storage
  - Write Testing and Validation section with cryptographic test requirements and security verification steps
  - Write Code Analysis Patterns section with search patterns for detecting insecure cryptographic usage
  - Write Checklist section for systematic cryptographic security audits
  - Verify file structure matches existing agent definitions (accessibility-auditor.md, rust-engineer.md)
  - Save file to /workspace/.claude/agents/crypto-specialist.md

- [ ] Create css-architecture-reviewer agent definition file
  - Create /workspace/.claude/agents/css-architecture-reviewer.md with YAML frontmatter (name: css-architecture-reviewer, description covering CSS organization and specificity expertise, color: purple, model: claude-sonnet-4-0, tools: Read/Grep/Glob)
  - Write agent instruction section covering CSS architecture review (organization patterns, specificity issues, cascade analysis, naming conventions like BEM/SMACSS)
  - Add methodology section for CSS reviews and code analysis patterns for common issues (overly-specific selectors, !important overuse, deep nesting)
  - Add best practices section covering CSS architecture patterns and specificity management
  - Add reporting section for documenting findings with severity levels
  - Verify file follows structure of existing agent files

- [ ] Create database-optimizer agent definition file
  - Create file at `/workspace/.claude/agents/database-optimizer.md` with YAML frontmatter (name: database-optimizer, description, color, model: claude-sonnet-4-0, tools field)
  - Write agent instruction section covering database performance analysis responsibilities
  - Include query performance optimization guidance (execution plans, index usage, join strategies)
  - Document N+1 query problem detection and resolution patterns
  - Specify indexing strategy recommendations (covering indexes, partial indexes, index maintenance)
  - Add database-specific optimization patterns (PostgreSQL, MySQL, SQLite, etc.)
  - Include code analysis patterns for detecting common performance issues
  - Verify file follows existing agent file structure and formatting conventions

- [ ] Create dead-code-detective agent definition file
  - Create file at /workspace/.claude/agents/dead-code-detective.md
  - Add YAML frontmatter with name: "dead-code-detective", description, color, model: "claude-sonnet-4-0", and tools fields
  - Write agent instructions covering purpose (identifying unused code and dead functions), analysis methodology, reporting format, and collaboration guidelines
  - Verify file follows existing agent file structure (frontmatter + instruction sections)

- [ ] Create dependency-auditor agent definition file
  - Write YAML frontmatter with name "dependency-auditor", description, color "purple", model "claude-sonnet-4-0", and tools array
  - Write Core Philosophy section explaining dependency management principles and security importance
  - Write Primary Responsibilities section covering package file reviews, version management, import statement analysis, and security vulnerability detection
  - Write Detection Triggers section specifying when this agent must be included (package file changes, import statement additions/removals, new library introductions)
  - Write Review Methodology section with patterns for detecting dependency issues across common package managers (npm, cargo, pip, go modules)
  - Write Security Analysis section covering vulnerability scanning patterns, outdated dependency detection, and license compliance checks
  - Write Version Management section with guidance on semantic versioning, version pinning, and dependency conflict resolution
  - Write Reporting section defining how to document dependency issues with severity classification
  - Verify file follows established agent file structure and formatting conventions from existing agents

- [ ] Create documentation-reviewer agent definition file
  - Create /workspace/.claude/agents/documentation-reviewer.md with YAML frontmatter (name: documentation-reviewer, description for documentation quality and API documentation validation, color: purple, model: claude-sonnet-4-0, tools: Read/Grep/Glob)
  - Write agent instructions covering documentation quality assessment, API documentation validation, and completeness checks
  - Include detection patterns for common documentation issues (missing docstrings, outdated docs, incomplete parameter documentation, broken examples)
  - Define testing methodology for cross-referencing documentation with code and validating examples
  - Specify when agent must be included (public API changes, documentation file modifications, new modules/classes)
  - Add code analysis patterns using grep for undocumented functions and missing README sections
  - Verify file follows structure pattern from accessibility-auditor.md

- [ ] Create git-hygiene-inspector agent definition file
  - Write YAML frontmatter with name: git-hygiene-inspector, description (reviews commit message quality, commit granularity, and branch strategies), color (select appropriate color), model: claude-sonnet-4-0, and tools: Read, Glob, Grep, Bash
  - Define agent purpose and core responsibilities for reviewing git hygiene (commit message quality, commit granularity, branch strategies)
  - Specify analysis protocol for evaluating commit messages against project guidelines
  - Include evaluation criteria for commit granularity (atomic commits, single responsibility, appropriate scope)
  - Define branch strategy review guidelines (branch naming, merge strategies, PR patterns)
  - Add output format specification for reporting findings with severity levels
  - Specify integration with existing git guidelines in .claude/guidelines/git.md and .claude/guidelines/git-commit-messages.md
  - Validate agent file follows established patterns from existing agents (frontmatter structure, clear responsibilities, specific procedures)

- [ ] Create go-engineer agent definition file at .claude/agents/go-engineer.md
  - Create YAML frontmatter with name "go-engineer", description for Go development expertise, color "cyan", model "claude-sonnet-4-0", and tools list
  - Write comprehensive agent instructions covering Go philosophy (simplicity, explicit error handling, interface-based design)
  - Include sections for error handling patterns, concurrency primitives (goroutines, channels, sync package), testing strategies, and common anti-patterns
  - Add Go-specific quality checklist covering error handling, resource cleanup, race conditions, and idiomatic patterns
  - Verify file follows structure from rust-engineer.md reference (frontmatter, core philosophy, responsibilities, implementation principles, master checklist)
  - Verify agent can serve as fallback for go-nit-checker by covering anti-pattern detection

- [ ] Create go-nit-checker agent definition file
  - Write YAML frontmatter with name (go-nit-checker), description (Expert Go code reviewer specializing in identifying anti-patterns, error handling issues, and unnecessary type conversions. Focuses on Go-specific code smells, idiomatic violations, and performance concerns.), color (rust), model (claude-sonnet-4-0), and tools (Read, Grep, Glob)
  - Write agent instruction section covering core responsibilities for Go-specific nit-checking
  - Define anti-pattern detection capabilities (unnecessary type conversions, improper error handling, goroutine leaks, defer misuse)
  - Document common Go code smells and idiomatic violations to check
  - Include examples of good vs bad patterns for each category
  - Add validation checklist for Go code quality
  - Verify file structure matches existing agent files (rust-engineer.md, accessibility-auditor.md)

- [ ] Create interface-designer agent definition file at .claude/agents/interface-designer.md
  - Write YAML frontmatter with name: "interface-designer", description matching analyst-roster.md purpose (API consistency, versioning, breaking changes), color: "purple", model: "claude-sonnet-4-0", and tools: "Read, Glob, Grep, Bash"
  - Write comprehensive agent instructions covering API design consistency philosophy and primary responsibilities
  - Include implementation best practices for REST/GraphQL conventions and API documentation requirements
  - Verify file follows existing agent structure patterns from accessibility-auditor.md and commit-message-author.md
  - Validate YAML frontmatter parses correctly and all required fields are present

- [ ] Create java-nit-checker agent definition file at .claude/agents/java-nit-checker.md
  - Write YAML frontmatter with name: java-nit-checker, description covering Java anti-patterns and null handling, color: rust, model: claude-sonnet-4-0
  - Write agent instruction section defining role as Java code reviewer specializing in anti-patterns and null handling issues
  - Document common Java anti-patterns to detect (mutable defaults, null handling issues, stream misuse, exception handling problems)
  - Include code examples showing bad patterns and correct alternatives
  - Define testing methodology for identifying anti-patterns through code analysis
  - Verify file structure matches existing agent files (rust-engineer.md, accessibility-auditor.md format)
  - Ensure all content uses ASCII characters (no emojis, Unicode arrows, or special typography)

- [ ] Create javascript-nit-checker agent definition file
  - Add YAML frontmatter with name: "javascript-nit-checker", description: "Identifies JavaScript quirks and anti-patterns", model: "claude-sonnet-4-0", color: "yellow", tools: none
  - Document core mission to validate JavaScript code for quirks and anti-patterns
  - Define validation tasks covering equality operators, variable declarations, mutations, Promise handling, and common JavaScript pitfalls
  - Specify analysis framework for processing JavaScript files and staged changes
  - Define YAML response format with status field (clean/issues/fatal_error) and structured issue reporting
  - Include operating principles for JavaScript-specific validation
  - Add examples demonstrating common JavaScript anti-patterns and proper flagging

- [ ] Create logging-auditor agent definition file
  - Write YAML frontmatter with name "logging-auditor", description, color "purple", model "claude-sonnet-4-0", and empty tools array
  - Write agent purpose section explaining responsibility for reviewing log levels and sensitive data exposure in logs
  - Write core philosophy section on balancing observability with security and privacy
  - Write primary responsibilities section covering log level appropriateness review, sensitive data detection (credentials, PII, tokens), and compliance guidance
  - Write methodology section with code analysis patterns for detecting common logging issues (overly verbose debug in production, hardcoded secrets, unredacted PII)
  - Write best practices section for structured logging, log sanitization, and appropriate log levels
  - Write testing checklist for validating log output doesn't expose sensitive information
  - Verify file structure matches existing agent patterns from accessibility-auditor.md and commit-message-author.md

- [ ] Create markdown-linter agent definition file
  - Write YAML frontmatter with name, description, color, model, and tools fields
  - Add comprehensive agent instruction section covering markdown syntax validation
  - Include markdown formatting rules (headings, lists, links, code blocks)
  - Define linting standards for document structure and consistency
  - Specify validation approach for common markdown anti-patterns
  - Add examples of well-formed vs malformed markdown patterns
  - Verify file follows existing agent template structure from .claude/agents/ directory

- [ ] Create memory-inspector agent definition file
  - Write YAML frontmatter with name, description, color (gray), model (claude-sonnet-4-0), and tools fields
  - Write Core Philosophy section explaining memory analysis principles and approach
  - Write Primary Responsibilities section covering memory usage analysis, leak detection, allocation tracking, and low-level memory operations
  - Write Memory Analysis Methodology section with specific techniques for profiling, identifying leaks, and analyzing allocations
  - Write Implementation Guidance section with best practices for memory-efficient code
  - Write Tool Usage section with grep patterns and analysis commands for memory-related issues
  - Write Testing and Validation section for memory correctness verification
  - Write Reporting section for documenting memory findings and recommendations
  - Verify file saved at /workspace/.claude/agents/memory-inspector.md

- [ ] Create migration-specialist agent definition file at /workspace/.claude/agents/migration-specialist.md
  - Write YAML frontmatter with name, description, color, model, and tools fields
  - Implement agent instructions for data migration and schema evolution review
  - Include methodology for analyzing migration safety, data integrity, and rollback procedures
  - Document patterns for detecting migration anti-patterns (data loss risks, breaking changes, missing rollback strategies)
  - Add validation checklist for migration script quality and compatibility
  - Verify file structure follows established agent definition patterns from existing agents

- [ ] Create mobile-compatibility-tester agent definition file
  - Write YAML frontmatter with name: "mobile-compatibility-tester", description for responsive design and touch target review, color, model (claude-sonnet-4-0), and tools fields
  - Write agent instruction section covering core philosophy for mobile-first design
  - Define primary responsibilities: responsive layout assessment, touch target validation, mobile interaction pattern review
  - Specify mobile testing methodology including viewport testing, touch interaction validation, mobile-specific accessibility
  - Include code analysis patterns for detecting responsive design issues (media queries, viewport meta tags, touch event handlers)
  - Document mobile-specific testing checklist covering touch targets (44px minimum), responsive breakpoints, mobile navigation patterns
  - Add reporting guidelines for mobile compatibility issues with severity classification
  - Verify file structure matches existing agent definition format in /workspace/.claude/agents/

- [ ] Create module-boundary-guard agent definition file
  - Write YAML frontmatter with name "module-boundary-guard", description "Reviews module boundaries and encapsulation", color, model "claude-sonnet-4-0", and tools fields
  - Write agent instructions covering core philosophy of module boundary enforcement
  - Define primary responsibilities for analyzing module coupling, dependency violations, and encapsulation breaches
  - Document review methodology including layer boundary checks, import pattern analysis, and circular dependency detection
  - Specify output format for boundary violation reports with severity levels and remediation guidance
  - Include code analysis patterns for detecting common boundary violations
  - Add comprehensive checklist for systematic module boundary validation
  - Save file to /workspace/.claude/agents/module-boundary-guard.md
  - Verify file structure matches existing agent file patterns (YAML frontmatter followed by markdown content)

- [ ] Create naming-consistency-checker agent definition file
  - Add YAML frontmatter with name, description, color (use "purple"), model (claude-sonnet-4-0), and tools fields
  - Write agent instruction section covering naming convention review responsibilities
  - Define scope: variable names, function names, class names, file names, and module names across codebase
  - Specify review methodology: pattern detection, consistency analysis, convention adherence checks
  - Include common naming patterns to check (camelCase, snake_case, PascalCase, kebab-case)
  - Document language-specific convention validation (JavaScript/TypeScript, Python, Rust, Go, etc.)
  - Add checklist for identifier naming issues (abbreviations, clarity, consistency, domain terminology)
  - Specify reporting format for naming inconsistencies with severity levels and remediation guidance
  - Verify file structure matches existing agent files (frontmatter followed by instructions)

- [ ] Create numerical-methods-analyst agent definition file
  - Create `/workspace/.claude/agents/numerical-methods-analyst.md` with YAML frontmatter (name: numerical-methods-analyst, description covering mathematical computation and numerical analysis, color: blue, model: claude-sonnet-4-0, tools: Read/Glob/Grep/Bash)
  - Add agent instruction section covering mathematical computation review responsibilities (numerical stability analysis, floating-point arithmetic best practices, algorithm correctness verification, computational complexity assessment, precision and accuracy validation)
  - Document when to engage this agent (mathematical operations, scientific computing, numerical algorithms)
  - Verify file follows existing agent file structure (frontmatter, heading, responsibilities sections) matching accessibility-auditor.md pattern
  - Verify file uses ASCII-only characters except where required for proper mathematical notation

- [ ] Create performance-analyst agent definition file
  - Create `/workspace/.claude/agents/performance-analyst.md` with YAML frontmatter (name: performance-analyst, description for performance optimization and bottleneck analysis, color: yellow, model: claude-sonnet-4-0, tools: Read/Glob/Grep/Bash)
  - Write agent instructions covering performance profiling methodology, bottleneck identification, and optimization strategies (algorithmic, memory, I/O, concurrency)
  - Include common performance anti-patterns detection and analysis tools usage patterns
  - Add performance validation checklist and code analysis patterns
  - Verify file follows existing agent file structure with clear sections and practical examples
  - Verify file is valid Markdown with proper YAML frontmatter syntax

- [ ] Create python-nit-checker agent definition file
  - Add YAML frontmatter with name: python-nit-checker, description, color: orange, model: claude-sonnet-4-0, tools: []
  - Write agent instructions covering identification of Python anti-patterns and mutable defaults
  - Include specific patterns to detect (mutable default arguments, late binding closures, bare except clauses, etc.)
  - Provide code examples showing anti-patterns and their corrections
  - Define clear output format for reporting findings with severity levels
  - Specify validation approach using static analysis patterns

- [ ] Create query-security-reviewer agent definition file
  - Add YAML frontmatter with name "query-security-reviewer", description, color "red", model "claude-sonnet-4-0", and empty tools array
  - Write agent purpose section explaining SQL injection risk review and parameterization validation
  - Add responsibility section covering query analysis, parameterized query verification, SQL injection pattern detection, and security recommendations
  - Define methodology section with SQL injection attack vector analysis, query construction review, and input sanitization validation
  - Include code analysis patterns section with example grep/search patterns for unsafe query construction
  - Add security checklist section covering common SQL injection vulnerabilities
  - Provide remediation guidance section with secure query construction examples
  - Write output format section defining report structure with findings, severity levels, and fix recommendations
  - Verify file created at /workspace/.claude/agents/query-security-reviewer.md with complete content and proper formatting

- [ ] Create queue-processor-analyst agent definition file
  - Add YAML frontmatter with name "queue-processor-analyst", description "Reviews message queue patterns", color, model "claude-sonnet-4-0", and tools array
  - Write agent instructions defining role as message queue pattern analyst
  - Document core responsibilities for reviewing queue implementations
  - Specify analysis focus areas: message ordering, delivery semantics, error handling, backpressure, dead letter queues
  - Include common anti-patterns to detect: unbounded queues, missing retry logic, lost messages, blocked consumers
  - Add review checklist covering queue configuration, message serialization, consumer patterns, monitoring
  - Provide guidance on queue technology patterns (RabbitMQ, Kafka, SQS, Redis, etc.)
  - Write file to /workspace/.claude/agents/queue-processor-analyst.md
  - Verify file follows agent definition format from existing examples

- [ ] Create rate-limit-engineer agent definition file
  - Write YAML frontmatter with name: rate-limit-engineer, description: "Expert in rate limiting and throttling strategies for APIs and services. Reviews rate limit implementations, quota management, and request throttling patterns.", color: orange, model: claude-sonnet-4-0
  - Create comprehensive agent instruction section covering rate limiting responsibilities
  - Include sections on rate limiting strategies (token bucket, leaky bucket, sliding window), implementation review patterns, quota management, and common anti-patterns
  - Add code review checklist for identifying rate limiting issues in API endpoints
  - Include examples of proper and improper rate limiting implementations
  - Verify file structure matches existing agent definition format (rust-engineer.md, accessibility-auditor.md)

- [ ] Create regex-validator agent definition file at .claude/agents/regex-validator.md
  - Write YAML frontmatter with name, description, color, model
  - Add comprehensive agent instruction section covering regex patterns, performance analysis, security issues, and best practices
  - Include examples of regex validation and optimization
  - Verify file follows structure from existing agent templates (frontmatter + instructions)
  - Confirm file is properly formatted markdown

- [ ] Create rust-nit-checker agent specification file
  - Add YAML frontmatter with name, description ("Identifies Rust anti-patterns, unnecessary clones, and error handling issues"), color (rust), model (claude-sonnet-4-0), and no tools specification
  - Write agent instruction section defining role as Rust code quality specialist focused on nit-level issues
  - Document detection patterns for Rust anti-patterns (unnecessary clones, `Box<dyn Error>`, improper error handling, panic in production code, missing SAFETY comments on unsafe blocks)
  - Specify output format with severity levels and actionable suggestions
  - Include examples of common Rust nits with good/bad code snippets
  - Verify file follows established agent file structure from rust-engineer.md and commit-message-nit-checker.md

- [ ] Create schema-evolutionist agent definition file
  - Write YAML frontmatter with name: "schema-evolutionist", description: "Reviews database schema compatibility", color: "blue", model: "claude-sonnet-4-0", tools: ["Read", "Glob", "Grep", "Bash"]
  - Write comprehensive agent instruction section covering database schema analysis responsibilities (compatibility checks, migration validation, breaking change detection)
  - Include examples of schema compatibility patterns and anti-patterns
  - Add checklist for schema review (version compatibility, data type changes, constraint modifications, index changes)
  - Verify file follows existing agent structure pattern with YAML frontmatter and markdown instructions
  - Validate YAML frontmatter syntax is correct

- [ ] [Implementation] Create security-auditor agent definition file
  - Write YAML frontmatter with security auditor role and vulnerability detection focus
  - Implement security vulnerability review covering injection attacks and secret exposure
  - Include security testing methodology with vulnerability detection patterns
  - Add comprehensive testing checklists and security issue reporting
  - Document security best practices and anti-patterns with examples
  - Save to /workspace/.claude/agents/security-auditor.md

- [ ] Create session-manager agent definition file at .claude/agents/session-manager.md
  - Write YAML frontmatter with name: "session-manager", description: "Expert in reviewing session storage and timeout handling for backend systems, ensuring secure and efficient session lifecycle management", color: "purple", model: "claude-sonnet-4-0"
  - Write agent instruction section covering core responsibilities (session storage review, timeout validation, session security), methodology (analyzing session configurations, token management, timeout policies), common session anti-patterns to detect, and best practices for session lifecycle management
  - Include code analysis patterns for detecting session-related issues (storage configuration, timeout settings, session fixation vulnerabilities)
  - Verify file structure matches existing agents (accessibility-auditor.md format)
  - Validate YAML frontmatter syntax is correct

- [ ] Create state-management-auditor agent definition file
  - Write YAML frontmatter with name "state-management-auditor", description for frontend state mutations and store patterns, color "blue", model "claude-sonnet-4-0", and tools array with Read, Grep, Glob, Bash
  - Write agent instruction section covering core philosophy on state management best practices
  - Document primary responsibilities including state mutation analysis, store pattern review, and state consistency validation
  - Define testing methodology for state flow analysis, immutability verification, and side effect detection
  - Specify implementation best practices for Redux/Vuex/MobX patterns, React hooks, and state synchronization
  - Include comprehensive testing checklist covering mutation patterns, store structure, async state handling, and state persistence
  - Provide code analysis patterns using grep for detecting state anti-patterns, direct mutations, and missing immutability
  - Document issue severity classification and reporting structure
  - Verify file created at /workspace/.claude/agents/state-management-auditor.md with complete agent specification

- [ ] [Implementation] Create style-conformist agent definition file
  - Write YAML frontmatter with style conformist role and formatting focus
  - Write Core Mission section defining responsibility for code formatting review
  - Write Analysis Framework section covering formatting patterns to check
  - Write Response Format section with YAML-based output structure
  - Write Operating Principles section emphasizing objective validation
  - Include example validations showing well-formatted vs poorly-formatted code
  - Verify file has required YAML frontmatter fields and comprehensive content
  - Save to /workspace/.claude/agents/style-conformist.md

- [ ] [Implementation] Create test-inspector agent definition file
  - Write YAML frontmatter with test inspector role and coverage analysis focus
  - Write comprehensive agent instruction section covering test coverage and quality assessment
  - Include guidance on when test-inspector should be invoked
  - Define core responsibilities: coverage assessment and test pattern validation
  - Add testing methodology guidelines and best practices
  - Include validation checklist for test completeness and quality
  - Verify file follows same structure as existing agents
  - Save to /workspace/.claude/agents/test-inspector.md

- [ ] Create type-safety-inspector agent definition file at .claude/agents/type-safety-inspector.md
  - Write YAML frontmatter with name: "type-safety-inspector", description explaining type safety review focus, color: "blue", model: "claude-sonnet-4-0", tools: "Read, Glob, Grep"
  - Write Core Philosophy section explaining the importance of type safety in strongly-typed languages
  - Write Primary Responsibilities section covering type checking, generic constraints, null safety, type inference issues, and type conversions
  - Write Core Implementation Principles section with patterns for identifying type safety issues across Rust, TypeScript, Haskell, Go, Java, and other strongly-typed languages
  - Write Code Analysis Patterns section with grep/search patterns for detecting common type safety violations (unsafe casts, any/unknown types, null/undefined handling, generic constraint violations)
  - Write Testing and Validation section with checklists for type safety verification
  - Write Reporting Guidelines section explaining how to categorize and report type safety issues
  - Verify file follows structure pattern from existing agent files (accessibility-auditor.md, rust-engineer.md)
