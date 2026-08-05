---
name: feature-review
description: Full feature review, pre- or post-merge — context gathering, diff integrity, local-first functional walkthrough, multi-angle adversarially-verified code review, merge-and-deploy gate for unmerged PRs, deployed smoke, findings report, and triaged GitHub issue. Use when the user wants to review a feature or PR (merged, unmerged, or consolidated review-only), or asks "what am I reviewing / did this ship correctly". Triggers: "review PR #N", "review this feature", "test locally then merge then test on dev", "go through the docs and tell me what I'm reviewing", "test all the functionality".
---

# Skill: feature-review

Run a complete review of a feature — merged or not. **Order is local-first**: test locally (on the PR head if unmerged) BEFORE anything merges; merge only after the local walkthrough + code review pass and the user approves; deployed testing comes last, after the merge deploy goes green. The review has **seven phases**; scale to what the user asked for (a quick "what am I reviewing" stops after Phase 2; "review everything" runs all seven). Announce which phases you're running.

Applies to any PRP-standard repo. Repo-specific hooks (seed commands, dev-login, mockup paths, UX doc, design tokens) come from the **target repo's own CLAUDE.md — read it first**; where this skill cites a concrete file or command it is a worked example from the reference implementation (the eventledger FB-005 / PRD022 review: PRs #153/#157 → issue #163, reports `PRPs/reports/PRD022-*` in maxtel-eventledger-poc), not a fixed path. Throughout: lead with outcomes; keep evidence (file:line, screenshots, SQL counts) for the report. Findings are **F-numbered continuing from the feature's previous review reports** — grep the repo's `PRPs/reports/` for existing findings files first so numbering never restarts.

## Phase 0 — Context

1. Read the PRD (`PRPs/prds/`), its plan reports (`PRPs/reports/`), and the PR body (`gh pr view N --json title,body,files`). Extract: acceptance criteria (the AC matrix in the terminal-phase report), declared deviations/deferrals, and the oracle figures (seeded counts/totals the PRD cites).
2. **Cross-repo scope check**: grep the sibling repos' history and files (`git log --all -i --grep`, `git grep -il`) for the PRD/feature-brief id. Report whether the work is self-contained.
3. Check post-merge CI: `gh run list --branch <default>` — did the deploy that shipped this feature go green?

Deliverable: a review brief — what's being reviewed, the passing criteria (AC matrix), what's declared out of scope (do NOT flag declared deviations as bugs).

## Phase 1 — Diff integrity (consolidated / review-only PRs)

For a reconstructed review PR (cherry-picked branch against a frozen baseline): diff the review branch against the default branch restricted to the PR's file set, then attribute every delta to a named later commit (`git log --oneline review-branch..origin/<default> -- <file>`). Every difference must be explained by declared later work; anything unexplained is cherry-pick drift — a finding.

⚠️ Never merge a review-only PR (throwaway base). Close it with an outcome comment at the end (Phase 7).

## Phase 2 — Local functional walkthrough

1. **Unmerged PR? Check out the PR head first** (`gh pr checkout N` or a worktree at the head SHA) — the local test must exercise the branch, not the default branch. Then stack up per the repo's CLAUDE.md (prefer the container stack the PR's own test plan used, e.g. `docker compose --profile app up --build -d`); run migrations + seeds idempotently, then any feature-specific replay seed (mind seed ordering — reference/master data before ingest replays).
2. Verify the oracle figures by direct SQL (`docker exec …psql`) before trusting the UI.
3. Walk every AC in the browser (dev-bypass login where the repo provides one): happy paths, role gates per role (deny paths must *redirect/hide*, not error), and API-level gates with `curl` + dev headers — expect 403 on writes for read-only roles, and test with a **valid** body (an invalid body may 400 before the gate and mask it).
4. **Mockup & style parity** (where the repo has client-intake mockups — this is a gate, not a glance):
   - Locate the feature's mockups (e.g. `client-intake/mockups/<feature>/`) and the PRD's **Mockup Inventory** section — it lists every section per screen with CANONICAL/REFERENCE fidelity; CANONICAL sections are the contract.
   - Serve the mockups over `python3 -m http.server` (the browser extension can't open `file://`) in a tab adjacent to the running app; screenshot both per screen, on the *same record* (drive the mockup's query params to match).
   - Compare **section-by-section from the Mockup Inventory**, and separately compare **style**: button chrome (every action styled as a real button, not bare text), pill colors/shapes, alignment (text left / numerics right — dropdown option lists included), date label format, negative-amount styling, totals/count-line placement, spacing/typography vs the mockup stylesheet and the app's global design tokens (both named in the repo's CLAUDE.md).
   - Output a parity table: **Ships / Deferred-with-reason / Deviation** per section, with style deltas listed explicitly. A functional or style deviation NOT declared in a plan report is a finding (this is how the reference review caught a bare-text Save button and a right-aligned item dropdown); declared ones are context.
   - Grade datagrids/filters/detail screens against the repo's UX patterns doc if it has one (e.g. `docs/ux/patterns.md` — date format, sortable headers, pagination thresholds, text left / numerics right).
5. ⚠️ `window.confirm` freezes the browser extension — stub `window.confirm = () => true` via the JS tool **on the current page** (re-stub after every navigation) before clicking Discard/Confirm-style actions.
6. Create test fixtures with greppable names (`REVIEW-QA-…`) and clean them up, or document what was deliberately left.

## Phase 3 — Multi-angle code review (adversarially verified)

