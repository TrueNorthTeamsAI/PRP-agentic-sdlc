# Feature: Plugin Path Migration — `.claude/PRPs/` → `PRPs/`

## Summary

Mechanical search-replace of the artifact directory path `.claude/PRPs/` to `PRPs/` across all plugin command, skill, template, and root-level documentation files. This is Phase 1 of PRD001 — it changes only the *strings* the plugin commands write, reads, and shows to users. It does not move actual artifacts (Phase 4) and does not add migration logic (Phase 2). After this phase, freshly initialized projects will create `PRPs/` directly; existing v3 projects will break until Phase 2 ships the migration shim.

## User Story

As a developer running PRP commands with bypass-permissions enabled,
I want command-level path references rewritten to `PRPs/`,
So that artifact writes target a top-level directory and stop triggering Claude Code's `.claude/`-permission-prompt bug.

## Problem Statement

Every plugin command currently writes artifacts to `.claude/PRPs/`. Claude Code's bypass-permissions mode has a known bug that prompts on `.claude/` writes anyway, so daily PRP workflows are interrupted. The first step toward fixing this is to update every literal `.claude/PRPs/` reference inside the plugin source so commands target a non-`.claude/` directory.

## Solution Statement

Edit 20 source files (13 commands, 2 skills, 1 template, 4 docs) and replace 152 occurrences of `.claude/PRPs/` with `PRPs/`. No logic changes. No new files. Replacements span six usage categories: operational Read/Write tool calls, bash code-fence examples, output-path prose, user-visible reporting blocks, slash-command examples, and prose descriptions. Historical/archived files (PRD001 itself, `old-prp-commands/`, `.claude/PRPs/features/completed/`, legacy `.claude/PRPs/scripts/*.py`) are explicitly excluded.

## Metadata

| Field            | Value |
| ---------------- | ----- |
| Type             | REFACTOR |
| Complexity       | LOW |
| Systems Affected | plugins/prp-core/commands, plugins/prp-core/skills, plugins/prp-core/templates, root docs |
| Dependencies     | none |
| Estimated Tasks  | 22 |
| Source PRD       | `.claude/PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` |
| PRD Phase        | Phase 1 — Plugin path migration |

---

## UX Design

### Before State

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              BEFORE STATE                                      ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║   ┌─────────────┐         ┌──────────────────┐        ┌──────────────────┐    ║
║   │  /prp-prd   │ ──────► │  Write to        │ ─────► │  Permission      │    ║
║   │  /prp-plan  │         │ .claude/PRPs/... │        │  prompt fires    │    ║
║   └─────────────┘         └──────────────────┘        └──────────────────┘    ║
║                                                                ▼               ║
║   USER_FLOW: User invokes command → command says "writing to .claude/PRPs/X"   ║
║              → Claude Code prompts despite bypass-permissions                  ║
║   PAIN_POINT: Every artifact write interrupts flow                             ║
║   DATA_FLOW: command file (literal `.claude/PRPs/...`) → Write tool → prompt   ║
║                                                                                ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

### After State

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                               AFTER STATE                                      ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║   ┌─────────────┐         ┌──────────────────┐        ┌──────────────────┐    ║
║   │  /prp-prd   │ ──────► │  Write to        │ ─────► │  No prompt       │    ║
║   │  /prp-plan  │         │  PRPs/...        │        │  Write proceeds  │    ║
║   └─────────────┘         └──────────────────┘        └──────────────────┘    ║
║                                                                                ║
║   USER_FLOW: User invokes command → command says "writing to PRPs/X" → done   ║
║   VALUE_ADD: Command output paths and examples now target a top-level         ║
║              `PRPs/` directory (Phase 2 will add the auto-migration)          ║
║   DATA_FLOW: command file (literal `PRPs/...`) → Write tool → success         ║
║                                                                                ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

### Interaction Changes

