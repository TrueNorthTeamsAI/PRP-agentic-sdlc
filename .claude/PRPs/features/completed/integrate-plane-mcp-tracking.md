# Feature: Integrate Plane MCP for PRP Workflow Task Management

## Feature Description

Integrate the Plane project management tool as the external work item tracking system for the PRP SDLC framework. Each discrete PRP workflow invocation (plan, implement, ralph, investigate, fix, debug, research) creates a Plane work item for persistent, visible tracking. PRDs map to Plane modules, and downstream commands inherit tracking metadata through a propagation chain.

## User Story

As a developer using the PRP framework
I want each workflow step to automatically create and update Plane work items
So that I have persistent, visible tracking of all development activity outside the ephemeral Claude Code session

## Problem Statement

PRP workflow commands (`prp-prd`, `prp-plan`, `prp-implement`, `prp-ralph`, `prp-issue-investigate`, `prp-issue-fix`, `prp-debug`, `prp-codebase-question`, `prp-research-team`) have no external task tracking. When a Claude Code session ends, there's no persistent record in a project management tool of what was worked on, what stage it reached, or how work items relate to each other. Claude Code's internal TodoWrite handles granular sub-steps within a session but provides no cross-session visibility.

## Solution Statement

1. **Create a reusable `plane-track` skill** that all PRP commands call silently to create/update Plane work items. Follows the same pattern as `context-read` — silent, optional, gracefully degrades if Plane MCP is unavailable.

2. **Establish metadata propagation chain**: PRD (establishes module) -> Plan (inherits module + project) -> Implement/Ralph (inherits from plan). Standalone commands (debug, research, investigate) use a default project from CLAUDE.md.

3. **Add Plane tracking sections** to all PRP command files with create-at-start and update-at-completion semantics.

4. **Work item title convention**: `[Type] Description` (e.g., `[PRD] Add user authentication`, `[Implement] Add user auth - Phase 1`).

## Feature Metadata

**Feature Type**: New Capability (cross-cutting integration)
**Estimated Complexity**: Medium-High
**Primary Systems Affected**:
- `plugins/prp-core/skills/` — New plane-track skill
- `plugins/prp-core/commands/` — All 9 PRP command files modified
- `.mcp.json` — Plane MCP server configuration
**Dependencies**:
- Plane MCP server (`plane-mcp-server` via uvx)
- Plane instance (local or cloud) with API key
- Plane workspace with at least one project

---

## CONTEXT REFERENCES

### Relevant Codebase Files

- `plugins/prp-core/commands/prp-prd.md` — Entry point where module association is established
- `plugins/prp-core/commands/prp-plan.md` — Inherits PRD tracking, creates plan work item
- `plugins/prp-core/commands/prp-implement.md` — Inherits plan tracking
- `plugins/prp-core/commands/prp-ralph.md` — Inherits plan tracking
- `plugins/prp-core/commands/prp-issue-investigate.md` — Standalone tracking from CLAUDE.md
- `plugins/prp-core/commands/prp-issue-fix.md` — Standalone tracking from CLAUDE.md
- `plugins/prp-core/commands/prp-debug.md` — Standalone tracking from CLAUDE.md
- `plugins/prp-core/commands/prp-codebase-question.md` — Standalone tracking from CLAUDE.md
- `plugins/prp-core/commands/prp-research-team.md` — Standalone tracking from CLAUDE.md
- `plugins/prp-core/skills/context-read/SKILL.md` — Pattern for silent, optional skills

### New Files to Create

- `plugins/prp-core/skills/plane-track/SKILL.md` — Reusable Plane tracking skill
- `.mcp.json` — Plane MCP server configuration

### External Documentation

- Plane API Reference: https://developers.plane.so/api-reference
- `plane-mcp-server` PyPI package: provides 55+ MCP tools for Plane
- Key tools: `list_projects`, `create_work_item`, `update_work_item`, `list_modules`, `create_module`, `add_work_items_to_module`, `list_states`

