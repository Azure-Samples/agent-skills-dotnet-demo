# Extending the Framework: Adding New Skills

This guide walks you through building and integrating new skills into the agent framework. Whether you need a simple prompt-based skill or a complex script-driven one, the process is straightforward and follows the same patterns used in the demo skills.

## What is a Skill?

A **skill** is a reusable piece of domain expertise that an agent can invoke to handle specific tasks. Each skill is a directory under `skills/` containing:

1. **`SKILL.md`** — Frontmatter metadata (name, description) + instructions for the agent
2. **`scripts/` (optional)** — Executable scripts (`.cs`, `.py`, or other) for advanced tasks
3. **`README.md` (optional)** — User-facing documentation for the skill

The `FileAgentSkillsProvider` scans `skills/` at runtime, loads all `SKILL.md` files, and registers each skill as a tool the agent can invoke.

## Skill Anatomy

### SKILL.md Format

Every skill starts with YAML frontmatter followed by a `## Instructions` section:

```yaml
---
name: skill-name
description: >-
  A brief, clear description of what this skill does.
  Use when asked to perform this specific task.
---

## Instructions

When the agent invokes this skill:

1. **First Step** — Describe what you do first.
2. **Second Step** — Describe what you do second.
3. **Output** — Describe the format of results.

Include examples and clarifications as needed.
```

**Frontmatter Rules:**
- `name` — Lowercase, kebab-case (e.g., `sentiment-analyzer`, `api-caller`)
- `description` — Clear, action-oriented, one sentence per use case. Mention common invocation patterns.

**Instructions Section:**
- Written as prose instructions to the AI model (the model reads these directly)
- Use numbered steps or bullets for clarity
- Include format expectations (markdown tables, JSON, plain text)
- Add examples if the task is ambiguous

### Three Skill Types

#### 1. Prompt-Only Skills

Pure LLM execution — no external scripts. The agent follows the instructions and generates output.

**Example: `meeting-notes`**
```
skills/meeting-notes/
├── SKILL.md          (frontmatter + instructions only)
└── README.md         (optional user docs)
```

**Use When:**
- Summarization, reformatting, analysis
- No external file/API access needed
- The LLM can execute the task directly

#### 2. .NET Script Skills

Combines agent instructions with a C# script for analysis/processing.

**Example: `code-reviewer`**
```
skills/code-reviewer/
├── SKILL.md          (frontmatter + instructions)
├── scripts/analyze.cs    (C# analysis logic)
└── README.md         (optional user docs)
```

**Script Pattern:**
```csharp
// Usage: dotnet run scripts/analyze.cs -- <input>
var inputPath = args.FirstOrDefault() ?? "default.cs";

// Read file or input
var data = File.ReadAllLines(inputPath);

// Perform analysis
var results = /* your logic here */;

// Output results
Console.WriteLine("=== Analysis Results ===");
Console.WriteLine(results);
```

**Use When:**
- Static code analysis, file inspection
- .NET-specific logic needed
- Performance-critical operations

**⚠️ Note:** C# script execution via Agent Skills is not yet supported in the framework. Your instructions should still work (prompt-based), but the script won't be automatically invoked. See the [Agent Skills documentation](https://learn.microsoft.com/en-us/agent-framework/agents/skills) for the latest status.

#### 3. Python Script Skills

Agent instructions + Python script for data processing, statistical analysis, or API calls.

**Example: `data-analyzer`**
```
skills/data-analyzer/
├── SKILL.md          (frontmatter + instructions)
├── scripts/analyze.py    (Python analysis logic)
└── README.md         (optional user docs)
```

**Script Pattern:**
```python
"""Simple data analysis script."""
import sys

input_path = sys.argv[1] if len(sys.argv) > 1 else "data.csv"

# Read and process
# ...

# Output results
print("=== Results ===")
print(output)
```

**Use When:**
- Data analysis, statistics, CSV/JSON processing
- Machine learning or scientific computing
- Python-native libraries (pandas, scipy, requests)

**Requirements:**
- Python 3.x must be installed
- Dependencies declared in the script or a `requirements.txt`

---

## Creating a New Skill: Step-by-Step

### Step 1: Create the Skill Directory

```bash
mkdir skills/your-skill-name
cd skills/your-skill-name
```

### Step 2: Write SKILL.md

