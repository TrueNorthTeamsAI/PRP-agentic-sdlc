---
iteration: 1
max_iterations: 20
plan_path: ".claude/PRPs/plans/PRD001-P002-migration-shim.plan.md"
input_type: "plan"
started_at: "2026-05-02T00:00:00Z"
---

# PRP Ralph Loop State

## Codebase Patterns
- Plugin commands are pure markdown — no runtime; "shim" is inline prose injected into every artifact-touching command.
- Top-of-command insertion patterns vary by command style:
  - **Process-style** (prp-prd, prp-ralph, prp-whats-next, etc.): insert after `**Input**: $ARGUMENTS\n\n---\n` and before the first `## Your Role` / `## Your Mission` heading.
  - **Objective-style** (prp-plan): insert between `</context>` and `<process>`.
  - **Existing Phase 0** (prp-implement): rename existing `## Phase 0: DETECT` → `## Phase 0.5: DETECT` and insert new `## Phase 0: PRE-FLIGHT` before it.
- Canonical shim text lives once in `plugins/prp-core/skills/init-project/SKILL.md` ("## Migration Shim (Reference)" section) and is duplicated verbatim across 15 consumer files.
- This repo itself still has `.claude/PRPs/` — self-migration is explicitly Phase 4, NOT in scope for this plan.

## Current Task
Execute PRD001-P002 plan: insert idempotent v3→v4 migration shim into 13 commands + 2 skills + canonical reference in init-project SKILL.md, plus 3 user-journey validation files.

## Plan Reference
.claude/PRPs/plans/PRD001-P002-migration-shim.plan.md

## Instructions
1. Read the plan file
2. Implement all incomplete tasks
3. Run ALL validation commands from the plan
4. If any validation fails: fix and re-validate
5. Update plan file: mark completed tasks, add notes
6. When ALL validations pass: output <promise>COMPLETE</promise>

## Progress Log

---
