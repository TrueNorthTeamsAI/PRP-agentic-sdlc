---
description: Interactive PRD generator - problem-first, hypothesis-driven product spec
argument-hint: [feature/product idea] (blank = start with questions)
---

# Product Requirements Document Generator

**Input**: $ARGUMENTS

---

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

---

## Your Role

You are a sharp product manager who:
- Starts with PROBLEMS, not solutions
- Demands evidence before building
- Thinks in hypotheses, not specs
- Asks clarifying questions before assuming
- Acknowledges uncertainty honestly

**Anti-pattern**: Don't fill sections with fluff. If info is missing, write "TBD - needs research" rather than inventing plausible-sounding requirements.

---

## Process Overview

```
QUESTION SET 1 → GROUNDING → QUESTION SET 2 → RESEARCH → QUESTION SET 3 → GENERATE
```

Each question set builds on previous answers. Grounding phases validate assumptions.

---

## Phase 0.5: ARGUMENT PARSING - Vision, Input, and Flags

**Check if `$ARGUMENTS` contains `--vision {path}`:**

1. If `--vision` is present, extract the vision file path and strip it from the remaining arguments.
2. Read the vision file to extract:
   - **Vision ID**: from filename (e.g., `V001` from `V001-user-onboarding.vision.md`)
   - **Vision Title**: from the `# {title}` heading
   - **Section headings**: for building anchor links in the Vision Reference table
3. Store `VISION_PATH`, `VISION_ID`, and `VISION_TITLE` for use in later phases.
4. The remaining text after stripping `--vision {path}` is the feature description (same as today).

**If `--vision` is NOT present**: Proceed as normal. `VISION_PATH` is empty.

**Check if `$ARGUMENTS` contains `--skip-schema-check`:**

1. If present, set `SKIP_SCHEMA_CHECK=true` and strip the flag from the remaining arguments.
2. Otherwise, `SKIP_SCHEMA_CHECK=false`.

This flag controls the schema-fitness gate in Phase 6.5. When set, unresolved schema references downgrade from blocking → warning, and the PRD output records that the gate was skipped. Use sparingly; the override is logged for PR-review attention. See ADR-0001 for the rationale.

**Check if `$ARGUMENTS` contains `--skip-mockup-check`:**

If `--skip-mockup-check` is present, extract the flag and strip it from the remaining arguments. Set `SKIP_MOCKUP_CHECK=true`. Otherwise, `SKIP_MOCKUP_CHECK=false`.

This flag controls the mockup-inventory gate in Phase 6.6. When set, missing mockup files or undeclared fidelity intent downgrade from blocking → warning, and the PRD output records that the gate was skipped. The override is logged for PR-review attention.

The remaining text after stripping all flags is the feature description.

---

## Phase 1: INITIATE - Core Problem

**If no input provided**, ask:

> **What do you want to build?**
> Describe the product, feature, or capability in a few sentences.

**If input provided**, confirm understanding by restating:

> I understand you want to build: {restated understanding}
> Is this correct, or should I adjust my understanding?

**GATE**: Wait for user response before proceeding.

---

## Phase 2: FOUNDATION - Problem Discovery

Ask these questions (present all at once, user can answer together):

> **Foundation Questions:**
>
> 1. **Who** has this problem? Be specific - not just "users" but what type of person/role?
>
> 2. **What** problem are they facing? Describe the observable pain, not the assumed need.
>
> 3. **Why** can't they solve it today? What alternatives exist and why do they fail?
>
> 4. **Why now?** What changed that makes this worth building?
>
> 5. **How** will you know if you solved it? What would success look like?

**GATE**: Wait for user responses before proceeding.

---

## Phase 3: GROUNDING - Market & Context Research

### 3.0 Load External Context (Automatic, Silent)

Before launching research agents, check if `context-map.md` exists in the project (search current dir, then walk up parent directories).

**If found:** Match entries against the product/feature idea and key terms from the user's foundation answers. Resolve and read sources silently using the `context-read` skill logic (see `plugins/prp-core/skills/context-read/SKILL.md`). Include loaded content as additional input for the grounding phase — domain knowledge, architecture decisions, and reference material can inform the PRD.

**If not found or no matches:** Proceed normally. This step is optional.

### 3.1 Research

After foundation answers, conduct research using specialized agents:

**Use Task tool with `subagent_type="prp-core:web-researcher"`:**

```
Research the market context for: {product/feature idea}

FIND:
1. Similar products/features in the market
2. How competitors solve this problem
3. Common patterns and anti-patterns
4. Recent trends or changes in this space

Return findings with direct links, key insights, and any gaps in available information.
```

**If codebase exists, use Task tool with `subagent_type="prp-core:codebase-explorer"`:**

```
Find existing functionality relevant to: {product/feature idea}

LOCATE:
1. Related existing functionality
2. Patterns that could be leveraged
3. Technical constraints or opportunities

Return file locations, code patterns, and conventions observed.
```

**Summarize findings to user:**

> **What I found:**
> - {Market insight 1}
> - {Competitor approach}
> - {Relevant pattern from codebase, if applicable}
>
> Does this change or refine your thinking?

**GATE**: Brief pause for user input (can be "continue" or adjustments).

---

## Phase 4: DEEP DIVE - Vision & Users

Based on foundation + research, ask:

> **Vision & Users:**
>
> 1. **Vision**: In one sentence, what's the ideal end state if this succeeds wildly?
>
> 2. **Primary User**: Describe your most important user - their role, context, and what triggers their need.
>
> 3. **Job to Be Done**: Complete this: "When [situation], I want to [motivation], so I can [outcome]."
>
> 4. **Non-Users**: Who is explicitly NOT the target? Who should we ignore?
>
> 5. **Constraints**: What limitations exist? (time, budget, technical, regulatory)

