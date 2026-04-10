# Error Handling Reference

This guide covers the most common errors encountered when setting up or running the Agent Skills demo, with practical solutions for each.

---

## Azure Credential Failures

### Error: `AuthenticationFailedException` or `No credentials available`

**What It Looks Like:**
```
Unhandled exception: Azure.Identity.AuthenticationFailedException:
SharedTokenCacheCredential: Failed to authenticate via the token cache.
```

### Root Causes

1. **Not logged in to Azure CLI**
2. **Wrong tenant configured**
3. **Stale token in cache**
4. **Multiple Azure accounts (wrong one selected)**

### How to Fix

**Option 1: Log in with correct tenant**
```bash
az login --tenant <your-tenant-id>
```

(If you ran `setup.ps1`, it prints this exact command at the end — copy and run it.)

**Option 2: Clear the token cache and re-authenticate**
```bash
az logout
az login --tenant <your-tenant-id>
```

**Option 3: Force interactive login**
```bash
az login --use-device-code --tenant <your-tenant-id>
```

### Prevention Tips

- **After setup.ps1**, always use the `az login` command it prints — copy-paste it exactly.
- If you switch Azure accounts, run `az logout` first, then `az login` with the correct tenant.
- Verify tenant: `az account show` — check the `tenantId` and `isDefault` fields.

---

## Rate Limiting (429 Errors)

### Error: `The rate limit for the Azure OpenAI resource has been exceeded`

**What It Looks Like:**
```
StatusCode: 429, ReasonPhrase: 'Too Many Requests'
Retry-After: 30
```

### Root Causes

1. **Too many requests sent too quickly**
2. **Concurrent requests to the same deployment**
3. **Azure OpenAI quota exceeded for your subscription**

### How to Fix

**Immediate:**
```csharp
// The demo app handles retries, but if you're testing rapidly:
// 1. Wait 30+ seconds before running again
// 2. Check Azure portal for throttling metrics
```

