# Feature: Phase 4 — Self-Migration of PRP-agentic-sdlc to `PRPs/` Layout

## Summary

Phase 4 of PRD001. Move this repo's own PRP artifact tree from `.claude/PRPs/` to `PRPs/` at the repo root using `git mv` to preserve history. Update the two legacy runner scripts whose internal documentation strings reference the old path. Verify the migration shim now treats this repo as already-migrated (no-op). Phases 1-3 are complete; Phase 5 (release v4.0.0) and Phase 6 (consumer validation) gate on this.

## User Story

As a developer working on the PRP-agentic-sdlc repo,
I want this repo's own PRP artifacts to live at `PRPs/` like every other v4 consumer,
So that the plugin's source-of-truth repo eats its own dogfood and the in-repo permission-prompt friction is gone.

## Problem Statement

The plugin source already writes to `PRPs/` (Phase 1) and ships an auto-migration shim (Phase 2), but this repo's own artifact tree still lives at `.claude/PRPs/`. Every PRP command run *inside this repo* either (a) fights the `.claude/` permission-prompt bug or (b) triggers the migration shim opportunistically — neither is the intended steady state. We need to perform the migration deliberately as a single atomic commit so subsequent work on this repo runs on the v4 layout natively.

## Solution Statement

`git mv .claude/PRPs PRPs` to preserve file history. Update the two legacy Python runner scripts in `PRPs/scripts/` whose docstrings and inline regexes reference the old path. Leave migration-shim references in plugin commands/skills untouched (they describe the V3-state-being-detected — intentional). Leave user-journey docs untouched (they document the migration flow). Verify by running `grep -rn '.claude/PRPs'` and confirming only intentional references remain (shim text, journey docs, archived plans, the v4 release-note line).

## Metadata

| Field            | Value                                                              |
| ---------------- | ------------------------------------------------------------------ |
| Type             | REFACTOR (infrastructure)                                          |
| Complexity       | LOW                                                                |
| Systems Affected | this repo's artifact tree + 2 legacy scripts                       |
| Dependencies     | Phase 1, 2, 3 of PRD001 (all complete)                             |
| Estimated Tasks  | 4                                                                  |
| Source PRD       | `.claude/PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` |
| PRD Phase        | #4 — Self-migration of this repo                                    |
| Git Strategy     | `main-only`                                                        |

---

## UX Design

### Before State

```
╔══════════════════════════════════════════════════════════════════╗
║  PRP-agentic-sdlc/                                               ║
║  ├── .claude/                                                    ║
║  │   ├── PRPs/  ← artifacts here (V3 layout)                     ║
║  │   ├── settings.local.json                                     ║
║  │   └── user-journeys/                                          ║
║  ├── plugins/prp-core/  (already V4-aware)                       ║
║  └── README.md          (already documents PRPs/ layout)         ║
║                                                                  ║
║  Running any /prp-core:* command in this repo:                   ║
║  → Migration shim detects v3 layout                              ║
║  → Auto-migrates on first invocation (incidental, not staged)    ║
║  → OR: writes to PRPs/ alongside .claude/PRPs/ (partial state!)  ║
╚══════════════════════════════════════════════════════════════════╝
```

### After State

```
╔══════════════════════════════════════════════════════════════════╗
║  PRP-agentic-sdlc/                                               ║
║  ├── .claude/                                                    ║
║  │   ├── settings.local.json                                     ║
║  │   ├── user-journeys/  (unchanged — documents migration)       ║
║  │   └── prp-ralph.state.md  (transient, when Ralph runs)        ║
║  ├── PRPs/  ← all artifacts here, history preserved by git mv    ║
║  │   ├── prds/  plans/  reports/  ralph-archives/  features/     ║
║  │   ├── scripts/  (2 legacy py files w/ updated path refs)      ║
║  │   └── .counters.json                                          ║
║  └── plugins/prp-core/                                           ║
║                                                                  ║
║  Running any /prp-core:* command in this repo:                   ║
║  → Shim sees PRPs/ already exists, no-op                         ║
║  → Writes proceed to PRPs/ without permission prompts            ║
╚══════════════════════════════════════════════════════════════════╝
```

### Interaction Changes

| Location                             | Before                            | After                          | User Impact                          |
| ------------------------------------ | --------------------------------- | ------------------------------ | ------------------------------------ |
| Artifact tree in this repo           | `.claude/PRPs/...`                | `PRPs/...`                     | One-line CLI fix; matches all docs   |
| Legacy script docstrings (2 files)   | `.claude/PRPs/scripts/*.py` paths | `PRPs/scripts/*.py` paths      | Help text accurate after move        |
| Migration shim behavior on this repo | Triggers on first command        | No-op (PRPs/ already present)  | Steady-state v4                      |