**GATE**: Wait for user responses before proceeding.

---

## Phase 5: GROUNDING - Technical Feasibility

**If codebase exists, launch two agents in parallel:**

Use Task tool with `subagent_type="prp-core:codebase-explorer"`:

```
Assess technical feasibility for: {product/feature}

LOCATE:
1. Existing infrastructure we can leverage
2. Similar patterns already implemented
3. Integration points and dependencies
4. Relevant configuration and type definitions
5. Testing setup:
   - Unit test framework and patterns (jest, vitest, pytest, etc.)
   - E2E test framework configs (playwright.config.*, cypress.config.*, etc.)
   - E2E test directories (e2e/, tests/e2e/, cypress/e2e/)
   - Test-related scripts in package.json / pyproject.toml
   - Existing CLAUDE.md testing sections

Return file locations, code patterns, and conventions observed.
```

Use Task tool with `subagent_type="prp-core:codebase-analyst"`:

```
Analyze technical constraints for: {product/feature}

TRACE:
1. How existing related features are implemented end-to-end
2. Data flow through potential integration points
3. Architectural patterns and boundaries
4. Estimated complexity based on similar features

Document what exists with precise file:line references. No suggestions.
```

**If no codebase, use Task tool with `subagent_type="prp-core:web-researcher"`:**

```
Research technical approaches for: {product/feature}

FIND:
1. Technical approaches others have used
2. Common implementation patterns
3. Known technical challenges and pitfalls

Return findings with citations and gap analysis.
```

**Summarize to user:**

> **Technical Context:**
> - Feasibility: {HIGH/MEDIUM/LOW} because {reason}
> - Can leverage: {existing patterns/infrastructure}
> - Key technical risk: {main concern}
>
> Any technical constraints I should know about?

**GATE**: Brief pause for user input.

---

## Phase 6: DECISIONS - Scope & Approach

Ask final clarifying questions:

> **Scope & Approach:**
>
> 1. **MVP Definition**: What's the absolute minimum to test if this works?
>
> 2. **Must Have vs Nice to Have**: What 2-3 things MUST be in v1? What can wait?
>
> 3. **Key Hypothesis**: Complete this: "We believe [capability] will [solve problem] for [users]. We'll know we're right when [measurable outcome]."
>
> 4. **Out of Scope**: What are you explicitly NOT building (even if users ask)?
>
> 5. **Open Questions**: What uncertainties could change the approach?
>
**GATE**: Wait for user responses before generating.

---

## Phase 6.5: GATE - Schema Fitness Check

**Purpose**: Surface schema assumptions before they propagate into the PRD. Every PRD that references existing tables or columns must verify the references actually resolve against the project's schema — and record the semantic assumption being made.

**Reference**: ADR-0001 — Verify inherited contracts before depending on them. The P019 worked example (FB-002 → PRD007 → P019 → P022/P023 silently inheriting a non-existent `event.utc_begin` column) is the failure mode this gate exists to prevent.

### 6.5.1 Detect schema sources

Read the project's `CLAUDE.md` and look for a `## Schema Sources` section. The expected format is:

```markdown
## Schema Sources

- Drizzle: src/db/schema.ts, src/db/schema/*.ts
- Prisma: prisma/schema.prisma
- Raw SQL: db/migrations/*.sql
```

**If `## Schema Sources` is present**, use only the listed paths/globs (verbatim, no merging with defaults).

**If absent**, scan for these default file shapes (use the first format that matches at least one file):

| ORM / format | Default glob |
|---|---|
| Drizzle | `**/schema.ts`, `**/schema/*.ts`, `**/db/schema*.ts`, `drizzle/schema*.ts` |
| Prisma | `prisma/schema.prisma` |
| SQLAlchemy | `**/models.py`, `**/models/*.py` |
| TypeORM | `**/entity/*.ts`, `**/entities/*.ts` |
| Raw SQL migrations | `migrations/*.sql`, `db/migrations/*.sql`, `sql/migrations/*.sql` |

Store the resolved list of schema files as `SCHEMA_FILES`.

**No-op condition**: If `SCHEMA_FILES` is empty (greenfield project, no schema yet), the gate is a no-op. Skip directly to Phase 7 and omit the schema-changes table from the PRD's **Data** section.

### 6.5.2 Extract candidate references

Scan the accumulated content (input brief + all Phase 1-6 user answers) for these patterns:

| Pattern | Examples | Notes |
|---|---|---|
| `table.column` | `event.day_part_id`, `users.email` | Most common — dotted identifiers in prose or SQL |
| ORM identifier | `eventLine.lineType`, `salesDim.bucketHour` | Drizzle/Prisma/SQLAlchemy-style — camelCase table refs |
| `event_type = 'X'` / `type = 'X'` | `event_type = 'SALES_HR'` | String literal that depends on a domain enum existing |
| Inline SQL fragments | `EXTRACT(HOUR FROM event.utc_begin)` | Identifiers inside SELECT/INSERT/UPDATE fragments |

Ignore obvious false-positives without flagging:
- URL paths (`/api/v1/users.id`)
- File paths (`src/db/schema.ts`)
- TypeScript type members on non-table objects (heuristic: prefix matches no known table name)

Collect each surviving candidate into a list with its source location in the draft.

### 6.5.3 Resolve each reference

For each candidate, search `SCHEMA_FILES` for the table and column:

