---
description: Execute an implementation plan with rigorous validation loops
argument-hint: <path/to/plan.md>
---

# Implement Plan

**Plan**: $ARGUMENTS

---

## Your Mission

Execute the plan end-to-end with rigorous self-validation. You are autonomous.

**Core Philosophy**: Validation loops catch mistakes early. Run checks after every change. Fix issues immediately. The goal is a working implementation, not just code that exists.

**Golden Rule**: If a validation fails, fix it before moving on. Never accumulate broken state.

---

## Phase 0: DETECT - Project Environment

### 0.1 Identify Package Manager

Check for these files to determine the project's toolchain:

| File Found | Package Manager | Runner |
|------------|-----------------|--------|
| `bun.lockb` | bun | `bun` / `bun run` |
| `pnpm-lock.yaml` | pnpm | `pnpm` / `pnpm run` |
| `yarn.lock` | yarn | `yarn` / `yarn run` |
| `package-lock.json` | npm | `npm run` |
| `pyproject.toml` | uv/pip | `uv run` / `python` |
| `Cargo.toml` | cargo | `cargo` |
| `go.mod` | go | `go` |

**Store the detected runner** - use it for all subsequent commands.

### 0.2 Identify Validation Scripts

Check `package.json` (or equivalent) for available scripts:
- Type checking: `type-check`, `typecheck`, `tsc`
- Linting: `lint`, `lint:fix`
- Testing: `test`, `test:unit`, `test:integration`
- Building: `build`, `compile`

**Use the plan's "Validation Commands" section** - it should specify exact commands for this project.

---

## Phase 1: LOAD - Read the Plan

### 1.1 Load Plan File

```bash
cat $ARGUMENTS
```

### 1.2 Extract Key Sections

Locate and understand:

- **Summary** - What we're building
- **Patterns to Mirror** - Code to copy from
- **Files to Change** - CREATE/UPDATE list
- **Step-by-Step Tasks** - Implementation order
- **Validation Commands** - How to verify (USE THESE, not hardcoded commands)
- **User Journeys** - Journey files and impact classification (if present)
- **How to Execute** - Start/seed/ready/teardown commands (if present)
- **E2E Tests to Write** - E2E test files to generate (if present)
- **Acceptance Criteria** - Definition of done
- **Plane Tracking** - Project identifier, module ID, plan work item ID (if present)

### 1.3 Plane Tracking — Create Work Item (silent)

**Uses `plane-track` skill logic (see `plugins/prp-core/skills/plane-track/SKILL.md`).**

Read `Plane Strategy` from the plan's `## Metadata` table. If `integrated`:

1. Call plane-track: action=`create`, type=`Implement`, title=`{Feature Name}`, project_identifier=`{from plan}`, module_id=`{from plan}`, description=`Implementing plan: {plan file path}`, priority=`medium`
2. Store the returned `work_item_id` for status update at completion
3. Call plane-track: action=`update`, work_item_id=`{id}`, project_identifier=`{id}`, status=`doing`

If `Plane Strategy` is `none` or missing, skip all Plane operations silently. If Plane MCP is unavailable, skip silently.

### 1.3 Validate Plan Exists

**If plan not found:**

```
Error: Plan not found at $ARGUMENTS

Create a plan first: /prp-plan "feature description"
```

**PHASE_1_CHECKPOINT:**

- [ ] Plan file loaded
- [ ] Key sections identified
- [ ] Tasks list extracted

---

## Phase 2: PREPARE - Git State

### 2.1 Check Current State

```bash
git branch --show-current
git status --porcelain
git worktree list
```

### 2.2 Branch Decision

| Current State     | Action                                               |
| ----------------- | ---------------------------------------------------- |
| In worktree       | Use it (log: "Using worktree")                       |
| On main, clean    | Create branch: `git checkout -b feature/{plan-slug}` |
| On main, dirty    | STOP: "Stash or commit changes first"                |
| On feature branch | Use it (log: "Using existing branch")                |

