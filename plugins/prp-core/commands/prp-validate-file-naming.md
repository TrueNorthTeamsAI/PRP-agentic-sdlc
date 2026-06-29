---
description: Validate PRP artifact naming (PRDs, visions, plans, reports) — accepts both date+initials and legacy counter formats
---

# Validate PRP Artifact Naming

## Phase 0: PRE-FLIGHT — Artifact Path Migration

Before any artifact read or write, probe the working tree:

| State | Condition | Action |
|-------|-----------|--------|
| FRESH | Neither `.claude/PRPs/` nor `PRPs/` exists | Continue silently |
| V4    | `PRPs/` exists, `.claude/PRPs/` does not | Continue silently |
| V3    | `.claude/PRPs/` exists, `PRPs/` does not | Auto-migrate, then continue |
| BOTH  | Both directories exist | STOP with abort message |

### V3 → V4 Migration

1. Detect git repo: run `git rev-parse --is-inside-work-tree`. If exit 0 → git repo; else plain.
2. **Git repo path**: from repo root (`git rev-parse --show-toplevel`), run `git mv .claude/PRPs PRPs`. The rename is staged but not committed; the next command-driven `git commit` will include it.
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
- Run `git mv` from repo root (`git rev-parse --show-toplevel`) so invoking from a subdirectory still works.

---

## Objective

Scan all PRP artifacts in `PRPs/`, verify they match a supported naming format (date+initials **or** legacy counter), fix any filenames that don't comply, and update internal cross-references after any renames. `.counters.json` is no longer used — do not read or write it.

---

## Naming Convention Reference

PRP-Core supports two naming formats. Both are valid; new artifacts use date+initials, but legacy counter-numbered artifacts are not renamed.

### Date+initials (current — used for all new artifacts)

`{YYYYMMDD}{II}[s]` where `YYYYMMDD` is the UTC creation date, `II` is the author's 2-char uppercase initials, and `[s]` is an optional lowercase suffix (`b`, `c`, ...) for same-day same-author collisions.

| Artifact | Pattern | Example |
|----------|---------|---------|
| Vision | `V{YYYYMMDD}{II}[s]-{slug}.vision.md` | `V20260630DR-platform-strategy.vision.md` |
| PRD (standalone) | `PRD{YYYYMMDD}{II}[s]-{slug}.prd.md` | `PRD20260630DR-tank-prp-integration.prd.md` |
| PRD (vision-linked) | `V{...}-PRD{...}-{slug}.prd.md` | `V20260630DR-PRD20260701HA-auth-middleware.prd.md` |
| Plan | `{PRD-prefix}-P{NN}-{slug}.plan.md` | `PRD20260630DR-P02-tank-issue-lifecycle.plan.md` |
| Report | `{plan-name}-report.md` | `PRD20260630DR-P02-tank-issue-lifecycle-report.md` |

- Plan numbers (`P{NN}`) are **per-PRD** — they restart at `P01` for each PRD.
- Plan numbers are zero-padded to 2 digits.

### Legacy counter format (preserved as-is)

| Artifact | Pattern | Example |
|----------|---------|---------|
| Vision | `V{NNN}-{slug}.vision.md` | `V001-platform-strategy.vision.md` |
| PRD (standalone) | `PRD{NNN}-{slug}.prd.md` | `PRD001-tank-prp-integration.prd.md` |
| PRD (vision-linked) | `V{NNN}-PRD{NNN}-{slug}.prd.md` | `V001-PRD003-auth-middleware.prd.md` |
| Plan | `{PRD-prefix}-P{NNN}-{slug}.plan.md` | `PRD001-P002-tank-issue-lifecycle.plan.md` |

- Numbers are zero-padded to 3 digits.
- Plan numbers are **global** across all PRDs (legacy convention).
- Reports mirror the plan filename with `-report` suffix.
- Ralph archive directories use `{date}-{plan-name}/` format.

### Combined regex (either format)