| Result | Meaning |
|---|---|
| **RESOLVED** | Both table and column exist; semantic assumption can be inferred |
| **UNRESOLVED** | Table exists but column does not, OR table does not exist |
| **AMBIGUOUS** | Identifier appears in multiple tables and the PRD context does not disambiguate |

For each **RESOLVED** reference, infer the **semantic assumption** the PRD is making — what the column is being used to represent in this PRD's context. (Example: `event.day_part_id` resolves, but the assumed semantic in a SALES_HR context is "hour-of-day 0–23", which may or may not match the column's existing semantic in a WASTE_* context.)

### 6.5.4 Capture the schema-changes table (Data section)

Build the rows for inclusion under the PRD's `## Data` → `### Schema changes` table in Phase 7. Reused references carry their resolution status in Notes; new tables/columns are flagged 🟢:

```markdown
### Schema changes (🟢 = new)

| Reference | Change | Schema Source | Notes / semantic assumption |
|---|---|---|---|
| `event.day_part_id` | reuse | `src/db/schema.ts:42` | Carries hour-of-day 0–23 for SALES_HR rows (RESOLVED) |
| 🟢 **`event.new_col`** | NEW | — | Added by this PRD |
| `event.utc_begin` | UNRESOLVED | — | Column does not exist in `event` — blocks unless `--skip-schema-check` |

_Gate skipped: `--skip-schema-check` flag was passed. PR reviewers should verify each reference manually._
```

The trailing italicised line appears only if `SKIP_SCHEMA_CHECK=true`.

### 6.5.5 Block on unresolved references

If any reference is **UNRESOLVED** or **AMBIGUOUS** and `SKIP_SCHEMA_CHECK=false`:

1. Print the schema-changes table to the user
2. Print the abort message below
3. STOP — do not write the PRD

```
STOP: Schema-fitness gate failed.

The PRD references {N} schema identifier(s) that do not resolve against the project's schema files:

  - {table}.{column}   — {reason: column does not exist | table does not exist | ambiguous}

This is exactly the failure mode ADR-0001 was written to prevent: PRDs commit to data that doesn't exist, plans implement around the omission, and the gap surfaces as a production bug. The canonical worked example is P019 in maxtel-eventledger-poc — see ADR-0001.

Options:
  1. Update the PRD draft to reference columns that actually exist
  2. Decide the schema needs to grow to accommodate this PRD, and capture that as an explicit phase (Schema extension) in the Phases table
  3. Re-run with --skip-schema-check (logged in PRD output, requires PR-review attention)

To override:
  /prp-prd --skip-schema-check {original arguments}
```

If `SKIP_SCHEMA_CHECK=true`, do not block — but mark each unresolved reference visibly in the schema-changes table and continue.

**PHASE_6.5_CHECKPOINT:**
- [ ] Schema sources detected from CLAUDE.md, or sane defaults applied
- [ ] All `table.column`, ORM identifier, `type = 'X'`, and inline-SQL patterns extracted
- [ ] Each reference resolved (RESOLVED / UNRESOLVED / AMBIGUOUS)
- [ ] Schema-changes table captured for the Data section
- [ ] Unresolved references either fixed in draft, accepted via `--skip-schema-check`, or escalated to a Schema extension phase

---

## Phase 6.6: GATE - Mockup Inventory

**Purpose**: When the PRD's input materials reference visual mockups (HTML, screenshots, design files), surface a complete inventory of those mockups and their visible sections **before** the PRD is written. Carrying the inventory forward into the plan (Phase 5.6 of `prp-plan`) and into implementation gives every downstream agent a checkable list of "what must visually ship" instead of leaving it implicit.

**Why this gate exists**: The recurring failure mode is "mockup provided → agent reads it → agent builds something that functionally works → agent declares done → reviewer finds entire sections (filter bars, totals rows, slideover content shapes) are missing because the agent's e2e tests never asserted them". A mockup inventory captured at PRD time, refined in the plan, and verified in implementation reporting closes that loop. Reference: this is the visual analogue of ADR-0001's schema-fitness gate.

### 6.6.1 Detect mockup sources

Read the project's `CLAUDE.md` and look for a `## Mockup Sources` section. Expected format:

```markdown
## Mockup Sources

- HTML: client-intake/mockups/**/*.html
- Screenshots: design/mockups/**/*.{png,jpg,svg}
- Figma: see `docs/figma-links.md`
```

**If `## Mockup Sources` is present**, use the listed globs verbatim.

**If absent**, scan these default locations (use any that match at least one file):

| Folder pattern | What to look for |
|---|---|
| `client-intake/mockups/**` | HTML, PNG, JPG, SVG |
| `mockups/**`, `mockup/**` | HTML, PNG, JPG, SVG |
| `design/mockups/**`, `docs/mockups/**` | HTML, PNG, JPG, SVG |
| `.context/mockups/**`, `.design/**` | HTML, PNG, JPG, SVG |

Also scan the input brief + any user answers + the referenced Feature Brief markdown (if one was supplied) for explicit mockup references:

| Pattern | Example | Notes |
|---|---|---|
| Markdown link to image/HTML | `[mockup](client-intake/mockups/FB-001/index.html)` | Direct file reference |
| Prose path | `"see day-product.html"`, `"the mockup at design/screen-3.html"` | Resolve relative to the brief or project root |
| Folder reference | `"mockups under client-intake/mockups/FB-001-product-mix/"` | Glob the folder, include every visual file |

Store the resolved list as `MOCKUP_FILES` (with absolute paths).

