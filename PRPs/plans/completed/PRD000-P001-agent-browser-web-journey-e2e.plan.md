# Feature: agent-browser as the web-journey e2e engine

## Summary

Add **agent-browser** (the installed Vercel Agent Browser CLI, v0.27.0) as a recognized **third e2e testing framework** across the `prp-core` plugin, alongside `Playwright | Cypress | none`. Today the framework models e2e as a strict two-way branch — "code framework configured → run `npx playwright test`" vs "no framework → curl-based bash Validation Scripts" — which leaves genuine **web-UI journeys with no code framework** stranded in the **Manual / non-blocking** bucket (`prp-plan.md:405`, `prp-implement.md:360`). This plan ships a shared internal skill (`e2e-browser`) that encodes the methodology for driving a `type: web` journey via agent-browser and for the Level-6 visual-parity walk, then wires a third branch arm into every existing e2e/journey touchpoint. It is **opt-in and config-gated**: projects that don't set `Framework: agent-browser` behave exactly as before.

## User Story

As a **developer using the PRP framework on a web app that has no committed Playwright/Cypress suite**
I want **agent-browser recognized as a first-class e2e engine that the plan/implement/ralph loop knows how to drive**
So that **my web-UI journeys become automated and blocking instead of being punted to "requires manual verification," and the Level-6 visual-parity check becomes a repeatable screenshot walk instead of a vague "open a browser tab" instruction.**

## Problem Statement

The e2e framework identity is a closed two-value branch throughout the plugin. A `type: web` journey is only "Automated (blocking)" if (a) a code e2e framework is installed, or (b) the flow reduces to `curl` API calls. A real browser flow (click a button, assert DOM text, follow JS routing) with no installed Playwright/Cypress has **no automated path** and falls to Manual/non-blocking (traced: `prp-plan.md:399-405`, `templates/user-journey.md:65-101` shows curl-only, `prp-implement.md:340-360`). This is testable: after this change, a project with `Framework: agent-browser` must produce a blocking automated web journey and drive it during implement/ralph.

## Solution Statement

Introduce a third recognized value, `agent-browser`, and a shared skill that both authors (journey → agent-browser command sequence) and executes (run the sequence, assert, screenshot). Thread the third branch arm through the six consumer touchpoints and keep the three execution paths (`prp-implement`, `prp-ralph`, `build-with-agent-team`) in sync per the CLAUDE.md mandate. The skill is the single source of methodology; the commands only *reference* it, so the logic lives in one place and does not drift.

## Metadata

| Field            | Value                                                                 |
| ---------------- | --------------------------------------------------------------------- |
| Type             | NEW_CAPABILITY                                                        |
| Complexity       | MEDIUM                                                                |
| Systems Affected | prp-core plugin: 4 commands, 2 skills (1 new), 1 template             |
| Dependencies     | agent-browser CLI v0.27.0 (already installed at `~/.local/...`; consumer projects must install it) |
| Estimated Tasks  | 9                                                                     |
| Source PRD       | N/A (free-form input)                                                 |
| PRD Phase        | N/A                                                                   |

---

## UX Design

### Before State

```
╔══════════════════════════════════════════════════════════════════════════╗
║                             BEFORE STATE                                   ║
╠══════════════════════════════════════════════════════════════════════════╣
║  E2E config value ∈ { Playwright | Cypress | none }   (prp-prd.md:825)     ║
║                                                                            ║
║   web journey ─┬─ framework configured ──► npx playwright test  (blocking) ║
║                └─ no framework ──► bash Validation Script (curl, API-only) ║
║                                    │                                       ║
║                                    ▼                                       ║
║              a real browser-UI flow can't be expressed in curl            ║
║                                    │                                       ║
║                                    ▼                                       ║
║              falls to MANUAL / non-blocking  (prp-plan.md:405)            ║
║                                                                            ║
║  Level 6 visual parity: "open each route in a browser tab" (manual/vague) ║
║  PAIN: web journeys silently non-blocking; visual parity not automatable  ║
╚══════════════════════════════════════════════════════════════════════════╝
```