---

## User Journeys

No new user-facing flows. The three existing journeys (`migrate-v3-to-v4.md`, `partial-state-abort.md`, `fresh-project-no-migration.md`) describe the shim's behavior on consumer projects — unaffected by self-migration. No journey updates needed.

---

## How to Execute

This is an infrastructure-only phase. No services, no seed data, no e2e tests.

```bash
# Pre-flight
cd c:/Source/TrueNorthTeams/PRP-agentic-sdlc
git status --short                              # working tree should be clean before starting
test -d .claude/PRPs && echo "v3 layout present"
test ! -d PRPs && echo "no PRPs/ yet — ready to migrate"
```

---

## Mandatory Reading

| Priority | File                                                       | Lines  | Why Read This                                                       |
| -------- | ---------------------------------------------------------- | ------ | ------------------------------------------------------------------- |
| P0       | `.claude/PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` | 152-198 | Phase 4 scope and parallelism notes                                 |
| P0       | `.claude/PRPs/scripts/invoke_command.py`                   | 1-25   | Edit target — docstring path strings                                |
| P0       | `.claude/PRPs/scripts/prp_workflow.py`                     | 1-220  | Edit target — multiple path-string references including a regex    |
| P1       | `.claude/PRPs/ralph-archives/2026-05-02-PRD001-P002-migration-shim/learnings.md` | all | What the shim does on first invocation — confirms post-move it no-ops |
| P1       | `plugins/prp-core/skills/init-project/SKILL.md`            | grep `git mv` | Reference implementation of the move command pattern              |

**External Documentation:** N/A — internal infrastructure only.

**Context Sources Loaded:** None.

---

## Patterns to Mirror

**GIT_MV_FOR_HISTORY_PRESERVATION** (the canonical move pattern):

```bash
# Used by the migration shim itself; mirror exactly:
git mv .claude/PRPs PRPs
```

`git mv` stages the move atomically and preserves blame/history through the rename. Plain `mv` followed by `git add` works but loses similarity-detection in some viewers.

**SCRIPT_HEADER_DOCSTRING_STYLE** (existing convention in `prp_workflow.py:1-25`):

```python
"""
PRP Workflow - end-to-end runner.

USAGE:
    uv run PRPs/scripts/prp_workflow.py "Add JWT authentication"
    ...
"""
```

Match the existing docstring layout exactly when rewriting paths. Only the path strings change.

---

## Files to Change

| File                                                                              | Action            | Justification                                              |
| --------------------------------------------------------------------------------- | ----------------- | ---------------------------------------------------------- |
| `.claude/PRPs/` → `PRPs/` (entire tree)                                           | RENAME (`git mv`) | The migration itself                                       |
| `PRPs/scripts/invoke_command.py`                                                  | UPDATE            | 3 docstring path strings (post-move path)                  |
| `PRPs/scripts/prp_workflow.py`                                                    | UPDATE            | 8 occurrences: docstrings, inline regex literals, ROOT path |
| `.claude/user-journeys/*.md` (3 files)                                            | NO CHANGE         | Describe consumer migration flow; references intentional   |
| `plugins/prp-core/commands/*.md`, `plugins/prp-core/skills/*/SKILL.md`            | NO CHANGE         | Migration shim refs intentional (V3 detection)             |
| `old-prp-commands/*.md`                                                           | NO CHANGE         | Historical archive — out of scope per PRD                  |
| `c:\Source\CLAUDE.md`                                                             | NO CHANGE         | v4 release-note line is intentional (Phase 3 outcome)      |

---

## NOT Building (Scope Limits)

- **Editing migration shim text** in `plugins/prp-core/commands/*.md` and `plugins/prp-core/skills/*/SKILL.md` — those `.claude/PRPs` references describe what the shim *detects*. Out of scope.
- **Editing user-journey docs** — they describe consumer-side migration flows for testing the shim. References are intentional.
- **Bumping plugin version** — that's Phase 5.
- **Running consumer-project migrations** — that's Phase 6.
- **Editing `old-prp-commands/`** — historical archive per PRD line 113.
- **Touching `.claude/prp-ralph.state.md`** — it lives at `.claude/`, not `.claude/PRPs/`. Not part of the artifact tree.
- **Refactoring or removing the legacy `scripts/*.py`** — they may be unused but verifying that is out of scope; just keep their internal references consistent with the new location.

---

## Step-by-Step Tasks

### Task 1: Pre-flight verification