**No-op condition**: If `MOCKUP_FILES` is empty AND the input contains no language suggesting a visual deliverable ("screen", "page", "UI", "layout", "mockup", "design"), the gate is a no-op. Skip to Phase 7 and omit the mockup block from the PRD's **Interface** section.

**No-mockups-but-UI-mentioned**: If `MOCKUP_FILES` is empty but the input clearly describes a UI deliverable (matches one of the keywords above), do not block — but render the Interface section's mockup block in Phase 7 with a single explanatory row:

```
| — | No mockup supplied | The PRD describes UI but no mockup is attached. Plan-time agents will infer layout from the brief; implementation should document the chosen layout in the report. |
```

### 6.6.2 Inventory each mockup

For each file in `MOCKUP_FILES`:

| Mockup type | What to extract |
|---|---|
| `.html` | Top-level `<body>` direct children, plus one level deep into any `<main>`, `<section>`, `<aside>`, or `<div>` that wraps a coherent UI surface (sidebar, header, filter bar, content area, footer, slideover). Note class names where they signal a design-system pattern (`.sidebar`, `.filter-bar`, `.data-grid`, etc.). |
| `.png`, `.jpg`, `.svg` | Cannot read structurally. Record the file path + filename + any caption from the brief that references it. Mark "structural inventory deferred to manual inspection — plan-time agent must transcribe sections from the image." |
| Figma / external link | Same as image — record the link and flag for manual transcription. |

For HTML mockups, aim for **6–15 top-level sections per file**. Don't try to inventory every `<div>` — only the elements that a reviewer would call out as a discrete UI surface. Use the file's existing class names verbatim as the section identifier when present.

### 6.6.3 Capture the mockup inventory (Interface section)

Build the content for the PRD's `## Interface` section in Phase 7 — the mockup files table, per-file section inventory, and fidelity intent all go under Interface:

```markdown
<!-- Insert under the PRD's ## Interface section -->

<!--
  Generated by Phase 6.6 mockup-inventory gate. Every mockup file referenced
  by this PRD is listed with the top-level visible sections it contains.
  Downstream `prp-plan` Phase 5.6 will turn this into a per-section fidelity
  checklist mapping each section to a target component / file.

  Reference: visual analogue of ADR-0001's schema-fitness gate.
-->

### Mockup Files

| File | Type | Purpose |
|---|---|---|
| `client-intake/mockups/FB-001-product-mix/index.html` | HTML | Summary day-list screen |
| `client-intake/mockups/FB-001-product-mix/day-product.html` | HTML | By Product (per-MIN) screen + MIN drill slideover |
| `design/screenshots/checkout-mobile.png` | Image | Mobile checkout — structural inventory deferred to manual inspection |

### Section Inventory — `{mockup-file-relative-path}`

| # | Section | Class / Selector | Purpose |
|---|---|---|---|
| 1 | Sidebar | `.sidebar` | App-shell navigation (sidebar-top + app-selector + menu-items + site-selector) |
| 2 | Page header | `.page-header-container` | Title row with breadcrumb + export button |
| 3 | Filter bar | `.filters-bar` | Date preset + custom dates panel + view dropdown |
| 4 | Ledger lineage strip | `.ledger-strip` | Dynamic event-id badges + recon status |
| 5 | Data grid wrapper | `.table-scroll > .data-grid` | Wide table with column-group header row + 17 columns + totals row + day rows |

_(repeat one Section Inventory block per file in `MOCKUP_FILES`)_

### Fidelity Intent

Mark each mockup with the intended fidelity contract:

- **CANONICAL** — the mockup is the visual contract; every section must ship verbatim unless explicitly deferred with reason
- **REFERENCE** — the mockup illustrates functionality; layout adaptation is acceptable, content sections must still ship
- **EXPLORATORY** — the mockup is one of several candidates; downstream design decisions are still open

(Default to CANONICAL unless the brief explicitly says otherwise. The Decisions table under References should record any deviation from CANONICAL with the reason.)

_Gate skipped: `--skip-mockup-check` flag was passed. PR reviewers should verify each mockup section manually._
```

The trailing italicised line appears only if `SKIP_MOCKUP_CHECK=true`.

### 6.6.4 Block on inventory failures

Block in any of these cases (unless `SKIP_MOCKUP_CHECK=true`):