### Patterns to Follow

**Silent skill pattern** (from `context-read`):
- Check availability first, skip silently if unavailable
- Never block the parent workflow
- Return structured data for caller to store

**Metadata propagation**:
```
PRD (module + project) → Plan (inherits) → Implement/Ralph (inherits)
```

**Resolution order for project identifier**:
```
Artifact metadata → CLAUDE.md ## Plane Integration default → skip tracking
```

**Work item status flow**:
```
todo → doing → review → done
```
Mapped to Plane state groups: `unstarted → started → started/review → completed`

---

## IMPLEMENTATION PLAN

### Phase 1: Infrastructure

Set up the Plane MCP connection and create the reusable tracking skill.

**Tasks:**
- Create `.mcp.json` with Plane MCP server configuration
- Create `plugins/prp-core/skills/plane-track/SKILL.md` with create/update actions
- Define skill interface: action, type, title, project_identifier, module_id, description, priority, work_item_id, status
- Implement graceful degradation (try `list_projects`, if fails return empty)

### Phase 2: PRD Integration (Entry Point)

The PRD command is where module association is established.

**Tasks:**
- Add Plane project/module question to Phase 2 (FOUNDATION)
- Add `## Plane Tracking` metadata section to PRD template
- Add Phase 7.25 (TRACK): resolve/create module, create PRD work item, update PRD file with IDs
- Add `PLANE_TRACKED` to success criteria

### Phase 3: Plan Integration (Inherits from PRD)

**Tasks:**
- Parse `## Plane Tracking` from PRD in Phase 0 (DETECT)
- Add `## Plane Tracking` section to plan template
- Create `[Plan]` work item after writing plan file
- Store work_item_id in plan metadata

### Phase 4: Implement + Ralph Integration (Inherits from Plan)

**Tasks:**
- Parse plan's `## Plane Tracking` in both commands
- Create `[Implement]` or `[Ralph]` work item at start, status=`doing`
- Update work item status to `done` at completion

### Phase 5: Standalone Commands (Issue, Debug, Research)

**Tasks:**
- Add tracking to `prp-issue-investigate` (creates `[Investigate]` work item)
- Add tracking to `prp-issue-fix` (creates `[Fix]` work item)
- Add tracking to `prp-debug` (creates `[Debug]` work item)
- Add tracking to `prp-codebase-question` (creates `[Research]` work item)
- Add tracking to `prp-research-team` (creates `[Research-Team]` work item)
- All use CLAUDE.md `## Plane Integration` → `Default Project` for project identifier

---

## STEP-BY-STEP TASKS

### Task 1: CREATE `.mcp.json`

- **IMPLEMENT**: Plane MCP server configuration at project root
- **DETAILS**: Configure `plane-mcp-server` via uvx with API key, base URL, workspace slug
- **GOTCHA**: Include `--with pywin32` in args for Windows compatibility

### Task 2: CREATE `plugins/prp-core/skills/plane-track/SKILL.md`

- **IMPLEMENT**: Reusable skill with three steps: CHECK availability, CREATE work item, UPDATE status
- **PATTERN**: Mirror `context-read` skill's silent/optional approach
- **DETAILS**:
  - Step 1: Call `list_projects` — if fails, return empty result, skip silently
  - Step 2 (create): Format title as `[{type}] {title}`, call `create_work_item`, optionally `add_work_items_to_module`
  - Step 3 (update): Resolve logical status to Plane state via `list_states`, call `update_work_item`
  - Returns: `{ work_item_id, identifier, module_id, url }`

### Task 3: MODIFY `plugins/prp-core/commands/prp-prd.md`

- **IMPLEMENT**: Add Plane tracking as the entry point for module association
- **DETAILS**:
  - Phase 2: Add question 6 for Plane project identifier and module name
  - PRD template: Add `## Plane Tracking` table (Project, Module, Module ID, PRD Work Item, PRD Work Item ID)
  - Add Phase 7.25 (TRACK): Resolve/create module, create PRD work item, update PRD file

