---
description: Analyze PRP artifact hierarchy to determine the next development step and provide a ready-to-run command
argument-hint: [--implement | --agent-team]
---

# PRP What's Next

**Input**: $ARGUMENTS

---

## Your Mission

Scan the PRP artifact hierarchy (visions, PRDs, plans) to determine the current development status and recommend the exact next step. Output a status summary and a copy-paste-ready command.

**Core Philosophy**: Read, don't guess. Parse the actual artifact files to determine status. Cross-reference folder structure (`completed/` folders) with in-document status fields.

---

## Phase 1: PARSE FLAGS

Check `$ARGUMENTS` for execution mode flags:

| Flag | Execution Command | Description |
|------|-------------------|-------------|
| *(default)* | `/prp-core:prp-ralph` | Autonomous loop until validations pass |
| `--implement` | `/prp-core:prp-implement` | Interactive step-by-step execution |
| `--agent-team` | `/prp-core:build-with-agent-team` | Parallel agent team execution (Opus only) |

Store the selected execution mode for Phase 5.

---

## Phase 1.5: SANITY CHECK - Validate Naming Convention

Before scanning, verify that all PRP artifacts follow the required naming convention. The command cannot reliably sequence documents without consistent hierarchical IDs.

### 1.5.1 Scan for Artifacts

List all `.vision.md`, `.prd.md`, and `.plan.md` files across both active and `completed/` directories.

### 1.5.2 Validate Each Filename

Check every discovered file against these required patterns:

| Artifact | Required Pattern | Regex |
|----------|-----------------|-------|
| Vision | `V{NNN}-{slug}.vision.md` | `^V\d{3}-.+\.vision\.md$` |
| PRD (standalone) | `PRD{NNN}-{slug}.prd.md` | `^PRD\d{3}-.+\.prd\.md$` |
| PRD (vision-linked) | `V{NNN}-PRD{NNN}-{slug}.prd.md` | `^V\d{3}-PRD\d{3}-.+\.prd\.md$` |
| Plan (standalone PRD) | `PRD{NNN}-P{NNN}-{slug}.plan.md` | `^PRD\d{3}-P\d{3}-.+\.plan\.md$` |
| Plan (vision-linked PRD) | `V{NNN}-PRD{NNN}-P{NNN}-{slug}.plan.md` | `^V\d{3}-PRD\d{3}-P\d{3}-.+\.plan\.md$` |

### 1.5.3 If Any Files Fail Validation

**STOP immediately.** Do not proceed to Phase 2. Output:

```markdown
## Naming Convention Issue

The following PRP artifacts don't follow the required naming convention:

| File | Expected Pattern | Location |
|------|------------------|----------|
| {filename} | {which pattern it should match} | {directory} |
| ... | ... | ... |

This command needs consistent hierarchical IDs (e.g., `V001-`, `PRD001-`, `P001-`) to sequence documents correctly.

**Fix this first by running:**

```
/prp-core:prp-validate-file-naming
```

Then re-run `/prp-core:prp-whats-next`.
```

### 1.5.4 Also Check .counters.json

If artifacts exist but `.claude/PRPs/.counters.json` does not, include it in the warning:

> `.counters.json` is missing. The validate command will also create this file.

**Only proceed to Phase 2 if ALL artifacts pass validation.**

---

## Phase 2: INVENTORY - Scan All Artifacts

### 2.1 Discover Artifacts

Scan the PRP directory tree for all artifacts:

```
.claude/PRPs/visions/*.vision.md          → Active visions
.claude/PRPs/visions/completed/*.vision.md → Completed visions
.claude/PRPs/prds/*.prd.md                → Active PRDs
.claude/PRPs/prds/completed/*.prd.md      → Completed PRDs
.claude/PRPs/plans/*.plan.md              → Active plans
.claude/PRPs/plans/completed/*.plan.md    → Completed plans
```

Also check for `.claude/PRPs/.counters.json` to understand numbering context.

