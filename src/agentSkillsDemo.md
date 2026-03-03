# Agent Skills Demo — Detailed Walkthrough

## Overview

This demo shows how to use **Agent Skills** from the Microsoft Agent Framework to give an Azure OpenAI–powered agent domain expertise via reusable `SKILL.md` files. Agent Skills are a core concept in the framework: they let you define specialized knowledge and instructions in standalone files, then attach them to an agent at runtime so the model can automatically select and apply the right skill for each request.

The result is a single agent that can summarize meetings, analyze datasets, and review code — all driven by three small skill definitions rather than hardcoded prompt logic.

## Key Concepts

- **Agent Skills** — Reusable domain expertise defined in `SKILL.md` files. Each skill has a `name`, `description`, and an `Instructions` section that tells the model how to handle a specific class of requests. Skills can optionally include executable scripts.
- **FileAgentSkillsProvider** — Loads skills from a local directory. It scans for `SKILL.md` files, parses their YAML frontmatter, and registers each skill as a tool the model can invoke.
- **ChatClientAgent** — The agent wrapper (created via `.AsAIAgent()`) that connects to Azure OpenAI and exposes skills as callable tools through the Responses API.
- **AIContextProviders** — The mechanism that attaches skills to an agent. You pass one or more providers (like `FileAgentSkillsProvider`) into `ChatClientAgentOptions.AIContextProviders`, making those skills available at runtime.

## How the Code Works

The demo (`src/agentSkillsDemo.cs`) runs as a file-based C# app via `dotnet run`. Here's each step:

### Step 1: Configuration via User Secrets

```csharp
var config = new ConfigurationBuilder()
    .AddUserSecrets("agent-skills-demo")
    .Build();

var endpoint = config["AzureOpenAI:Endpoint"]
    ?? throw new InvalidOperationException("Set AzureOpenAI:Endpoint in User Secrets.");
var deploymentName = config["AzureOpenAI:Deployment"]
    ?? "gpt-5-mini";
```

The app reads `AzureOpenAI:Endpoint` and `AzureOpenAI:Deployment` from .NET User Secrets (secret ID: `agent-skills-demo`). This keeps credentials out of source code. The deployment defaults to `gpt-5-mini` if not explicitly set.

### Step 2: FileAgentSkillsProvider Setup

```csharp
var skillsDir = Path.Combine(Directory.GetCurrentDirectory(), "skills");
var skillsProvider = new FileAgentSkillsProvider(skillPath: skillsDir);
```

Points the provider at the `skills/` directory. On construction, it discovers all subdirectories containing a `SKILL.md` file and parses them into skill definitions.

### Step 3: Agent Creation

```csharp
AIAgent agent = new AzureOpenAIClient(
    new Uri(endpoint), new AzureCliCredential())
    .GetResponsesClient(deploymentName)
    .AsAIAgent(new ChatClientAgentOptions
    {
        Name = "SkillsAgent",
        ChatOptions = new()
        {
            Instructions = "You are a helpful assistant with access to specialized skills.",
        },
        AIContextProviders = [skillsProvider],
    });
```

This chain creates an `AzureOpenAIClient` authenticated via Azure CLI, gets a Responses client for the `gpt-5-mini` deployment, and wraps it as an `AIAgent`. The skills provider is attached through `AIContextProviders`, making all discovered skills available as tools.

### Step 4: Running Prompts

```csharp
AgentResponse response1 = await agent.RunAsync(meetingPrompt);
```

Each call to `RunAsync` sends a prompt to the model. The model sees the registered skill descriptions, picks the best match, and uses that skill's instructions to shape its response. The demo runs three prompts — one per skill — with inline sample data.

## The Three Demo Skills

### meeting-notes (Prompt-only skill)

**What it does:** Summarizes meeting transcripts into structured notes with key discussion points, decisions, and action items.

**How it works:** This is the simplest skill type — pure prompt instructions, no scripts. The `SKILL.md` tells the model to extract four sections: Key Discussion Points, Decisions Made, Action Items (with owner and due date), and a concise Summary. The model follows these instructions to transform raw transcript text into structured markdown.

**Demo input:** A standup transcript with five participants discussing login redesign, payment bugs, search API work, and a staging credentials blocker.

### data-analyzer (Python script skill)

