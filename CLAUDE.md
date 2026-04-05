# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Nature

This is a **PRP (Product Requirement Prompt) Framework** repository, not a traditional software project. The core concept: **"PRP = PRD + curated codebase intelligence + agent/runbook"** — designed to enable AI agents to ship production-ready code on the first pass.

## Architecture

### Plugin-Based System

All commands, agents, skills, and hooks live in `plugins/prp-core/`. This directory is a Claude Code plugin that gets installed into target projects. **Do not create `.claude/commands/`, `.claude/agents/`, `.claude/hooks/`, or `.claude/skills/` directories** — the plugin provides everything.

```
plugins/prp-core/
  .claude-plugin/plugin.json  # Plugin manifest
  commands/                   # All PRP commands (prp-plan, prp-implement, etc.)
  agents/                     # Specialized agents (codebase-explorer, code-reviewer, etc.)
  skills/                     # Skills (build-with-agent-team, init-project, etc.)
  hooks/                      # Ralph/research stop hooks
  templates/                  # PRP and user journey templates
```

The `.claude/` directory in this repo is reserved for:
- `.claude/PRPs/` — Artifact storage (plans, PRDs, visions, reports, investigations)
- `.claude/PRPs/visions/` — Vision documents (active); `completed/` subfolder for archived visions
- `.claude/PRPs/.counters.json` — Global artifact numbering counters
- `.claude/settings.local.json` — Tool permissions

### Template-Based Methodology

- **PRP Templates** in `PRPs/templates/` follow structured format with validation loops
- **Context-Rich Approach**: Every PRP must include comprehensive documentation, examples, and gotchas
- **Validation-First Design**: Each PRP contains executable validation gates (syntax, tests, integration)

### AI Documentation Curation

- `PRPs/ai_docs/` contains curated Claude Code documentation for context injection
- `claude_md_files/` provides framework-specific CLAUDE.md examples for target projects

## PRP Workflow

### Vision → PRD → Plan → Execute

The PRP framework supports an optional **Vision** layer above PRDs. A Vision captures strategic objectives that span multiple PRDs, providing the "why behind the why."

```
/prp-core:prp-vision "objective"      → Interactive vision for major milestones
/prp-core:prp-prd "idea"              → Interactive PRD (standalone)
/prp-core:prp-prd --vision path "idea" → Interactive PRD linked to a vision
/prp-core:prp-plan path/to/prd.md     → Plan for next pending phase
```

Then choose ONE execution path:

```
/prp-core:prp-implement path/to/plan  → Sequential execution with validation loops
/prp-core:prp-ralph path/to/plan      → Autonomous loop until all validations pass
/prp-core:build-with-agent-team plan   → Parallel execution with agent teams (Opus only)
```

All three execution paths share the same **completion protocol**:
1. Update Source PRD (mark phase complete)
2. Archive plan to `completed/`
3. Git operations (per strategy)

**IMPORTANT: Keep all three execution paths in sync.** When updating completion logic (PRD status, git operations, plan archival) in any one of `prp-implement`, `prp-ralph`, or `build-with-agent-team`, apply the same change to all three.

### Execution Path Comparison

| Path | When to Use | Agent Model |
|------|-------------|-------------|
| `prp-implement` | Interactive, step-by-step with user oversight | Any |
| `prp-ralph` | Autonomous loop, hands-off until done | Any |
| `build-with-agent-team` | Complex builds benefiting from parallelism | Opus 4.6 only |

### Vision Layer

Visions sit above PRDs and capture strategic objectives for major milestones:

- **One active vision** per project at a time
- PRDs link to visions via `--vision` flag: `/prp-prd --vision .claude/PRPs/visions/V001-name.vision.md`
- Vision's git strategy cascades to all PRDs: `none`→`none`, `prd`→`branch-per-prd`, `plan`→`branch-per-phase`
- Vision's PRD Tracker is automatically updated when PRDs are created under it
- Completed visions move to `.claude/PRPs/visions/completed/`
- Stored in `.claude/PRPs/visions/`

