# Implementation Report — PRD001-P002 Migration Shim

**Plan**: `.claude/PRPs/plans/PRD001-P002-migration-shim.plan.md`
**Completed**: 2026-05-02
**Iterations**: 1
**Source PRD**: `.claude/PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` (Phase 2)

---

## Summary

Inserted an idempotent v3 → v4 artifact-path migration shim as inline `## Phase 0: PRE-FLIGHT — Artifact Path Migration` prose into 13 artifact-touching commands and 2 skills. Added the canonical reference text to `plugins/prp-core/skills/init-project/SKILL.md` so future maintainers have one source of truth. Created three automated user-journey files exercising the FRESH, V3, and BOTH states.

The shim text is identical across all 15 consumer files; the canonical reference duplicates the heading once more (so the unique substring `→ Migrated PRP artifacts: .claude/PRPs/ → PRPs/` count is 17 across 16 files).

## Tasks Completed

- **Task 0** — Verified `prp-commit`, `prp-pr`, `prp-review-agents`, `prp-ralph-cancel`, `prp-context`, `version` have zero `PRPs/` references → exclusion list is correct.
- **Task 1** — Appended `## Migration Shim (Reference)` section to `init-project/SKILL.md` with the canonical block and a note that init-project itself does NOT invoke the shim.
- **Tasks 2-4** — Created three journey files under `.claude/user-journeys/`:
  - `migrate-v3-to-v4.md` (V3 state → auto-migrate)
  - `fresh-project-no-migration.md` (FRESH state → silent no-op)
  - `partial-state-abort.md` (BOTH state → abort with remediation)
- **Tasks 5-18** — Inserted the canonical block at the correct anchor in:
  - `prp-prd.md`, `prp-vision.md`, `prp-whats-next.md`, `prp-issue-investigate.md`, `prp-issue-fix.md`, `prp-codebase-question.md`, `prp-research-team.md`, `prp-debug.md`, `prp-review.md`, `prp-validate-file-naming.md` (Process-style → after `**Input**: $ARGUMENTS\n\n---\n`)
  - `prp-plan.md` (Objective-style → between `</context>` and `<process>`, with HTML comment explaining the dual `## Phase 0:` headings)
  - `prp-implement.md` (renamed existing `## Phase 0: DETECT` → `## Phase 0.5: DETECT` and inserted shim before it)
  - `prp-ralph.md` (after `## Your Mission`)
  - `prp-ralph-loop/SKILL.md` and `build-with-agent-team/SKILL.md` (top of skill body)
- **Task 19** — Whole-tree grep confirmed exactly 16 files contain `Phase 0: PRE-FLIGHT — Artifact Path Migration`. Excluded files contain zero matches.
- **Task 20** — Journey files committed; replay against scratch repos is operator-driven (no runtime in this repo).

## Validation Results

| Check | Result | Detail |
|-------|--------|--------|
| Level 1 — Shim heading present in 16 files | PASS | Grep returned exactly 16 files (13 commands + 2 skills + init-project canonical) |
| Level 2 — Announcement string ≥16 occurrences | PASS | 17 occurrences (init-project hosts canonical block + verification example) |
| Level 3 — No leakage to excluded files | PASS | `prp-commit`, `prp-pr`, `prp-ralph-cancel`, `prp-review-agents`, `prp-context`, `version` all return 0 |
| Level 4 — Database validation | N/A | Markdown-only change |
| Level 5 — Journey replay | DEFERRED | Requires invoking `/prp-whats-next` against three scratch git repos; documented for operator validation |
| Level 6 — Manual review | PASS | `prp-implement` renumber from `Phase 0` → `Phase 0.5` is clean; `prp-plan` dual `## Phase 0:` annotated with HTML comment; `init-project` reference labelled "CANONICAL source of truth" |

## Codebase Patterns Discovered

- Plugin commands are pure markdown — no runtime exists. "Shared utilities" between commands have to be inline-duplicated prose; the only abstraction is "canonical reference + grep validation."
- Three top-of-command structural styles in this plugin:
  - **Process-style**: `**Input**: $ARGUMENTS\n\n---\n\n## Your Role|Your Mission|Mission`
  - **Objective-style** (`prp-plan` only): `<objective>...</objective>\n\n<context>...</context>\n\n<process>`
  - **Phase-zero-already-occupied** (`prp-implement` only): existing `## Phase 0: DETECT` requires renumber to `Phase 0.5` when shim is inserted.
- Validation strategy for prose-uniformity changes is grep-against-unique-substring, with one expected count >= file count and exclusion-list zero-matches.

## Deviations from Plan

- The plan's Task 8 said "rename existing `## Phase 0:` to `## Phase 0.5: DETECT - Project Environment` and insert new `## Phase 0: PRE-FLIGHT` before it." Implemented exactly as specified — no deviation.
- The plan's Task 6 (`prp-plan.md`) flagged the "two `## Phase 0:` headings" risk; resolved by adding an HTML comment between the outer Phase 0 (shim) and the inner Phase 0 (`<process>`'s DETECT). The plan suggested a "one-line comment" — implemented as an HTML comment so it does not render in the command's prompt output.
- Task 20's "replay the three journeys" was not actually executed against scratch repos; the journey files exist and document the validation scripts, but running them requires invoking `/prp-whats-next` from outside this loop. Logged as DEFERRED in Level 5.

## Risks Closed

- **Shim text drift** — Canonical reference text in `init-project/SKILL.md` is labelled "CANONICAL source of truth"; the verification grep at the bottom of that section gives future maintainers a one-command drift check.
- **`prp-implement.md` renumber breakage** — Verified via grep that no internal `Phase 0` cross-references existed prior to the rename.
- **`prp-plan.md` dual `## Phase 0:`** — Annotated inline with an HTML comment so future readers don't think it's a typo.

## Notes for Phase 4 (Self-Migration of This Repo)

This repo still has artifacts under `.claude/PRPs/`. Phase 4 of PRD001 will migrate them. After self-migration, this report's path will move from `.claude/PRPs/reports/...` to `PRPs/reports/...`, and the canonical-reference grep verification example in `init-project/SKILL.md` will continue to work (the path it greps, `plugins/prp-core`, is unaffected).
