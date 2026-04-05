---
name: context-read
description: "Non-interactive context loader — finds context-map.md, matches sources by topic, resolves paths, and reads content silently. Used by other PRP commands to auto-load relevant external context. No user prompts."
user-invocable: false
---

# Context Read (Silent)

Load relevant context from the project's `context-map.md` without user interaction. This skill is the shared engine used by both the interactive `/prp-context` command and inline context loading in other PRP commands.

**Input**: `$ARGUMENTS` — a topic, section name, or keyword to match against context-map entries.

---

## When This Skill Is Used

This skill is called automatically by other PRP commands when they need external context:

| Caller | When | Purpose |
|--------|------|---------|
| `prp-plan` | After parsing feature, before codebase exploration | Load domain knowledge for the feature area |
| `prp-prd` | During grounding phases | Load existing domain docs and references |
| `prp-issue-investigate` | Before codebase exploration | Load context for the issue area |
| `prp-debug` | During hypothesis formation | Load domain context for suspected area |
| `prp-codebase-question` | During query parsing | Load external refs related to the question |
| `prp-research-team` | During domain classification | Load context as input material for researchers |
| `/prp-context` | Always (interactive wrapper) | User-facing context lookup with prompts |

---

## Behavior: Silent Mode (Default)

When called by other commands, this skill operates silently:

