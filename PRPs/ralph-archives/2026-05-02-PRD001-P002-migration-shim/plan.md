# Feature: Auto-Migration Shim — `.claude/PRPs/` → `PRPs/`

## Summary

Add a single, idempotent pre-flight check that runs at the top of every PRP command which touches artifacts. When a project still has the v3 layout (`.claude/PRPs/` exists, `PRPs/` does not), the shim performs `git mv .claude/PRPs PRPs` (or plain `mv` for non-git repos), prints a one-line announcement, and proceeds. When the project is already on v4 (`PRPs/` exists), the shim is a no-op. When both directories exist (partial state), the shim aborts with a clear error and asks the user to resolve manually. The shim is delivered as inline prose at the top of each artifact-touching command — no shared executable, no new skill — to avoid hidden control flow and keep each command self-contained.

## User Story

As a developer upgrading from prp-core v3.x to v4.0,
I want my existing `.claude/PRPs/` artifacts auto-migrated to `PRPs/` on first command invocation,
So that I don't have to perform a manual `git mv` and audit consumer projects before getting work done.

## Problem Statement

Phase 1 of PRD001 already rewrote every plugin command to read and write `PRPs/`. On any v3.x consumer project that has not been hand-migrated, the next PRP command will fail to find existing PRDs/visions/plans because they still live under `.claude/PRPs/`. Without a migration mechanism, every consumer must perform a manual `git mv .claude/PRPs PRPs` before their first v4 command works — a per-project chore that contradicts the PRD's "auto-migration" promise (PRD §Solution Detail, MoSCoW "Must").

## Solution Statement

Insert a small pre-flight block at the top of each artifact-touching command (and the two artifact-touching skills). The block:

1. Probes the working tree for one of four states: `FRESH`, `V3`, `V4`, `BOTH`.
2. On `V3`, runs `git mv .claude/PRPs PRPs` (or `mv` if not a git repo) and prints a one-line announcement.
3. On `BOTH`, aborts with a remediation message.
4. On `FRESH` or `V4`, is silent.

The block is **inline prose** repeated verbatim across commands, not a shared skill or script. Rationale: PRP commands are markdown — there is no runtime — so "shared" only saves duplicated text, not code. Inline keeps every command self-contained and discoverable. The block is small (~25 lines) and never changes once written. It is documented once in `plugins/prp-core/skills/init-project/SKILL.md` adjacent prose so future maintainers can find the canonical version (no executable role for that skill — it just hosts the reference text).

## Metadata

| Field            | Value |
| ---------------- | ----- |
| Type             | NEW_CAPABILITY |
| Complexity       | MEDIUM |
| Systems Affected | plugins/prp-core/commands (13 files), plugins/prp-core/skills (2 files) |
| Dependencies     | none — Phase 1 already complete |
| Estimated Tasks  | 18 |
| Source PRD       | `.claude/PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` |
| PRD Phase        | Phase 2 — Migration shim |

---

## UX Design

### Before State

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              BEFORE STATE (v3 consumer post-Phase-1)          ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║  ┌────────────────────┐    ┌────────────────────┐    ┌──────────────────────┐ ║
║  │ User runs          │ ─► │ Command tries to   │ ─► │ FAILURE: PRDs live   │ ║
║  │ /prp-plan PRD.md   │    │ Read PRPs/prds/... │    │ in .claude/PRPs/...  │ ║
║  └────────────────────┘    └────────────────────┘    └──────────────────────┘ ║
║                                                                                ║
║  USER_FLOW: User invokes any PRP command → gets "file not found" or similar   ║
║             → must manually `git mv .claude/PRPs PRPs` → retry.               ║
║  PAIN_POINT: Per-project manual migration; trust collapse on first run.       ║
║  DATA_FLOW: command starts → reads from PRPs/ (does not exist) → fails        ║
║                                                                                ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

### After State

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                               AFTER STATE                                      ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║  ┌────────────────────┐    ┌────────────────────┐    ┌──────────────────────┐ ║
║  │ User runs          │ ─► │ Pre-flight detects │ ─► │ git mv .claude/PRPs  │ ║
║  │ /prp-plan PRD.md   │    │ V3 layout          │    │ PRPs ; print notice  │ ║
║  └────────────────────┘    └────────────────────┘    └──────────┬───────────┘ ║
║                                                                  │             ║
║                                                                  ▼             ║
║                                                       ┌────────────────────┐  ║
║                                                       │ Command proceeds   │  ║
║                                                       │ on PRPs/...        │  ║
║                                                       └────────────────────┘  ║
║                                                                                ║
║  USER_FLOW: User invokes any PRP command → shim auto-migrates ONCE → command   ║
║             continues normally. Subsequent commands: silent no-op.            ║
║  VALUE_ADD: Zero-touch upgrade from v3 → v4. One-line "I moved your stuff"    ║
║             announcement preserves trust through transparency.                ║
║  DATA_FLOW: command starts → pre-flight probe → (optional `git mv`) → command ║
║                                                                                ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

