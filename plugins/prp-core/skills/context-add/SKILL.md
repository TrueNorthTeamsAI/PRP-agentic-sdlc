---
name: context-add
description: Add a new entry to the project's context-map.md — auto-detects source type and converts absolute paths to mapped relative paths
argument-hint: <path, URL, or description of source>
---

# Add Context Source

Add a new entry to this project's `context-map.md`. Handles path detection, source type resolution, and relative path conversion using the parent CLAUDE.md mappings.

**Input**: `$ARGUMENTS`

---

## Phase 1: Preconditions

### 1.1 Validate Input

The user must provide at least a path, URL, or description of the source to add.

```
Input: $ARGUMENTS
```

If `$ARGUMENTS` is empty or blank, ask the user:
> "What context source would you like to add? Provide a file path, folder path, URL, or describe what you're looking for."

### 1.2 Find or Create context-map.md

Search for `context-map.md` in the current working directory (project root).

**If found**: Read it and parse existing sections.

**If not found**: Ask the user:
> "No `context-map.md` found in this project. Create one from the PRP template?"

If yes, copy the template from `${CLAUDE_PLUGIN_ROOT}/templates/context-map.md` to the project root.

### 1.3 Load Parent CLAUDE.md Source Mappings

Walk up the directory tree to find the nearest parent `CLAUDE.md`. Look for the `## Context Sources` section and parse the path mappings:

```
- **{source-name}**: {absolute-base-path}
```

Build a reverse lookup table for path-to-source-type detection:

```
D:\Source\TrueNorthTeams\2nd-brain-openclaw-node-browser-automation\ → second-brain
D:\Source\TrueNorthTeams\archon-kb\ → archon
```

Sort by longest path first so more specific mappings match before general ones.

**PHASE_1_CHECKPOINT:**
- [ ] Input provided
- [ ] context-map.md located or created
- [ ] Parent CLAUDE.md mappings loaded (if available)

---

## Phase 2: Detect Source Type

### 2.1 Analyze the Input

Determine the source type from the input:

| Input Pattern | Detected Type | Path Handling |
|--------------|---------------|---------------|
| Starts with `http://` or `https://` | `web` | Use URL as-is |
| Absolute path inside a mapped base path | Mapped type (e.g., `second-brain`) | Convert to relative |
| Absolute path inside the project directory | `project` | Convert to relative |
| Absolute path elsewhere | `file` | Use as-is |
| Relative path (no drive letter, no leading `/`) | `project` | Use as-is |
| Starts with `obsidian:` | `obsidian` | Strip prefix, use as vault path |
| Starts with `obsidian-tag:` or mentions "obsidian tag" | `obsidian-tag` | Strip prefix, use as tag name (no `#`) |
| Starts with `obsidian-folder:` or mentions "obsidian folder" | `obsidian-folder` | Strip prefix, use as vault folder path |
| Starts with `obsidian-search:` or mentions "obsidian search" | `obsidian-search` | Strip prefix, use as search query |
| Mentions "obsidian" or "vault" (generic) | Ask user | Prompt: "Which Obsidian source type? (file, tag, folder, search)" |
| Mentions "archon" or "knowledge base" | `archon` | Ask for KB identifier |

### 2.2 Reverse-Resolve Mapped Types

For absolute paths, check against the reverse lookup table from Phase 1.3:

