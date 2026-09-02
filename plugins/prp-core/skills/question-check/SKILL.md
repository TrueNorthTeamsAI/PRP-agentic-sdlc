---
name: question-check
description: Check drafted questions against the project's docs before asking the user anything. Run it whenever you are about to ask the user a question — clarifying, blocking, or a trailing "let me know" — including AskUserQuestion calls and end-of-turn open questions. It launches a separate research agent that sweeps every doc corpus reachable from the workspace (operator memory, CLAUDE.md files, ADRs, PRDs/plans/reports, integration contracts, worktree-local and uncommitted reports) and returns, per question, whether the answer is already written down and where. Answered questions get dropped and the documented answer used; only genuinely unanswered ones reach the user.
---

# Skill: question-check

Kill redundant questions. In a PRP-standard repo most of what you are about to ask is already written down — in an ADR, a PRD, a plan, an integration contract, an investigation report, or the operator's memory. Asking anyway wastes the user's time and signals you didn't look.

Applies to any repo. **The doc corpus is discovered, not hard-coded** — see *Corpus discovery* below; where this skill names a concrete path it is a worked example from the reference implementation (a five-application platform workspace, ~2,200 markdown files), not a fixed location.

**Hard rule: the sweep runs in a separate agent. Never search the corpus inline in the main thread.** Real corpora run to thousands of files; inline searching floods the main context and gets abandoned halfway. One agent, one structured answer back.

## When this fires

Before **any** question reaches the user. That includes:
- `AskUserQuestion` calls — draft the questions, run this first, then ask only the survivors.
- Blocking questions ("I can't proceed until you tell me X").
- Trailing questions at the end of a turn ("do you want me to also…", "which env?", "is Y the intended behaviour?").
- Assumption statements you're about to hedge on ("I'll assume X — confirm?"). That's a question wearing a hat.

**One exemption:** pure authorization asks, where the docs cannot hold the answer because the answer is a decision the user makes right now — "shall I merge this?", "OK to deploy?", "delete this branch?". Those go straight through. Everything else — including preference and process questions ("file an issue or keep the report local?", "does this need an ADR?") — gets checked, because CLAUDE.md files and operator memory record preferences as facts.

If a question mixes both (authorization + a factual unknown), split it: check the factual half, ask the authorization half.

## Procedure

### 1. Draft the questions first
Write them out explicitly, numbered, in the form you'd actually ask. Vague questions get vague sweeps. For each, note what *kind* of answer would settle it: a value, a path, a decision record, a contract, a preference.

### 2. Launch the sweep agent
One `Agent` call, `subagent_type: "general-purpose"`, **`model: "sonnet"`**, `run_in_background: false` — you need the verdicts before writing the response. Use the prompt template below, filling in the questions, the resolved corpus (step 0 below), and any task context needed to interpret them (repo, story id, PR number, files in play).

**Model: Sonnet for the sweep, not Haiku.** The grep half is mechanical, but the verdict half is pure discrimination — does this doc *answer* the question or merely discuss the area, is it superseded, do two finds actually corroborate or just share a keyword. That's the tier where Haiku over-claims, and a false ANSWERED is the worst outcome this skill can produce: the main thread then acts on something the user never said, citing a doc that doesn't support it. A missed answer only costs one question. Escalate to `opus` when the questions are themselves subtle (contradiction-hunting across ADRs, "is this behaviour intentional per spec"). Never drop to Haiku for the full sweep.

If there are more than ~6 questions, still send one agent — it parallelizes internally. Don't fan out one agent per question.

### 3. Act on the verdicts
- **ANSWERED** → drop the question. Use the documented answer, and say where it came from in one clause: "per `docs/decisions/ADR-0009.md`, scoping is claim-only, so …". Never present a documented answer as your own inference.
- **PARTIAL** → don't ask the original question. Ask the narrowed residual only, and lead with what the docs already gave: "Docs say X for dev; nothing covers prod — is prod the same?"
- **UNANSWERED** → ask it, unchanged.
- **STALE** → treat as UNANSWERED but surface the conflict: "`<doc>` says X but it predates `<event>` — still true?"
- **CONFLICT** (two docs disagree) → surface both with paths; that's a finding, not just a question.

If the sweep returns nothing useful for every question, say so in one clause and ask. Do not re-run with reworded questions hoping for a hit — one pass, then ask.

### 4. Fix what the sweep breaks
A sweep that finds a stale instruction file, a wrong memory, or two docs contradicting each other has found a defect, not just an answer. Repair what you own (operator memory, profile CLAUDE.md) in the same turn; report what needs a PR (repo docs). This is where the skill pays for itself twice.

### 5. Never silently swallow a wrong answer
Docs go stale. If a documented answer contradicts what you've observed in this session (live output, test result, actual file contents), the observation wins. Say so explicitly and treat the doc as stale.

## Corpus discovery (step 0 — do this before launching)

Resolve the corpus **once**, cheaply, in the main thread, then hand the resolved paths to the agent. Do not make the agent guess where docs live.

1. **Read the project bindings.** If the workspace or target repo's CLAUDE.md declares doc locations, that list wins. A repo can pin them explicitly:

   ```markdown
   ## question-check corpus
   - tier1: ~/.claude/projects/<slug>/memory/, ./CLAUDE.md, applications/*/CLAUDE.md
   - tier2: docs/decisions/, docs/integrations/, docs/patterns/, docs/runsheets/
   - tier3: PRPs/prds/, PRPs/plans/, PRPs/reports/, PRPs/investigations/
   - tier4: worktrees/*/
   - exclude: .context/payloads/, release-manifests/
   ```

