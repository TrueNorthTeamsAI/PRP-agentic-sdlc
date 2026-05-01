# Relocate PRP Artifacts from `.claude/PRPs/` to `PRPs/`

## Problem Statement

PRP artifacts (plans, PRDs, visions, reports, investigations) currently live under `.claude/PRPs/`. Claude Code has a known bug where edits to anything under `.claude/` trigger permission prompts even when bypass-permissions mode is enabled. Since PRP artifacts are read and written constantly during day-to-day work, this is a daily-papercut friction point that interrupts every PRD authoring, plan execution, and Ralph loop.

## Evidence

- User has been hitting permission prompts on `.claude/PRPs/` writes throughout this session and prior sessions, despite bypass-permissions being on.
- Permission prompts appeared even on routine operations (writing the counters file, moving features to `completed/`).
- The bug is consistent across all PRP commands that touch the artifact directory (`prp-prd`, `prp-plan`, `prp-implement`, `prp-ralph`).
- 208 references to `.claude/PRPs/` across 26 files in the plugin source — every command-driven write hits the bug.

## Proposed Solution

Move PRP artifacts from `.claude/PRPs/` to `PRPs/` at the repository root. The `.claude/` directory keeps only what genuinely belongs to Claude Code's tooling layer (permissions, rules, settings). PRP artifacts are first-class project content — specs, plans, decisions — and belong in a top-level visible directory alongside `docs/` or `tests/`. This sidesteps the permission bug entirely and improves discoverability for new contributors.

The plugin ships a one-time migration shim: on first command invocation in a project where `.claude/PRPs/` exists but `PRPs/` does not, the command performs `git mv .claude/PRPs PRPs` automatically and announces the move. Existing consumers don't have to do manual migration.

This is a breaking change → ship as **v4.0.0**.

## Key Hypothesis

We believe relocating PRP artifacts to `PRPs/` at the repo root will eliminate the permission-prompt friction for users running prp-core in bypass-permissions mode.
We'll know we're right when (a) zero permission prompts occur during normal PRD/plan/implement workflows, and (b) consumer projects auto-migrate without manual intervention.

## What We're NOT Building

- **Moving `.claude/settings.local.json`, `.claude/rules/`, or `.claude/commands/`** — these are Claude Code's own tooling files; they belong in `.claude/`. The permission bug there is much less painful because those files are edited rarely.
- **Supporting both old and new paths simultaneously in plugin commands** — every command would need conditional logic. Single-path with auto-migration is simpler.
- **Backporting the new path to v3.x** — v3.x stays on `.claude/PRPs/`; only v4.0+ uses `PRPs/`.
- **A separate "migration command"** — migration is automatic on first command invocation, not a separately-invoked tool.
- **Renaming the artifacts themselves** — `.prd.md`, `.plan.md`, `.vision.md` extensions stay the same.

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|--------------|
| Permission prompts during PRP workflows | 0 | Run `/prp-prd`, `/prp-plan`, `/prp-implement` end-to-end on a fresh project with bypass-permissions on; observe |
| Auto-migration success rate | 100% on existing v3.x consumer projects | Test on at least 2 consumer projects: 2nd-brain-saas-platform, 2nd-brain-hieraphical-rag-mcp |
| Plugin source references to `.claude/PRPs/` | 0 (only mentioned in migration shim and CHANGELOG) | `grep -r '.claude/PRPs' plugins/` |

## Open Questions

- [ ] Does the auto-migration shim need to handle the case where the consumer has *both* `.claude/PRPs/` and `PRPs/` (e.g., partial manual migration)? Decision: warn and abort migration, ask user to resolve.
- [ ] Should `init-project` scaffolding in this repo also update its templates (e.g., `claude_md_files/*.md`) to reference `PRPs/`? Likely yes — confirm during implementation.
- [ ] Is `.gitignore` affected? `.claude/PRPs/` is committed today, `PRPs/` will be too — same convention, no `.gitignore` changes expected.
- [ ] Do any consumer projects have CI or automation that hardcodes `.claude/PRPs/`? Unknown — call out in release notes so consumers can audit.

