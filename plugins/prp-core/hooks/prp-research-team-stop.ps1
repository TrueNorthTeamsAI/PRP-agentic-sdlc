# PRP Research Team Stop Hook (Windows PowerShell)
# Validates that the research plan output contains all required sections
# Uses a sentinel file to scope: only fires when prp-research-team command ran

$ErrorActionPreference = "Stop"

# Sentinel file location
$SentinelFile = ".claude/prp-research-team.state"

# Check if our command ran (sentinel exists)
if (-not (Test-Path $SentinelFile)) {
    # Not our command - allow exit
    exit 0
}

# Read the output file path from sentinel
$outputPath = (Get-Content $SentinelFile -First 1).Trim()

# Validate output path exists
if (-not $outputPath -or -not (Test-Path $outputPath)) {
    Write-Error "Research plan file not found at: $outputPath"
    Write-Error "The research plan was not generated. Please re-run the command."
    Remove-Item $SentinelFile -Force
    exit 0
}

# Required sections that must be present in the research plan
$requiredSections = @(
    "## Research Question"
    "## Research Question Decomposition"
    "## Team Composition"
    "## Research Tasks"
    "## Team Orchestration Guide"
    "## Acceptance Criteria"
)

# Read the output file
$outputContent = Get-Content $outputPath -Raw

# Check each required section
$missing = @()
foreach ($section in $requiredSections) {
    if ($outputContent -notmatch [regex]::Escape($section)) {
        $missing += $section
    }
}

# All sections present - clean up and allow exit
if ($missing.Count -eq 0) {
    Remove-Item $SentinelFile -Force
    exit 0
}

# Missing sections - block exit with feedback
$missingList = ($missing | ForEach-Object { "- $_" }) -join "`n"

$feedback = @"
Research plan is incomplete. Missing required sections:
$missingList

Please add the missing sections to: $outputPath

All 6 required sections must be present:
1. ## Research Question
2. ## Research Question Decomposition
3. ## Team Composition
4. ## Research Tasks
5. ## Team Orchestration Guide
6. ## Acceptance Criteria
"@

$output = @{
    decision = "block"
    reason = $feedback
} | ConvertTo-Json -Compress

Write-Output $output
exit 0
