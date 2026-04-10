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
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (for `setup.ps1`; optional if setting up manually)

## Setup Environment

**Decision Tree:**

```
Do you already have an Azure OpenAI (gpt-5-mini) model deployed?
│
├─ YES → Skip to "Option B: Manual Setup" (set User Secrets)
│
└─ NO → Choose:
     ├─ Option A: Automated (setup.ps1) ← Easiest
     └─ Option B: Manual (skip setup.ps1, follow manual steps)
```

### Option A: Deploy with azd (Automated)

If you don't have Azure OpenAI deployed yet, this is easiest.

Install [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) and [Azure CLI (az)](https://learn.microsoft.com/cli/azure/install-azure-cli), then:

```powershell
az login --tenant <your-tenant-id>
./setup.ps1
```

This deploys the Azure OpenAI resource, configures User Secrets, and prints the exact `az login` command to use.

### Option B: Manual Setup

If you already have Azure OpenAI deployed or prefer manual configuration:

```bash
dotnet user-secrets init --id agent-skills-demo
dotnet user-secrets set --id agent-skills-demo "AzureOpenAI:Endpoint" "https://<your-resource>.openai.azure.com/"
dotnet user-secrets set --id agent-skills-demo "AzureOpenAI:Deployment" "gpt-5-mini"
```

Replace `<your-resource>` with your actual Azure OpenAI resource name (e.g., `my-openai-resource`).

## Run the Demo

The app uses `AzureCliCredential`, so log in first:

```bash
az login --tenant <your-tenant-id>
```

> ⚠️ **If you ran `setup.ps1`**, it prints the exact `az login` command at the end. Copy and paste it exactly — a plain `az login` may default to the wrong tenant.

Then run:

```bash
dotnet run src/agentSkillsDemo.cs
```

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

The `FileAgentSkillsProvider` scans `skills/` at startup and exposes skills as tools — the model reads skill descriptions and automatically picks the best match for each prompt.

## Verify Your Setup

After running the demo, verify everything worked:

```
✅ Three prompts executed successfully
✅ Each prompt returned structured output
✅ No auth/credential errors
✅ No missing skills warnings
```

If something failed, see the **Troubleshooting** section below.

---

## Troubleshooting

**Problem:** `AuthenticationFailedException` or credential errors  
**Fix:** See [Error Handling Guide](docs/error-handling.md#azure-credential-failures) — Usually an `az login` issue.

**Problem:** Python skill fails or no output  
**Fix:** See [Error Handling Guide](docs/error-handling.md#python-not-available) — Check Python is installed and in PATH.

**Problem:** Skills not found or agent has no tools  
**Fix:** See [Error Handling Guide](docs/error-handling.md#missing-skills-directory) — Verify `skills/` directory structure.

For **10+ common errors** with detailed fixes, see [docs/error-handling.md](docs/error-handling.md).

---

## Learn More

- 📖 **[Extending the Framework](docs/extending-framework.md)** — Build new skills (prompt-only, .NET script, Python script)
- 📖 **[Error Handling Reference](docs/error-handling.md)** — Troubleshoot Azure, Python, User Secrets, network issues
- 📖 **[Full scenario walkthrough](src/agentSkillsDemo.md)** — Detailed explanation of every concept and code step

## Skills Overview

| Skill | Type | Description |
|-------|------|-------------|
| `meeting-notes` | Prompt-only | Summarizes meeting transcripts into structured notes |
| `code-reviewer` | .NET script | Analyzes code using a C# script |
| `data-analyzer` | Python script | Performs data analysis using Python |

> **⚠️ Note on C# Script Execution:** The `code-reviewer` skill includes a C# script (`scripts/analyze.cs`), but C# script execution is **not yet supported** in the Microsoft Agent Framework and will be added in a future release. See the [Agent Skills documentation](https://learn.microsoft.com/en-us/agent-framework/agents/skills#providing-skills-to-an-agent) for the latest status. In the meantime, the skill's prompt-based instructions (defined in `SKILL.md`) still work — only the script-based static analysis step is unavailable.

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

## Official Resources

- [Agent Skills Blog Post](https://devblogs.microsoft.com/semantic-kernel/give-your-agents-domain-expertise-with-agent-skills-in-microsoft-agent-framework/)
- [Agent Skills Documentation](https://learn.microsoft.com/en-us/agent-framework/agents/skills)
- [Azure OpenAI Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
