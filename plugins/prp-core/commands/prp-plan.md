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

## Phase 0: PRE-FLIGHT — Artifact Path Migration

Before any artifact read or write, probe the working tree:

| State | Condition | Action |
|-------|-----------|--------|
| FRESH | Neither `.claude/PRPs/` nor `PRPs/` exists | Continue silently |
| V4    | `PRPs/` exists, `.claude/PRPs/` does not | Continue silently |
| V3    | `.claude/PRPs/` exists, `PRPs/` does not | Auto-migrate, then continue |
| BOTH  | Both directories exist | STOP with abort message |

### V3 → V4 Migration

1. Detect git repo: run `git rev-parse --is-inside-work-tree`. If exit 0 → git repo; else plain.
2. **Git repo path**: from repo root (`git rev-parse --show-toplevel`), run `git mv .claude/PRPs PRPs`. The rename is staged but not committed; the next command-driven `git commit` will include it.
3. **Non-git path**: run `mv .claude/PRPs PRPs` (Bash) or `Move-Item .claude/PRPs PRPs` (PowerShell).
4. Print exactly one line:
   `→ Migrated PRP artifacts: .claude/PRPs/ → PRPs/ (git mv staged for next commit)`
   (Drop "git mv staged" suffix if non-git.)
5. Continue with the command's normal flow.

### BOTH State Abort

Print the following and STOP:

```
STOP: PRP artifact directory is in a partial-migration state.

Both `.claude/PRPs/` and `PRPs/` exist. The migration shim cannot decide which is authoritative.

Resolve by choosing one:
  # If PRPs/ has the latest work:
  rm -rf .claude/PRPs

  # If .claude/PRPs/ has the latest work:
  rm -rf PRPs
  git mv .claude/PRPs PRPs

Then re-run the command.
```

### Detection Implementation Notes

- Use `test -d .claude/PRPs` and `test -d PRPs` (Bash) or `Test-Path .claude/PRPs` and `Test-Path PRPs` (PowerShell). Prefer `test -d` since the project workspace is cross-platform.
- The shim is idempotent: running it twice on the same tree always reaches the same state.
- The shim does NOT touch `.claude/rules/`, `.claude/settings.local.json`, or any other `.claude/*` content.
- Run `git mv` from repo root (`git rev-parse --show-toplevel`) so invoking from a subdirectory still works.

<!-- NOTE: This `## Phase 0: PRE-FLIGHT` lives outside the `<process>` block intentionally.
     The `<process>` block below also opens with a `## Phase 0: DETECT` — that is the
     command's first work phase, distinct from this pre-flight shim. -->

<process>

## Phase 0: DETECT - Input Type Resolution

**Parse flags first:**

- **`--skip-schema-check`**: If present, set `SKIP_SCHEMA_CHECK=true` and strip the flag from `$ARGUMENTS`. Otherwise, `SKIP_SCHEMA_CHECK=false`. This flag controls the schema-dependency gate in Phase 5.5 — when set, the plan output is not blocked even if "Verified by" cells contain `TODO:`, but the plan is annotated to flag PR-review attention. See ADR-0001.
- **`--skip-mockup-check`**: If present, set `SKIP_MOCKUP_CHECK=true` and strip the flag from `$ARGUMENTS`. Otherwise, `SKIP_MOCKUP_CHECK=false`. This flag controls the mockup-fidelity gate in Phase 5.6 — when set, sections marked `TODO:` in the Mockup Fidelity Checklist do not block plan output, but each unset row is tagged `⚠ SKIPPED` for PR-review attention.

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

## Phase 5.5: GATE - Existing Schema Dependencies

**Purpose**: Force the plan author to write down every existing table or column the plan reads or writes, the semantic assumption being made, and how that assumption is verified. The plan blocks if any assumption is unverified.

**Reference**: ADR-0001 — Verify inherited contracts before depending on them. The canonical failure mode (P019 in maxtel-eventledger-poc — `event.day_part_id` inherited from WASTE_* with the wrong semantic for SALES_HR) is exactly what this gate exists to catch.

### 5.5.1 Detect schema sources

Read the project's `CLAUDE.md` for a `## Schema Sources` section. Format:

```markdown
## Schema Sources

- Drizzle: src/db/schema.ts, src/db/schema/*.ts
- Prisma: prisma/schema.prisma
- Raw SQL: db/migrations/*.sql
```

