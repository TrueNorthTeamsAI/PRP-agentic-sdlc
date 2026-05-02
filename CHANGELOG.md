# Changelog

All notable changes to the prp-core plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] — 2026-05-02

### ⚠️ Breaking Changes

- **PRP artifacts relocated** from `.claude/PRPs/` to `PRPs/` at the repo root.
  Consumers in `bypass-permissions` mode were hitting permission prompts on every
  artifact write because Claude Code gates writes under `.claude/` even with the
  bypass flag set. PRP artifacts (PRDs, plans, visions, reports, investigations,
  `.counters.json`) are first-class project content and now live alongside `docs/`
  and `tests/`.

### Migration

The first invocation of any `/prp-*` command after upgrading runs an automatic
shim that detects the v3 layout and performs `git mv .claude/PRPs PRPs`. The
rename is staged but not committed; the next command-driven commit picks it up.

- **Happy path** (v3 layout, no `PRPs/`): silent auto-migrate, command proceeds.
- **Already migrated** (`PRPs/` exists, no `.claude/PRPs/`): no-op.
- **Partial state** (both directories exist): shim aborts with a clear message.
  Resolve by deleting whichever copy is stale, then re-run the command.
- **Non-git repo**: shim falls back to plain `mv`/`Move-Item` and warns.

If you have CI or external tooling that hardcodes `.claude/PRPs/`, update those
paths to `PRPs/` before pulling v4.0.0 into automation.

### Added

- Auto-migration shim documented in `plugins/prp-core/skills/init-project/SKILL.md`
  (canonical block) and inlined at the top of every PRP command.

### Changed

- All plugin commands, skills, templates, and scripts now read/write under `PRPs/`.
- Root `CLAUDE.md`, `README.md`, `README-for-DUMMIES.md`, plugin `README.md`, and
  `claude_md_files/*.md` updated to reference `PRPs/`.
- `init-project` scaffolds `PRPs/` directly — fresh projects never see `.claude/PRPs/`.

### Removed

- `.claude/PRPs/` as the artifact location. Mentions remain only in the migration
  shim text and this changelog.

---

_Versions prior to 4.0.0 are not documented in this file; see git tags v3.0.0–v3.4.0 for history._
