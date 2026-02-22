# Feature: Git Strategy & PRD Status Tracking

## Summary

Added configurable git branching strategies to the PRP workflow and fixed the broken PRD status update pipeline. PRDs now declare a `Git Strategy` field that controls how prp-plan, prp-implement, and prp-ralph handle branch creation and commits. The Source PRD metadata gap was fixed so completed phases correctly update their PRD status.

## User Story

As a developer using the PRP framework
I want my PRDs to declare a git branching strategy
So that the plan/implement/Ralph workflow handles branches and commits automatically according to my project's needs

## Problem Statement

Two issues existed:
1. **PRD status never updated on completion** — prp-implement Phase 5.3 looked for a `Source PRD:` field in plan files, but prp-plan never wrote it. Completed phases silently skipped the PRD update.
2. **No git strategy coordination** — The PRP workflow had no opinion on branching. Plans, implementations, and Ralph loops had no commit steps, and there was no way to configure branch-per-PRD vs branch-per-phase vs staying on main.

## Solution Statement

- Added `Source PRD` and `PRD Phase` metadata fields to the plan template
- Made prp-plan write these fields when generating from a PRD
- Added 3-tier fallback lookup in prp-implement and prp-ralph (metadata table → inline text → directory scan)
- Added `Git Strategy` field to PRD template with 4 options: `none`, `main-only`, `branch-per-prd`, `branch-per-phase`
- Added git strategy question to PRD generator (Phase 6)
- Added strategy-aware git operations to prp-prd, prp-plan, prp-implement, and prp-ralph

## Metadata

| Field            | Value                                  |
| ---------------- | -------------------------------------- |
| Type             | ENHANCEMENT                            |
| Complexity       | MEDIUM                                 |
| Systems Affected | prp-prd, prp-plan, prp-implement, prp-ralph |
| Dependencies     | git CLI                                |
| Estimated Tasks  | 8                                      |
| Source PRD       | N/A                                    |
| PRD Phase        | N/A                                    |

---

## Files Changed

| File | Action | Justification |
|------|--------|---------------|
| `.claude/commands/prp-core/prp-prd.md` | UPDATE | Git strategy question + template field + post-generation git ops |
| `.claude/commands/prp-core/prp-plan.md` | UPDATE | Source PRD/Phase metadata, GIT_STRATEGY extraction, strategy-aware git ops |
| `.claude/commands/prp-core/prp-implement.md` | UPDATE | 3-tier PRD lookup, strategy-aware git ops (step 5.5→5.6) |
| `.claude/commands/prp-core/prp-ralph.md` | UPDATE | Source PRD update (step 4), strategy-aware git ops (step 6) |
| `plugins/prp-core/commands/prp-prd.md` | UPDATE | Same as .claude version + Phase 7.75 for git ops |
| `plugins/prp-core/commands/prp-plan.md` | UPDATE | Same as .claude version + Plane tracking preserved |
| `plugins/prp-core/commands/prp-implement.md` | UPDATE | 3-tier PRD lookup + git ops (step 5.6) |
| `plugins/prp-core/commands/prp-ralph.md` | UPDATE | Source PRD update (step 4) + git ops (step 6) |

---

## Git Strategy Options

| Strategy | Value | Behavior |
|----------|-------|----------|
| **none** | `none` | No git operations. User manages git manually. |
| **main-only** | `main-only` | All work on current branch. Auto-commit after each step. Default if not specified. |
| **branch-per-prd** | `branch-per-prd` | One feature branch for entire PRD. Created at PRD generation. All phases commit there. |
| **branch-per-phase** | `branch-per-phase` | Each phase gets its own branch off main. Created by prp-plan. |

### Strategy Flow by Command

| Command | none | main-only | branch-per-prd | branch-per-phase |
|---------|------|-----------|-----------------|------------------|
| prp-prd | skip | commit on current | create `feat/{name}`, commit | commit on current |
| prp-plan | skip | commit on current | verify on `feat/{name}`, commit | create `feat/{name}/phase-N`, commit |
| prp-implement | skip | commit on current | verify on `feat/{name}`, commit | verify on phase branch, commit |
| prp-ralph | skip | commit on current | verify on `feat/{name}`, commit | verify on phase branch, commit |

---

## PRD Status Update Fix

### Root Cause
prp-plan never wrote `Source PRD:` metadata into plan files. prp-implement Phase 5.3 only checked for that field, so it silently skipped the PRD update.

### Fix Applied
1. Plan template now includes `Source PRD` and `PRD Phase` rows in the Metadata table
2. prp-plan Phase 0 extracts `SOURCE_PRD` and carries it into the metadata
3. prp-implement and prp-ralph use 3-tier lookup: metadata table → inline text → PRD directory scan
4. If no PRD found after all methods, a warning is logged (no more silent skip)

---

## Acceptance Criteria

- [x] PRD generator asks for git strategy (4 options + none)
- [x] PRD template includes `Git Strategy` field in Technical Approach
- [x] prp-plan extracts git strategy from PRD
- [x] prp-plan writes Source PRD and PRD Phase to plan metadata
- [x] All 4 commands (prd, plan, implement, ralph) execute strategy-aware git operations
- [x] `none` strategy results in zero git operations across all commands
- [x] `main-only` is the default when no strategy specified
- [x] Source PRD 3-tier lookup works in implement and ralph
- [x] Both `.claude/commands/` and `plugins/prp-core/commands/` versions updated

---

*Completed: 2026-02-23*
*Status: COMPLETE (retrospective)*