**If present**, use only the listed paths/globs verbatim.

**If absent**, fall back to defaults:

| ORM / format | Default glob |
|---|---|
| Drizzle | `**/schema.ts`, `**/schema/*.ts`, `**/db/schema*.ts`, `drizzle/schema*.ts` |
| Prisma | `prisma/schema.prisma` |
| SQLAlchemy | `**/models.py`, `**/models/*.py` |
| TypeORM | `**/entity/*.ts`, `**/entities/*.ts` |
| Raw SQL migrations | `migrations/*.sql`, `db/migrations/*.sql`, `sql/migrations/*.sql` |

Store the resolved list as `SCHEMA_FILES`.

**No-op condition**: If `SCHEMA_FILES` is empty (greenfield, no schema yet), skip this phase entirely and omit the "Existing Schema Dependencies" section from the plan template.

### 5.5.2 Derive candidate dependencies

Enumerate every existing table/column the plan touches by combining four sources:

1. **Phase 2 (codebase exploration)** — schema files, repository code, ORM identifiers surfaced by `codebase-explorer` and `codebase-analyst`
2. **Phase 5 (architecture)** — integration points and data-flow traces
3. **Files to Change list** (Phase 6 draft) — any file marked `UPDATE` against a schema-source path
4. **Source PRD's `## Schema References` section** (if input was a PRD file) — propagate forward so the plan author confirms each reference

Include reads and writes both. Include the dependency even if this plan does NOT modify the schema — the point is to flag every column the plan depends on for correctness.

### 5.5.3 Author the dependency declaration

For each candidate, the author records three fields:

| Reference | Semantic Assumption | Verified by |
|---|---|---|
| `event.day_part_id` | Carries hour-of-day 0–23 for SALES_HR rows | `TODO: verify before merge` |
| `event_type = 'SALES_HR'` | Enum value exists in the event_type column | `src/db/schema.ts:88 — pgEnum lists SALES_HR` |

**Acceptable `Verified by` values:**

| Citation | Format | Example |
|---|---|---|
| Test | `path/to/test.ts:LINE — what it asserts` | `src/event/event.test.ts:42 — asserts day_part_id is in [1,4]` |
| Schema comment | `schema-file:LINE — comment text` | `src/db/schema.ts:42 — column comment: "hour of day 0–23"` |
| ADR | `ADR-NNNN` (workspace or per-repo) | `ADR-0007` |
| Manual + citation | `Manual: {note}; verified at {path or URL}` | `Manual: column semantic confirmed by team; see PRPs/research/R003-event-schema-audit.md` |
| Unverified placeholder | `TODO: verify before merge` | Allowed at draft time, **blocks plan output unless `--skip-schema-check`** |

A bare assertion ("trust me", "obvious from context") is not acceptable. The citation has to point to something durable.

### 5.5.4 Block on unverified assumptions

Scan the "Existing Schema Dependencies" table the author has filled in. If any "Verified by" cell contains `TODO:` AND `SKIP_SCHEMA_CHECK=false`:

1. Print the offending rows to the user
2. Print the abort message below
3. STOP — do not write the plan

```
STOP: Schema-dependency gate failed.

The plan declares {N} schema dependencies with no verification:

  - {table}.{column}   — TODO: verify before merge

ADR-0001 requires every existing-schema dependency to carry a verification citation (test, schema comment, ADR, or manual citation). A plan that inherits a column without verifying its semantic is the failure mode the gate exists to prevent — see P019 worked example: SALES drilldown collapses 24 hours into 4 buckets because `day_part_id` was inherited from WASTE_* without verification.

Options:
  1. Write a test that asserts the assumption; cite test file:line in "Verified by"
  2. Find a schema comment, ADR, or manual research note that documents the semantic; cite it
  3. Decide the schema needs to grow — capture as an explicit task ahead of the dependent work
  4. Re-run with --skip-schema-check (logged in plan output, requires PR-review attention)

To override:
  /prp-plan --skip-schema-check {original arguments}
```

If `SKIP_SCHEMA_CHECK=true`, do not block — but tag each `TODO:` row with `⚠ SKIPPED` in the rendered plan and add a banner at the top of the "Existing Schema Dependencies" section noting the gate was overridden.

