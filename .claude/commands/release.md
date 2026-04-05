---
name: release
description: Bump prp-core plugin version (minor by default, --major for major), commit, and push
user-invocable: true
---

# Bump Version, Commit, and Push

## Parse Arguments

Check `$ARGUMENTS` for flags:

- **--major**: Bump the major version (e.g., 3.1.0 → 4.0.0)
- **--no-stage**: Skip staging; only commit what is already staged
- **Default**: Bump minor version (e.g., 3.1.0 → 3.2.0), stage all uncommitted changes

## Steps

1. **Read** `plugins/prp-core/.claude-plugin/plugin.json` to get the current version string.

2. **Calculate new version**:
   - Parse the version as `major.minor.patch`.
   - If `--major`: increment major, reset minor and patch to 0.
   - Otherwise: increment minor, reset patch to 0.

3. **Update** `plugins/prp-core/.claude-plugin/plugin.json` with the new version string.

4. **Stage changes**:
   - Unless `--no-stage` was passed, run `git add -A` to stage all uncommitted changes.
   - If `--no-stage` was passed, only stage the plugin file: `git add plugins/prp-core/.claude-plugin/plugin.json`

5. **Commit** with a descriptive message:
   - Run `git diff --cached --stat` and `git diff --cached` to review staged changes.
   - If the only change is the version bump in `plugin.json`, use: `chore: bump prp-core to v{new_version}`
   - Otherwise, write a conventional commit message that summarizes the substantive changes (not the version bump). Append `(v{new_version})` to the end. Example: `feat: add release command and whats-next workflow (v3.2.0)`

6. **Tag** the commit with the new version:
   ```
   git tag v{new_version}
   ```

7. **Push** the commit and tag:
   ```
   git push && git push --tags
   ```

8. **Output** a brief confirmation:
   ```
   prp-core bumped: v{old_version} → v{new_version} (committed and pushed)
   ```
