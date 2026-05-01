# Feature: Add Vision Layer and Artifact Numbering System

## Feature Description

Introduce a "Vision" layer that sits above PRDs in the PRP framework hierarchy. A Vision captures high-level objectives, problem space, success criteria, and scope boundaries for major milestones that span multiple PRDs. Additionally, implement a hierarchical numbering system across visions, PRDs, and plans to provide clear lineage and discoverability as projects grow.

## User Story

As a developer working on a major application milestone
I want to define a strategic vision that spawns and tracks multiple PRDs
So that each PRD has consistent strategic context and I can trace artifacts back to the broader objective

## Problem Statement

Currently, PRDs are standalone documents. When a major milestone spans multiple PRDs, the developer must:
- Re-explain the bigger picture in each PRD
- Manually track which PRDs relate to which strategic objective
- Lose strategic coherence as the number of PRDs grows
- Struggle to find the right artifact as `.claude/PRPs/` accumulates files with no hierarchy or numbering

There is no mechanism to capture the "why behind the why" — the strategic layer that gives PRDs their direction.

## Solution Statement

### 1. Vision Layer

Create a `/prp-vision` command that runs an interactive discovery flow (mirroring `/prp-prd`) to produce a vision document. The vision:

- Captures the strategic problem, objectives, success criteria, scope boundaries, assumptions/risks, and external context references
- Contains a **PRD Tracker** (same format as the PRD's Implementation Phases table) that tracks PRDs spawned under it
- Is a **living document** — the PRD tracker updates as PRDs are created; other sections remain stable
- PRDs reference back to the vision by file path (no content duplication)
- Stored in `.claude/PRPs/visions/` (active) and `.claude/PRPs/visions/completed/` (done)
- Only one active vision per project at a time; completed visions move to the `completed/` folder
- During context gathering, uses `context-add` to register external references in the project's `context-map.md`

### 2. Hierarchical Numbering System

Introduce artifact numbering that encodes lineage:

```
V001                    — Vision
V001-PRD001             — PRD linked to vision V001
V001-PRD001-P001        — Plan under that PRD
PRD002                  — Standalone PRD (no vision)
PRD002-P001             — Plan under standalone PRD
```

- Numbering is global per project (counters never reset)
- Numbers are zero-padded to 3 digits
- Encoded in filenames: `V001-user-onboarding.vision.md`, `V001-PRD001-auth-middleware.prd.md`
- Standalone PRDs and plans (without a vision) get their own sequential number

## Feature Metadata

**Feature Type**: New Capability
**Estimated Complexity**: High
**Primary Systems Affected**:
- `plugins/prp-core/commands/` — New `prp-vision` command
- `plugins/prp-core/commands/prp-prd.md` — Update to support vision references and numbering
- `plugins/prp-core/commands/prp-plan.md` — Update to support numbering
- `plugins/prp-core/templates/` — New vision template
- `.claude/PRPs/visions/` — New artifact directory
**Dependencies**:
- Context skills (`context-add`, `context-read`) — must exist (confirmed present)
- Existing `prp-prd` command — will be modified
- Existing `prp-plan` command — will be modified

---

## CONTEXT REFERENCES

### Relevant Codebase Files

- `plugins/prp-core/commands/prp-prd.md` — PRD command with interactive discovery flow (pattern to mirror for vision discovery)
- `plugins/prp-core/commands/prp-plan.md` — Plan command (needs numbering integration)
- `plugins/prp-core/skills/context-add/SKILL.md` — Context-add skill (vision will invoke during context gathering)
- `plugins/prp-core/skills/context-read/SKILL.md` — Context-read skill (vision context loaded by downstream PRDs)
- `plugins/prp-core/templates/context-map.md` — Context map template (vision references registered here)
- `.claude/PRPs/features/completed/add-prp-core-runner-skill.md` — Example feature doc format

### New Files to Create

- `plugins/prp-core/commands/prp-vision.md` — Interactive vision creation command
- `plugins/prp-core/templates/vision.md` — Vision document template

### Files to Modify

- `plugins/prp-core/commands/prp-prd.md` — Add vision reference support + numbering
- `plugins/prp-core/commands/prp-plan.md` — Add numbering
- `CLAUDE.md` — Document the vision command and numbering system

---

## DESIGN DECISIONS

### Vision Document Structure

| Section | Purpose | Living? |
|---------|---------|---------|
| Problem / Opportunity | The strategic gap being addressed | No |
| Objectives | What success looks like at the vision level | No |
| Success Criteria | Measurable outcomes | No |
| Scope Boundaries | What's in, what's explicitly out | No |
| Key Assumptions & Risks | What could invalidate the vision | No |
| Context & References | External sources (repos, URLs, docs) | No |
| Git Strategy | Branching model for PRDs and plans under this vision | No |
| PRD Tracker | Living table of PRDs spawned from this vision | **Yes** |

### Vision Discovery Flow

```
┌─────────────────────────────────────────────────────────┐
│  INITIATE: "What major objective are you pursuing?"      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  PROBLEM SPACE: What's the gap? Who's affected? Impact? │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  CURRENT STATE: What exists? What's been tried?         │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  DESIRED OUTCOME: What does the world look like solved? │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  BOUNDARIES: What's out of scope? What constraints?     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  CONTEXT GATHERING: External refs → context-map.md      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  SUCCESS DEFINITION: How will you measure it worked?    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GIT STRATEGY: Branching model (none / prd / plan)      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GENERATE: Write vision to .claude/PRPs/visions/        │
└─────────────────────────────────────────────────────────┘
```

### Numbering System (Option B)

Hierarchical with standalone support:

- `V001` — Vision (global counter)
- `V001-PRD001` — PRD linked to a vision (counter scoped per vision)
- `V001-PRD001-P001` — Plan under a vision-linked PRD
- `PRD002` — Standalone PRD (global counter, shared with vision-linked PRDs)
- `PRD002-P001` — Plan under standalone PRD

**Counter tracking**: A `.claude/PRPs/.counters.json` file tracks the next available number for each type:

```json
{
  "vision": 0,
  "prd": 0,
  "plan": 0
}
```

Values represent the **last assigned number** (not the next). To assign a new number: read the file, increment the relevant counter, write the file back, then zero-pad to 3 digits for the filename.

**Counter management mechanics** (for all PRP commands — vision, prd, plan):

1. Use the **Read** tool to read `.claude/PRPs/.counters.json`. If the file does not exist, treat it as `{"vision": 0, "prd": 0, "plan": 0}`.
2. Increment the relevant counter (e.g., `"prd": 2` → `"prd": 3`).
3. Use the **Write** tool to write the updated JSON back to `.claude/PRPs/.counters.json`.
4. Zero-pad the new number to 3 digits for the filename (e.g., `3` → `003`).
5. If the Read tool returns a parse error, warn the user and ask them to check the file manually. Do not overwrite a corrupted file.

**PRD numbering under a vision**: The global `prd` counter is used for ALL PRDs regardless of whether they are vision-linked or standalone. This ensures every PRD has a globally unique number. The vision prefix is prepended for linked PRDs:
- Vision-linked: `V001-PRD003-feature-name.prd.md` (global PRD counter = 3)
- Standalone: `PRD004-feature-name.prd.md` (global PRD counter = 4)

The vision's PRD Tracker table records which PRD numbers belong to it. There is no per-vision PRD counter.

### PRD ↔ Vision Relationship

- PRDs reference their parent vision by file path in a `## Vision Reference` section
- The vision's PRD Tracker is updated when a new PRD is created under it
- PRDs can exist without a vision (standalone)
- The `/prp-prd` command gains an optional `--vision` argument to link to a vision

**Vision Reference section format in PRDs** (added when `--vision` is provided):

```markdown
## Vision Reference

| Field | Value |
|-------|-------|
| Vision | [V001 — User Onboarding](.claude/PRPs/visions/V001-user-onboarding.vision.md) |
| Problem | [Problem / Opportunity](.claude/PRPs/visions/V001-user-onboarding.vision.md#problem--opportunity) |
| Objectives | [Objectives](.claude/PRPs/visions/V001-user-onboarding.vision.md#objectives) |
| Success Criteria | [Success Criteria](.claude/PRPs/visions/V001-user-onboarding.vision.md#success-criteria) |
| Scope | [Scope Boundaries](.claude/PRPs/visions/V001-user-onboarding.vision.md#scope-boundaries) |
```

The table uses relative markdown links with anchor fragments to point to specific vision sections. This gives the PRD reader (human or agent) direct navigability without duplicating content. Anchors use GitHub-style slugs (lowercase, spaces→hyphens, strip special chars).

### Context Integration

During vision creation (Phase 6: Context Gathering):
1. Ask user for external references (repos, docs, URLs, Obsidian notes, etc.)
2. Add each reference to the vision doc's Context & References section
3. For each reference, invoke context-add by using the **Skill** tool: `skill: "prp-core:context-add", args: "{path-or-url}"`. This runs the context-add skill's full flow (auto-detect source type, resolve paths, ask for section/label/description, write to context-map.md). When the skill prompts for a section name, suggest the vision identifier (e.g., `V001 User Onboarding`) to group vision context together in context-map.md.
4. If the Skill tool call fails or context-add is unavailable, log a warning but continue vision creation — context registration is not a blocker.

### Git Strategy (Vision-Level)

The vision defines the branching model that all PRDs and plans under it follow. This is **optional** — if not set, defaults to `none`. The three options:

**`none`** — No branching. All work happens directly on the main/current branch.
- PRDs and plans commit directly to main
- No PRs created automatically
- Simplest model, suitable for solo work or small changes

**`prd`** — One feature branch per PRD. PR created when the PRD is fully implemented.
```
main
 └── feat/V001-PRD001-auth          ← branch created when PRD starts
      ├── commit: plan P001 work
      ├── commit: plan P002 work
      └── PR → main                 ← created when all plans under this PRD are done
```
- Branch naming: `feat/{prd-id}-{kebab-name}` (e.g., `feat/V001-PRD001-auth-middleware`)
- All plans under the PRD commit to the same branch
- Single PR back to main when the PRD is complete

**`plan`** — One branch per PRD, with sub-branches per plan. PRs at each level.
```
main
 └── feat/V001-PRD001-auth          ← PRD branch, created when PRD starts
      ├── feat/V001-PRD001-P001-setup   ← plan sub-branch
      │    └── PR → feat/V001-PRD001-auth    ← PR when plan is done
      ├── feat/V001-PRD001-P002-endpoints
      │    └── PR → feat/V001-PRD001-auth    ← PR when plan is done
      └── PR → main                          ← PR when all plans merged to PRD branch
```
- PRD branch naming: `feat/{prd-id}-{kebab-name}`
- Plan sub-branch naming: `feat/{plan-id}-{kebab-name}`
- Each plan implementation ends with a PR back to the PRD branch
- When all plans are merged to the PRD branch, a final PR goes from PRD branch → main

**How this flows downstream**:
- The vision's git strategy is recorded in the vision doc's `## Git Strategy` section
- When `/prp-prd --vision` creates a PRD, it reads the vision's git strategy and records it in the PRD's `Technical Approach > Git Strategy` field (mapped: `none`→`none`, `prd`→`branch-per-prd`, `plan`→`branch-per-phase`)
- `/prp-plan` and `/prp-implement` already respect the PRD's git strategy field — no changes needed there
- This means the vision sets the strategy once, and it cascades automatically through PRDs → plans → implementations

### Active Vision Lifecycle

- One active vision at a time per project
- When all PRDs under a vision are complete, prompt to move it to `completed/`
- Completed visions retain their numbering — numbers are never reused

---

## IMPLEMENTATION PLAN

### Phase 1: Foundation — Template and Numbering Infrastructure

**Tasks:**
- Create the vision document template (`plugins/prp-core/templates/vision.md`)
- Design and implement the `.claude/PRPs/.counters.json` schema
- Create `.claude/PRPs/visions/` and `.claude/PRPs/visions/completed/` directory conventions

### Phase 2: Vision Command — `/prp-vision`

**Tasks:**
- Create `plugins/prp-core/commands/prp-vision.md` with full interactive discovery flow
- Implement all 8 phases (Initiate → Problem Space → Current State → Desired Outcome → Boundaries → Context Gathering → Success Definition → Generate)
- Integrate `context-add` invocation during context gathering phase
- Implement counter increment and vision numbering on generation

### Phase 3: PRD Integration — Vision References and Numbering

**Tasks:**
- Modify `plugins/prp-core/commands/prp-prd.md` to:
  - Accept optional `--vision` argument (path to vision file)
  - Add `## Vision Reference` section to PRD template when linked
  - Assign numbered filename using counter system
  - Update parent vision's PRD Tracker table when a PRD is created under it
- Modify `plugins/prp-core/commands/prp-plan.md` to:
  - Assign numbered filename using counter system

### Phase 4: Documentation

**Tasks:**
- Update `CLAUDE.md` to document the vision command, numbering system, and updated workflow
- Update `plugins/prp-core/README.md` with vision layer documentation

---

## STEP-BY-STEP TASKS

### Task 1: CREATE vision template

- **IMPLEMENT**: Create `plugins/prp-core/templates/vision.md` with the exact content below
- **PATTERN**: Mirror the structure and commenting style of `plugins/prp-core/templates/context-map.md`
- **VALIDATE**: `test -f plugins/prp-core/templates/vision.md && echo "Template created"`
- **EXACT TEMPLATE CONTENT**:

```markdown
---
version: 1
description: Vision document — strategic layer above PRDs for major milestones
id: "{vision-id}"
status: active
created: "{timestamp}"
---

# {Vision Title}

<!--
  This is a Vision document — the strategic layer that sits above PRDs.
  It captures the high-level objectives, problem space, and success criteria
  for a major milestone that spans multiple PRDs.

  LIFECYCLE:
    - Only ONE vision is active per project at a time
    - The PRD Tracker section is the only "living" part — update it as PRDs are created
    - When all PRDs are complete, move this file to .claude/PRPs/visions/completed/
    - Numbers are never reused

  USAGE:
    - Create PRDs under this vision: /prp-prd --vision {path-to-this-file}
    - PRDs reference this vision by file path (no content duplication)
-->

## Problem / Opportunity

<!-- What strategic gap or opportunity does this vision address? Who is affected and what is the impact? -->

{Description of the problem or opportunity}

## Objectives

<!-- What does this vision achieve? Focus on outcomes, not implementation. -->

- {Objective 1}
- {Objective 2}
- {Objective 3}

## Success Criteria

<!-- How will you measure that this vision has been achieved? Be specific and measurable. -->

| Criteria | Target | How Measured |
|----------|--------|--------------|
| {Criteria 1} | {Specific target} | {Measurement method} |
| {Criteria 2} | {Specific target} | {Measurement method} |

## Scope Boundaries

### In Scope

- {What is included}

### Out of Scope

- {What is explicitly excluded} — {why}

### Constraints

- {Known limitations or constraints}

## Key Assumptions & Risks

### Assumptions

- {Assumption 1} — if wrong: {consequence}
- {Assumption 2} — if wrong: {consequence}

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| {Risk 1} | {H/M/L} | {H/M/L} | {How to handle} |

## Context & References

<!-- External sources gathered during vision creation. These are also registered in the project's context-map.md for discoverability by downstream PRP commands. -->

| Label | Type | Path / URL | Description |
|-------|------|------------|-------------|
| {Source name} | {web/project/file/second-brain/obsidian/etc.} | {path or URL} | {What it contains} |

## Git Strategy

<!--
  Branching model for all PRDs and plans under this vision. Optional — defaults to none.
  This value cascades: PRDs created under this vision inherit it automatically.

  OPTIONS:
    none  — All work on main branch, no PRs created automatically
    prd   — One branch per PRD, single PR → main when PRD is complete
    plan  — One branch per PRD + sub-branches per plan, PRs at each level
-->

**Strategy**: `{none | prd | plan}`

## PRD Tracker

<!--
  Living section — updated as PRDs are created under this vision.
  STATUS: pending | in-progress | complete
  PARALLEL: PRDs that can run concurrently (e.g., "with 3" or "-")
  DEPENDS: PRDs that must complete first (e.g., "1, 2" or "-")
  PRD FILE: link to generated PRD file once created
-->

| # | PRD | Description | Status | Parallel | Depends | PRD File |
|---|-----|-------------|--------|----------|---------|----------|
| 1 | {PRD name} | {What this PRD delivers} | pending | - | - | - |

---

*Generated: {timestamp}*
*Status: ACTIVE*
```

### Task 2: CREATE counter system design

- **IMPLEMENT**: Document the `.claude/PRPs/.counters.json` schema and initialization logic
- **PATTERN**: Simple JSON counter file, created on first use
- **DETAILS**:
  - Initial state: `{"vision": 0, "prd": 0, "plan": 0}`
  - Commands read, increment, and write back atomically
  - Zero-pad to 3 digits in filenames
  - If file doesn't exist, create with initial state
- **VALIDATE**: Counter logic is documented in the prp-vision command

### Task 3: CREATE `/prp-vision` command

- **IMPLEMENT**: Create `plugins/prp-core/commands/prp-vision.md`
- **PATTERN**: Mirror the phased interactive Q&A structure of `plugins/prp-core/commands/prp-prd.md` — same frontmatter format, same GATE pattern between phases, same grounding research pattern using subagents
- **DETAILS**:
  - Phase 1: INITIATE — Accept `$ARGUMENTS` or ask "What major objective are you pursuing?"
  - Phase 2: PROBLEM SPACE — Present all questions at once (like PRD Phase 2):
    1. What's the strategic gap or opportunity?
    2. Who is most affected by this problem?
    3. What is the cost of NOT addressing this?
    4. What is the scale/impact?
  - Phase 3: CURRENT STATE — Grounding research phase:
    - Use `subagent_type="prp-core:web-researcher"` for market/industry context
    - Use `subagent_type="prp-core:codebase-explorer"` if codebase exists (find related existing functionality)
    - Ask: "What exists today? What approaches have been tried? What worked/failed?"
  - Phase 4: DESIRED OUTCOME — Ask:
    1. What does the world look like when this is fully solved?
    2. What capabilities will exist that don't exist now?
    3. What will users/stakeholders be able to do differently?
  - Phase 5: BOUNDARIES — Ask:
    1. What is explicitly OUT of scope for this vision?
    2. What constraints exist? (time, budget, technical, organizational)
    3. What assumptions are you making? What would invalidate them?
  - Phase 6: CONTEXT GATHERING — Ask:
    > "Are there external references that provide important context for this vision? These could be URLs, documents in other repos, Obsidian notes, or other sources. I'll register each one in the project's context-map so downstream PRDs and plans can discover them automatically."
    - For each reference the user provides, do TWO things:
      1. Record it in the vision doc's Context & References table
      2. Invoke context-add via the **Skill** tool: `skill: "prp-core:context-add", args: "{the-reference}"`. When the skill asks for a section name, suggest the vision identifier (e.g., "V001 User Onboarding").
    - If the Skill tool call fails, log a warning and continue — context registration is not a blocker
    - When user says "done" or "no more", proceed to next phase
  - Phase 7: SUCCESS DEFINITION — Ask:
    1. How will you know this vision has been achieved?
    2. What specific, measurable outcomes define success?
    3. What timeframe are you targeting?
  - Phase 8: GIT STRATEGY (Optional) — Ask:
    > **How should we handle branching for this vision's work?**
    >
    > - `none` — All work on the main branch. No branches or PRs created automatically. (default)
    > - `prd` — One feature branch per PRD. A single PR back to main when the PRD is fully implemented.
    > - `plan` — One branch per PRD, with sub-branches for each plan. PRs created at the end of each plan implementation back to the PRD branch, and a final PR from the PRD branch back to main.
    
    If the user skips or says "none", record `none`. This value is written to the vision doc's `## Git Strategy` section and cascades to all PRDs created under this vision.
  - Phase 9: GENERATE — Write the vision doc:
    1. Read `.claude/PRPs/.counters.json` (use Read tool). If file doesn't exist, treat as `{"vision": 0, "prd": 0, "plan": 0}`.
    2. Increment `vision` counter by 1.
    3. Write updated counters back (use Write tool).
    4. Create directory: `mkdir -p .claude/PRPs/visions`
    5. Generate filename: `V{NNN}-{kebab-case-name}.vision.md` (e.g., `V001-user-onboarding.vision.md`)
    6. Fill in the vision template (from `plugins/prp-core/templates/vision.md`) with discovery answers
    7. Write the selected git strategy to the `## Git Strategy` section
    8. The PRD Tracker starts empty or with preliminary PRDs if the user mentioned specific features during discovery
  - Phase 9.5: GIT — Commit the vision doc:
    ```bash
    git add .claude/PRPs/visions/V{NNN}-{name}.vision.md .claude/PRPs/.counters.json
    git commit -m "docs: add vision V{NNN} for {feature-name}"
    git push -u origin HEAD
    ```
  - Phase 10: OUTPUT — Report summary with:
    - File path
    - Vision ID and title
    - Key objectives (bullet list)
    - Success criteria (table)
    - Next step: `Run: /prp-prd --vision .claude/PRPs/visions/V{NNN}-{name}.vision.md`
- **GOTCHA**: Must create `.claude/PRPs/visions/` directory if it doesn't exist
- **GOTCHA**: Must create/update `.claude/PRPs/.counters.json` for vision counter
- **GOTCHA**: Context gathering must invoke `context-add` via Skill tool, not just write to vision doc
- **GOTCHA**: Each phase must end with a GATE (wait for user response) before proceeding
- **VALIDATE**: `test -f plugins/prp-core/commands/prp-vision.md && echo "Command created"`

### Task 4: MODIFY `/prp-prd` to support vision references

- **IMPLEMENT**: Update `plugins/prp-core/commands/prp-prd.md`
- **PATTERN**: Add optional `--vision` argument handling and vision reference section
- **DETAILS**:
  - **Argument parsing**: At the start of Phase 1 (INITIATE), check if `$ARGUMENTS` contains `--vision {path}`. Extract the vision path and strip it from the remaining arguments. The remaining text is the feature description (same as today).
  - **If vision provided**:
    1. Read the vision file to extract: title, vision ID (from filename, e.g., `V001`), section headings, and git strategy
    2. After generating the PRD, insert a `## Vision Reference` section immediately after the PRD title, using this exact format:
       ```markdown
       ## Vision Reference

       | Field | Value |
       |-------|-------|
       | Vision | [V001 — {Vision Title}]({relative-path-to-vision-file}) |
       | Problem | [Problem / Opportunity]({relative-path-to-vision-file}#problem--opportunity) |
       | Objectives | [Objectives]({relative-path-to-vision-file}#objectives) |
       | Success Criteria | [Success Criteria]({relative-path-to-vision-file}#success-criteria) |
       | Scope | [Scope Boundaries]({relative-path-to-vision-file}#scope-boundaries) |
       ```
       Anchors use GitHub-style slugs: lowercase, spaces→hyphens, strip special chars (e.g., `Problem / Opportunity` → `#problem--opportunity`).
    3. Update the vision file's PRD Tracker table: use the **Edit** tool to append a new row:
       ```
       | {next-row-#} | {PRD-name} | {description} | pending | - | - | [{PRD-ID}]({relative-path-to-prd}) |
       ```
       The row number is determined by counting existing data rows in the tracker table.
  - **Numbering**:
    1. Read `.claude/PRPs/.counters.json` (Read tool). If missing, treat as `{"vision": 0, "prd": 0, "plan": 0}`.
    2. Increment `prd` counter by 1.
    3. Write updated counters back (Write tool).
    4. If vision-linked: filename = `V{NNN}-PRD{NNN}-{kebab-name}.prd.md` (e.g., `V001-PRD003-auth-middleware.prd.md`)
    5. If standalone: filename = `PRD{NNN}-{kebab-name}.prd.md` (e.g., `PRD004-search-api.prd.md`)
  - **If NO vision provided**: Existing behavior unchanged, except the filename now uses the numbered format (`PRD{NNN}-{name}.prd.md` instead of `{name}.prd.md`).
  - **Where to add these changes in prp-prd.md**:
    - Argument parsing: add to Phase 1 (INITIATE), before the first user interaction
    - Vision reference section: add to Phase 7 (GENERATE), in the PRD template, conditionally included
    - Git strategy cascade: in Phase 6 (DECISIONS), if vision is provided, read its `## Git Strategy` value and pre-fill the PRD's git strategy question. Map vision strategies to PRD strategies: `none`→`none`, `prd`→`branch-per-prd`, `plan`→`branch-per-phase`. The user can still override.
    - Vision tracker update: add as Phase 7.1 (after GENERATE, before TRACK), only when vision is provided
    - Numbering: add to Phase 7 (GENERATE), replacing the current filename generation logic
- **GOTCHA**: Must handle both vision-linked and standalone PRDs
- **GOTCHA**: Must not break existing PRD generation when no vision is provided
- **GOTCHA**: The vision file path in the PRD reference must be relative from the PRD's location to the vision file
- **VALIDATE**: `grep -q "vision" plugins/prp-core/commands/prp-prd.md && echo "Vision support added"`

### Task 5: MODIFY `/prp-plan` to support numbering

- **IMPLEMENT**: Update `plugins/prp-core/commands/prp-plan.md`
- **PATTERN**: Add counter-based numbering to plan filenames
- **DETAILS**:
  - **Determining the prefix**: When `prp-plan` reads the parent PRD file, extract the numbering prefix from the PRD's filename:
    - If PRD filename starts with `V` (e.g., `V001-PRD003-auth.prd.md`): prefix is `V001-PRD003`
    - If PRD filename starts with `PRD` (e.g., `PRD004-search.prd.md`): prefix is `PRD004`
    - If PRD filename has no number prefix (legacy): use `PRD000` as prefix (backward compatibility)
  - **Assigning plan number**:
    1. Read `.claude/PRPs/.counters.json` (Read tool). If missing, treat as `{"vision": 0, "prd": 0, "plan": 0}`.
    2. Increment `plan` counter by 1.
    3. Write updated counters back (Write tool).
    4. Generate filename: `{prefix}-P{NNN}-{kebab-name}.plan.md`
       - Example: `V001-PRD003-P005-auth-implementation.plan.md`
       - Example: `PRD004-P006-search-indexing.plan.md`
  - **Where to add in prp-plan.md**: Replace the current output filename generation logic (where it constructs the `.plan.md` filename) with the numbered variant. The rest of the plan command is unchanged.
- **GOTCHA**: Must parse the PRD filename to extract the prefix, not the PRD content
- **GOTCHA**: Legacy PRDs without number prefixes should still work (use `PRD000` prefix)
- **VALIDATE**: `grep -q "counters.json" plugins/prp-core/commands/prp-plan.md && echo "Numbering added"`

### Task 6: UPDATE documentation

- **IMPLEMENT**: Update `CLAUDE.md` and `plugins/prp-core/README.md`
- **DETAILS**:
  - Add `/prp-vision` to the command listing in CLAUDE.md
  - Document the numbering system convention
  - Document the Vision → PRD → Plan hierarchy
  - Add vision workflow to the standard development workflow section
- **VALIDATE**: `grep -q "prp-vision" CLAUDE.md && echo "Docs updated"`

---

## TESTING STRATEGY

### Manual Validation

**Test 1: Vision Creation (Happy Path)**
1. Run `/prp-vision` with no arguments
2. Walk through all discovery phases
3. Provide external references during context gathering
4. Verify: vision doc created in `.claude/PRPs/visions/` with `V001` prefix
5. Verify: `.claude/PRPs/.counters.json` updated
6. Verify: external references added to `context-map.md` via `context-add`

**Test 2: PRD Under Vision**
1. Run `/prp-prd --vision .claude/PRPs/visions/V001-name.vision.md`
2. Walk through PRD creation
3. Verify: PRD created with `V001-PRD001` prefix
4. Verify: vision's PRD Tracker updated with new entry
5. Verify: PRD contains `## Vision Reference` section with path references

**Test 3: Standalone PRD (No Vision)**
1. Run `/prp-prd` without `--vision`
2. Verify: PRD created with standalone `PRD002` prefix
3. Verify: no vision reference section
4. Verify: existing PRD behavior unchanged

**Test 4: Plan Numbering**
1. Run `/prp-plan` against a numbered PRD
2. Verify: plan created with correct hierarchical prefix

**Test 5: Vision Completion**
1. Mark all PRDs under a vision as complete
2. Verify: prompted to move vision to `completed/`
3. Verify: vision moved to `.claude/PRPs/visions/completed/`

### Edge Cases

1. **First vision ever**: `.counters.json` doesn't exist yet — should be created
2. **Multiple PRDs under same vision**: Counter increments correctly per vision
3. **Mixed standalone and vision PRDs**: Global PRD counter handles both
4. **Long vision names**: Filename truncation to reasonable length
5. **Context-add failures**: Vision creation continues even if `context-add` fails for a reference

---

## ACCEPTANCE CRITERIA

- [ ] Vision template exists at `plugins/prp-core/templates/vision.md` with all 7 sections
- [ ] `/prp-vision` command exists with full interactive discovery flow (8+ phases)
- [ ] Vision discovery invokes `context-add` for each external reference provided
- [ ] Vision docs stored in `.claude/PRPs/visions/` with `V###` numbered filenames
- [ ] Only one active vision per project; completed visions move to `completed/`
- [ ] `/prp-prd` supports optional `--vision` argument
- [ ] Vision-linked PRDs include `## Vision Reference` section with path references (not copies)
- [ ] Vision's PRD Tracker is updated when a new PRD is created under it
- [ ] Numbering system: `V001`, `V001-PRD001`, `V001-PRD001-P001`, `PRD002`, `PRD002-P001`
- [ ] `.claude/PRPs/.counters.json` tracks global counters
- [ ] Standalone PRDs (no vision) still work without breaking changes
- [ ] `CLAUDE.md` updated with vision command and numbering documentation
- [ ] All manual test scenarios pass

---

## NOTES

### Design Decisions

**Why interactive Q&A (not a template to fill in)?**
The PRD's interactive discovery flow is battle-tested and draws out thinking the user might not have articulated. Vision creation benefits from the same guided process, especially since strategic thinking is often less structured than feature-level thinking.

**Why file-path references (not content copies)?**
Content duplication creates drift. If the vision's objectives evolve slightly, copied sections in PRDs become stale. Path references ensure PRDs always read current vision state.

**Why global counters (not per-vision)?**
PRDs can be standalone or vision-linked. A global PRD counter means `PRD003` is always unique regardless of whether it belongs to a vision. This simplifies lookups and avoids numbering collisions.

**Why one active vision at a time?**
Simplifies project focus and prevents scope confusion. Multiple concurrent visions would require tracking which PRDs map to which vision — the numbering system handles this, but cognitively one active vision keeps the team aligned.

**Why integrate with context-add during vision creation?**
External references gathered during vision creation are valuable project-wide context. Registering them in `context-map.md` makes them discoverable by all downstream PRP commands (`prp-prd`, `prp-plan`, `prp-implement`) through the `context-read` engine.

### Trade-offs

**Numbering complexity vs. discoverability:**
The hierarchical numbering adds overhead to filename generation but makes artifact relationships immediately visible from filenames alone. Worth the complexity given the problem of growing artifact collections.

**Counter file vs. filesystem scanning:**
Could scan `.claude/PRPs/` to determine next number, but a counter file is faster and avoids race conditions. Trade-off: counter file can get out of sync if files are manually renamed/deleted. Mitigation: counter file is authoritative; manual renames are unsupported.

<!-- EOF -->
