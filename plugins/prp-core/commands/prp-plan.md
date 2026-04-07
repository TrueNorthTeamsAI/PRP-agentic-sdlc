---
description: Create comprehensive feature implementation plan with codebase analysis and research
argument-hint: <feature description | path/to/prd.md>
---

<objective>
Transform "$ARGUMENTS" into a battle-tested implementation plan through systematic codebase exploration, pattern extraction, and strategic research.

**Core Principle**: PLAN ONLY - no code written. Create a context-rich document that enables one-pass implementation success.

**Execution Order**: CODEBASE FIRST, RESEARCH SECOND. Solutions must fit existing patterns before introducing new ones.

**Agent Strategy**: Use specialized agents for intelligence gathering:
- `prp-core:codebase-explorer` — finds WHERE code lives and extracts implementation patterns
- `prp-core:codebase-analyst` — analyzes HOW integration points work and traces data flow
- `prp-core:web-researcher` — strategic web research with citations and gap analysis

Launch codebase agents in parallel first, then research agent second.
</objective>

<context>
CLAUDE.md rules: @CLAUDE.md

**Directory Discovery** (run these to understand project structure):
- List root contents: `ls -la`
- Find main source directories: `ls -la */ 2>/dev/null | head -50`
- Identify project type from config files (package.json, pyproject.toml, Cargo.toml, go.mod, etc.)

**IMPORTANT**: Do NOT assume `src/` exists. Common alternatives include:
- `app/` (Next.js, Rails, Laravel)
- `lib/` (Ruby gems, Elixir)
- `packages/` (monorepos)
- `cmd/`, `internal/`, `pkg/` (Go)
- Root-level source files (Python, scripts)

Discover the actual structure before proceeding.
</context>

<process>

## Phase 0: DETECT - Input Type Resolution

**Determine input type:**

| Input Pattern | Type | Action |
|---------------|------|--------|
| Ends with `.prd.md` | PRD file | Parse PRD, select next phase |
| Ends with `.md` and contains "Implementation Phases" | PRD file | Parse PRD, select next phase |
| File path that exists | Document | Read and extract feature description |
| Free-form text | Description | Use directly as feature input |
| Empty/blank | Conversation | Use conversation context as input |

### If PRD File Detected:

1. **Read the PRD file**
2. **Parse the Implementation Phases table** - find rows with `Status: pending`
3. **Check dependencies** - only select phases whose dependencies are `complete`
4. **Select the next actionable phase:**
   - First pending phase with all dependencies complete
   - If multiple candidates with same dependencies, note parallelism opportunity

4. **Extract phase context:**
   ```
   SOURCE_PRD: {path to the PRD file}
   GIT_STRATEGY: {from project's CLAUDE.md "## Git Strategy" section, default "main-only" if not specified}
   BASE_BRANCH: {from project's CLAUDE.md "## Git Strategy" section, default "main" if not specified}
   PHASE: {phase number and name}
   GOAL: {from phase details}
   SCOPE: {from phase details}
   SUCCESS SIGNAL: {from phase details}
   PRD CONTEXT: {problem statement, user, hypothesis from PRD}
   ```

   **IMPORTANT**: Carry `SOURCE_PRD` and `PHASE` into the plan's Metadata table (Phase 6) as `Source PRD` and `PRD Phase` fields.

5. **Report selection to user:**
   ```
   PRD: {prd file path}
   Selected Phase: #{number} - {name}

   {If parallel phases available:}
   Note: Phase {X} can also run in parallel (in separate worktree).

   Proceeding with Phase #{number}...
   ```

### If Free-form or Conversation Context:

- Proceed directly to Phase 1 with the input as feature description

**PHASE_0_CHECKPOINT:**
- [ ] Input type determined
- [ ] If PRD: next phase selected and dependencies verified
- [ ] Feature description ready for Phase 1

---

## Phase 1: PARSE - Feature Understanding

**EXTRACT from input:**

- Core problem being solved
- User value and business impact
- Feature type: NEW_CAPABILITY | ENHANCEMENT | REFACTOR | BUG_FIX
- Complexity: LOW | MEDIUM | HIGH
- Affected systems list

**FORMULATE user story:**

```
As a <user type>
I want to <action/goal>
So that <benefit/value>
```

**PHASE_1_CHECKPOINT:**

- [ ] Problem statement is specific and testable
- [ ] User story follows correct format
- [ ] Complexity assessment has rationale
- [ ] Affected systems identified

**GATE**: If requirements are AMBIGUOUS → STOP and ASK user for clarification before proceeding.

