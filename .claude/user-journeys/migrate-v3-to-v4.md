# Journey: V3 → V4 Auto-Migration

**Type**: Automated (validation-script-driven)
**Origin**: PRD001-P002 — Migration Shim
**Status**: Active

---

## Goal

Verify that the first PRP command invoked on a v3 consumer (one that still has `.claude/PRPs/` from prp-core ≤3.x) auto-migrates artifacts to `PRPs/` via `git mv`, prints the announcement line, and proceeds normally.

## Preconditions

A scratch git repo with a v3 layout: `.claude/PRPs/` populated, no `PRPs/` directory.

## Setup

```powershell
$tmp = New-TemporaryFile ; rm $tmp ; mkdir $tmp ; cd $tmp
git init -q
mkdir -p .claude/PRPs/prds
"# fake PRD" | Out-File -Encoding utf8 .claude/PRPs/prds/PRD000-fake.prd.md
'{"vision":0,"prd":1,"plan":0}' | Out-File -Encoding utf8 .claude/PRPs/.counters.json
git add .
git commit -q -m "v3 baseline"
```

## Steps

1. From inside the scratch repo, invoke `/prp-whats-next` (the lightest-weight artifact-touching command).
2. Observe the announcement line in stdout.
3. Run the validation script below.

## Expected

- `PRPs/prds/PRD000-fake.prd.md` exists.
- `.claude/PRPs/` no longer exists.
- `git status --porcelain` shows the rename in staging (`R` entries from `.claude/PRPs/...` to `PRPs/...`).
- Stdout contains the literal line: `→ Migrated PRP artifacts: .claude/PRPs/ → PRPs/ (git mv staged for next commit)`.
- The original command (`/prp-whats-next`) proceeds and produces its normal output (status report or "no artifacts").

## Validation Script

Exit 0 = PASS. Run from the scratch repo root after the command completes.

```bash
set -e
test ! -d .claude/PRPs
test -d PRPs
test -f PRPs/prds/PRD000-fake.prd.md
git status --porcelain | grep -qE "^R.*\.claude/PRPs.*->.*PRPs"
```

## Teardown

```powershell
cd $HOME ; rm -rf $tmp
```

## Notes

- This journey exercises the **V3** state of the migration shim. Idempotency is verified separately by re-running the command — second run sees V4 and is silent.
- If the consumer repo is in a subdirectory when the user invokes the command, the shim resolves repo root via `git rev-parse --show-toplevel` so the `git mv` still succeeds.
