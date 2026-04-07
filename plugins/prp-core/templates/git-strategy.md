# Git Strategy Rules

This project uses the **{strategy}** git strategy with `{base-branch}` as the base branch.

## Branch Naming

All branches use a hierarchical naming convention that reflects PRP artifact lineage.

### Feature branches (PRP workflow)

Branch names are built from the artifact IDs, skipping levels that don't apply:

| Strategy | Branch created by | Pattern | Example |
|----------|-------------------|---------|---------|
| `branch-per-prd` | prp-prd | `feat/{prd-id}-{name}` | `feat/PRD003-auth-system` |
| `branch-per-prd` (with vision) | prp-prd | `feat/{vision-id}/{prd-id}-{name}` | `feat/V001/PRD001-auth-system` |
| `branch-per-phase` | prp-plan | `feat/{prd-id}/{plan-id}-{name}` | `feat/PRD003/P001-api-endpoints` |
| `branch-per-phase` (with vision) | prp-plan | `feat/{vision-id}/{prd-id}/{plan-id}-{name}` | `feat/V001/PRD001/P001-api-endpoints` |

Rules:
- Use the artifact ID prefix (e.g., `PRD003`, `P001`, `V001`) — not the full hierarchical ID
- `{name}` is the kebab-case short name of the artifact
- If the PRD is **not** linked to a vision, omit the vision segment

### Fix and ad-hoc branches

For bug fixes, hotfixes, and ad-hoc work outside the PRP workflow:

| Type | Pattern | Example |
|------|---------|---------|
| Bug fix | `fix/{name}` | `fix/pagination-offset` |
| Hotfix | `fix/{name}` | `fix/critical-auth-bypass` |
| Chore | `chore/{name}` | `chore/upgrade-deps` |
| Refactor | `refactor/{name}` | `refactor/extract-service` |

These branch off from and merge back to `{base-branch}`.

## Merge Targets (PR destinations)

Branches merge back to their **parent** in the hierarchy:

| Branch | Merges into | When |
|--------|-------------|------|
| `feat/{vision}/{prd}/{plan}-{name}` | `feat/{vision}/{prd}-{name}` | Plan/phase implementation complete |
| `feat/{prd}/{plan}-{name}` | `feat/{prd}-{name}` | Plan/phase implementation complete (no vision) |
| `feat/{vision}/{prd}-{name}` | `{base-branch}` | All PRD phases complete |
| `feat/{prd}-{name}` | `{base-branch}` | All PRD phases complete (no vision) |
| `fix/{name}` | `{base-branch}` | Fix verified |
| `chore/{name}` | `{base-branch}` | Work complete |
| `refactor/{name}` | `{base-branch}` | Refactor complete |

### PR creation

When a branch is ready to merge:
1. Push the branch to remote
2. Create a PR targeting the parent branch (see table above)
3. Use conventional commit style for the PR title (e.g., `feat: implement auth API endpoints`)

## Strategy Details

- **`none`** — No git operations. You manage git manually.
- **`main-only`** — All work committed directly on `{base-branch}`. No branches or PRs created.
- **`branch-per-prd`** — One feature branch per PRD. All phases commit on the PRD branch. PR back to `{base-branch}` when the PRD is complete.
- **`branch-per-phase`** — Separate branch per implementation phase. Phase branches PR back to the PRD branch. PRD branch PRs back to `{base-branch}` when all phases are complete.

## Base Branch

The base development branch is `{base-branch}`. All top-level feature branches and fix branches originate from and merge back to this branch.