- **ACTION**: Confirm starting state is sane.
- **IMPLEMENT**: Run all checks; abort if any fail.
- **COMMANDS**:
  ```bash
  cd c:/Source/TrueNorthTeams/PRP-agentic-sdlc
  git status --short                          # must be empty (no uncommitted changes)
  test -d .claude/PRPs && echo "v3 OK"        # must exist
  test ! -d PRPs && echo "target free"        # must NOT exist (else partial state — abort)
  git rev-parse --abbrev-ref HEAD             # confirm on `main` (per main-only strategy)
  ```
- **GOTCHA**: If `PRPs/` already exists (partial-state), abort and surface to user. The shim's partial-state handler refuses to guess; we follow the same rule.
- **VALIDATE**: All four checks succeed. Working tree clean.

### Task 2: Execute `git mv` of artifact tree

- **ACTION**: Move the entire `.claude/PRPs/` tree to `PRPs/` in one staged operation.
- **IMPLEMENT**:
  ```bash
  git mv .claude/PRPs PRPs
  git status --short                          # should show R-prefixed renames for every artifact file
  ```
- **MIRROR**: The migration shim's `git mv` line — same command, same direction.
- **GOTCHA 1**: On Windows, `git mv` with case-only renames or path-separator differences can fail silently. The path is fully lowercase-different here (`.claude/PRPs` → `PRPs`), so this is fine, but verify with `git status` immediately after.
- **GOTCHA 2**: `git mv` with a directory argument moves the whole tree atomically — do NOT run it file-by-file or you'll lose rename detection.
- **GOTCHA 3**: Don't `git add` first — `git mv` stages the rename itself.
- **VALIDATE**:
  ```bash
  test ! -d .claude/PRPs                      # source gone
  test -d PRPs                                # target present
  git status --porcelain | grep -c '^R '      # rename count > 0; expect ~40 entries
  ls PRPs/                                    # should list: features, plans, prds, ralph-archives, reports, scripts
  cat PRPs/.counters.json                     # should show {"vision":0,"prd":1,"plan":4} (this plan increments to 4)
  ```

### Task 3: Update legacy script path strings

- **ACTION**: Rewrite the two Python scripts so their docstrings, regexes, and inline path constants reference the new location.
- **FILES**:
  - `PRPs/scripts/invoke_command.py` (3 substitutions)
  - `PRPs/scripts/prp_workflow.py` (8 substitutions)
- **IMPLEMENT** (`invoke_command.py` lines 5-7):
  ```diff
  -    uv run .claude/PRPs/scripts/invoke_command.py prp-core-create "Add JWT authentication"
  -    uv run .claude/PRPs/scripts/invoke_command.py prp-core-execute my-feature --interactive
  -    uv run .claude/PRPs/scripts/invoke_command.py .claude/commands/prp-core/prp-core-pr.md "Add auth feature"
  +    uv run PRPs/scripts/invoke_command.py prp-core-create "Add JWT authentication"
  +    uv run PRPs/scripts/invoke_command.py prp-core-execute my-feature --interactive
  +    uv run PRPs/scripts/invoke_command.py PRPs/scripts/prp-core-pr.md "Add auth feature"
  ```
  Note: line 7 referenced `.claude/commands/prp-core/prp-core-pr.md` which is itself a stale pre-plugin path. The plugin is now at `plugins/prp-core/commands/`. Decision: rewrite to `plugins/prp-core/commands/prp-core-pr.md` as the most accurate target. If that file does not exist (the plugin renamed it), fall back to `plugins/prp-core/commands/prp-pr.md`. **Verify which exists before writing the diff.**
- **IMPLEMENT** (`prp_workflow.py`):
  - Lines 6, 9, 12, 15, 211: replace `.claude/PRPs/scripts/prp_workflow.py` → `PRPs/scripts/prp_workflow.py`
  - Lines 12, 211: replace `--prp-path .claude/PRPs/features/my-feature.md` → `--prp-path PRPs/features/my-feature.md`
  - Line 60: `str(ROOT / ".claude/PRPs/scripts/invoke_command.py")` → `str(ROOT / "PRPs/scripts/invoke_command.py")`
  - Line 80: `- \`.claude/PRPs/features/xxx.md\`` → `- \`PRPs/features/xxx.md\``
  - Line 83: comment `# Try to find .claude/PRPs/features/*.md pattern` → `# Try to find PRPs/features/*.md pattern`
  - Line 84: `re.search(r'\.claude/PRPs/features/[a-z0-9_-]+\.md', output)` → `re.search(r'PRPs/features/[a-z0-9_-]+\.md', output)`
  - Line 89: `re.search(r'\`([^\`]*\.claude/PRPs/features/[^\`]+\.md)\`', output)` → `re.search(r'\`([^\`]*PRPs/features/[^\`]+\.md)\`', output)`
