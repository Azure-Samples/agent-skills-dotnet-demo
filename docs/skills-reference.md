# Skills Reference

The demo includes three Agent Skills that showcase different skill types supported by the Microsoft Agent Framework.

## What Are Agent Skills?

Agent Skills give agents domain expertise through a file-based configuration system. Each skill is a directory with a `SKILL.md` descriptor and optional scripts. The `FileAgentSkillsProvider` discovers skills at runtime and exposes them as tools to the agent.

See the [official blog post](https://devblogs.microsoft.com/semantic-kernel/give-your-agents-domain-expertise-with-agent-skills-in-microsoft-agent-framework/) for the full conceptual overview.

## Skill Types

| Type | How it works | Example |
|------|-------------|---------|
| **Prompt-only** | SKILL.md contains instructions; no code | `meeting-notes` |
| **.NET script** | SKILL.md + a `.csx` script executed by the agent | `code-reviewer` |
| **Python script** | SKILL.md + a `.py` script executed by the agent | `data-analyzer` |

## Skill Directory Structure

```
skills/
├── meeting-notes/
│   └── SKILL.md              # Prompt-only — instructions in markdown
├── code-reviewer/
│   ├── SKILL.md              # Skill descriptor
│   └── scripts/
│       └── analyze.csx       # C# script for code analysis
└── data-analyzer/
    ├── SKILL.md              # Skill descriptor
    └── scripts/
        └── analyze.py        # Python script for data analysis
```

## meeting-notes (Prompt-Only)

**Purpose:** Summarizes meeting transcripts into structured notes with action items.

No scripts needed — the skill's prompt instructions guide the agent to extract key points, decisions, and action items from raw meeting text.

## code-reviewer (.NET Script)

**Purpose:** Analyzes source code for quality issues using a C# script.

The `analyze.csx` script receives code as input and returns a structured review with:
- Code quality observations
- Potential bugs or issues
- Improvement suggestions

## data-analyzer (Python Script)

**Purpose:** Performs data analysis tasks using Python.

The `analyze.py` script processes data inputs and returns analysis results. Demonstrates how Python-based tools integrate with the Agent Framework.

## Creating Your Own Skills

1. Create a new directory under `skills/`
2. Add a `SKILL.md` with the skill name, description, and instructions
3. Optionally add scripts in a `scripts/` subdirectory
4. The `FileAgentSkillsProvider` will auto-discover it at runtime

Refer to the [Agent Skills Documentation](https://learn.microsoft.com/en-us/agent-framework/agents/skills) for the full SKILL.md schema.