### Interaction Changes

| Location | Before | After | User Impact |
|----------|--------|-------|-------------|
| First v4 command on v3 project | "file not found" / silent miss | One-line "→ Migrated `.claude/PRPs/` → `PRPs/` (git mv staged)" then command proceeds | Upgrade is invisible/automatic |
| First command on fresh project | Command runs against empty tree | Same — shim is no-op when neither dir exists | No change |
| Project with both dirs (partial) | Command picks wrong one silently | Aborts with remediation message | Surfaces ambiguity instead of corrupting state |

---

## User Journeys

| Journey File | Impact | Description |
|-------------|--------|-------------|
| `.claude/user-journeys/migrate-v3-to-v4.md` | NEW | First-command-after-upgrade auto-migration on a v3 consumer |
| `.claude/user-journeys/fresh-project-no-migration.md` | NEW | Shim is a no-op on a fresh repo |
| `.claude/user-journeys/partial-state-abort.md` | NEW | Shim aborts when both dirs exist |

**Automated** (validation scripts — blocking):
- `migrate-v3-to-v4.md` — scriptable: stage a temp git repo with `.claude/PRPs/`, run `/prp-whats-next`, assert `PRPs/` exists and `.claude/PRPs/` does not, assert `git status` shows the rename staged.
- `fresh-project-no-migration.md` — scriptable: empty repo, run `/prp-whats-next`, assert no `git mv` happened.
- `partial-state-abort.md` — scriptable: repo with both dirs, run any PRP command, assert it aborts and prints the expected message.

**Manual**: None.

---

## How to Execute

### Start Services

N/A — this repo has no runtime services. Validation is grep + manual journey replay against scratch git repos.

### Seed Data / Reset State

For each journey replay, prepare a scratch repo:

```powershell
# V3 scratch
$tmp = New-TemporaryFile ; rm $tmp ; mkdir $tmp ; cd $tmp
git init -q
mkdir -p .claude/PRPs/prds
"# fake PRD" | Out-File -Encoding utf8 .claude/PRPs/prds/PRD000-fake.prd.md
'{"vision":0,"prd":1,"plan":0}' | Out-File -Encoding utf8 .claude/PRPs/.counters.json
git add . ; git commit -q -m "v3 baseline"

# Fresh scratch
$tmp2 = New-TemporaryFile ; rm $tmp2 ; mkdir $tmp2 ; cd $tmp2
git init -q ; "# README" | Out-File README.md ; git add . ; git commit -q -m "fresh"

# Both scratch
$tmp3 = New-TemporaryFile ; rm $tmp3 ; mkdir $tmp3 ; cd $tmp3
git init -q ; mkdir -p .claude/PRPs ; mkdir -p PRPs
"" | Out-File .claude/PRPs/.gitkeep ; "" | Out-File PRPs/.gitkeep
git add . ; git commit -q -m "both"
```

### Verify Ready

```powershell
git status        # working tree clean before each journey
ls -la            # confirm expected starting layout
```

### Teardown

```powershell
cd $HOME ; rm -rf $tmp $tmp2 $tmp3   # discard scratch repos
```

---

## Mandatory Reading

**CRITICAL: Implementation agent MUST read these files before starting any task:**

| Priority | File | Lines | Why Read This |
|----------|------|-------|---------------|
| P0 | `.claude/PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` | all | Source PRD; MoSCoW for shim; risks (partial state, non-git repo); Phase-2 success signal |
| P0 | `.claude/PRPs/plans/completed/PRD001-P001-plugin-path-migration.plan.md` | 1-100, 230-260 | Phase-1 scope; lists exactly which files were edited and the inventory of artifact-touching commands |
| P0 | `plugins/prp-core/commands/prp-prd.md` | 1-50 | Top-of-command structure for inserting the shim after frontmatter, before "Your Role" / Phase 0.5 |
| P0 | `plugins/prp-core/commands/prp-plan.md` | 1-60 | Top-of-command structure (uses `<objective>` / `<context>` / `<process>` blocks instead of `## Your Role`) |
| P0 | `plugins/prp-core/commands/prp-ralph.md` | 1-60 | Top-of-command structure (uses `## Phase 1: PARSE`); shim must precede arg parsing |
| P1 | `plugins/prp-core/commands/prp-whats-next.md` | 1-40 | Top-of-command for the "discovery" command — likely first invoked on an upgraded project |
| P1 | `plugins/prp-core/commands/prp-implement.md` | 1-30 | Pattern: this command begins with `## Phase 0: DETECT - Project Environment`; shim goes before Phase 0 |
| P1 | `plugins/prp-core/commands/prp-validate-file-naming.md` | 1-50 | Has its own grep-driven workflow; confirm shim integrates cleanly |
| P1 | `plugins/prp-core/skills/prp-ralph-loop/SKILL.md` | 1-60 | Skill is invoked mid-loop; needs shim guard for the case where loop starts on a v3 layout but the user upgraded mid-ralph (rare but possible) |
| P1 | `plugins/prp-core/skills/build-with-agent-team/SKILL.md` | 1-60 | Same rationale — skill performs artifact reads/writes |
| P2 | `plugins/prp-core/skills/init-project/SKILL.md` | all | Reference home for the canonical shim text; init-project does NOT call the shim (fresh repos never have `.claude/PRPs/`) |
| P2 | `plugins/prp-core/commands/prp-ralph-cancel.md` | all | Confirm exclusion — does it touch artifacts? (It removes a state file under `.claude/`; check whether shim applies) |

