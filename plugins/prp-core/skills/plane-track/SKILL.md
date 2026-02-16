---
name: plane-track
description: "Non-interactive Plane work item tracker — creates and updates work items in Plane for PRP workflow steps. Silent, optional, gracefully degrades if Plane MCP is unavailable."
user-invocable: false
---

# Plane Track (Silent)

Create and manage Plane work items for PRP workflow steps. Each PRP command invocation (plan, implement, investigate, etc.) gets a corresponding Plane work item for persistent tracking.

**Input**: Caller passes structured fields (see interface below). This skill is never called directly by users.

---

## When This Skill Is Used

This skill is called by PRP commands to track workflow steps in Plane:

| Caller | When | Work Item Type |
|--------|------|----------------|
| `prp-prd` | After generating PRD | `[PRD]` |
| `prp-plan` | After generating plan | `[Plan]` |
| `prp-implement` | At start and completion | `[Implement]` |
| `prp-ralph` | At start and completion | `[Ralph]` |
| `prp-issue-investigate` | At start and completion | `[Investigate]` |
| `prp-issue-fix` | At start and completion | `[Fix]` |
| `prp-debug` | At start and completion | `[Debug]` |
| `prp-codebase-question` | At start and completion | `[Research]` |
| `prp-research-team` | At start and completion | `[Research-Team]` |

---

## Behavior: Silent Mode

- **No user prompts** — creates/updates work items silently
- **Fail gracefully** — if Plane MCP is unavailable, log a note and return empty. Never block the calling command.
- **Returns structured data** — caller stores IDs in artifact metadata

---

## Caller Interface

The calling command provides these fields:

| Field | Required | Description |
|-------|----------|-------------|
| `action` | yes | `create` or `update` |
| `type` | yes (create) | PRD, Plan, Implement, Ralph, Investigate, Fix, Debug, Research, Research-Team |
| `title` | yes (create) | Human-readable work description |
| `project_identifier` | yes | Plane project identifier (e.g., `PROJ`) |
| `module_id` | no | Plane module ID — if provided, work item is added to this module |
| `description` | no | Longer description with context |
| `priority` | no | `urgent`, `high`, `medium`, `low`, `none` (default: `none`) |
| `work_item_id` | yes (update) | Plane work item ID to update |
| `status` | no (update) | Target status to transition to |

---

## Step 1: CHECK — Verify Plane MCP Availability

### 1.1 Test Connection

Attempt to call the Plane MCP `list_projects` tool with a minimal query.

**If Plane MCP is not available** (tool not found, connection error, timeout):

Return immediately:
```
PLANE_RESULT: Plane MCP not available. Skipping work item tracking.
```

Do NOT stop the calling command. Missing Plane tracking is never an error.

### 1.2 Resolve Project

Use the `project_identifier` to find the Plane project:

1. Call `list_projects` from the Plane MCP
2. Match the project by its identifier field
3. Extract the `project_id`

**If project not found**: Return with:
```
PLANE_RESULT: Project '{project_identifier}' not found in Plane. Skipping work item tracking.
```

---

## Step 2: CREATE — Create Work Item

**Only when `action = create`.**

### 2.1 Format Title

Apply the type prefix convention:
```
[{type}] {title}
```

Examples:
- `[PRD] Add user authentication`
- `[Plan] Add user authentication - Phase 1`
- `[Implement] Add user authentication - Phase 1`
- `[Investigate] Issue #123 - Login fails on mobile`
- `[Debug] Memory leak in WebSocket handler`
- `[Research] Authentication patterns in codebase`

### 2.2 Create the Work Item

Call the Plane MCP `create_work_item` tool:

```
project_id: {resolved project_id}
name: [{type}] {title}
description_html: <p>{description}</p>   (if description provided)
priority: {priority or "none"}
```

Store the returned `id` and `identifier` (e.g., `PROJ-42`).

### 2.3 Associate to Module (if module_id provided)

If the caller provided a `module_id`:

Call the Plane MCP `add_work_items_to_module` tool:
```
project_id: {project_id}
module_id: {module_id}
work_item_ids: [{work_item_id}]
```

### 2.4 Return Result

```
PLANE_RESULT:
  work_item_id: {id}
  identifier: {identifier}
  module_id: {module_id or "none"}
  url: {PLANE_BASE_URL}/{workspace}/projects/{project_id}/work-items/{id}
```

---

## Step 3: UPDATE — Update Work Item Status

**Only when `action = update`.**

### 3.1 Resolve Target State

The caller provides a logical status. Map it to a Plane state:

| Logical Status | Plane State Name |
|----------------|------------------|
| `todo` | Look up state with group `backlog` or `unstarted` |
| `doing` | Look up state with group `started` |
| `review` | Look up state with group `started` (name containing "review" if available) |
| `done` | Look up state with group `completed` |

To resolve: call `list_states` for the project and match by group name. Cache the state mapping for the session.

### 3.2 Update the Work Item

Call the Plane MCP `update_work_item` tool:
```
project_id: {project_id}
work_item_id: {work_item_id}
state_id: {resolved state_id}
```

### 3.3 Return Result

```
PLANE_RESULT:
  work_item_id: {work_item_id}
  status: {logical status}
  state_name: {actual Plane state name}
```

---

## Integration Contract

### For Callers (PRP Commands)

**Creating a work item:**

```markdown
<!-- In your command, after generating the artifact: -->

**Plane Tracking** (silent, using `plane-track` skill logic):
1. Resolve project from Plane Tracking metadata (PRD > plan > CLAUDE.md default)
2. Call plane-track skill: action=create, type="{Type}", title="{title}", project_identifier="{id}", module_id="{id if available}"
3. Store returned work_item_id and identifier in artifact's ## Plane Tracking table
4. If Plane unavailable, proceed without tracking
```

**Updating a work item:**

```markdown
<!-- At completion: -->

**Plane Tracking** (silent, using `plane-track` skill logic):
1. Parse ## Plane Tracking from the artifact to get work_item_id and project_identifier
2. Call plane-track skill: action=update, work_item_id="{id}", project_identifier="{id}", status="done"
3. If Plane unavailable, proceed without updating
```

### Resolution Order for Project Identifier

Commands resolve the Plane project identifier in this order:

1. **Artifact metadata** — `## Plane Tracking` section in the PRD or plan file being processed
2. **CLAUDE.md default** — `## Plane Integration` section with `Default Project` setting
3. **Skip** — If neither found, skip Plane tracking silently

---

## Error Handling

| Error | Action |
|-------|--------|
| Plane MCP not connected | Skip silently, return empty result |
| Project not found | Skip silently, return empty result |
| Module not found | Create work item without module, note in result |
| State not found | Use default state, note in result |
| API error (timeout, 5xx) | Skip silently, return empty result |
| Authentication error (401/403) | Skip silently, note "Plane auth failed" in result |

**Golden Rule**: Plane tracking is always optional. Never block a PRP workflow because of a Plane error.

---

## Success Criteria

- **SILENT**: No user prompts, no interactive questions
- **GRACEFUL**: Never blocks the calling command on failure
- **TRACKED**: Work items appear in correct Plane project and module
- **CONSISTENT**: Title convention `[Type] Description` applied uniformly
- **STATEFUL**: Work items move through status lifecycle correctly