### After State

```
╔══════════════════════════════════════════════════════════════════════════╗
║                              AFTER STATE                                   ║
╠══════════════════════════════════════════════════════════════════════════╣
║  E2E config ∈ { Playwright | Cypress | agent-browser | none }             ║
║                                                                            ║
║   web journey ─┬─ Playwright/Cypress ──► npx playwright test   (blocking)  ║
║                ├─ agent-browser ──► invoke skill: e2e-browser  (blocking)  ║
║                │        └─ open → snapshot -i → click/fill → assert → exit ║
║                └─ none ──► curl Validation Script (API journeys)          ║
║                                                                            ║
║   ┌───────────────────────┐                                               ║
║   │ NEW skill: e2e-browser │ ◄── journey→command translation + assertions ║
║   └───────────────────────┘     + Level-6 screenshot-vs-mockup walk       ║
║                                                                            ║
║  VALUE: web journeys are automated & blocking without a code test suite;  ║
║         Level 6 becomes a repeatable agent-browser screenshot walk        ║
╚══════════════════════════════════════════════════════════════════════════╝
```

### Interaction Changes

| Location | Before | After | User Impact |
|----------|--------|-------|-------------|
| `prp-prd.md` E2E enum (`:825`, `:889-918`) | `{Playwright \| Cypress \| none \| TBD}` | adds `agent-browser` | PRD + CLAUDE.md can record agent-browser as the engine |
| `prp-plan.md` Phase 4.5 / Level 5 (`:399-405`, `:1117-1131`) | web journey → Manual if no code framework | third arm: framework=agent-browser → skill-driven, Automated/blocking | web journeys stop being silently non-blocking |
| `prp-plan.md` Level 6 (`:1133-1150`) | "open each route in a browser tab" (manual) | optional agent-browser screenshot capture per row when configured | visual parity is repeatable |
| `templates/user-journey.md` (`:65-101`) | curl-only Validation Script | adds an "Agent-Browser Validation" variant for `type: web` | web journeys get a runnable, browser-driven script |
| `prp-implement.md` §4.6 / `prp-ralph.md` §3.4 | 2-way branch | 3-way branch invoking the skill | implement & ralph actually drive the browser flow |

---

## User Journeys

| Journey File | Impact | Description |
|-------------|--------|-------------|
| `.claude/user-journeys/agent-browser-e2e-engine.md` | NEW | Verifies agent-browser is wired through every e2e touchpoint + the skill exists |

**Automated** (validation script — blocking):
- `.claude/user-journeys/agent-browser-e2e-engine.md` — grep-based consistency check across the six consumers + skill presence. This repo has **no** code e2e framework, so this journey ships a bash Validation Script (exit 0 = PASS).

**Manual** (require human testing — non-blocking):
- None. (The live browser-driving payoff is exercised in a downstream consumer repo, not in this prompt-only repo.)

---

## How to Execute

<!-- This feature edits markdown prompt files. "Execution" = validating file content, not running a server. -->

### Start Services
```bash
# None. No runtime service.
cd "$(git rev-parse --show-toplevel)"   # PRP-agentic-sdlc repo root
```

### Seed Data / Reset State
```bash
# None.
```

### Verify Ready
```bash
test -d plugins/prp-core && echo "plugin tree present"
```

### Teardown
```bash
# None.
```

---

## Mandatory Reading

**CRITICAL: Implementation agent MUST read these before starting any task:**

