---
name: agent-browser-e2e-engine
description: agent-browser is wired through every e2e/journey touchpoint as a recognized third framework value
type: cli
created_by: PRD000-P001-agent-browser-web-journey-e2e.plan.md
last_modified_by: PRD000-P001-agent-browser-web-journey-e2e.plan.md
---

# Journey: agent-browser recognized as a third e2e framework across the plugin

## Preconditions

- Working tree is the PRP-agentic-sdlc repo root.
- The plan `PRD000-P001-agent-browser-web-journey-e2e.plan.md` has been implemented.

## Steps

### Step 1: The framework enum lists agent-browser

**Action**:
```bash
grep -n "agent-browser" plugins/prp-core/commands/prp-prd.md
```

**Expected**:
```
The E2E Testing framework enum (Testing Strategy block + Phase 7.5 CLAUDE.md
persistence) includes "agent-browser" alongside Playwright | Cypress | none.
```

### Step 2: The new skill exists and is well-formed

**Action**:
```bash
test -f plugins/prp-core/skills/e2e-browser/SKILL.md && head -6 plugins/prp-core/skills/e2e-browser/SKILL.md
```

**Expected**:
```
File exists; frontmatter has name: e2e-browser, a description, and
allowed-tools: Bash(agent-browser:*).
```

### Step 3: Every consumer branch has a third arm

**Action**:
```bash
grep -rn "agent-browser" plugins/prp-core/commands/prp-plan.md \
  plugins/prp-core/commands/prp-implement.md \
  plugins/prp-core/commands/prp-ralph.md \
  plugins/prp-core/templates/user-journey.md \
  plugins/prp-core/skills/prp-ralph-loop/SKILL.md \
  plugins/prp-core/skills/build-with-agent-team/SKILL.md
```

**Expected**:
```
Each file references agent-browser in its e2e/journey branch (Level 5,
Phase 4.5, §4.6, §3.4, validation-script variant, ralph-loop mirror,
agent-team validation).
```

## Validation Script

```bash
#!/bin/bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

fail() { echo "FAIL: $1"; exit 1; }

# Step 1: enum + persistence in prp-prd
grep -q "agent-browser" plugins/prp-core/commands/prp-prd.md \
  || fail "prp-prd.md does not mention agent-browser"

# Step 2: new skill exists with correct frontmatter
test -f plugins/prp-core/skills/e2e-browser/SKILL.md \
  || fail "e2e-browser skill missing"
grep -q "name: e2e-browser" plugins/prp-core/skills/e2e-browser/SKILL.md \
  || fail "e2e-browser SKILL.md missing name"
grep -q "Bash(agent-browser" plugins/prp-core/skills/e2e-browser/SKILL.md \
  || fail "e2e-browser SKILL.md missing allowed-tools"

# Step 3: third arm present in every consumer
for f in \
  plugins/prp-core/commands/prp-plan.md \
  plugins/prp-core/commands/prp-implement.md \
  plugins/prp-core/commands/prp-ralph.md \
  plugins/prp-core/templates/user-journey.md \
  plugins/prp-core/skills/prp-ralph-loop/SKILL.md \
  plugins/prp-core/skills/build-with-agent-team/SKILL.md ; do
  grep -q "agent-browser" "$f" || fail "$f has no agent-browser branch"
done

echo "JOURNEY PASS: agent-browser-e2e-engine"
```

## Error Scenarios

| Scenario | Action | Expected |
|----------|--------|----------|
| Skill omitted | Only commands edited, no skill dir | Step 2 fails — skill is the shared engine, required |
| One consumer missed | e.g. prp-ralph left unedited | Step 3 fails — sync contract violated |

## Notes

- This journey validates the *framework-authoring* change: that agent-browser is
  wired consistently as a third e2e value. It does NOT drive a live browser — the
  PRP framework repo has no running app.
- The real end-user payoff (a `type: web` journey becoming automated/blocking in a
  consumer project) is exercised in a downstream consumer repo, not here.
- Created by plan PRD000-P001. Keep in sync if any e2e touchpoint file is renamed.
