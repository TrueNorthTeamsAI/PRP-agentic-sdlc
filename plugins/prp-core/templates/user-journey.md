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
