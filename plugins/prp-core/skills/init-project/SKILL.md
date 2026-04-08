---
name: init-project
description: Create a new GitHub repo, clone it, and scaffold with CLAUDE.md template, .gitignore, README, context-map.md, and Jira MCP integration. Pass the repo name as an argument. Reads defaults from parent CLAUDE.md.
argument-hint: <repo-name>
---

# Initialize New Project

Create a new GitHub repository with proper PRP framework scaffolding. This skill handles repo creation, cloning, and initial file setup so every project starts with the right structure — including context tracking and Jira issue tracking.

**Input**: `$ARGUMENTS`

---

## Phase 1: Preconditions

### 1.1 Validate Arguments

The repo name is required:

```
Repo name: $ARGUMENTS
```

If `$ARGUMENTS` is empty or blank, stop and ask the user:
> "What should the new repository be named? Use lowercase with hyphens (e.g., `my-new-api`)."

Validate the repo name:
- Must contain only lowercase letters, numbers, and hyphens
- Must not start or end with a hyphen
- Must be between 1 and 100 characters

If invalid, explain the rules and ask for a corrected name.

### 1.2 Check Prerequisites

Run these checks and fail fast with helpful messages:

1. **GitHub CLI**: Run `gh auth status`
   - If not authenticated: "Please run `gh auth login` first to authenticate with GitHub."
   - If `gh` not found: "The GitHub CLI (`gh`) is required. Install it from https://cli.github.com/"

2. **Git**: Run `git --version`
   - If not found: "Git is required. Install it from https://git-scm.com/"

**PHASE_1_CHECKPOINT**:
- [ ] Repo name is valid
- [ ] `gh` is authenticated
- [ ] `git` is available

---

## Phase 2: Discover Defaults & Gather Input

### 2.1 Read Repository Defaults

Search for the nearest `scaffold-repo.json` by walking up the directory tree from the current working directory. Use the first one found. Parse its values verbatim — do not merge with other config files further up the tree.

If no `scaffold-repo.json` is found, fall back to searching for the nearest `CLAUDE.md` and look for a section called `## Repository Defaults` containing:

- **GitHub Owner** (e.g., `TrueNorthTeamsAI`)
- **Default Visibility** (e.g., `private`)
- **Dev Directory** (e.g., `D:\Source\TrueNorthTeams`)