### Task 4: MODIFY `plugins/prp-core/commands/prp-plan.md`

- **IMPLEMENT**: Inherit tracking from PRD, create plan work item
- **DETAILS**:
  - Phase 0: Extract Plane Tracking from PRD
  - Plan template: Add `## Plane Tracking` section
  - After writing plan: call plane-track to create `[Plan]` work item

### Task 5: MODIFY `plugins/prp-core/commands/prp-implement.md`

- **IMPLEMENT**: Create/update work items
- **DETAILS**:
  - Phase 1: Parse plan's Plane Tracking, add Phase 1.3 to create `[Implement]` work item
  - Phase 5: Add Phase 5.4 to update work item status to `done`

### Task 6: MODIFY `plugins/prp-core/commands/prp-ralph.md`

- **IMPLEMENT**: Create/update work items
- **DETAILS**:
  - Add Phase 1.5: Create `[Ralph]` work item, status=`doing`
  - Phase 4.2 completion: Update work item status to `done`

### Task 7: MODIFY `plugins/prp-core/commands/prp-issue-investigate.md`

- **IMPLEMENT**: Standalone tracking using CLAUDE.md default project
- **DETAILS**: Add Phase 1.5 (create) and Phase 6.5 (update to done)

### Task 8: MODIFY `plugins/prp-core/commands/prp-issue-fix.md`

- **IMPLEMENT**: Standalone tracking using CLAUDE.md default project
- **DETAILS**: Add Phase 1.4 (create) and Phase 9.5 (update to done)

### Task 9: MODIFY `plugins/prp-core/commands/prp-debug.md`

- **IMPLEMENT**: Standalone tracking using CLAUDE.md default project
- **DETAILS**: Add Phase 1.4 (create) and completion tracking

### Task 10: MODIFY `plugins/prp-core/commands/prp-codebase-question.md`

- **IMPLEMENT**: Standalone tracking using CLAUDE.md default project
- **DETAILS**: Add Phase 1.5 (create) and completion tracking

### Task 11: MODIFY `plugins/prp-core/commands/prp-research-team.md`

- **IMPLEMENT**: Standalone tracking using CLAUDE.md default project
- **DETAILS**: Add Phase 1.4 (create) and completion tracking

---

## TESTING STRATEGY

### Integration Tests

1. **Happy Path — PRD to Implement chain**: Create PRD with Plane module, generate plan, implement — verify work items appear in Plane UI in correct module
2. **Standalone command**: Run `prp-debug` with CLAUDE.md default project configured — verify work item created
3. **Graceful degradation**: Disconnect Plane MCP, run any command — verify it completes without errors
4. **Module creation**: Specify a new module name in PRD — verify module created in Plane

### Edge Cases

1. **No Plane config in CLAUDE.md**: Standalone commands should skip tracking silently
2. **Plane MCP unavailable**: All commands should work normally without tracking
3. **Invalid project identifier**: Should log warning and skip, not crash
4. **PRD without Plane tracking**: Plan should still work, just without tracking metadata

---

## VALIDATION COMMANDS

### Level 1: File Structure

```bash
# Verify new files exist
test -f .mcp.json && echo "MCP config exists"
test -f plugins/prp-core/skills/plane-track/SKILL.md && echo "plane-track skill exists"

# Verify all modified commands contain Plane tracking
for cmd in prp-prd prp-plan prp-implement prp-ralph prp-issue-investigate prp-issue-fix prp-debug prp-codebase-question prp-research-team; do
  grep -q "plane-track" "plugins/prp-core/commands/${cmd}.md" && echo "${cmd}: has plane-track reference"
done
```

### Level 2: Content Validation

