# Feature: Rename scaffold-repo to init-project and Add Plane + Context Scaffolding

## Feature Description

Rename the `scaffold-repo` skill to `init-project` to better reflect its purpose, and enhance it with Plane MCP setup (`.mcp.json` generation) and context tracking scaffolding (`context-map.md`). The skill now creates a fully configured project with external work item tracking and context source registry out of the box.

## User Story

As a developer initializing a new project
I want the scaffolding to include Plane MCP configuration and a context map
So that new projects start with work item tracking and context source management already wired up

## Problem Statement

The `scaffold-repo` skill had three gaps:

1. **Naming**: "scaffold-repo" described the mechanism, not the intent. "init-project" better communicates what the developer is doing.

2. **No Plane integration**: New projects had no `.mcp.json` for the Plane MCP server. Developers had to manually configure this after scaffolding, which was easy to forget and error-prone.

3. **No context tracking**: New projects lacked a `context-map.md` file, meaning the `/prp-context` and `/context-add` commands had nothing to work with until manually set up.

4. **No CLAUDE.md Plane section**: The generated `CLAUDE.md` didn't include the `## Plane Integration` section that standalone PRP commands (debug, research, investigate) need to find the default Plane project identifier.

## Solution Statement

1. **Rename** the skill directory from `plugins/prp-core/skills/scaffold-repo/` to `plugins/prp-core/skills/init-project/`
2. **Add Phase 2.4**: Ask the user for Plane integration settings (project identifier, API key, workspace slug, base URL) — all skippable
3. **Add Phase 4.5**: Copy `context-map.md` template into the new project
4. **Add Phase 4.6**: Generate `.mcp.json` with Plane MCP server configuration (real values or placeholders)
5. **Update Phase 4.2**: Append `## Plane Integration` section to the generated CLAUDE.md
6. **Update parent CLAUDE.md references** from `scaffold-repo` to `init-project`

## Feature Metadata

**Feature Type**: Enhancement + Rename
**Estimated Complexity**: Low-Medium
**Primary Systems Affected**:
- `plugins/prp-core/skills/init-project/` — Renamed and enhanced skill
- `D:\Source\CLAUDE.md` — Parent workspace instructions (references updated)
**Dependencies**:
- Plane MCP integration feature (for `.mcp.json` format and Plane Integration section format)
- Existing `context-map.md` template in plugin templates directory

---

## CONTEXT REFERENCES

### Relevant Codebase Files

- `plugins/prp-core/skills/scaffold-repo/SKILL.md` (original, to be replaced) — Existing scaffolding logic
- `plugins/prp-core/templates/context-map.md` — Template for context source registry
- `plugins/prp-core/skills/plane-track/SKILL.md` — Defines the Plane tracking pattern and `.mcp.json` format
- `D:\Source\CLAUDE.md` — Parent workspace instructions with scaffold-repo references

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `plugins/prp-core/skills/init-project/SKILL.md` | CREATE (rename) | Renamed and enhanced skill file |
| `plugins/prp-core/skills/scaffold-repo/SKILL.md` | DELETE | Old skill directory removed |
| `D:\Source\CLAUDE.md` | MODIFY | Update two references from scaffold-repo to init-project |

### Patterns to Follow

**Plane Integration questions pattern** (from `prp-prd.md` Phase 2):
- Ask for project identifier, API key, workspace slug, base URL
- All skippable — use placeholders if skipped
- Present summary before proceeding

**CLAUDE.md Plane Integration section**:
```markdown
## Plane Integration

| Setting | Value |
|---------|-------|
| Default Project | {identifier or "TBD"} |
```

---

## IMPLEMENTATION PLAN

### Phase 1: Rename

- Delete `plugins/prp-core/skills/scaffold-repo/` directory
- Create `plugins/prp-core/skills/init-project/` directory
- Update skill name in YAML frontmatter

### Phase 2: Enhance SKILL.md

- Add Phase 2.4: Plane Integration questions
- Add Phase 4.5: Scaffold `context-map.md` from template
- Add Phase 4.6: Generate `.mcp.json` with Plane MCP config
- Update Phase 4.2: Append `## Plane Integration` section to CLAUDE.md template
- Update Phase 5 commit message and Phase 6 report to include new files

### Phase 3: Update References

- Update `D:\Source\CLAUDE.md` line 51: `/prp-core:scaffold-repo` → `/prp-core:init-project`
- Update `D:\Source\CLAUDE.md` line 159: command reference in Repository Defaults section

---

## STEP-BY-STEP TASKS