**PHASE_5.5_CHECKPOINT:**
- [ ] Schema sources detected, or no-op confirmed for greenfield
- [ ] Every existing table/column the plan reads or writes is listed
- [ ] Each dependency has a Semantic Assumption stated explicitly
- [ ] Each dependency has a Verified by citation (test, schema comment, ADR, or manual citation)
- [ ] No `TODO:` remains in Verified by (or `--skip-schema-check` was passed)
- [ ] PRD's `## Schema References` rows are carried forward into this table (if input was a PRD)

---

## Phase 5.6: GATE - Mockup Fidelity Checklist

**Purpose**: Force the plan author to write down, for every mockup the PRD references, **every visible section** of that mockup and the React component / file / pattern that will render it — at what fidelity, with what acceptance signal. The plan blocks if any section is unassigned.

**Why this gate exists**: The recurring failure mode is "mockup provided → agent reads it → agent builds something that functionally works → e2e tests pass on data-testid selectors → agent declares done → reviewer finds entire sections (filter bars, totals rows, slideover content shapes, column subgroups, group-header separators) are missing because the plan never enumerated them". Capturing the section-by-section assignment in the plan is the structural fix that closes that loop. **This is the visual analogue of Phase 5.5's schema-dependency gate.**

**Reference**: Inherits from the PRD's Phase 6.6 Mockup Inventory. If the input PRD has no Mockup Inventory section, treat this gate as a no-op (skip and omit the section from the plan template).

### 5.6.1 Inherit the Mockup Inventory

If `SOURCE_PRD` is set, read the PRD's `## Mockup Inventory` section and extract:

- `MOCKUP_FILES`: list of `(file path, type, fidelity)` triples
- `SECTION_INVENTORY`: per-file list of sections (`# / Section / Class / Purpose` rows)

If the PRD's Mockup Inventory is absent OR explicitly says "no mockups" — this gate is a no-op. Omit the "Mockup Fidelity Checklist" section from the plan template and proceed to Phase 6.

If `SOURCE_PRD` is unset (free-form input), scan the project's mockup folders (using the same detection rules as `prp-prd` Phase 6.6.1) and build the inventory directly. If still nothing found, no-op.

### 5.6.2 Refine the section list against the codebase

For each mockup file:

