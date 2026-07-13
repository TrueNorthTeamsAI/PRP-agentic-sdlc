---
name: {journey-name}
description: {one-line description of what this journey validates}
type: web | cli | api | hybrid
created_by: {plan-name}.plan.md
last_modified_by: {plan-name}.plan.md
---

# Journey: {Human-Readable Journey Title}

## Preconditions

<!--
  What must be true before this journey can run.
  Application-level state, not infrastructure.
  How to start the system is documented in the plan's "How to Execute" section.
-->

- {e.g., "System is running and accessible"}
- {e.g., "User is logged in as an admin"}
- {e.g., "At least one project exists in the database"}

## Steps

<!--
  Each step is a concrete action the user takes.
  Include the EXACT command, URL, or UI action.
  Include the EXPECTED result after each step.
  Steps should be automatable where possible (curl, CLI commands).

  For web journeys, describe the UI action clearly:
    "Navigate to /dashboard, click the 'New Project' button"

  For API journeys, include the full request:
    curl -X POST http://localhost:3000/api/projects -H "Content-Type: application/json" -d '{...}'

  For CLI journeys, include the exact command:
    my-tool create --name "test-project"
-->

### Step 1: {Action description}

**Action**:
```bash
{exact command, URL path, or UI action}
```

**Expected**:
```
{response, output, or UI state}
```

### Step 2: {Action description}

**Action**:
```bash
{exact command, URL path, or UI action}
```

**Expected**:
```
{response, output, or UI state}
```

## Validation Script

<!--
  OPTIONAL. For projects WITHOUT an e2e test framework (Playwright, Cypress, etc.).
  A bash script that exercises the journey steps with assertions.
  Assumes preconditions are already met — setup is the caller's responsibility
  (see the plan's "How to Execute" section).

  Exit 0 = PASS, non-zero = FAIL.

  For projects WITH an e2e framework, e2e test files are generated
  during implementation instead and this section can be omitted.
-->

```bash
#!/bin/bash
set -euo pipefail

# Step 1: {description}
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:3000/api/example \
  -H "Content-Type: application/json" \
  -d '{"name": "test"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" != "201" ]]; then
  echo "FAIL Step 1: Expected 201, got $HTTP_CODE"
  echo "$BODY"
  exit 1
fi
echo "PASS Step 1: Resource created"

# Step 2: {description}
# {next assertion...}

echo "JOURNEY PASS: {journey-name}"
```

## Agent-Browser Validation

<!--
  OPTIONAL. For `type: web` journeys when the project's e2e Framework is
  `agent-browser` (from CLAUDE.md `## Testing`). Drives a real browser via the
  agent-browser CLI instead of curl — use this for UI flows that cannot be
  reduced to API calls (click a button, assert rendered DOM text, follow JS
  routing). Executed by the `e2e-browser` skill.

  Exactly ONE validation mechanism applies per journey:
    - type: api / cli, or no e2e framework  → use the `## Validation Script` (curl) above
    - type: web + Framework: agent-browser   → use this section
    - Framework: Playwright / Cypress        → omit both; a spec file is generated instead

  Same contract as the Validation Script: exit 0 = PASS, non-zero = FAIL.
  Assumes preconditions are met and the app is running (plan's "How to Execute").
-->

```bash
#!/bin/bash
set -euo pipefail
BASE="${BASE_URL:-http://localhost:3000}"
fail() { echo "FAIL: $1"; agent-browser close || true; exit 1; }

# Step 1: {description}
agent-browser open "$BASE/{path}"
agent-browser snapshot -i                      # returns @refs (e.g. @e1, @e2)
agent-browser click @e1
agent-browser wait --text "{expected text}" || fail "Step 1: expected text missing"

# Step 2: {description} — assert rendered state
agent-browser is visible @e2 || fail "Step 2: element not visible"

agent-browser close
echo "JOURNEY PASS: {journey-name}"
```

## Error Scenarios

<!--
  OPTIONAL. Document what happens when things go wrong.
  Useful for negative-path testing and edge cases.
-->

| Scenario | Action | Expected |
|----------|--------|----------|
| {e.g., "Missing required field"} | {e.g., "POST without name"} | {e.g., "400 with validation error"} |
| {e.g., "Unauthorized access"} | {e.g., "Request without auth token"} | {e.g., "401 Unauthorized"} |

## Notes

<!--
  Context for future editors:
  - Why this journey exists
  - Which plan/feature created it
  - Known limitations of the automated validation
  - Related journeys that should be run together
-->