**If NO artifacts exist at all**, report:

> No PRP artifacts found in `.claude/PRPs/`. Start by creating a vision or PRD:
> ```
> /prp-core:prp-vision "your objective"
> /prp-core:prp-prd "your feature idea"
> ```

And stop here.

### 2.2 Read Each Artifact

For each discovered artifact, extract key status information:

**Visions** — Parse:
- Vision ID (from filename, e.g., `V001`)
- Title (from `#` heading)
- Status (from frontmatter `status:` field)
- PRD Tracker table: each row's `#`, `PRD`, `Description`, `Status`, `Depends`, `PRD File`

**PRDs** — Parse:
- PRD ID (from filename, e.g., `PRD001` or `V001-PRD001`)
- Title (from `#` heading)
- Whether vision-linked (check for Vision Reference section or `V###` prefix)
- Implementation Phases table: each row's `#`, `Phase`, `Description`, `Status`, `Depends`, `PRP Plan`

**Plans** — Parse:
- Plan ID (from filename)
- Source PRD (from Metadata table `Source PRD` field)
- PRD Phase (from Metadata table `PRD Phase` field)
- Location: active (`plans/`) or completed (`plans/completed/`)

---

## Phase 3: ANALYZE - Determine Status

### 3.1 Build Status Tree

Construct a hierarchical status view:

```
Vision V001 "Title" [active]
  ├── PRD001 "Title" [in-progress]  ← has pending phases
  │   ├── Phase 1: "Name" [complete] → plan in completed/
  │   ├── Phase 2: "Name" [in-progress] → plan exists in plans/
  │   ├── Phase 3: "Name" [pending] → no plan yet, depends: 2
  │   └── Phase 4: "Name" [pending] → no plan yet, depends: 3
  ├── PRD002 "Title" [pending]       ← not started
  └── PRD003 "Title" [pending]       ← depends on PRD001

Standalone:
  ├── PRD004 "Title" [in-progress]
  │   ├── Phase 1: "Name" [complete]
  │   └── Phase 2: "Name" [pending] → no plan yet, depends: 1
  ...
```

### 3.2 Cross-Validate Status

For each artifact, cross-validate status using multiple signals:

