---
version: 1
description: Vision document — strategic layer above PRDs for major milestones
id: "{vision-id}"
status: active
created: "{timestamp}"
---

# {Vision Title}

<!--
  This is a Vision document — the strategic layer that sits above PRDs.
  It captures the high-level objectives, problem space, and success criteria
  for a major milestone that spans multiple PRDs.

  LIFECYCLE:
    - Only ONE vision is active per project at a time
    - The PRD Tracker section is the only "living" part — update it as PRDs are created
    - When all PRDs are complete, move this file to .claude/PRPs/visions/completed/
    - Numbers are never reused

  USAGE:
    - Create PRDs under this vision: /prp-prd --vision {path-to-this-file}
    - PRDs reference this vision by file path (no content duplication)
-->

## Problem / Opportunity

<!-- What strategic gap or opportunity does this vision address? Who is affected and what is the impact? -->

{Description of the problem or opportunity}

## Objectives

<!-- What does this vision achieve? Focus on outcomes, not implementation. -->

- {Objective 1}
- {Objective 2}
- {Objective 3}

## Success Criteria

<!-- How will you measure that this vision has been achieved? Be specific and measurable. -->

| Criteria | Target | How Measured |
|----------|--------|--------------|
| {Criteria 1} | {Specific target} | {Measurement method} |
| {Criteria 2} | {Specific target} | {Measurement method} |

## Scope Boundaries

### In Scope

- {What is included}

### Out of Scope

- {What is explicitly excluded} — {why}

### Constraints

- {Known limitations or constraints}

## Key Assumptions & Risks

### Assumptions

- {Assumption 1} — if wrong: {consequence}
- {Assumption 2} — if wrong: {consequence}

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| {Risk 1} | {H/M/L} | {H/M/L} | {How to handle} |

## Context & References

<!-- External sources gathered during vision creation. These are also registered in the project's context-map.md for discoverability by downstream PRP commands. -->

| Label | Type | Path / URL | Description |
|-------|------|------------|-------------|
| {Source name} | {web/project/file/second-brain/obsidian/etc.} | {path or URL} | {What it contains} |

## PRD Tracker

<!--
  Living section — updated as PRDs are created under this vision.
  STATUS: pending | in-progress | complete
  PARALLEL: PRDs that can run concurrently (e.g., "with 3" or "-")
  DEPENDS: PRDs that must complete first (e.g., "1, 2" or "-")
  PRD FILE: link to generated PRD file once created
-->

| # | PRD | Description | Status | Parallel | Depends | PRD File |
|---|-----|-------------|--------|----------|---------|----------|
| 1 | {PRD name} | {What this PRD delivers} | pending | - | - | - |

---

*Generated: {timestamp}*
*Status: ACTIVE*
