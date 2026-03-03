# Detailed Setup Guide

This guide covers the full setup process for the Agent Skills .NET Demo, including manual steps and troubleshooting.

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [.NET 10 SDK](https://dotnet.microsoft.com/download) | Build and run the console app | `winget install Microsoft.DotNet.SDK.10` |
| [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) | Deploy Azure infrastructure | `winget install Microsoft.Azd` |
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | Fallback for endpoint extraction | `winget install Microsoft.AzureCLI` |
| Python 3.x | Required for the Python skill | `winget install Python.Python.3` |

## Automated Setup (Recommended)

The `setup.ps1` script handles everything after `azd auth login`:

```powershell
azd auth login
./setup.ps1
```

At the end, the script prints the exact `az login --tenant <tenant-id>` command you need before running the demo.

**What it does:**

1. Checks that `azd` and `dotnet` are installed
2. Runs `azd up` (you'll pick subscription and location interactively)
3. Extracts the Azure OpenAI endpoint from the deployment
4. Configures User Secrets automatically

## Manual Setup

If you prefer to run each step manually:

### 1. Deploy Azure Infrastructure

```bash
azd auth login
azd up
```

You'll be prompted to select:
- **Environment name** — any name (e.g., `agent-skills-dev`)
- **Azure subscription**
- **Location** — choose a region that supports Azure OpenAI (e.g., `eastus`)

### 2. Get the Azure OpenAI Endpoint

After deployment, retrieve the endpoint:

```bash
# Option A: From azd environment
azd env get-values | grep AZURE_OPENAI_ENDPOINT

# Option B: From Azure CLI
az cognitiveservices account show \
  --name <your-resource-name> \
  --resource-group <your-resource-group> \
  --query properties.endpoint -o tsv
```

The endpoint looks like: `https://<name>.openai.azure.com/`

### 3. Configure User Secrets

```powershell
dotnet user-secrets set --id agent-skills-demo "AzureOpenAI:Endpoint" "https://<name>.openai.azure.com/"
dotnet user-secrets set --id agent-skills-demo "AzureOpenAI:Deployment" "gpt-5-mini"
```

### 4. Run the Demo

```bash
dotnet run src/agentSkillsDemo.cs
```

## Infrastructure Details

The Bicep files in `infra/` deploy:

- **Resource Group** — named after your azd environment
- **Azure OpenAI Service** — Cognitive Services account (kind: `OpenAI`)
- **Model Deployment** — `gpt-5-mini` with 1K TPM capacity

Files:
- `infra/main.bicep` — Subscription-level orchestrator
- `infra/modules/cognitive-services.bicep` — Azure OpenAI account
- `infra/modules/model-deployment.bicep` — Model deployment
- `infra/main.parameters.json` — Parameter file referencing azd env vars
- `azure.yaml` — azd project configuration

## Troubleshooting

### `azd up` fails with quota error
Choose a different Azure region. Not all regions support all models.

### Endpoint not auto-detected
Run `azd env get-values` manually and look for `AZURE_OPENAI_ENDPOINT`.

### Authentication errors when running the app
The app uses `AzureCliCredential` (reads your `az login` session). Make sure you're logged in to the correct tenant:

```bash
az login --tenant <your-tenant-id>
```

If you get `Token tenant does not match resource tenant`, your `az login` defaulted to the wrong tenant. The `setup.ps1` script prints the correct tenant ID after deployment.
