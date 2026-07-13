---
name: e2e-browser
description: "Drive a type:web user journey with the agent-browser CLI — translate journey steps into open/snapshot/click/fill/assert sequences, and run the Level-6 screenshot-vs-mockup parity walk. Invoked by prp-plan/prp-implement/prp-ralph when the project's e2e Framework is agent-browser. Not user-facing."
user-invocable: false
allowed-tools: Bash(agent-browser:*)
---

<!--
  NOTE ON allowed-tools: prp-core skills conventionally omit `allowed-tools`.
  This skill is a deliberate exception because it shells out to the agent-browser
  CLI on every step; it mirrors the standalone ~/.claude/skills/agent-browser/SKILL.md
  (`allowed-tools: Bash(agent-browser:*)`). Flagged for PR review.
-->

# e2e-browser — agent-browser as the web-journey e2e engine

This skill is the shared engine invoked whenever a project's e2e **Framework is
`agent-browser`** (recorded in the project's `CLAUDE.md` `## Testing` section, per
`prp-prd` Phase 7.5). It does two jobs:

1. **Author/execute** a `type: web` user journey as an agent-browser command
   sequence with real assertions (used by `prp-plan` Level 5, `prp-implement`
   §4.6, `prp-ralph` §3.4, and `build-with-agent-team`).
2. **Assist** the Level-6 visual-parity walk by capturing route screenshots
   beside the mockup (used by `prp-plan` Level 6).

The command vocabulary is the agent-browser CLI. See `~/.claude/skills/agent-browser/SKILL.md`
for the full reference. This skill only adds the *methodology* for turning a
journey doc into a pass/fail run.

---

## 0. Precondition — fail loud, never silently downgrade

Before running anything, confirm the CLI is available:

```bash
command -v agent-browser >/dev/null 2>&1 || npx agent-browser --version >/dev/null 2>&1
```

**If the CLI is NOT available AND the project's Framework is `agent-browser`:**
STOP with an explicit error — do **not** reclassify the journey as Manual and do
**not** skip it:

```
STOP: e2e Framework is `agent-browser` but the agent-browser CLI is not installed.
Install it (`npm i -g agent-browser`, or use `npx agent-browser`) and re-run.
A web journey configured for agent-browser must never be silently downgraded to
"manual / non-blocking".
```

This is the anti-silent-failure contract: a missing engine is a hard failure, not
a skipped check.

---

## 1. Contract

- **Input**: one `type: web` journey file (from `.claude/user-journeys/`) whose
  `## Agent-Browser Validation` section holds the command sequence, PLUS the
  running app (setup is the caller's responsibility — see the plan's `## How to
  Execute`).
- **Output**: exit `0` = PASS, non-zero = FAIL. Same contract as the curl
  `## Validation Script`, so every consumer's "EXPECT: exit 0" line holds
  unchanged.
- **Side effects**: opens/closes a browser session; may save screenshots.

---

## 2. Journey step → agent-browser command translation

For each **Step** in the journey (`Action` / `Expected`):

| Journey element | agent-browser realization |
|---|---|
| "Navigate to /path" | `agent-browser open <base-url>/path` |
| "Click the X button" | `agent-browser snapshot -i` → find the `@ref` → `agent-browser click @ref` (or `agent-browser find role button click --name "X"`) |
| "Enter Y in the Z field" | `agent-browser fill @ref "Y"` (or `agent-browser find label "Z" fill "Y"`) |
| "…and the page shows/routes to…" | `agent-browser wait --url "**/dashboard"` or `agent-browser wait --text "Success"` |
| **Expected**: visible text | `agent-browser get text @ref --json` → assert it contains the expected value → non-zero on mismatch |
| **Expected**: element present/enabled | `agent-browser is visible @ref` / `agent-browser is enabled @ref` |
| **Expected**: URL | `agent-browser get url --json` → compare |

Re-run `snapshot -i` after any navigation or significant DOM change (refs are
per-snapshot). Prefer semantic locators (`find role/text/label`) for stability
when refs are ambiguous.

**Authenticated journeys**: log in once, `agent-browser state save auth.json`,
then `agent-browser state load auth.json` on subsequent runs (see agent-browser
SKILL.md "Authentication with saved state").

---

## 3. Assertion pattern (exit-code discipline)

Wrap each Expected as a shell assertion that exits non-zero on failure, then end
with the canonical PASS line so the output matches the curl-script convention:

```bash
#!/bin/bash
set -euo pipefail
BASE="${BASE_URL:-http://localhost:3000}"

fail() { echo "FAIL: $1"; agent-browser close || true; exit 1; }

agent-browser open "$BASE/login"
agent-browser snapshot -i            # returns @refs; pick from output
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --url "**/dashboard" || fail "did not reach dashboard"

TITLE=$(agent-browser get text @e1 --json)   # re-snapshot first in real use
echo "$TITLE" | grep -q "Welcome" || fail "dashboard greeting missing"

agent-browser close
echo "JOURNEY PASS: {journey-name}"
```

Log PASS/FAIL per journey. Manual (judgment) journeys are still non-blocking —
this skill is only for journeys classified **Automated**.

---

## 4. Level-6 visual-parity assist (screenshots, NOT auto-pass)

When invoked for `prp-plan` Level 6:

1. `agent-browser open <base-url>/<route>` for each route in the Mockup Fidelity
   Checklist.
2. `agent-browser screenshot <route>.png --full` — capture the rendered page.
3. Open the corresponding mockup HTML (`agent-browser open file://<mockup>` in a
   second session, or a browser tab) and screenshot it too.
4. Present both to the human/reviewer and walk the checklist row-by-row.

**Screenshots ASSIST the walk — they do not pass it.** Level 6 remains a
human-owned parity judgment (per `prp-plan` Level 6 rationale: "Levels 1-5 prove
the code is correct… they do not prove the rendered UI matches the canonical
visual contract"). Do not mark a Mockup Fidelity row "Ships" from a screenshot
alone.

---

## 5. Teardown

Always close the session, even on failure (the `fail()` helper above does this):

```bash
agent-browser close
```

Service start/stop is the caller's job (plan `## How to Execute` → Teardown).
