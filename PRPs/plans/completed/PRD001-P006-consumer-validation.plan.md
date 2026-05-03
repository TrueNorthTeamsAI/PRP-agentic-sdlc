# Feature: Consumer Validation of v4.0.0 Migration Shim

## Summary

Validate that the v4.0.0 auto-migration shim (Phase 0 PRE-FLIGHT block embedded in every PRP command and skill) works end-to-end on real consumer projects. Both target consumers (`2nd-brain-saas-platform`, `2nd-brain-hieraphical-rag-mcp`) are confirmed still on the v3 layout — `.claude/PRPs/` exists, `PRPs/` does not — making them clean V3 test fixtures. This phase ships no production code; it produces a validation report and any bug-fix follow-ups (filed as new PRDs/issues if needed).

## User Story

As a maintainer of prp-core
I want to confirm v4.0.0 auto-migrates real consumer projects without manual intervention
So that I can close PRD001 with confidence and trust the upgrade path I promised in the release notes.

## Problem Statement

The migration shim was tested in isolation and on this repo (Phase 4 self-migration), but never on a foreign consumer with its own commit history, branch state, and accumulated artifact tree. Until that runs cleanly, the v4.0.0 release claim "consumers auto-migrate without manual intervention" is unverified.

## Solution Statement

For each of the two consumer repos: ensure plugin v4.0.0 is installed, confirm pre-migration state (V3 layout, clean working tree), invoke a benign PRP command that triggers Phase 0 PRE-FLIGHT, and verify the shim performs `git mv .claude/PRPs PRPs`, the announcement prints, and the command completes normally. Document the run in a validation report under `PRPs/reports/`. If anything fails, capture the failure verbatim and file a bug PRD against prp-core; do not patch in this phase.

## Metadata

| Field            | Value                                                                                       |
| ---------------- | ------------------------------------------------------------------------------------------- |
| Type             | VALIDATION                                                                                  |
| Complexity       | LOW                                                                                         |
| Systems Affected | Consumer repos (`2nd-brain-saas-platform`, `2nd-brain-hieraphical-rag-mcp`); prp-core v4.0.0 |
| Dependencies     | prp-core v4.0.0 (released, Phase 5 complete)                                                |
| Estimated Tasks  | 6                                                                                           |
| Source PRD       | `PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md`                               |
| PRD Phase        | #6 — Consumer validation                                                                    |

---

## Pre-Migration State (Verified 2026-05-02)

```bash
# Confirmed during plan generation:
ls c:/Source/TrueNorthTeams/2nd-brain-saas-platform/.claude/PRPs/
  → plans, prds, ralph-archives, reports          (V3 layout present)
ls c:/Source/TrueNorthTeams/2nd-brain-saas-platform/PRPs/
  → No such file or directory                      (no v4 dir yet)

ls c:/Source/TrueNorthTeams/2nd-brain-hieraphical-rag-mcp/.claude/PRPs/
  → plans, prds, ralph-archives, reports          (V3 layout present)
ls c:/Source/TrueNorthTeams/2nd-brain-hieraphical-rag-mcp/PRPs/
  → No such file or directory                      (no v4 dir yet)
```

Both repos are textbook V3 cases — exactly the migration scenario the shim was built for.

---

## How to Execute

### Pre-flight (per consumer repo)

```bash
cd <consumer-repo-root>
git status                              # MUST be clean (no uncommitted changes)
git rev-parse --abbrev-ref HEAD         # note current branch
git rev-parse --is-inside-work-tree     # MUST exit 0 (git path of shim)
ls .claude/PRPs PRPs 2>&1               # confirm V3 (only .claude/PRPs/ exists)
```