| Priority | File | Lines | Why Read This |
|----------|------|-------|---------------|
| P0 | `~/.claude/skills/agent-browser/SKILL.md` | all | The agent-browser CLI reference — the vocabulary the new skill wraps (open/snapshot -i/click/fill/get text/is visible/screenshot/wait/--json) |
| P0 | `plugins/prp-core/commands/prp-plan.md` | 379-413, 1117-1150 | Phase 4.5 + Level 5/6 — the exact branch text to extend |
| P0 | `plugins/prp-core/commands/prp-implement.md` | 279-291, 327-362 | §4.2.1 + §4.6 — the 2-way branch to make 3-way |
| P0 | `plugins/prp-core/commands/prp-ralph.md` | 246-271 | §3.4 validate block — mirror the implement change |
| P1 | `plugins/prp-core/commands/prp-prd.md` | 813-830, 889-918, 1055 | E2E enum + Phase 7.5 CLAUDE.md persistence + success criterion |
| P1 | `plugins/prp-core/templates/user-journey.md` | 1-7, 65-102 | frontmatter `type` + the curl-only Validation Script to add a variant beside |
| P1 | `plugins/prp-core/skills/context-read/SKILL.md` | 1-4 | Internal-skill frontmatter pattern to MIRROR (`user-invocable: false`) |
| P1 | `plugins/prp-core/skills/build-with-agent-team/SKILL.md` | 410-428 | existing bare `agent-browser` mention (`:425`) to align with the new skill |
| P2 | `plugins/prp-core/skills/prp-ralph-loop/SKILL.md` | 195-212, 467-483 | ralph-loop KB that mirrors prp-ralph's e2e handling |

**External Documentation:**
| Source | Section | Why Needed |
|--------|---------|------------|
| `~/.claude/skills/agent-browser/SKILL.md` (installed CLI v0.27.0) | Core workflow, Interactions, Get information, Check state, Screenshots, Wait, `--json` | Canonical command reference; no web fetch needed — the tool is local and this file is authoritative |

**Context Sources Loaded** (from `context-map.md`): _None — no context-map.md in this repo._

---

## Patterns to Mirror

**INTERNAL_SKILL_FRONTMATTER** (invoked by commands, not the user):
```yaml
# SOURCE: plugins/prp-core/skills/context-read/SKILL.md:1-4
# COPY THIS PATTERN (add allowed-tools because this skill shells out to agent-browser):
---
name: context-read
description: "Non-interactive context loader — ... No user prompts."
user-invocable: false
---
```

**THE TWO-WAY BRANCH TO EXTEND (Level 5)** — this is the exact shape a third arm gets inserted into:
```markdown
# SOURCE: plugins/prp-core/commands/prp-plan.md:1121-1131
**If e2e framework configured** (from CLAUDE.md `## Testing` section):
```bash
{e2e run command from CLAUDE.md, e.g., npx playwright test, npx cypress run}
```

