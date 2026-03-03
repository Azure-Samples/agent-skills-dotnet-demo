---
name: data-analyzer
description: >-
  Analyze datasets and generate statistical summaries and insights.
  Use when asked to analyze data, compute statistics, or identify trends.
---

## Instructions

When analyzing data:

1. **Overview** — Report the shape of the dataset (rows, columns, types).
2. **Statistics** — Compute mean, median, min, max, and standard deviation for numeric columns.
3. **Missing Data** — Identify columns with missing or null values.
4. **Trends** — Highlight any notable patterns or outliers.

For automated processing, use the script at `scripts/analyze.py` which reads
CSV files and generates basic statistical summaries.

Present results in a clear table format when possible.
