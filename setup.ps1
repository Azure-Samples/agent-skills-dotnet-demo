#!/usr/bin/env pwsh
# setup.ps1 — Automated setup for Agent Skills .NET Demo
# Deploys Azure infrastructure via azd and configures .NET user secrets.

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$SkipSecrets,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "`n=== Agent Skills Demo — Automated Setup ===" -ForegroundColor Cyan

if ($WhatIfPreference) {
    Write-Host "[DRY-RUN MODE] No changes will be made.`n" -ForegroundColor Magenta
}

# --- Check prerequisites ---
$requiredTools = @("azd", "dotnet")
$optionalTools = @(
    @{ Name = "az";     Label = "Azure CLI (needed for tenant detection)" }
    @{ Name = "python"; Label = "Python (needed for data-analyzer skill)" }
)

foreach ($tool in $requiredTools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: '$tool' is not installed or not on PATH." -ForegroundColor Red
        exit 1
    }
}

foreach ($entry in $optionalTools) {
    if (-not (Get-Command $entry.Name -ErrorAction SilentlyContinue)) {
        Write-Host "WARNING: '$($entry.Name)' not found — $($entry.Label)" -ForegroundColor Yellow
    }
}

# Check az auth status if az is available
if (Get-Command "az" -ErrorAction SilentlyContinue) {
    $azAccount = az account show 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Azure CLI is not logged in. Run 'az login' if deployment needs it." -ForegroundColor Yellow
    }
}

Write-Host "Prerequisites OK ($($requiredTools -join ', '))" -ForegroundColor Green

# --- Check existing User Secrets ---
$deploymentName = "gpt-5-mini"
$secretsId = "agent-skills-demo"
$existingSecrets = $null

try {
    $existingSecrets = dotnet user-secrets list --id $secretsId 2>$null
} catch {
    # No secrets set yet — that's fine
}

$secretsExist = $existingSecrets -and ($existingSecrets | Where-Object { $_ -match 'AzureOpenAI' })

if ($secretsExist -and -not $Force) {
    Write-Host "`nUser Secrets are already configured:" -ForegroundColor Yellow
    $existingSecrets | Where-Object { $_ -match 'AzureOpenAI' } | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
    Write-Host "Use -Force to overwrite, or -SkipSecrets to keep existing values." -ForegroundColor Yellow

    if (-not $WhatIfPreference) {
        $response = Read-Host "Overwrite existing secrets? [y/N]"
        if ($response -notmatch '^[yY]') {
            $SkipSecrets = $true
            Write-Host "Keeping existing User Secrets." -ForegroundColor Green
        }
    } else {
        Write-Host "[DRY-RUN] Would prompt to overwrite existing secrets." -ForegroundColor Magenta
    }
}

# --- Deploy Azure infrastructure ---
Write-Host "`nRunning 'azd up' to deploy Azure infrastructure..." -ForegroundColor Yellow
Write-Host "You will be prompted to select a subscription, location, etc.`n"

if ($PSCmdlet.ShouldProcess("Azure infrastructure", "Deploy with 'azd up'")) {
    azd up
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: 'azd up' failed. User Secrets will NOT be updated." -ForegroundColor Red
        exit 1
    }
    Write-Host "`nDeployment complete!" -ForegroundColor Green
} else {
    Write-Host "[DRY-RUN] Would run 'azd up' to deploy infrastructure." -ForegroundColor Magenta
}

# --- Extract the Azure OpenAI endpoint ---
Write-Host "`nExtracting Azure OpenAI endpoint from deployed environment..." -ForegroundColor Yellow

$envValues = azd env get-values 2>$null
$endpoint = $null

# Try JSON-style parsing first (azd env get-values -o json)
try {
    $envJson = azd env get-values --output json 2>$null
    if ($LASTEXITCODE -eq 0 -and $envJson) {
        $envObj = $envJson | ConvertFrom-Json
        if ($envObj.AZURE_OPENAI_ENDPOINT) {
            $endpoint = $envObj.AZURE_OPENAI_ENDPOINT
        }
    }
} catch {
    # JSON output not supported in this azd version — fall back to line parsing
}