**If no e2e framework** (validation scripts only):
1. Run setup from "How to Execute" ...
**EXPECT**: All e2e tests or validation scripts pass (exit 0). Manual journeys ... non-blocking.
```

**THE E2E ENUM (single source of the closed value list)**:
```markdown
# SOURCE: plugins/prp-core/commands/prp-prd.md:824-828
### E2E Testing
- **Framework**: {Playwright | Cypress | none | TBD}
- **Config**: `{path to config file, or "N/A"}`
- **Run**: `{npx playwright test | etc.}`
```

**THE JOURNEY VALIDATION-SCRIPT PATTERN (bash, exit 0 = PASS)** the agent-browser variant sits beside:
```bash
# SOURCE: plugins/prp-core/templates/user-journey.md:79-101
#!/bin/bash
set -euo pipefail
# ...curl assertions...
echo "JOURNEY PASS: {journey-name}"
```

**AGENT-BROWSER COMMAND VOCABULARY** the skill wraps:
```bash
# SOURCE: ~/.claude/skills/agent-browser/SKILL.md:11-16, 46-84, 88-92, 227-233
agent-browser open <url>
agent-browser snapshot -i            # interactive elements with @refs
agent-browser click @e1 ; agent-browser fill @e2 "text"
agent-browser get text @e1 ; agent-browser is visible @e1
agent-browser screenshot path.png ; agent-browser wait --url "**/dashboard"
agent-browser <cmd> --json           # machine-readable for assertions
agent-browser close
```

---

## Files to Change

| File | Action | Justification |
|------|--------|---------------|
| `plugins/prp-core/skills/e2e-browser/SKILL.md` | CREATE | The shared engine: journey→agent-browser translation, assertion conventions, Level-6 screenshot walk, install/precondition checks |
| `plugins/prp-core/commands/prp-prd.md` | UPDATE | Add `agent-browser` to E2E enum (`:825`), discovery hints (`:242`), and Phase 7.5 CLAUDE.md persistence (`:906-911`) |
| `plugins/prp-core/templates/user-journey.md` | UPDATE | Add an "Agent-Browser Validation" section variant beside the curl Validation Script (`:65-102`), for `type: web` |
| `plugins/prp-core/commands/prp-plan.md` | UPDATE | Third arm in Phase 4.5 classification (`:399-405`), Level 5 (`:1121-1131`), Level 6 (`:1133-1150`); note in E2E Tests table comment (`:1057-1060`) |
| `plugins/prp-core/commands/prp-implement.md` | UPDATE | Third arm in §4.2.1 (`:279-291`) and §4.6 (`:340-360`) |
| `plugins/prp-core/commands/prp-ralph.md` | UPDATE | Third arm in §3.4 validate block (`:248-259`) |
| `plugins/prp-core/skills/build-with-agent-team/SKILL.md` | UPDATE | Point the existing `:425` agent-browser mention at the new skill; add the framework arm to Step 6 validation so it stays in sync |
| `plugins/prp-core/skills/prp-ralph-loop/SKILL.md` | UPDATE | Mirror prp-ralph's third arm in the KB (`:202`, `:467-468`) |
| `.claude/user-journeys/agent-browser-e2e-engine.md` | CREATE (done in Phase 4.5) | Automated consistency journey for this feature |

---

## NOT Building (Scope Limits)

- **Not replacing Playwright/Cypress.** agent-browser is an additional value, not a default. Projects already on a code framework are untouched.
- **Not auto-installing agent-browser.** Consumer projects install it themselves; the skill *detects* absence and fails loudly (no silent fallback to Manual).
- **Not building a pixel-diff/visual-regression engine.** Level 6 stays a human-owned parity *walk*; agent-browser only makes the screenshot capture repeatable.
- **Not fixing the pre-existing build-with-agent-team divergence** beyond adding the agent-browser arm — its lack of a formal framework/no-framework branch (vs prp-implement/ralph) is noted but a broader refactor is out of scope.
- **Not touching** non-e2e commands (debug, review, commit, pr, vision, whats-next, etc. — confirmed zero e2e hits).

---

## Step-by-Step Tasks

Execute in order. There is no compiler; **VALIDATE** steps are grep/structure assertions plus the journey script.

### Task 1: CREATE `plugins/prp-core/skills/e2e-browser/SKILL.md`

- **ACTION**: CREATE the shared engine skill (flat dir, single SKILL.md — mirrors every other prp-core skill).
- **IMPLEMENT** frontmatter:
  ```yaml
  ---
  name: e2e-browser
  description: "Drive a type:web user journey with the agent-browser CLI — translate journey steps into open/snapshot/click/fill/assert sequences, and run the Level-6 screenshot-vs-mockup parity walk. Invoked by prp-plan/prp-implement/prp-ralph when the project's e2e Framework is agent-browser. Not user-facing."
  user-invocable: false
  allowed-tools: Bash(agent-browser:*)
  ---
  ```
- **IMPLEMENT** body sections:
  1. **Preconditions / fail-loud check**: `command -v agent-browser` (or `npx agent-browser --version`); if absent AND framework=agent-browser → **STOP with an explicit error** ("e2e Framework is agent-browser but the CLI is not installed: `npm i -g agent-browser`"). Never silently downgrade to Manual.
  2. **Journey → command translation**: how to turn each journey Step (Action/Expected) into `open`/`snapshot -i`/`click @ref`/`fill @ref`/`wait`, and each Expected into an assertion via `get text`/`is visible`/`get url` + `--json`, returning non-zero on mismatch. Exit 0 = PASS (same contract as the curl Validation Script).
  3. **Auth/state reuse**: reference `state save/load` for logged-in journeys (`agent-browser SKILL.md:202-217`).
  4. **Level-6 visual-parity assist**: `open {route}` + `screenshot route.png`; open the mockup; walk the Mockup Fidelity Checklist row-by-row. Explicit: screenshots assist the human walk — this is NOT auto-pass.
  5. **Teardown**: `agent-browser close`.
- **MIRROR**: frontmatter shape from `skills/context-read/SKILL.md:1-4`; command vocabulary from `~/.claude/skills/agent-browser/SKILL.md`.
- **GOTCHA**: prp-core skills conventionally omit `allowed-tools`; this skill is a deliberate ADAPTED exception because it shells out to the CLI — mirror the standalone `~/.claude/skills/agent-browser/SKILL.md:4` (`allowed-tools: Bash(agent-browser:*)`). Document the deviation in a comment.
- **VALIDATE**: `test -f plugins/prp-core/skills/e2e-browser/SKILL.md && grep -q "name: e2e-browser" plugins/prp-core/skills/e2e-browser/SKILL.md && grep -q "Bash(agent-browser" plugins/prp-core/skills/e2e-browser/SKILL.md`

### Task 2: UPDATE `plugins/prp-core/commands/prp-prd.md` — enum + discovery + persistence

- **ACTION**: Add `agent-browser` as a recognized value in three places.
- **IMPLEMENT**:
  - `:825` enum → `{Playwright | Cypress | agent-browser | none | TBD}`; update the `- **Approach**` line (`:828`) to mention agent-browser drives journeys directly without spec files.
  - Discovery hint (`:242-243`): add "agent-browser CLI available (`agent-browser --version`) / journeys authored as agent-browser command sequences" to what the grounding agent looks for.
  - Phase 7.5 persisted `### E2E Tests` block (`:906-911`): allow `Framework: agent-browser` with `Config: N/A` and `Run: (skill: e2e-browser)`.
