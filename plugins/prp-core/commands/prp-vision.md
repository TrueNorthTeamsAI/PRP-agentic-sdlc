---
description: Interactive vision generator - strategic layer above PRDs for major milestones
argument-hint: [major objective] (blank = start with questions)
---

# Vision Document Generator

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

You are a strategic product thinker who:
- Starts with the BIG PICTURE — the "why behind the why"
- Captures strategic objectives that span multiple PRDs
- Demands clarity on scope boundaries and success criteria
- Thinks in outcomes, not implementations
- Asks probing questions to draw out strategic thinking

**Anti-pattern**: Don't fill sections with vague aspirations. If info is missing, write "TBD - needs discovery" rather than inventing plausible-sounding objectives.

---

## Process Overview

```
INITIATE → PROBLEM SPACE → CURRENT STATE → DESIRED OUTCOME → BOUNDARIES → CONTEXT → SUCCESS → GIT STRATEGY → GENERATE
```

Each phase builds on previous answers. Research phases validate assumptions.

---

## Phase 1: INITIATE - Major Objective

**If no input provided**, ask:

> **What major objective are you pursuing?**
> Describe the strategic goal, milestone, or initiative in a few sentences. This should be bigger than a single feature — think "user onboarding experience" not "add signup form."

**If input provided**, confirm understanding by restating:

> I understand you're pursuing: {restated understanding}
> Is this correct, or should I adjust my understanding?

**GATE**: Wait for user response before proceeding.

---

## Phase 2: PROBLEM SPACE - Strategic Gap

Ask these questions (present all at once, user can answer together):

> **Problem Space Questions:**
>
> 1. **What's the strategic gap or opportunity?** What problem or opportunity makes this worth pursuing at a strategic level?
>
> 2. **Who is most affected?** Who are the primary stakeholders, users, or teams impacted by this problem?
>
> 3. **What is the cost of NOT addressing this?** What happens if you do nothing? (lost revenue, tech debt, user churn, competitive risk, etc.)
>
> 4. **What is the scale/impact?** How many users, how much revenue, how critical to the business?

**GATE**: Wait for user responses before proceeding.

---

## Phase 3: CURRENT STATE - Grounding Research

### 3.0 Load External Context (Automatic, Silent)

Before launching research agents, check if `context-map.md` exists in the project (search current dir, then walk up parent directories).

**If found:** Match entries against the objective and key terms from the user's problem space answers. Resolve and read sources silently using the `context-read` skill logic (see `plugins/prp-core/skills/context-read/SKILL.md`). Include loaded content as additional input for the grounding phase.

**If not found or no matches:** Proceed normally. This step is optional.

### 3.1 Research

After problem space answers, conduct research using specialized agents:

**Use Task tool with `subagent_type="prp-core:web-researcher"`:**

```
Research the market and strategic context for: {major objective}

FIND:
1. How other organizations/products approach this strategic area
2. Industry trends and best practices
3. Common success patterns and failure modes
4. Recent developments or shifts in this space

Return findings with direct links, key insights, and any gaps in available information.
```

**If codebase exists, use Task tool with `subagent_type="prp-core:codebase-explorer"`:**

```
Find existing functionality relevant to: {major objective}

LOCATE:
1. Related existing features or capabilities
2. Infrastructure that could be leveraged
3. Technical constraints or opportunities
4. Patterns that align with this strategic direction

Return file locations, code patterns, and conventions observed.
```

**Ask the user:**

> **Current State:**
>
> {Summarize research findings}
>
> Based on this research:
> 1. **What exists today?** What's already in place (internally or externally)?
> 2. **What's been tried?** Any previous attempts at solving this?
> 3. **What worked/failed?** Lessons learned from past approaches?

**GATE**: Wait for user responses before proceeding.

---

## Phase 4: DESIRED OUTCOME - End State

Ask these questions:

> **Desired Outcome:**
>
> 1. **What does the world look like when this is fully solved?** Paint the picture of success.
>
> 2. **What capabilities will exist that don't exist now?** Be specific about new abilities.
>
> 3. **What will users/stakeholders be able to do differently?** Focus on behavioral changes, not features.

