# Tests — Agent Skills .NET Demo

Test suite for validating skill scripts, error handling, and demo pre-flight configuration.

## Prerequisites

- **.NET 10 SDK** — Required for C# script tests
- **Python 3.x** — Required for data-analyzer tests
- **pytest** — Install via `pip install -r tests/requirements.txt`
- **PowerShell 7+** (pwsh) — Used by test runner and PowerShell test scripts

## Quick Start

```bash
# From repo root
pip install -r tests/requirements.txt
pwsh tests/run-tests.ps1
```

## Test Structure

```
tests/
├── README.md                  # This file
├── requirements.txt           # Python test dependencies
├── run-tests.ps1              # Master test runner (runs all suites)
├── test_data_analyzer.py      # Python: data-analyzer skill tests (pytest)
├── test_code_reviewer.ps1     # PowerShell: code-reviewer skill tests
└── test_preflight.ps1         # PowerShell: pre-flight validation tests
```

## Test Suites

### 1. Pre-flight Validation (`test_preflight.ps1`)

Smoke tests that validate the demo environment is ready:

| Test | What it checks |
|------|---------------|
| Skills directory exists | `skills/` folder is present |
| All three skills present | meeting-notes, data-analyzer, code-reviewer |
| SKILL.md in each skill | Required metadata file exists |
| Python 3 available | `python --version` returns Python 3.x |
| Script files exist | analyze.py and analyze.cs are present |
| .NET SDK available | `dotnet --version` works |
| User Secrets reference | Demo source references correct secrets ID |
| Skills path detection | Demo references correct skills directory |

### 2. Data Analyzer Tests (`test_data_analyzer.py`)

Tests the Python data analysis script as a CLI tool via `subprocess.run`:

| Test | What it checks |
|------|---------------|
| Valid CSV | Multi-row CSV produces statistics (mean, median, stdev) |
| Column names in output | Numeric column headers appear in output |
| Empty CSV (header only) | Graceful handling, no IndexError crash |
| Single-row CSV | No stdev crash with insufficient data |
| No numeric columns | Text-only CSV doesn't produce stats |
| Mixed numeric/text values | Non-parseable values silently skipped |
| Missing file | Exit code 1 with "File not found" message |
| Zero-byte file | No unhandled crash |

### 3. Code Reviewer Tests (`test_code_reviewer.ps1`)

Tests the C# code analysis script via `dotnet run`:

| Test | What it checks |
|------|---------------|
| Valid C# file | Correct line count, TODO count, long line count |
| Empty file (0 lines) | No DivideByZeroException |
| Multiple TODOs + long lines | Correct counts and warnings |
| Non-existent file | Exit code 1 with "File not found" |
| Clean file (no issues) | No false-positive warnings |

## Running Individual Suites

```bash
# Python tests only
python -m pytest tests/test_data_analyzer.py -v

# C# script tests only
pwsh tests/test_code_reviewer.ps1

# Pre-flight checks only
pwsh tests/test_preflight.ps1
```

## Expected Failures

Some tests verify **expected fixed behavior** for known bugs that are being fixed in parallel:

- **Empty CSV test** — The current `analyze.py` crashes with `IndexError` on empty CSV. After the fix, this test should pass.
- **Empty file test (C#)** — The current `analyze.cs` has a division-by-zero on empty files. After the fix, this test should pass.

If these tests fail, it means the corresponding script fixes haven't been applied yet — not that the tests are wrong.

## Adding New Tests

- **Python tests:** Add to `test_data_analyzer.py` or create new `test_*.py` files
- **PowerShell tests:** Follow the `Test-Case` pattern in existing `.ps1` files
- **New suites:** Register in `run-tests.ps1` with the `Run-Suite` function
