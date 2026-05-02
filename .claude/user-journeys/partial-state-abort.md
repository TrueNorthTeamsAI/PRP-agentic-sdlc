# Journey: Partial-State Abort

**Type**: Automated (validation-script-driven)
**Origin**: PRD001-P002 — Migration Shim
**Status**: Active

---

## Goal

Verify that when both `.claude/PRPs/` and `PRPs/` exist (ambiguous state), the migration shim refuses to guess which is authoritative — it prints a clear abort message and STOPS without modifying either directory.

## Preconditions

A git repo with both directories present, each holding at least one sentinel file.

## Setup

```powershell
$tmp3 = New-TemporaryFile ; rm $tmp3 ; mkdir $tmp3 ; cd $tmp3
git init -q
mkdir -p .claude/PRPs
mkdir -p PRPs
"" | Out-File -Encoding utf8 .claude/PRPs/.gitkeep
"" | Out-File -Encoding utf8 PRPs/.gitkeep
git add .
git commit -q -m "both"
```

## Steps

1. From inside the scratch repo, invoke any artifact-touching PRP command (e.g., `/prp-whats-next`).
2. Observe stdout — the abort message must be displayed.
3. Confirm the command STOPPED and did not proceed past Phase 0.
4. Run the validation script.

## Expected

- Command STOPS without performing any artifact reads/writes.
- Stdout contains the literal line: `STOP: PRP artifact directory is in a partial-migration state.`
- Stdout includes the remediation block showing both `rm -rf` options.
- Both directories still exist with original sentinel files unchanged.
- No `git mv`, `mv`, or `Move-Item` was executed.

## Validation Script

Exit 0 = PASS.

```bash
set -e
test -d .claude/PRPs
test -d PRPs
test -f .claude/PRPs/.gitkeep
test -f PRPs/.gitkeep
```

If you captured stdout as `out.txt`:

```bash
grep -q "STOP: PRP artifact directory is in a partial-migration state" out.txt
```

## Teardown

```powershell
cd $HOME ; rm -rf $tmp3
```

## Notes

- This journey exercises the **BOTH** state. Auto-resolution is intentionally not attempted — see PRD001 risk register: "warn and abort, ask user to resolve."
- Two valid resolutions exist (keep `PRPs/`, keep `.claude/PRPs/`, or merge); the shim cannot pick safely.