| Location | Before | After | User Impact |
|----------|--------|-------|-------------|
| `/prp-prd` output report | `**File**: .claude/PRPs/prds/...` | `**File**: PRPs/prds/...` | Copy-pasted next-step path no longer hits `.claude/` |
| `/prp-plan` output report | `**OUTPUT_FILE**: .claude/PRPs/plans/...` | `**OUTPUT_FILE**: PRPs/plans/...` | Same |
| `/prp-implement` archive prose | `Plan archived to: .claude/PRPs/plans/completed/` | `Plan archived to: PRPs/plans/completed/` | Same |
| README artifact tree | `.claude/PRPs/` tree | `PRPs/` tree | Docs reflect new layout |

---

## User Journeys

This feature has no end-user-facing UI flows. Plugin authors and PRP-command users observe the change through command output strings only. No `.claude/user-journeys/` files needed for Phase 1 (Phases 2 and 4 may need them for the migration experience).

---

## How to Execute

### Start Services
N/A — this repo has no runtime services. Validation is grep-based.

### Seed Data / Reset State
N/A.

### Verify Ready
```powershell
git status                                # working tree state
Get-Location                              # confirm in PRP-agentic-sdlc root
```

### Teardown
N/A.

---

## Mandatory Reading

**CRITICAL: Implementation agent MUST read these files before starting any task:**

| Priority | File | Lines | Why Read This |
|----------|------|-------|---------------|
| P0 | `.claude/PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` | all | Source PRD, scope, NOT-building list |
| P0 | `plugins/prp-core/commands/prp-prd.md` | 245-275, 525-565, 590-650 | High-density `.claude/PRPs/` block (counters + git add + output reporting) |
| P0 | `plugins/prp-core/commands/prp-plan.md` | 425-510, 850-945 | Counters block + completion bash + output reporting |
| P1 | `plugins/prp-core/commands/prp-ralph.md` | 40-90, 300-410, 510-520 | Highest-occurrence file (14 hits) — variable assignment, archive paths |
| P1 | `plugins/prp-core/commands/prp-implement.md` | 325-340, 495-585 | Reports + archive completion bash |
| P1 | `plugins/prp-core/commands/prp-validate-file-naming.md` | 1-50, 125-205 | Find/grep commands referencing `.claude/PRPs` |
| P2 | `plugins/prp-core/skills/prp-ralph-loop/SKILL.md` | 38-50, 175-200, 315-325 | State-file template embeds path; archive prose |
| P2 | `plugins/prp-core/skills/build-with-agent-team/SKILL.md` | 388-420 | Archive completion bash mirrored from prp-plan |
| P2 | `plugins/prp-core/templates/vision.md` | 15-25 | Embedded prose inside generated vision documents |

**External Documentation:** None — pure path-string refactor.

**Context Sources Loaded** (from `context-map.md` via Phase 1.5): None loaded; no `context-map.md` matches at the PRP-framework level.

---

## Patterns to Mirror

This is a string-replacement refactor — not a code-pattern-mirroring task. The "pattern" is uniform replacement. Reference the canonical examples below for the *kinds* of strings being changed.

**OPERATIONAL_READ_WRITE_PATH:**
```
SOURCE: plugins/prp-core/commands/prp-prd.md:249-251
BEFORE:
  1. Read `.claude/PRPs/.counters.json` (use Read tool). If the file does not exist, treat it as `{"vision": 0, "prd": 0, "plan": 0}`.
  3. Write updated counters back to `.claude/PRPs/.counters.json` (use Write tool).
AFTER:
  1. Read `PRPs/.counters.json` (use Read tool). If the file does not exist, treat it as `{"vision": 0, "prd": 0, "plan": 0}`.
  3. Write updated counters back to `PRPs/.counters.json` (use Write tool).
```

**BASH_CODE_FENCE:**
```
SOURCE: plugins/prp-core/commands/prp-plan.md:873
BEFORE:
  git add .claude/PRPs/plans/{numbered-filename} .claude/PRPs/.counters.json
AFTER:
  git add PRPs/plans/{numbered-filename} PRPs/.counters.json
```

**MKDIR:**
```
SOURCE: plugins/prp-core/commands/prp-implement.md:330
BEFORE: mkdir -p .claude/PRPs/reports
AFTER:  mkdir -p PRPs/reports
```