Create `SKILL.md` with clear frontmatter and instructions:

```yaml
---
name: your-skill-name
description: >-
  Brief description of what this skill does.
  Use when asked to [specific task].
---

## Instructions

When your skill is invoked:

1. **Analyze Input** — Describe what you look for.
2. **Process** — Describe your processing logic.
3. **Output** — Describe the result format.

Be explicit about:
- Edge cases (empty input, invalid data, etc.)
- Output format (markdown, JSON, plain text, tables)
- Any assumptions or limitations
```

### Step 3: Add Scripts (Optional)

If your skill needs external logic, create a `scripts/` subdirectory:

```bash
mkdir scripts
```

**For C# Analysis:**
```bash
# scripts/analyze.cs
```

**For Python Processing:**
```bash
# scripts/analyze.py
```

> **Important:** Keep scripts small and focused. They should read input (file path or stdin), process it, and write output to stdout.

### Step 4: Test the Skill Locally

#### Test Prompt-Only Skills

Run the demo and verify the agent invokes your skill:

```bash
dotnet run src/agentSkillsDemo.cs
```

Add a prompt that triggers your skill's use case.

#### Test Python Scripts

Test your script in isolation:

```bash
python scripts/analyze.py sample_input.csv
```

Verify output format and error handling.

#### Test .NET Scripts

```bash
dotnet run scripts/analyze.cs -- sample_file.cs
```

Check console output for expected results.

### Step 5: Verify Integration

The demo app will auto-discover your skill. Confirm:
1. `SKILL.md` has valid frontmatter
2. Skill name is unique and kebab-case
3. Description clearly explains the use case

---

## SKILL.md Format Reference

### Frontmatter

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | ✅ | Unique, lowercase, kebab-case identifier |
| `description` | string | ✅ | Clear, action-oriented summary |

### Instructions Section

The `## Instructions` section is read directly by the AI model. Write it as if instructing a human:

**Good:**
```
## Instructions

When analyzing this code:

1. **Check syntax** — Look for unmatched braces, quotes, etc.
2. **Find logic errors** — Identify off-by-one bugs, null references, race conditions.
3. **Rate findings** — Use 🔴 Critical | 🟡 Warning | 🟢 Suggestion.

Present results as a markdown list.
```

**Avoid:**
```
## Instructions

Use regex to find syntax errors and pattern-match logic bugs.
```

The model needs explicit guidance, not implementation hints.

---

## Example: Building a "Sentiment Analyzer" Skill

Let's build a complete example step-by-step.

### Goal
Create a skill that analyzes sentiment in user feedback and categorizes it (positive, neutral, negative) with confidence scores.

### Step 1: Create Directory
```bash
mkdir skills/sentiment-analyzer
cd skills/sentiment-analyzer
```

### Step 2: Write SKILL.md

```yaml
---
name: sentiment-analyzer
description: >-
  Analyze sentiment in text, categorizing feedback as positive, neutral, or negative.
  Use when you need to understand user emotion or satisfaction from reviews or comments.
---

## Instructions

When analyzing text for sentiment:

1. **Read the input** — Accept a block of text (review, comment, feedback).
2. **Identify tone** — Look for emotional language, tone indicators, and context clues.
3. **Categorize** — Classify as:
   - 🟢 **Positive** — Happy, satisfied, or grateful language
   - 🟡 **Neutral** — Factual, balanced, or mixed feelings
   - 🔴 **Negative** — Frustrated, disappointed, or critical language
4. **Confidence Score** — Estimate confidence (0.0 to 1.0) based on clarity of sentiment.
5. **Explain** — Briefly describe the key phrases or tone that led to your classification.

Output as a structured markdown block:

```
**Sentiment:** [Positive|Neutral|Negative]
**Confidence:** 0.85 (high confidence)
**Key Phrases:** [list of emotional indicators]
**Explanation:** [2-3 sentence explanation]
```
```

### Step 3: Test Prompt-Only

Add this to `agentSkillsDemo.cs`:

```csharp
var sentimentPrompt = @"Analyze this customer feedback:
'The product is amazing! Fast shipping, great quality, and excellent support. Highly recommend!'";

Console.WriteLine("3. Sentiment Analyzer");
Console.WriteLine(sentimentPrompt);

var sentimentResponse = await client.InvokeAsync(sentimentPrompt);
Console.WriteLine(sentimentResponse);
```