---

## Phase 1.5: CONTEXT - Load External Context (Automatic)

**This phase runs silently. No user prompts.**

Check if `context-map.md` exists in the project (search current dir, then walk up parent directories).

**If found:**

1. Parse the context map entries
2. Match entries against the feature description, affected systems, and key terms from Phase 1
3. If matches found: resolve and read sources silently using the `context-read` skill logic (see `plugins/prp-core/skills/context-read/SKILL.md` for resolution rules)
4. Capture loaded context for use in Phase 2 and beyond — treat as additional input alongside codebase findings
5. Record which sources were loaded (label, type, path) for inclusion in the plan's "Context Sources Loaded" section

**If not found or no matches:** Proceed normally. This phase is optional — missing context is never a blocker.

**PHASE_1.5_CHECKPOINT:**
- [ ] context-map.md checked
- [ ] Matching sources loaded (or confirmed none available)
- [ ] Loaded context captured for downstream phases

---

## Phase 2: EXPLORE - Codebase Intelligence

**CRITICAL: Launch two specialized agents in parallel using multiple Task tool calls in a single message.**

### Agent 1: `prp-core:codebase-explorer`

Finds WHERE code lives and extracts implementation patterns.

Use Task tool with `subagent_type="prp-core:codebase-explorer"`:

```
Find all code relevant to implementing: [feature description].

LOCATE:
1. Similar implementations - analogous features with file:line references
2. Naming conventions - actual examples of function/class/file naming
3. Error handling patterns - how errors are created, thrown, caught
4. Logging patterns - logger usage, message formats
5. Type definitions - relevant interfaces and types
6. Test patterns - test file structure, assertion styles, test file locations
7. Configuration - relevant config files and settings
8. Dependencies - relevant libraries already in use
9. Testing config - check CLAUDE.md for ## Testing or ## E2E Testing sections, check PRD's ## Testing Strategy if available

Categorize findings by purpose (implementation, tests, config, types, docs).
Return ACTUAL code snippets from codebase, not generic examples.
```

### Agent 2: `prp-core:codebase-analyst`

Analyzes HOW integration points work and traces data flow.

Use Task tool with `subagent_type="prp-core:codebase-analyst"`:

```
Analyze the implementation details relevant to: [feature description].

TRACE:
1. Entry points - where new code will connect to existing code
2. Data flow - how data moves through related components
3. State changes - side effects in related functions
4. Contracts - interfaces and expectations between components
5. Patterns in use - design patterns and architectural decisions

Document what exists with precise file:line references. No suggestions or improvements.
```

### Merge Agent Results

Combine findings from both agents into a unified discovery table:

| Category | File:Lines                                  | Pattern Description  | Code Snippet                              |
| -------- | ------------------------------------------- | -------------------- | ----------------------------------------- |
| NAMING   | `src/features/X/service.ts:10-15`           | camelCase functions  | `export function createThing()`           |
| ERRORS   | `src/features/X/errors.ts:5-20`             | Custom error classes | `class ThingNotFoundError`                |
| LOGGING  | `src/core/logging/index.ts:1-10`            | getLogger pattern    | `const logger = getLogger("domain")`      |
| TESTS    | `src/features/X/tests/service.test.ts:1-30` | describe/it blocks   | `describe("service", () => {`             |
| TYPES    | `src/features/X/models.ts:1-20`             | Drizzle inference    | `type Thing = typeof things.$inferSelect` |
| FLOW     | `src/features/X/service.ts:40-60`           | Data transformation  | `input → validate → persist → respond`    |

**PHASE_2_CHECKPOINT:**

- [ ] Both agents (`prp-core:codebase-explorer` and `prp-core:codebase-analyst`) launched in parallel and completed
- [ ] At least 3 similar implementations found with file:line refs
- [ ] Code snippets are ACTUAL (copy-pasted from codebase, not invented)
- [ ] Integration points mapped with data flow traces
- [ ] Dependencies cataloged with versions from package.json

---

## Phase 3: RESEARCH - External Documentation

**ONLY AFTER Phase 2 is complete** - solutions must fit existing codebase patterns first.

**Use Task tool with `subagent_type="prp-core:web-researcher"`:**

```
Research external documentation relevant to implementing: [feature description].

FIND:
1. Official documentation for involved libraries (match versions from package.json: [list relevant deps and versions])
2. Known gotchas, breaking changes, deprecations for these versions
3. Security considerations and best practices
4. Performance optimization patterns

VERSION CONSTRAINTS:
- [library]: v{version} (from package.json)
- [library]: v{version}

Return findings with:
- Direct links to specific doc sections (not just homepages)
- Key insights that affect implementation
- Gotchas with mitigation strategies
- Any conflicts between docs and existing codebase patterns found in Phase 2
```