**What it does:** Analyzes datasets and produces statistical summaries, trend identification, and anomaly detection.

**How it works:** The `SKILL.md` instructs the model to report dataset shape, compute statistics (mean, median, min, max, std dev), flag missing data, and highlight trends. It also references `scripts/analyze.py` — a Python script that can process CSV files independently, computing the same statistics programmatically.

**Script:** `skills/data-analyzer/scripts/analyze.py` reads a CSV via `csv.DictReader`, auto-detects numeric columns, and prints summary statistics.

**Demo input:** Six rows of sales data across two regions, two products, and three months.

### code-reviewer (.NET script skill)

**What it does:** Reviews code for bugs, best-practice violations, performance issues, and security concerns.

**How it works:** The `SKILL.md` instructs the model to check best practices, identify potential bugs (null references, race conditions), suggest improvements, and flag security concerns. Each finding is rated as 🔴 Critical, 🟡 Warning, or 🟢 Suggestion. The skill also includes `scripts/analyze.cs` — a C# file-based app that performs basic static analysis (line counts, TODO detection, long-line warnings).

**Script:** `skills/code-reviewer/scripts/analyze.cs` runs via `dotnet run analyze.cs -- <file.cs>` and reports line metrics plus simple code-quality warnings.

**Demo input:** A `UserService` class with a null-dereference bug in `GetDisplayName` and a performance issue (loading all users into memory before filtering) in `GetActiveUsersAsync`.

## Skill File Structure

```
skills/
├── meeting-notes/
│   └── SKILL.md
├── data-analyzer/
│   ├── SKILL.md
│   └── scripts/
│       └── analyze.py
└── code-reviewer/
    ├── SKILL.md
    └── scripts/
        └── analyze.cs
```

Each `SKILL.md` uses YAML frontmatter followed by an Instructions section:

```markdown
---
name: skill-name
description: >-
  When to use this skill. The model reads this to decide
  whether to select this skill for a given prompt.
---

## Instructions

Step-by-step instructions the model follows when this skill is active.
```

The `name` identifies the skill. The `description` is what the model uses to decide if this skill matches a user's request. The `Instructions` section contains the detailed prompt template the model follows.

## How Skill Selection Works

1. **Registration** — `FileAgentSkillsProvider` scans the `skills/` directory and registers each `SKILL.md` as a tool with the model.
2. **Description matching** — When a prompt arrives, the model reads all registered skill descriptions to determine which skill (if any) is relevant.
3. **Instruction application** — The model selects the best-matching skill and uses its Instructions section to shape the response format and content.
4. **Automatic selection** — No routing code is needed. The model picks the right skill based on semantic matching between the prompt and skill descriptions.

## NuGet Packages Used

| Package | Purpose |
|---------|---------|
| `Microsoft.Agents.AI` | Core Agent Skills framework — `AIAgent`, `FileAgentSkillsProvider`, `AgentResponse` |
| `Microsoft.Agents.AI.OpenAI` | OpenAI integration — `.AsAIAgent()` extension method, `ChatClientAgentOptions` |
| `Azure.AI.OpenAI` | Azure OpenAI client SDK — `AzureOpenAIClient`, Responses API |
| `Azure.Identity` | Azure authentication — `AzureCliCredential` for token-based auth |
| `Microsoft.Extensions.Configuration` | Configuration abstractions — `ConfigurationBuilder` |
| `Microsoft.Extensions.Configuration.UserSecrets` | User Secrets provider — keeps endpoints and keys out of source |

## Experimental APIs

```csharp
#pragma warning disable MAAI001, OPENAI001
```

- **MAAI001** — Microsoft Agents AI APIs are in preview. Types like `FileAgentSkillsProvider` and `AIAgent` are marked experimental.
- **OPENAI001** — The OpenAI Responses API (`GetResponsesClient`) is also in preview.

These suppressions are required to compile. The APIs may change in future releases.

## Next Steps

- **Create your own skill:** Add a new directory under `skills/` with a `SKILL.md` file. Define a `name`, `description`, and `Instructions` section. The agent picks it up automatically.
- **Add scripts:** Include executable scripts alongside `SKILL.md` for skills that need programmatic processing.
- **Reference:** See the [Microsoft Agent Framework documentation](https://github.com/microsoft/agents) and the accompanying blog post for more on Agent Skills patterns and advanced scenarios.
