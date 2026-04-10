"""Simple data analysis script for CSV files.
Usage: python analyze.py <file.csv>
"""
import csv
import sys
from statistics import mean, median, stdev

if len(sys.argv) < 2:
    print("Usage: python analyze.py <file.csv>")
    print("Error: No input file specified.")
    sys.exit(1)

file_path = sys.argv[1]

try:
    with open(file_path, newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
except FileNotFoundError:
    print(f"File not found: {file_path}")
    sys.exit(1)
except csv.Error as e:
    print(f"Error reading CSV file: {e}")
    sys.exit(1)

if not rows:
    print(f"=== Data Analysis: {file_path} ===")
    print("No data rows found. The file is empty or contains only a header.")
    sys.exit(0)

print(f"=== Data Analysis: {file_path} ===")
print(f"Rows: {len(rows)}  |  Columns: {len(rows[0])}")

# Analyze numeric columns
for col in rows[0].keys():
    values = []
    for row in rows:
        try:
            values.append(float(row[col]))
        except (ValueError, TypeError):
            continue
    if len(values) >= 2:
        print(f"\n📊 {col}:")
        print(f"   Mean: {mean(values):.2f}  |  Median: {median(values):.2f}")
        print(f"   Min: {min(values):.2f}   |  Max: {max(values):.2f}")
        print(f"   Std Dev: {stdev(values):.2f}")
    elif len(values) == 1:
        print(f"\n📊 {col}:")
        print(f"   Single value: {values[0]:.2f} (need ≥2 values for statistics)")