- **MIRROR**: existing enum line `:825`.
- **GOTCHA**: `agent-browser` has no config file — the `Config` field is `N/A`; don't require a config path.
- **VALIDATE**: `grep -q "agent-browser" plugins/prp-core/commands/prp-prd.md`

### Task 3: UPDATE `plugins/prp-core/templates/user-journey.md` — Agent-Browser Validation variant

- **ACTION**: Add a new optional section "## Agent-Browser Validation" beside the curl "## Validation Script" (`:65-102`), for `type: web` journeys when Framework=agent-browser.
- **IMPLEMENT**: an HTML-comment guide + a fenced example: `agent-browser open ...` → `snapshot -i` → `click/fill` → assert with `get text --json` / `is visible` → non-zero on mismatch → `echo "JOURNEY PASS: {name}"`. Keep the exit-0 = PASS contract identical to the bash script.
- **MIRROR**: the exit-code + `JOURNEY PASS:` convention at `templates/user-journey.md:91-101`.
- **GOTCHA**: keep the curl Validation Script as-is for `type: api`/`cli`; the two variants coexist. Note in the comment that exactly one applies per journey based on `type` + configured framework.
- **VALIDATE**: `grep -q "Agent-Browser Validation" plugins/prp-core/templates/user-journey.md`

### Task 4: UPDATE `plugins/prp-core/commands/prp-plan.md` — Phase 4.5 classification third arm

- **ACTION**: In the "Automated vs Manual" classification (`:399-405`, `:782-786`), add that `type: web` journeys are **Automated (blocking)** when Framework=agent-browser (authored as an Agent-Browser Validation section), not Manual.
- **IMPLEMENT**: extend the bullet at `:399-400` with a third case; extend the "Automated (blocking)" note at `:782` to include "agent-browser command sequences".
- **MIRROR**: existing bullet phrasing at `:399-400`.
- **GOTCHA**: don't remove the "Manual = visual design feel" case — genuine judgment journeys stay Manual.
- **VALIDATE**: `grep -q "agent-browser" plugins/prp-core/commands/prp-plan.md`

### Task 5: UPDATE `plugins/prp-core/commands/prp-plan.md` — Level 5 + Level 6 third arm

