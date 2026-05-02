# Feature: Release prp-core v4.0.0

## Summary

Cut a tagged GitHub release of prp-core v4.0.0, the breaking-change version that relocates PRP artifacts from `.claude/PRPs/` to `PRPs/` at the repo root. This phase produces: a `CHANGELOG.md`, a bumped `plugin.json`, a signed git tag, and a GitHub Release with migration notes for downstream consumers.

## User Story

As a prp-core consumer running v3.x in `bypass-permissions` mode
I want a clearly-tagged v4.0.0 release with migration instructions
So that I can run `claude plugin update prp-core`, hit the auto-migration shim on first command, and stop seeing permission prompts on PRP artifact writes.

## Problem Statement

Phases 1–4 finished the technical work (plugin paths updated, migration shim built, docs refreshed, this repo self-migrated), but consumers cannot pick up any of it until v4.0.0 ships. Without a release, the work is invisible.

## Solution Statement

Run a single, scripted release pass:
1. Verify the plugin source is clean (no stray `.claude/PRPs/` references outside the migration shim).
2. Author `CHANGELOG.md` covering v4.0.0 (the breaking change + migration notes) — this is the first changelog this repo has had, so set up the format too.
3. Invoke `/release --major` (the existing release command at [.claude/commands/release.md](.claude/commands/release.md)) to bump `plugin.json` 3.4.0 → 4.0.0, commit, tag `v4.0.0`, and push.
4. Create the GitHub Release from the new tag with `gh release create v4.0.0`, body sourced from the v4.0.0 section of `CHANGELOG.md`.

## Metadata

| Field            | Value                                                          |
| ---------------- | -------------------------------------------------------------- |
| Type             | RELEASE                                                        |
| Complexity       | LOW                                                            |
| Systems Affected | `plugins/prp-core/.claude-plugin/plugin.json`, repo root, GitHub Releases |
| Dependencies     | git, `gh` CLI, existing `/release` slash command               |
| Estimated Tasks  | 5                                                              |
| Source PRD       | `PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md`  |
| PRD Phase        | 5 — Release v4.0.0                                             |

---

## UX Design

### Before State
```
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Consumer in v3.x:                                                            ║
║                                                                               ║
║   claude plugin update prp-core   ──► Pulls v3.4.0                            ║
║   /prp-plan ...                   ──► Writes to .claude/PRPs/                 ║
║                                       ──► Permission prompt                   ║
║                                       ──► User clicks through                 ║
║                                                                               ║
║   PAIN_POINT: bypass-permissions does not bypass writes under .claude/        ║
║   DATA_FLOW:  artifact → .claude/PRPs/ → permission gate → maybe written      ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

### After State
```
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Consumer after `claude plugin update prp-core`:                              ║
║                                                                               ║
║   claude plugin update prp-core   ──► Pulls v4.0.0                            ║
║   /prp-plan ...                                                               ║
║      ├─► Migration shim: .claude/PRPs/ → PRPs/   (one-time, silent)           ║
║      └─► Writes to PRPs/                          (no permission prompt)      ║
║                                                                               ║
║   VALUE_ADD: zero permission prompts on the hot path                          ║
║   DATA_FLOW: artifact → PRPs/ (top-level) → written                           ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

### Interaction Changes

| Location                          | Before                            | After                                          | User Impact                          |
| --------------------------------- | --------------------------------- | ---------------------------------------------- | ------------------------------------ |
| `claude plugin update prp-core`   | Pulls v3.4.0                      | Pulls v4.0.0 (breaking)                        | Consumer must read release notes     |
| First `/prp-*` command after update | Writes to `.claude/PRPs/`         | Auto-migrates `.claude/PRPs/` → `PRPs/`, writes to `PRPs/` | Migration is invisible if happy path |
| GitHub Releases page              | Last entry: v3.4.0                | New entry: v4.0.0 with migration notes         | Consumer can audit before updating   |

---

## User Journeys

| Journey File                                          | Impact   | Description                                  |
| ----------------------------------------------------- | -------- | -------------------------------------------- |
| `.claude/user-journeys/migrate-v3-to-v4.md`           | VERIFY   | Should exercise cleanly against tagged v4.0.0 |
| `.claude/user-journeys/fresh-project-no-migration.md` | VERIFY   | Should pass against tagged v4.0.0             |
| `.claude/user-journeys/partial-state-abort.md`        | VERIFY   | Should pass against tagged v4.0.0             |

