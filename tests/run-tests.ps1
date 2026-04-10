<#
.SYNOPSIS
    Runs all tests for the Agent Skills Demo project.

.DESCRIPTION
    Executes Python tests (pytest), C# script tests, and pre-flight checks.
    Reports a combined summary at the end.

.NOTES
    Run from repo root: pwsh tests/run-tests.ps1
#>

$ErrorActionPreference = "Continue"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$RepoRoot = Split-Path -Parent $ScriptDir
$TestsDir = Join-Path $RepoRoot "tests"

$Suites = @()
$OverallExitCode = 0

function Run-Suite {
    param(
        [string]$Name,
        [string]$Command,
        [string[]]$Arguments
    )
    Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $Name" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    try {
        & $Command @Arguments
        $exitCode = $LASTEXITCODE
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $exitCode = 1
    }

    $status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
    $script:Suites += [PSCustomObject]@{
        Suite  = $Name
        Status = $status
        Exit   = $exitCode
    }
    if ($exitCode -ne 0) { $script:OverallExitCode = 1 }
}

Write-Host "=== Agent Skills Demo — Test Runner ===" -ForegroundColor Magenta
Write-Host "Repository: $RepoRoot"
Write-Host "Timestamp:  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# ── Suite 1: Pre-flight Checks ───────────────────────────────────────

Run-Suite "Pre-flight Validation" "pwsh" @("-NoProfile", "-File", (Join-Path $TestsDir "test_preflight.ps1"))

# ── Suite 2: Python Tests (pytest) ───────────────────────────────────

$pythonCmd = $null
foreach ($cmd in @("python", "python3")) {
    try {
        $ver = & $cmd --version 2>&1 | Out-String
        if ($ver -match "Python 3") { $pythonCmd = $cmd; break }
    }
    catch { continue }
}

if ($pythonCmd) {
    Run-Suite "Python Data Analyzer Tests" $pythonCmd @("-m", "pytest", (Join-Path $TestsDir "test_data_analyzer.py"), "-v", "--tb=short")
}
else {
    Write-Host "`n⚠ SKIPPED: Python tests — Python 3 not found" -ForegroundColor Yellow
    $Suites += [PSCustomObject]@{ Suite = "Python Data Analyzer Tests"; Status = "SKIP"; Exit = 0 }
}

# ── Suite 3: C# Code Reviewer Tests ──────────────────────────────────

Run-Suite "C# Code Reviewer Tests" "pwsh" @("-NoProfile", "-File", (Join-Path $TestsDir "test_code_reviewer.ps1"))

# ── Combined Summary ─────────────────────────────────────────────────

Write-Host "`n"
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║         TEST RESULTS SUMMARY             ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Magenta
$Suites | Format-Table -AutoSize

$passCount = ($Suites | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($Suites | Where-Object { $_.Status -eq "FAIL" }).Count
$skipCount = ($Suites | Where-Object { $_.Status -eq "SKIP" }).Count

Write-Host "Suites: $($Suites.Count) total | $passCount passed | $failCount failed | $skipCount skipped"

if ($OverallExitCode -eq 0) {
    Write-Host "`n✅ All test suites passed." -ForegroundColor Green
}
else {
    Write-Host "`n❌ Some test suites failed. See details above." -ForegroundColor Red
}

exit $OverallExitCode