2. **Otherwise apply the PRP-standard defaults**, in priority order:
   - **Tier 1 — operator memory + instructions** (smallest, densest): the active profile's `projects/<slug>/memory/` directory (read its `MEMORY.md` index first — hooks often answer outright, and ⚠️ markers flag known-stale facts), the profile-level `CLAUDE.md`, and `CLAUDE.md` at every level of the tree (workspace root, each application, each worktree).
   - **Tier 2 — decision records + contracts** (authoritative, dated): `docs/decisions/` (ADRs), `docs/integrations/` (external system contracts), `docs/patterns/`, `docs/runsheets/`, `docs/deployments/`, at both workspace and per-application level.
   - **Tier 3 — PRP artifacts**: `PRPs/prds/`, `PRPs/plans/`, `PRPs/reports/`, `PRPs/investigations/`, `PRPs/research/`, `PRPs/user-journeys/` — **including `completed/` subdirectories**, workspace and per-application. PRDs give intent, plans give design, reports give what was actually found.
   - **Tier 4 — worktrees and uncommitted local work**: every worktree pool in use. Review reports and investigation notes frequently exist **only** here, uncommitted — skipping this tier is the most common way a sweep misses a documented answer.
   - **Tier 5 — sibling/adjacent repos and loose worklogs** at the workspace root. Lower priority; flag anything sourced here, and note when a restructure has made it partly stale.
   - Exclude: `node_modules`, `.git`, `dist`, `.next`, `build`, lockfiles, generated payload/manifest data.

3. **Sanity-check the size** (`rg --files -g '*.md' <roots> | wc -l`). Under ~100 files, tell the agent to read the whole tier-1/2 set rather than grepping.

## Sweep agent prompt template

> You are a documentation-recall agent. Your only job: for each question below, determine whether the answer is **already written down** in this project's docs, and return the answer with evidence. You do not answer from your own reasoning, training knowledge, or inference — only from text you actually read. If you cannot point to a file and line, the verdict is UNANSWERED.
>
> **Questions** (verbatim; keep the numbering in your output):
> 1. …
>
> **Task context** (why these are being asked): …
>
> **Corpus** (resolved for you — search in this order, highest signal first):
> - Tier 1: …
> - Tier 2: …
> - Tier 3: …
> - Tier 4: …
> - Tier 5: …
> - Exclude: …
>
> Read `.md`/`.mdx`/`.txt` docs; source code only when a doc points at it and the question is about actual behaviour.
>
> **Live sources count as corroboration, not as the primary sweep.** `gh issue view` / `gh pr view` on a repo a doc already points to, and `git log` for dates, are allowed and often give the strongest second find — an open issue frequently records the current decision better than any committed doc. Label anything sourced that way as live-fetched with the date, and never let it replace the doc sweep.
>
> ### Protocol
> 1. For each question derive 3–6 distinct keyword sets — synonyms, identifiers (story ids, PR/issue numbers, table/column names, env names, hostnames, flag names), and the domain term the docs would actually use.
> 2. Sweep with `rg -il` across tiers (parallelize where you can), then **read** the hits — never verdict off a filename or a grep line alone.
> 3. **Double-check, then triple-check.** ANSWERED requires the answer to be supported by **two independent finds** — two different documents, or one document confirmed by a second search path that didn't rely on the first hit's wording. One lonely hit is PARTIAL at best. Note third corroborations; where the second search actively contradicts the first, that's CONFLICT.
> 4. **Check freshness.** Prefer the newest doc; use the date in its name/frontmatter, `git log` where available, else mtime. Anything superseded by a later doc, or predating a known cutover, is STALE — say what superseded it.
> 5. **Verify existence by listing, not by grepping for the name.** If a question asks whether some document exists, list the directory.
> 6. Don't be generous. A doc that discusses the *area* of the question but not the question is UNANSWERED. Over-claiming is worse than missing: it makes the main thread act on something the user never said.
>
> Budget: aim for under ~60 tool calls. Depth on Tier 1–2 beats breadth on Tier 5.
>
> ### Output — return exactly this, no preamble
> For each question, in order:
>
> ```
> Q<n>: <the question, abbreviated>
> VERDICT: ANSWERED | PARTIAL | UNANSWERED | STALE | CONFLICT
> ANSWER: <the documented answer, stated plainly — or "none">
> EVIDENCE: <path>:<line> — "<short quote>"   (one line per supporting doc; ≥2 for ANSWERED)
> FRESHNESS: <date/commit of newest supporting doc + anything that supersedes it>
> RESIDUAL: <for PARTIAL: the narrowed question that genuinely still needs the user>
> ```
>
> Then a final section:
>
> ```
> CONTRADICTIONS: <docs that disagree with each other, or with the task context — path + what conflicts>
> NOT SEARCHED: <any tier or path you couldn't cover, and why>
> ```
>
> Your final message IS the return value — no chat framing.

## Reporting back to the user

When the sweep pruned questions, say so in one line before the substance — the user should see the check happened and what it saved:

`Docs answered 2 of 3: <a> (per <path>), <b> (per <path>). Still need you on: <c>.`

If it pruned everything, there's no question left to ask — proceed and cite. Don't announce the sweep when it found nothing; just ask the questions.

## Cost

A one-to-two question check on a large corpus runs ~15–20 tool calls and ~80k subagent tokens; four questions with deep residuals roughly doubles that. Cost scales with question count and residual depth, not corpus size. That is cheaper than a wrong assumption and far cheaper than a round-trip through the user — but it is not free, so don't run it on authorization asks (see the exemption) or on questions you've already checked this session.