**USER_VISIBLE_REPORT:**
```
SOURCE: plugins/prp-core/commands/prp-prd.md:561
BEFORE: **File**: .claude/PRPs/prds/{numbered-name}.prd.md
AFTER:  **File**: PRPs/prds/{numbered-name}.prd.md
```

**SLASH_COMMAND_EXAMPLE:**
```
SOURCE: plugins/prp-core/commands/prp-plan.md:939
BEFORE: /prp-implement .claude/PRPs/plans/{numbered-filename}
AFTER:  /prp-implement PRPs/plans/{numbered-filename}
```

**EMBEDDED_TEMPLATE_PROSE:**
```
SOURCE: plugins/prp-core/templates/vision.md:19
BEFORE: When all PRDs are complete, move this file to .claude/PRPs/visions/completed/
AFTER:  When all PRDs are complete, move this file to PRPs/visions/completed/
```

**SHELL_VARIABLE_VALUE:**
```
SOURCE: plugins/prp-core/commands/prp-ralph.md:349
BEFORE: ARCHIVE_DIR=".claude/PRPs/ralph-archives/${DATE}-${PLAN_NAME}"
AFTER:  ARCHIVE_DIR="PRPs/ralph-archives/${DATE}-${PLAN_NAME}"
```

**FIND_COMMAND_PATH_ARG:**
```
SOURCE: plugins/prp-core/commands/prp-validate-file-naming.md:39-41
BEFORE: find .claude/PRPs -type f -name "*.md" | sort
        find .claude/PRPs/ralph-archives -type d
AFTER:  find PRPs -type f -name "*.md" | sort
        find PRPs/ralph-archives -type d
```

---

## Files to Change

| File | Action | Occurrences | Justification |
|------|--------|-------------|---------------|
| `plugins/prp-core/commands/prp-prd.md` | UPDATE | 11 | Counters file, output paths, git add, user report |
| `plugins/prp-core/commands/prp-plan.md` | UPDATE | 10 | Counters file, output paths, git add, user report |
| `plugins/prp-core/commands/prp-ralph.md` | UPDATE | 14 | Plan path, ralph-archives, mkdir, ARCHIVE_DIR var, ls/cat examples |
| `plugins/prp-core/commands/prp-implement.md` | UPDATE | 11 | Reports dir, archive bash, user report |
| `plugins/prp-core/commands/prp-review.md` | UPDATE | 10 | Reviews dir, ls reports, gh pr review --body-file |
| `plugins/prp-core/commands/prp-vision.md` | UPDATE | 9 | Counters, visions dir, git add, user report |
| `plugins/prp-core/commands/prp-whats-next.md` | UPDATE | 9 | Glob patterns, counters, "no artifacts" report |
| `plugins/prp-core/commands/prp-issue-fix.md` | UPDATE | 7 | issues dir + completed |
| `plugins/prp-core/commands/prp-issue-investigate.md` | UPDATE | 6 | issues dir, mkdir, output prose, git add |
| `plugins/prp-core/commands/prp-validate-file-naming.md` | UPDATE | 6 | find/grep paths, scan target |
| `plugins/prp-core/commands/prp-codebase-question.md` | UPDATE | 4 | research dir |
| `plugins/prp-core/commands/prp-research-team.md` | UPDATE | 4 | research-plans dir |
| `plugins/prp-core/commands/prp-debug.md` | UPDATE | 3 | debug dir |
| `plugins/prp-core/skills/build-with-agent-team/SKILL.md` | UPDATE | 6 | Archive completion bash (PRD/plan completed dirs) |
| `plugins/prp-core/skills/prp-ralph-loop/SKILL.md` | UPDATE | 5 | State file plan_path example, archive prose, ralph-archives tree |
| `plugins/prp-core/templates/vision.md` | UPDATE | 1 | Embedded "move to completed" prose in generated vision docs |
| `plugins/prp-core/README.md` | UPDATE | 5 | Workflow command examples + artifact tree block |
| `README.md` | UPDATE | 14 | Command examples, vision workflow, artifact tree, .counters.json |
| `README-for-DUMMIES.md` | UPDATE | 14 | Mirror of README.md |
| `CLAUDE.md` | UPDATE | 8 | Artifact storage section, vision flag example, counter location, dir tree |

