# ADR-0001: Verify inherited contracts before depending on them (PRD/plan gate)

- **Status**: Accepted
- **Date**: 2026-06-03
- **Deciders**: Daniel
- **Related**: `prp-prd` command, `prp-plan` command, `maxtel-eventledger-poc` (P019 worked example), every downstream repo that uses the PRP framework

## Context

PRDs and plans generated through the PRP framework routinely reference existing artifacts — database tables and columns, auth middleware, error hierarchies, test fixtures, route groupings — as "locked", "inherited", or "the existing pattern". The framework provides no mechanism that forces the author to verify the inherited artifact actually fits the new use case. Reviewers have to infer the assumption from the file-change list, which means assumption-mismatches survive the design phase invisibly and surface as bugs in production.

The worked example that triggered this ADR sits in `maxtel-eventledger-poc` (a downstream consumer of this framework):

1. **FB-002 brief line 116** wrote SQL referencing `event.utc_begin` — assumed the column existed
2. **PRD007 line 173** echoed the same SQL and stated "the data contract is locked by the PRD006 SALES dim schema" — verified the dim extension table but not the parent `event` row
3. **PRD006** committed to "produce 24 SALES_HR rows" but never named the column that encodes the hour
4. **P019 (schema plan)** was scoped to the dim extension only; the parent `event` table was treated as already-designed, inherited from the WASTE family where `day_part_id` (a band-FK 1–4) is semantically correct
5. **P022 / P023** captured the NZ hour correctly in memory at the parser/aggregator layer and faithfully dropped it at write time against the schema P019 had locked

No plan was ever scoped to ask "does the parent `event` row carry the time-of-day column this new event family needs?" Two consumer-PRDs wrote SQL referencing a column that doesn't exist; three plans implemented around the omission without flagging it. Result: production SALES drilldown collapses 24 hours of trading into 4 band-shaped buckets because there is nowhere on the event row to store the hour 0–23 cleanly.

Schema is the obvious instance. The same anti-pattern applies to any inherited contract: auth middleware ("the existing JWT layer will set the tenant context we need" — without checking), error hierarchies ("we'll extend `BaseError`" — without checking the fields the new surface needs), test fixtures and seeds ("we'll reuse `phase5.seed.ts`" — without checking the constants encode the assumption the new code makes), route grouping ("we'll mount under `/api`" — without checking the global-prefix interaction). The leverage point for fixing the pattern is the framework, not any individual downstream repo.

This ADR lives in the `prp-agentic-sdlc` repo because the decision is internal to this framework — the gate is implemented here, the templates live here, and the override semantics are defined here. Downstream repos consume the gate transparently through the plugin; they do not have to know how it works.

## Decision

A schema-fitness gate is added to the PRP framework at both the PRD and Plan generation steps. The gate enforces a single principle: **verify what you inherit; do not assume it.**

Two concrete gate mechanisms ship in the first iteration:

1. **`/prp-prd`** (Phase 6.5) scans the PRD draft and input brief for `table.column` patterns, `event_type = 'X'` strings, and ORM-style identifiers (Drizzle / Prisma / SQLAlchemy / TypeORM). Each reference is cross-referenced against the project's schema files. The command emits a "Schema References" section in the PRD listing every reference, whether it resolved, and the semantic assumption made. A reference that does not resolve blocks PRD output (with an explicit `--skip-schema-check` override flag that is logged in the PRD).

2. **`/prp-plan`** (Phase 5.5) requires an "Existing Schema Dependencies" section. Every existing table or column the plan reads or writes (whether or not the plan modifies it) must be listed with three fields: name, semantic assumption, and a "verified by" citation (test file:line, schema comment, ADR number, or `TODO: verify before merge`). The command blocks plan output if any `TODO:` remains, with the same `--skip-schema-check` override semantics.

Schema is the first concrete domain the gate covers; the broader principle ("verify what you inherit") is recorded here so future ADRs may extend the gate to other inherited contracts (auth, errors, fixtures, route grouping) without re-litigating the why. Forward-scope domains are explicitly out of v1 — they are named in the originating brief's "Forward Concerns" section as the second-iteration scope.

Schema source detection is configurable per downstream project via a `## Schema Sources` section in that project's `CLAUDE.md`. If absent, the gate falls back to sane defaults for Drizzle / Prisma / SQLAlchemy / TypeORM / raw SQL migrations. Greenfield projects with no schema files are a no-op.