- **GOTCHA**: Lines 84 and 89 are **regex literals** — the leading `\.` in `\.claude` is regex-escape syntax. After substitution, the literal becomes `PRPs/...` with no escape needed. Do not leave a stray `\` behind.
- **GOTCHA**: These scripts may be unused (they predate the plugin layout). Do **not** add coverage tests or rewrite their logic — the task is path-string consistency only.
- **VALIDATE**:
  ```bash
  python -c "import ast; ast.parse(open('PRPs/scripts/prp_workflow.py').read())"
  python -c "import ast; ast.parse(open('PRPs/scripts/invoke_command.py').read())"
  grep -n '.claude/PRPs' PRPs/scripts/                  # should return zero hits
  ```

### Task 4: Final grep gate + PRD update + commit

- **ACTION**: Run the final reference audit, update the PRD's Implementation Phases table, archive the plan, and commit.
- **IMPLEMENT**:
  1. Final grep audit (expected residual hits enumerated below):
     ```bash
     grep -rn '\.claude/PRPs' \
       --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=old-prp-commands \
       c:/Source/TrueNorthTeams/PRP-agentic-sdlc/
     ```
     **EXPECTED residual hits (all intentional):**
     - `.claude/user-journeys/migrate-v3-to-v4.md`, `partial-state-abort.md`, `fresh-project-no-migration.md` — describe consumer migration flow
     - `plugins/prp-core/commands/*.md` and `plugins/prp-core/skills/*/SKILL.md` — migration shim's V3 detection text
     - `PRPs/ralph-archives/**` — historical Ralph state files (frozen at point in time)
     - `PRPs/plans/completed/PRD001-P00*.plan.md` and `PRPs/reports/PRD001-P00*-report.md` — completed plans/reports referencing past state
     - `PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` — the PRD itself describes the migration
  2. Update PRD `.claude/PRPs/prds/...prd.md` ← **wait, this path is now `PRPs/prds/...prd.md` after Task 2**:
     - Edit `PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md`
     - In the Implementation Phases table, change Phase 4 row: `Status: pending` → `Status: complete`; add plan path `PRPs/plans/completed/PRD001-P004-self-migration-of-this-repo.plan.md` to the PRP Plan column.
  3. Archive plan: `git mv PRPs/plans/PRD001-P004-self-migration-of-this-repo.plan.md PRPs/plans/completed/`
  4. Write report at `PRPs/reports/PRD001-P004-self-migration-of-this-repo-report.md` (per Ralph completion protocol)
  5. Stage and commit (main-only strategy):
     ```bash
     git add -A
     git commit -m "refactor: self-migrate this repo to PRPs/ layout (PRD001-P004)"
     git push origin main
     ```
- **GOTCHA**: When updating the PRD, you must edit the file at its **new** path (`PRPs/prds/...`), not the old `.claude/PRPs/prds/...`. The plan-archival `git mv` likewise targets the new tree.
- **GOTCHA**: Do not amend the rename commit with the script edits — make them a single commit so reviewers see "rename + reference fixups" together. Use `git add -A` after Task 3 so the rename and the script edits land atomically.
- **VALIDATE**:
  ```bash
  git log --oneline -1                                  # single commit message visible
  git show --stat HEAD | head -20                       # confirms renames + 2 script modifications
  test -d PRPs && test ! -d .claude/PRPs                # final state correct
  ```

---

## Testing Strategy

### Unit Tests
N/A — no code logic changes.

### Validation
- **Static**: `python -c "import ast; ast.parse(...)"` on both edited scripts (Task 3 ends with this).
- **Reference grep gate**: enumerated in Task 4; residual hits must match the expected list and contain no surprise paths.
- **Behavioral spot-check** (manual, post-commit): Run any `/prp-core:*` read-only command (e.g., `/prp-core:prp-whats-next`) in this repo and confirm:
  - No migration-shim banner appears (because `PRPs/` already exists, shim should no-op).
  - Output reads from `PRPs/` paths.

### Edge Cases Checklist
- [ ] Working tree clean before starting (Task 1)
- [ ] No partial state (`PRPs/` does not exist before move)
- [ ] All ~40 artifact files appear as `R` (renamed) in `git status --porcelain`, not as deleted+added
- [ ] Both edited Python scripts parse with `ast.parse`
- [ ] Final grep gate returns only the enumerated intentional hits
- [ ] After commit, running a PRP command writes to `PRPs/` without triggering the shim
- [ ] `.counters.json` survived the move with content `{"vision":0,"prd":1,"plan":4}` (this plan creation increments to 4)

---

## Validation Commands

### Level 1: STATIC_ANALYSIS
```bash
python -c "import ast; ast.parse(open('PRPs/scripts/invoke_command.py').read())"
python -c "import ast; ast.parse(open('PRPs/scripts/prp_workflow.py').read())"
```

### Level 2: REFERENCE GATE
```bash
# In-script residual check (must be zero)
grep -n '\.claude/PRPs' PRPs/scripts/invoke_command.py PRPs/scripts/prp_workflow.py

# Whole-repo audit (must match enumerated intentional residuals only)
grep -rn '\.claude/PRPs' \
  --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=old-prp-commands \
  c:/Source/TrueNorthTeams/PRP-agentic-sdlc/
```

### Level 3: STRUCTURAL
```bash
test ! -d .claude/PRPs                        # source removed
test -d PRPs                                  # target exists
test -f PRPs/.counters.json                   # counters preserved
git log --diff-filter=R --name-status -1 | head -20   # rename detection working
```

### Level 4: BEHAVIORAL (manual, post-commit)
- Run `/prp-core:prp-whats-next` (or any read-only PRP command) in this repo.
- Confirm: no migration-shim banner; output references `PRPs/` paths.

---

## Acceptance Criteria

- [ ] `.claude/PRPs/` no longer exists at the repo root
- [ ] `PRPs/` exists with the full prior tree (features, plans, prds, ralph-archives, reports, scripts) and `.counters.json`
- [ ] `git log --diff-filter=R` shows the rename was detected (history preserved)
- [ ] `PRPs/scripts/invoke_command.py` and `PRPs/scripts/prp_workflow.py` parse and contain zero `.claude/PRPs` references
- [ ] Final grep gate returns only the enumerated intentional residuals
- [ ] PRD Phase 4 status set to `complete`; plan path linked
- [ ] Plan archived to `PRPs/plans/completed/`
- [ ] Single atomic commit on `main` per `main-only` strategy

---

## Completion Checklist

- [ ] All 4 tasks executed in order
- [ ] Level 1 static analysis passes
- [ ] Level 2 reference gate matches enumerated residuals exactly
- [ ] Level 3 structural checks pass
- [ ] PRD updated; plan archived; report written
- [ ] Commit + push completed

---

## Risks and Mitigations

| Risk                                                              | Likelihood | Impact | Mitigation                                                                  |
| ----------------------------------------------------------------- | ---------- | ------ | --------------------------------------------------------------------------- |
| `git mv` loses rename detection across ~40 files                  | LOW        | LOW    | Pass directory (not files individually); verify with `git status -porcelain` |
| Partial state already present (`PRPs/` exists alongside `.claude/PRPs/`) | LOW        | MED    | Task 1 pre-flight aborts before any destructive op                          |
| Script regex literals broken by sloppy substitution               | MED        | LOW    | Per-line diff in Task 3 + `ast.parse` validation                            |
| Migration shim fires after this commit (because consumers see new state via plugin source pull) | LOW | LOW | Shim's pre-condition is `.claude/PRPs/` exists in *consumer* repo, not this one — uncoupled |
| In-flight Ralph state file at `.claude/prp-ralph.state.md` accidentally moved | LOW | MED | It's at `.claude/`, not `.claude/PRPs/` — outside the move scope. Verify via `ls .claude/` after Task 2 |
| Grep gate catches a forgotten reference outside enumerated set    | LOW        | MED    | Task 4 fails closed: review and either add to expected list or fix          |

---

## Notes

- **Why a deliberate Phase rather than letting the shim do it**: The shim is for *consumer* projects upgrading from v3. Letting it migrate this repo opportunistically would produce a one-line auto-commit indistinguishable from real work and would not include the script-path fix-ups. Phase 4 makes the move a first-class commit with full reference audit.
- **`.counters.json` increment**: Performed at plan-creation time (this plan). After self-migration, the file is at `PRPs/.counters.json` with content `{"vision":0,"prd":1,"plan":4}`.
- **Phase 5 dependency**: Once this commits, Phase 5 (release v4.0.0) is unblocked — the plugin source is V4, the docs are V4, and now the source-of-truth repo runs V4.
- **Confidence Score**: 9/10. The change set is fully enumerated, `git mv` is the same command the shim uses successfully (proven via Phase 2 journeys), and the script edits are mechanical with `ast.parse` as a structural safety net. The only unknowable is whether running a PRP command after the move surfaces some hardcoded `.claude/PRPs/` reference no grep caught — Level 4 manual check exists for exactly that reason.