**Files explicitly NOT changed:**

| File | Reason |
|------|--------|
| `.claude/PRPs/prds/PRD001-*.prd.md` | This is the source PRD; `.claude/PRPs/` text is intentional historical reference |
| `.claude/PRPs/features/completed/*.md` | Archived/historical feature designs |
| `.claude/PRPs/scripts/*.py` | Legacy scripts under old path; will move with `git mv` in Phase 4. Not part of plugin source |
| `old-prp-commands/prp-old/*.md` | Archived commands |
| Hooks (`plugins/prp-core/hooks/`) | Verified zero occurrences |
| Agents (`plugins/prp-core/agents/`) | Verified zero occurrences |
| `claude_md_files/*.md` | Verified zero occurrences |

---

## NOT Building (Scope Limits)

- **Migration shim logic** — Phase 2 of PRD001. This phase only changes path strings.
- **Moving artifacts on disk** — Phase 4 of PRD001. The repo's own `.claude/PRPs/` stays where it is until then.
- **Updating `.gitignore`** — neither path is ignored; PRD confirms no `.gitignore` change expected.
- **Renaming artifact extensions** — `.prd.md`, `.plan.md`, `.vision.md` stay.
- **Changing `.claude/rules/`, `.claude/settings.local.json`, or `.claude/commands/`** — out of scope per PRD.
- **Updating archived/historical docs** — PRD001 itself, `old-prp-commands/`, `.claude/PRPs/features/completed/`, legacy `.claude/PRPs/scripts/*.py` are intentionally untouched.
- **Bumping `plugin.json` version** — Phase 5 of PRD001.
- **Writing CHANGELOG entry** — Phase 5 of PRD001.

---

## Step-by-Step Tasks

Execute in order. Each task uses the same pattern: open the file, run targeted Edit replacements (prefer `replace_all=true` for unambiguous strings), validate with grep.

**Pre-task setup (Task 0):**

### Task 0: Baseline grep
- **ACTION**: Capture baseline occurrence count to verify against post-edit count
- **COMMAND**:
  ```powershell
  Grep pattern: "\.claude/PRPs" (regex), output_mode: count, path: c:\Source\TrueNorthTeams\PRP-agentic-sdlc
  ```
- **EXPECT**: ~241 total across ~27 files (includes intentionally-excluded files)
- **RECORD**: Note count for files in scope (target: 152 across 20 files)
- **VALIDATE**: Counts captured for diff comparison after each edit

### Task 1: UPDATE `plugins/prp-core/commands/prp-prd.md` (11 → 0)
- **ACTION**: Replace all `.claude/PRPs/` with `PRPs/` using `Edit replace_all=true`
- **STRING**: `.claude/PRPs/` → `PRPs/`
- **GOTCHA**: Verify no occurrences remain by grepping just this file after edit
- **VALIDATE**: `Grep pattern="\.claude/PRPs" path=plugins/prp-core/commands/prp-prd.md` → 0 matches

### Task 2: UPDATE `plugins/prp-core/commands/prp-plan.md` (10 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 3: UPDATE `plugins/prp-core/commands/prp-ralph.md` (14 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **GOTCHA**: This file has the `ARCHIVE_DIR=".claude/PRPs/ralph-archives/..."` shell variable — confirm the resulting `ARCHIVE_DIR="PRPs/ralph-archives/..."` is still valid bash (no leading slash needed; relative paths are fine).
- **VALIDATE**: per-file grep returns 0 matches

### Task 4: UPDATE `plugins/prp-core/commands/prp-implement.md` (11 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 5: UPDATE `plugins/prp-core/commands/prp-review.md` (10 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **GOTCHA**: `gh pr review --body-file .claude/PRPs/reviews/...` — confirm replacement keeps the `--body-file` arg intact. Using `replace_all` on the bare path string handles this safely.
- **VALIDATE**: per-file grep returns 0 matches

