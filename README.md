# Agent Skills .NET Demo

A sample .NET 10 console application showcasing [Microsoft Agent Framework Agent Skills](https://devblogs.microsoft.com/semantic-kernel/give-your-agents-domain-expertise-with-agent-skills-in-microsoft-agent-framework/). Three demo skills: prompt-only, .NET script, and Python script. Each demo is a single `.cs` file — run it directly with `dotnet run`.

## Key Concepts

- **Agent Skills** — Reusable domain expertise defined in `SKILL.md` files. Skills give agents specialized knowledge for specific tasks (meeting summarization, code review, data analysis).
- **FileAgentSkillsProvider** — Scans a local directory for `SKILL.md` files and registers them as tools the AI model can invoke.
- **File-based .NET 10** — The demo uses `dotnet run file.cs` syntax — no project file needed. NuGet packages are declared with `#:package` directives.

> 📖 **[Full scenario walkthrough →](src/agentSkillsDemo.md)** — Detailed explanation of every concept, code step, and skill type.

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- An Azure subscription
- Python 3.x (for the Python skill)

## Setup Environment (Optional)

If you already have a `gpt-5-mini` Azure OpenAI model deployed, skip to Option B and set User Secrets manually.

### Option A: Deploy with azd (Automated)

Install [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) and [Azure CLI (az)](https://learn.microsoft.com/cli/azure/install-azure-cli), then run:

```powershell
./setup.ps1
```

This deploys the Azure OpenAI resource and configures User Secrets automatically.

### Option B: Manual Setup

If you already have a deployed model, set User Secrets:

```bash
dotnet user-secrets set --id agent-skills-demo "AzureOpenAI:Endpoint" "https://<your-resource>.openai.azure.com/"
dotnet user-secrets set --id agent-skills-demo "AzureOpenAI:Deployment" "gpt-5-mini"
```

(Replace `<your-resource>` with your actual Azure OpenAI resource name.)

## Run the Demo

```bash
dotnet run src/agentSkillsDemo.cs
```

The app uses `AzureCliCredential`, so you need to log in first:

```bash
az login --tenant <your-tenant-id>
```

> ⚠️ If you ran `setup.ps1`, it prints the exact `az login --tenant ...` command at the end. Use that — a plain `az login` may default to the wrong tenant.

### What Happens

```
┌──────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│  Your Prompt │────▶│  ChatClientAgent     │────▶│  Azure OpenAI       │
│              │     │  (with skills tools) │     │  (gpt-5-mini)       │
└──────────────┘     └──────────┬───────────┘     └──────────┬──────────┘
                                │                            │
                                │  FileAgentSkillsProvider   │  model picks
                                │  registers skills as tools │  the best skill
                                │                            │
                     ┌──────────▼───────────┐     ┌──────────▼──────────┐
                     │  Available Skills     │     │  Skill Execution    │
                     │  ┌─────────────────┐  │     │                     │
                     │  │ meeting-notes   │  │◀────│  Runs the selected  │
                     │  │ code-reviewer   │  │     │  skill's prompt /   │
                     │  │ data-analyzer   │  │     │  script and returns │
                     │  └─────────────────┘  │     │  structured output  │
                     └───────────────────────┘     └─────────────────────┘
```

The demo runs **three prompts**, each triggering a different skill with inline sample data:

1. **Meeting Notes** — Summarizes a standup transcript into key points, decisions, and action items
2. **Data Analyzer** — Analyzes CSV sales data for trends, top performers, and anomalies
3. **Code Reviewer** — Reviews a C# code snippet for bugs, performance issues, and best practices

The `FileAgentSkillsProvider` exposes skills as tools — the model reads skill descriptions and automatically picks the best match for each prompt.

> 📖 For detailed steps and configuration, see the [docs](docs/) folder.

## Skills Overview

| Skill | Type | Description |
|-------|------|-------------|
| `meeting-notes` | Prompt-only | Summarizes meeting transcripts into structured notes |
| `code-reviewer` | .NET script | Analyzes code using a C# script |
| `data-analyzer` | Python script | Performs data analysis using Python |

## Clean Up

To delete all Azure resources and clean up local configuration:

```powershell
./cleanup.ps1
```

This script removes the Azure deployment, clears User Secrets, and deletes the local `.azure` folder.

**Alternative (manual):** If you prefer to run commands individually:

```powershell
azd down --purge
```

The `--purge` flag permanently deletes the Azure OpenAI resource (avoiding soft-delete charges). If you skip `--purge`, the resource enters a soft-deleted state and can be recovered within 48 hours.

## Learn More

- [Agent Skills Blog Post](https://devblogs.microsoft.com/semantic-kernel/give-your-agents-domain-expertise-with-agent-skills-in-microsoft-agent-framework/)
- [Agent Skills Documentation](https://learn.microsoft.com/en-us/agent-framework/agents/skills)
