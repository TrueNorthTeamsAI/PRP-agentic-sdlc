---
description: Look up and read project context from the context map — gathers external docs, knowledge base entries, and references by topic
argument-hint: <topic, section name, or --list> [--section <name>] [--deep]
---

# Context Lookup

**Input**: $ARGUMENTS

---

## Your Mission

Read the project's `context-map.md`, find sources matching the user's query, read/fetch those sources, and present an organized synthesis. You are a context gatherer — your job is to load relevant information into the conversation so the user (or a downstream command like `/prp-plan`) can use it.

**Core Philosophy**: Gather and present. Do not analyze, critique, or suggest changes to the source material. Present what the documents say.

**Architecture Note**: This command is the **interactive, user-facing wrapper** around the `context-read` skill (`plugins/prp-core/skills/context-read/SKILL.md`). The skill contains the core resolution logic (find context-map, parse entries, resolve paths, read sources). This command adds interactive features: `--list` mode, user confirmation before reading, and formatted presentation. Other PRP commands (like `prp-plan`) call the `context-read` skill directly in silent mode — no prompts, no formatting.

---

## Phase 1: LOCATE — Find the Context Map

### 1.1 Find context-map.md

Search for `context-map.md` starting from the current working directory, then walking up parent directories. Use the first one found.

If not found:
> "No `context-map.md` found in this project or parent directories. Create one with `/prp-context-add` or copy the template from the PRP plugin."

Stop here if not found.

### 1.2 Find Parent CLAUDE.md Source Mappings

Search for the nearest parent `CLAUDE.md` by walking up the directory tree. Look for a section called `## Context Sources` containing path mappings in this format:

```
- **{source-name}**: {absolute-base-path}
```

Parse these into a lookup table:

```
source-name → base-path
```

These mappings are used to resolve relative paths for mapped source types. If no mappings section is found, only built-in types (`project`, `file`, `web`) and MCP types (`archon`, `obsidian`) will work.

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

**PHASE_1_CHECKPOINT:**
- [ ] context-map.md located and read
- [ ] Parent CLAUDE.md source mappings parsed (if available)
- [ ] All entries parsed into structured list

---

## Phase 2: MATCH — Find Relevant Sources

### 2.1 Parse Arguments

| Argument | Behavior |
|----------|----------|
| `--list` | List all sections and entries, then stop (no reading) |
| `--section <name>` | Read ALL entries under the named section |
| `--deep` | Use subagents for parallel reading of large source sets |
| `<topic>` | Fuzzy match against section names, labels, and descriptions |

### 2.2 Handle --list

If `--list` is specified, output the full context map in a readable format and stop:

```markdown
## Context Map: {project-name}

### {Section 1}
- **{Label}** (`{type}`) — {Description}
- **{Label}** (`{type}`) — {Description}

### {Section 2}
- ...
```

### 2.3 Match Sources

For topic-based queries (not `--list` or `--section`):

1. **Exact section match**: If the query matches a `##` heading exactly (case-insensitive), select all entries in that section
2. **Label match**: If the query matches an entry label (case-insensitive, partial match), select that entry
3. **Description match**: If the query appears in an entry's description, select that entry
4. **Multi-word queries**: Match if ALL words appear across the label + description of an entry

If no matches found:
> "No context sources matched '{query}'. Use `/prp-context --list` to see all available sources."

Present matched entries and confirm with the user before reading:

```
Found {N} matching sources:
  1. **{Label}** (`{type}`) — {Description}
  2. **{Label}** (`{type}`) — {Description}

Read these sources? (yes / select specific numbers / no)
```

**PHASE_2_CHECKPOINT:**
- [ ] Arguments parsed
- [ ] Sources matched (or --list output displayed)
- [ ] User confirmed sources to read

---

## Phase 3: RESOLVE — Determine How to Read Each Source

For each matched entry, resolve the actual read method:

### 3.1 Built-in Types

**`project`**: Resolve relative to the project root (directory containing `context-map.md`).
- If path points to a file → Read tool
- If path points to a directory → Glob for `**/*.md` then Read each file

**`file`**: Use the path as-is (absolute).
- Read tool directly

**`web`**: URL to fetch.
- WebFetch tool with prompt: "Extract and summarize the main content of this page. Preserve key technical details, code examples, and structured information."

### 3.2 Mapped Types (second-brain, shared-docs, etc.)

Look up the source type name in the parent CLAUDE.md mappings from Phase 1.2.

**Resolution**: `{base-path from mapping}` + `{path from entry}` → absolute path

- If resolved path is a file → Read tool
- If resolved path is a directory → Glob for `**/*.md` then Read each file

If the source type has no mapping in the parent CLAUDE.md:
> "Source type `{type}` has no mapping in the parent CLAUDE.md. Add it under `## Context Sources`:\n  `- **{type}**: {absolute-base-path}`"

### 3.3 Obsidian Types (via CLI)

All Obsidian types use the `obsidian` CLI tool (requires Obsidian to be running). If the CLI is unavailable, fall back to Obsidian MCP tools (`obsidian_get_file_contents`, `obsidian_simple_search`). See `plugins/prp-core/skills/context-read/SKILL.md` for full resolution rules.

**`obsidian`**: Read a single note by vault path.
- `obsidian read path="{path}"`
- Path is relative to vault root (e.g., `knowledge/projects/MyProject/Design Notes.md`)