### Task 1: DELETE `plugins/prp-core/skills/scaffold-repo/SKILL.md`

- **IMPLEMENT**: Remove old skill directory
- **VALIDATE**: Directory no longer exists

### Task 2: CREATE `plugins/prp-core/skills/init-project/SKILL.md`

- **IMPLEMENT**: Full rewrite of skill with new name and enhanced phases
- **DETAILS**:
  - YAML frontmatter: name=`init-project`, updated description
  - Phase 2.4: Plane Integration questions (identifier, API key, workspace slug, base URL)
  - Phase 2.5: Confirm Settings — now includes Plane Project and Plane Instance
  - Phase 4.2: CLAUDE.md template includes `## Plane Integration` section
  - Phase 4.5: Copy context-map.md from `${CLAUDE_PLUGIN_ROOT}/templates/context-map.md`
  - Phase 4.6: Generate `.mcp.json` (real values if provided, placeholders if skipped)
  - Phase 5: Commit message and file list updated to include context-map.md and .mcp.json
  - Phase 6: Report includes new files and Plane-specific next steps

### Task 3: UPDATE `D:\Source\CLAUDE.md`

- **IMPLEMENT**: Replace two scaffold-repo references with init-project
- **DETAILS**:
  - Line 51: `/prp-core:scaffold-repo repo-name` → `/prp-core:init-project repo-name`
  - Line 159: `/prp-core:scaffold-repo` → `/prp-core:init-project`

---

## VALIDATION COMMANDS

### Level 1: File Structure

```bash
# Old skill removed
test ! -f plugins/prp-core/skills/scaffold-repo/SKILL.md && echo "Old skill removed"

# New skill exists
test -f plugins/prp-core/skills/init-project/SKILL.md && echo "New skill exists"

# Verify skill name
grep -q "^name: init-project$" plugins/prp-core/skills/init-project/SKILL.md && echo "Correct skill name"
```

### Level 2: Content Validation

```bash
# New phases exist
grep -q "Plane Integration" plugins/prp-core/skills/init-project/SKILL.md && echo "Has Plane Integration phase"
grep -q "context-map.md" plugins/prp-core/skills/init-project/SKILL.md && echo "Has context-map scaffolding"
grep -q ".mcp.json" plugins/prp-core/skills/init-project/SKILL.md && echo "Has .mcp.json generation"

# Parent CLAUDE.md updated
grep -q "init-project" D:/Source/CLAUDE.md && echo "Parent CLAUDE.md updated"
! grep -q "scaffold-repo" D:/Source/CLAUDE.md && echo "No old references remain"
```

---

## ACCEPTANCE CRITERIA

- [x] `plugins/prp-core/skills/scaffold-repo/` removed
- [x] `plugins/prp-core/skills/init-project/SKILL.md` created with correct name
- [x] Phase 2.4 asks for Plane integration settings (all skippable)
- [x] Phase 4.2 CLAUDE.md template includes `## Plane Integration` section
- [x] Phase 4.5 scaffolds `context-map.md` from template
- [x] Phase 4.6 generates `.mcp.json` with Plane MCP config (real or placeholder values)
- [x] Phase 5 commit includes context-map.md and .mcp.json
- [x] Phase 6 report lists all new files and Plane-specific next steps
- [x] `D:\Source\CLAUDE.md` references updated from scaffold-repo to init-project
- [x] `scaffold-repo.json` config file name preserved (not renamed — it's the config format, not the skill name)

---

## COMPLETION CHECKLIST

- [x] Old skill directory deleted
- [x] New skill created with enhanced phases
- [x] Plane Integration questions added (Phase 2.4)
- [x] Context-map scaffolding added (Phase 4.5)
- [x] .mcp.json generation added (Phase 4.6)
- [x] CLAUDE.md template enhanced with Plane section
- [x] Parent CLAUDE.md references updated
- [x] All acceptance criteria met

---

## NOTES

### Design Decisions

**Why keep `scaffold-repo.json` name?**
- The config file name is a format/convention, not tied to the skill name
- Existing repos may already have `scaffold-repo.json` files
- Renaming the config would break backward compatibility for no benefit

**Why ask for Plane settings during init?**
- Setting up Plane at project creation means work tracking is available from the first `/prp-prd` invocation
- All questions are skippable — the skill generates placeholder values that can be filled in later
- Matches the principle of "batteries included but optional"

**Why scaffold context-map.md?**
- The `/prp-context` and `/context-add` commands expect `context-map.md` to exist
- Without it, context features are non-functional until manual setup
- Copying from the template gives users a ready-to-use registry with documentation

<!-- EOF -->