**Manual** (release-only verification — non-blocking for this phase, blocking for Phase 6):
- All three journeys above are exercised by Phase 6 (consumer validation), not this phase. This phase only ensures the release artifacts exist and are correct.

No new journey files are introduced by this phase.

---

## How to Execute

### Start Services
```
N/A — no services required for a release.
```

### Seed Data / Reset State
```bash
# Working tree should be clean before release
git status
```

### Verify Ready
```bash
# Must be on main, up to date with origin
git rev-parse --abbrev-ref HEAD       # → main
git fetch origin && git status -sb    # → no diverge from origin/main
gh auth status                        # → logged in
```

### Teardown
```
N/A
```

---

## Mandatory Reading

| Priority | File                                                  | Lines | Why Read This                                                                 |
| -------- | ----------------------------------------------------- | ----- | ----------------------------------------------------------------------------- |
| P0       | `.claude/commands/release.md`                          | 1-50  | The exact mechanics of the version bump, commit, tag, push step              |
| P0       | `plugins/prp-core/.claude-plugin/plugin.json`          | 1-9   | Current version (3.4.0) — confirm before bump                                |
| P0       | `PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` | full  | Source PRD — pulls release-notes content (problem, hypothesis, NOT building) |
| P1       | `plugins/prp-core/skills/init-project/SKILL.md`        | 595-640 | Canonical migration shim block — referenced in release notes                |

**External Documentation:**