### 2.3 Sync with Remote

```bash
git fetch origin
git pull --rebase origin main 2>/dev/null || true
```

**PHASE_2_CHECKPOINT:**

- [ ] On correct branch (not main with uncommitted work)
- [ ] Working directory ready
- [ ] Up to date with remote

---

## Phase 3: EXECUTE - Implement Tasks

**For each task in the plan's Step-by-Step Tasks section:**

### 3.1 Read Context

1. Read the **MIRROR** file reference from the task
2. Understand the pattern to follow
3. Read any **IMPORTS** specified

### 3.2 Implement

1. Make the change exactly as specified
2. Follow the pattern from MIRROR reference
3. Handle any **GOTCHA** warnings

### 3.3 Validate Immediately

**After EVERY file change, run the type-check command from the plan's Validation Commands section.**

Common patterns:
- `{runner} run type-check` (JS/TS projects)
- `mypy .` (Python)
- `cargo check` (Rust)
- `go build ./...` (Go)

**If types fail:**

1. Read the error
2. Fix the issue
3. Re-run type-check
4. Only proceed when passing

### 3.4 Track Progress

Log each task as you complete it:

```
Task 1: CREATE src/features/x/models.ts ✅
Task 2: CREATE src/features/x/service.ts ✅
Task 3: UPDATE src/routes/index.ts ✅
```

**Deviation Handling:**
If you must deviate from the plan:

- Note WHAT changed
- Note WHY it changed
- Continue with the deviation documented

**PHASE_3_CHECKPOINT:**

- [ ] All tasks executed in order
- [ ] Each task passed type-check
- [ ] Deviations documented

---

## Phase 4: VALIDATE - Full Verification

### 4.1 Static Analysis

**Run the type-check and lint commands from the plan's Validation Commands section.**

Common patterns:
- JS/TS: `{runner} run type-check && {runner} run lint`
- Python: `ruff check . && mypy .`
- Rust: `cargo check && cargo clippy`
- Go: `go vet ./...`

**Must pass with zero errors.**

If lint errors:

1. Run the lint fix command (e.g., `{runner} run lint:fix`, `ruff check --fix .`)
2. Re-check
3. Manual fix remaining issues

### 4.2 Unit Tests

**You MUST write or update tests for new code.** This is not optional.

**Test requirements:**

1. Every new function/feature needs at least one test
2. Edge cases identified in the plan need tests
3. Update existing tests if behavior changed

**Write tests**, then run the test command from the plan.

Common patterns:
- JS/TS: `{runner} test` or `{runner} run test`
- Python: `pytest` or `uv run pytest`
- Rust: `cargo test`
- Go: `go test ./...`

**If tests fail:**

1. Read failure output
2. Determine: bug in implementation or bug in test?
3. Fix the actual issue
4. Re-run tests
5. Repeat until green

### 4.2.1 E2E Test Generation

**If the plan has an `## E2E Tests to Write` table:**

1. Read each journey file referenced in the table
2. Generate e2e test files using the project's e2e framework patterns:
   - Read existing e2e tests for pattern reference
   - Translate journey steps into test assertions
   - Use the e2e config from CLAUDE.md (framework, test directory, conventions)
3. Place test files in the e2e directory specified by the project config
4. Run the e2e test command to verify they compile/parse correctly (tests may fail if services aren't running — that's OK at this stage)

**If no `## E2E Tests to Write` table:** Skip this step — journey validation scripts handle e2e coverage.

### 4.3 Build Check

**Run the build command from the plan's Validation Commands section.**

Common patterns:
- JS/TS: `{runner} run build`
- Python: N/A (interpreted) or `uv build`
- Rust: `cargo build --release`
- Go: `go build ./...`

**Must complete without errors.**

### 4.4 Integration Testing (if applicable)