| Artifact | Regex |
|----------|-------|
| Vision | `^V(\d{3}\|\d{8}[A-Z]{2}[a-z]?)-.+\.vision\.md$` |
| PRD (standalone) | `^PRD(\d{3}\|\d{8}[A-Z]{2}[a-z]?)-.+\.prd\.md$` |
| PRD (vision-linked) | `^V(\d{3}\|\d{8}[A-Z]{2}[a-z]?)-PRD(\d{3}\|\d{8}[A-Z]{2}[a-z]?)-.+\.prd\.md$` |
| Plan (standalone PRD) | `^PRD(\d{3}\|\d{8}[A-Z]{2}[a-z]?)-P\d{2,3}-.+\.plan\.md$` |
| Plan (vision-linked PRD) | `^V(\d{3}\|\d{8}[A-Z]{2}[a-z]?)-PRD(\d{3}\|\d{8}[A-Z]{2}[a-z]?)-P\d{2,3}-.+\.plan\.md$` |

---

## Process

### Phase 1: Inventory

Read the current state of all PRP artifact directories:

```bash
find PRPs -type f -name "*.md" | sort
find PRPs/ralph-archives -type d -mindepth 1 -maxdepth 1 | sort
```

Build an inventory of every artifact, noting:
- Which already have a correct prefix (either date+initials or legacy counter — both are valid)
- Which are missing prefixes (truly unprefixed legacy names)
- Which have placeholder prefixes (e.g., `PRD000`)

> Do **not** read `PRPs/.counters.json`. The counter system is retired. If the file is present, ignore its contents.

### Phase 2: Determine Top-Level Document Ordering

Top-level documents are **visions** (if any exist) or **standalone PRDs** (if no visions exist). Their ordering determines the numbering prefix for all downstream artifacts.

**Step 1: Identify which documents need ordering.**

- If visions exist → visions are top-level. Standalone PRDs (not linked to a vision) are also top-level.
- If no visions exist → standalone PRDs are top-level.
- Vision-linked PRDs inherit their vision's number and are ordered within that vision (Phase 2b).

**Step 2: Try to infer ordering** from:
1. Existing correct prefixes — preserve any `V{NNN}` or `PRD{NNN}` already assigned
2. Git history — which file was committed first (`git log --diff-filter=A --format="%ai %s" -- <file>`)
3. File modification dates
4. References between documents (a document that references another is likely later)

**Step 3: Present and confirm.**

- If ALL top-level documents already have correct prefixes → use them, no need to ask.
- Otherwise → present the proposed ordering to the user and ask them to confirm or correct it. Show what evidence you used (git dates, references, etc.) so the user can judge.

```
I've determined this ordering for your {visions/PRDs}. Please confirm or correct:

  1. {V/PRD}001 — {filename} — {title or slug} (evidence: {committed 2026-01-15 / file date / etc.})
  2. {V/PRD}002 — {filename} — {title or slug} (evidence: {committed 2026-02-03 / etc.})
  3. {V/PRD}003 — {filename} — {title or slug} (evidence: {no git history — guessed from file date})

Reply "yes" to confirm, or provide the correct order (e.g., "2, 1, 3").
```

**Do not proceed past this phase until the user confirms.**

### Phase 2b: Determine Vision-Linked PRD Ordering

For each vision, determine the order of PRDs linked to it:
- If PRDs already have correct `V{NNN}-PRD{NNN}` prefixes → preserve them, no need to ask.
- Otherwise → infer from the vision's PRD Tracker table, git history, or phase references, then present the proposed ordering to the user for confirmation before proceeding.

### Phase 3: Determine Plan Ordering

For each PRD, read its Implementation Phases table to find referenced plans. Then determine the global plan creation order:
1. Check if plans already have `P{NNN}` numbers — preserve those
2. For unnumbered plans, use git history or file dates to determine creation order
3. Assign `P{NNN}` numbers globally across all PRDs (not per-PRD)

- If all plans already have correct `P{NNN}` numbers → preserve them, no need to ask.
- Otherwise → infer ordering, present the proposed plan numbering to the user for confirmation, and wait for approval before proceeding.

### Phase 4: Rename Files

Rename in this order (dependencies first):

**1. Visions** (in `visions/` and `visions/completed/`):
- Add `V{NNN}-` prefix if missing