### Task 6: UPDATE `plugins/prp-core/commands/prp-vision.md` (9 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 7: UPDATE `plugins/prp-core/commands/prp-whats-next.md` (9 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **GOTCHA**: This file contains glob patterns like `.claude/PRPs/visions/*.vision.md` — replacement preserves the glob suffix.
- **VALIDATE**: per-file grep returns 0 matches; spot-check the glob patterns still parse as valid globs.

### Task 8: UPDATE `plugins/prp-core/commands/prp-issue-fix.md` (7 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 9: UPDATE `plugins/prp-core/commands/prp-issue-investigate.md` (6 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 10: UPDATE `plugins/prp-core/commands/prp-validate-file-naming.md` (6 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **GOTCHA**: This file also has `find .claude/PRPs -type f` (no trailing slash) — that occurrence will NOT match `.claude/PRPs/`. Run a second targeted Edit for the trailing-slash-less form: `find .claude/PRPs ` → `find PRPs ` and `find .claude/PRPs\n` cases. After replace_all on `.claude/PRPs/`, grep for residual `.claude/PRPs` (no trailing slash) and edit each remaining.
- **VALIDATE**: `Grep pattern="\.claude/PRPs" path=plugins/prp-core/commands/prp-validate-file-naming.md` → 0 matches (regardless of trailing slash)

### Task 11: UPDATE `plugins/prp-core/commands/prp-codebase-question.md` (4 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 12: UPDATE `plugins/prp-core/commands/prp-research-team.md` (4 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 13: UPDATE `plugins/prp-core/commands/prp-debug.md` (3 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 14: UPDATE `plugins/prp-core/skills/build-with-agent-team/SKILL.md` (6 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 15: UPDATE `plugins/prp-core/skills/prp-ralph-loop/SKILL.md` (5 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **GOTCHA**: Line ~41 has `plan_path: ".claude/PRPs/plans/add-feature.md"` inside a YAML state-file frontmatter example — confirm the resulting `plan_path: "PRPs/plans/add-feature.md"` is still valid YAML (it is — just a string value).
- **VALIDATE**: per-file grep returns 0 matches