- **ACTION**: Add the third branch to Level 5 (`:1117-1131`) and reference the skill in Level 6 (`:1133-1150`).
- **IMPLEMENT**:
  - Level 5: after the Playwright/Cypress arm, add **"If Framework is `agent-browser`"** → invoke the `e2e-browser` skill to run each automated web journey's Agent-Browser Validation; keep **EXPECT: exit 0** (`:1131`).
  - Also update the `### E2E Tests to Write` comment (`:1057-1060`) to note agent-browser journeys need no `.spec.ts` file — the journey doc + skill are the coverage.
  - Level 6 step 2 (`:1140`): make the "open each route in a browser tab" step note that when Framework=agent-browser, the `e2e-browser` skill captures the screenshots for the walk.
- **MIRROR**: the two-arm structure at `:1121-1131`.
- **GOTCHA**: Level 6 must still say screenshots ASSIST the human walk — do not let agent-browser auto-pass visual parity (preserve the `:1150` rationale).
- **VALIDATE**: `grep -c "agent-browser" plugins/prp-core/commands/prp-plan.md` returns ≥ 3 (Phase 4.5, Level 5, Level 6).

### Task 6: UPDATE `plugins/prp-core/commands/prp-implement.md` — §4.2.1 + §4.6 third arm

- **ACTION**: Add the agent-browser arm to E2E Test Generation (`:279-291`) and Journey/E2E Validation (`:340-360`).
- **IMPLEMENT**:
  - §4.2.1: note that when Framework=agent-browser there are no `.spec.ts` files to generate — journeys carry Agent-Browser Validation sections instead; skip generation, don't skip validation.
  - §4.6 "Run validation": add third case → **If Framework=agent-browser**: invoke `e2e-browser` skill per automated web journey; PASS/FAIL by exit code. This makes web journeys **blocking**, so the "requires manual verification / non-blocking" fallback (`:360`) applies only to true Manual journeys.
- **MIRROR**: the two-arm block at `:340-350`.
- **GOTCHA**: keep the prerequisite (`:329` — 4.1-4.3 must pass first) and teardown ordering unchanged.
- **VALIDATE**: `grep -q "agent-browser" plugins/prp-core/commands/prp-implement.md`

### Task 7: UPDATE `plugins/prp-core/commands/prp-ralph.md` — §3.4 third arm (SYNC with Task 6)

- **ACTION**: Mirror the Task 6 §4.6 change in the ralph validate block (`:248-259`).
- **IMPLEMENT**: add step "**If Framework=agent-browser**: invoke `e2e-browser` skill for each automated web journey" to the numbered list (`:248-253`) and reflect it in the example block (`:255-260`).
- **MIRROR**: exactly the wording chosen in Task 6 (three-path sync mandate, CLAUDE.md).
- **GOTCHA**: this is the sync-contract touchpoint — the wording must match prp-implement §4.6 so the paths don't drift.
- **VALIDATE**: `grep -q "agent-browser" plugins/prp-core/commands/prp-ralph.md`

### Task 8: UPDATE `plugins/prp-core/skills/build-with-agent-team/SKILL.md` — align + SYNC

- **ACTION**: Point the existing bare mention (`:425`) at the new skill and add the framework arm to Step 6 validation (`:305-397`).
- **IMPLEMENT**: `:425` → "use the `e2e-browser` skill for UI testing (when the project's e2e Framework is agent-browser)"; add a short note in Step 6 that web-journey validation follows the same three-way framework branch as prp-implement §4.6.
- **MIRROR**: Task 6 wording (sync mandate).
- **GOTCHA**: don't attempt to restructure this skill's validation into the full framework/no-framework branch — just add the agent-browser reference (scope limit).
- **VALIDATE**: `grep -q "e2e-browser" plugins/prp-core/skills/build-with-agent-team/SKILL.md`

### Task 9: UPDATE `plugins/prp-core/skills/prp-ralph-loop/SKILL.md` — mirror KB