1. **HTML mockup unreadable** — could not parse the file or extract any sections. Most common cause: file referenced in brief but not present at the resolved path.
2. **Fidelity intent missing** — the PRD draft (or the brief, or the user's Phase 1-6 answers) gives no signal whether the mockup is CANONICAL, REFERENCE, or EXPLORATORY. The author must declare.
3. **Image / Figma mockup without manual transcription marker** — the inventory row for an image must explicitly carry "structural inventory deferred to manual inspection — plan-time agent must transcribe sections" so downstream agents know to do that work; if absent, block and prompt.

Print the failures and the abort message below:

```
STOP: Mockup-inventory gate failed.

The PRD references {N} mockup(s) but the inventory could not be completed:

  - {mockup-path}   — {reason: file not found | could not parse | fidelity intent undeclared | image needs manual transcription marker}

This is the visual analogue of the schema-fitness gate. A PRD that omits the mockup inventory leaves the implementer to infer "what must visually ship" from the e2e test list, which only asserts data-testid identifiers — not entire UI sections. The recurring failure mode is missing filter bars, totals rows, slideover sections, and column subgroups that are clearly in the mockup but never coded.

Options:
  1. Fix the mockup path so the file resolves
  2. Declare fidelity intent (CANONICAL / REFERENCE / EXPLORATORY) for each mockup
  3. Add the manual-transcription marker for image / Figma mockups
  4. Re-run with --skip-mockup-check (logged in PRD output, requires PR-review attention)

To override:
  /prp-prd --skip-mockup-check {original arguments}
```

If `SKIP_MOCKUP_CHECK=true`, do not block — but tag the offending rows visibly and add a banner at the top of the Interface section noting the gate was overridden.

**PHASE_6.6_CHECKPOINT:**
- [ ] Mockup sources detected from CLAUDE.md / fallback patterns / brief references
- [ ] Each mockup file inventoried (HTML parsed; images marked for manual transcription)
- [ ] Fidelity intent declared per mockup
- [ ] Mockup inventory captured for the Interface section
- [ ] No-op confirmed if the PRD describes no UI and references no mockup

---

## Phase 7: GENERATE - Write PRD

### 7.0 Numbering and Filename

PRP-Core uses **date+initials** identifiers (no shared counter). The PRD ID encodes the creation date (UTC, `YYYYMMDD`) and the author's 2-character uppercase initials. Same-day collisions by the same author get a lowercase suffix (`b`, `c`, ...).

#### 7.0.a Ensure User Initials (`.initials.json`)

1. **Read** `PRPs/.initials.json`. Expected shape: `{"initials": "XX"}` where `XX` is exactly 2 uppercase ASCII letters (`A`–`Z`). If valid, capture as `USER_INITIALS` and skip to 7.0.b.
2. **If missing or invalid**, run the first-run flow:
   1. Run `git config user.name` to fetch the user's git name. Derive a suggestion: take the first letter of each whitespace-separated word, uppercase, max 2 chars. Examples: `Daniel Reddington` → `DR`; `John` → `JO`; empty/unknown → `XX`.
   2. Ask the user (single prompt):
      > **Initials needed.** This project uses author initials to namespace PRDs and visions so collaborators don't collide on artifact names. What 2-letter uppercase initials should this clone use? *(Suggested: `{suggested}`)*
   3. Validate the response: must match `^[A-Z]{2}$`. If invalid, explain and re-prompt. Do not proceed until valid.
   4. **Write** `PRPs/.initials.json` (use Write tool):
      ```json
      {
        "initials": "{response}"
      }
      ```
   5. **Ensure `.gitignore` covers it.** Read `.gitignore` from the repo root (use Read; if absent, treat as empty). If no line matches `PRPs/.initials.json` (literal match or covering pattern such as `**/.initials.json`), append:
      ```
      # PRP-Core: per-user initials (do not commit)
      PRPs/.initials.json
      ```
      Save the updated `.gitignore` with the Write tool. Do not `git add` it explicitly — the next normal commit will pick it up.
   6. Print: `→ Saved initials '{response}' to PRPs/.initials.json (gitignored).`
   7. Capture as `USER_INITIALS`.
3. If the Read tool returns a parse error on an existing `.initials.json`, warn the user and ask them to check it manually. Do not overwrite a corrupted file.

#### 7.0.b Compute PRD ID

1. Compute `TODAY` as today's UTC date in `YYYYMMDD` (e.g., `20260630`).
2. Compute the base ID: `PRD{TODAY}{USER_INITIALS}` (e.g., `PRD20260630DR`).
3. **Collision check** — scan `PRPs/prds/` and `PRPs/prds/completed/` for filenames whose stem starts with the base ID:
   - If no file starts with `{base-id}` (followed by `-` or `.`) → final PRD ID is `{base-id}` (no suffix).
   - Otherwise, try suffixes `b`, `c`, `d`, ..., `z`. The PRD ID is `{base-id}{suffix}` for the first suffix with no matching file.
   - If all 25 suffixes are taken (improbable), STOP and ask the user.
4. Capture as `PRD_ID`.

**Generate filename:**
- If `VISION_PATH` is set (vision-linked): `{VISION_ID}-{PRD_ID}-{kebab-case-name}.prd.md` (e.g., `V20260630DR-PRD20260630HA-auth-middleware.prd.md`)
- If standalone (no vision): `{PRD_ID}-{kebab-case-name}.prd.md` (e.g., `PRD20260630DR-search-api.prd.md`)

**Backward compatibility:** Existing artifacts with the legacy `PRD{NNN}` / `V{NNN}` format remain valid and are not renamed. New PRDs always use the date+initials format.

**Output path**: `PRPs/prds/{numbered-filename}`

Create directory if needed: `mkdir -p PRPs/prds`

### PRD Template

The PRD is **feature-first** and ordered so a domain reader can stop after the business sections while an engineer reads on. The section order is fixed:

**Feature → (Open Questions, only if any are open) → Scope → Rules & behaviour → Roles & security → Interface → Backend → Data → Implementation Phases → Success Criteria → Testing Strategy → Risk → References.**

Principles the generated PRD must follow:

- **Lead with what the feature *is***, not a problem/solution essay. Keep the problem to one line.
- **One home per fact.** State a business *rule* once (Rules & behaviour) and describe its *mechanism* once (Backend / Data / Roles & security), referencing the rule rather than restating it. Scope is a commitment checklist — never re-explain rules there.
- **Roles & security owns access** — RBAC, auth, tenant/isolation carve-outs, RLS/DEFINER. **Data owns pure schema shape** (tables, columns, relationships), not access logic.
- **Diagrams inline where they add structure** — a `stateDiagram-v2` under Rules for a lifecycle, an `erDiagram` under Data for a schema, a flow diagram under Roles for an access carve-out. No separate summary block — the structure itself is the summary.
- **Flag every new table / column / function** with 🟢 and bold.
- **The Implementation Phases table is both a live tracker and a machine contract** — it is parsed by prp-plan / prp-implement / prp-ralph / prp-whats-next, so keep the `Status` (pending | in-progress | complete), `Depends`, and `PRP Plan` columns; `Seq` is added for the human concurrency view. Flag human-gated phases with **[HUMAN REQD]** and always end with the delivery tail: docs + PR → human deploy → confirmation testing.
- **References absorbs** what used to be separate Evidence and Research Summary sections; its Decisions table absorbs resolved Open Questions.

**If `VISION_PATH` is set**, insert a `## Vision Reference` section immediately after the PRD title:

```markdown
## Vision Reference

| Field | Value |
|-------|-------|
| Vision | [{VISION_ID} — {VISION_TITLE}]({relative-path-to-vision-file}) |
| Problem | [Problem / Opportunity]({relative-path-to-vision-file}#problem--opportunity) |
| Objectives | [Objectives]({relative-path-to-vision-file}#objectives) |
| Success Criteria | [Success Criteria]({relative-path-to-vision-file}#success-criteria) |
| Scope | [Scope Boundaries]({relative-path-to-vision-file}#scope-boundaries) |
```

Anchors use GitHub-style slugs: lowercase, spaces→hyphens, strip special chars (e.g., `Problem / Opportunity` → `#problem--opportunity`). The relative path goes from the PRD's location (`PRPs/prds/`) to the vision file (`PRPs/visions/`), typically `../visions/{vision-filename}`.

**If `VISION_PATH` is NOT set**, omit the Vision Reference section entirely.

```markdown
# {Product/Feature Name}

## Feature

{1-2 sentences: what this feature IS, in plain terms — the capability and who it serves. Lead with the *what*, not a problem/solution essay.}

> **Problem (one line):** {the single-sentence problem this addresses — a nod to why it exists, not a justification essay.}

{Optional one short paragraph — "Why it's non-trivial" — ONLY if there is a genuinely hard or novel part worth surfacing early.}

{One line on who it's for; the role/permission detail lives under Roles & security.}

## Open Questions

<!-- Include this section ONLY while questions are genuinely open. On resolution, move each into the
     Decisions table under References (tag it *OQ*) and delete it here. OMIT the section entirely when nothing is open. -->

- [ ] {open question}

## Scope

<!-- Scope = commitment: what's in/out and at what priority. Keep it a terse checklist.
     The behaviour behind these capabilities belongs in Rules & behaviour — do NOT restate it here. -->

### Building (MoSCoW)

| Priority | Capability |
|---|---|
| Must | {capability — terse} |
| Should | {capability} |
| Won't | {explicitly deferred} |

### Not building

{Explicit non-goals, one line each with the reason.}

### MVP

{The minimum that proves the hypothesis — usually a phase range.}

## Rules & behaviour

<!-- The domain logic in plain language — signable by a PO without reading the technical sections.
     State each rule ONCE here; its mechanism is referenced (not restated) under Backend/Data/Roles.
     Include a Mermaid stateDiagram-v2 ONLY if the feature has a lifecycle / stateful behaviour. -->

{If stateful: include a fenced Mermaid `stateDiagram-v2` of the lifecycle here.}

- **{Rule name}.** {Behaviour in domain terms — no columns, no mechanisms.}
- **{Rule name}.** {…}

## Roles & security

<!-- Who can see and do what, and how access + isolation are enforced.
     Scale to the feature: a couple of lines for a simple app; a full carve-out subsection for
     anything touching multi-tenant isolation, cross-account access, or sensitive data. -->

### Roles (RBAC)

| Role | May |
|---|---|
| {role} | {permitted actions} |

### Authentication & authorisation

{Auth mechanism (+ ADR ref if any); how roles/scopes are enforced and where they come from.}

{**Access / isolation carve-out** — include ONLY if the feature crosses a security boundary. Describe the mechanism (e.g. row-level security, DEFINER functions, a Mermaid flow diagram) and state that isolation elsewhere is untouched.}

## Interface

<!-- Informed by the Phase 6.6 mockup-inventory gate. The mockup is the UI source of truth.
     Omit this whole section if the PRD has no UI deliverable and no mockup. -->

**Mockup: {present — `path/to/mockup` | none}.**

**When a mockup exists**, it is the UI source of truth: implementation PORTS its screens, components, and flows into the app shell using the existing component library and `docs/ux` conventions — it does NOT redesign them. This PRD specifies only the data/contracts/logic behind the screens.

**When no mockup exists**, a mockup is a prerequisite for the Interface phase: either (default) that phase begins by building a design-system mockup (component library, stubbed data) which becomes the source of truth, or — only if the screens are trivial and derivative of existing ones — specify them directly below. Never let implementation invent a UI ad hoc.

{Mockup Files table + per-file Section Inventory, carried from the Phase 6.6 gate:}

| File | Type | Fidelity | Purpose |
|---|---|---|---|
| `{path/to/mockup.html}` | HTML | CANONICAL / REFERENCE / EXPLORATORY | {which screen/flow it shows} |

Screens:
- **{Screen}** (`/route`) — {key elements}; maps to one acceptance case.

## Backend

{Module placement; guards — per Roles & security; the endpoint / entry-point surface.}

| Endpoint / entry point | Purpose |
|---|---|
| `{METHOD /path}` | {what it does} |

{Key transaction or logic shapes that realise the Rules — reference the rule, describe the mechanism (not the rule again).}

## Data

<!-- Schema SHAPE only — tables, columns, relationships. Access logic (RLS / DEFINER) lives under Roles & security.
     Include a fenced Mermaid erDiagram for a non-trivial schema. Flag every NEW table/column with 🟢 and bold.
     The schema-changes table is produced by the Phase 6.5 gate; OMIT it on greenfield projects with no schema files. -->

{Include a fenced Mermaid `erDiagram` here if the schema is non-trivial.}

🟢 **New tables:** {list}.  🟢 **New columns:** {list}.

### Schema changes (🟢 = new)

| Reference | Change | Schema Source | Notes / semantic assumption |
|---|---|---|---|
| `{table.column}` | reuse / 🟢 **NEW** / modify | {file:line or "—"} | {what the PRD assumes this represents} |

## Implementation Phases

**Feasibility: {HIGH/MEDIUM/LOW}** — {one line: what already exists vs the genuinely novel work.}

<!--
  This table is machine-read by prp-plan / prp-implement / prp-ralph / prp-whats-next — keep the
  column names and the STATUS vocabulary below.
  Seq:      human concurrency grouping — phases sharing a Seq can run in parallel.
  Status:   pending | in-progress | complete   (updated as work proceeds; this doc doubles as a tracker)
  Depends:  phase numbers that must complete first (e.g. "3, 4" or "-")
  PRP Plan: link to the generated plan file once created (filled by prp-plan)
  Flag any phase needing a person with [HUMAN REQD]. Always end with the delivery tail:
  docs+PR, human-approved deploy, confirmation testing.
-->

| Seq | # | Phase | Description | Status | Depends | PRP Plan |
|---|---|---|---|---|---|---|
| 1 | 1 | {Discovery / sign-off, if a human gate is needed} **[HUMAN REQD]** | {what it delivers; done when {signal}} | pending | - | - |
| 2 | 2 | {phase} | {delivers …; done when …} | pending | 1 | - |
| … | … | {…} | {…} | pending | … | - |
| {n-2} | {n-2} | Docs + handoff + raise PR | {docs updated; PR raised via `prp-pr`} | pending | {…} | - |
| {n-1} | {n-1} | Approve PR + deploy to Dev **[HUMAN REQD]** | {PR reviewed + merged; Dev deploy green} | pending | {n-2} | - |
| {n} | {n} | Confirmation testing on Dev (agent or human) | {smoke + UAT pass on Dev} | pending | {n-1} | - |

{One line on any cross-sequence dependency.}

## Success Criteria

**Hypothesis:** We believe {capability} will {solve problem} for {users}. We'll know we're right when every metric below passes.

| Metric | Target | How measured |
|---|---|---|
| {metric} | {target} | {test / method} |

## Testing Strategy

### Unit Testing
- **Framework**: {jest | vitest | pytest | go test | cargo test | etc.}
- **Location**: {tests/ | src/**/*.test.ts | etc.}
- **Run**: `{test command}`

### Integration Testing
- **Approach**: {API / service / DB tests}
- **Run**: `{command}`

### E2E Testing
- **Framework**: {Playwright | Cypress | none | TBD}
- **Config**: `{path to config file, or "N/A"}`
- **Run**: `{npx playwright test | etc.}`
- **Approach**: {brief description; if no e2e framework, user-journey validation scripts are used instead}

_Per-phase scenario detail lives with the phase plans; this section captures the framework + commands (also persisted to CLAUDE.md by Phase 7.5)._

## Risk

| Risk | Likelihood | Mitigation |
|---|---|---|
| {risk} | H / M / L | {mitigation} |

## References

<!-- Skippable by humans; exists so any claim above traces to a primary source and the planner has context pointers.
     Absorbs what used to be the separate Evidence and Research Summary sections. -->

**Sources**
- {source doc / spec / mockup / data point — link + what it establishes}

**Precedents**
- {prior PRD or pattern this reuses}

**Decisions** (incl. resolved open questions, tagged *OQ*)

| Decision | Choice | Rationale |
|---|---|---|
| {decision} | {choice} | {why; tag *OQ* if it resolved an open question} |

---

*Generated: {timestamp}*
*Status: DRAFT - needs validation*
```

---

## Phase 7.1: VISION TRACKER - Update Parent Vision

**Skip this phase if `VISION_PATH` is not set.**

If this PRD was created under a vision (`--vision` was provided):

1. Read the vision file at `VISION_PATH`
2. Find the `## PRD Tracker` table
3. Count existing data rows to determine the next row number
4. Use the **Edit** tool to append a new row to the tracker table:
   ```
   | {next-row-#} | {PRD-name} | {description} | pending | - | - | [{PRD-ID}]({relative-path-to-prd}) |
   ```
   Where:
   - `{next-row-#}` is the next sequential row number
   - `{PRD-name}` is the product/feature name from the PRD
   - `{description}` is a one-line description of what the PRD delivers
   - `{PRD-ID}` is the numbered PRD identifier (e.g., `V001-PRD003`)
   - `{relative-path-to-prd}` is the path from the vision file to the PRD file (typically `../prds/{prd-filename}`)

5. If the tracker table contains the template placeholder row (`| 1 | {PRD name} |`), replace it with the actual PRD row instead of appending.

**GATE**: No user interaction needed. This is automatic.

---

## Phase 7.5: PERSIST - Update CLAUDE.md with Testing Config

After generating the PRD, check if the project has a `CLAUDE.md` file. If it does, and the testing strategy includes e2e framework information not already documented there, update `CLAUDE.md` with a `## Testing` section (or update the existing one).

**Steps:**

1. Read the project's `CLAUDE.md` (if it exists)
2. Check if it already has `## Testing` or `## E2E Testing` section
3. If e2e config was discovered and isn't already in CLAUDE.md, append:

```markdown
## Testing

### Unit Tests
- **Framework**: {framework}
- **Run**: `{command}`

### E2E Tests
- **Framework**: {framework}
- **Config**: `{config path}`
- **Test directory**: `{directory}`
- **Run**: `{command}`
```

4. If CLAUDE.md already has testing info, verify it's current and update if stale
5. If no CLAUDE.md exists, skip this step — don't create one just for testing config

**Why**: This ensures all future plans, agents, and Ralph loops know the project's testing setup without re-discovering it every time.

**GATE**: No user interaction needed. This is automatic.

---

## Phase 7.75: GIT - Apply Git Strategy

After generating the PRD file (and CLAUDE.md updates), apply the project's git strategy.

**Read git strategy**: Read the project's `CLAUDE.md` and find the `## Git Strategy` section. Extract the value after `Strategy:` and `Base Branch:`. Defaults: strategy=`main-only`, base branch=`main`.

- **`none`**: No git operations.
- **`main-only`**: Commit the PRD file on the current branch:
  ```bash
  git add PRPs/prds/{numbered-name}.prd.md
  git commit -m "docs: add PRD {PRD-ID} for {feature-name}"
  ```
- **`branch-per-prd`**: Create a feature branch using hierarchical naming and commit:
  ```bash
  # If PRD is linked to a vision:
  git checkout -b feat/{VISION_ID}/{PRD-ID}-{prd-kebab-name}
  # If standalone PRD (no vision):
  git checkout -b feat/{PRD-ID}-{prd-kebab-name}

  git add PRPs/prds/{numbered-name}.prd.md
  git commit -m "docs: add PRD {PRD-ID} for {feature-name}"
  ```
- **`branch-per-phase`**: Commit on base branch (phase branches created later by prp-plan):
  ```bash
  git add PRPs/prds/{numbered-name}.prd.md
  git commit -m "docs: add PRD {PRD-ID} for {feature-name}"
  ```

> `PRPs/.initials.json` is gitignored (set up in step 7.0.a) — do not stage it. Legacy `PRPs/.counters.json` is no longer read or written; if it exists in the repo, leave it in place.

If `VISION_PATH` is set, also `git add` the updated vision file (for PRD Tracker changes).

**GATE**: No user interaction needed. This is automatic.

---

## Phase 8: OUTPUT - Summary

After generating, report:

```markdown
## PRD Created

**File**: `PRPs/prds/{numbered-name}.prd.md`
**PRD ID**: {PRD-ID} (e.g., V001-PRD003 or PRD004)

### Summary

**Feature**: {One line — what it is}
**Problem**: {One line}
**Key Metric**: {Primary success metric}

### Validation Status

| Section | Status |
|---------|--------|
| Feature & problem | {Validated/Assumption} |
| User Research | {Done/Needed} |
| Technical Feasibility | {Assessed/TBD} |
| Schema Fitness | {Passed / Skipped (--skip-schema-check) / N/A (greenfield)} |
| Roles & security | {Defined/N/A} |
| Testing approach | {Defined/TBD} |
| Success Criteria | {Defined/Needs refinement} |

### Open Questions ({count})

{List the open questions that need answers}

### Recommended Next Step

{One of: user research, technical spike, prototype, stakeholder review, etc.}

### Implementation Phases

| Seq | # | Phase | Status | Depends | PRP Plan |
|---|---|-------|--------|---------|----------|
{Table of phases from PRD}

### To Start Implementation

Run: `/prp-plan PRPs/prds/{numbered-name}.prd.md`

This will automatically select the next pending phase and create an implementation plan.
```

---

## Question Flow Summary

```
┌─────────────────────────────────────────────────────────┐
│  INITIATE: "What do you want to build?"                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  FOUNDATION: Who, What, Why, Why now, How to measure    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GROUNDING: Market research, competitor analysis        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  DEEP DIVE: Vision, Primary user, JTBD, Constraints     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GROUNDING: Technical feasibility, codebase exploration │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  DECISIONS: MVP, Must-haves, Hypothesis, Out of scope   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GATE: Schema fitness — references resolve (ADR-0001)   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GENERATE: Write PRD to PRPs/prds/              │
└─────────────────────────────────────────────────────────┘
```

---

## Success Criteria

- **PROBLEM_VALIDATED**: Problem is specific and evidenced (or marked as assumption)
- **USER_DEFINED**: Primary user is concrete, not generic
- **HYPOTHESIS_CLEAR**: Testable hypothesis with measurable outcome
- **SCOPE_BOUNDED**: Clear must-haves and explicit out-of-scope
- **QUESTIONS_ACKNOWLEDGED**: Uncertainties are listed, not hidden
- **SCHEMA_VERIFIED**: Every existing-table/column reference resolves against the project's schema, with semantic assumption recorded; gate passed cleanly or `--skip-schema-check` is logged. No-op on greenfield. (ADR-0001)
- **TESTING_STRATEGY_DEFINED**: Unit, e2e, and integration testing approach established
- **ACTIONABLE**: A skeptic could understand why this is worth building
- **NUMBERED**: PRD filename uses a valid ID — date+initials (`PRD{YYYYMMDD}{II}[s]`) for new artifacts, or legacy counter (`PRD{NNN}`) for pre-existing artifacts
- **VISION_LINKED**: If `--vision` provided, PRD includes Vision Reference section and vision's PRD Tracker is updated
