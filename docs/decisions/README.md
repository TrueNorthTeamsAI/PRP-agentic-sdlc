# Architecture Decision Records — `prp-agentic-sdlc`

This directory holds **per-repo ADRs** — decisions internal to the `prp-agentic-sdlc` framework itself (how the plugin behaves, what its commands enforce, how artifacts are structured).

Workspace-scope ADRs (decisions affecting multiple repos) live at the workspace ledger: `../../../docs/decisions/` (relative to this repo).

## Index

| Number | Title | Status | Related |
|---|---|---|---|
| [ADR-0001](0001-verify-inherited-contracts.md) | Verify inherited contracts before depending on them (PRD/plan gate) | Accepted | prp-prd, prp-plan, maxtel-eventledger-poc (P019 worked example), every downstream repo |

## How to add a new ADR

1. Read the workspace `truenorthteams/CLAUDE.md` "Decision Ledger (ADRs)" section for the rules.
2. Copy `_template.md` as the starting point.
3. Pick the next free integer (`max(N) + 1` from this index — numbers never reuse).
4. Add a row to the table above with Number, Title, Status, Related.
5. Open a PR. Status flips from `Proposed` to `Accepted` on merge.

Supersede with a new ADR rather than rewriting history. Leave the original in place with `Status: Superseded by ADR-NNNN`.

### When per-repo vs. workspace

- **Per-repo** (here): the decision is internal to this framework. Example: how the plugin's commands enforce content gates; how artifacts are numbered; what the override semantics for a flag are.
- **Workspace** (`../../../docs/decisions/`): the decision affects more than one repo. Example: cross-repo contracts; layering boundaries between platform and application repos; shared auth models.

If a per-repo ADR is later adopted by a second app, promote it to the workspace ledger and leave a pointer in the original location.