**External Documentation:**

| Source | Section | Why Needed |
|--------|---------|------------|
| [git-mv(1)](https://git-scm.com/docs/git-mv) | "DESCRIPTION" + "OPTIONS" | Confirm `git mv` semantics: stages the rename in one atomic step; preserves history via rename detection; fails if destination exists |
| [git-status porcelain](https://git-scm.com/docs/git-status#_porcelain_format_version_1) | "Porcelain Format" | If we add an optional "uncommitted edits warning" (PRD MoSCoW Could), use `git status --porcelain` to detect dirty state under `.claude/PRPs/` before moving |

GOTCHA captured from git-mv docs: `git mv` requires the **destination to not exist**. If it does (the `BOTH` state), the command fails with `fatal: destination exists`. The shim's `BOTH`-state abort handles this proactively rather than relying on the git error.

**Context Sources Loaded** (from `context-map.md` via Phase 1.5): None — no `context-map.md` at the repo root.

---

## Patterns to Mirror

This is a new pre-flight block, but the *style* mirrors existing top-of-command structure.

**TOP_OF_COMMAND_INSERTION_POINT (Process-style command):**

```
SOURCE: plugins/prp-core/commands/prp-prd.md:1-12
EXISTING:
  ---
  description: Interactive PRD generator - problem-first, hypothesis-driven product spec
  argument-hint: [feature/product idea] (blank = start with questions)
  ---

  # Product Requirements Document Generator

  **Input**: $ARGUMENTS

  ---

  ## Your Role

INSERT SHIM BLOCK AFTER the first `---` separator (i.e., right after `**Input**: $ARGUMENTS\n\n---\n`) and BEFORE `## Your Role`.
```

**TOP_OF_COMMAND_INSERTION_POINT (Objective-style command):**

```
SOURCE: plugins/prp-core/commands/prp-plan.md:1-39
EXISTING:
  ---
  description: ...
  argument-hint: ...
  ---

  <objective>
  ...
  </objective>

  <context>
  ...
  </context>

  <process>

  ## Phase 0: DETECT - Input Type Resolution

INSERT SHIM BLOCK BETWEEN `</context>` and `<process>` — i.e., as a `## Phase 0: PRE-FLIGHT - Artifact Path Migration` that runs before the existing Phase 0.
```

**TOP_OF_COMMAND_INSERTION_POINT (Mission-style command):**

```
SOURCE: plugins/prp-core/commands/prp-ralph.md:1-22
EXISTING:
  ---
  description: ...
  argument-hint: ...
  ---

  # PRP Ralph Loop

  **Input**: $ARGUMENTS

  ---

  ## Your Mission
  ...
  ---

  ## Phase 1: PARSE - Validate Input

INSERT SHIM BLOCK AFTER `## Your Mission` paragraph and BEFORE `## Phase 1: PARSE`. Add as `## Phase 0: PRE-FLIGHT - Artifact Path Migration`.
```

**ANNOUNCEMENT_TONE:**

```
SOURCE: plugins/prp-core/commands/prp-implement.md (existing user-visible report style)
PATTERN: One-line, prefixed with `→`, no surrounding chrome.
EXAMPLE: `→ Migrated PRP artifacts: .claude/PRPs/ → PRPs/ (git mv staged for next commit)`
```

**ABORT_MESSAGE_TONE:**

```
SOURCE: plugins/prp-core/commands/prp-ralph.md:40-49 (existing STOP-with-message pattern)
PATTERN: Bold "STOP", then explanation, then bash code block with remediation.
ADAPT FOR SHIM:
  STOP: PRP artifact directory is in a partial-migration state.

  Both `.claude/PRPs/` and `PRPs/` exist. The migration shim cannot decide which is authoritative.

  Resolve by choosing one:
  ```bash
  # If PRPs/ has the latest work:
  rm -rf .claude/PRPs

  # If .claude/PRPs/ has the latest work:
  rm -rf PRPs
  git mv .claude/PRPs PRPs
  ```
  Then re-run the command.
```

---

## Files to Change

| File | Action | Justification |
|------|--------|---------------|
| `plugins/prp-core/skills/init-project/SKILL.md` | UPDATE | Embed canonical shim block as reference text + scaffolding-side note that init-project does NOT call it (fresh repos always FRESH state) |
| `plugins/prp-core/commands/prp-prd.md` | UPDATE | Add Phase 0 shim block at top |
| `plugins/prp-core/commands/prp-plan.md` | UPDATE | Add Phase 0 shim block (between `</context>` and `<process>`) |
| `plugins/prp-core/commands/prp-ralph.md` | UPDATE | Add Phase 0 shim block before existing Phase 1 |
| `plugins/prp-core/commands/prp-implement.md` | UPDATE | Add Phase 0 shim block before existing Phase 0: DETECT (rename to "Phase -1" or insert as new "Phase 0: PRE-FLIGHT" and renumber) |
| `plugins/prp-core/commands/prp-vision.md` | UPDATE | Add shim |
| `plugins/prp-core/commands/prp-whats-next.md` | UPDATE | Add shim |
| `plugins/prp-core/commands/prp-issue-investigate.md` | UPDATE | Add shim |
| `plugins/prp-core/commands/prp-issue-fix.md` | UPDATE | Add shim |
| `plugins/prp-core/commands/prp-validate-file-naming.md` | UPDATE | Add shim |
| `plugins/prp-core/commands/prp-codebase-question.md` | UPDATE | Add shim |
| `plugins/prp-core/commands/prp-research-team.md` | UPDATE | Add shim |
| `plugins/prp-core/commands/prp-debug.md` | UPDATE | Add shim |
| `plugins/prp-core/commands/prp-review.md` | UPDATE | Add shim (writes to `PRPs/reviews/`) |
| `plugins/prp-core/skills/prp-ralph-loop/SKILL.md` | UPDATE | Add shim guard at the top of iteration entry |
| `plugins/prp-core/skills/build-with-agent-team/SKILL.md` | UPDATE | Add shim guard at the top |
| `.claude/user-journeys/migrate-v3-to-v4.md` | CREATE | Automated journey — V3 → V4 |
| `.claude/user-journeys/fresh-project-no-migration.md` | CREATE | Automated journey — FRESH no-op |
| `.claude/user-journeys/partial-state-abort.md` | CREATE | Automated journey — BOTH abort |

**Files explicitly NOT changed:**

| File | Reason |
|------|--------|
| `plugins/prp-core/commands/prp-commit.md` | Does not read or write artifact files; just `git add` / `git commit`. No shim needed. (VERIFY in Task 0.) |
| `plugins/prp-core/commands/prp-pr.md` | Same — only invokes `gh pr create`. (VERIFY in Task 0.) |
| `plugins/prp-core/commands/prp-review-agents.md` | Spawns subagents that themselves run no artifact reads on the host repo. (VERIFY in Task 0.) |
| `plugins/prp-core/commands/prp-ralph-cancel.md` | Touches `.claude/prp-ralph.state.md` (Claude tooling state, NOT an artifact). Shim does not apply. (VERIFY in Task 0.) |
| `plugins/prp-core/commands/version.md` | Pure read of `plugin.json`. No artifacts. |
| `plugins/prp-core/commands/prp-context.md` | Reads `context-map.md`, not PRP artifacts. (VERIFY.) |
| `plugins/prp-core/skills/context-add/SKILL.md` | Edits `context-map.md`, not PRP artifacts. |
| `plugins/prp-core/skills/context-read/SKILL.md` | Reads `context-map.md` and external sources. |
| `plugins/prp-core/agents/*.md` | Agents do not have command-style entry points; they are invoked from commands that already run the shim. |

---

## NOT Building (Scope Limits)

- **A new shared skill called `migrate-artifacts`** — PRD's MoSCoW prefers inline simplicity over abstraction. Inline duplication of ~25 lines × 15 files is acceptable; the block never changes.
- **Per-project opt-out flag** — explicitly excluded by PRD ("Won't").
- **Backport to v3.x** — explicitly excluded.
- **Migration of `.claude/rules/`, `.claude/settings.local.json`, or `.claude/commands/`** — PRD scope limit.
- **Renaming artifact extensions** — PRD scope limit.
- **A `/prp-migrate` standalone command** — PRD: "migration is automatic on first command invocation, not a separately-invoked tool."
- **Self-migrating this repo** — that's Phase 4 of PRD001.
- **Bumping `plugin.json` to v4.0.0 or writing CHANGELOG** — Phase 5.
- **Updating root `CLAUDE.md`, `README.md`, `claude_md_files/*.md`** — Phase 3 scope (parallel to this).

---

## Step-by-Step Tasks

Execute in order. Tasks 1–3 establish the canonical shim text and the journey suite. Tasks 4–18 propagate the block to every consumer file and validate.

### Task 0: Verify exclusion list

- **ACTION**: Confirm the "NOT changed" command files genuinely do not read/write `.claude/PRPs/` or `PRPs/`.
- **COMMAND**:
  ```
  Grep pattern="PRPs/" path=plugins/prp-core/commands/prp-commit.md
  Grep pattern="PRPs/" path=plugins/prp-core/commands/prp-pr.md
  Grep pattern="PRPs/" path=plugins/prp-core/commands/prp-review-agents.md
  Grep pattern="PRPs/" path=plugins/prp-core/commands/prp-ralph-cancel.md
  Grep pattern="PRPs/" path=plugins/prp-core/commands/prp-context.md
  Grep pattern="PRPs/" path=plugins/prp-core/commands/version.md
  ```
- **EXPECT**: Zero matches (or matches only in prose comments, not in operational paths). If any file has operational artifact paths, MOVE it from "NOT changed" to "UPDATE" and add a task.
- **GOTCHA**: `prp-pr.md` may reference `PRPs/plans/` in PR body templates — read carefully; templating is not the same as reading/writing artifact files. If it only embeds the path string in a PR description, no shim needed.
- **VALIDATE**: Inventory matches reality.

### Task 1: CREATE canonical shim block reference in `plugins/prp-core/skills/init-project/SKILL.md`

- **ACTION**: Append a new section `## Migration Shim (Reference)` to the end of the SKILL.md.
- **CONTENT**: The exact block below, marked clearly as the canonical source. Include a note that `init-project` itself does NOT call the shim because fresh repos never have `.claude/PRPs/`.
- **CANONICAL_BLOCK** (~25 lines, copy verbatim into every consumer):

  ```markdown
  ## Phase 0: PRE-FLIGHT — Artifact Path Migration

  Before any artifact read or write, probe the working tree:

  | State | Condition | Action |
  |-------|-----------|--------|
  | FRESH | Neither `.claude/PRPs/` nor `PRPs/` exists | Continue silently |
  | V4    | `PRPs/` exists, `.claude/PRPs/` does not | Continue silently |
  | V3    | `.claude/PRPs/` exists, `PRPs/` does not | Auto-migrate, then continue |
  | BOTH  | Both directories exist | STOP with abort message |

  ### V3 → V4 Migration

  1. Detect git status: run `git rev-parse --is-inside-work-tree` (Bash). If exit 0 → git repo; else plain repo.
  2. **Git repo path**: run `git mv .claude/PRPs PRPs`. The rename is staged but not committed; the next command-driven `git commit` will include it.
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
  ```

- **VALIDATE**: Read back the file; confirm the block is present and labeled as canonical.

### Task 2: CREATE `.claude/user-journeys/migrate-v3-to-v4.md`

- **ACTION**: Create the V3 → V4 journey using `plugins/prp-core/templates/user-journey.md` as a template.
- **CONTENT**:
  - **Setup**: scratch git repo with `.claude/PRPs/prds/PRD000-fake.prd.md` and `.claude/PRPs/.counters.json`.
  - **Steps**: invoke `/prp-whats-next` (the lightest-weight artifact-touching command).
  - **Expected**:
    - `PRPs/prds/PRD000-fake.prd.md` exists.
    - `.claude/PRPs/` does not exist.
    - `git status --porcelain` shows the rename in staging.
    - Stdout contains the announcement line `→ Migrated PRP artifacts: .claude/PRPs/ → PRPs/`.
  - **Validation Script** (bash, exit 0 = PASS):
    ```bash
    set -e
    test ! -d .claude/PRPs
    test -d PRPs
    test -f PRPs/prds/PRD000-fake.prd.md
    git status --porcelain | grep -q "^R.*\.claude/PRPs.*->.*PRPs"
    ```
- **VALIDATE**: File exists at correct path; mkdir parent if needed.

### Task 3: CREATE `.claude/user-journeys/fresh-project-no-migration.md`

- **ACTION**: Create the FRESH no-op journey.
- **CONTENT**:
  - **Setup**: empty git repo with only `README.md`.
  - **Steps**: invoke `/prp-whats-next`.
  - **Expected**:
    - Neither `.claude/PRPs/` nor `PRPs/` exists after invocation.
    - Stdout contains no migration announcement.
    - Exit code from the command is 0 (or its normal "no artifacts found" output).
  - **Validation Script**:
    ```bash
    set -e
    test ! -d .claude/PRPs
    test ! -d PRPs
    ```
- **VALIDATE**: File exists.

### Task 4: CREATE `.claude/user-journeys/partial-state-abort.md`

- **ACTION**: Create the BOTH-state abort journey.
- **CONTENT**:
  - **Setup**: git repo with both `.claude/PRPs/` and `PRPs/` directories (each with a sentinel file).
  - **Steps**: invoke any artifact-touching command (e.g., `/prp-whats-next`).
  - **Expected**:
    - Command STOPS without modifying either directory.
    - Stdout contains "STOP: PRP artifact directory is in a partial-migration state."
    - Both directories still exist with original contents.
  - **Validation Script**:
    ```bash
    set -e
    test -d .claude/PRPs
    test -d PRPs
    # Sentinel files unchanged
    test -f .claude/PRPs/.gitkeep
    test -f PRPs/.gitkeep
    ```
- **VALIDATE**: File exists; mkdir `.claude/user-journeys/` if needed.

### Task 5: UPDATE `plugins/prp-core/commands/prp-prd.md`

- **ACTION**: Insert canonical block after `**Input**: $ARGUMENTS\n\n---\n` and before `## Your Role`. Label as `## Phase 0: PRE-FLIGHT — Artifact Path Migration`.
- **MIRROR**: Canonical block from Task 1.
- **GOTCHA**: This file currently has no `## Phase 0:` heading — adding one alters the implicit numbering. Existing "Phase 1: INITIATE" stays numbered as-is; the shim adds a Phase 0 prefix.
- **VALIDATE**: `Grep pattern="Phase 0: PRE-FLIGHT" path=plugins/prp-core/commands/prp-prd.md` returns 1 match.

### Task 6: UPDATE `plugins/prp-core/commands/prp-plan.md`

- **ACTION**: Insert canonical block as a new `## Phase 0: PRE-FLIGHT` between `</context>` (line ~37) and `<process>` (line ~39). Existing "Phase 0: DETECT - Input Type Resolution" inside `<process>` stays — the new shim Phase 0 lives **outside** the `<process>` block to keep the original numbering.
- **MIRROR**: Canonical block from Task 1.
- **GOTCHA**: The existing `<process>` opens with `## Phase 0: DETECT`. We now have two `## Phase 0:` headings (one outside, one inside `<process>`). This is intentional — the outer is the shim, inner is the command's first work phase. Note this in a one-line comment to avoid future confusion.
- **VALIDATE**: `Grep pattern="Phase 0: PRE-FLIGHT" path=plugins/prp-core/commands/prp-plan.md` returns 1 match.

### Task 7: UPDATE `plugins/prp-core/commands/prp-ralph.md`

- **ACTION**: Insert canonical block as `## Phase 0: PRE-FLIGHT` between `## Your Mission` block (ends ~line 18) and `## Phase 1: PARSE` (line ~22). Renumber subsequent headings? **NO** — keep "Phase 1: PARSE" as-is; "Phase 0" is just a label.
- **MIRROR**: Canonical block from Task 1.
- **VALIDATE**: `Grep pattern="Phase 0: PRE-FLIGHT" path=plugins/prp-core/commands/prp-ralph.md` returns 1 match.

### Task 8: UPDATE `plugins/prp-core/commands/prp-implement.md`

- **ACTION**: Existing file already has `## Phase 0: DETECT - Project Environment`. Rename existing `## Phase 0:` to `## Phase 0.5: DETECT - Project Environment` and insert new `## Phase 0: PRE-FLIGHT` before it.
- **MIRROR**: Canonical block.
- **GOTCHA**: Renumbering risk — search for any cross-references to "Phase 0" inside the file. There likely are none (each phase is self-contained), but verify with a grep.
- **VALIDATE**: `Grep pattern="Phase 0: PRE-FLIGHT" path=plugins/prp-core/commands/prp-implement.md` returns 1 match. Existing "Phase 0: DETECT" → renamed to "Phase 0.5: DETECT".

### Task 9: UPDATE `plugins/prp-core/commands/prp-whats-next.md`

- **ACTION**: Insert canonical block at top after frontmatter / first `---`.
- **MIRROR**: Canonical block.
- **VALIDATE**: per-file grep returns 1 match.

### Task 10: UPDATE `plugins/prp-core/commands/prp-vision.md`

- **ACTION**: Insert canonical block at top.
- **VALIDATE**: per-file grep returns 1 match.

### Task 11: UPDATE `plugins/prp-core/commands/prp-issue-investigate.md`

- **ACTION**: Insert canonical block at top.
- **VALIDATE**: per-file grep returns 1 match.

### Task 12: UPDATE `plugins/prp-core/commands/prp-issue-fix.md`

- **ACTION**: Insert canonical block at top.
- **VALIDATE**: per-file grep returns 1 match.

### Task 13: UPDATE `plugins/prp-core/commands/prp-validate-file-naming.md`

- **ACTION**: Insert canonical block at top — before any of the file's grep/find operations on `PRPs/`.
- **VALIDATE**: per-file grep returns 1 match.

### Task 14: UPDATE `plugins/prp-core/commands/prp-codebase-question.md`

- **ACTION**: Insert canonical block at top.
- **VALIDATE**: per-file grep returns 1 match.

### Task 15: UPDATE `plugins/prp-core/commands/prp-research-team.md`

- **ACTION**: Insert canonical block at top.
- **VALIDATE**: per-file grep returns 1 match.

### Task 16: UPDATE `plugins/prp-core/commands/prp-debug.md`

- **ACTION**: Insert canonical block at top.
- **VALIDATE**: per-file grep returns 1 match.

### Task 17: UPDATE `plugins/prp-core/commands/prp-review.md`

- **ACTION**: Insert canonical block at top — before any write to `PRPs/reviews/`.
- **VALIDATE**: per-file grep returns 1 match.

### Task 18: UPDATE `plugins/prp-core/skills/prp-ralph-loop/SKILL.md` and `plugins/prp-core/skills/build-with-agent-team/SKILL.md`

- **ACTION**: Insert canonical block as a new `## Pre-Flight` section near the top of each skill, before any artifact reads/writes.
- **GOTCHA**: `prp-ralph-loop` is invoked iteratively. The shim must be safely idempotent — running it on every iteration is fine because once V4 is reached, every subsequent invocation is a silent no-op.
- **VALIDATE**: per-file grep returns 1 match each.

### Task 19: Final whole-tree validation

- **ACTION**: Confirm shim is present in every UPDATE-listed file and absent from every NOT-changed file.
- **COMMAND**:
  ```
  Grep pattern="Phase 0: PRE-FLIGHT" path=plugins/prp-core output_mode=files_with_matches
  ```
- **EXPECT**: Exactly the 13 commands + 2 skills + init-project SKILL.md = 16 files.
- **VALIDATE**: Match the expected list one-to-one.

### Task 20: Replay the three journeys

- **ACTION**: Run the validation scripts from each journey file against scratch repos. Document any discrepancies.
- **EXPECT**: All three exit 0.
- **VALIDATE**: Manual replay or Bash script that automates all three.

---

## Testing Strategy

### Unit Tests to Write

N/A — markdown-only change.

### E2E Tests to Write

N/A — this repo has no e2e framework. Coverage is via the three Validation Scripts in the journey files.

### Edge Cases Checklist

- [ ] V3 with **uncommitted edits** inside `.claude/PRPs/` — `git mv` stages the rename; uncommitted edits travel with the file. (PRD risk noted.)
- [ ] V3 inside a **non-git directory** — falls back to plain `mv`. Rare but possible (prototyping).
- [ ] V3 with `.claude/PRPs/` **partially populated** (e.g., only `.counters.json`, no PRDs yet) — shim still moves it; subsequent commands still work.
- [ ] V3 where the user is in a **subdirectory** of the repo — `git mv` resolves relative to repo root, so we must `cd` to repo root first or use absolute paths. Detection: `git rev-parse --show-toplevel`.
- [ ] BOTH state with **identical contents** in both dirs — still abort; no merge logic. PRD: "warn and abort, ask user to resolve."
- [ ] Very large `.claude/PRPs/` tree — `git mv` is O(files). No special handling needed.
- [ ] Symlinks under `.claude/PRPs/` — undefined territory; not in scope. Document as known limitation in announcement.
- [ ] Read-only filesystem — shim fails loudly; no recovery attempt.
- [ ] Concurrent invocation (two PRP commands simultaneously) — first wins; second sees V4 and is no-op. Acceptable.
- [ ] Idempotency — running shim twice on V4 must be a no-op.

---

## Validation Commands

### Level 1: STATIC_ANALYSIS — Shim presence

```
Grep pattern="Phase 0: PRE-FLIGHT" path=plugins/prp-core output_mode=files_with_matches
```

**EXPECT**: 16 files (13 commands + 2 skills + init-project SKILL.md reference home).

### Level 2: STATIC_ANALYSIS — Shim text uniformity

```
Grep pattern="→ Migrated PRP artifacts" path=plugins/prp-core output_mode=count
```

**EXPECT**: At least 1 match per file in the 16-file list. Count >= 16.

### Level 3: STATIC_ANALYSIS — No shim leakage to excluded files

```
Grep pattern="Phase 0: PRE-FLIGHT" path=plugins/prp-core/commands/prp-commit.md
Grep pattern="Phase 0: PRE-FLIGHT" path=plugins/prp-core/commands/prp-pr.md
Grep pattern="Phase 0: PRE-FLIGHT" path=plugins/prp-core/commands/prp-ralph-cancel.md
```

**EXPECT**: 0 matches per file.

### Level 4: DATABASE_VALIDATION

N/A.

### Level 5: USER_JOURNEY_VALIDATION

Run "How to Execute" Setup → Run validation script for each of the three journeys → Teardown.

```bash
# For each journey:
bash .claude/user-journeys/migrate-v3-to-v4.md.script    # extract Validation Script
bash .claude/user-journeys/fresh-project-no-migration.md.script
bash .claude/user-journeys/partial-state-abort.md.script
```

**EXPECT**: All three exit 0.

### Level 6: MANUAL_VALIDATION

1. Read three commands at random (`prp-prd`, `prp-ralph`, `prp-implement`) and confirm the inserted shim block reads coherently with surrounding prose.
2. In `prp-implement.md`, confirm the renumber-conflict resolution is clean (`Phase 0: PRE-FLIGHT` → `Phase 0.5: DETECT`).
3. In `prp-plan.md`, confirm the dual `## Phase 0:` (one outside `<process>`, one inside) reads sensibly with the comment annotation.
4. Read `plugins/prp-core/skills/init-project/SKILL.md` final section and confirm the canonical block is labeled "canonical" so future maintainers know to treat that copy as source-of-truth.

---

## Acceptance Criteria

- [ ] All 13 artifact-touching commands have the shim as `## Phase 0: PRE-FLIGHT`
- [ ] Both artifact-touching skills (`prp-ralph-loop`, `build-with-agent-team`) have the shim
- [ ] `init-project/SKILL.md` hosts the canonical block, labeled clearly
- [ ] Shim block text is identical across all 15 consumer files (verified by grep on a unique substring)
- [ ] Three journey files exist with passing validation scripts
- [ ] Excluded commands (`prp-commit`, `prp-pr`, `prp-ralph-cancel`, `version`, `prp-context`, `prp-review-agents`) do NOT have the shim
- [ ] V3 → V4 auto-migration journey passes against a scratch repo
- [ ] FRESH no-op journey passes
- [ ] BOTH-state abort journey passes
- [ ] Shim is idempotent: running any PRP command twice on the same tree yields a stable V4 state
- [ ] No regressions in Phase 1 work (no `.claude/PRPs/` re-introduced)

---

## Completion Checklist

- [ ] Task 0 exclusion verification recorded
- [ ] Task 1 canonical block written to `init-project/SKILL.md`
- [ ] Tasks 2-4 journey files created and reviewed
- [ ] Tasks 5-18 each command/skill updated and per-file grep validated
- [ ] Task 19 whole-tree presence/absence grep matches expected 16-file list
- [ ] Task 20 all three journey validation scripts pass
- [ ] Level 1-3 grep validations pass
- [ ] Level 6 manual review complete
- [ ] PRD001 phase 2 status updated from `pending` → `in-progress` → `complete`
- [ ] Plan archived to `PRPs/plans/completed/` (or `.claude/PRPs/plans/completed/` if Phase 4 hasn't run yet)
- [ ] Git commit per `main-only` strategy

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Shim text drift between consumer files (someone edits one copy and not others) | MED | MED | Task 19 final grep verifies a unique substring count == file count. Canonical reference in `init-project/SKILL.md` documents the source of truth. |
| Renumbering in `prp-implement.md` (`Phase 0: DETECT` → `Phase 0.5`) breaks an internal reference | LOW | LOW | Task 8 GOTCHA: grep for "Phase 0" cross-references first. |
| User in a subdirectory; `git mv .claude/PRPs PRPs` resolves relative to CWD, not repo root | MED | MED | Shim resolves repo root via `git rev-parse --show-toplevel` and runs `git mv` with absolute paths. Documented in canonical block "Detection Implementation Notes". |
| Non-git project loses history because `mv` doesn't preserve git rename detection | N/A | LOW | Non-git projects have no history to preserve. Plain `mv` is correct. |
| User has `.claude/PRPs/` symlink, not directory | LOW | MED | Out of scope. Document as known limitation. Shim's `test -d` follows symlinks, which means it triggers; `git mv` may behave oddly. Accept and note. |
| `BOTH` state abort message is mistakenly triggered when `PRPs/` exists as an empty placeholder (e.g., user pre-created the dir) | MED | LOW | Abort is correct behavior — user must resolve. Empty placeholder vs. populated dir is indistinguishable from outside, so we can't auto-resolve safely. |
| Shim runs in a Ralph loop iteration that started under V3 and the migration completes mid-loop | LOW | LOW | Idempotent: iteration N migrates, iteration N+1 sees V4 and no-ops. Loop's plan path was set as `PRPs/...` in Phase 1 anyway, so post-migration the path is reachable. |
| Shim's announcement noise breaks a user's scripted output parser | LOW | LOW | Single-line, prefix `→`, easy to grep around. Document in CHANGELOG (Phase 5). |
| `git mv` fails because `.claude/PRPs/` has uncommitted deletes/renames inside | LOW | MED | `git mv` reports a clean error; shim should re-print git's error and STOP. User resolves. (PRD: "warn and abort, ask user to resolve" — same posture.) |

---

## Notes

- **Why inline instead of a shared skill?** PRP commands are markdown — there's no runtime to call into. "Calling a skill" from a command means embedding the skill's prose anyway. Inline removes a layer of indirection without losing maintainability, and Task 19's grep makes drift detection trivial. The PRD explicitly weighs this: "best implementation: a small helper documented in a single place ... Alternative: inline ... simpler, no new skill abstraction." We chose inline.
- **Why `init-project/SKILL.md` as the canonical home?** It's the natural place a maintainer looks first when onboarding to the plugin's bootstrap behavior. Putting the reference text adjacent to "how new projects start" colocates it with the lifecycle. An alternative (`docs/migration-shim.md`) would also work but adds a new file for a permanent transitional concern.
- **Why `→ Migrated ...` instead of richer output?** PRP commands are noisy — adding multi-line announcements during a `git mv` would clutter routine workflows. One line is enough; CHANGELOG explains the why.
- **Why not handle BOTH automatically?** Two valid resolutions exist (keep `.claude/PRPs/`, keep `PRPs/`, or merge). PRD: "warn and abort, ask user to resolve." Auto-resolution risks silent data loss.
- **Confidence**: HIGH for one-pass success. The block is small, the consumer list is fixed (Phase 1 already enumerated it), the validation is grep-based, and the three journeys exercise all three states. Risk is concentrated in the `prp-implement.md` renumber and the `prp-plan.md` dual-Phase-0; both are flagged in task GOTCHAs.