**GATE**: Wait for user responses before proceeding.

---

## Phase 5: BOUNDARIES - Scope and Constraints

Ask these questions:

> **Boundaries:**
>
> 1. **What is explicitly OUT of scope for this vision?** What might people expect you to include that you're deliberately excluding?
>
> 2. **What constraints exist?** (time, budget, technical limitations, organizational, regulatory, etc.)
>
> 3. **What assumptions are you making?** And what would invalidate each assumption?

**GATE**: Wait for user responses before proceeding.

---

## Phase 6: CONTEXT GATHERING - External References

Ask:

> **Are there external references that provide important context for this vision?**
>
> These could be URLs, documents in other repos, Obsidian notes, or other sources. I'll register each one in the project's context-map so downstream PRDs and plans can discover them automatically.
>
> Provide references one at a time, or list them all. Say "done" or "no more" when finished.

**For each reference the user provides**, do TWO things:

1. **Record it** in the vision doc's Context & References table (label, type, path/URL, description)
2. **Invoke context-add** via the **Skill** tool: `skill: "prp-core:context-add", args: "{the-reference}"`. When the skill asks for a section name, suggest the vision identifier (e.g., "V001 User Onboarding") to group vision context together in context-map.md.

**If the Skill tool call fails**, log a warning and continue — context registration is not a blocker.

**When user says "done" or "no more" or "none"**, proceed to next phase.

**GATE**: Wait for user to indicate they're done providing references.

---

## Phase 7: SUCCESS DEFINITION - Measurable Outcomes

Ask these questions:

> **Success Definition:**
>
> 1. **How will you know this vision has been achieved?** What observable changes indicate success?
>
> 2. **What specific, measurable outcomes define success?** (e.g., "80% of users complete onboarding within 5 minutes")
>
> 3. **What timeframe are you targeting?** When do you expect this to be substantially complete?

**GATE**: Wait for user responses before proceeding.

---

## Phase 8: GENERATE - Write Vision Document

### 8.1 Compute Vision ID

PRP-Core uses **date+initials** identifiers for visions and PRDs (no shared counter). The ID encodes the creation date (UTC, `YYYYMMDD`) and the author's 2-character uppercase initials; same-day collisions get a lowercase suffix (`b`, `c`, ...).

#### 8.1.a Ensure User Initials (`.initials.json`)

1. **Read** `PRPs/.initials.json`. Expected shape: `{"initials": "XX"}` where `XX` is exactly 2 uppercase ASCII letters (`A`–`Z`). If valid, capture as `USER_INITIALS` and skip to 8.1.b.
2. **If missing or invalid**, run the first-run flow:
   1. Run `git config user.name`. Derive a suggestion: first letter of each whitespace-separated word, uppercase, max 2 chars. Fallback `XX` if unknown.
   2. Ask: *"Initials needed. This project uses author initials to namespace visions/PRDs. What 2-letter uppercase initials should this clone use? (Suggested: `{suggested}`)"*
   3. Validate `^[A-Z]{2}$`. Re-prompt if invalid.
   4. **Write** `PRPs/.initials.json` with `{"initials": "{response}"}`.
   5. **Ensure `.gitignore` covers `PRPs/.initials.json`** at the repo root. Read `.gitignore` (if absent, treat as empty). If no matching line exists, append:
      ```
      # PRP-Core: per-user initials (do not commit)
      PRPs/.initials.json
      ```
   6. Print: `→ Saved initials '{response}' to PRPs/.initials.json (gitignored).`
   7. Capture as `USER_INITIALS`.
3. On parse error of an existing `.initials.json`, warn the user; do not overwrite.

#### 8.1.b Compute Vision ID

1. `TODAY` = today's UTC date in `YYYYMMDD` (e.g., `20260630`).
2. Base ID: `V{TODAY}{USER_INITIALS}` (e.g., `V20260630DR`).
3. **Collision check** — scan `PRPs/visions/` and `PRPs/visions/completed/` for filenames starting with the base ID (followed by `-` or `.`):
   - No match → final ID is `{base-id}`.
   - Otherwise try suffixes `b`, `c`, ..., `z`; pick the first unused.
   - If all 25 are taken, STOP and ask the user.