## Consequences

**Easier**:

- Future PRDs and plans that reference inherited schemas surface the assumption in a named, scannable section before merge. Reviewers stop having to infer intent from file-change lists.
- The next P019-shape bug is caught at design time, not in production. Cross-family semantic collisions (one column with two meanings across event types) become mechanical to detect rather than eyeball-dependent.
- Every downstream project picks up the gate on first use of the framework — no onboarding step, no per-repo CLAUDE.md drift.
- The "Schema References" / "Existing Schema Dependencies" sections become a durable artifact in every PRD and plan: an in-tree record of what the author was assuming at design time, useful for future debugging and onboarding.
- Anchors the broader principle ("verify what you inherit") in a single place so subsequent iterations extending the gate to other inherited contracts have a recorded why to reference.

**Harder**:

- PRD and plan generation requires more author content. For projects with a high authoring volume the gate adds an estimated 5–10% authoring time per artifact.
- Schema-source detection has to be configurable per project: Drizzle / Prisma / SQLAlchemy / Java JPA / raw SQL migrations all live in different file shapes. The gate ships with sane defaults but configuration via project CLAUDE.md is required for non-default setups.
- The `--skip-schema-check` override becomes a temptation. PR-review discipline is the secondary gate; CI cannot enforce the *content* of the schema-references section, only that the section is present.
- Initial false positives are likely (a column referenced as a comment, a temporary variable named after a column). The gate needs an explicit allowlist mechanism in CLAUDE.md or the command's frontmatter as a follow-up.

**Operational**:

- The framework ships a new minor version with the gate. Every downstream project picks up the gate on next plugin update.
- This repo's `CLAUDE.md` gains a one-line pointer to this ADR. New project scaffolds (`/prp-core:init-project`) reference the gate in the generated CLAUDE.md.
- No per-environment cost — the gate runs at authoring time only, not at build, deploy, or runtime.

**Migration cost if reversing later**: low. Revert the gate PR. Templates lose the new sections; runtime check disappears. Existing PRDs and plans that have the sections keep them as plain markdown — no data loss, no schema migration. About an hour of work plus a plugin version bump.

## Alternatives Considered

- **Per-repo CLAUDE.md guidance only** — write the "verify what you inherit" principle into each downstream repo's CLAUDE.md. Rejected because the same authors who got P019 wrong have CLAUDE.md available and didn't grep the schema. Norm-setting without enforcement does not change behaviour at scale; the framework is the leverage point.
- **Schema-only fix in `maxtel-eventledger-poc`'s CLAUDE.md** — closer to the incident, lowest ceremony. Rejected because the pattern will recur in every future TNT project that scaffolds against an existing data model. Fixing it in one downstream repo is wallpapering.
- **Template enrichment with no runtime check** — add the required sections to the templates but enforce nothing. Rejected because the failure mode here is not ignorance, it is optimism. Three authors at three stages all assumed `event.utc_begin` existed and none of them grep'd the schema. A required section those same authors fill in without grepping does not change much. The template addition only works paired with an automated check.
- **A specialized `/prp-core:prp-schema-audit` subagent invoked manually** — heavier engineering, opt-in by author. Rejected because opt-in gates are skipped on the days they matter most (last-minute submission, "I'll fix it in the next PR"). The gate has to be opt-out to bind.
- **Wider scope in v1 — gate auth flows, error hierarchies, fixtures, routes simultaneously** — comprehensive but unbounded. Rejected as too much for one iteration. Schema is concrete and testable; the broader inheritance domains are named here as forward scope and can be added by subsequent ADRs once the schema gate is bedded in.
- **Static-analysis auto-generation of the "Existing Schema Dependencies" section** (no required author input) — zero authoring cost. Rejected because the *point* of the section is to capture the semantic assumption, which a parser cannot infer. The author has to write down what they think a column means. Static analysis can verify the column *exists*; it cannot verify it means what the plan assumes.
- **Workspace-scope ADR** — the original draft of this ADR lived at the workspace ledger because the gate is consumed by every TNT repo. Demoted to per-repo scope because the decision is internal to this framework: the gate is implemented here, configured here, and overridden here. Downstream repos consume it transparently. If the principle gets adopted as a cross-repo standard beyond schema fitness, promote a follow-up ADR to the workspace ledger per the workspace promotion rule.