**If the plan involves API/server changes, use the integration test commands from the plan.**

Example pattern:
```bash
# Start server in background (command varies by project)
{runner} run dev &
SERVER_PID=$!
sleep 3

# Test endpoints (adjust URL/port per project config)
curl -s http://localhost:{port}/health | jq

# Stop server
kill $SERVER_PID
```

### 4.5 Edge Case Testing

Run any edge case tests specified in the plan.

### 4.6 Journey / E2E Validation

**Prerequisite**: Phases 4.1-4.3 must ALL pass first. No point testing journeys against broken code.

**If plan has `## How to Execute` section:**

1. **Setup**: Run the commands from "How to Execute":
   - Start Services
   - Seed Data / Reset State
   - Verify Ready (wait for health check to pass)

2. **Run validation:**

   **If e2e framework configured** (plan has `## E2E Tests to Write`):
   ```bash
   {e2e run command from CLAUDE.md, e.g., npx playwright test}
   ```

   **If no e2e framework** (validation scripts only):
   - For each journey listed as **Automated** in the plan's `## User Journeys`:
     - Read the journey file
     - Extract the `## Validation Script` section
     - Execute the script
     - Log PASS/FAIL

3. **Teardown**: Run the teardown commands from "How to Execute"

4. **If validation fails:**
   - Read the failure output
   - Fix the implementation (not the test/script unless it's wrong)
   - Re-run setup → validation → teardown
   - Repeat until passing

**Manual journeys**: Log as "requires manual verification" in the report. Non-blocking.

**If plan has no `## How to Execute` section:** Skip this step entirely.

**PHASE_4_CHECKPOINT:**

- [ ] Type-check passes (command from plan)
- [ ] Lint passes (0 errors)
- [ ] Tests pass (all green)
- [ ] Build succeeds
- [ ] Integration tests pass (if applicable)
- [ ] Journey / e2e validation passes (if applicable)

---

## Phase 5: REPORT - Create Implementation Report

### 5.1 Create Report Directory

```bash
mkdir -p .claude/PRPs/reports
```

### 5.2 Generate Report

**Path**: `.claude/PRPs/reports/{plan-name}-report.md`

```markdown
# Implementation Report

**Plan**: `$ARGUMENTS`
**Source Issue**: #{number} (if applicable)
**Branch**: `{branch-name}`
**Date**: {YYYY-MM-DD}
**Status**: {COMPLETE | PARTIAL}

---

## Summary

{Brief description of what was implemented}

---

## Assessment vs Reality

Compare the original investigation's assessment with what actually happened:

| Metric     | Predicted   | Actual   | Reasoning                                                                      |
| ---------- | ----------- | -------- | ------------------------------------------------------------------------------ |
| Complexity | {from plan} | {actual} | {Why it matched or differed - e.g., "discovered additional integration point"} |
| Confidence | {from plan} | {actual} | {e.g., "root cause was correct" or "had to pivot because X"}                   |

**If implementation deviated from the plan, explain why:**

- {What changed and why - based on what you discovered during implementation}

---

## Tasks Completed

| #   | Task               | File       | Status |
| --- | ------------------ | ---------- | ------ |
| 1   | {task description} | `src/x.ts` | ✅     |
| 2   | {task description} | `src/y.ts` | ✅     |

---

## Validation Results

| Check       | Result | Details               |
| ----------- | ------ | --------------------- |
| Type check  | ✅     | No errors             |
| Lint        | ✅     | 0 errors, N warnings  |
| Unit tests  | ✅     | X passed, 0 failed    |
| Build       | ✅     | Compiled successfully |
| Integration | ✅/⏭️  | {result or "N/A"}     |

---

## Files Changed

| File       | Action | Lines     |
| ---------- | ------ | --------- |
| `src/x.ts` | CREATE | +{N}      |
| `src/y.ts` | UPDATE | +{N}/-{M} |

---

## Deviations from Plan

{List any deviations with rationale, or "None"}

---

## Issues Encountered

{List any issues and how they were resolved, or "None"}

---

## Tests Written

| Test File       | Test Cases               |
| --------------- | ------------------------ |
| `src/x.test.ts` | {list of test functions} |

---

## Journey / E2E Validation

| Journey | Type | Result | Notes |
|---------|------|--------|-------|
| `.claude/user-journeys/{name}.md` | Automated | ✅/❌ | {details} |
| `.claude/user-journeys/{name}.md` | Manual | ⏭️ | Requires manual verification |

**E2E Tests Generated**:
| Test File | Journey Source | Status |
|-----------|---------------|--------|
| `e2e/{name}.spec.ts` | `.claude/user-journeys/{name}.md` | ✅/❌ |

_Omit this section if no user journeys in the plan._

---

## Manual Testing

Step-by-step instructions to manually run and verify what was implemented.

### Prerequisites

{List anything needed before testing — running services, environment variables, seed data, etc.}

### Steps to Test

1. {Start the application / run the relevant service}
   ```bash
   {command to start, e.g., npm run dev, uv run uvicorn main:app}
   ```

2. {How to exercise the new functionality}
   ```bash
   {command, URL to visit, UI action, API call, etc.}
   ```

3. {Expected result — what the tester should see}

4. {Any additional scenarios or edge cases to verify}

### Expected Behavior

| Scenario | Action | Expected Result |
|----------|--------|-----------------|
| {Happy path} | {What to do} | {What should happen} |
| {Edge case} | {What to do} | {What should happen} |

---

## Next Steps

- [ ] Manual testing (follow steps above)
- [ ] Review implementation
- [ ] Create PR: `gh pr create` (if applicable)
- [ ] Merge when approved
```

### 5.3 Update Source PRD (if applicable)

**Check if plan was generated from a PRD (try each method in order):**

1. **Metadata table**: Look for `Source PRD` row in the plan's `## Metadata` table
2. **Inline reference**: Search the plan file for `Source PRD:` text anywhere
3. **PRD directory scan**: If neither found, scan `.claude/PRPs/prds/` for any `.prd.md` file whose Implementation Phases table references this plan's filename or feature name

**If PRD source found by any method:**

1. Read the PRD file
2. Find the matching phase row in the Implementation Phases table (match by plan path, phase name, or feature name)
3. Update the phase:
   - Change Status from `in-progress` to `complete`
4. Save the PRD

**If no PRD source found after all methods**: Log a warning to the user: "No source PRD found — skipping PRD status update. To link manually, add `| Source PRD | path/to/file.prd.md |` to the plan's Metadata table."

**Check if ALL PRD phases are now complete:**

If a PRD was found and updated, re-read the PRD's Implementation Phases table. If every phase has Status `complete`:
1. Archive the PRD to the completed folder:
   ```bash
   mkdir -p .claude/PRPs/prds/completed
   mv {prd_path} .claude/PRPs/prds/completed/
   ```
2. Log: "All PRD phases complete — PRD archived to `.claude/PRPs/prds/completed/`"

### 5.4 Plane Tracking — Update Status (silent)

If `Plane Strategy` is `integrated` and an Implement work item was created in Phase 1.3:

1. Call plane-track: action=`update`, work_item_id=`{id}`, project_identifier=`{id}`, status=`done`
2. If Plane MCP is unavailable, skip silently

### 5.5 Archive Plan

```bash
mkdir -p .claude/PRPs/plans/completed
mv $ARGUMENTS .claude/PRPs/plans/completed/
```

### 5.6 Git Operations

**Determine git strategy**: If a source PRD was found in step 5.3, read its `Git Strategy` field from the Technical Approach section. Default to `main-only` if no PRD or field is missing. If no PRD exists, ask the user which strategy to use.

- **`none`**: Skip all git operations. Do not stage or commit.
- **`main-only`**: Commit on current branch and push:
  ```bash
  git add -A
  git commit -m "feat: implement {feature-name}"
  git push -u origin HEAD
  ```
- **`branch-per-prd`**: Verify on the PRD branch (`feat/{prd-name}`). If not, check it out. Then commit and push:
  ```bash
  git checkout feat/{prd-kebab-name}  # if not already on it
  git add -A
  git commit -m "feat: implement {feature-name}"
  git push -u origin HEAD
  ```
- **`branch-per-phase`**: Should already be on the phase branch (created by prp-plan). Verify, then commit and push:
  ```bash
  git add -A
  git commit -m "feat: implement {feature-name}"
  git push -u origin HEAD
  ```

Use the conventional commit type that best matches the work (feat, fix, refactor, etc.).

**PHASE_5_CHECKPOINT:**

- [ ] Report created at `.claude/PRPs/reports/`
- [ ] PRD updated (if applicable) - phase marked complete
- [ ] Plan moved to completed folder
- [ ] Git operations executed per strategy (or skipped if `none`)

---

## Phase 6: OUTPUT - Report to User

```markdown
## Implementation Complete

**Plan**: `$ARGUMENTS`
**Source Issue**: #{number} (if applicable)
**Branch**: `{branch-name}`
**Status**: ✅ Complete

### Validation Summary

| Check      | Result          |
| ---------- | --------------- |
| Type check | ✅              |
| Lint       | ✅              |
| Tests      | ✅ ({N} passed) |
| Build      | ✅              |
| Journeys   | ✅/⏭️ ({N} auto, {M} manual) |

### Files Changed

- {N} files created
- {M} files updated
- {K} tests written

### Deviations

{If none: "Implementation matched the plan."}
{If any: Brief summary of what changed and why}

### Artifacts

- Report: `.claude/PRPs/reports/{name}-report.md`
- Plan archived to: `.claude/PRPs/plans/completed/`

{If from PRD:}
### PRD Progress

**PRD**: `{prd-file-path}`
**Phase Completed**: #{number} - {phase name}

| # | Phase | Status |
|---|-------|--------|
{Updated phases table showing progress}

**Next Phase**: {next pending phase, or "All phases complete!"}
{If next phase can parallel: "Note: Phase {X} can also start now (parallel)"}

To continue: `/prp-plan {prd-path}`

### Next Steps

1. Review the report (especially if deviations noted)
2. Create PR: `gh pr create` or `/prp-pr`
3. Merge when approved
{If more phases: "4. Continue with next phase: `/prp-plan {prd-path}`"}
```

---

## Handling Failures

### Type Check Fails

1. Read error message carefully
2. Fix the type issue
3. Re-run the type-check command
4. Don't proceed until passing

### Tests Fail

1. Identify which test failed
2. Determine: implementation bug or test bug?
3. Fix the root cause (usually implementation)
4. Re-run tests
5. Repeat until green

### Lint Fails

1. Run the lint fix command for auto-fixable issues
2. Manually fix remaining issues
3. Re-run lint
4. Proceed when clean

### Build Fails

1. Usually a type or import issue
2. Check the error output
3. Fix and re-run

### Integration Test Fails

1. Check if server started correctly
2. Verify endpoint exists
3. Check request format
4. Fix implementation and retry

---

## Success Criteria

- **TASKS_COMPLETE**: All plan tasks executed
- **TYPES_PASS**: Type-check command exits 0
- **LINT_PASS**: Lint command exits 0 (warnings OK)
- **TESTS_PASS**: Test command all green
- **BUILD_PASS**: Build command succeeds
- **JOURNEYS_VALIDATED**: E2E tests or validation scripts pass (if applicable)
- **REPORT_CREATED**: Implementation report exists
- **PLAN_ARCHIVED**: Original plan moved to completed
- **PLANE_TRACKED**: Work item status updated to done (or skipped if unavailable)