**Longer-term:**
- Request a quota increase in [Azure Portal](https://portal.azure.com/) → Azure OpenAI → Quotas
- Use a deployment with higher quota (`gpt-5-large` instead of `gpt-5-mini`)
- Add delays between successive invocations in your code

### Prevention Tips

- Run the demo once, wait a minute, then run again if needed
- Don't write loops that hammer the API rapidly without delays
- Monitor usage in Azure Portal → Azure OpenAI → Tokens Used

---

## Missing Skills Directory

### Error: `DirectoryNotFoundException` or Silent Failure

**What It Looks Like:**
```
Unhandled exception: System.IO.DirectoryNotFoundException:
Could not find a part of the path C:\src\agent-skills-dotnet-demo\skills
```

Or the agent simply doesn't have any skills available.

### Root Causes

1. **`skills/` directory deleted or moved**
2. **Running from wrong working directory**
3. **Corrupted skill YAML frontmatter (skills skipped silently)**

### How to Fix

**Check directory exists:**
```bash
ls skills/
# Should show: meeting-notes, code-reviewer, data-analyzer
```

**Run from correct directory:**
```bash
cd C:\src\agent-skills-dotnet-demo
dotnet run src/agentSkillsDemo.cs
```

**Validate SKILL.md files:**
```bash
# Check each skill has valid YAML frontmatter
cat skills/meeting-notes/SKILL.md
# Should show: --- at top, then name: meeting-notes, description: ...
```

### Prevention Tips

- Keep `skills/` at the repository root
- Always run `dotnet run` from the repository root (`C:\src\agent-skills-dotnet-demo`)
- Use the exact structure: `skills/<skill-name>/SKILL.md`

---

## Python Not Available

### Error: `Cannot run program "python"` or Python-based skill silently fails

**What It Looks Like:**
```
The system cannot find the file specified
(Attempting to invoke data-analyzer skill produces no output)
```

### Root Causes

1. **Python not installed**
2. **Python not in system PATH**
3. **Using `python3` but script expects `python`**
4. **Python script has syntax errors**

### How to Fix

**Check Python is installed:**
```bash
python --version
# Or on Mac/Linux:
python3 --version
```

**If not installed:**
- [Download Python 3.x](https://www.python.org/downloads/)
- Run the installer, **check "Add Python to PATH"**
- Restart terminal and verify: `python --version`

**If Python installed but not in PATH:**
```bash
# Find Python installation
which python
# or
where python

# Add to PATH manually (Windows):
# Control Panel → System → Environment Variables → Add Python directory to PATH
```

**Check script syntax:**
```bash
python scripts/analyze.py --help
# Should run without error; if not, syntax error in script
```

### Prevention Tips

- Verify Python is in PATH: `python --version` should work from any directory
- The demo uses `python` (not `python3`); adjust scripts if needed on Linux/Mac
- Test Python skills locally: `python scripts/analyze.py sample.csv` before running the full demo

---

## User Secrets Not Configured

### Error: `InvalidOperationException: The User Secret with ID 'agent-skills-demo' is not configured`

**What It Looks Like:**
```
Unhandled exception: System.InvalidOperationException:
The User Secret with ID 'agent-skills-demo' is not configured.
```

### Root Causes

1. **Secrets not initialized** (`setup.ps1` skipped or failed)
2. **Running on different machine** (secrets stored per-machine)
3. **Secrets corrupted or deleted**

### How to Fix

**Option 1: Run setup.ps1 (recommended)**
```powershell
./setup.ps1
```

This deploys Azure resources and configures secrets automatically.

**Option 2: Set secrets manually**
```bash
dotnet user-secrets init --id agent-skills-demo
dotnet user-secrets set --id agent-skills-demo "AzureOpenAI:Endpoint" "https://<your-resource>.openai.azure.com/"
dotnet user-secrets set --id agent-skills-demo "AzureOpenAI:Deployment" "gpt-5-mini"
```

(Replace `<your-resource>` with your actual Azure OpenAI resource name.)

**Option 3: Verify secrets are set**
```bash
dotnet user-secrets list --id agent-skills-demo
# Should show: AzureOpenAI:Endpoint and AzureOpenAI:Deployment
```

### Prevention Tips

- After setup, verify with: `dotnet user-secrets list --id agent-skills-demo`
- If you move to a new machine, re-run `setup.ps1` or set secrets manually
- Secrets are machine-specific; don't commit them to Git

---

## Network/Connectivity Issues

### Error: `HttpRequestException`, `OperationCanceledException`, or `Connection timeout`

**What It Looks Like:**
```
System.Net.Http.HttpRequestException: An error occurred while sending the request.
---
System.Net.Sockets.SocketException: A connection attempt failed because the connected party did not properly respond.
```

### Root Causes

1. **No internet connection**
2. **Firewall blocking Azure OpenAI endpoint**
3. **Azure service outage**
4. **Proxy misconfiguration**

### How to Fix

**Check internet connectivity:**
```bash
ping 8.8.8.8
# or
curl https://www.google.com
```

**Verify Azure endpoint is reachable:**
```bash
curl https://<your-resource>.openai.azure.com/
# Should get 401 Unauthorized (that's OK; means the service responded)
```

**Check firewall:**
- Windows Firewall: Allow .NET runtime outbound access
- Corporate firewall: Check Azure OpenAI endpoint is whitelisted (*.openai.azure.com)

**Check Azure status:**
- Visit [Azure Status](https://status.azure.com/) — verify no outages in your region

### Prevention Tips

- Run a quick connectivity test before troubleshooting: `ping openai.azure.com`
- Corporate environment? Ask IT to whitelist Azure OpenAI domain
- Try the demo on a different network (personal hotspot) to rule out firewall issues

---

## CSV/Data Format Errors (data-analyzer skill)

### Error: `IndexError: list index out of range` or no output from data-analyzer

**What It Looks Like:**
- Script fails silently or crashes
- Or: `Error: invalid literal for float(): ''`

### Root Causes

1. **Empty CSV file**
2. **CSV missing headers**
3. **Non-numeric data in numeric columns**
4. **Columns with all empty values**

### How to Fix

**Verify CSV format:**
```bash
# CSV should have headers and rows:
cat sample.csv
# Expected:
# Name,Value
# Alice,100
# Bob,200
```

**Test data-analyzer script directly:**
```bash
python skills/data-analyzer/scripts/analyze.py sample.csv
```

**For empty CSVs:**
- Add at least 2 rows of data (stdev requires ≥2 values)
- Include headers: `Column1,Column2`

### Prevention Tips

- Always include CSV headers
- Ensure numeric columns have numeric values (or empty cells — the script skips them)
- Test scripts locally before integrating into the demo

---

## C# Script Execution

### Error: `NotSupportedException` when invoking code-reviewer skill

**What It Looks Like:**
```
The code-reviewer skill includes a script, but C# script execution is not yet supported.
(Skill still works via prompt-based instructions.)
```

### Root Cause

C# script execution via Agent Skills is not yet supported in the Microsoft Agent Framework. A future release will add this capability.

### How to Work Around It

**Your skill still works!** The `code-reviewer` skill uses prompt-based instructions (defined in `SKILL.md`) to guide the agent. The C# script (`scripts/analyze.cs`) is available for manual testing but won't be automatically invoked.

**Manual testing:**
```bash
dotnet run skills/code-reviewer/scripts/analyze.cs -- Program.cs
```

**Check for updates:**
- [Agent Skills Documentation](https://learn.microsoft.com/en-us/agent-framework/agents/skills) — See status section
- GitHub Releases — Microsoft Agent Framework

### Prevention Tips

- Use prompt-only skills or Python scripts for now
- If you need static code analysis, the C# script can still be invoked manually
- Watch the framework documentation for C# script support announcement

---

## Setup.ps1 Script Failures

### Error: `setup.ps1` fails or exits prematurely

**What It Looks Like:**
```
./setup.ps1
(Hangs, exits with error, or incomplete output)
```

### Root Causes

1. **Azure CLI not installed**
2. **Not logged in to Azure (`az login` needed first)**
3. **Insufficient subscription permissions**
4. **Deployment quota exceeded**
5. **setup.ps1 not idempotent (fails on re-run)**

### How to Fix

**Verify prerequisites:**
```bash
az version        # Check Azure CLI installed
az account show   # Check you're logged in
```

**If not logged in:**
```bash
az login --tenant <your-tenant-id>
az account set --subscription <your-subscription-id>
```

**Run setup again:**
```powershell
./setup.ps1
```

**Check permissions:**
- You need "Contributor" or "Owner" role on the subscription
- Ask your Azure admin if unsure

**If setup.ps1 fails mid-way:**
- Clean up partial resources: `azd down --purge`
- Check Azure Portal for failed deployments
- Fix the issue, then run `./setup.ps1` again

### Prevention Tips

- Run `setup.ps1` only once (unless you clean up first with `cleanup.ps1`)
- Verify Azure login before starting: `az account show`
- Keep terminal open to see error messages (they're usually actionable)

---

## "Resource already exists" Errors

### Error: Deployment fails because resource name is taken

**What It Looks Like:**
```
ResourceExistsError: {
  "message": "Provided name is already in use by another resource"
}
```

### Root Causes

1. **Azure Storage account name is globally unique — already taken**
2. **Azure OpenAI deployment name already used in subscription**
3. **Running setup.ps1 twice without cleanup**

### How to Fix

**Option 1: Clean up and re-deploy**
```powershell
./cleanup.ps1
./setup.ps1
```

**Option 2: Edit deployment name (if you know what you're doing)**
- Edit `infra/main.bicep`
- Change storage account suffix or deployment name
- Re-run setup.ps1

**Option 3: Use existing resources**
- If you already have Azure OpenAI deployed, skip setup
- Set User Secrets manually (see "User Secrets Not Configured" above)

### Prevention Tips

- Run `cleanup.ps1` before `setup.ps1` if you've deployed before
- Storage account names must be globally unique (consider adding a suffix with your initials: `agentskills<YOUR_INITIALS>`)

---

## Quick Diagnostic Checklist

When something goes wrong, run through this:

```bash
# 1. Verify Azure login
az account show

# 2. Verify Python
python --version

# 3. Verify User Secrets
dotnet user-secrets list --id agent-skills-demo

# 4. Verify skills directory
ls skills/

# 5. Test Python script in isolation
python skills/data-analyzer/scripts/analyze.py sample.csv

# 6. Run the demo and check output
dotnet run src/agentSkillsDemo.cs
```

If any step fails, refer to the corresponding section above.

---

## Still Stuck?

- **Check [setup-guide.md](setup-guide.md)** — Detailed setup instructions
- **Review [skills-reference.md](skills-reference.md)** — Existing skill patterns
- **Read [extending-framework.md](extending-framework.md)** — Guidelines for custom skills
- **Azure Docs:** [Agent Skills](https://learn.microsoft.com/en-us/agent-framework/agents/skills) and [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
