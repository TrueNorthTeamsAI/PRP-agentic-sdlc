# PRP Ralph Stop Hook (Windows PowerShell)
# Prevents session exit when a Ralph loop is active
# Feeds the PRP plan execution prompt back for the next iteration
#
# NOTE: On Windows, Claude Code does not pass stdin to hooks (Issue #10450).
# This script uses state-file-based completion detection instead of
# transcript inspection. The agent writes status: complete to the state
# file frontmatter when all validations pass.

$ErrorActionPreference = "Stop"

# State file location (relative to current working directory)
$StateFile = ".claude/prp-ralph.state.md"

# Check if Ralph loop is active
if (-not (Test-Path $StateFile)) {
    # No active loop - allow exit
    exit 0
}

# Read state file content
$content = Get-Content $StateFile -Raw

# Parse YAML frontmatter (between --- markers)
if ($content -notmatch '(?s)^---\r?\n(.+?)\r?\n---') {
    Write-Error "PRP Ralph: State file has no valid frontmatter"
    Remove-Item $StateFile -Force
    exit 0
}

$frontmatter = $Matches[1]

# Extract values from frontmatter
$iteration = $null
$maxIterations = $null
$planPath = $null
$status = $null

foreach ($line in ($frontmatter -split '\r?\n')) {
    if ($line -match '^iteration:\s*(\d+)') {
        $iteration = [int]$Matches[1]
    }
    elseif ($line -match '^max_iterations:\s*(\d+)') {
        $maxIterations = [int]$Matches[1]
    }
    elseif ($line -match '^plan_path:\s*"?(.+?)"?\s*$') {
        $planPath = $Matches[1]
    }
    elseif ($line -match '^status:\s*(\S+)') {
        $status = $Matches[1]
    }
}

# Validate required fields
if ($null -eq $iteration) {
    Write-Error "PRP Ralph: State file corrupted (invalid iteration)"
    Remove-Item $StateFile -Force
    exit 0
}

if ($null -eq $maxIterations) {
    Write-Error "PRP Ralph: State file corrupted (invalid max_iterations)"
    Remove-Item $StateFile -Force
    exit 0
}

# Check for completion via state file status field
if ($status -eq "complete") {
    Write-Host "PRP Ralph: All validations passed! Loop complete."
    Remove-Item $StateFile -Force
    exit 0
}

# Check if max iterations reached
if ($maxIterations -gt 0 -and $iteration -ge $maxIterations) {
    Write-Host "PRP Ralph: Max iterations ($maxIterations) reached."
    Write-Host "   Check .claude/prp-ralph.state.md for progress log."
    Remove-Item $StateFile -Force
    exit 0
}

# Not complete - continue loop
$nextIteration = $iteration + 1

# Update iteration in state file
$updatedContent = $content -replace '(?m)^iteration:\s*\d+', "iteration: $nextIteration"
Set-Content -Path $StateFile -Value $updatedContent -NoNewline

# Build the prompt to feed back
$prompt = @"
# PRP Ralph Loop - Iteration $nextIteration

## Your Task

Continue executing the PRP plan until ALL validations pass.

**Plan file**: ``$planPath``
**State file**: ``.claude/prp-ralph.state.md``

## Instructions

1. **Read the plan file** - understand all tasks and validation requirements
2. **Check your previous work** - review files, git status, test outputs
3. **Identify what's incomplete** - which tasks/validations are still failing?
4. **Fix and implement** - address failures, complete remaining tasks
5. **Run ALL validations** - type-check, lint, tests, build
6. **Update progress** - mark tasks complete, add learnings to state file

## Validation Requirements

Run these (or equivalent from your plan):
``````bash
bun run type-check || npm run type-check
bun run lint || npm run lint
bun test || npm test
bun run build || npm run build
``````

## Completion

When ALL validations pass:
1. Generate implementation report
2. Archive the plan
3. Output: ``<promise>COMPLETE</promise>``

If validations are still failing:
- Fix the issues
- End your response normally
- The loop will continue

**Do NOT output the completion promise if ANY validation is failing.**
"@

$systemMsg = "PRP Ralph iteration $nextIteration of $maxIterations | Plan: $planPath"

# Output JSON to block exit and feed prompt back
$output = @{
    decision = "block"
    reason = $prompt
    systemMessage = $systemMsg
} | ConvertTo-Json -Compress

Write-Output $output
exit 0
