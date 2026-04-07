---
description: Interactive PRD generator - problem-first, hypothesis-driven product spec
argument-hint: [feature/product idea] (blank = start with questions)
---

# Product Requirements Document Generator

**Input**: $ARGUMENTS

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

## Phase 0.5: ARGUMENT PARSING - Vision and Input

**Check if `$ARGUMENTS` contains `--vision {path}`:**

1. If `--vision` is present, extract the vision file path and strip it from the remaining arguments.
2. Read the vision file to extract:
   - **Vision ID**: from filename (e.g., `V001` from `V001-user-onboarding.vision.md`)
   - **Vision Title**: from the `# {title}` heading
   - **Section headings**: for building anchor links in the Vision Reference table
3. Store `VISION_PATH`, `VISION_ID`, and `VISION_TITLE` for use in later phases.
4. The remaining text after stripping `--vision {path}` is the feature description (same as today).

**If `--vision` is NOT present**: Proceed as normal. `VISION_PATH` is empty.

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

## Phase 7: GENERATE - Write PRD

### 7.0 Numbering and Filename

1. Read `.claude/PRPs/.counters.json` (use Read tool). If the file does not exist, treat it as `{"vision": 0, "prd": 0, "plan": 0}`.
2. Increment the `prd` counter by 1.
3. Write updated counters back to `.claude/PRPs/.counters.json` (use Write tool).
4. Zero-pad the new number to 3 digits (e.g., `3` → `003`).
5. If the Read tool returns a parse error, warn the user and ask them to check the file manually. Do not overwrite a corrupted file.

**Generate filename:**
- If `VISION_PATH` is set (vision-linked): `V{VNN}-PRD{NNN}-{kebab-case-name}.prd.md` (e.g., `V001-PRD003-auth-middleware.prd.md`)
- If standalone (no vision): `PRD{NNN}-{kebab-case-name}.prd.md` (e.g., `PRD004-search-api.prd.md`)

**Output path**: `.claude/PRPs/prds/{numbered-filename}`

Create directory if needed: `mkdir -p .claude/PRPs/prds`

### PRD Template

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

Anchors use GitHub-style slugs: lowercase, spaces→hyphens, strip special chars (e.g., `Problem / Opportunity` → `#problem--opportunity`). The relative path goes from the PRD's location (`.claude/PRPs/prds/`) to the vision file (`.claude/PRPs/visions/`), typically `../visions/{vision-filename}`.

**If `VISION_PATH` is NOT set**, omit the Vision Reference section entirely.

```markdown
# {Product/Feature Name}

## Problem Statement

{2-3 sentences: Who has what problem, and what's the cost of not solving it?}

## Evidence

- {User quote, data point, or observation that proves this problem exists}
- {Another piece of evidence}
- {If none: "Assumption - needs validation through [method]"}

## Proposed Solution

{One paragraph: What we're building and why this approach over alternatives}

## Key Hypothesis

We believe {capability} will {solve problem} for {users}.
We'll know we're right when {measurable outcome}.

## What We're NOT Building

- {Out of scope item 1} - {why}
- {Out of scope item 2} - {why}

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|--------------|
| {Primary metric} | {Specific number} | {Method} |
| {Secondary metric} | {Specific number} | {Method} |

## Open Questions

- [ ] {Unresolved question 1}
- [ ] {Unresolved question 2}

---

## Users & Context

**Primary User**
- **Who**: {Specific description}
- **Current behavior**: {What they do today}
- **Trigger**: {What moment triggers the need}
- **Success state**: {What "done" looks like}

**Job to Be Done**
When {situation}, I want to {motivation}, so I can {outcome}.

**Non-Users**
{Who this is NOT for and why}

---

## Solution Detail

### Core Capabilities (MoSCoW)

| Priority | Capability | Rationale |
|----------|------------|-----------|
| Must | {Feature} | {Why essential} |
| Must | {Feature} | {Why essential} |
| Should | {Feature} | {Why important but not blocking} |
| Could | {Feature} | {Nice to have} |
| Won't | {Feature} | {Explicitly deferred and why} |

### MVP Scope

{What's the minimum to validate the hypothesis}

### User Flow

{Critical path - shortest journey to value}

---

## Technical Approach

**Feasibility**: {HIGH/MEDIUM/LOW}

**Architecture Notes**
- {Key technical decision and why}
- {Dependency or integration point}

**Technical Risks**

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| {Risk} | {H/M/L} | {How to handle} |

---

## Testing Strategy

### Unit Testing
- **Framework**: {jest | vitest | pytest | go test | cargo test | etc.}
- **Location**: {tests/ | src/**/*.test.ts | etc.}
- **Run**: `{test command}`

### E2E Testing
- **Framework**: {Playwright | Cypress | none | TBD}
- **Config**: `{path to config file, or "N/A"}`
- **Test directory**: `{e2e/ | tests/e2e/ | etc.}`
- **Run command**: `{npx playwright test | npx cypress run | etc.}`
- **Approach**: {Brief description of e2e testing approach}

_If no e2e framework: user journey validation scripts (bash) will be used instead._

### Integration Testing
- **Approach**: {API tests, service tests, etc.}
- **Run**: `{command}`

---

## Implementation Phases

<!--
  STATUS: pending | in-progress | complete
  PARALLEL: phases that can run concurrently (e.g., "with 3" or "-")
  DEPENDS: phases that must complete first (e.g., "1, 2" or "-")
  PRP: link to generated plan file once created
-->

| # | Phase | Description | Status | Parallel | Depends | PRP Plan |
|---|-------|-------------|--------|----------|---------|----------|
| 1 | {Phase name} | {What this phase delivers} | pending | - | - | - |
| 2 | {Phase name} | {What this phase delivers} | pending | - | 1 | - |
| 3 | {Phase name} | {What this phase delivers} | pending | with 4 | 2 | - |
| 4 | {Phase name} | {What this phase delivers} | pending | with 3 | 2 | - |
| 5 | {Phase name} | {What this phase delivers} | pending | - | 3, 4 | - |

### Phase Details

**Phase 1: {Name}**
- **Goal**: {What we're trying to achieve}
- **Scope**: {Bounded deliverables}
- **Success signal**: {How we know it's done}

**Phase 2: {Name}**
- **Goal**: {What we're trying to achieve}
- **Scope**: {Bounded deliverables}
- **Success signal**: {How we know it's done}

{Continue for each phase...}

### Parallelism Notes

{Explain which phases can run in parallel and why, e.g., "Phases 3 and 4 can run in parallel in separate worktrees as they touch different domains (frontend vs auth)"}

---

## Decisions Log

| Decision | Choice | Alternatives | Rationale |
|----------|--------|--------------|-----------|
| {Decision} | {Choice} | {Options considered} | {Why this one} |

---

## Research Summary

**Market Context**
{Key findings from market research}

**Technical Context**
{Key findings from technical exploration}

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
  git add .claude/PRPs/prds/{numbered-name}.prd.md .claude/PRPs/.counters.json
  git commit -m "docs: add PRD {PRD-ID} for {feature-name}"
  ```
