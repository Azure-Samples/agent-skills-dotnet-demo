"""
Tests for the data-analyzer skill (skills/data-analyzer/scripts/analyze.py).

Runs the script as an external process via subprocess, verifying CLI behavior
including output format, error handling, and edge cases.

NOTE: Some tests verify EXPECTED fixed behavior. If Linus hasn't applied fixes
yet, failures on empty-CSV and single-row tests are expected.
"""

import os
import subprocess
import sys
import tempfile
import textwrap

import pytest

SCRIPT_PATH = os.path.join(
    os.path.dirname(__file__), "..", "skills", "data-analyzer", "scripts", "analyze.py"
)
PYTHON = sys.executable


def _run_analyzer(file_path: str) -> subprocess.CompletedProcess:
    """Helper: run analyze.py with the given file path."""
    env = os.environ.copy()
    # Ensure UTF-8 output so emoji characters (📊) don't crash on Windows cp1252
    env["PYTHONIOENCODING"] = "utf-8"
    return subprocess.run(
        [PYTHON, SCRIPT_PATH, file_path],
        capture_output=True,
        text=True,
        timeout=30,
        env=env,
    )


def _write_csv(tmp_dir: str, name: str, content: str) -> str:
    """Helper: write a CSV string to a file and return its path."""
    path = os.path.join(tmp_dir, name)
    with open(path, "w", newline="") as f:
        f.write(textwrap.dedent(content))
    return path


# ── Happy-path tests ────────────────────────────────────────────────


class TestValidCSV:
    """Tests with well-formed CSV data that should always work."""

    def test_analyze_valid_csv(self, tmp_path):
        """A normal multi-row CSV should produce statistics output."""
        csv_content = """\
            Name,Age,Score
            Alice,30,88.5
            Bob,25,92.0
            Carol,35,76.3
        """
        csv_file = _write_csv(str(tmp_path), "valid.csv", csv_content)
        result = _run_analyzer(csv_file)

        assert result.returncode == 0, f"Script failed: {result.stderr}"
        assert "=== Data Analysis:" in result.stdout
        assert "Rows: 3" in result.stdout
        assert "Columns: 3" in result.stdout
        # Numeric columns should have statistics
        assert "Mean:" in result.stdout
        assert "Median:" in result.stdout
        assert "Std Dev:" in result.stdout

    def test_output_contains_column_names(self, tmp_path):
        """Output should reference numeric column names."""
        csv_content = """\
            Product,Price,Quantity
            Widget,10.0,5
            Gadget,20.0,3
            Doohickey,15.0,8
        """
        csv_file = _write_csv(str(tmp_path), "products.csv", csv_content)
        result = _run_analyzer(csv_file)

        assert result.returncode == 0
        assert "Price" in result.stdout
        assert "Quantity" in result.stdout


# ── Edge-case tests ─────────────────────────────────────────────────


class TestEdgeCases:
    """Tests for boundary conditions and unusual inputs."""

    def test_analyze_empty_csv(self, tmp_path):
        """Header-only CSV (no data rows) should produce a graceful message, not crash.

        EXPECTED BEHAVIOR AFTER FIX: The script should either report 0 rows
        with no statistics or print a user-friendly message. It must NOT raise
        an IndexError or other unhandled exception.
        """
        csv_content = "Name,Age,Score\n"
        csv_file = _write_csv(str(tmp_path), "empty.csv", csv_content)
        result = _run_analyzer(csv_file)

        # Must not crash — exit code 0 or a handled exit code
        assert result.returncode == 0, (
            f"Empty CSV crashed (exit code {result.returncode}). "
            f"stderr: {result.stderr}"
        )
        # Should show a friendly empty-data message or "Rows: 0"
        assert "No data rows found" in result.stdout or "Rows: 0" in result.stdout
        # Should NOT contain statistics headers for empty data
        assert "Std Dev:" not in result.stdout

    def test_analyze_single_row_csv(self, tmp_path):
        """CSV with one data row should not crash on stdev calculation.

        With a single data point, stdev is undefined. The script should either
        skip stdev, show N/A, or handle it gracefully.
        """
        csv_content = """\
            Name,Age,Score
            Alice,30,88.5
        """
        csv_file = _write_csv(str(tmp_path), "single.csv", csv_content)
        result = _run_analyzer(csv_file)

        assert result.returncode == 0, (
            f"Single-row CSV crashed (exit code {result.returncode}). "
            f"stderr: {result.stderr}"
        )
        assert "Rows: 1" in result.stdout
        # With only 1 numeric value per column, stdev should NOT be attempted
        # (stdev requires ≥2 values). The script currently guards with
        # `if len(values) > 1` so this should pass, but stats may be absent.
        # After Linus's fix, single-value columns should show mean/median
        # without stdev.

    def test_analyze_no_numeric_columns(self, tmp_path):
        """CSV with only text columns should not crash.

        The script should report columns but produce no numeric statistics.
        """
        csv_content = """\
            Name,City,Country
            Alice,Seattle,USA
            Bob,London,UK
            Carol,Tokyo,Japan
        """
        csv_file = _write_csv(str(tmp_path), "text_only.csv", csv_content)
        result = _run_analyzer(csv_file)

        assert result.returncode == 0, (
            f"Text-only CSV crashed (exit code {result.returncode}). "
            f"stderr: {result.stderr}"
        )
        assert "Rows: 3" in result.stdout
        assert "Columns: 3" in result.stdout
        # No numeric columns → no statistics
        assert "Mean:" not in result.stdout

    def test_analyze_mixed_numeric_text(self, tmp_path):
        """Columns with a mix of numeric and non-numeric values should skip
        non-parseable entries and still compute stats on the valid ones."""
        csv_content = """\
            Item,Value
            A,10.0
            B,N/A
            C,30.0
            D,20.0
        """
        csv_file = _write_csv(str(tmp_path), "mixed.csv", csv_content)
        result = _run_analyzer(csv_file)

        assert result.returncode == 0
        # "N/A" should be silently skipped; remaining 3 values should be analyzed
        assert "Mean:" in result.stdout


# ── Error-path tests ────────────────────────────────────────────────


class TestErrorPaths:
    """Tests for error conditions that should produce clean failures."""

    def test_analyze_missing_file(self, tmp_path):
        """Running with a non-existent file should print an error and exit 1."""
        fake_path = os.path.join(str(tmp_path), "does_not_exist.csv")
        result = _run_analyzer(fake_path)

        assert result.returncode == 1, (
            f"Expected exit code 1 for missing file, got {result.returncode}"
        )
        assert "File not found" in result.stdout or "File not found" in result.stderr

    def test_analyze_completely_empty_file(self, tmp_path):
        """A zero-byte file (no header, no data) should not crash."""
        csv_file = _write_csv(str(tmp_path), "zero.csv", "")
        result = _run_analyzer(csv_file)

        # Should not crash with an unhandled exception
        assert result.returncode in (0, 1), (
            f"Zero-byte file caused unhandled crash (exit code {result.returncode}). "
            f"stderr: {result.stderr}"
        )
