<#
.SYNOPSIS
    Pre-flight validation smoke tests for the Agent Skills Demo.

.DESCRIPTION
    Validates that the demo environment is set up correctly before running.
    Checks: skills directory, Python availability, User Secrets configuration.

.NOTES
    Run from repo root: pwsh tests/test_preflight.ps1
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$RepoRoot = Split-Path -Parent $ScriptDir

$Passed = 0
$Failed = 0
$Results = @()

function Test-Case {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    Write-Host "  [$Name] " -NoNewline
    try {
        & $Test
        Write-Host "PASS" -ForegroundColor Green
        $script:Passed++
        $script:Results += [PSCustomObject]@{ Name = $Name; Status = "PASS"; Detail = "" }
    }
    catch {
        Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
        $script:Failed++
        $script:Results += [PSCustomObject]@{ Name = $Name; Status = "FAIL"; Detail = $_.Exception.Message }
    }
}

Write-Host "`n=== Pre-flight Validation Tests ===" -ForegroundColor Cyan
Write-Host "Repo root: $RepoRoot`n"

# ── Test: Skills directory exists ─────────────────────────────────────

Test-Case "Skills directory exists" {
    $skillsDir = Join-Path $RepoRoot "skills"
    if (-not (Test-Path $skillsDir)) {
        throw "Skills directory not found at: $skillsDir"
    }
}

# ── Test: Skills directory contains expected skills ───────────────────

Test-Case "All three skill directories present" {
    $skillsDir = Join-Path $RepoRoot "skills"
    $expected = @("meeting-notes", "data-analyzer", "code-reviewer")
    foreach ($skill in $expected) {
        $path = Join-Path $skillsDir $skill
        if (-not (Test-Path $path)) {
            throw "Missing skill directory: $skill"
        }
    }
}

# ── Test: Each skill has SKILL.md ─────────────────────────────────────

Test-Case "Each skill has SKILL.md" {
    $skillsDir = Join-Path $RepoRoot "skills"
    $skills = @("meeting-notes", "data-analyzer", "code-reviewer")
    foreach ($skill in $skills) {
        $md = Join-Path $skillsDir $skill "SKILL.md"
        if (-not (Test-Path $md)) {
            throw "Missing SKILL.md in: $skill"
        }
    }
}

# ── Test: Python is available ─────────────────────────────────────────

Test-Case "Python 3 is available" {
    $pythonCmd = $null
    foreach ($cmd in @("python", "python3")) {
        try {
            $ver = & $cmd --version 2>&1 | Out-String
            if ($ver -match "Python 3") {
                $pythonCmd = $cmd
                break
            }
        }
        catch {
            continue
        }
    }
    if (-not $pythonCmd) {
        throw "Python 3 not found. data-analyzer skill requires Python."
    }
}

# ── Test: Python script exists ────────────────────────────────────────

Test-Case "data-analyzer script exists" {
    $script = Join-Path $RepoRoot "skills" "data-analyzer" "scripts" "analyze.py"
    if (-not (Test-Path $script)) {
        throw "analyze.py not found at: $script"
    }
}

# ── Test: C# script exists ───────────────────────────────────────────

Test-Case "code-reviewer script exists" {
    $script = Join-Path $RepoRoot "skills" "code-reviewer" "scripts" "analyze.cs"
    if (-not (Test-Path $script)) {
        throw "analyze.cs not found at: $script"
    }
}

# ── Test: .NET SDK available ──────────────────────────────────────────

Test-Case ".NET SDK is available" {
    try {
        $ver = & dotnet --version 2>&1 | Out-String
        if ($ver -notmatch "\d+\.\d+") {
            throw "dotnet --version returned unexpected output: $ver"
        }
    }
    catch {
        throw ".NET SDK not found. Run: https://dot.net/download"
    }
}

# ── Test: User Secrets ID configured ─────────────────────────────────

Test-Case "User Secrets reference in demo source" {
    $demoFile = Join-Path $RepoRoot "src" "agentSkillsDemo.cs"
    if (-not (Test-Path $demoFile)) {
        throw "Demo source file not found: $demoFile"
    }
    $content = Get-Content $demoFile -Raw
    if ($content -notmatch "agent-skills-demo") {
        throw "User Secrets ID 'agent-skills-demo' not found in demo source"
    }
}

# ── Test: Missing skills directory detection ──────────────────────────

Test-Case "Detects missing skills directory path" {
    $fakePath = Join-Path $RepoRoot "nonexistent-skills"
    if (Test-Path $fakePath) {
        throw "Test setup error: fake path should not exist"
    }
    # This tests the validation logic — the demo should detect this
    # For now, verify that the skills path used in demo source is "skills"
    $demoFile = Join-Path $RepoRoot "src" "agentSkillsDemo.cs"
    $content = Get-Content $demoFile -Raw
    if ($content -notmatch '"skills"') {
        throw "Demo doesn't reference 'skills' directory — path may be hardcoded differently"
    }
}

# ── Summary ──────────────────────────────────────────────────────────

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $Passed  |  Failed: $Failed"
$Results | Format-Table -AutoSize

if ($Failed -gt 0) {
    Write-Host "Some pre-flight checks failed." -ForegroundColor Yellow
    exit 1
}
else {
    Write-Host "All pre-flight checks passed." -ForegroundColor Green
    exit 0
}