1. Normalize the input path (resolve `\` vs `/`, ensure trailing separator)
2. Check if the path starts with any mapped base path
3. If yes: set type to the mapping name, strip the base path to get the relative path
4. If no: check if it's inside the project directory for `project` type, otherwise use `file`

**Example**:
- Input: `D:\Source\TrueNorthTeams\2nd-brain-openclaw-node-browser-automation\Architecture\Auth Design.md`
- Mapping: `second-brain` → `D:\Source\TrueNorthTeams\2nd-brain-openclaw-node-browser-automation\`
- Result: type = `second-brain`, path = `Architecture/Auth Design.md`

### 2.3 Verify the Source Exists

Before adding, verify the source is accessible:

| Type | Verification |
|------|-------------|
| `project` | Check file/directory exists with Glob or Read |
| `file` | Check file exists with Read |
| `web` | No verification (URLs may be valid but unreachable) |
| `second-brain` | Check resolved absolute path exists |
| `obsidian` | `obsidian read path="{path}"` via CLI (or MCP fallback) |
| `obsidian-tag` | `obsidian tag name="{tag}"` — check tag exists and has files |
| `obsidian-folder` | `obsidian files folder="{folder}"` — check folder has files |
| `obsidian-search` | No verification (search results vary over time) |
| `archon` | No verification (MCP may not be connected) |

If the source doesn't exist, warn the user but allow adding anyway:
> "Warning: `{resolved-path}` does not exist. Add the entry anyway? It may be a planned source or the path may need correction."

**PHASE_2_CHECKPOINT:**
- [ ] Source type detected
- [ ] Path converted to relative (if applicable)
- [ ] Source existence verified (or warning issued)

---

## Phase 3: Gather Entry Details

### 3.1 Determine the Section

Parse existing sections from context-map.md. Present them as options:

> "Which section should this entry go under?"
>
> 1. Architecture
> 2. Infrastructure
> 3. Domain Knowledge
> 4. Reference
> 5. Create new section...

If the user picks "Create new section", ask for the section name.

### 3.2 Determine the Label

Suggest a label based on the filename or path:

- File path → filename without extension, title-cased
- URL → page title or domain name
- Directory → directory name, title-cased

> "Label for this source? (suggested: **{suggestion}**)"

Accept the suggestion or a custom label from the user.

### 3.3 Determine the Description

Ask for a brief description:

> "One-line description of what this source contains:"

### 3.4 Confirm Entry

Present the complete entry for confirmation:

```
New context entry:

  Section:     ## {Section}
  Entry:       - **{Label}** | `{type}` | `{path}` | {Description}

Add this entry? (yes/no)
```

**PHASE_3_CHECKPOINT:**
- [ ] Section selected (existing or new)
- [ ] Label determined
- [ ] Description provided
- [ ] User confirmed

---

## Phase 4: Write Entry

### 4.1 Locate Insert Position

Find the target section heading (`## {Section}`) in context-map.md.

- If the section has existing entries, insert after the last entry in that section
- If the section is empty (only has a comment), insert after the comment
- If creating a new section, append it before the last section or at the end of the file

### 4.2 Format and Insert

Format the entry line:

```
- **{Label}** | `{type}` | `{path}` | {Description}
```

Use the Edit tool to insert the entry at the correct position.

### 4.3 Verify

Read the modified context-map.md and verify:
- The new entry is present
- The file still parses correctly (no broken formatting)
- The entry is under the correct section

**PHASE_4_CHECKPOINT:**
- [ ] Entry inserted at correct position
- [ ] File formatting verified
- [ ] Entry appears under correct section

---

## Phase 5: Report

Display the result:

```
Context source added:

  Section: ## {Section}
  - **{Label}** | `{type}` | `{path}` | {Description}

  File: context-map.md

To look up this context: /prp-context {section-name}
To see all sources:      /prp-context --list
```

---

## Usage Examples

```bash
# Add a file from the second brain (auto-detects mapped type)
/prp-context-add "D:\Source\TrueNorthTeams\2nd-brain\Architecture\Auth Design.md"

# Add a project-local reference doc
/prp-context-add docs/reference/api-spec.md

# Add a web resource
/prp-context-add https://react.dev/blog/react-19

# Add an Obsidian note by vault path
/prp-context-add obsidian:Projects/MyProject/Design Notes

# Add all Obsidian notes tagged with a specific tag
/prp-context-add obsidian-tag:type/architecture

# Add all notes in an Obsidian vault folder
/prp-context-add obsidian-folder:knowledge/projects/MyProject

# Add an Obsidian search (matches notes by keyword)
/prp-context-add obsidian-search:authentication flow

# Add an Archon knowledge base
/prp-context-add archon:project-domain

# Descriptive input (will prompt for details)
/prp-context-add "the infrastructure runbook from the infra repo"
```

---

## Critical Reminders

1. **Always reverse-resolve paths.** Never store absolute paths when a mapped relative path is possible. This keeps context-map.md portable.

2. **Preserve existing formatting.** When inserting entries, match the indentation and style of existing entries in the file.

3. **Don't reorganize.** Only add the new entry. Don't move, rename, or restructure existing entries.

4. **Section comments are optional.** If a section has an HTML comment (like `<!-- ... -->`), insert the entry after the comment, not before it.

5. **One entry at a time.** If the user wants to add multiple sources, process them one at a time with confirmation for each.

---

## Success Criteria

- **INPUT_PARSED**: User's input understood and source identified
- **TYPE_DETECTED**: Source type correctly determined from path/URL
- **PATH_RELATIVE**: Absolute paths converted to mapped relative paths where possible
- **ENTRY_ADDED**: New entry written to context-map.md under correct section
- **FORMAT_PRESERVED**: Existing file formatting maintained