### Task 16: UPDATE `plugins/prp-core/templates/vision.md` (1 → 0)
- **ACTION**: `Edit`, `.claude/PRPs/visions/completed/` → `PRPs/visions/completed/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 17: UPDATE `plugins/prp-core/README.md` (5 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 18: UPDATE `README.md` (14 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 19: UPDATE `README-for-DUMMIES.md` (14 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **VALIDATE**: per-file grep returns 0 matches

### Task 20: UPDATE `CLAUDE.md` (8 → 0)
- **ACTION**: `Edit replace_all=true`, `.claude/PRPs/` → `PRPs/`
- **GOTCHA**: There is one block under `.claude/` listing "what `.claude/` is reserved for" (lines ~26-29). After the bulk replace, that block will list `PRPs/` as reserved-under-`.claude/`, which is now wrong. Manually edit that block to drop the `PRPs/` and `PRPs/visions/` and `PRPs/.counters.json` entries (they no longer live under `.claude/`). Keep `.claude/settings.local.json` and any other genuinely-Claude-tooling lines.
- **VALIDATE**: per-file grep returns 0 matches; visually re-read the "reserved for" block to confirm correctness.

### Task 21: Final whole-tree grep
- **ACTION**: Confirm zero residual occurrences in scope
- **COMMAND**:
  ```
  Grep pattern: "\.claude/PRPs" path: c:\Source\TrueNorthTeams\PRP-agentic-sdlc output_mode: files_with_matches
  ```
- **EXPECT**: Only these files remain (intentionally excluded):
  - `.claude/PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md`
  - `.claude/PRPs/features/completed/add-vision-layer-and-numbering-system.md`
  - `.claude/PRPs/features/completed/add-prp-core-runner-skill.md`
  - `.claude/PRPs/scripts/invoke_command.py`
  - `.claude/PRPs/scripts/prp_workflow.py`
  - `old-prp-commands/prp-old/prp-core-create.md`
  - `old-prp-commands/prp-old/prp-core-execute.md`
  - `.claude/PRPs/plans/PRD001-P001-plugin-path-migration.plan.md` (this plan file — references the old path in scope tables)
- **VALIDATE**: No plugin command/skill/template/root-doc files appear in the residual list.

### Task 22: Smoke-read three command output blocks
- **ACTION**: Spot-check that user-visible output reports look right
- **READ**: `plugins/prp-core/commands/prp-prd.md` lines 555-600
- **READ**: `plugins/prp-core/commands/prp-plan.md` lines 890-940
- **READ**: `plugins/prp-core/commands/prp-implement.md` lines 575-590
- **EXPECT**: All `**File**:`, `**OUTPUT_FILE**:`, `Plan archived to:`, and slash-command-example lines now show `PRPs/...` (no `.claude/`).

---

## Testing Strategy

### Unit Tests to Write

N/A — markdown-only changes. No code under test.

### E2E Tests to Write

N/A for Phase 1. End-to-end PRP workflow validation lands in Phase 6 (consumer validation) once the migration shim is also in place.

### Edge Cases Checklist

- [ ] Trailing-slash-less forms (`find .claude/PRPs`) caught by Task 10's secondary grep
- [ ] No accidental over-replacement of `.claude/` (only `.claude/PRPs/` should change; e.g., `.claude/rules/`, `.claude/settings.local.json`, `.claude/commands/` mentions stay)
- [ ] CLAUDE.md "reserved for" block updated to remove the now-stale PRP entries
- [ ] Glob patterns in `prp-whats-next.md` remain valid globs after replacement
- [ ] YAML state-file example in `prp-ralph-loop/SKILL.md` remains valid YAML
- [ ] Bash variable assignment in `prp-ralph.md` (`ARCHIVE_DIR="..."`) remains valid

---

## Validation Commands

### Level 1: STATIC_ANALYSIS — Grep for residuals
```
Grep pattern="\.claude/PRPs" path=plugins/prp-core output_mode=count
```
**EXPECT**: zero matches across `plugins/prp-core/`

```
Grep pattern="\.claude/PRPs" path=. output_mode=files_with_matches
```
**EXPECT**: Only the 8 intentionally-excluded files appear (PRD001, two completed-features, two legacy scripts, two old-prp-commands files, this plan file).

### Level 2: STATIC_ANALYSIS — Stale `.claude/` references in CLAUDE.md
Read `CLAUDE.md` lines 25-30. Confirm the block listing what `.claude/` contains no longer mentions `PRPs/`, `PRPs/visions/`, or `.counters.json`.

### Level 3: STATIC_ANALYSIS — No accidental damage
```
Grep pattern="\.claude/(rules|settings|commands|hooks|agents|skills)" path=plugins/prp-core output_mode=count
```
**EXPECT**: Same count as before edits (this verifies we didn't accidentally replace other `.claude/...` paths).

### Level 4: DATABASE_VALIDATION

N/A.

### Level 5: USER_JOURNEY_VALIDATION

N/A. End-to-end PRP command runs are deferred to Phase 6 (consumer validation), since running a PRP command in this repo right now without the migration shim (Phase 2) and the artifact move (Phase 4) would target a `PRPs/` directory that does not yet exist on disk and fail to find existing PRDs/visions.

### Level 6: MANUAL_VALIDATION

1. Open `plugins/prp-core/commands/prp-prd.md` in an editor.
2. Search for `.claude/PRPs` — should find nothing.
3. Search for `PRPs/` — should find ~11 hits, all in plausible places (counters file, output paths, git add, user reports).
4. Repeat for `prp-plan.md`, `prp-ralph.md`, `prp-implement.md` (the four heavy-occurrence files).
5. Read `CLAUDE.md` end-to-end and confirm the artifact storage section reads coherently with the new `PRPs/` layout.

---

## Acceptance Criteria

- [ ] All 20 in-scope files have zero `.claude/PRPs` occurrences
- [ ] The 8 intentionally-excluded files remain unchanged (PRD001 still has its 33 references, etc.)
- [ ] `CLAUDE.md` reserved-for block is corrected to remove now-stale `.claude/PRPs/...` entries
- [ ] No accidental edits to other `.claude/...` paths (`rules/`, `settings.local.json`, etc.)
- [ ] Spot-checked output blocks in prp-prd, prp-plan, prp-implement, prp-vision render coherently with `PRPs/` paths
- [ ] Plan does not break the PRD's "Won't" rules (no dual-path support, no v3.x backport, no separate migration command in this phase)

---

## Completion Checklist

- [ ] Task 0 baseline grep recorded
- [ ] Tasks 1-20 completed in order, each validated by per-file grep
- [ ] Task 21 final tree-wide grep returns only the 8 excluded files (+ this plan file)
- [ ] Task 22 spot-read confirms output blocks read correctly
- [ ] Level 1-3 grep validations pass
- [ ] Level 6 manual read-through complete
- [ ] PRD001 phase 1 status updated from `pending` to `in-progress` → `complete` after merge
- [ ] Plan archived to `PRPs/plans/completed/` (or `.claude/PRPs/plans/completed/` if Phase 4 hasn't happened yet — keep on whichever path is current at completion time)
- [ ] Git commit created per `main-only` strategy

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `replace_all` over-replaces a path that should keep `.claude/PRPs/` (e.g., a CHANGELOG-style example) | LOW | MED | None of the in-scope files contain such examples (verified by inventory). The 8 excluded files are not edited at all. |
| Repo becomes broken between Phase 1 and Phase 4 (commands write to `PRPs/` but artifacts still live in `.claude/PRPs/`) | HIGH | MED | This is expected and accepted — Phase 1, 2, 3 land together (parallel) and Phase 4 immediately follows. Don't ship Phase 1 alone in a release. |
| CLAUDE.md "reserved for" block left stale after bulk replace | MED | LOW | Task 20 GOTCHA explicitly calls this out; Level 2 validation re-reads the block. |
| Trailing-slash-less occurrences (`find .claude/PRPs`) missed | MED | LOW | Task 10 GOTCHA covers this; Task 21 final grep catches anything still missed. |
| Glob patterns broken by replacement | LOW | LOW | The replacement is a prefix swap; glob suffix is preserved. Edge-case re-check in Task 7. |
| Concurrent edits in parallel Phase 2/Phase 3 branches cause merge conflicts | MED | LOW | Phase 2 (migration shim) edits the *top* of command files (pre-flight call); Phase 3 (docs/scaffolding) mostly edits `claude_md_files/` (zero occurrences here) and `init-project` skill (zero occurrences). Conflict surface is minimal. |

---

## Notes

- **Why no validation script for end-to-end behavior?** Running `/prp-prd` in this repo right now would write to `PRPs/prds/...`, which doesn't exist on disk. Real end-to-end validation is gated on Phase 4 (artifact move) + Phase 5 (release) + Phase 6 (consumer test). Phase 1 stops at "all path strings are correct."
- **Excluded `.claude/PRPs/scripts/*.py`:** These legacy scripts contain regex patterns matching the old path. They will travel with the `git mv` in Phase 4. If anyone resurrects them later, those regexes need updating; flag this in the Phase 4 plan.
- **`.claude/PRPs/scripts/`** is itself an inconsistency vs. `PRPs/scripts/` mentioned in the root README's "Project Structure" section. Phase 4 will resolve this naturally when the directory moves.
- **CLAUDE.md project structure block (line ~197):** That block lists `.claude/PRPs/` as artifact storage. After Task 20, it should list `PRPs/`. Confirm the surrounding bullet about `.claude/` reserved usage no longer claims to host PRP artifacts.
- **Confidence**: HIGH for one-pass success — the inventory is complete (152 occurrences across 20 in-scope files), the change is uniform, and per-file grep validation catches misses immediately. Risk is concentrated in the CLAUDE.md "reserved for" block, which Task 20's GOTCHA addresses explicitly.