**2. PRDs** (in `prds/` and `prds/completed/`):
- Add `PRD{NNN}-` prefix if missing
- Add `V{NNN}-` prefix if vision-linked and missing

**3. Plans** (in `plans/` and `plans/completed/`):
- Add `{PRD-prefix}-P{NNN}-` prefix if missing
- Fix `PRD000` → correct PRD number
- If a plan was superseded by another for the same phase, append `-draft` suffix

**4. Reports** (in `reports/`):
- Rename to match their corresponding plan name + `-report` suffix
- If reports are in the wrong directory (e.g., `plans/reports/`), move them to `reports/`

**5. Ralph archives** (in `ralph-archives/`):
- Rename directories to match `{date}-{plan-name}/` using the new plan name

Use `mv` for each rename. Print each rename as it happens:
```
RENAME: prds/old-name.prd.md → prds/PRD001-new-name.prd.md
```

### Phase 5: Update Internal References

Search all vision and PRD files for references to plan or PRD filenames and update them:

```bash
grep -rn "\.plan\.md\|\.prd\.md\|PRPs/plans\|PRPs/prds" PRPs/prds/ PRPs/visions/ 2>/dev/null
```

For each match:
- If the referenced filename was renamed, update the reference to the new name
- Ensure paths are correct (e.g., `plans/completed/` not just `plans/`)

Also check plan files themselves for cross-references to other plans or PRDs.

### Phase 6: Retire `.counters.json`

The counter system has been retired. Do **not** write `PRPs/.counters.json`. If it exists on disk, leave it untouched (preserved for historical reference). New PRDs and visions use date+initials IDs; new plan numbers come from a per-PRD scan of `PRPs/plans/`.

### Phase 7: Report

Print a summary:

```
## PRP Numbering Validation Report

### PRDs
| # | Filename | Status |
|---|----------|--------|
| PRD001 | PRD001-slug.prd.md | ✓ (already correct) or RENAMED from old-name.prd.md |

### Plans
| # | PRD | Filename | Status |
|---|-----|----------|--------|
| P001 | PRD001 | PRD001-P001-slug.plan.md | ✓ or RENAMED |

### Reports
| Plan | Report | Status |
|------|--------|--------|
| PRD001-P001 | PRD001-P001-slug-report.md | ✓ or RENAMED or MOVED |

### Ralph Archives
| Directory | Status |
|-----------|--------|
| 2026-04-05-PRD001-P001-slug/ | ✓ or RENAMED |

### References Updated
| File | Old Reference | New Reference |
|------|---------------|---------------|
| PRD001-slug.prd.md:42 | old-plan-name.plan.md | new-plan-name.plan.md |

### Counters
*Retired — `.counters.json` is no longer maintained. New artifacts use date+initials IDs; new plans use per-PRD numbering scanned from `PRPs/plans/`.*
```

---

## Rules

- **Never delete files** — only rename/move
- **Never renumber existing correctly-numbered artifacts** — only add/fix prefixes
- **Both naming formats are valid** — date+initials (new) and 3-digit counter (legacy). Do not convert legacy artifacts to the new format; only fix truly broken/missing prefixes.
- **Always confirm ordering with the user** — for top-level documents (visions or standalone PRDs), vision-linked PRDs, and plans whose prefixes are missing or broken, infer the best ordering you can, then present it to the user for confirmation before renaming. Do not proceed until the user approves.
- **When assigning new prefixes to legacy unnumbered artifacts**: use the legacy 3-digit counter format (`PRD001`, `P001`) — pick the next free number by inspecting other legacy artifacts. Do NOT mint date+initials retroactively (we don't know the original author).
- **Preserve slugs** — keep the descriptive part of filenames intact (only add/fix the prefix)
- **Plan counter scope** — for the new date+initials format, plan numbers are **per-PRD**. For legacy artifacts, plan numbers are global across all PRDs. Preserve whichever scheme is in use.
- **Superseded plans** get a `-draft` suffix but keep the same P number as the plan that replaced them (since they share the same phase)
- **Reports directory** is `PRPs/reports/`, NOT `PRPs/plans/reports/`
- **Never touch `.counters.json`** — it is retired. If present, leave it alone.