### Artifact Numbering System

All artifacts use hierarchical numbering for lineage and discoverability:

```
V001                    — Vision
V001-PRD001             — PRD linked to vision V001
V001-PRD001-P001        — Plan under that PRD
PRD002                  — Standalone PRD (no vision)
PRD002-P001             — Plan under standalone PRD
```

- Numbering is global per project (counters never reset)
- Numbers are zero-padded to 3 digits
- Counter state stored in `.claude/PRPs/.counters.json`
- Standalone PRDs and plans (without a vision) get their own sequential number

### Supporting Commands

```
/prp-core:prp-commit                   → Stage and commit with conventional message
/prp-core:prp-pr                       → Push and create pull request
/prp-core:prp-review                   → Review current changes or PR
/prp-core:prp-review-agents #PR        → Multi-agent review (7 specialized agents)
/prp-core:prp-debug "problem"          → Root cause analysis
/prp-core:prp-codebase-question "q"    → Research codebase with parallel agents
/prp-core:prp-issue-investigate #123   → Investigate a GitHub issue
/prp-core:prp-issue-fix path/to/inv    → Implement fix from investigation
/prp-core:prp-research-team "question" → Design research team with parallel agents
/prp-core:scaffold-repo repo-name      → Create and scaffold a new GitHub repo
```

## Git Strategy

PRDs declare a `Git Strategy` field in their Technical Approach section. All downstream commands (plan, implement, ralph, build-with-agent-team) read and follow it.

| Strategy | Behavior |
|----------|----------|
| `none` | No git operations. User manages git manually. |
| `main-only` | Commit on current branch. No branch creation. **(default)** |
| `branch-per-prd` | One feature branch for the entire PRD. Created at PRD generation. |
| `branch-per-phase` | Each phase gets its own branch. Created by prp-plan. |

### Strategy Flow

| Command | none | main-only | branch-per-prd | branch-per-phase |
|---------|------|-----------|-----------------|------------------|
| prp-prd | skip | commit | create branch + commit | commit |
| prp-plan | skip | commit | verify branch, commit | create phase branch, commit |
| execute* | skip | commit | verify branch, commit | verify branch, commit |

*execute = prp-implement, prp-ralph, or build-with-agent-team

## Integrations

### Context Map (Optional)

Projects can include a `context-map.md` for external knowledge sources. The `prp-prd` and `prp-plan` commands auto-load matching context before research phases.

## Critical Success Patterns

1. **Context is King**: Include ALL necessary documentation, examples, and caveats
2. **Validation Loops**: Provide executable tests/lints the AI can run and fix
3. **Information Dense**: Use keywords and patterns from the codebase
4. **Progressive Success**: Start simple, validate, then enhance
5. **One-Pass Target**: Plans should enable implementation without clarification

## Anti-Patterns to Avoid

- Don't create minimal context prompts — context is everything
- Don't skip validation steps — they're critical for one-pass success
- Don't ignore the structured PRP format — it's battle-tested
- Don't create new patterns when existing templates work
- Don't hardcode values that should be config
- Don't catch all exceptions — be specific
- Don't duplicate plugin content into `.claude/` directories — edit `plugins/prp-core/` directly

## Project Structure

```
PRPs-agentic-sdlc-starter/
  plugins/prp-core/          # THE plugin — all commands, agents, skills, hooks
  .claude/PRPs/              # Artifact storage (plans, PRDs, visions, reports)
  PRPs/
    templates/               # PRP templates with validation
    scripts/                 # PRP runner and utilities
    ai_docs/                 # Curated Claude Code documentation
  claude_md_files/           # Framework-specific CLAUDE.md examples
  pyproject.toml             # Python package configuration
  CLAUDE.md                  # This file
```
