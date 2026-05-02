# Feature: Phase 3 — Docs + Scaffolding Update for PRPs/ Relocation

## Summary

Phase 3 of PRD001 (`.claude/PRPs/` → `PRPs/` relocation). Phases 1 (plugin source) and 2 (auto-migration shim) shipped. This phase closes the docs/scaffolding gap so user-facing documentation, the workspace-level CLAUDE.md, and the `init-project` flow all reflect the V4 layout. The exploration found most repo-level docs are already V4-correct; the actual remaining work is small and surgical.

## User Story

As a developer reading TrueNorthTeams docs or scaffolding a new project with `/prp-core:init-project`,
I want every reference to PRP artifact paths to point to `PRPs/`,
So that I never see contradictory guidance between docs and the running plugin (which already writes to `PRPs/`).

## Problem Statement

The workspace-level `c:\Source\CLAUDE.md` (auto-loaded into every Claude session under `C:\Source\`) still describes artifact storage at `.claude/PRPs/` across 10 lines. The repo's own `README.md` project-structure diagram shows a pre-plugin layout (`.claude/commands/prp-core/`). `README-for-DUMMIES.md` mentions "Plane tracking" in the completion protocol — an inaccuracy unrelated to this PRD but caught during inventory; flagged for the user, not auto-fixed in this phase. Without these fixes, new readers see V3 guidance while the plugin behaves V4, and `init-project`-scaffolded projects inherit conflicting context.

## Solution Statement

Edit three files. No code changes, no template additions. Verify the rest of the candidate set (`claude_md_files/*.md`, `plugins/prp-core/templates/claude-md/*.md`, `init-project/SKILL.md` scaffolding actions) needs no changes — confirmed during exploration. Run final grep gate to prove zero non-shim `.claude/PRPs` references survive.

## Metadata

| Field            | Value                                              |
| ---------------- | -------------------------------------------------- |
| Type             | REFACTOR (docs)                                    |
| Complexity       | LOW                                                |
| Systems Affected | docs, workspace config                             |
| Dependencies     | none (parallel with Phases 1, 2 — both complete)   |
| Estimated Tasks  | 4                                                  |
| Source PRD       | `.claude/PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` |
| PRD Phase        | #3 — Docs + scaffolding update                     |

---

## UX Design

### Before State

```
╔══════════════════════════════════════════════════════════════════╗
║  Developer opens any repo under C:\Source\                       ║
║  Workspace CLAUDE.md auto-loads into Claude session              ║
║  Reads: "All PRP artifacts under .claude/PRPs/"                  ║
║       ▼                                                          ║
║  Runs /prp-core:prp-prd → plugin writes to PRPs/ (V4)            ║
║       ▼                                                          ║
║  CONFUSION: docs say one thing, behavior is another              ║
╚══════════════════════════════════════════════════════════════════╝
```

### After State

```
╔══════════════════════════════════════════════════════════════════╗
║  Workspace CLAUDE.md describes PRPs/ at repo root                ║
║       ▼                                                          ║
║  Plugin writes to PRPs/                                          ║
║       ▼                                                          ║
║  Docs and behavior agree end-to-end                              ║
╚══════════════════════════════════════════════════════════════════╝
```

### Interaction Changes

| Location                              | Before                                    | After                              | User Impact                       |
| ------------------------------------- | ----------------------------------------- | ---------------------------------- | --------------------------------- |
| `c:\Source\CLAUDE.md` §PRP Artifacts  | `.claude/PRPs/...` (10 occurrences)       | `PRPs/...`                         | Workspace guidance matches V4 |
| `README.md` project-structure tree    | `.claude/commands/prp-core/`              | `plugins/prp-core/`                | Reflects plugin install model |
| `README-for-DUMMIES.md` L122          | "update Plane tracking"                   | (decision pending)                 | Accuracy — flagged for user   |

---

## User Journeys

No user-facing functional flows change. This is a docs-only update. Skipping `.claude/user-journeys/` files.

---

## How to Execute

This is a docs-only phase. No services, no seed data, no teardown. Validation is `grep` and visual review.

```bash
# Sanity check before starting
grep -rn '.claude/PRPs' c:/Source/CLAUDE.md README.md README-for-DUMMIES.md plugins/prp-core/README.md
grep -rn '.claude/commands/prp-core' README.md README-for-DUMMIES.md
```

---

## Mandatory Reading

| Priority | File                              | Lines  | Why Read This                                            |
| -------- | --------------------------------- | ------ | -------------------------------------------------------- |
| P0       | `CLAUDE.md` (repo root)           | 60-104 | Canonical V4 wording for the artifacts-location section — mirror exactly |
| P0       | `c:\Source\CLAUDE.md`             | 55-84  | Edit target. Stale block at L60-74; IJFW layer ref at L80 |
| P1       | `README.md`                       | 320-336 | Edit target. Project-structure tree                     |
| P1       | `README-for-DUMMIES.md`           | 118-128 | Decision target. "Plane tracking" line                  |
| P2       | `plugins/prp-core/skills/init-project/SKILL.md` | 213-510 | Verify scaffolding actions — no changes expected |

**External Documentation:** N/A — internal docs only.

**Context Sources Loaded:** None (no `context-map.md` matches for "docs path migration").

---

## Patterns to Mirror

**ARTIFACTS-LOCATION SECTION (canonical from repo root CLAUDE.md):**

```markdown
# SOURCE: CLAUDE.md:25-29 + ## Artifact Numbering System block
# COPY THIS WORDING when rewriting c:\Source\CLAUDE.md §PRP Artifacts Location

The `.claude/` directory in this repo is reserved for:
- `.claude/settings.local.json` — Tool permissions

PRP artifacts (plans, PRDs, visions, reports, investigations, `.counters.json`) live at the top-level `PRPs/` directory, not under `.claude/`.
```

```markdown
# SOURCE: README.md:265-280 (project tree showing PRPs/ structure)
# COPY THIS PATTERN for the workspace CLAUDE.md bullet list under "PRP Artifacts Location"

PRPs/
  visions/      — Vision documents
  prds/         — PRD documents
  plans/        — Implementation plans
  investigations/ — Issue investigations
  research/     — Research reports
  .counters.json — Global numbering counters
```

**EM-DASH BULLET STYLE (existing convention in c:\Source\CLAUDE.md):**

```markdown
# Match this style verbatim:
- `PRPs/visions/` — Vision documents (active); `completed/` subfolder for archived visions
```

---

## Files to Change

| File                                              | Action          | Justification                                       |
| ------------------------------------------------- | --------------- | --------------------------------------------------- |
| `c:\Source\CLAUDE.md`                             | UPDATE          | Replace 10 stale `.claude/PRPs` refs with `PRPs/`   |
| `README.md`                                       | UPDATE          | Fix project-structure tree (pre-plugin layout)      |
| `README-for-DUMMIES.md`                           | UPDATE          | Decide on "Plane tracking" line — confirm with user |
| `claude_md_files/*.md` (8 files)                  | NO CHANGE       | Verified zero artifact-path refs                    |
| `plugins/prp-core/templates/claude-md/*.md`       | NO CHANGE       | Verified zero artifact-path refs                    |
| `plugins/prp-core/skills/init-project/SKILL.md`   | NO CHANGE       | FRESH-state behavior is correct; shim ref text intentional |

---

## NOT Building (Scope Limits)

- **Editing migration shim text in commands/skills** — those `.claude/PRPs` references are intentional (they describe the V3 state being detected). Out of scope.
- **Editing `old-prp-commands/`** — historical archive, predates V4. Per PRD line 113, archived feature docs stay unchanged.
- **Self-migration of this repo's artifacts** — that's Phase 4. This phase only updates docs.
- **Plugin version bump** — that's Phase 5.
- **Deciding the "Plane tracking" question** — the inaccuracy is unrelated to PRD001. Surface to user; do not silently rewrite.

---

## Step-by-Step Tasks

### Task 1: UPDATE `c:\Source\CLAUDE.md` — §PRP Artifacts Location

- **ACTION**: Replace lines 60-74 (the `### PRP Artifacts Location` section) and update line 80 (IJFW Layer first bullet).
- **IMPLEMENT**: Rewrite the section to describe `PRPs/` at repo root. Mirror the bullet style from the existing block (em-dash separators). Update the L80 IJFW bullet from "warrants a `.claude/PRPs/` artifact" → "warrants a `PRPs/` artifact".
- **REPLACEMENT TEXT** for L62-74:
  ```markdown
  All PRP-generated artifacts are stored under `PRPs/` at the repo root:
  - `PRPs/visions/` — Vision documents (active); `completed/` subfolder for archived visions
  - `PRPs/prds/` — Product requirement documents
  - `PRPs/plans/` — Implementation plans
  - `PRPs/investigations/` — Issue investigation reports
  - `PRPs/research/` — Research reports the user has requested
  - `PRPs/.counters.json` — Global artifact numbering counters

  Artifacts use hierarchical numbering: `V001`, `V001-PRD001`, `V001-PRD001-P001`, `PRD002`, `PRD002-P001`. Counters are global per project and never reset.

  These directories are created automatically by the commands. Do not pre-create them.

  **Important:** `PRPs/` and all its subfolders must be committed to version control. Do NOT add `PRPs/` to `.gitignore` — these artifacts are part of the project history.

  **Note (v4.0+):** Artifacts moved from `.claude/PRPs/` to `PRPs/` in v4.0. The plugin auto-migrates v3 projects on first command invocation; see plugin release notes.
  ```
- **GOTCHA**: This file lives outside the repo (`c:\Source\CLAUDE.md`), not under `c:\Source\TrueNorthTeams\PRP-agentic-sdlc\`. The `prp-commit` step will not stage it. Call out to user.
- **VALIDATE**: `grep -n '.claude/PRPs' c:/Source/CLAUDE.md` returns no hits.

### Task 2: UPDATE `README.md` — fix project-structure tree

- **ACTION**: Replace lines 322-335. The current tree shows `.claude/commands/prp-core/` (pre-plugin layout) and an outdated comment for `agents/`.
- **IMPLEMENT**: Replace the tree with the current plugin-install model:
  ```
  your-project/
  ├── .claude/
  │   ├── settings.local.json    # Permissions
  │   └── rules/                 # Auto-loaded rules (e.g., git-strategy.md)
  ├── PRPs/                      # All PRP artifacts
  │   ├── .counters.json         # Artifact numbering counters
  │   ├── visions/               # Vision documents
  │   ├── prds/                  # PRD documents
  │   ├── plans/                 # Implementation plans
  │   ├── investigations/        # Issue investigations
  │   └── research/              # Research reports
  ├── CLAUDE.md                  # Project-specific guidelines
  └── src/                       # Your source code
  ```
- **GOTCHA**: Don't list `templates/` and `ai_docs/` here — those live in the *plugin* (`plugins/prp-core/`), not in consumer projects. Lines 357-365 (Resources section) describe them but should be qualified as plugin-shipped, not consumer-project-tree members.
- **SUB-EDIT**: At lines 357 and 363, change `### Templates (PRPs/templates/)` → `### Templates (shipped with plugin)` and `### AI Documentation (PRPs/ai_docs/)` → `### AI Documentation (shipped with plugin)`. The plugin source still organizes these under its own `PRPs/` subdir during development of the plugin itself, but consumer projects don't see them as tree members.
- **VALIDATE**: `grep -n '.claude/commands/prp-core' README.md` returns no hits.

### Task 3: REVIEW `README-for-DUMMIES.md:122` — "Plane tracking" accuracy

- **ACTION**: Surface the inaccuracy to the user, do not silently edit.
- **CONTEXT**: Line 122 reads: *"All three share the same completion protocol: update PRD status, update Plane tracking, archive the plan, and commit per the PRD's git strategy."* The repo's own CLAUDE.md describes the completion protocol as: *(1) Update Source PRD, (2) Archive plan to `completed/`, (3) Git operations*. There is no Plane tracking step in the canonical protocol.
- **DECISION POINT**: Either (a) remove "update Plane tracking" from the line, or (b) confirm Plane integration exists somewhere and point to it. Ask user during execution.
- **GOTCHA**: Plane tracking is mentioned by name only in `README-for-DUMMIES.md:122`; no plugin command implements it. Most likely a stale reference.
- **VALIDATE**: After user decision, line either omits "Plane tracking" or links to actual Plane integration logic. Either way, doc reflects truth.

### Task 4: CONFIRM no-change set + final grep gate

- **ACTION**: Run the full grep gate from PRD success metric.
- **VERIFY** these zero-change files stay untouched (already verified in exploration):
  - `claude_md_files/CLAUDE-{ASTRO,JAVA-GRADLE,JAVA-MAVEN,NEXTJS-15,NODE,PYTHON-BASIC,REACT,RUST}.md`
  - `plugins/prp-core/templates/claude-md/*.md`
  - `plugins/prp-core/skills/init-project/SKILL.md` (scaffolding actions; shim reference text is correct as-is)
  - `plugins/prp-core/README.md`
  - Repo root `CLAUDE.md`
- **VALIDATE**:
  ```bash
  # Should match only migration shim blocks and the v4 release-note line in workspace CLAUDE.md
  grep -rn '.claude/PRPs' \
    --exclude-dir=.git --exclude-dir=node_modules \
    --exclude-dir=old-prp-commands \
    c:/Source/TrueNorthTeams/PRP-agentic-sdlc/ c:/Source/CLAUDE.md \
    | grep -v 'plugins/prp-core/commands' \
    | grep -v 'plugins/prp-core/skills/init-project/SKILL.md' \
    | grep -v 'plugins/prp-core/skills/build-with-agent-team/SKILL.md' \
    | grep -v 'plugins/prp-core/skills/prp-ralph-loop/SKILL.md' \
    | grep -v '.claude/PRPs/' # excludes paths inside the artifact tree itself
  ```
  EXPECTED: Either zero hits, or only the v4 release-note line in `c:\Source\CLAUDE.md` that intentionally documents the migration.

---

## Testing Strategy

### Unit Tests
N/A — markdown docs.

### Validation
- Pre-edit and post-edit greps (Task 1, 2, 4)
- Visual diff review of each edited file
- Spot-check by re-reading workspace CLAUDE.md from a fresh Claude session if user wants behavioral confirmation

### Edge Cases Checklist
- [ ] Workspace CLAUDE.md change does NOT introduce trailing whitespace or alter unrelated sections
- [ ] README.md tree change preserves heading levels and code-block fencing
- [ ] No accidental edits to migration shim blocks in `plugins/prp-core/commands/*.md`
- [ ] `.counters.json` increment landed (`{"vision":0,"prd":1,"plan":3}`)

---

## Validation Commands

### Level 1: STATIC_ANALYSIS
N/A — markdown docs.

### Level 2: GREP GATE (the project's only programmable validation)
```bash
# Should return zero non-shim hits
grep -rn '.claude/PRPs' README.md README-for-DUMMIES.md CLAUDE.md plugins/prp-core/README.md claude_md_files/
grep -n '.claude/PRPs' c:/Source/CLAUDE.md  # should match only the v4 release-note line, if present
grep -rn '.claude/commands/prp-core' README.md README-for-DUMMIES.md
```
EXPECT: Repo-side greps return 0; workspace CLAUDE.md returns at most the intentional release-note line.

### Level 3: VISUAL REVIEW
- Open each edited file, compare to mirrored pattern from repo root CLAUDE.md
- Confirm em-dash bullets, code-fence styles, heading hierarchy match existing conventions

### Level 4: BEHAVIORAL SANITY
- Open a fresh Claude session in any `C:\Source\<repo>\` and confirm workspace CLAUDE.md loads with V4 wording
- (Cannot be automated — human-in-the-loop)

---

## Acceptance Criteria

- [ ] `c:\Source\CLAUDE.md` §PRP Artifacts Location describes `PRPs/` and includes the v4 migration note
- [ ] `c:\Source\CLAUDE.md:80` IJFW bullet says "warrants a `PRPs/` artifact"
- [ ] `README.md` project-structure tree reflects plugin layout (`plugins/prp-core/`, no `.claude/commands/prp-core/`)
- [ ] `README-for-DUMMIES.md:122` accuracy decision made (with user input) and applied
- [ ] Final grep gate passes (zero non-shim `.claude/PRPs` hits in repo root + workspace CLAUDE.md, except the intentional release-note line)
- [ ] PRD001 Phase 3 status set to `complete` and plan archived to `completed/`

---

## Completion Checklist

- [ ] All 4 tasks executed
- [ ] Grep gate passes (Level 2)
- [ ] Visual review complete (Level 3)
- [ ] PRD updated: Phase 3 status `complete`, plan path linked
- [ ] Plan archived to `.claude/PRPs/plans/completed/PRD001-P003-docs-and-scaffolding-update.plan.md`
- [ ] Git commit per `main-only` strategy
- [ ] User informed that `c:\Source\CLAUDE.md` lives outside the repo and was edited there separately (will not appear in this repo's commit)

---

## Risks and Mitigations

| Risk                                                              | Likelihood | Impact | Mitigation                                                   |
| ----------------------------------------------------------------- | ---------- | ------ | ------------------------------------------------------------ |
| Editing workspace CLAUDE.md outside the repo confuses git scope   | MED        | LOW    | Call out explicitly in commit message + completion report; do not stage |
| Plane-tracking decision drifts to a separate PR/PRD               | LOW        | LOW    | Acceptable — flag and proceed even if user defers            |
| README tree change breaks user mental model from prior versions   | LOW        | LOW    | Tree matches actual on-disk reality; old model was already wrong |
| Hidden `.claude/PRPs` reference in untouched file                 | LOW        | MED    | Final grep gate (Task 4) catches anything missed             |

---

## Notes

- **Workspace CLAUDE.md scope question**: The PRD scope (line 177) says "Root `CLAUDE.md`" which technically refers to this repo's root CLAUDE.md (already V4-correct). However, the workspace-level `c:\Source\CLAUDE.md` has a much bigger user impact (auto-loaded into every session). Treating it as in-scope for Phase 3 is the right call but should be acknowledged as a slight scope-stretch. Document in completion report.
- **Plugin templates have no path text**: This is a feature, not a bug — those templates are framework-specific guidance (TypeScript/Java/Rust conventions) and were never the right place for cross-project artifact-path docs. The artifact-path docs live in workspace CLAUDE.md and the repo's own CLAUDE.md, which propagate correctly.
- **`init-project` shim non-invocation**: Confirmed correct. Fresh repos start in FRESH state; the shim's no-op path handles it. No changes needed.
- **Counter increment**: Performed at plan-creation time. `.counters.json` now `{"vision":0,"prd":1,"plan":3}`.
- **Confidence Score**: 9/10. The change set is tiny, the canonical patterns are already established in the repo's own CLAUDE.md, and the grep gate provides deterministic verification.