**`obsidian-tag`**: Find and read all notes with a specific tag.
- `obsidian tag name="{tag}" verbose` → get file list
- `obsidian read path="{file}"` for each file (max 10)
- Path field = tag name without `#` (e.g., `type/architecture`)

**`obsidian-folder`**: Read all notes in a vault folder.
- `obsidian files folder="{folder}"` → get file list
- `obsidian read path="{file}"` for each `.md` file (max 10)
- Path field = folder path relative to vault root (e.g., `knowledge/projects/MyProject`)

**`obsidian-search`**: Search vault by keyword and read matching notes.
- `obsidian search query="{query}" matches limit=10` → matching files with context
- `obsidian read path="{file}"` for each match
- Path field = the search query text

### 3.4 Other MCP Types

**`archon`**: Query via Archon MCP server.
- Use the appropriate Archon MCP tool to query the knowledge base
- The path field serves as the query or knowledge base identifier
- If Archon MCP is not connected, report: "Archon MCP server is not available in this session. Start it and retry."

**PHASE_3_CHECKPOINT:**
- [ ] Every matched source has a resolved read method
- [ ] Unresolvable sources reported to user

---

## Phase 4: READ — Gather Content

### 4.1 Read Sources

**If `--deep` flag or more than 5 sources**: Use Task tool with `subagent_type="Explore"` to read sources in parallel. Give each subagent a batch of sources to read and summarize.

**Otherwise**: Read sources sequentially using the resolved methods from Phase 3.

For each source, capture:
- Source label and type
- Full content (or summary if content exceeds ~2000 lines)
- Any errors encountered (file not found, MCP unavailable, URL unreachable)

### 4.2 Handle Errors Gracefully

| Error | Action |
|-------|--------|
| File not found | Report: "Source not found: `{path}`. The context map entry may be stale." |
| Directory empty | Report: "No .md files found in: `{path}`" |
| MCP unavailable | Report: "MCP server `{type}` is not available in this session" |
| URL fetch failed | Report: "Could not fetch: `{url}`" |
| Permission denied | Report: "Cannot read: `{path}` — permission denied" |

Continue reading other sources even if some fail.

**PHASE_4_CHECKPOINT:**
- [ ] All resolvable sources read
- [ ] Errors reported for unreadable sources
- [ ] Content captured for each source

---

## Phase 5: PRESENT — Synthesize and Output

### 5.1 Organize by Section

Group the gathered content by context-map section:

```markdown
## Context Loaded

### {Section Name}

#### {Source Label}
**Source**: `{type}` — `{path}`

{Content or summary of the source}

---

#### {Source Label}
**Source**: `{type}` — `{path}`

{Content or summary of the source}

---

### {Section Name}

...
```

### 5.2 Summary

After presenting all sources, provide a brief summary:

```markdown
## Summary

**Sources loaded**: {N} of {M} matched ({K} errors)
**Sections covered**: {list of sections}
**Errors**: {list any failed sources, or "None"}

This context is now available in the conversation. You can:
- Ask questions about the loaded content
- Use `/prp-plan` to start planning with this context
- Use `/prp-context <other-topic>` to load additional context
```

**PHASE_5_CHECKPOINT:**
- [ ] Content organized by section
- [ ] Summary with stats presented
- [ ] Errors clearly reported

---

## Usage Examples

```bash
# List all available context sources
/prp-context --list

# Load all infrastructure context
/prp-context infrastructure

# Load a specific section
/prp-context --section "Domain Knowledge"

# Search by topic keyword
/prp-context authentication

# Load multiple topics (space-separated words matched across labels/descriptions)
/prp-context "API contracts auth"

# Deep read with parallel agents for large source sets
/prp-context --deep architecture
```

---

## Integration with Other Commands

Other PRP commands do NOT call this command directly. Instead, they use the `context-read` skill (`plugins/prp-core/skills/context-read/SKILL.md`) which operates in silent mode — no user prompts, no confirmation, graceful degradation if no context is available.

The following commands auto-load context via the `context-read` skill:
- `/prp-plan` — loads context relevant to the feature before codebase exploration
- `/prp-prd` — loads domain context during grounding phases
- `/prp-issue-investigate` — loads context for the issue area before exploration
- `/prp-debug` — loads domain context during hypothesis formation
- `/prp-codebase-question` — loads external refs related to the question
- `/prp-research-team` — loads context as input material for researchers

This `/prp-context` command is for **interactive use** — when the user wants to browse, search, and explore context sources manually.

---

## Critical Reminders

1. **Gather, don't analyze.** Present source content faithfully. No opinions or suggestions.

2. **Resolve paths carefully.** Always check the parent CLAUDE.md for source type mappings before declaring a type unresolvable.

3. **Report errors, don't stop.** If one source fails, continue reading the rest.

4. **Respect content size.** For very large files (>500 lines), present the first 200 lines and note the truncation. For directories with many files, summarize file count and read the most recent 10.

5. **MCP availability varies.** Not all MCP servers are available in every session. Report unavailability clearly.

---

## Success Criteria

- **CONTEXT_MAP_FOUND**: Located and parsed `context-map.md`
- **SOURCES_MATCHED**: Relevant sources identified from user query
- **PATHS_RESOLVED**: All source types resolved via mappings or built-in rules
- **CONTENT_LOADED**: Source content read and presented
- **ERRORS_REPORTED**: Any failures clearly communicated
- **NO_ANALYSIS**: Content presented as-is, no critique or suggestions