| Source                                                                              | Section                       | Why Needed                                       |
| ----------------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------------ |
| [keepachangelog v1.1.0](https://keepachangelog.com/en/1.1.0/)                        | Whole spec                    | Format for new `CHANGELOG.md` (no prior format)  |
| [Semantic Versioning v2.0.0](https://semver.org/spec/v2.0.0.html#spec-item-8)        | Item 8 — major bump           | Justifies 3.4.0 → 4.0.0 for breaking path change |
| [gh release create](https://cli.github.com/manual/gh_release_create)                 | `--notes-file`, `--target`    | Body sourcing and target tag                     |

**Context Sources Loaded** (from `context-map.md` via Phase 1.5):

No `context-map.md` found in repo — no external context auto-loaded.

---

## Patterns to Mirror

**RELEASE_MECHANICS** (the canonical version-bump path):
```markdown
# SOURCE: .claude/commands/release.md:19-45
# COPY THIS PATTERN: do not invent a new release flow — invoke /release --major.

1. Read plugins/prp-core/.claude-plugin/plugin.json
2. Increment major, reset minor and patch to 0  (3.4.0 → 4.0.0)
3. Update plugin.json
4. git add -A
5. git commit -m "feat: ... (v4.0.0)"
6. git tag v4.0.0
7. git push && git push --tags
```

**RELEASE_COMMIT_MESSAGE** (when there are substantive non-version changes staged):
```
# SOURCE: .claude/commands/release.md:34-35
# COPY THIS PATTERN:
feat: <one-line summary of substantive change> (v4.0.0)

# For this phase the only change is CHANGELOG.md + plugin.json bump, so:
chore: release prp-core v4.0.0 (relocate PRP artifacts to repo root)
```

**TAG_NAMING** (mirror existing tags):
```
# SOURCE: `git tag --list`
v3.0.0, v3.0.1, v3.2.0, v3.3.0, v3.4.0   →   v4.0.0
# COPY THIS PATTERN: lowercase `v` prefix, no annotated message, no `-rc` suffix.
```

**KEEPACHANGELOG_HEADER** (target shape for the new `CHANGELOG.md`):
```markdown
# Changelog

All notable changes to the prp-core plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] — 2026-05-02

### ⚠️ Breaking Changes

- **PRP artifacts relocated** from `.claude/PRPs/` to `PRPs/` at the repo root.
  Consumers in `bypass-permissions` mode were hitting permission prompts on every
  artifact write because Claude Code gates writes under `.claude/` even with the
  bypass flag set. PRP artifacts (PRDs, plans, visions, reports, investigations,
  `.counters.json`) are first-class project content and now live alongside `docs/`
  and `tests/`.

### Migration

The first invocation of any `/prp-*` command after upgrading runs an automatic
shim that detects the v3 layout and performs `git mv .claude/PRPs PRPs`. The
rename is staged but not committed; the next command-driven commit picks it up.

- **Happy path** (v3 layout, no `PRPs/`): silent auto-migrate, command proceeds.
- **Already migrated** (`PRPs/` exists, no `.claude/PRPs/`): no-op.
- **Partial state** (both directories exist): shim aborts with a clear message.
  Resolve by deleting whichever copy is stale, then re-run the command.
- **Non-git repo**: shim falls back to plain `mv`/`Move-Item` and warns.

If you have CI or external tooling that hardcodes `.claude/PRPs/`, update those
paths to `PRPs/` before pulling v4.0.0 into automation.

### Added

- Auto-migration shim documented in `plugins/prp-core/skills/init-project/SKILL.md`
  (canonical block) and inlined at the top of every PRP command.

### Changed

- All plugin commands, skills, templates, and scripts now read/write under `PRPs/`.
- Root `CLAUDE.md`, `README.md`, `README-for-DUMMIES.md`, plugin `README.md`, and
  `claude_md_files/*.md` updated to reference `PRPs/`.
- `init-project` scaffolds `PRPs/` directly — fresh projects never see `.claude/PRPs/`.

### Removed

- `.claude/PRPs/` as the artifact location. Mentions remain only in the migration
  shim text and this changelog.
```

**GH_RELEASE_INVOCATION**:
```bash
# COPY THIS PATTERN:
gh release create v4.0.0 \
  --title "v4.0.0 — Relocate PRP artifacts to PRPs/" \
  --notes-file <(awk '/^## \[4\.0\.0\]/,/^## \[/{ if (/^## \[/ && !/^## \[4\.0\.0\]/) exit; print }' CHANGELOG.md)
```

---

## Files to Change

| File                                              | Action  | Justification                                         |
| ------------------------------------------------- | ------- | ----------------------------------------------------- |
| `CHANGELOG.md`                                     | CREATE  | First changelog for the repo; v4.0.0 entry           |
| `plugins/prp-core/.claude-plugin/plugin.json`     | UPDATE  | `version` field 3.4.0 → 4.0.0 (done by `/release`)   |
| `PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` | UPDATE | Mark Phase 5 complete, link this plan         |
| `PRPs/plans/PRD001-P005-release-v4.0.0.plan.md`   | MOVE    | Archive to `PRPs/plans/completed/` after success     |

No source code changes. No test changes.

---

## NOT Building (Scope Limits)

- **Consumer-side validation** — explicitly Phase 6's job. This phase ends when v4.0.0 is tagged on GitHub.
- **Backporting fixes to v3.x branch** — out of scope per PRD ("Backport to v3.x: Won't").
- **Releasing as a pre-release / `-rc` tag** — PRD calls for a clean major bump; consumers test via Phase 6.
- **Auto-generated release notes from commit history** — `gh release create --generate-notes` would dump every commit since v3.4.0; we want the curated changelog body instead.
- **Editing `pyproject.toml` version** — that file is package metadata for tooling, not the prp-core plugin version. The plugin's source of truth is `plugin.json`.

---

## Step-by-Step Tasks

### Task 1: VERIFY clean working tree and pre-flight grep gate

- **ACTION**: Confirm release pre-conditions before touching anything.
- **IMPLEMENT**:
  ```bash
  # Working tree clean, on main, up to date
  git status                                # → "nothing to commit, working tree clean"
  git rev-parse --abbrev-ref HEAD           # → main
  git fetch origin && git status -sb        # → no diverge

  # Pre-flight grep gate (per PRD success metric):
  # All .claude/PRPs/ refs in plugins/ must be inside the migration shim block.
  grep -rn '\.claude/PRPs' plugins/
  ```
- **EXPECT**: All matches in `plugins/` are inside the canonical migration shim block in `plugins/prp-core/skills/init-project/SKILL.md` (lines ~595-640) or the inlined shim block at the top of each PRP command. No stray references outside those blocks.
- **GOTCHA**: If a stray reference is found, STOP — fix it under Phase 1's domain and re-verify before proceeding. Do not paper over with a CHANGELOG note.
- **VALIDATE**: Manual review of grep output. Optional automated check:
  ```bash
  # Lines containing .claude/PRPs that are NOT in a migration-shim context:
  grep -rn '\.claude/PRPs' plugins/ | grep -viE '(migrate|migration|shim|FRESH|V3|V4|PARTIAL)' || echo "OK: all references are in shim context"
  ```

### Task 2: CREATE `CHANGELOG.md`

- **ACTION**: Author the first `CHANGELOG.md` for this repo with the v4.0.0 entry.
- **IMPLEMENT**: Use the **KEEPACHANGELOG_HEADER** snippet under "Patterns to Mirror" verbatim. Anchor the v4.0.0 entry's date to today (`date +%F` on bash; `Get-Date -Format yyyy-MM-dd` on PowerShell).
- **MIRROR**: Keep a Changelog v1.1.0 spec (no prior file in this repo to mirror).
- **CONTENT**: Sections in order: ⚠️ Breaking Changes, Migration, Added, Changed, Removed. Pull factual content from the source PRD's Problem Statement, Proposed Solution, NOT Building, and Decisions Log. Do **not** invent capabilities not in the PRD.
- **GOTCHA**: Do not include earlier versions (v3.x) in this changelog — they predate the format. Add a note at the bottom: `_Versions prior to 4.0.0 are not documented in this file; see git tags v3.0.0–v3.4.0 for history._`
- **VALIDATE**:
  ```bash
  test -f CHANGELOG.md && head -5 CHANGELOG.md | grep -q "Changelog"
  awk '/^## \[4\.0\.0\]/,0' CHANGELOG.md | head -1 | grep -q "4.0.0"   # entry exists
  ```

### Task 3: UPDATE source PRD (mark Phase 5 in-progress, link plan)

- **ACTION**: Edit `PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md`.
- **IMPLEMENT**: In the Implementation Phases table, change Phase 5's `Status` from `pending` to `in-progress`, set `PRP Plan` to `PRPs/plans/PRD001-P005-release-v4.0.0.plan.md`.
- **MIRROR**: Phases 1–4 rows for cell formatting.
- **GOTCHA**: This step is normally done by `/prp-plan` itself when creating this plan; if already done, skip.
- **VALIDATE**: `grep -n "P005" PRPs/prds/PRD001-relocate-prp-artifacts-to-repo-root.prd.md` returns the plan path.

### Task 4: RUN `/release --major`

- **ACTION**: Invoke the existing `/release` slash command with the `--major` flag.
- **IMPLEMENT**: At the Claude Code prompt, run: `/release --major`
- **WHAT IT DOES** (per [.claude/commands/release.md:17-45](.claude/commands/release.md)):
  1. Reads `plugins/prp-core/.claude-plugin/plugin.json` → current `3.4.0`.
  2. Bumps to `4.0.0` (major increment, minor/patch reset).
  3. Writes `plugin.json` back.
  4. `git add -A` (stages CHANGELOG.md, plugin.json, updated PRD, this plan).
  5. Commits with message: `feat: relocate PRP artifacts to PRPs/ at repo root (v4.0.0)`
     - Override the default `chore: bump prp-core to v4.0.0` because this commit carries substantive changes (CHANGELOG, PRD update, plan archive). Per the release command spec line 35.
  6. `git tag v4.0.0`.
  7. `git push && git push --tags`.
- **GOTCHA**: If `/release --major` insists on the default `chore: bump...` message because it sees only `plugin.json` staged, run `git add -A` manually first, then re-invoke. Alternatively, run the steps by hand using the script below.
- **MANUAL FALLBACK** (if `/release` is unavailable):
  ```bash
  # Edit plugin.json: "version": "3.4.0" → "version": "4.0.0"
  git add -A
  git commit -m "feat: relocate PRP artifacts to PRPs/ at repo root (v4.0.0)"
  git tag v4.0.0
  git push && git push --tags
  ```
- **VALIDATE**:
  ```bash
  grep '"version"' plugins/prp-core/.claude-plugin/plugin.json    # → "version": "4.0.0"
  git tag --list | grep -q '^v4\.0\.0$'                            # tag exists locally
  git ls-remote --tags origin v4.0.0 | grep -q v4.0.0              # tag pushed to origin
  git log -1 --pretty=%s | grep -q 'v4\.0\.0'                      # commit subject mentions v4.0.0
  ```

### Task 5: CREATE the GitHub Release

- **ACTION**: Publish the GitHub Release tied to tag `v4.0.0` with body sourced from `CHANGELOG.md`.
- **IMPLEMENT**:
  ```bash
  # Extract just the v4.0.0 section from CHANGELOG.md into a temp file:
  awk '/^## \[4\.0\.0\]/{flag=1} /^## \[/ && !/^## \[4\.0\.0\]/{if(flag){exit}} flag' CHANGELOG.md > /tmp/v4-notes.md

  gh release create v4.0.0 \
    --title "v4.0.0 — Relocate PRP artifacts to PRPs/" \
    --notes-file /tmp/v4-notes.md
  ```
  PowerShell equivalent if running natively:
  ```powershell
  $notes = (Get-Content CHANGELOG.md -Raw) -split '(?m)^## \['
  $v4 = ($notes | Where-Object { $_ -match '^4\.0\.0\]' }) -replace '^', '## ['
  Set-Content -Path "$env:TEMP\v4-notes.md" -Value $v4 -Encoding utf8
  gh release create v4.0.0 --title "v4.0.0 — Relocate PRP artifacts to PRPs/" --notes-file "$env:TEMP\v4-notes.md"
  ```
- **GOTCHA**: `gh release create` will fail if the tag isn't on the remote yet. Task 4's `git push --tags` must succeed first. Verify with `git ls-remote --tags origin v4.0.0` before this task.
- **GOTCHA**: Do **not** pass `--generate-notes` — it would prepend auto-generated commit-list noise to the curated body.
- **VALIDATE**:
  ```bash
  gh release view v4.0.0 --json tagName,name,body | python -c "import sys,json; r=json.load(sys.stdin); assert r['tagName']=='v4.0.0'; assert 'Breaking' in r['body']; print('OK')"
  ```

---

## Testing Strategy

### Unit Tests to Write

None. This repo has no unit test suite (per PRD Testing Strategy: "N/A — this repo has no traditional unit test suite; the plugin is markdown commands, not code.").

### E2E Tests to Write

None as part of this phase. Existing user journeys at `.claude/user-journeys/{migrate-v3-to-v4,fresh-project-no-migration,partial-state-abort}.md` are exercised by **Phase 6** against the published v4.0.0 release.

### Edge Cases Checklist

- [ ] `/release --major` invoked when working tree has unrelated dirty files → would commit them. Mitigation: Task 1's `git status` gate.
- [ ] Network failure between `git push` and `git push --tags` → tag exists locally but not on origin → `gh release create` fails. Recovery: re-run `git push --tags`.
- [ ] `gh` not authenticated → `gh release create` fails with auth error. Mitigation: Task 1's `gh auth status` gate.
- [ ] CHANGELOG.md awk extraction returns empty (heading mismatch) → empty release body. Mitigation: Task 5's `--notes-file` content visible before submitting; or use `gh release view` post-create check.
- [ ] Tag `v4.0.0` already exists (interrupted prior attempt) → `git tag` fails. Recovery: `git tag -d v4.0.0 && git push origin :refs/tags/v4.0.0` after confirming nothing depends on the prior attempt; then re-run.

---

## Validation Commands

### Level 1: STATIC_ANALYSIS

```bash
# No code, so no lint/type-check. Validate JSON syntactically:
python -c "import json; json.load(open('plugins/prp-core/.claude-plugin/plugin.json'))" && echo OK
```
**EXPECT**: Exit 0, prints `OK`.

### Level 2: UNIT_TESTS

N/A — no unit test suite.

### Level 3: FULL_SUITE

```bash
# Plugin source must not reference the old path outside the migration shim:
grep -rn '\.claude/PRPs' plugins/ | grep -viE '(migrate|migration|shim|FRESH|V3|V4|PARTIAL|→ Migrated)' || echo "OK"
```
**EXPECT**: Prints `OK` (no stray references).

### Level 4: DATABASE_VALIDATION

N/A.

### Level 5: USER_JOURNEY_VALIDATION

Deferred to Phase 6 — running the journeys requires fresh consumer projects, not this repo.

### Level 6: MANUAL_VALIDATION

After Task 5 completes:

1. Visit `https://github.com/TrueNorthTeamsAI/PRP-agentic-sdlc/releases/tag/v4.0.0` in a browser.
2. Confirm the release page shows:
   - Title: "v4.0.0 — Relocate PRP artifacts to PRPs/"
   - Body containing "Breaking Changes", "Migration", and the auto-migration shim explanation.
   - Source code archive links (auto-generated by GitHub).
3. From a separate terminal, in a sandbox repo: `claude plugin update prp-core` — confirm it pulls v4.0.0 (smoke check; deep validation is Phase 6).

---

## Acceptance Criteria

- [ ] `plugins/prp-core/.claude-plugin/plugin.json` contains `"version": "4.0.0"` on `main`.
- [ ] `CHANGELOG.md` exists at repo root with a `## [4.0.0]` section dated today.
- [ ] Git tag `v4.0.0` exists locally and on `origin`.
- [ ] GitHub Release `v4.0.0` is published with body sourced from `CHANGELOG.md`.
- [ ] Pre-flight grep gate passes (no stray `.claude/PRPs/` references in `plugins/`).
- [ ] PRD Phase 5 status updated to `complete`, plan archived to `PRPs/plans/completed/`.

---

## Completion Checklist

- [ ] Task 1: pre-flight gate passed (clean tree + grep clean)
- [ ] Task 2: `CHANGELOG.md` created with v4.0.0 entry
- [ ] Task 3: PRD updated (Phase 5 in-progress + plan link)
- [ ] Task 4: `/release --major` ran successfully (commit + tag + push)
- [ ] Task 5: GitHub Release published
- [ ] Level 1 + Level 3 validations pass
- [ ] Manual validation (browser confirmation of release page) done
- [ ] PRD updated again: Phase 5 → `complete`
- [ ] Plan moved to `PRPs/plans/completed/PRD001-P005-release-v4.0.0.plan.md`

---

## Risks and Mitigations

| Risk                                                                                  | Likelihood | Impact | Mitigation                                                                                       |
| ------------------------------------------------------------------------------------- | ---------- | ------ | ------------------------------------------------------------------------------------------------ |
| `/release --major` produces a `chore:` commit that buries the substantive change      | MED        | LOW    | Task 4 instructs overriding the message; manual fallback documented                              |
| Stray `.claude/PRPs/` reference outside shim → release ships with broken paths        | LOW        | HIGH   | Task 1 grep gate; Phase 1's success metric was already verified, this is a safety net           |
| Tag pushed but GitHub Release creation fails (e.g., `gh` auth lapse)                  | LOW        | MED    | Re-runnable: `gh release create` is idempotent on title/body if tag exists; can be retried       |
| Release notes diverge from actual behavior (PRD edited after CHANGELOG drafted)       | LOW        | MED    | CHANGELOG is sourced directly from the PRD's frozen sections at release time, not paraphrased   |
| Consumers update mid-PRP-workflow and hit migration shim with uncommitted v3 changes  | LOW        | MED    | PRD release notes already call this out (Phase 5 deliverable); flagged in CHANGELOG → Migration |
| `pyproject.toml` version mistakenly bumped, creating two competing version sources    | LOW        | LOW    | Explicit "NOT Building" entry; only `plugin.json` is the prp-core version of truth              |

---

## Notes

- **Release command source of truth**: this plan deliberately delegates the bump+tag+push mechanics to the existing `/release` slash command rather than duplicating its steps. If `/release` is enhanced later (e.g., to auto-generate CHANGELOG entries), this plan should shrink, not grow.
- **CHANGELOG bootstrap**: this is the first `CHANGELOG.md` in the repo. Future releases (v4.1, v4.2, …) extend it by prepending a new section above `[4.0.0]`. Versions <4.0 are intentionally not back-filled — git tags carry that history.
- **Phase 6 dependency**: this phase intentionally does not exercise consumer projects. That's Phase 6's scope and gates on a public v4.0.0 tag existing.
- **Confidence**: 9/10 for one-pass success. The mechanical steps (bump, tag, push, release) are well-understood and scripted; the only judgment call is the CHANGELOG body wording, which is sourced verbatim from the PRD.