# Fallback: parse KEY="VALUE" lines
if (-not $endpoint -and $envValues) {
    foreach ($line in $envValues) {
        if ($line -match '^\s*AZURE_OPENAI_ENDPOINT\s*=\s*"?([^"]+)"?\s*$') {
            $endpoint = $Matches[1]
        }
    }
}

# Fallback: query Azure directly
if (-not $endpoint -and (Get-Command "az" -ErrorAction SilentlyContinue)) {
    Write-Host "Could not auto-detect endpoint from azd env. Trying az CLI..." -ForegroundColor Yellow
    $rgLine = $envValues | Where-Object { $_ -match 'AZURE_RESOURCE_GROUP' }
    if ($rgLine -match '=\s*"?([^"]+)"?') {
        $rg = $Matches[1]
        $endpoint = az cognitiveservices account list --resource-group $rg --query "[0].properties.endpoint" -o tsv 2>$null
    }
}

if ($endpoint) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Azure OpenAI Endpoint:" -ForegroundColor Cyan
    Write-Host "  $endpoint" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Cyan
} else {
    Write-Host "WARNING: Could not extract endpoint automatically." -ForegroundColor Red
    Write-Host "Run:  azd env get-values  to find it manually.`n"
}

# --- Verify deployment before setting secrets ---
$deploymentVerified = $false
if ($endpoint -and -not $WhatIfPreference) {
    # Quick verification: endpoint should be a valid URL
    if ($endpoint -match '^https://') {
        $deploymentVerified = $true
    } else {
        Write-Host "WARNING: Endpoint does not look valid: $endpoint" -ForegroundColor Yellow
    }
} elseif ($WhatIfPreference) {
    Write-Host "[DRY-RUN] Would verify deployment endpoint." -ForegroundColor Magenta
    $deploymentVerified = $true
}

# --- Set User Secrets (only after verified deployment) ---
if ($SkipSecrets) {
    Write-Host "Skipping User Secrets (--SkipSecrets specified or user chose to keep existing)." -ForegroundColor Yellow
} elseif ($deploymentVerified) {
    if ($PSCmdlet.ShouldProcess("User Secrets ($secretsId)", "Set AzureOpenAI:Endpoint and AzureOpenAI:Deployment")) {
        Write-Host "Setting User Secrets..." -ForegroundColor Yellow
        dotnet user-secrets set --id $secretsId "AzureOpenAI:Endpoint" $endpoint
        dotnet user-secrets set --id $secretsId "AzureOpenAI:Deployment" $deploymentName
        Write-Host "User Secrets configured!" -ForegroundColor Green
    }
} elseif (-not $endpoint) {
    Write-Host "Skipping User Secrets (no endpoint detected). Set them manually:" -ForegroundColor Yellow
    Write-Host "  dotnet user-secrets set --id $secretsId `"AzureOpenAI:Endpoint`" `"<your-endpoint>`""
    Write-Host "  dotnet user-secrets set --id $secretsId `"AzureOpenAI:Deployment`" `"$deploymentName`""
} else {
    Write-Host "Skipping User Secrets (deployment verification failed)." -ForegroundColor Red
    Write-Host "Set them manually after confirming the deployment:" -ForegroundColor Yellow
    Write-Host "  dotnet user-secrets set --id $secretsId `"AzureOpenAI:Endpoint`" `"$endpoint`""
    Write-Host "  dotnet user-secrets set --id $secretsId `"AzureOpenAI:Deployment`" `"$deploymentName`""
}

# --- Detect tenant and remind user to az login to the correct one ---
if (Get-Command "az" -ErrorAction SilentlyContinue) {
    $subId = $null
    foreach ($line in $envValues) {
        if ($line -match '^\s*AZURE_SUBSCRIPTION_ID\s*=\s*"?([^"]+)"?\s*$') {
            $subId = $Matches[1]
        }
    }
    if ($subId) {
        $tenantId = az account show --subscription $subId --query tenantId -o tsv 2>$null
        if ($tenantId) {
            Write-Host "`nIMPORTANT: Before running the demo, login to the correct tenant:" -ForegroundColor Yellow
            Write-Host "  az login --tenant $tenantId" -ForegroundColor White
        }
    }
}

Write-Host "`nSetup complete. Run the demo with:" -ForegroundColor Green
Write-Host "  dotnet run src/agentSkillsDemo.cs`n"