1. **Document status fields** — The `Status` column in tracker/phases tables
2. **Folder location** — Files in `completed/` folders are definitively complete
3. **Plan existence** — A phase with a plan file in `plans/` (not `completed/`) is at least in-progress
4. **Plan in completed/** — A phase whose plan is in `plans/completed/` should be `complete`

**Conflict resolution**: If document says `pending` but plan exists in active `plans/`, treat as `in-progress`. If document says `in-progress` but plan is in `completed/`, treat as `complete`. Physical file location is the stronger signal.

### 3.3 Determine Next Action

Walk the hierarchy top-down to find the FIRST actionable item:

**Priority order:**

1. **In-progress plan exists** — An active plan file in `plans/` whose PRD phase is `in-progress`
   → **Action**: Execute this plan (it's already been created, just needs implementation)

2. **PRD phase ready for planning** — A phase with `Status: pending`, all dependencies `complete`, and no linked plan file
   → **Action**: Create a plan for this phase

3. **Vision PRD ready for creation** — A vision tracker row with `Status: pending`, all dependencies `complete`, and `PRD File: -`
   → **Action**: Create a PRD for this vision item

4. **All phases of a PRD complete but PRD not in completed/** — Housekeeping
   → **Action**: Note that this PRD may need to be moved to completed/

5. **All PRDs of a vision complete but vision not in completed/** — Housekeeping
   → **Action**: Note that this vision may need to be moved to completed/

6. **Everything is complete**
   → **Action**: All planned work is done. Suggest creating a new vision or PRD.

**Dependency checking**: A phase/PRD is "ready" only when ALL items listed in its `Depends` column have `Status: complete`.

---

## Phase 4: FORMAT - Status Summary

Output the status summary in this format:

Also read the project's `CLAUDE.md` and find the `## Git Strategy` section. Extract the values after `Strategy:` and `Base Branch:`. Defaults: strategy=`main-only`, base branch=`main`. Display at the top of the status.

```markdown
## PRP Development Status

**Git Strategy**: `{strategy}` | **Base Branch**: `{base-branch}` *(from CLAUDE.md)*

### Active Vision: V001 — {Title}

| # | PRD | Status | Phases | Progress |
|---|-----|--------|--------|----------|
| 1 | PRD001 — {name} | in-progress | 2/5 complete | ██████░░░░ 40% |
| 2 | PRD002 — {name} | pending | 0/3 complete | ░░░░░░░░░░ 0% |
| 3 | PRD003 — {name} | pending (blocked by 1) | - | - |

### Active PRD: PRD001 — {Title}

| # | Phase | Status | Plan | Blocked By |
|---|-------|--------|------|------------|
| 1 | {name} | complete | completed/ | - |
| 2 | {name} | in-progress | {plan-path} | - |
| 3 | {name} | pending | - | Phase 2 |
| 4 | {name} | pending | - | Phase 3 |

### Standalone PRDs
| PRD | Status | Phases | Progress |
|-----|--------|--------|----------|
| PRD004 — {name} | in-progress | 1/2 complete | █████░░░░░ 50% |
```

**Progress bar**: Use `█` for complete and `░` for remaining, 10 characters wide.

Omit sections that have no artifacts (e.g., don't show "Active Vision" if there are no visions).

---

## Phase 5: RECOMMEND - Next Command

After the status summary, output the recommendation:

```markdown
---

### Next Step

**{Action description}** — {Brief explanation of why this is next}

{If executing a plan:}
> Phase {N} of PRD{NNN} is ready for implementation. The plan has already been created.

{If creating a plan:}
> Phase {N} of PRD{NNN} has all dependencies met and needs a plan before implementation.

{If creating a PRD:}
> Vision V{NNN} has PRD #{N} ready to be defined.

### Run This

```
{exact command to copy-paste}
```
```

**Command templates by action type:**

| Action | Default (ralph) | --implement | --agent-team |
|--------|-----------------|-------------|--------------|
| Execute plan | `/prp-core:prp-ralph {plan-path}` | `/prp-core:prp-implement {plan-path}` | `/prp-core:build-with-agent-team {plan-path}` |
| Create plan | `/prp-core:prp-plan {prd-path}` | *(same)* | *(same)* |
| Create PRD (vision) | `/prp-core:prp-prd --vision {vision-path} "{prd-description}"` | *(same)* | *(same)* |
| Create PRD (standalone) | `/prp-core:prp-prd "{description}"` | *(same)* | *(same)* |

**Note**: The `--implement` and `--agent-team` flags only affect the execution step (plan → implementation). Planning and PRD creation commands are always the same regardless of flag.

If the next step is "create a plan" or "create a PRD", also show what the step AFTER that would be:

```markdown
Then, once the {plan/PRD} is created:
```
{execution command that would follow}
```
```

---

## Rules

- **Read-only**: This command NEVER modifies any files. It only reads and reports.
- **Parse carefully**: Use the actual table contents, not assumptions. Phase numbers can be non-sequential (e.g., 1, 1.5, 2, 3).
- **Dependency resolution**: Parse the `Depends` column literally. Values like `1, 2` mean phases 1 AND 2 must be complete. `-` means no dependencies.
- **Parallel awareness**: If multiple phases/PRDs can run in parallel (same dependencies met, marked with `Parallel: with N`), mention all of them but recommend the first by number.
- **Completed folder is authoritative**: If a file is in `completed/`, it's done, regardless of what any tracker table says.
- **Handle missing directories gracefully**: Not all projects will have visions or even PRDs yet.
- **Show the full picture**: Even though you recommend ONE next step, the status summary should show ALL active work so the user has full context.