**FORMAT the agent's findings into plan references:**

```markdown
- [Library Docs v{version}](https://url#specific-section)
  - KEY_INSIGHT: {what we learned that affects implementation}
  - APPLIES_TO: {which task/file this affects}
  - GOTCHA: {potential pitfall and how to avoid}
```

**PHASE_3_CHECKPOINT:**

- [ ] `prp-core:web-researcher` agent launched and completed
- [ ] Documentation versions match package.json
- [ ] URLs include specific section anchors (not just homepage)
- [ ] Gotchas documented with mitigation strategies
- [ ] No conflicting patterns between external docs and existing codebase

---

## Phase 4: DESIGN - UX Transformation

**CREATE ASCII diagrams showing user experience before and after:**

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              BEFORE STATE                                      ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   ┌─────────────┐         ┌─────────────┐         ┌─────────────┐            ║
║   │   Screen/   │ ──────► │   Action    │ ──────► │   Result    │            ║
║   │  Component  │         │   Current   │         │   Current   │            ║
║   └─────────────┘         └─────────────┘         └─────────────┘            ║
║                                                                               ║
║   USER_FLOW: [describe current step-by-step experience]                       ║
║   PAIN_POINT: [what's missing, broken, or inefficient]                        ║
║   DATA_FLOW: [how data moves through the system currently]                    ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════════════════════╗
║                               AFTER STATE                                      ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   ┌─────────────┐         ┌─────────────┐         ┌─────────────┐            ║
║   │   Screen/   │ ──────► │   Action    │ ──────► │   Result    │            ║
║   │  Component  │         │    NEW      │         │    NEW      │            ║
║   └─────────────┘         └─────────────┘         └─────────────┘            ║
║                                   │                                           ║
║                                   ▼                                           ║
║                          ┌─────────────┐                                      ║
║                          │ NEW_FEATURE │  ◄── [new capability added]          ║
║                          └─────────────┘                                      ║
║                                                                               ║
║   USER_FLOW: [describe new step-by-step experience]                           ║
║   VALUE_ADD: [what user gains from this change]                               ║
║   DATA_FLOW: [how data moves through the system after]                        ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

**DOCUMENT interaction changes:**

| Location        | Before          | After       | User_Action | Impact        |
| --------------- | --------------- | ----------- | ----------- | ------------- |
| `/route`        | State A         | State B     | Click X     | Can now Y     |
| `Component.tsx` | Missing feature | Has feature | Input Z     | Gets result W |

**PHASE_4_CHECKPOINT:**

- [ ] Before state accurately reflects current system behavior
- [ ] After state shows ALL new capabilities
- [ ] Data flows are traceable from input to output
- [ ] User value is explicit and measurable

---

## Phase 4.5: JOURNEYS - User Journey Documents

**For features with user-facing functionality**, create or update user journey documents.

### Steps:

1. **Scan existing journeys**: Check `.claude/user-journeys/` for existing journey files
2. **Classify impact**: For each existing journey, determine if it is:
   - **UNAFFECTED** — no changes needed
   - **MODIFIED** — steps or expected results change
   - **BROKEN** — journey will no longer work as written
3. **Create new journeys**: For each new user-facing flow introduced by this feature, create a journey file at `.claude/user-journeys/{journey-name}.md` using the template at `plugins/prp-core/templates/user-journey.md`
4. **Update modified journeys**: Edit existing journey files in place to reflect changes
5. **Create directory if needed**: `mkdir -p .claude/user-journeys`

### Journey Content Guidelines:

- Each journey describes **what the user does** — not how to start infrastructure
- Steps must be concrete: exact commands, URLs, UI actions
- Expected results must be specific: response codes, output text, UI state
- Include a **Validation Script** (bash, exit 0 = PASS) for projects WITHOUT an e2e test framework
- For projects WITH an e2e framework, omit the Validation Script — e2e test files will be generated during implementation

### Classify Journeys as Automated or Manual:

- **Automated**: Can be fully exercised by a script or e2e test (API calls, CLI commands, deterministic UI flows)
- **Manual**: Requires human judgment (visual design review, UX feel, complex multi-device flows) — non-blocking

**PHASE_4.5_CHECKPOINT:**

- [ ] Existing journeys scanned and classified
- [ ] New journey files created for new user-facing flows
- [ ] Modified journeys updated in place
- [ ] Each journey has concrete steps with expected results
- [ ] Journeys classified as automated or manual

---

## Phase 5: ARCHITECT - Strategic Design

**For complex features with multiple integration points**, use `prp-core:codebase-analyst` to trace how existing architecture works at the integration points identified in Phase 2:

Use Task tool with `subagent_type="prp-core:codebase-analyst"`:

```
Analyze the architecture around these integration points for: [feature description].

INTEGRATION POINTS (from Phase 2):
- [entry point 1 from explorer/analyst findings]
- [entry point 2]

ANALYZE:
1. How data flows through each integration point
2. What contracts exist between components
3. What side effects occur at each stage
4. What error handling patterns are in place

Document what exists with precise file:line references. No suggestions.
```

**Then ANALYZE deeply (use extended thinking if needed):**

- ARCHITECTURE_FIT: How does this integrate with the existing architecture?
- EXECUTION_ORDER: What must happen first → second → third?
- FAILURE_MODES: Edge cases, race conditions, error scenarios?
- PERFORMANCE: Will this scale? Database queries optimized?
- SECURITY: Attack vectors? Data exposure risks? Auth/authz?
- MAINTAINABILITY: Will future devs understand this code?

**DECIDE and document:**

```markdown
APPROACH_CHOSEN: [description]
RATIONALE: [why this over alternatives - reference codebase patterns]

ALTERNATIVES_REJECTED:

- [Alternative 1]: Rejected because [specific reason]
- [Alternative 2]: Rejected because [specific reason]

NOT_BUILDING (explicit scope limits):

- [Item 1 - explicitly out of scope and why]
- [Item 2 - explicitly out of scope and why]
```

**PHASE_5_CHECKPOINT:**

- [ ] Approach aligns with existing architecture and patterns
- [ ] Dependencies ordered correctly (types → repository → service → routes)
- [ ] Edge cases identified with specific mitigation strategies
- [ ] Scope boundaries are explicit and justified

---

## Phase 6: GENERATE - Implementation Plan File

### 6.0 Numbering and Filename

1. **Determine the prefix** from the parent PRD's filename (if input was a PRD file):
   - If PRD filename starts with `V` (e.g., `V001-PRD003-auth.prd.md`): prefix is `V001-PRD003`
   - If PRD filename starts with `PRD` (e.g., `PRD004-search.prd.md`): prefix is `PRD004`
   - If PRD filename has no number prefix (legacy): use `PRD000` as prefix (backward compatibility)
   - If input was free-form text (no PRD): use `PRD000` as prefix

2. **Assign plan number**:
   1. Read `.claude/PRPs/.counters.json` (use Read tool). If the file does not exist, treat it as `{"vision": 0, "prd": 0, "plan": 0}`.
   2. Increment the `plan` counter by 1.
   3. Write updated counters back to `.claude/PRPs/.counters.json` (use Write tool).
   4. Zero-pad the new number to 3 digits (e.g., `5` → `005`).
   5. If the Read tool returns a parse error, warn the user and ask them to check the file manually. Do not overwrite a corrupted file.

3. **Generate filename**: `{prefix}-P{NNN}-{kebab-case-feature-name}.plan.md`
   - Example: `V001-PRD003-P005-auth-implementation.plan.md`
   - Example: `PRD004-P006-search-indexing.plan.md`

**OUTPUT_PATH**: `.claude/PRPs/plans/{numbered-filename}`

Create directory if needed: `mkdir -p .claude/PRPs/plans`

**PLAN_STRUCTURE** (the template to fill and save):

```markdown
# Feature: {Feature Name}

## Summary

{One paragraph: What we're building and high-level approach}

## User Story

As a {user type}
I want to {action}
So that {benefit}

## Problem Statement

{Specific problem this solves - must be testable}

## Solution Statement

{How we're solving it - architecture overview}

## Metadata

| Field            | Value                                             |
| ---------------- | ------------------------------------------------- |
| Type             | NEW_CAPABILITY / ENHANCEMENT / REFACTOR / BUG_FIX |
| Complexity       | LOW / MEDIUM / HIGH                               |
| Systems Affected | {comma-separated list}                            |
| Dependencies     | {external libs/services with versions}            |
| Estimated Tasks  | {count}                                           |
| Source PRD       | {prd-file-path or N/A}                            |
| PRD Phase        | {phase number and name or N/A}                    |
---

## UX Design

### Before State
```

{ASCII diagram - current user experience with data flows}

```

### After State
```

{ASCII diagram - new user experience with data flows}

````

### Interaction Changes
| Location | Before | After | User Impact |
|----------|--------|-------|-------------|
| {path/component} | {old behavior} | {new behavior} | {what changes for user} |

---

## User Journeys

| Journey File | Impact | Description |
|-------------|--------|-------------|
| `.claude/user-journeys/{name}.md` | NEW / MODIFIED / VERIFY | {what this journey tests} |

**Automated** (e2e tests or validation scripts — blocking):
- `.claude/user-journeys/{name}.md` — {description}

**Manual** (require human testing — non-blocking):
- `.claude/user-journeys/{name}.md` — {description}

---

## How to Execute

<!--
  Infrastructure setup for running and validating the feature.
  Sourced from CLAUDE.md dev server commands, project docs, etc.
  Journeys and e2e tests assume this setup is already done.
-->

### Start Services
```bash
{startup commands — e.g., npm run dev, docker compose up -d}
```

### Seed Data / Reset State
```bash
{database reset, seed scripts, clear caches — if applicable}
```

### Verify Ready
```bash
{health check or readiness verification — e.g., curl http://localhost:3000/health}
```

### Teardown
```bash
{stop services, cleanup — e.g., docker compose down}
```

---

## Mandatory Reading

**CRITICAL: Implementation agent MUST read these files before starting any task:**

| Priority | File | Lines | Why Read This |
|----------|------|-------|---------------|
| P0 | `path/to/critical.ts` | 10-50 | Pattern to MIRROR exactly |
| P1 | `path/to/types.ts` | 1-30 | Types to IMPORT |
| P2 | `path/to/test.ts` | all | Test pattern to FOLLOW |

**External Documentation:**
| Source | Section | Why Needed |
|--------|---------|------------|
| [Lib Docs v{version}](url#anchor) | {section name} | {specific reason} |

**Context Sources Loaded** (from `context-map.md` via Phase 1.5):
| Source | Type | Section | Key Insight |
|--------|------|---------|-------------|
| {Label} | `{type}` | {section} | {What was learned that affects implementation} |

_If no context-map.md exists or no matches were found, omit this table._

---

## Patterns to Mirror

**NAMING_CONVENTION:**
```typescript
// SOURCE: src/features/example/service.ts:10-15
// COPY THIS PATTERN:
{actual code snippet from codebase}
````

**ERROR_HANDLING:**

```typescript
// SOURCE: src/features/example/errors.ts:5-20
// COPY THIS PATTERN:
{actual code snippet from codebase}
```

**LOGGING_PATTERN:**

```typescript
// SOURCE: src/features/example/service.ts:25-30
// COPY THIS PATTERN:
{actual code snippet from codebase}
```

**REPOSITORY_PATTERN:**

```typescript
// SOURCE: src/features/example/repository.ts:10-40
// COPY THIS PATTERN:
{actual code snippet from codebase}
```

**SERVICE_PATTERN:**

```typescript
// SOURCE: src/features/example/service.ts:40-80
// COPY THIS PATTERN:
{actual code snippet from codebase}
```

**TEST_STRUCTURE:**

```typescript
// SOURCE: src/features/example/tests/service.test.ts:1-25
// COPY THIS PATTERN:
{actual code snippet from codebase}
```

---

## Files to Change

| File                             | Action | Justification                            |
| -------------------------------- | ------ | ---------------------------------------- |
| `src/features/new/models.ts`     | CREATE | Type definitions - re-export from schema |
| `src/features/new/schemas.ts`    | CREATE | Zod validation schemas                   |
| `src/features/new/errors.ts`     | CREATE | Feature-specific errors                  |
| `src/features/new/repository.ts` | CREATE | Database operations                      |
| `src/features/new/service.ts`    | CREATE | Business logic                           |
| `src/features/new/index.ts`      | CREATE | Public API exports                       |
| `src/core/database/schema.ts`    | UPDATE | Add table definition                     |

---

## NOT Building (Scope Limits)

Explicit exclusions to prevent scope creep:

- {Item 1 - explicitly out of scope and why}
- {Item 2 - explicitly out of scope and why}

---

## Step-by-Step Tasks

Execute in order. Each task is atomic and independently verifiable.

### Task 1: CREATE `src/core/database/schema.ts` (update)

- **ACTION**: ADD table definition to schema
- **IMPLEMENT**: {specific columns, types, constraints}
- **MIRROR**: `src/core/database/schema.ts:XX-YY` - follow existing table pattern
- **IMPORTS**: `import { pgTable, text, timestamp } from "drizzle-orm/pg-core"`
- **GOTCHA**: {known issue to avoid, e.g., "use uuid for id, not serial"}
- **VALIDATE**: `npx tsc --noEmit` - types must compile

### Task 2: CREATE `src/features/new/models.ts`

- **ACTION**: CREATE type definitions file
- **IMPLEMENT**: Re-export table, define inferred types
- **MIRROR**: `src/features/projects/models.ts:1-10`
- **IMPORTS**: `import { things } from "@/core/database/schema"`
- **TYPES**: `type Thing = typeof things.$inferSelect`
- **GOTCHA**: Use `$inferSelect` for read types, `$inferInsert` for write
- **VALIDATE**: `npx tsc --noEmit`

### Task 3: CREATE `src/features/new/schemas.ts`

- **ACTION**: CREATE Zod validation schemas
- **IMPLEMENT**: CreateThingSchema, UpdateThingSchema
- **MIRROR**: `src/features/projects/schemas.ts:1-30`
- **IMPORTS**: `import { z } from "zod/v4"` (note: zod/v4 not zod)
- **GOTCHA**: z.record requires two args in v4
- **VALIDATE**: `npx tsc --noEmit`

### Task 4: CREATE `src/features/new/errors.ts`

- **ACTION**: CREATE feature-specific error classes
- **IMPLEMENT**: ThingNotFoundError, ThingAccessDeniedError
- **MIRROR**: `src/features/projects/errors.ts:1-40`
- **PATTERN**: Extend base Error, include code and statusCode
- **VALIDATE**: `npx tsc --noEmit`

### Task 5: CREATE `src/features/new/repository.ts`

- **ACTION**: CREATE database operations
- **IMPLEMENT**: findById, findByUserId, create, update, delete
- **MIRROR**: `src/features/projects/repository.ts:1-60`
- **IMPORTS**: `import { db } from "@/core/database/client"`
- **GOTCHA**: Use `results[0]` pattern, not `.first()` - check noUncheckedIndexedAccess
- **VALIDATE**: `npx tsc --noEmit`

### Task 6: CREATE `src/features/new/service.ts`

- **ACTION**: CREATE business logic layer
- **IMPLEMENT**: createThing, getThing, updateThing, deleteThing
- **MIRROR**: `src/features/projects/service.ts:1-80`
- **PATTERN**: Use repository, add logging, throw custom errors
- **IMPORTS**: `import { getLogger } from "@/core/logging"`
- **VALIDATE**: `{type-check-cmd} && {lint-cmd}`

### Task 7: CREATE `{source-dir}/features/new/index.ts`

- **ACTION**: CREATE public API exports
- **IMPLEMENT**: Export types, schemas, errors, service functions
- **MIRROR**: `{source-dir}/features/{example}/index.ts:1-20`
- **PATTERN**: Named exports only, hide repository (internal)
- **VALIDATE**: `{type-check-cmd}`

### Task 8: CREATE `{source-dir}/features/new/tests/service.test.ts`

- **ACTION**: CREATE unit tests for service
- **IMPLEMENT**: Test each service function, happy path + error cases
- **MIRROR**: `{source-dir}/features/{example}/tests/service.test.ts:1-100`
- **PATTERN**: Use project's test framework (jest, vitest, bun:test, pytest, etc.)
- **VALIDATE**: `{test-cmd} {path-to-tests}`

---

## Testing Strategy

### Unit Tests to Write

| Test File                                | Test Cases                 | Validates      |
| ---------------------------------------- | -------------------------- | -------------- |
| `src/features/new/tests/schemas.test.ts` | valid input, invalid input | Zod schemas    |
| `src/features/new/tests/errors.test.ts`  | error properties           | Error classes  |
| `src/features/new/tests/service.test.ts` | CRUD ops, access control   | Business logic |

### E2E Tests to Write

<!--
  Only if project has e2e framework (from CLAUDE.md / PRD Testing Strategy).
  Otherwise journey Validation Scripts serve as e2e coverage.
-->

| Test File | Journey Source | Test Cases |
|-----------|---------------|------------|
| `e2e/{name}.spec.ts` | `.claude/user-journeys/{name}.md` | {scenarios derived from journey steps} |

### Edge Cases Checklist

- [ ] Empty string inputs
- [ ] Missing required fields
- [ ] Unauthorized access attempts
- [ ] Not found scenarios
- [ ] Duplicate creation attempts
- [ ] {feature-specific edge case}

---

## Validation Commands

**IMPORTANT**: Replace these placeholders with actual commands from the project's package.json/config.

### Level 1: STATIC_ANALYSIS

```bash
{runner} run lint && {runner} run type-check
# Examples: npm run lint, pnpm lint, ruff check . && mypy ., cargo clippy
```

**EXPECT**: Exit 0, no errors or warnings

### Level 2: UNIT_TESTS

```bash
{runner} test {path/to/feature/tests}
# Examples: npm test, pytest tests/, cargo test, go test ./...
```

**EXPECT**: All tests pass, coverage >= 80%

### Level 3: FULL_SUITE

```bash
{runner} test && {runner} run build
# Examples: npm test && npm run build, cargo test && cargo build
```

**EXPECT**: All tests pass, build succeeds

### Level 4: DATABASE_VALIDATION (if schema changes)

Use Supabase MCP to verify:

- [ ] Table created with correct columns
- [ ] RLS policies applied
- [ ] Indexes created

### Level 5: USER_JOURNEY_VALIDATION

Run after Levels 1-3 pass. Uses "How to Execute" for setup/teardown.

**If e2e framework configured** (from CLAUDE.md `## Testing` section):
```bash
{e2e run command from CLAUDE.md, e.g., npx playwright test, npx cypress run}
```

**If no e2e framework** (validation scripts only):
1. Run setup from "How to Execute" (Start Services → Seed Data → Verify Ready)
2. For each journey with a Validation Script: extract and execute the script
3. Run teardown from "How to Execute"

**EXPECT**: All e2e tests or validation scripts pass (exit 0). Manual journeys listed in report but non-blocking.

### Level 6: MANUAL_VALIDATION

{Step-by-step manual testing specific to this feature}

---

## Acceptance Criteria

- [ ] All specified functionality implemented per user story
- [ ] Level 1-3 validation commands pass with exit 0
- [ ] Unit tests cover >= 80% of new code
- [ ] Code mirrors existing patterns exactly (naming, structure, logging)
- [ ] No regressions in existing tests
- [ ] UX matches "After State" diagram
- [ ] User journeys created/updated for new user-facing flows
- [ ] E2E tests or validation scripts defined for automated journeys

---

## Completion Checklist

- [ ] All tasks completed in dependency order
- [ ] Each task validated immediately after completion
- [ ] Level 1: Static analysis (lint + type-check) passes
- [ ] Level 2: Unit tests pass
- [ ] Level 3: Full test suite + build succeeds
- [ ] Level 4: Database validation passes (if applicable)
- [ ] Level 5: User journey / e2e validation passes (if applicable)
- [ ] User journey files created/updated in `.claude/user-journeys/`
- [ ] All acceptance criteria met

---

## Risks and Mitigations

| Risk               | Likelihood   | Impact       | Mitigation                              |
| ------------------ | ------------ | ------------ | --------------------------------------- |
| {Risk description} | LOW/MED/HIGH | LOW/MED/HIGH | {Specific prevention/handling strategy} |

---

## Notes

{Additional context, design decisions, trade-offs, future considerations}

````

</process>

<output>
**OUTPUT_FILE**: `.claude/PRPs/plans/{numbered-filename}` (e.g., `V001-PRD003-P005-auth-implementation.plan.md`)

**If input was from PRD file**, also update the PRD:

1. **Update phase status** in the Implementation Phases table:
   - Change the phase's Status from `pending` to `in-progress`
   - Add the plan file path to the PRP Plan column

2. **Edit the PRD file** with these changes

**Git Operations** (after writing the plan file and updating the PRD):

**Read git strategy**: Read the project's `CLAUDE.md` and find the `## Git Strategy` section. Extract the value after `Strategy:` and `Base Branch:`. Defaults: strategy=`main-only`, base branch=`main`.

- **`none`**: Skip all git operations.
- **`main-only`**: Commit on current branch:
  ```bash
  git add .claude/PRPs/plans/{numbered-filename} .claude/PRPs/.counters.json {prd-file-path if updated}
  git commit -m "docs: add implementation plan {plan-id} for {feature-name}"
  ```
- **`branch-per-prd`**: Verify on the PRD branch. If not, check it out. Then commit:
  ```bash
  # If vision-linked: feat/{vision-id}/{prd-id}-{prd-kebab-name}
  # If standalone:    feat/{prd-id}-{prd-kebab-name}
  git checkout feat/{...}  # if not already on it
  git add .claude/PRPs/plans/{numbered-filename} .claude/PRPs/.counters.json {prd-file-path if updated}
  git commit -m "docs: add implementation plan {plan-id} for {feature-name}"
  ```
- **`branch-per-phase`**: Create a phase branch from the PRD branch (or base branch if no PRD branch) using hierarchical naming, and commit:
  ```bash
  # If vision-linked: feat/{vision-id}/{prd-id}/{plan-id}-{phase-kebab}
  # If standalone:    feat/{prd-id}/{plan-id}-{phase-kebab}
  git checkout -b feat/{...}
  git add .claude/PRPs/plans/{numbered-filename} .claude/PRPs/.counters.json {prd-file-path if updated}
  git commit -m "docs: add implementation plan {plan-id} for {feature-name}"
  ```

**REPORT_TO_USER** (display after creating plan):

```markdown
## Plan Created

**File**: `.claude/PRPs/plans/{numbered-filename}`

{If from PRD:}
**Source PRD**: `{prd-file-path}`
**Phase**: #{number} - {phase name}
**PRD Updated**: Status set to `in-progress`, plan linked

{If parallel phases available:}
**Parallel Opportunity**: Phase {X} can run concurrently in a separate worktree.
To start: `git worktree add -b phase-{X} ../project-phase-{X} && cd ../project-phase-{X} && /prp-plan {prd-path}`

**Summary**: {2-3 sentence feature overview}

**Complexity**: {LOW/MEDIUM/HIGH} - {brief rationale}

**Scope**:
- {N} files to CREATE
- {M} files to UPDATE
- {K} total tasks

**Key Patterns Discovered**:
- {Pattern 1 from codebase-explorer/analyst with file:line}
- {Pattern 2 from codebase-explorer/analyst with file:line}

**External Research**:
- {Key doc 1 with version}
- {Key doc 2 with version}

**UX Transformation**:
- BEFORE: {one-line current state}
- AFTER: {one-line new state}

**User Journeys**:
- {N} new, {M} modified, {K} automated, {J} manual

**Risks**:
- {Primary risk}: {mitigation}

**Confidence Score**: {1-10}/10 for one-pass implementation success
- {Rationale for score}

**Next Step**: To execute, run: `/prp-implement .claude/PRPs/plans/{numbered-filename}`
````

</output>

<verification>
**FINAL_VALIDATION before saving plan:**

**CONTEXT_COMPLETENESS:**

- [ ] All patterns from `prp-core:codebase-explorer` and `prp-core:codebase-analyst` documented with file:line references
- [ ] External docs versioned to match package.json
- [ ] Integration points mapped with specific file paths
- [ ] Gotchas captured with mitigation strategies
- [ ] Every task has at least one executable validation command

**IMPLEMENTATION_READINESS:**

- [ ] Tasks ordered by dependency (can execute top-to-bottom)
- [ ] Each task is atomic and independently testable
- [ ] No placeholders - all content is specific and actionable
- [ ] Pattern references include actual code snippets (copy-pasted, not invented)

**PATTERN_FAITHFULNESS:**

- [ ] Every new file mirrors existing codebase style exactly
- [ ] No unnecessary abstractions introduced
- [ ] Naming follows discovered conventions
- [ ] Error/logging patterns match existing
- [ ] Test structure matches existing tests

**VALIDATION_COVERAGE:**

- [ ] Every task has executable validation command
- [ ] All 6 validation levels defined where applicable
- [ ] Edge cases enumerated with test plans
- [ ] User journeys created for user-facing flows
- [ ] E2E tests table populated (if e2e framework configured)
- [ ] How to Execute section has start/seed/ready/teardown commands

**UX_CLARITY:**

- [ ] Before/After ASCII diagrams are detailed and accurate
- [ ] Data flows are traceable
- [ ] User value is explicit and measurable

**NO_PRIOR_KNOWLEDGE_TEST**: Could an agent unfamiliar with this codebase implement using ONLY the plan?
</verification>

<success_criteria>
**CONTEXT_COMPLETE**: All patterns, gotchas, integration points documented from actual codebase via `prp-core:codebase-explorer` and `prp-core:codebase-analyst` agents
**IMPLEMENTATION_READY**: Tasks executable top-to-bottom without questions, research, or clarification
**PATTERN_FAITHFUL**: Every new file mirrors existing codebase style exactly
**VALIDATION_DEFINED**: Every task has executable verification command
**UX_DOCUMENTED**: Before/After transformation is visually clear with data flows
**JOURNEYS_DEFINED**: User journey files created for new user-facing flows with concrete steps
**ONE_PASS_TARGET**: Confidence score 8+ indicates high likelihood of first-attempt success
</success_criteria>