If neither is found or any value is missing, ask the user for the missing values:
- "What GitHub owner (user or org) should own this repo?"
- "Should the repo be public or private?" (default: private)
- "What directory should the repo be cloned into?" (default: current working directory's parent)

### 2.2 Select Tech Stack

Ask the user to choose a tech stack. Present these options:

| # | Stack | Template |
|---|-------|----------|
| 1 | Next.js 15 / React 19 | `CLAUDE-NEXTJS-15.md` |
| 2 | React (Vite/CRA) | `CLAUDE-REACT.md` |
| 3 | Node.js | `CLAUDE-NODE.md` |
| 4 | Python | `CLAUDE-PYTHON-BASIC.md` |
| 5 | Java (Maven) | `CLAUDE-JAVA-MAVEN.md` |
| 6 | Java (Gradle) | `CLAUDE-JAVA-GRADLE.md` |
| 7 | Rust | `CLAUDE-RUST.md` |
| 8 | Astro | `CLAUDE-ASTRO.md` |
| 9 | Other / None | No template (blank CLAUDE.md) |

Record the user's choice and map it to the template filename.

### 2.3 Select Git Strategy

Ask the user to choose a git strategy for the project. This is a project-wide setting stored in CLAUDE.md that controls how all PRP commands handle branching and commits.

> **Git Strategy** — How should PRP commands handle branching?
>
> | # | Strategy | Description |
> |---|----------|-------------|
> | 1 | `none` | No git operations. You manage git manually. |
> | 2 | `main-only` | All work on current branch, auto-commit after each step. **(default)** |
> | 3 | `branch-per-prd` | One feature branch per PRD. All phases commit there. PR back to base branch when PRD is complete. |
> | 4 | `branch-per-phase` | Separate branch per implementation phase. Phase branches PR back to PRD branch, then PRD branch PRs back to base branch. |
>
> Enter a number or strategy name (default: 2 / `main-only`):

If the user presses enter or gives no input, default to `main-only`.

Then ask for the base development branch:

> **Base Branch** — What is the base development branch? (default: `main`)
>
> This is where feature branches originate from and merge back to. Common choices: `main`, `dev`, `develop`.

If the user presses enter or gives no input, default to `main`.

Record the selected strategy and base branch for writing into CLAUDE.md and the rules file.

### 2.4 Project Description

Ask the user:
> "Give a one-line description of this project (used in GitHub repo description and README):"

### 2.5 Jira Integration

Ask the user:
> **Jira Integration** (for issue tracking):
>
> 1. **Jira URL** — Your Jira instance URL (e.g., `https://your-org.atlassian.net`).
>    Enter the URL, or "skip" to set up later.
>
> 2. **Jira username** — Your Jira username (usually your email address).
>    Or "skip" to configure `.mcp.json` manually later.
>
> 3. **Jira API token** — Your Jira API token (generate at https://id.atlassian.com/manage-profile/security/api-tokens).
>    Or "skip" to configure later.

If the user skips all Jira questions, `.mcp.json` will include the Jira server with placeholder values that need to be filled in.

### 2.6 Confirm Settings

Present a summary and ask for confirmation before proceeding:

```
Project Settings:
  Name:           {repo-name}
  Owner:          {owner}
  Visibility:     {visibility}
  Tech Stack:     {stack-name}
  Git Strategy:   {git-strategy}
  Base Branch:    {base-branch}
  Directory:      {dev-directory}\{repo-name}
  Description:    {description}
  Jira URL:       {jira-url or "Not configured"}
  Jira Username:  {jira-username or "Not configured"}

Proceed? (yes/no)
```

Wait for user confirmation. If "no", ask what to change.

**PHASE_2_CHECKPOINT**:
- [ ] GitHub owner determined
- [ ] Visibility determined
- [ ] Dev directory determined
- [ ] Tech stack selected
- [ ] Git strategy selected
- [ ] Base branch confirmed
- [ ] Description provided
- [ ] Jira integration settings collected (or explicitly skipped)
- [ ] User confirmed settings

---

## Phase 3: Create GitHub Repository

### 3.1 Create the Repo

Run:
```bash
gh repo create {owner}/{repo-name} --{visibility} --description "{description}" --clone=false
```

### 3.2 Handle Errors

- **Repo already exists**: Ask the user:
  > "Repository `{owner}/{repo-name}` already exists. Would you like to:
  > 1. Clone it and scaffold (skip creation)
  > 2. Abort"

  If option 1: skip to Phase 4.
  If option 2: stop.

- **Permission denied**: "You don't have permission to create repos under `{owner}`. Check your GitHub access or use a different owner."

- **Other errors**: Report the error and stop.

**PHASE_3_CHECKPOINT**:
- [ ] GitHub repository created (or already exists and user chose to continue)

---

## Phase 4: Clone & Scaffold

### 4.1 Clone the Repository

```bash
gh repo clone {owner}/{repo-name} "{dev-directory}/{repo-name}"
```

Then change into the new directory and set the default repo for GitHub CLI operations (ensures PRs target the origin, not an upstream fork):

```bash
cd "{dev-directory}/{repo-name}"
gh repo set-default {owner}/{repo-name}
```

### 4.2 Scaffold CLAUDE.md

**If a template was selected (options 1-8):**

Read the template from:
```
${CLAUDE_PLUGIN_ROOT}/templates/claude-md/{template-filename}
```

Customize the template:
- Find the first `# CLAUDE.md` or `# ` heading line
- Replace it with: `# CLAUDE.md - {repo-name}`
- After the heading, insert a project overview paragraph:
  ```
  > {description}
  ```
- Keep all remaining template content intact — it contains valuable framework-specific conventions and rules
- Append the Git Strategy section at the end of the file (before any trailing blank lines):
  ```markdown
  ## Git Strategy

  Strategy: `{git-strategy}`
  Base Branch: `{base-branch}`
  ```

Write the customized content to `{dev-directory}/{repo-name}/CLAUDE.md`.

**If "Other / None" was selected (option 9):**

Write a minimal CLAUDE.md:
```markdown
# CLAUDE.md - {repo-name}

> {description}

## Project Overview

<!-- Describe: what it is, tech stack, key dependencies -->

## Essential Commands

<!-- Dev server, test, lint, build, deploy commands -->

## Architecture

<!-- Directory structure, key patterns, where things live -->

## Project-Specific Conventions

<!-- Naming patterns, gotchas, unique patterns -->

## Git Strategy

Strategy: `{git-strategy}`

```

### 4.3 Generate .gitignore

Generate a `.gitignore` based on the selected tech stack:

**Next.js 15 / React / Node.js / Astro:**
```gitignore
# Dependencies
node_modules/

# Build output
dist/
build/
.next/
.astro/

# Environment
.env
.env.local
.env.*.local
.mcp.json

# IDE
.vscode/settings.json
.idea/

# OS
.DS_Store
Thumbs.db

# Debug
*.log
npm-debug.log*

# Testing
coverage/
```

**Python:**
```gitignore
# Virtual environments
.venv/
venv/
__pycache__/
*.py[cod]
*$py.class

# Distribution
dist/
build/
*.egg-info/
*.egg

# Environment
.env
.env.local
.mcp.json

# IDE
.vscode/settings.json
.idea/

# OS
.DS_Store
Thumbs.db

# Testing
.coverage
htmlcov/
.pytest_cache/

# mypy
.mypy_cache/
```

**Java (Maven):**
```gitignore
# Build
target/
*.class
*.jar
*.war

# IDE
.idea/
*.iml
.vscode/settings.json

# Environment
.env
.mcp.json

# OS
.DS_Store
Thumbs.db
```

**Java (Gradle):**
```gitignore
# Build
build/
.gradle/
*.class
*.jar
*.war

# IDE
.idea/
*.iml
.vscode/settings.json

# Environment
.env
.mcp.json

# OS
.DS_Store
Thumbs.db
```

**Rust:**
```gitignore
# Build
target/

# IDE
.vscode/settings.json
.idea/

# Environment
.env
.mcp.json

# OS
.DS_Store
Thumbs.db
```

**Other / None:**
```gitignore
# Environment
.env
.env.local
.mcp.json

# IDE
.vscode/settings.json
.idea/

# OS
.DS_Store
Thumbs.db
```

Write the appropriate `.gitignore` to `{dev-directory}/{repo-name}/.gitignore`.

### 4.4 Generate README.md

Write:
```markdown
# {repo-name}

{description}

## Getting Started

See [CLAUDE.md](./CLAUDE.md) for development guidance, conventions, and available commands.

## Development

<!-- Add setup instructions here -->
```

Write to `{dev-directory}/{repo-name}/README.md`.

### 4.5 Scaffold context-map.md

Copy the context-map template from:
```
${CLAUDE_PLUGIN_ROOT}/templates/context-map.md
```

Write to `{dev-directory}/{repo-name}/context-map.md`.

This gives the project a ready-to-use context source registry. The user can add entries later with `/prp-context-add`.

### 4.6 Scaffold .mcp.json (Jira MCP)

Write `.mcp.json` to `{dev-directory}/{repo-name}/.mcp.json`.

The file contains the Jira MCP server configuration. Use actual values where the user provided them, and placeholder values where they skipped.

**If the user provided Jira settings:**
```json
{
  "mcpServers": {
    "jira": {
      "type": "stdio",
      "command": "C:\\Users\\Bruce\\.local\\bin\\uvx.exe",
      "args": ["mcp-atlassian"],
      "env": {
        "JIRA_URL": "{jira-url}",
        "JIRA_USERNAME": "{jira-username}",
        "JIRA_API_TOKEN": "{jira-api-token}"
      }
    }
  }
}
```

**If the user skipped Jira setup:**
```json
{
  "mcpServers": {
    "jira": {
      "type": "stdio",
      "command": "C:\\Users\\Bruce\\.local\\bin\\uvx.exe",
      "args": ["mcp-atlassian"],
      "env": {
        "JIRA_URL": "REPLACE_WITH_YOUR_JIRA_URL",
        "JIRA_USERNAME": "REPLACE_WITH_YOUR_JIRA_USERNAME",
        "JIRA_API_TOKEN": "REPLACE_WITH_YOUR_JIRA_API_TOKEN"
      }
    }
  }
}
```

### 4.7 Scaffold .claude/rules/git-strategy.md

If the git strategy is **not** `none`, create the rules file from the template:

1. Create directory: `mkdir -p {dev-directory}/{repo-name}/.claude/rules`
2. Read the template from `${CLAUDE_PLUGIN_ROOT}/templates/git-strategy.md`
3. Replace all `{strategy}` placeholders with the selected git strategy
4. Replace all `{base-branch}` placeholders with the selected base branch
5. Write to `{dev-directory}/{repo-name}/.claude/rules/git-strategy.md`

If the git strategy is `none`, skip this step — no rules file is needed.

**PHASE_4_CHECKPOINT**:
- [ ] Repository cloned to dev directory
- [ ] CLAUDE.md written (from template or minimal)
- [ ] .gitignore written (stack-appropriate)
- [ ] README.md written
- [ ] context-map.md written (from template)
- [ ] .mcp.json written (with Jira MCP config)
- [ ] .claude/rules/git-strategy.md written (if strategy is not `none`)

---

## Phase 5: Commit & Push

### 5.1 Stage, Commit, Push

```bash
cd "{dev-directory}/{repo-name}"
git add CLAUDE.md .gitignore README.md context-map.md .mcp.json .claude/rules/git-strategy.md
git commit -m "chore: initialize project with CLAUDE.md, context-map, and Jira integration"
git push -u origin {base-branch}
```

If push fails because the branch doesn't exist remotely yet (fresh repo):
```bash
git push --set-upstream origin {base-branch}
```

If `.claude/rules/git-strategy.md` was not created (strategy is `none`), omit it from the `git add`.

**PHASE_5_CHECKPOINT**:
- [ ] Files staged
- [ ] Initial commit created
- [ ] Pushed to remote

---

## Phase 6: Report

Display the completion summary:

```
Project initialized successfully!

  Location:      {dev-directory}\{repo-name}
  GitHub:        https://github.com/{owner}/{repo-name}
  Stack:         {stack-name}
  Git Strategy:  {git-strategy}
  Base Branch:   {base-branch}
  Jira URL:       {jira-url or "Not configured — edit .mcp.json"}

  Files created:
    CLAUDE.md                       — Project conventions and AI guidance
    .gitignore                      — Stack-appropriate ignore rules
    README.md                       — Project overview
    context-map.md                  — External context source registry
    .mcp.json                       — MCP server configuration (Jira)
    .claude/rules/git-strategy.md   — Branch naming and merge conventions

Next steps:
  1. Open the repo: cd "{dev-directory}\{repo-name}"
  2. Review and customize CLAUDE.md for your project
  3. Initialize your project (npm init, uv init, cargo init, etc.)
  {If Jira was skipped:}
  4. Configure Jira: edit .mcp.json with your Jira URL, username, and API token
  5. Add context sources: /prp-context-add <path-or-url>
  6. Start building: /prp-prd "your feature idea"
```

---

## Execute

Now run through all phases:

1. Validate the repo name from `$ARGUMENTS` and check prerequisites
2. Find and parse defaults from scaffold-repo.json or CLAUDE.md
3. Ask for tech stack, git strategy, base branch, description, Jira integration settings, and confirm
4. Create the GitHub repo
5. Clone, scaffold CLAUDE.md (with git strategy + base branch), generate .gitignore, README, context-map.md, .mcp.json (Jira), and .claude/rules/git-strategy.md
6. Commit and push
7. Report success
