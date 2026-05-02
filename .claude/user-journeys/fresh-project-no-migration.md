# Journey: Fresh Project — Shim Is a No-Op

**Type**: Automated (validation-script-driven)
**Origin**: PRD001-P002 — Migration Shim
**Status**: Active

---

## Goal

Verify that on a brand-new repo with neither `.claude/PRPs/` nor `PRPs/`, the migration shim is silently a no-op and does not create either directory.

## Preconditions

An empty git repo with only a `README.md`. No PRP artifacts of any kind.

## Setup

```powershell
$tmp2 = New-TemporaryFile ; rm $tmp2 ; mkdir $tmp2 ; cd $tmp2
git init -q
"# README" | Out-File -Encoding utf8 README.md
git add .
git commit -q -m "fresh"
```

## Steps

1. From inside the scratch repo, invoke `/prp-whats-next`.
2. Observe stdout.
3. Run the validation script below.

## Expected

- Neither `.claude/PRPs/` nor `PRPs/` exists after invocation.
- Stdout contains no migration announcement (the literal `→ Migrated PRP artifacts:` substring must NOT appear).
- The command produces its normal "no artifacts found" or empty-tree output.

## Validation Script

Exit 0 = PASS.

```bash
set -e
test ! -d .claude/PRPs
test ! -d PRPs
```

If you also captured stdout as `out.txt`:

```bash
! grep -q "→ Migrated PRP artifacts" out.txt
```

## Teardown

```powershell
cd $HOME ; rm -rf $tmp2
```

## Notes

- This journey exercises the **FRESH** state. The shim probe must short-circuit silently.
- A fresh repo never reaches the migration branch; this guards against regressions where the shim accidentally creates an empty `PRPs/` directory.