```bash
# Verify plane-track skill has required sections
grep -q "## Step 1: CHECK" plugins/prp-core/skills/plane-track/SKILL.md && echo "Has check step"
grep -q "## Step 2: CREATE" plugins/prp-core/skills/plane-track/SKILL.md && echo "Has create step"
grep -q "## Step 3: UPDATE" plugins/prp-core/skills/plane-track/SKILL.md && echo "Has update step"

# Verify PRD has Plane Tracking template section
grep -q "## Plane Tracking" plugins/prp-core/commands/prp-prd.md && echo "PRD has Plane Tracking section"

# Verify plan inherits from PRD
grep -q "Plane Tracking" plugins/prp-core/commands/prp-plan.md && echo "Plan references Plane Tracking"
```

### Level 3: Manual Validation

1. Start Claude Code session with Plane MCP connected
2. Run `/prp-prd` — verify it asks for Plane module, creates work item
3. Run `/prp-plan` on resulting PRD — verify it inherits module and creates plan work item
4. Check Plane UI to confirm work items appear in the correct module

---

## ACCEPTANCE CRITERIA

- [x] `.mcp.json` created with Plane MCP server configuration
- [x] `plugins/prp-core/skills/plane-track/SKILL.md` created with create/update actions
- [x] plane-track skill gracefully degrades when Plane MCP is unavailable
- [x] `prp-prd.md` asks for Plane project/module and stores metadata in PRD
- [x] `prp-plan.md` inherits Plane tracking from PRD and creates plan work item
- [x] `prp-implement.md` creates work item at start, updates at completion
- [x] `prp-ralph.md` creates work item at start, updates at completion
- [x] `prp-issue-investigate.md` creates work item using CLAUDE.md default project
- [x] `prp-issue-fix.md` creates work item using CLAUDE.md default project
- [x] `prp-debug.md` creates work item using CLAUDE.md default project
- [x] `prp-codebase-question.md` creates work item using CLAUDE.md default project
- [x] `prp-research-team.md` creates work item using CLAUDE.md default project
- [x] All commands add `PLANE_TRACKED` to success criteria
- [x] Work item title convention `[Type] Description` used consistently
- [x] Metadata propagation chain: PRD -> Plan -> Implement/Ralph works correctly

---

## COMPLETION CHECKLIST

- [x] All tasks (1-11) completed
- [x] plane-track skill created with CHECK/CREATE/UPDATE steps
- [x] PRD command is the entry point for module association
- [x] Plan command inherits and propagates tracking metadata
- [x] Implement and Ralph commands create and close work items
- [x] All 5 standalone commands (investigate, fix, debug, research, research-team) track via CLAUDE.md default
- [x] Graceful degradation pattern applied to all commands
- [x] `.mcp.json` configured for local Plane instance

---

## NOTES

### Design Decisions

**Why a reusable skill instead of inline logic?**
- 11 command files need the same tracking logic — a skill avoids massive duplication
- Follows existing pattern (`context-read` skill)
- Single place to update if Plane API changes

**Why PRD = Module, Command = Work Item?**
- A PRD represents a feature/epic — maps naturally to a Plane module
- Each workflow step (plan, implement, investigate) is a discrete work unit — maps to work items
- This gives a hierarchical view in Plane: Module > Work Items

**Why silent/optional tracking?**
- Plane integration should never block development
- Not all projects will have Plane configured
- Matches the framework's philosophy of graceful degradation

**Resolution order: Artifact > CLAUDE.md > skip**
- Commands derived from PRDs get tracking metadata from the artifact chain
- Standalone commands fall back to CLAUDE.md default project
- If nothing is configured, tracking is skipped entirely — no errors, no prompts

### Trade-offs

**Metadata in markdown files vs. separate config:**
- Chose to embed `## Plane Tracking` sections directly in PRD/plan files
- Pro: All context travels with the artifact, no external dependencies
- Con: Slightly larger artifacts, manual parsing needed
- Alternative considered: `.plane-tracking.json` sidecar files — rejected for complexity

**Work item status mapping:**
- Plane uses custom states per project; we map logical statuses (todo/doing/done) to state groups
- Requires a `list_states` call to resolve — slightly slower but correct across all Plane configurations

<!-- EOF -->