- **ACTION**: Reflect the third arm in the ralph-loop knowledge base (`:202`, `:467-468`).
- **IMPLEMENT**: `:202` → note automated web journeys via agent-browser exit 0 like any other; `:467-468` validation-commands snippet → mention the agent-browser path.
- **MIRROR**: prp-ralph §3.4 wording from Task 7.
- **GOTCHA**: keep "Manual journeys are non-blocking" (`:202`) intact.
- **VALIDATE**: `grep -q "agent-browser" plugins/prp-core/skills/prp-ralph-loop/SKILL.md`

---

## Testing Strategy

### Unit Tests to Write

| Test File | Test Cases | Validates |
|-----------|-----------|-----------|
| _N/A_ | Markdown prompt files — no unit-testable code | — |

### E2E Tests to Write

<!-- This repo has no code e2e framework; the journey Validation Script (grep-based) is the coverage. -->

| Test File | Journey Source | Test Cases |
|-----------|---------------|------------|
| _N/A — Validation Script_ | `.claude/user-journeys/agent-browser-e2e-engine.md` | enum present; skill exists w/ frontmatter; all six consumers carry the arm |

### Edge Cases Checklist

- [ ] Framework=agent-browser but CLI not installed → skill STOPS with explicit error (no silent Manual fallback)
- [ ] Framework=none → behavior byte-identical to today (curl scripts; web flows still Manual)
- [ ] Framework=Playwright → untouched; still runs `npx playwright test`
- [ ] `type: api`/`cli` journey with Framework=agent-browser → still uses curl Validation Script, not the browser variant
- [ ] Level 6 with agent-browser → screenshots captured but human still walks the checklist (no auto-pass)
- [ ] All three execution paths (implement/ralph/agent-team) carry matching wording (sync mandate)

---

## Validation Commands

### Level 1: STATIC_ANALYSIS

```bash
cd "$(git rev-parse --show-toplevel)"
# No linter for prompt files. Structural check: new skill dir is flat with a SKILL.md.
test -f plugins/prp-core/skills/e2e-browser/SKILL.md && echo "skill present"
# Frontmatter well-formed (name + allowed-tools):
grep -q "name: e2e-browser" plugins/prp-core/skills/e2e-browser/SKILL.md \
  && grep -q "Bash(agent-browser" plugins/prp-core/skills/e2e-browser/SKILL.md \
  && echo "frontmatter OK"
```
**EXPECT**: Exit 0; both lines print.

### Level 2: UNIT_TESTS

```bash
# N/A — no code units.
echo "no unit tests (prompt-only feature)"
```
**EXPECT**: N/A.

### Level 3: FULL_SUITE

```bash
# "Build" = every consumer references agent-browser (the wiring is complete).
cd "$(git rev-parse --show-toplevel)"
for f in \
  plugins/prp-core/commands/prp-prd.md \
  plugins/prp-core/commands/prp-plan.md \
  plugins/prp-core/commands/prp-implement.md \
  plugins/prp-core/commands/prp-ralph.md \
  plugins/prp-core/templates/user-journey.md \
  plugins/prp-core/skills/prp-ralph-loop/SKILL.md ; do
  grep -q "agent-browser" "$f" || { echo "MISSING arm: $f"; exit 1; }
done
grep -q "e2e-browser" plugins/prp-core/skills/build-with-agent-team/SKILL.md || { echo "MISSING skill ref: build-with-agent-team"; exit 1; }
echo "all consumers wired"
```
**EXPECT**: "all consumers wired", exit 0.

### Level 4: DATABASE_VALIDATION

N/A — no database.

### Level 5: USER_JOURNEY_VALIDATION

```bash
# This repo has no code e2e framework → run the journey's Validation Script.
bash <(sed -n '/^```bash$/,/^```$/p' .claude/user-journeys/agent-browser-e2e-engine.md | sed '1d;$d')
# Or manually: copy the Validation Script from the journey doc and run it.
```
**EXPECT**: `JOURNEY PASS: agent-browser-e2e-engine`, exit 0.

### Level 6: VISUAL_PARITY

