---
description: Validate and fix PRP artifact numbering (PRDs, plans, reports) and update .counters.json
---

# Validate PRD Numbers

## Objective

Scan all PRP artifacts in `.claude/PRPs/`, ensure they follow the hierarchical numbering convention (`PRD{NNN}`, `PRD{NNN}-P{NNN}`), fix any filenames that don't comply, update all internal cross-references, and sync `.counters.json`.

---

## Naming Convention Reference

The prp-core numbering convention:

| Artifact | Pattern | Example |
|----------|---------|---------|
| Vision | `V{NNN}-{slug}.vision.md` | `V001-platform-strategy.vision.md` |
| PRD (standalone) | `PRD{NNN}-{slug}.prd.md` | `PRD001-tank-prp-integration.prd.md` |
| PRD (vision-linked) | `V{NNN}-PRD{NNN}-{slug}.prd.md` | `V001-PRD003-auth-middleware.prd.md` |
| Plan | `{PRD-prefix}-P{NNN}-{slug}.plan.md` | `PRD001-P002-tank-issue-lifecycle.plan.md` |
| Report | `{plan-name}-report.md` | `PRD001-P002-tank-issue-lifecycle-report.md` |

- Numbers are zero-padded to 3 digits (e.g., `1` → `001`)
- Plan numbers are **global** across all PRDs (not per-PRD)
- Reports mirror the plan filename with `-report` suffix
- Ralph archive directories use `{date}-{plan-name}/` format

---

## Process

### Phase 1: Inventory

Read the current state of all PRP artifact directories:

```bash
find .claude/PRPs -type f -name "*.md" | sort
find .claude/PRPs/ralph-archives -type d -mindepth 1 -maxdepth 1 | sort
cat .claude/PRPs/.counters.json
```

Build an inventory of every artifact, noting:
- Which already have correct `PRD{NNN}` / `P{NNN}` prefixes
- Which are missing prefixes (legacy names)
- Which have wrong prefixes (e.g., `PRD000` placeholder)

### Phase 2: Determine PRD Ordering

**If the user provides an explicit ordering**, use it. Otherwise, infer ordering from:
1. Git history — which PRD file was committed first
2. File modification dates
3. References between PRDs (a PRD that references another is likely later)

Ask the user to confirm the ordering before proceeding:

```
I've identified these PRDs. Please confirm the numbering order:
  1. PRD001 — {name} ({status})
  2. PRD002 — {name} ({status})
  3. PRD003 — {name} ({status})
```

### Phase 3: Determine Plan Ordering

For each PRD, read its Implementation Phases table to find referenced plans. Then determine the global plan creation order:
1. Check if plans already have `P{NNN}` numbers — preserve those
2. For unnumbered plans, use git history or file dates to determine creation order
3. Assign `P{NNN}` numbers globally across all PRDs (not per-PRD)

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
grep -rn "\.plan\.md\|\.prd\.md\|PRPs/plans\|PRPs/prds" .claude/PRPs/prds/ .claude/PRPs/visions/ 2>/dev/null
```

For each match:
- If the referenced filename was renamed, update the reference to the new name
- Ensure paths are correct (e.g., `plans/completed/` not just `plans/`)

Also check plan files themselves for cross-references to other plans or PRDs.

### Phase 6: Update .counters.json

Count the final state and write the updated counters:

```json
{
  "vision": <highest V number assigned>,
  "prd": <highest PRD number assigned>,
  "plan": <highest P number assigned>
}
```

**Important**: Counters track the highest number assigned, not the total count of files. If PRD001 and PRD003 exist but PRD002 was deleted, the counter should be `3`.

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
Before: {"vision": 0, "prd": 0, "plan": 0}
After:  {"vision": 0, "prd": 3, "plan": 3}
```

---

## Rules

- **Never delete files** — only rename/move
- **Never renumber existing correctly-numbered artifacts** — only add/fix prefixes
- **Always ask for PRD ordering confirmation** before renaming if the ordering is ambiguous
- **Preserve slugs** — keep the descriptive part of filenames intact (only add/fix the prefix)
- **Global plan counter** — P numbers are unique across the whole project, not per-PRD
- **Superseded plans** get a `-draft` suffix but keep the same P number as the plan that replaced them (since they share the same phase)
- **Reports directory** is `.claude/PRPs/reports/`, NOT `.claude/PRPs/plans/reports/`
