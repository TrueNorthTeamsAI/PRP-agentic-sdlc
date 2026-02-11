---
name: scaffold-repo
description: Create a new GitHub repo, clone it, and scaffold with CLAUDE.md template, .gitignore, and README. Pass the repo name as an argument. Reads GitHub owner and visibility defaults from parent CLAUDE.md.
argument-hint: <repo-name>
---

# Scaffold New Repository

Create a new GitHub repository with proper PRP framework scaffolding. This skill handles repo creation, cloning, and initial file setup so every project starts with the right structure.

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

Search for the nearest `CLAUDE.md` by walking up the directory tree from the current working directory. Look for a section called `## Repository Defaults` containing:

- **GitHub Owner** (e.g., `TrueNorthTeamsAI`)
- **Default Visibility** (e.g., `private`)
- **Dev Directory** (e.g., `D:\Source\TrueNorthTeams`)

Parse these values from the markdown. The format is:
```
- **GitHub Owner**: {value}
- **Default Visibility**: {value}
- **Dev Directory**: {value}
```

If the section is not found or any value is missing, ask the user for the missing values:
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

### 2.3 Project Description

Ask the user:
> "Give a one-line description of this project (used in GitHub repo description and README):"

### 2.4 Confirm Settings

Present a summary and ask for confirmation before proceeding:

```
Repository Settings:
  Name:        {repo-name}
  Owner:       {owner}
  Visibility:  {visibility}
  Tech Stack:  {stack-name}
  Directory:   {dev-directory}\{repo-name}
  Description: {description}

Proceed? (yes/no)
```

Wait for user confirmation. If "no", ask what to change.

**PHASE_2_CHECKPOINT**:
- [ ] GitHub owner determined
- [ ] Visibility determined
- [ ] Dev directory determined
- [ ] Tech stack selected
- [ ] Description provided
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

Then change into the new directory for subsequent operations.

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

# Claude
.claude/PRPs/
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

# Claude
.claude/PRPs/
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

# OS
.DS_Store
Thumbs.db

# Claude
.claude/PRPs/
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

# OS
.DS_Store
Thumbs.db

# Claude
.claude/PRPs/
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

# OS
.DS_Store
Thumbs.db

# Claude
.claude/PRPs/
```

**Other / None:**
```gitignore
# Environment
.env
.env.local

# IDE
.vscode/settings.json
.idea/

# OS
.DS_Store
Thumbs.db

# Claude
.claude/PRPs/
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

**PHASE_4_CHECKPOINT**:
- [ ] Repository cloned to dev directory
- [ ] CLAUDE.md written (from template or minimal)
- [ ] .gitignore written (stack-appropriate)
- [ ] README.md written

---

## Phase 5: Commit & Push

### 5.1 Detect Default Branch

Check what the default branch is:
```bash
git -C "{dev-directory}/{repo-name}" branch --show-current
```

If empty (fresh repo with no commits), default to `main`.

### 5.2 Stage, Commit, Push

```bash
cd "{dev-directory}/{repo-name}"
git add CLAUDE.md .gitignore README.md
git commit -m "chore: initial repository scaffold with CLAUDE.md template"
git push -u origin main
```

If push fails because the branch doesn't exist remotely yet (fresh repo):
```bash
git push --set-upstream origin main
```

**PHASE_5_CHECKPOINT**:
- [ ] Files staged
- [ ] Initial commit created
- [ ] Pushed to remote

---

## Phase 6: Report

Display the completion summary:

```
Repository scaffolded successfully!

  Location:  {dev-directory}\{repo-name}
  GitHub:    https://github.com/{owner}/{repo-name}
  Stack:     {stack-name}
  Files:     CLAUDE.md, .gitignore, README.md

Next steps:
  1. Open the repo: cd "{dev-directory}\{repo-name}"
  2. Review and customize CLAUDE.md for your project
  3. Initialize your project (npm init, uv init, cargo init, etc.)
  4. Start building: /prp-prd "your feature idea"
```

---

## Execute

Now run through all phases:

1. Validate the repo name from `$ARGUMENTS` and check prerequisites
2. Find and parse Repository Defaults from the nearest CLAUDE.md
3. Ask for tech stack, description, and confirm
4. Create the GitHub repo
5. Clone, scaffold CLAUDE.md from template, generate .gitignore and README
6. Commit and push
7. Report success