If working tree is dirty: stash or commit before proceeding (the shim's git path stages a rename — dirty trees mix it with unrelated edits).

### Plugin version confirmation

```bash
# In consumer repo, confirm prp-core@4.0.0 is the resolved plugin version
# (Mechanism depends on how Claude Code reports installed plugin versions —
#  if no CLI exists, inspect the plugin install location for plugin.json)
```

### Trigger migration

Run the lightest read-mostly PRP command available — `/prp-core:prp-whats-next` is ideal: it reads the artifact tree, doesn't write code, and goes through Phase 0 PRE-FLIGHT first.

```
/prp-core:prp-whats-next
```

### Post-migration verification

```bash
ls .claude/PRPs 2>&1                    # MUST: No such file or directory
ls PRPs/                                # MUST: plans, prds, ralph-archives, reports
git status                              # MUST show staged rename: .claude/PRPs/* → PRPs/*
git log -1 --stat                       # rename not yet committed (expected)
```

### Teardown

Commit the staged rename so the consumer repo's history records the migration:

```bash
git commit -m "chore: migrate PRP artifacts to PRPs/ (prp-core v4.0.0)"
```

Do NOT push without the consumer-repo owner's blessing — this is a validation run, not an authorized release on those repos.

---

## Mandatory Reading

| Priority | File                                                              | Lines | Why Read This                                                                            |
| -------- | ----------------------------------------------------------------- | ----- | ---------------------------------------------------------------------------------------- |
| P0       | `plugins/prp-core/commands/prp-prd.md`                            | 10–60 | Canonical Phase 0 PRE-FLIGHT block — the exact migration logic under test               |
| P0       | `plugins/prp-core/commands/prp-whats-next.md`                     | 1–80  | The command we'll invoke to trigger the shim; confirm it actually runs Phase 0          |
| P1       | `PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md`     | all   | Acceptance criteria, success metrics (2 consumer repos must auto-migrate cleanly)        |
| P1       | `PRPs/plans/completed/PRD001-P002-migration-shim.plan.md`         | all   | What the shim was supposed to do — baseline for "did it behave as designed"             |

---

## Patterns to Mirror

This phase produces a validation report, not code. The reporting pattern mirrors existing reports in `PRPs/reports/` (check that directory for the prevailing structure before writing the new report).

---

## Files to Change

| File                                                          | Action | Justification                                          |
| ------------------------------------------------------------- | ------ | ------------------------------------------------------ |
| `PRPs/reports/PRD001-P006-consumer-validation-report.md`      | CREATE | Document the two validation runs + outcomes            |
| `PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` | UPDATE | Mark Phase 6 status `complete` (after successful runs) |

No plugin source changes. If the shim misbehaves on a consumer, file a new PRD/issue — do NOT hot-patch in this phase.

---

## NOT Building (Scope Limits)

- **No fixes to the shim.** If validation surfaces a bug, capture it and file a follow-up PRD. This phase is observe-only.
- **No third consumer.** PRD scope explicitly names two repos. Adding more is gold-plating.
- **No automation harness.** A scripted multi-repo runner is overkill for a one-time validation.
- **No push to consumer remotes.** The migration commit stays local until the consumer owner authorizes a push.

---

## Step-by-Step Tasks

### Task 1: Confirm prp-core v4.0.0 is the active plugin version

- **ACTION**: Verify Claude Code is loading prp-core@4.0.0 (not a cached v3.x).
- **METHOD**: Run `/prp-core:version` (if the slash command exists per the available skills list — it does: `prp-core:version` is registered) inside one consumer repo.
- **EXPECT**: Output reports `4.0.0`.
- **GOTCHA**: If it reports v3.x, stop — `claude plugin update prp-core` first, then resume.
- **VALIDATE**: Stdout contains `4.0.0`.

### Task 2: Snapshot pre-migration state for `2nd-brain-saas-platform`

- **ACTION**: Capture the baseline that will be compared post-run.
- **CAPTURE**:
  - Current branch name (`git rev-parse --abbrev-ref HEAD`)
  - Working tree status (`git status --porcelain`) — MUST be empty
  - Listing of `.claude/PRPs/` (file count, top-level dirs)
  - Confirmation `PRPs/` does not exist
- **GOTCHA**: If working tree is dirty, stash with `git stash push -u -m "pre-prp-core-v4-validation"` before proceeding.
- **VALIDATE**: Snapshot recorded in scratch notes (will roll into the report).

### Task 3: Trigger the shim on `2nd-brain-saas-platform`

- **ACTION**: From the consumer repo root, invoke `/prp-core:prp-whats-next` in a Claude Code session.
- **OBSERVE**:
  - Did Phase 0 PRE-FLIGHT print the migration announcement line?
  - Did the command complete without permission prompts or errors?
  - How long did the migration take?
- **POST-CHECK** (run in shell):
  ```bash
  test ! -d .claude/PRPs && echo "OK: .claude/PRPs/ removed"
  test -d PRPs && echo "OK: PRPs/ exists"
  git status --porcelain | grep -E '^R' | head -5  # should show staged renames
  ```
- **GOTCHA**: If both directories end up existing, the shim hit the `BOTH` abort path — that's a bug; log it and skip Task 5 commit.
- **VALIDATE**: All three post-checks pass.

### Task 4: Repeat Tasks 2 + 3 on `2nd-brain-hieraphical-rag-mcp`

- **ACTION**: Same procedure, second consumer.
- **EXPECT**: Identical clean migration. Two-for-two is the PRD's acceptance bar.

### Task 5: Commit the migration in each consumer repo (local only)

- **ACTION**: For each consumer where Task 3/4 succeeded:
  ```bash
  git commit -m "chore: migrate PRP artifacts to PRPs/ (prp-core v4.0.0)"
  ```
- **DO NOT PUSH** without the consumer owner's authorization.
- **VALIDATE**: `git log -1 --stat` shows the rename in the new commit.

### Task 6: Write the validation report

- **ACTION**: CREATE `PRPs/reports/PRD001-P006-consumer-validation-report.md` in *this* repo (PRP-agentic-sdlc), not the consumers.
- **CONTENT**:
  - Pre-migration snapshot per consumer (branch, working-tree status, file counts)
  - Exact Phase 0 announcement output captured from each run
  - Post-migration verification results
  - Time elapsed per migration
  - Any anomalies or deviations from expected behavior (even if non-blocking)
  - Final verdict: PASS / PASS-WITH-NOTES / FAIL per consumer
  - If any FAIL: link to the follow-up PRD/issue filed for the bug
- **MIRROR**: Existing reports in `PRPs/reports/` (read one before writing to match prevailing structure).
- **VALIDATE**: Report exists, both consumers covered, verdict line is unambiguous.

---

## Testing Strategy

### Validation runs (this phase IS the test)

| Consumer                            | Pre-state expected | Post-state expected                | Verdict criterion                             |
| ----------------------------------- | ------------------ | ---------------------------------- | --------------------------------------------- |
| `2nd-brain-saas-platform`           | V3 (confirmed)     | `PRPs/` populated, `.claude/PRPs/` gone, rename staged | Zero manual intervention, command completes  |
| `2nd-brain-hieraphical-rag-mcp`     | V3 (confirmed)     | Same as above                      | Same as above                                 |

### Edge Cases Checklist

- [ ] Working tree is clean before the run (skip otherwise — out of scope for this phase)
- [ ] Consumer repo is on `main` or its primary branch (note any non-main branch in the report)
- [ ] No pre-existing `PRPs/` directory (confirmed already)
- [ ] Counters file (`.claude/PRPs/.counters.json`) travels with the rename and ends up at `PRPs/.counters.json`
- [ ] No permission prompts during the migration itself (the entire point of PRD001)

---

## Validation Commands

### Level 1: STATIC_ANALYSIS

N/A — no code changes in this phase.

### Level 2: UNIT_TESTS

N/A — repo has no unit test suite.

### Level 3: FULL_SUITE

N/A.

### Level 4: DATABASE_VALIDATION

N/A.

### Level 5: USER_JOURNEY_VALIDATION

The validation runs ARE the journey. Per consumer, the journey is: clean repo → run `/prp-core:prp-whats-next` → V3-to-V4 migration occurs invisibly → command output appears → file system reflects new layout.

**EXPECT**: Both consumer journeys exit successfully with no manual remediation.

### Level 6: MANUAL_VALIDATION

After both runs:

1. Open each consumer repo in a fresh Claude Code session.
2. Invoke another PRP command (`/prp-core:prp-prd "trivial test"` then immediately abort, or `/prp-core:prp-codebase-question "what does this repo do"`).
3. Confirm Phase 0 PRE-FLIGHT recognizes the V4 layout and continues silently (no second migration attempt, no errors).
4. Confirm zero permission prompts on artifact reads/writes — this is the original PRD's success metric.

---

## Acceptance Criteria

- [ ] `2nd-brain-saas-platform` migrates from V3 to V4 with zero manual intervention
- [ ] `2nd-brain-hieraphical-rag-mcp` migrates from V3 to V4 with zero manual intervention
- [ ] Both repos show staged `.claude/PRPs/* → PRPs/*` renames in `git status` after the trigger command
- [ ] Counters file lands at `PRPs/.counters.json` in both
- [ ] Zero permission prompts observed during either migration
- [ ] Subsequent PRP commands on each migrated repo treat layout as V4 (silent continue, no re-migration)
- [ ] Validation report written to `PRPs/reports/PRD001-P006-consumer-validation-report.md` with PASS/FAIL verdicts
- [ ] PRD001 Phase 6 status updated to `complete` (only if both verdicts are PASS or PASS-WITH-NOTES)

---

## Completion Checklist

- [ ] Task 1: Plugin v4.0.0 confirmed active
- [ ] Task 2: `2nd-brain-saas-platform` baseline captured
- [ ] Task 3: `2nd-brain-saas-platform` migration triggered and verified
- [ ] Task 4: `2nd-brain-hieraphical-rag-mcp` baseline + migration triggered and verified
- [ ] Task 5: Migration commits created locally in both consumer repos
- [ ] Task 6: Validation report written
- [ ] PRD001 Phase 6 marked `complete`
- [ ] Plan archived to `PRPs/plans/completed/`

---

## Risks and Mitigations

| Risk                                                                              | Likelihood | Impact | Mitigation                                                                                                |
| --------------------------------------------------------------------------------- | ---------- | ------ | --------------------------------------------------------------------------------------------------------- |
| Consumer working tree dirty at run time → migration mixes with unrelated edits   | MED        | MED    | Task 2 enforces `git status --porcelain` is empty; stash if not                                           |
| Plugin v4.0.0 not actually loaded (cached v3.x in Claude Code)                    | LOW        | HIGH   | Task 1 explicit version check; `claude plugin update prp-core` if mismatched                              |
| Shim's `BOTH` abort path triggers due to leftover state from a partial test run   | LOW        | LOW    | Pre-flight `ls .claude/PRPs PRPs` confirms only V3 dir exists; if both, clean up first                    |
| Migration succeeds but a downstream command fails on the new path                 | LOW        | MED    | Level 6 manual validation runs a second command post-migration to surface this                            |
| Hidden hardcoded `.claude/PRPs/` in consumer-side custom tooling (e.g., CI YAML)  | MED        | LOW    | Out of scope for prp-core validation; note in report and let consumer owner audit                         |
| Pushing the migration commit upstream without consumer owner's awareness          | LOW        | HIGH   | Explicit instruction in plan: commit locally only, do not push                                            |

---

## Notes

- This is the final phase of PRD001. After it ships, PRD001 is fully complete and can be archived.
- If validation surfaces a regression, the v4.0.x patch line is open for fixes — but those are new PRDs, not amendments to this plan.
- The two consumer repos were chosen during PRD authoring as the canonical real-world test cases. Their currently-confirmed V3 state (verified during this plan's generation) means they're frozen exactly where the shim expects to find them.
- Do not run the migration in *this* repo (PRP-agentic-sdlc) again — it was self-migrated in Phase 4 and is already on V4.
