---
version: 1
description: Project context sources — external documents, knowledge bases, and references
---

# Context Map

<!--
  This file defines external context sources for this project.
  Use `/prp-context <topic>` to look up and read sources by section or keyword.
  Use `/prp-context-add <path-or-url>` to add new entries interactively.

  ENTRY FORMAT:
    - **Label** | `source-type` | `path` | Description

  SOURCE TYPES:
    Built-in (no mapping required):
      project   — Relative to this project's root directory
      file      — Absolute file path, used as-is
      web       — URL, fetched via WebFetch

    Mapped (resolved via parent CLAUDE.md "Context Sources" section):
      Any custom name (e.g., second-brain, archon, shared-docs).
      The parent CLAUDE.md defines base paths for each name.
      The path in this file is appended to that base path.

    Obsidian (read via Obsidian CLI, requires Obsidian running):
      obsidian         — Single note by vault path
      obsidian-tag     — All notes with a specific tag (path = tag name, no #)
      obsidian-folder  — All notes in a vault folder
      obsidian-search  — Notes matching a keyword search

    MCP (read via MCP server tools):
      archon    — Archon knowledge base (queried via MCP server)

  SECTIONS:
    Organize entries under ## headings by topic.
    Sections act as filters for `/prp-context <section-name>`.

  EXAMPLES:
    - **Auth Architecture** | `second-brain` | `Architecture/Auth Design.md` | JWT + refresh token flow
    - **API Spec** | `project` | `docs/api-spec.md` | OpenAPI specification for this service
    - **K8s Runbook** | `file` | `D:\Source\infra\docs\k8s-runbook.md` | Cluster operations guide
    - **React 19 Docs** | `web` | `https://react.dev/blog/react-19` | React 19 migration guide
    - **Domain Knowledge** | `archon` | `project-domain` | Query Archon KB for domain context
    - **Design Notes** | `obsidian` | `Projects/MyProject/Design Notes` | Single note from Obsidian vault
    - **Architecture Decisions** | `obsidian-tag` | `type/architecture` | All notes tagged #type/architecture
    - **Project Notes** | `obsidian-folder` | `knowledge/projects/MyProject` | All notes in vault folder
    - **Auth Research** | `obsidian-search` | `authentication flow` | Vault search for keyword matches
-->

## Architecture
<!-- System design, ADRs, technical decisions -->

## Infrastructure
<!-- Deployment, CI/CD, cloud, networking -->

## Domain Knowledge
<!-- Business logic, domain models, product requirements -->

## Reference
<!-- External docs, API specs, style guides, standards -->