Run the demo:
```bash
dotnet run src/agentSkillsDemo.cs
```

The agent should invoke `sentiment-analyzer` and return structured sentiment analysis.

### Step 4: (Optional) Add Python Script

If you want real sentiment analysis, create `scripts/analyze.py`:

```python
"""Sentiment analysis using a simple keyword approach."""
import sys

text = sys.argv[1] if len(sys.argv) > 1 else ""

positive_words = {"great", "amazing", "excellent", "love", "perfect", "happy"}
negative_words = {"hate", "awful", "terrible", "worst", "broken", "disappointed"}

positive_count = sum(1 for w in text.lower().split() if w in positive_words)
negative_count = sum(1 for w in text.lower().split() if w in negative_words)
total_sentiment_words = positive_count + negative_count

if total_sentiment_words == 0:
    sentiment = "Neutral"
    confidence = 0.5
else:
    ratio = positive_count / total_sentiment_words
    if ratio > 0.7:
        sentiment = "Positive"
        confidence = ratio
    elif ratio < 0.3:
        sentiment = "Negative"
        confidence = 1 - ratio
    else:
        sentiment = "Neutral"
        confidence = 0.6

print(f"Sentiment: {sentiment}")
print(f"Confidence: {confidence:.2f}")
print(f"Positive words: {positive_count}, Negative words: {negative_count}")
```

---

## Best Practices

### Naming
- Use lowercase, kebab-case for skill names: `sentiment-analyzer`, not `SentimentAnalyzer` or `sentiment_analyzer`
- Keep names descriptive but concise (max 2-3 words)

### Descriptions
- Write from the user's perspective: "Use when you need to..."
- Include common invocation patterns or keywords
- Keep to one sentence; be specific about the use case

### Instructions
- Assume the agent is reading your instructions, not a program parsing them
- Use clear, numbered steps
- Specify output format explicitly (markdown table, JSON, plain text, etc.)
- Describe edge cases (empty input, invalid data, missing fields)
- Add example inputs/outputs if the task is ambiguous

### Script Robustness
- Always validate input (file exists, required fields present)
- Handle edge cases gracefully (empty data, missing values, format errors)
- Write errors to stderr; results to stdout
- Exit with code 0 on success, 1 on error
- Include usage examples at the top of the script

### Testing
- Test scripts in isolation: `python scripts/analyze.py test_input.csv`
- Test prompts in the demo by adding new invocations
- Test with edge cases: empty files, invalid formats, large data
- Verify error messages are actionable (tell users how to fix problems)

---

## File Structure Reference

**Minimal Prompt-Only Skill:**
```
skills/meeting-notes/
├── SKILL.md
```

**Full-Featured Skill with Script:**
```
skills/sentiment-analyzer/
├── SKILL.md
├── scripts/analyze.py
├── requirements.txt      (if needed)
└── README.md            (optional)
```

---

## Troubleshooting

### Skill Not Discovered
**Problem:** Your skill doesn't appear in the agent's available tools.

**Check:**
- Is the directory under `skills/`?
- Does `SKILL.md` exist with correct frontmatter (`name:` and `description:`)?
- Is the YAML frontmatter valid (no syntax errors)?

**Fix:** Restart the demo app. `FileAgentSkillsProvider` scans on startup.

### Script Not Executing
**Problem:** Your script is defined in `SKILL.md` but doesn't run.

**Note:** C# script execution in Agent Skills is not yet supported. Python scripts may not execute depending on framework support.

**Workaround:** Use prompt-only instructions (your skill will still work). See the [Agent Skills documentation](https://learn.microsoft.com/en-us/agent-framework/agents/skills) for the latest status.

### Python Script Fails
**Problem:** `scripts/analyze.py` throws an error.

**Check:**
- Is Python 3.x installed? (`python --version`)
- Is the script executable? (`python scripts/analyze.py --help`)
- Are dependencies installed? (`pip install -r requirements.txt`)

**Fix:** Test in isolation and verify error messages.

---

## Learn More

- [Agent Skills Documentation](https://learn.microsoft.com/en-us/agent-framework/agents/skills) — Official framework reference
- [SKILL.md Reference](skills-reference.md) — Existing skill examples
- [Error Handling Guide](error-handling.md) — Common issues and fixes