- **No confirmation prompts** — reads all matched sources immediately
- **No formatted presentation** — returns raw content for the caller to use
- **No `--list` mode** — that's an interactive feature of `/prp-context`
- **Fail gracefully** — if no context-map found or no matches, return empty with a note (don't stop the calling command)

---

## Step 1: LOCATE — Find Context Map

### 1.1 Find context-map.md

Search for `context-map.md` starting from the current working directory, then walking up parent directories. Use the first one found.

**If not found**: Return immediately with:
```
CONTEXT_RESULT: No context-map.md found. Proceeding without external context.
```

Do NOT stop the calling command. Missing context is not an error.

### 1.2 Find Parent CLAUDE.md Source Mappings

Walk up the directory tree to find the nearest parent `CLAUDE.md`. Look for a section called `## Context Sources` containing path mappings:

```
- **{source-name}**: {absolute-base-path}
```

Parse these into a lookup table:

```
source-name → base-path
```

These mappings resolve relative paths for mapped source types. If no mappings section is found, only built-in types (`project`, `file`, `web`) and Obsidian CLI types (`obsidian`, `obsidian-tag`, `obsidian-folder`, `obsidian-search`) will work.

### 1.3 Parse the Context Map

Read `context-map.md` and parse all entries. Each entry follows:

```
- **Label** | `source-type` | `path` | Description
```

Build a structured list:

```
Section: {heading}
  - label: {Label}
    type: {source-type}
    path: {path}
    description: {Description}
```

---

## Step 2: MATCH — Find Relevant Sources

Match the input topic against context-map entries:

1. **Exact section match**: If the topic matches a `##` heading exactly (case-insensitive), select all entries in that section
2. **Label match**: If the topic matches an entry label (case-insensitive, partial match), select that entry
3. **Description match**: If the topic appears in an entry's description, select that entry
4. **Multi-word queries**: Match if ALL words appear across the label + description of an entry

**If no matches found**: Return:
```
CONTEXT_RESULT: No context sources matched '{topic}'. Proceeding without external context.
```

Do NOT stop the calling command. No matches is not an error.

**If matches found**: Proceed directly to reading (no confirmation prompt).

---

## Step 3: RESOLVE — Determine Read Method

For each matched entry, resolve the actual read method:

### Built-in Types

**`project`**: Resolve relative to the project root (directory containing `context-map.md`).
- File → Read tool
- Directory → Glob for `**/*.md` then Read each file (max 10 most recent)

**`file`**: Absolute path, use as-is.
- Read tool directly

**`web`**: URL to fetch.
- WebFetch tool with prompt: "Extract the main content. Preserve technical details, code examples, and structured information."

### Mapped Types (second-brain, shared-docs, etc.)

Look up the source type name in the parent CLAUDE.md mappings from Step 1.2.

**Resolution**: `{base-path from mapping}` + `{path from entry}` → absolute path

- File → Read tool
- Directory → Glob for `**/*.md` then Read each file (max 10 most recent)

If the source type has no mapping: skip it and note:
```
Skipped: Source type '{type}' has no mapping in parent CLAUDE.md.
```

### Obsidian Types (via CLI)

All Obsidian types use the `obsidian` CLI tool. The CLI requires Obsidian to be running. If `obsidian` is not found or returns an error, fall back to the Obsidian MCP tools (`obsidian_get_file_contents`, `obsidian_simple_search`) if available. If neither works, skip and note the error.

**`obsidian`**: Read a single note by vault path.
- Resolution: `obsidian read path="{path}"`
- If path doesn't end in `.md`, try appending `.md`
- The path is relative to the vault root (e.g., `knowledge/projects/MyProject/Design Notes.md`)

**`obsidian-tag`**: Find all notes with a specific tag, then read them.
- Resolution:
  1. `obsidian tag name="{path}" verbose` → get list of file paths
  2. `obsidian read path="{file}"` for each returned file
- The `path` field contains the tag name WITHOUT the `#` prefix (e.g., `type/architecture`, `domain/ai`)
- If more than 10 files match, read only the first 10 and note: "{N} files matched tag #{tag}, reading first 10"

**`obsidian-folder`**: Read all notes in an Obsidian vault folder.
- Resolution:
  1. `obsidian files folder="{path}"` → get list of files
  2. `obsidian read path="{file}"` for each `.md` file
- The `path` field is the folder path relative to vault root (e.g., `knowledge/projects/MyProject`)
- If more than 10 files, read only the first 10 and note the total

**`obsidian-search`**: Search vault content by keyword and read matching notes.
- Resolution:
  1. `obsidian search query="{path}" matches limit=10` → get matching files with context
  2. `obsidian read path="{file}"` for each matching file
- The `path` field contains the search query text
- Returns matching files with the lines that matched, giving context for relevance

### Other MCP Types

**`archon`**: Use the appropriate Archon MCP tool.
- If Archon MCP is not available, skip and note: "Archon MCP not available."

---

## Step 4: READ — Gather Content

### Reading Strategy

**5 or fewer sources**: Read sequentially using resolved methods.

**More than 5 sources**: Use Task tool with `subagent_type="Explore"` to read in parallel batches.

### For each source, capture:

```
SOURCE: {label} ({type})
PATH: {resolved-path}
CONTENT:
{file content, or summary if >500 lines}
```

### Error Handling (Silent)

| Error | Action |
|-------|--------|
| File not found | Note: "Not found: {path}" — continue |
| Directory empty | Note: "No .md files in: {path}" — continue |
| MCP unavailable | Note: "MCP '{type}' not available" — continue |
| URL fetch failed | Note: "Could not fetch: {url}" — continue |
| Permission denied | Note: "Cannot read: {path}" — continue |
| Obsidian CLI not found | Note: "Obsidian CLI not available, trying MCP fallback" — try MCP tools, continue if both fail |
| Obsidian not running | Note: "Obsidian app not running (CLI requires it)" — try MCP tools, continue if both fail |
| Tag not found | Note: "No notes found with tag #{tag}" — continue |
| Search no results | Note: "No vault results for '{query}'" — continue |

**Never stop** on individual source errors. Read what you can.

### Content Size Limits

- Files > 500 lines: Read first 200 lines, note truncation
- Directories with > 10 .md files: Read the 10 most recently modified

---

## Step 5: RETURN — Output for Caller

Return the loaded content in this structure:

```markdown
## Context Loaded

{N} sources loaded from context-map.md ({K} skipped/errors)

### {Section Name}

#### {Source Label}
**Source**: `{type}` | `{path}`

{Content}

---

### {Section Name}

#### {Source Label}
**Source**: `{type}` | `{path}`

{Content}

---
```

If no sources were loaded (all failed or no matches):
```
CONTEXT_RESULT: No external context loaded. Proceeding with codebase-only context.
```

---

## Integration Contract

When other PRP commands call this skill, they should:

1. **Call early** — before codebase exploration, not after
2. **Pass a relevant topic** — derived from the feature description, issue title, or question
3. **Use the output as additional context** — alongside codebase findings, not instead of
4. **Not fail if context is empty** — missing context is never a blocker
5. **Record what was loaded** — in the plan or report for traceability

### Calling Pattern for Other Commands

Other PRP commands integrate this skill with a phase like:

```markdown
### X.X Load External Context (Automatic)

If `context-map.md` exists in the project (search current dir, then walk up):

1. Parse the context map
2. Match entries against the {feature/issue/question} topic
3. If matches found: resolve and read sources silently (no user confirmation)
4. Include loaded context alongside codebase exploration findings
5. If no context-map or no matches: proceed normally — this step is optional

**Note**: This uses the `context-read` skill logic. See `plugins/prp-core/skills/context-read/SKILL.md` for resolution rules.
```

---

## Success Criteria

- **SILENT_OPERATION**: No user prompts or confirmation requests
- **GRACEFUL_DEGRADATION**: Missing context-map, no matches, or read errors never stop the caller
- **CONTENT_LOADED**: Matched sources read and returned
- **ERRORS_NOTED**: Failed reads noted but don't block
- **CALLER_UNBLOCKED**: Calling command always proceeds, with or without context