---

## Users & Context

**Primary User**
- **Who**: Developers using prp-core to drive feature work — PRD authors, plan executors, anyone running `/prp-implement` or `/prp-ralph` loops.
- **Current behavior**: They run PRP commands, hit permission prompts mid-flow, click through, lose focus, sometimes miss writes when they reflexively deny.
- **Trigger**: Every PRP command that writes to `.claude/PRPs/` (which is most of them).
- **Success state**: Commands run end-to-end without permission interruptions.

**Job to Be Done**
When I'm running a PRP workflow with bypass-permissions enabled, I want artifact writes to proceed without prompts, so I can stay in flow and trust the loop.

**Non-Users**
Anyone not using prp-core — out of scope. Anyone editing `.claude/settings.local.json` or `.claude/rules/` — those files stay where they are; this PRD doesn't help them.

---

## Solution Detail

### Core Capabilities (MoSCoW)

| Priority | Capability | Rationale |
|----------|------------|-----------|
| Must | All plugin commands write to `PRPs/` instead of `.claude/PRPs/` | Core of the change |
| Must | Auto-migration shim runs on first command invocation in v3 → v4 upgrade | Without this, every consumer hits broken paths |
| Must | `.claude/PRPs/.counters.json` moves to `PRPs/.counters.json` | Counters are part of the artifact tree |
| Must | All docs (CLAUDE.md, READMEs, scaffold templates) updated | Avoid drift between docs and behavior |
| Should | Migration shim writes a one-line announcement so user sees what happened | Trust through transparency |
| Should | Release notes call out the breaking change with explicit migration steps | Consumers with custom tooling need to audit |
| Could | Migration shim verifies git state is clean before `git mv` (warn if not) | Avoids losing in-progress edits |
| Won't | Per-project opt-out flag to keep `.claude/PRPs/` | Adds permanent dual-path complexity for one bug-workaround edge case |
| Won't | Backport to v3.x | Pure breaking change; staying clean |

### MVP Scope

The MVP is the full move plus auto-migration. There's no smaller version that delivers value — a half-moved system is worse than either endpoint. The "minimum" is:

1. Plugin commands all reference `PRPs/`
2. Migration shim works
3. Docs are updated

### User Flow

**Existing v3.x consumer upgrades to v4.0:**
1. User runs `claude plugin update prp-core`.
2. User runs any PRP command (e.g., `/prp-plan path/to/prd.md`).
3. Migration shim detects `.claude/PRPs/` exists and `PRPs/` does not → runs `git mv .claude/PRPs PRPs`, prints `→ Migrated PRP artifacts to PRPs/ (committed in next operation)`.
4. Command proceeds normally with the new path.

**New project initialized with v4.0:**
1. User runs `/prp-core:init-project my-repo`.
2. Scaffolding creates `PRPs/` directly — no `.claude/PRPs/` ever exists.

---

## Technical Approach

**Feasibility**: HIGH

**Architecture Notes**