4. Capture as `VISION_ID`.

### 8.2 Generate Vision Document

1. Create directory: `mkdir -p PRPs/visions`
2. Generate filename: `{VISION_ID}-{kebab-case-name}.vision.md` (e.g., `V20260630DR-user-onboarding.vision.md`)
3. Fill in the vision template (from `plugins/prp-core/templates/vision.md`) with discovery answers:
   - Replace all `{placeholder}` fields with actual content from phases 1-7
   - Fill `id` frontmatter with `{VISION_ID}` (e.g., `V20260630DR`)
   - Fill `created` frontmatter with current ISO timestamp
   - The PRD Tracker starts empty or with preliminary PRDs if the user mentioned specific features during discovery
4. Write the file to `PRPs/visions/{VISION_ID}-{kebab-case-name}.vision.md`

**Backward compatibility:** Existing artifacts with the legacy `V{NNN}` format remain valid and are not renamed.

### 8.3 Check for Existing Active Vision

Before writing, scan `PRPs/visions/` for any existing `.vision.md` files (excluding `completed/` subdirectory). If an active vision exists, warn the user:

> **Warning**: There is already an active vision: `{existing-vision-file}`. Only one active vision is recommended per project. Do you want to proceed anyway, or complete/archive the existing vision first?

**GATE**: Wait for user response if active vision exists.

---

## Phase 8.5: GIT - Commit Vision Document

```bash
git add PRPs/visions/{VISION_ID}-{name}.vision.md
git commit -m "docs: add vision {VISION_ID} for {feature-name}"
git push -u origin HEAD
```

> `PRPs/.initials.json` is gitignored (set up in step 8.1.a) — do not stage it. Legacy `PRPs/.counters.json` is no longer read or written; if it exists, leave it in place.

**GATE**: No user interaction needed. This is automatic.

---

## Phase 9: OUTPUT - Summary

After generating, report:

```markdown
## Vision Created

**File**: `PRPs/visions/{VISION_ID}-{name}.vision.md`
**Vision ID**: {VISION_ID}
**Title**: {Vision Title}

### Key Objectives

- {Objective 1}
- {Objective 2}
- {Objective 3}

### Success Criteria

| Criteria | Target | How Measured |
|----------|--------|--------------|
| {Criteria 1} | {Target 1} | {Method 1} |
| {Criteria 2} | {Target 2} | {Method 2} |

### Git Strategy

`{none | prd | plan}`

### Context References Registered

- {N} external references added to context-map.md (or "None")

### PRD Tracker

{Number of preliminary PRDs identified, or "Empty — ready for PRDs"}

### Next Step

Create PRDs under this vision:
Run: `/prp-prd --vision PRPs/visions/{VISION_ID}-{name}.vision.md "feature idea"`
```

---

## Question Flow Summary

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
│  CURRENT STATE: Research + What exists? What's tried?   │
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
│  GENERATE: Write vision to PRPs/visions/        │
└─────────────────────────────────────────────────────────┘
```

---

## Success Criteria

- **STRATEGIC_CLARITY**: Vision captures a clear strategic objective, not just a feature request
- **PROBLEM_VALIDATED**: Problem space is specific and evidenced (or marked as assumption)
- **SCOPE_BOUNDED**: Clear in-scope and out-of-scope boundaries defined
- **SUCCESS_MEASURABLE**: Success criteria are specific and measurable
- **CONTEXT_REGISTERED**: External references added to both vision doc and context-map.md
- **NUMBERING_CORRECT**: Vision file uses a valid ID — date+initials (`V{YYYYMMDD}{II}[s]`) for new artifacts, or legacy counter (`V{NNN}`) for pre-existing artifacts
- **ONE_ACTIVE**: Only one active vision per project (warned if existing)
- **ACTIONABLE**: A PRD creator could use this vision to scope and prioritize their work