1. Re-read the mockup file in full (don't trust an inherited summary — visual sections drift between PRD writing and plan writing).
2. Walk the DOM (or, for image mockups, walk the manually-transcribed section list from the PRD).
3. For each section, capture:
   - **Mockup ref**: file:line range where the section lives in the mockup HTML (so the implementer can re-read it)
   - **Section name**: stable label matching what the PRD inventory used
   - **Visible elements**: the table headers / button labels / form fields / list items that a reviewer would tick off
   - **Per-screen styles used**: any class only used inside this mockup (vs the project's centralized stylesheet)
4. Cross-reference against Phase 2 (codebase exploration) findings:
   - Which sections already have a centralized component the plan can reuse? (e.g. `PageHeader`, `DateRangeSelect`, `DataTable`)
   - Which sections need a new component? (e.g. custom-dates panel chrome, hour-chart bar visualization)
   - Which sections are screen-unique and belong in a section-specific CSS file?

### 5.6.3 Author the section assignment

For each section, the plan author records:

| Section | Mockup Ref | Target Component / File | Fidelity | Acceptance Signal |
|---|---|---|---|---|
| Sidebar | `index.html:194-248` | `apps/web/components/shell/sidebar.tsx` (existing, extend with `children?`) | VERBATIM | App sidebar shows `parent-active` row + `<div class="submenu">` with the 7 sub-items |
| Page header (title + export) | `index.html:254-257` | `apps/web/components/layout/page-header.tsx` (reuse) | VERBATIM | Breadcrumb format matches; Export button right-aligned |
| Filter bar (Dates + Custom panel + View) | `index.html:259-300` | NEW `apps/web/components/product-mix/summary-filter-bar.tsx`; PORT `.cdp-*` styles from `index.html:118-188` into `apps/web/app/styles/product-mix.css` | VERBATIM | "Custom" preset opens the cdp- chrome panel with date inputs + ✕ clear button |
| Ledger lineage strip | `index.html:303-305` (markup), `index.html:478-503` (JS render) | `apps/web/components/product-mix/ledger-strip.tsx` (reuse, extend with check-circle icon) | VERBATIM | Renders `N × SALES_DAILY — EV-X → EV-Y · N×POS_SEGMENT · ✓ N of M I34 reconciled · View Reconciliation ↗` |
| Wide data-grid (17 cols, col-group header) | `index.html:307-341` | INLINE in `apps/web/app/(authenticated)/sites/[siteId]/product-mix/page.tsx` — render `.data-grid` markup directly | VERBATIM | Column-group row + 17 col headers + totals row at top of tbody + day rows newest-first |
| Day-cell (single-line `.day-cell-name`) | `index.html:451-452` | Inside Summary page render | VERBATIM | Single-line "Tue 19 May", NOT two-line |

**Acceptable `Fidelity` values:**

| Value | Meaning |
|---|---|
| **VERBATIM** | Mockup is canonical; the rendered DOM must match section-by-section (class names from mockup, layout from mockup, content rendered from API data) |
| **ADAPTED** | Mockup provides shape; minor adjustments allowed (e.g. swap `<select>` populated dropdown for `<input type="date">` because the data source is different) — the **specific deviation must be noted in the row** |
| **DEFERRED** | Section is intentionally skipped in this plan — **the reason must be recorded** (schema constraint, separate phase owns it, future PRD, etc.) and the deferral must be reflected in the plan's "NOT Building" section |
| **TODO:** | Unset placeholder. **Blocks plan output unless `--skip-mockup-check`** |

A bare assignment ("see component X") is not acceptable. Each row must give the implementer enough to recognise the section in the mockup file AND know what acceptance signal closes it.

### 5.6.4 Block on unassigned sections

Scan the Mockup Fidelity Checklist. If any "Target Component / File" cell contains `TODO:` AND `SKIP_MOCKUP_CHECK=false`:

1. Print the offending rows to the user
2. Print the abort message below
3. STOP — do not write the plan

```
STOP: Mockup-fidelity gate failed.

The plan declares {N} mockup sections with no target component/file assignment:

  - {section} ({mockup-ref})   — TODO:

A plan that omits the section-by-section mockup assignment leaves the implementer to invent what to render. The recurring failure mode is missing filter bars, totals rows, slideover sections, and column subgroups that are clearly in the mockup but never coded — every passing e2e suite gives a false-positive sense of "done" because the tests only assert data-testid selectors on the pieces that DID get built.

Options:
  1. Assign each section a target component/file (reuse existing or NEW)
  2. Mark intentionally-skipped sections as DEFERRED with a reason, and reflect them in the plan's "NOT Building" section
  3. Re-run with --skip-mockup-check (logged in plan output, requires PR-review attention)

To override:
  /prp-plan --skip-mockup-check {original arguments}
```

If `SKIP_MOCKUP_CHECK=true`, do not block — but tag each `TODO:` row with `⚠ SKIPPED` in the rendered plan and add a banner at the top of the "Mockup Fidelity Checklist" section.

### 5.6.5 Visual-parity gate (carried into implementation)

The plan must include the following in its Validation Loop / Acceptance Criteria:

- **Visual Parity Check**: Before declaring any phase complete, the implementer brings up the dev stack, opens each rendered route at `http://localhost:{port}/{route}` AND opens the corresponding mockup HTML in a separate browser tab/window, and walks the Mockup Fidelity Checklist row-by-row. Each section ships or has a documented deferral. **e2e tests passing is not a substitute for this check — they assert data-testid selectors, not entire UI sections.**
- **Implementation Report visual-parity table**: The implementation report (per `prp-implement`) must include a "Visual Parity" section that mirrors the Mockup Fidelity Checklist with a "Ships in PR / Deferred / Deviation Noted" column for each row.

These two items get added to the plan's Validation Loop and Acceptance Criteria sections in Phase 6.

**PHASE_5.6_CHECKPOINT:**
- [ ] Mockup Inventory inherited from PRD (or no-op confirmed for non-UI plans)
- [ ] Each mockup re-read and section list refined
- [ ] Each section assigned a Target Component / File + Fidelity + Acceptance Signal
- [ ] No `TODO:` remains in any cell (or `--skip-mockup-check` was passed)
- [ ] DEFERRED rows propagated into the plan's "NOT Building" section
- [ ] Visual-parity check + report table baked into Validation Loop + Acceptance Criteria

---

## Phase 6: GENERATE - Implementation Plan File

### 6.0 Numbering and Filename

1. **Determine the prefix** from the parent PRD's filename (if input was a PRD file):
   - If PRD filename starts with `V` (e.g., `V001-PRD003-auth.prd.md`): prefix is `V001-PRD003`
   - If PRD filename starts with `PRD` (e.g., `PRD004-search.prd.md`): prefix is `PRD004`
   - If PRD filename has no number prefix (legacy): use `PRD000` as prefix (backward compatibility)
   - If input was free-form text (no PRD): use `PRD000` as prefix

2. **Assign plan number**:
   1. Read `PRPs/.counters.json` (use Read tool). If the file does not exist, treat it as `{"vision": 0, "prd": 0, "plan": 0}`.
   2. Increment the `plan` counter by 1.
   3. Write updated counters back to `PRPs/.counters.json` (use Write tool).
   4. Zero-pad the new number to 3 digits (e.g., `5` → `005`).
   5. If the Read tool returns a parse error, warn the user and ask them to check the file manually. Do not overwrite a corrupted file.

3. **Generate filename**: `{prefix}-P{NNN}-{kebab-case-feature-name}.plan.md`
   - Example: `V001-PRD003-P005-auth-implementation.plan.md`
   - Example: `PRD004-P006-search-indexing.plan.md`

**OUTPUT_PATH**: `PRPs/plans/{numbered-filename}`

Create directory if needed: `mkdir -p PRPs/plans`

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

## Existing Schema Dependencies

<!--
  Generated by Phase 5.5 schema-dependency gate. Lists every existing
  table or column this plan reads or writes — whether or not the plan
  modifies the schema — with the semantic assumption being made and
  the citation that verifies it.

  Omit this section only on greenfield projects (no schema files
  detected at all). If `--skip-schema-check` was used, the gate ran
  but did not block; rows with TODO are tagged `⚠ SKIPPED` and a
  banner appears below.

  Reference: ADR-0001 (verify inherited contracts).
-->

| Reference | Semantic Assumption | Verified by |
|-----------|---------------------|-------------|
| `{table.column}` | {What this plan assumes the column represents} | `{path/to/test.ts:LINE — what it asserts}` OR `{schema-file:LINE — comment}` OR `ADR-NNNN` OR `Manual: {note}; verified at {path}` |

_If `--skip-schema-check` was passed, the gate did not block unverified rows. PR reviewers must verify each `⚠ SKIPPED` row manually before merge._

---

## Mockup Fidelity Checklist

<!--
  Generated by Phase 5.6 mockup-fidelity gate. Lists every visible section
  of every mockup the PRD references, with the React component / file that
  will render it, the fidelity contract, and the acceptance signal that
  closes the row.

  Omit this section only when the PRD has no Mockup Inventory (non-UI
  features). If `--skip-mockup-check` was used, rows with `TODO:` are
  tagged `⚠ SKIPPED` and a banner appears below.

  Reference: visual analogue of ADR-0001's schema-dependency gate.
  Mirrors `prp-prd` Phase 6.6 Mockup Inventory.
-->

### `{path/to/first-mockup.html}` — Fidelity: VERBATIM / ADAPTED / EXPLORATORY

| # | Section | Mockup Ref | Target Component / File | Fidelity | Acceptance Signal |
|---|---|---|---|---|---|
| 1 | {Section name from PRD inventory} | `{mockup-file:line-range}` | `{path/to/component.tsx}` (REUSE / NEW / EXTEND) | VERBATIM / ADAPTED / DEFERRED | {What a reviewer ticks off — e.g. "Renders {N} cols with class X; clicking row Y triggers Z"} |

_Repeat one table per mockup file. For image mockups, list manually-transcribed sections (the structural inventory deferred in the PRD)._

_If `--skip-mockup-check` was passed, the gate did not block unassigned rows. PR reviewers must verify each `⚠ SKIPPED` row manually before merge._

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

### Level 6: VISUAL_PARITY (if Mockup Fidelity Checklist is present)

**Skip this level when** the plan has no `## Mockup Fidelity Checklist` section (non-UI plans).

Otherwise: run AFTER Levels 1-5 pass. Required before claiming any UI-bearing task complete.

1. Bring up the stack per "How to Execute" (Start Services → Seed Data → Verify Ready).
2. Open each rendered route in a browser tab at `http://localhost:{port}/{route}`.
3. Open the corresponding mockup HTML file from the Mockup Fidelity Checklist in a separate tab/window.
4. For each row in the Mockup Fidelity Checklist, walk the section side-by-side. Each row should be:
   - **Ships** — DOM matches the mockup at the declared Fidelity (VERBATIM = pixel-level; ADAPTED = the noted deviation only)
   - **Deferred** — the row was declared DEFERRED at plan time; confirm it's NOT rendered (no unintended ghost UI)
   - **Deviation Noted** — DOM differs from mockup beyond the declared Fidelity; the implementation report must record the deviation and the reason
5. Tear down per "How to Execute".

**EXPECT**: Every Ships row matches; every Deferred row carries the documented reason; every Deviation Noted row has a written rationale in the implementation report.

**WHY THIS LEVEL EXISTS**: Levels 1-5 prove the code is correct (types compile, units pass, e2e selectors resolve). They do not prove the rendered UI matches the canonical visual contract. The recurring failure mode is "e2e green, filter bar missing" — Level 6 is the gate that catches it before PR review.

### Level 7: MANUAL_VALIDATION

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
- [ ] Visual parity walked section-by-section against every mockup file (if Mockup Fidelity Checklist is present); each row marked Ships / Deferred / Deviation Noted in the implementation report

---

## Completion Checklist

- [ ] All tasks completed in dependency order
- [ ] Each task validated immediately after completion
- [ ] Level 1: Static analysis (lint + type-check) passes
- [ ] Level 2: Unit tests pass
- [ ] Level 3: Full test suite + build succeeds
- [ ] Level 4: Database validation passes (if applicable)
- [ ] Level 5: User journey / e2e validation passes (if applicable)
- [ ] Level 6: Visual parity walked against every mockup (if Mockup Fidelity Checklist present)
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
**OUTPUT_FILE**: `PRPs/plans/{numbered-filename}` (e.g., `V001-PRD003-P005-auth-implementation.plan.md`)

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
  git add PRPs/plans/{numbered-filename} PRPs/.counters.json {prd-file-path if updated}
  git commit -m "docs: add implementation plan {plan-id} for {feature-name}"
  ```
- **`branch-per-prd`**: Verify on the PRD branch. If not, check it out. Then commit:
  ```bash
  # If vision-linked: feat/{vision-id}/{prd-id}-{prd-kebab-name}
  # If standalone:    feat/{prd-id}-{prd-kebab-name}
  git checkout feat/{...}  # if not already on it
  git add PRPs/plans/{numbered-filename} PRPs/.counters.json {prd-file-path if updated}
  git commit -m "docs: add implementation plan {plan-id} for {feature-name}"
  ```
- **`branch-per-phase`**: Create a phase branch from the PRD branch (or base branch if no PRD branch) using hierarchical naming, and commit:
  ```bash
  # If vision-linked: feat/{vision-id}/{prd-id}/{plan-id}-{phase-kebab}
  # If standalone:    feat/{prd-id}/{plan-id}-{phase-kebab}
  git checkout -b feat/{...}
  git add PRPs/plans/{numbered-filename} PRPs/.counters.json {prd-file-path if updated}
  git commit -m "docs: add implementation plan {plan-id} for {feature-name}"
  ```

**REPORT_TO_USER** (display after creating plan):

```markdown
## Plan Created

**File**: `PRPs/plans/{numbered-filename}`

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

**Next Step**: To execute, run: `/prp-implement PRPs/plans/{numbered-filename}`
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
- [ ] Existing Schema Dependencies table is present (or section omitted because greenfield), every row has a Verified by citation, no `TODO:` remains unless `--skip-schema-check` was passed (ADR-0001)

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
**SCHEMA_VERIFIED**: Existing Schema Dependencies table is filled in — every inherited table/column carries a semantic assumption and a verification citation; gate passed cleanly or `--skip-schema-check` is logged. No-op on greenfield. (ADR-0001)
**UX_DOCUMENTED**: Before/After transformation is visually clear with data flows
**JOURNEYS_DEFINED**: User journey files created for new user-facing flows with concrete steps
**ONE_PASS_TARGET**: Confidence score 8+ indicates high likelihood of first-attempt success
</success_criteria>