**Skip** — no `## Mockup Fidelity Checklist` (this is a prompt-engineering feature, no UI).

### Level 7: MANUAL_VALIDATION

1. Read the new `e2e-browser/SKILL.md` end-to-end; confirm the fail-loud precondition, the journey→command translation, and the Level-6 assist are all present and unambiguous.
2. Diff prp-implement §4.6 against prp-ralph §3.4 — confirm the agent-browser arm wording matches (sync mandate).
3. Confirm Framework=none and Framework=Playwright paths read identically to before (no behavior change for existing users).

---

## Acceptance Criteria

- [ ] `agent-browser` is a recognized value in the E2E enum and CLAUDE.md persistence (`prp-prd.md`)
- [ ] New `e2e-browser` skill exists, flat dir, valid frontmatter, fail-loud on missing CLI
- [ ] `user-journey.md` template has an Agent-Browser Validation variant for `type: web`
- [ ] `type: web` journeys are classified **Automated/blocking** when Framework=agent-browser (`prp-plan.md` Phase 4.5)
- [ ] Level 5 has a third arm invoking the skill; EXPECT still exit 0
- [ ] Level 6 references the skill for screenshots but preserves the human walk (no auto-pass)
- [ ] prp-implement §4.6, prp-ralph §3.4, build-with-agent-team Step 6 carry **matching** agent-browser wording (sync mandate)
- [ ] Framework=none / Playwright / Cypress behavior is unchanged (regression check)
- [ ] Journey Validation Script passes (Level 5, exit 0)

---

## Completion Checklist

- [ ] All 9 tasks completed in order
- [ ] Level 1: skill structure/frontmatter checks pass
- [ ] Level 3: all consumers wired (grep gate) passes
- [ ] Level 5: journey Validation Script passes
- [ ] Level 7: manual read-through + sync diff done
- [ ] `.claude/user-journeys/agent-browser-e2e-engine.md` present
- [ ] All acceptance criteria met

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Execution paths drift (implement/ralph/agent-team wording diverges) | MED | HIGH | Tasks 6-8 explicitly require identical wording; Level 7 step 2 diffs them; CLAUDE.md sync mandate cited in each task |
| Silent fallback to Manual when CLI missing | MED | HIGH | Skill's precondition STOPS with explicit error (Task 1.1); edge-case test covers it |
| agent-browser auto-"passing" Level 6 visual parity | LOW | MED | Level 6 keeps the human walk; skill only captures screenshots (Task 5 gotcha, `:1150` rationale preserved) |
| Enum change breaks projects still on 2-value assumption | LOW | LOW | `agent-browser` is additive; `none`/`Playwright`/`Cypress` arms untouched (regression check) |
| Consumer project lacks the agent-browser CLI | MED | MED | Documented as a prerequisite in the skill + prp-prd Approach note; fail-loud, not silent |

---

## Notes

- **Why a skill, not a command**: the methodology must be reused by prp-plan (authoring), prp-implement, prp-ralph, and build-with-agent-team. A single internal (`user-invocable: false`) skill keeps the logic in one place; the commands only reference it — this is exactly the `context-read` pattern.
- **Deliberate frontmatter deviation**: prp-core skills omit `allowed-tools`, but `e2e-browser` shells out to the CLI, so it mirrors the standalone `~/.claude/skills/agent-browser/SKILL.md` (`allowed-tools: Bash(agent-browser:*)`). Flagged for PR review.
- **build-with-agent-team pre-existing gap**: it never had the formal framework/no-framework branch the other two paths use (only a bare `agent-browser` line at `:425`). This plan aligns that line and adds a sync note but does not refactor the skill's validation model — captured under NOT Building.
- **Downstream follow-up (not this plan)**: an optional thin `/prp-e2e` command for standalone re-runs, and exercising the live browser-driving path in a real consumer repo (e.g. maxtel-eventledger-poc, which currently uses Playwright).
- **Confidence for one-pass**: high — every edit point is line-anchored, the change is additive/pattern-mirroring, and validation is deterministic grep + a runnable journey script.