Save the diff to the scratchpad and create a worktree pinned at the PR head so agents read accurate surrounding code.

1. **Finders** — 8 parallel agents, ≤6 candidates each, every candidate `{file, line, summary, failure_scenario}`:
   A. line-by-line hunk scan · B. removed/replaced-behavior audit (incl. any dual-copy artifacts the repo maintains — e.g. duplicated DDL kept in two files) · C. cross-file tracer (callers, contracts, tenant scoping, both-flags invariants) · reuse (vs the repo's shared component/schema homes) · simplification (incl. file/component size caps from CLAUDE.md) · efficiency (N+1, missing indexes, scans under locks, serial awaits) · altitude (bandaids on shared infra) · conventions (quote the governing CLAUDE.md / patterns-doc rule verbatim).
2. **Dedup** against the feature's existing F-findings and merge multi-angle hits.
3. **Verify** — one independent verifier per surviving candidate, forced verdict **CONFIRMED** (quote the trigger) / **PLAUSIBLE** (name what would confirm) / **REFUTED** (quote the disproof). Refuted findings stay in the report under "refuted — do not raise": they save the next reviewer the same rabbit hole.
4. Rank ≤8 findings, correctness before cleanup. Note when a finding is UI-unreachable (API-only exposure) — it changes triage, not validity.

## Phase 4 — Merge gate → deploy → deployed smoke

**If the PR is unmerged**: merging is a gate, not a default. Proceed only when the local walkthrough (Phase 2) and code review (Phase 3) are clean-or-triaged AND the user explicitly approves the merge. Then merge per the repo's convention (`gh pr merge --auto` while checks run), watch the deploy workflow to completion in the background (`gh run watch`), and confirm liveness before smoking. If the deploy fails, stop and report — do not smoke a half-deployed env. (Review-only PRs are never merged — Phase 1 rule.)

Then repeat the critical AC subset on the deployed environment (real auth — the user signs in; dev-bypass is dead in deployed config). Verify: liveness, auth-gating (401 not 404), nav entry, list/detail render with real tenant data, one full write lifecycle if the signed-in role permits. Deliberately-left artifacts get greppable names and a note in the report.

## Phase 5 — Findings report

Write `PRPs/reports/<feature>-review-findings.md` in the target repo (follow the repo's artifact naming): ranked confirmed findings (file:line + trigger + suggested fix), minor/latent below the cut, **refuted** section, cleanup themes (advisory), and a suggested follow-up-PR grouping. Screenshots go in `PRPs/reports/assets/<feature>-review/`. Open the report in the user's editor.

## Phase 6 — Triage with the user

**Pilot triage rubric (when the project is a pilot — calibrate depth and urgency to that):**

- **Non-negotiable, always verified and always fix-now:** the feature brief's / PRD's acceptance criteria actually hold, and **data correctness on the ingest→ledger→report path** (or the project's equivalent core data path) — anything that makes stored or displayed figures wrong (misclassification, unsigned/doubled values, silent row loss, wrong-tenant/concept leakage) is fix-now *even if the triggering data hasn't arrived yet*. Wrong numbers discovered mid-pilot cost more than the fix.
- **Condition-gated (the "making it perfect" tail):** everything else ships as-is unless it demonstrably breaks something in the pilot. Medium-priority findings — latent crash ceilings, API-only exposures needing data shapes that don't exist yet, test-infra hygiene, perf/UX polish, convention debt — get *filed with receipts, not fixed*. Re-gauge them when the pilot graduates or when the area is next touched.
- The review's depth follows the same split: go deep on AC verification and data-path correctness (oracle SQL, replay, cross-grain tie-outs); stay shallow on the rest once it's bucketed.

Present three buckets and let the user draw the line: **fix before pilot/release** (per the rubric: broken ACs + data-correctness defects; plus user-reachable data loss, audit-chain integrity, cheap indexes), **scheduled polish batch** (UX/styling/cosmetic), **fix when the area is next touched** (API-only exposure, fixture regressions, latent-until-data-changes items). Severity ≠ urgency: a UI-unreachable SEVERE can wait; a silent UI data-loss cannot.

## Phase 7 — Close-out (only what the user approves)

- **GitHub issue** for the fix-now bucket: file:line receipts, acceptance criteria per item, evidence screenshots **linked to committed blobs pinned to a SHA** (private-repo raw URLs don't render), deferred items listed as documented-not-blocking.
- **Commit the reports + assets** via a `docs/` branch + PR — the issue's references must resolve for whoever picks it up. ⚠️ Cut branches from **`origin/<default>`** (check `origin/HEAD` — workspaces use both `main` and `master`), never a possibly-stale local branch; prefer a worktree when the checkout is on someone's in-flight branch.
- **Close the review-only PR** with an outcome comment linking the issue and docs PR.
- Update project memory: what passed, what's filed where, artifacts left on shared envs.
- **Board sync:** where the project tracks story state on an external board, invoke the matching board-sync skill (Azure DevOps: `azure-review`) to move the reviewed stories (passed → Ready for Test; failed/split → In Development, with evidence comments linking the GitHub issues). Stories not covered by this review stay untouched.

## Guardrails

- Declared deviations (in plan reports) are context, not findings.
- Don't test destructive/confirm-dialog actions on shared envs without the confirm stub and a cleanup plan.
- Money/quantity assertions come from the oracle (prototype DB / seeded figures), never from the screen alone.
- The review's job ends at findings + triage + issue. Fixing is a separate, user-initiated task.
