<#
.SYNOPSIS
    Tests for the code-reviewer skill (skills/code-reviewer/scripts/analyze.cs).

.DESCRIPTION
    Validates the C# file-based app that performs basic code analysis.
    Uses "dotnet run" to invoke the script and checks exit codes + output.

    NOTE: The empty-file test verifies EXPECTED fixed behavior. If Linus
    hasn't applied the division-by-zero fix yet, that test will fail.

.NOTES
    Run from repo root: pwsh tests/test_code_reviewer.ps1
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$RepoRoot = Split-Path -Parent $ScriptDir
$ScriptPath = Join-Path $RepoRoot "skills" "code-reviewer" "scripts" "analyze.cs"

$Passed = 0
$Failed = 0
$Skipped = 0
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

Write-Host "`n=== Code Reviewer Script Tests ===" -ForegroundColor Cyan
Write-Host "Script: $ScriptPath`n"

# ── Test: Valid C# file ──────────────────────────────────────────────

Test-Case "Valid C# file with known content" {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".cs"
    try {
        @"
// Sample code for testing
public class SampleClass
{
    // TODO: Implement this method
    public void DoSomething() { }

    public string VeryLongLineMethodThatHasAReallyLongNameAndAlsoHasParametersThatMakeItExceedOneHundredAndTwentyCharactersWhichIsTheThresholdForLongLines() { return ""; }

    public void ShortMethod()
    {
        Console.WriteLine("Hello");
    }
}
"@ | Set-Content -Path $tempFile -Encoding UTF8

        $result = & dotnet run $ScriptPath -- $tempFile 2>&1 | Out-String
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) { throw "Exit code was $exitCode, expected 0. Output: $result" }
        if ($result -notmatch "=== Code Analysis:") { throw "Missing analysis header in output" }
        if ($result -notmatch "Total lines:") { throw "Missing 'Total lines' in output" }
        if ($result -notmatch "TODO comments:\s+1") { throw "Should detect 1 TODO comment" }
        if ($result -notmatch "Long lines:\s+1") { throw "Should detect 1 long line" }
        if ($result -notmatch "Unresolved TODO") { throw "Should warn about TODO comments" }
        if ($result -notmatch "breaking long lines") { throw "Should warn about long lines" }
    }
    finally {
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }
}

# ── Test: Empty file (0 lines) ──────────────────────────────────────

Test-Case "Empty file (0 lines) — no division-by-zero" {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".cs"
    try {
        # Write a truly empty file (0 bytes)
        [System.IO.File]::WriteAllText($tempFile, "")

        $result = & dotnet run $ScriptPath -- $tempFile 2>&1 | Out-String
        $exitCode = $LASTEXITCODE

        # After Linus's fix, should handle empty file gracefully
        # Either exit 0 with "0 lines" output, or exit with a clean message
        if ($exitCode -ne 0 -and $result -notmatch "empty") {
            throw "Empty file caused crash (exit code $exitCode). Output: $result"
        }
        if ($result -match "DivideByZeroException") {
            throw "Division by zero on empty file — needs fix"
        }
    }
    finally {
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }
}

# ── Test: File with TODOs and long lines ─────────────────────────────

Test-Case "File with multiple TODOs and long lines" {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".cs"
    try {
        $longLine = "    var x = " + ("a" * 130) + ";"
        @"
// TODO: first task
// todo: second task (case-insensitive)
// TODO: third task
$longLine
$longLine
public class Test { }
"@ | Set-Content -Path $tempFile -Encoding UTF8

        $result = & dotnet run $ScriptPath -- $tempFile 2>&1 | Out-String
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) { throw "Exit code was $exitCode, expected 0" }
        if ($result -notmatch "TODO comments:\s+3") { throw "Should detect 3 TODO comments (case-insensitive)" }
        if ($result -notmatch "Long lines:\s+2") { throw "Should detect 2 long lines" }
    }
    finally {
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }
}

# ── Test: Non-existent file ──────────────────────────────────────────

Test-Case "Non-existent file — error message" {
    $fakePath = Join-Path ([System.IO.Path]::GetTempPath()) "nonexistent_file_12345.cs"
    
    $result = & dotnet run $ScriptPath -- $fakePath 2>&1 | Out-String
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 1) { throw "Expected exit code 1 for missing file, got $exitCode" }
    if ($result -notmatch "File not found") { throw "Should print 'File not found' message" }
}

# ── Test: Clean file (no issues) ─────────────────────────────────────

Test-Case "Clean file — no warnings" {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".cs"
    try {
        @"
public class CleanCode
{
    public void Run()
    {
        Console.WriteLine("Clean");
    }
}
"@ | Set-Content -Path $tempFile -Encoding UTF8

        $result = & dotnet run $ScriptPath -- $tempFile 2>&1 | Out-String
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) { throw "Exit code was $exitCode, expected 0" }
        if ($result -match "breaking long lines") { throw "Should NOT warn about long lines for clean file" }
        if ($result -match "Unresolved TODO") { throw "Should NOT warn about TODOs for clean file" }
        if ($result -notmatch "TODO comments:\s+0") { throw "Should show 0 TODOs" }
        if ($result -notmatch "Long lines:\s+0") { throw "Should show 0 long lines" }
    }
    finally {
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }
}

# ── Summary ──────────────────────────────────────────────────────────

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $Passed  |  Failed: $Failed  |  Skipped: $Skipped"
$Results | Format-Table -AutoSize

if ($Failed -gt 0) {
    Write-Host "Some tests failed." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "All tests passed." -ForegroundColor Green
    exit 0
}
