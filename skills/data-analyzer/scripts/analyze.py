"""Simple data analysis script for CSV files.
Usage: python analyze.py <file.csv>
"""
import csv
import sys
from statistics import mean, median, stdev

file_path = sys.argv[1] if len(sys.argv) > 1 else "data.csv"

try:
    with open(file_path, newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
except FileNotFoundError:
    print(f"File not found: {file_path}")
    sys.exit(1)

print(f"=== Data Analysis: {file_path} ===")
print(f"Rows: {len(rows)}  |  Columns: {len(rows[0]) if rows else 0}")

# Analyze numeric columns
for col in (rows[0].keys() if rows else []):
    values = []
    for row in rows:
        try:
            values.append(float(row[col]))
        except (ValueError, TypeError):
            continue
    if len(values) > 1:
        print(f"\n📊 {col}:")
        print(f"   Mean: {mean(values):.2f}  |  Median: {median(values):.2f}")
        print(f"   Min: {min(values):.2f}   |  Max: {max(values):.2f}")
        print(f"   Std Dev: {stdev(values):.2f}")