- The change is mechanical: a global path replacement across plugin command files, scripts, templates, and docs.
- 208 references across 26 files: 19 plugin command/skill/template files, 2 scripts, 4 docs (root CLAUDE.md, root README, README-for-DUMMIES, plugin README), and 2 archived feature docs (which can stay unchanged — they're historical records).
- Migration shim is shared logic. Best implementation: a small helper documented in a single place (e.g., `plugins/prp-core/skills/migrate-artifacts/SKILL.md`) that every command's "first step" calls. Alternative: inline the check at the top of each command as a 5-line snippet — simpler, no new skill abstraction.
- Counters file moves with the directory automatically (it's inside `.claude/PRPs/`).

**Git Strategy**: `main-only`

**Technical Risks**

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Consumer has both `.claude/PRPs/` and `PRPs/` (partial state) | L | Migration shim aborts with clear error; user resolves manually |
| Consumer has uncommitted work in `.claude/PRPs/` during migration | M | `git mv` preserves history and stages the rename; uncommitted edits inside renamed files travel with the move |
| In-flight feature branches reference old path | M | Release notes call out: merge or stash open PRP work before updating; migration only runs on the branch where the command is invoked |
| Auto-migration runs in a non-git repo | L | Shim falls back to plain `mv` and warns user; uncommon edge case |
| External tooling (CI, scripts) hardcodes `.claude/PRPs/` | L | Release notes flag this; consumers audit |
| Some commands miss the path update due to grep miss | M | Add a CI check or pre-release grep that fails the build if `.claude/PRPs/` appears anywhere outside the migration shim and CHANGELOG |

---

## Testing Strategy

### Unit Testing
- **Framework**: N/A — this repo has no traditional unit test suite; the plugin is markdown commands, not code.
- **Run**: N/A

### E2E Testing
- **Framework**: Manual + scripted validation
- **Approach**: Run the full PRP workflow (`/prp-prd` → `/prp-plan` → `/prp-implement`) on a fresh test project after upgrade and verify artifacts land in `PRPs/`.

### Integration Testing
- **Approach**: Test the migration shim against three real consumer states:
  1. **Fresh project** (no `.claude/PRPs/`, no `PRPs/`) — should create `PRPs/`.
  2. **Pre-existing v3 project** (has `.claude/PRPs/` with artifacts) — should auto-migrate.
  3. **Already-migrated project** (has `PRPs/`, no `.claude/PRPs/`) — should be a no-op.
- **Run**: Manual; document each in release-test checklist.
- **Repos to test against**: `2nd-brain-saas-platform`, `2nd-brain-hieraphical-rag-mcp`, plus a fresh empty repo.

---

## Implementation Phases

| # | Phase | Description | Status | Parallel | Depends | PRP Plan |
|---|-------|-------------|--------|----------|---------|----------|
| 1 | Plugin path migration | Replace `.claude/PRPs/` with `PRPs/` across all plugin command, skill, template, and script files | pending | - | - | - |
| 2 | Migration shim | Build the auto-migration logic that detects v3 layout and runs `git mv` on first command invocation | pending | with 1 | - | - |
| 3 | Docs + scaffolding update | Update root CLAUDE.md, READMEs, `init-project` scaffolding, and `claude_md_files/` templates | pending | with 1 | - | - |
| 4 | Self-migration of this repo | Run the migration on this repo (`PRP-agentic-sdlc` itself) | pending | - | 1, 2, 3 | - |
| 5 | Release v4.0.0 | Bump to v4.0.0 with full changelog, migration notes, and tag | pending | - | 4 | - |
| 6 | Consumer validation | Test migration on `2nd-brain-saas-platform` and `2nd-brain-hieraphical-rag-mcp` | pending | - | 5 | - |

### Phase Details

**Phase 1: Plugin path migration**
- **Goal**: Every plugin command, skill, template, and script writes to and reads from `PRPs/`.
- **Scope**: All 19 plugin files plus 2 scripts (`invoke_command.py`, `prp_workflow.py`). Mechanical search-replace `.claude/PRPs/` → `PRPs/` with manual review of each match.
- **Success signal**: `grep -r '.claude/PRPs' plugins/` returns nothing.

**Phase 2: Migration shim**
- **Goal**: First command invocation on a v3 project auto-migrates to v4 layout.
- **Scope**: Decide between shared skill vs. inline snippet. Implement, document, and add the call at the top of every command that touches PRP artifacts.
- **Success signal**: Running any PRP command on a fresh clone of a v3 consumer project moves `.claude/PRPs/` → `PRPs/` automatically and the command proceeds.

**Phase 3: Docs + scaffolding update**
- **Goal**: All user-facing docs and new-project scaffolding reflect `PRPs/`.
- **Scope**: Root `CLAUDE.md`, root `README.md`, `README-for-DUMMIES.md`, `plugins/prp-core/README.md`, `claude_md_files/*.md` (if they reference the path), and `init-project` skill.
- **Success signal**: A new project initialized with `init-project` has `PRPs/` (not `.claude/PRPs/`) from day one.

**Phase 4: Self-migration of this repo**
- **Goal**: This repository (PRP-agentic-sdlc) runs on the new layout.
- **Scope**: Run `git mv .claude/PRPs PRPs`, verify all internal references resolve, commit.
- **Success signal**: This repo's own PRP workflow continues to function on the new path.

**Phase 5: Release v4.0.0**
- **Goal**: Tagged GitHub release with breaking-change notes.
- **Scope**: Bump `plugin.json` to `4.0.0`, write changelog, run `/release` command, create GitHub release.
- **Success signal**: `claude plugin update prp-core` on consumer projects pulls v4.0.0.

**Phase 6: Consumer validation**
- **Goal**: Verify migration works on real-world consumer projects.
- **Scope**: Run the upgrade + first PRP command on at least two consumer projects, document the experience.
- **Success signal**: Both consumers migrate cleanly with zero manual intervention.

### Parallelism Notes

Phases 1, 2, and 3 can run in parallel — they touch different files and have no shared state. Phase 4 (self-migration) requires all three to be merged. Phases 5 and 6 are sequential and gate on phase 4.

---

## Decisions Log

| Decision | Choice | Alternatives | Rationale |
|----------|--------|--------------|-----------|
| New artifact location | `PRPs/` at repo root | `.PRPs/`, `prps/`, `docs/PRPs/` | PRPs are first-class project content (specs, plans, decisions), not hidden tooling. Dot-directories signal config (`.git`, `.vscode`); visible directories signal content (`docs/`, `tests/`). Capitalized matches "PRP" branding. |
| Dual-path support during transition | None — clean cut at v4.0 | Support both paths in plugin commands | Conditional logic in every command would create permanent maintenance burden for a transitional concern. Auto-migration handles the upgrade once. |
| Migration delivery | Auto-migration shim on first command | Manual migration command, release-note instructions only | Auto-migration is invisible to the user when it works, which is most of the time. Manual steps invite forgotten migrations and broken states. |
| Versioning | Major bump → v4.0.0 | Minor bump, patch | The path is a public contract: consumers' existing artifacts live there. Changing it is by definition breaking. Semver compels major. |
| Counters file location | `PRPs/.counters.json` | `PRPs/_meta/counters.json`, `.claude/PRPs.counters.json` | Counters are part of the artifact tree; co-locating keeps the model simple. Dot-prefix on the file (vs. directory) keeps it visually de-emphasized. |
| Should `.claude/rules/` move too? | No — stays in `.claude/` | Move alongside artifacts | Rules are Claude Code tooling integration, not project content. Permission bug there is rare (rules are edited infrequently). |

---

## Research Summary

**Market Context**

No external market research applies — this is an internal-tooling decision. Convention check across major OSS tools:
- `docs/`, `tests/`, `examples/` — visible, project content
- `.github/`, `.vscode/`, `.idea/` — hidden, tooling integration
- `.claude/` follows the latter pattern (Claude Code tooling); `PRPs/` should follow the former (project content).

**Technical Context**

- Plugin source contains 208 occurrences of `.claude/PRPs/` across 26 files — verified via `grep`.
- The plugin ships as markdown command files; there's no compiled code, type system, or unit test suite to update — search-replace is the primary mechanism.
- Migration shim must run *before* any command writes to `PRPs/`, so it belongs at the top of each command (or in shared pre-flight logic).
- Counters file is small JSON, no schema changes needed.

---

*Generated: 2026-05-02*
*Status: DRAFT - needs validation*