- **`branch-per-prd`**: Create a feature branch using hierarchical naming and commit:
  ```bash
  # If PRD is linked to a vision:
  git checkout -b feat/{VISION_ID}/{PRD-ID}-{prd-kebab-name}
  # If standalone PRD (no vision):
  git checkout -b feat/{PRD-ID}-{prd-kebab-name}

  git add .claude/PRPs/prds/{numbered-name}.prd.md .claude/PRPs/.counters.json
  git commit -m "docs: add PRD {PRD-ID} for {feature-name}"
  ```
- **`branch-per-phase`**: Commit on base branch (phase branches created later by prp-plan):
  ```bash
  git add .claude/PRPs/prds/{numbered-name}.prd.md .claude/PRPs/.counters.json
  git commit -m "docs: add PRD {PRD-ID} for {feature-name}"
  ```

If `VISION_PATH` is set, also `git add` the updated vision file (for PRD Tracker changes).

**GATE**: No user interaction needed. This is automatic.

---

## Phase 8: OUTPUT - Summary

After generating, report:

```markdown
## PRD Created

**File**: `.claude/PRPs/prds/{numbered-name}.prd.md`
**PRD ID**: {PRD-ID} (e.g., V001-PRD003 or PRD004)

### Summary

**Problem**: {One line}
**Solution**: {One line}
**Key Metric**: {Primary success metric}

### Validation Status

| Section | Status |
|---------|--------|
| Problem Statement | {Validated/Assumption} |
| User Research | {Done/Needed} |
| Technical Feasibility | {Assessed/TBD} |
| Testing Strategy | {Defined/TBD} |
| Success Metrics | {Defined/Needs refinement} |

### Open Questions ({count})

{List the open questions that need answers}

### Recommended Next Step

{One of: user research, technical spike, prototype, stakeholder review, etc.}

### Implementation Phases

| # | Phase | Status | Can Parallel |
|---|-------|--------|--------------|
{Table of phases from PRD}

### To Start Implementation

Run: `/prp-plan .claude/PRPs/prds/{numbered-name}.prd.md`

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
│  GENERATE: Write PRD to .claude/PRPs/prds/              │
└─────────────────────────────────────────────────────────┘
```

---

## Success Criteria

- **PROBLEM_VALIDATED**: Problem is specific and evidenced (or marked as assumption)
- **USER_DEFINED**: Primary user is concrete, not generic
- **HYPOTHESIS_CLEAR**: Testable hypothesis with measurable outcome
- **SCOPE_BOUNDED**: Clear must-haves and explicit out-of-scope
- **QUESTIONS_ACKNOWLEDGED**: Uncertainties are listed, not hidden
- **TESTING_STRATEGY_DEFINED**: Unit, e2e, and integration testing approach established
- **ACTIONABLE**: A skeptic could understand why this is worth building
- **NUMBERED**: PRD filename uses counter-based numbering from `.counters.json`
- **VISION_LINKED**: If `--vision` provided, PRD includes Vision Reference section and vision's PRD Tracker is updated
