---
name: migrate40
description: Explicitly migrate PRP artifacts from the v3 layout (.claude/PRPs/) to the v4 layout (PRPs/). Idempotent.
user-invocable: true
---

# PRP Migrate 4.0

Explicit, user-invokable version of the Phase 0 PRE-FLIGHT migration shim. Use this when you want to perform the v3 → v4 artifact relocation up-front, instead of letting it happen on the next PRP command.

This command is **idempotent**: running it on a v4 or fresh repo prints a status line and exits without changes.

---

## Procedure

Run from the repository root (or any subdirectory of a git work tree — step 2 resolves the root).

### 1. Detect repo state

| State | Condition | Action |
|-------|-----------|--------|
| FRESH | Neither `.claude/PRPs/` nor `PRPs/` exists | Print `→ No PRP artifacts found. Nothing to migrate.` and exit. |
| V4    | `PRPs/` exists, `.claude/PRPs/` does not | Print `→ Already on v4 layout. Nothing to migrate.` and exit. |
| V3    | `.claude/PRPs/` exists, `PRPs/` does not | Proceed to step 2. |
| BOTH  | Both directories exist | Abort — see "BOTH State Abort" below. |

Use `test -d .claude/PRPs` and `test -d PRPs` (Bash) or `Test-Path .claude/PRPs` / `Test-Path PRPs` (PowerShell).

### 2. V3 → V4 Migration

1. Detect git repo: run `git rev-parse --is-inside-work-tree`. Exit 0 → git repo; non-zero → plain.
2. **Git repo path**: from repo root (`git rev-parse --show-toplevel`), run:
   ```bash
   git mv .claude/PRPs PRPs
   ```
   The rename is staged but **not committed**. The next command-driven `git commit` (or your own) will include it.
3. **Non-git path**: run `mv .claude/PRPs PRPs` (Bash) or `Move-Item .claude/PRPs PRPs` (PowerShell).
4. Print exactly one line:
   `→ Migrated PRP artifacts: .claude/PRPs/ → PRPs/ (git mv staged for next commit)`
   (Drop "git mv staged" suffix if non-git.)

### 3. Post-migration verification

Confirm the new state and report it:

```bash
test ! -d .claude/PRPs && test -d PRPs && echo "OK: layout is v4"
```

Then print:

```
✓ Migration complete.
  Next step: review with `git status`, then commit with:
    git commit -m "chore: migrate PRP artifacts to PRPs/ (prp-core v4.0.0)"
```

If non-git: drop the commit suggestion.

---

## BOTH State Abort

If both `.claude/PRPs/` and `PRPs/` exist, print the following and STOP without making changes:

```
STOP: PRP artifact directory is in a partial-migration state.

Both `.claude/PRPs/` and `PRPs/` exist. The migration shim cannot decide which is authoritative.

Resolve by choosing one:
  # If PRPs/ has the latest work:
  rm -rf .claude/PRPs

  # If .claude/PRPs/ has the latest work:
  rm -rf PRPs
  git mv .claude/PRPs PRPs

Then re-run /prp-core:migrate40.
```

---

## Notes

- Touches only `.claude/PRPs/` → `PRPs/`. Does NOT modify `.claude/rules/`, `.claude/settings.local.json`, or any other `.claude/*` content.
- Safe to run from a subdirectory — the git path resolves the repo root first.
- For dirty working trees: the rename is the only staged change, but it will sit alongside any other unstaged edits. Stash unrelated changes first if you want a clean migration commit.
