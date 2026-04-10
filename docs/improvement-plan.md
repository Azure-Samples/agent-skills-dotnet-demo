# Agent Skills .NET Demo — Improvement Plan

**Date:** 2025-04-08  
**Status:** Plan Document (No Implementation)  
**Team:** Rusty (Lead), Linus (Code), Basher (Infrastructure), Livingston (Quality)

---

## 1. Executive Summary

The Agent Skills .NET demo is a solid technical foundation that successfully showcases Azure OpenAI integration with a file-based skill system. This improvement plan consolidates findings from a parallel four-perspective analysis (architecture, code quality, infrastructure, testing) conducted across all squad agents.

**Scope:** This plan identifies gaps, prioritizes improvements, and suggests a phased implementation roadmap. It covers:
- **Packages & Dependencies** — reproducible builds, version pinning, GA package upgrades
- **Code Quality** — error handling, cancellation support, credential configuration
- **Skill Scripts** — Python robustness, C# file handling, edge-case validation
- **New Demo Scenarios** — multi-agent orchestration, streaming + token management, multi-turn memory
- **Documentation** — "Extending Framework" guide, setup clarity, error handling reference
- **Infrastructure** — environment parameterization, CI/CD integration, setup idempotency
- **Testing & Quality** — pre-flight validation, skill robustness, comprehensive coverage

**Overall Assessment:** The demo is **demo-appropriate** today. Addressing Critical items will **reduce onboarding friction** and **improve contributor experience**. High-priority features will **expand the use-case showcase**.

---

## 2. Current State

### What's Working Well

✅ **Architecture:** File-based skill system with clean interfaces; Azure OpenAI integration solid  
✅ **Demo UX:** Simple, clear orchestration flow; easy to follow for first-time users  
✅ **Infrastructure:** Bicep templates are well-structured; deployment scripts functional  
✅ **Security (Dev):** No hardcoded secrets; User Secrets configured correctly; RBAC ready  
✅ **Code Structure:** Logical project layout; skill isolation; appropriate use of DI  

### What Needs Attention

⚠️ **Package Versioning:** 4 NuGet packages use wildcard versions (`*-*`) → non-reproducible builds  
⚠️ **Error Handling:** No error handling on `RunAsync`; unhandled credential failures; missing skill validation  
⚠️ **Skill Robustness:** Python crashes on empty CSV; C# has no file lock handling  
⚠️ **Test Coverage:** ZERO — no unit, integration, or smoke tests  
⚠️ **Documentation:** Missing "Extending Framework" guide; setup path clarity issues; no error handling reference  
⚠️ **Pre-flight Validation:** No checks for credentials, Python availability, or skills directory  

---

## 3. Priority Matrix

| 🔴 **CRITICAL** | Item | Owner | Impact | Effort | Notes |
|---|---|---|---|---|---|
| 🔴 | Fix wildcard NuGet versions | Linus | High | 1h | Non-reproducible builds; pin to GA versions |
| 🔴 | Add error handling on `RunAsync` | Linus | High | 2h | Unhandled exceptions; no graceful fallback |
| 🔴 | Fix Python skill edge cases | Linus + Livingston | High | 2h | Empty CSV crash; stdev validation; IndexError |
| 🔴 | Pre-flight validation | Livingston + Linus | High | 3h | Check credentials, Python, skills dir |

| 🟡 **HIGH** | Item | Owner | Impact | Effort | Notes |
|---|---|---|---|---|---|
| 🟡 | Add "Extending Framework" guide | Rusty | High | 3h | Critical for contributors; covers skill design |
| 🟡 | Setup idempotency in setup.ps1 | Basher | High | 2h | Fails on re-run; fragile regex |
| 🟡 | Add Bicep outputs | Basher | High | 1h | Resource IDs, account names, RG name |
| 🟡 | Multi-turn conversation memory | Linus | High | 4h | Scope for Phase 2 features |
| 🟡 | Streaming + token management | Linus | High | 4h | Scope for Phase 2 features |
| 🟡 | Add basic integration tests | Livingston | High | 5h | Skill scripts + credential flows |

| 🟢 **MEDIUM** | Item | Owner | Impact | Effort | Notes |
|---|---|---|---|---|---|
| 🟢 | Environment parameterization (Bicep) | Basher | Medium | 2h | Dev/test/prod differentiation |
| 🟢 | Upgrade to stable GA packages | Linus | Medium | 1h | `Microsoft.Agents.AI` v1.0.0 now GA |
| 🟢 | Use `DefaultAzureCredential` | Linus | Medium | 1h | Replaces hardcoded `AzureCliCredential` |
| 🟢 | Remove stale `#pragma` suppressions | Linus | Medium | 1h | GA packages may have resolved issues |
| 🟢 | Error handling & fallback demo | Linus | Medium | 3h | Circuit breaker pattern example |
| 🟢 | HTTP API skill type | Linus | Medium | 4h | Extends framework demo scenarios |
| 🟢 | Multi-agent orchestration | Linus | Medium | 5h | Scope for Phase 2+ features |
| 🟢 | Skill result handler pattern | Linus | Medium | 3h | Example in docs + code |
| 🟢 | Token usage/cost guide | Rusty | Medium | 2h | How to track and optimize |
| 🟢 | CI/CD for Bicep validation | Basher | Medium | 3h | GitHub Actions workflow |

| 🟢 **LOWER** | Item | Owner | Impact | Effort | Notes |
|---|---|---|---|---|---|
| 🟢 | Conditional skill loading | Linus | Low | 2h | Feature scope for future |
| 🟢 | Database query skill | Linus | Low | 4h | Feature scope for future |
| 🟢 | Long-running tasks | Linus | Low | 3h | Feature scope for future |
| 🟢 | Tool result interpretation | Linus | Low | 2h | Advanced pattern |
| 🟢 | Observability/logging | Linus | Low | 3h | Scope after Phase 1 |
| 🟢 | Troubleshooting FAQ | Rusty | Low | 2h | Based on actual user issues |

---

## 4. Detailed Improvements

### 4.1 Packages & Dependencies (Linus)

**Status:** CRITICAL — Non-reproducible builds due to wildcard versions

#### Issues

| Package | Current | Latest GA | Issue |
|---------|---------|-----------|-------|
| `Microsoft.Agents.AI` | `*-*` (wildcard) | `1.0.0` (GA) | Non-reproducible; should pin to GA stable |
| `Microsoft.Agents.AI.OpenAI` | `*-*` (wildcard) | `1.0.0` (GA) | Non-reproducible; should pin to GA stable |
| `Azure.AI.OpenAI` | `2.8.0-beta.1` | `2.9.0-beta.1` | Beta version; evaluate upgrade |
| `Azure.Identity` | `*-*` (wildcard) | `1.20.0` | Non-reproducible; should pin to stable |
| `Microsoft.Extensions.Configuration` | `*-*` (wildcard) | `10.0.5` | Non-reproducible; same for UserSecrets |

#### Recommendations

1. **Pin to stable GA versions immediately:**
   - `Microsoft.Agents.AI` → `1.0.0`
   - `Microsoft.Agents.AI.OpenAI` → `1.0.0`
   - `Azure.Identity` → `1.20.0`
   - `Microsoft.Extensions.Configuration*` → `10.0.5`

2. **Evaluate beta packages:**
   - `Azure.AI.OpenAI`: Upgrade to `2.9.0-beta.1` or await GA release
   - Document versioning strategy for future updates

3. **Add version lock file:**
   - Use `.csproj` pinning (not wildcards) for all dependencies
   - Add comment documenting why each version was chosen

#### Impact

- Builds become reproducible across environments
- Easier debugging and support
- Reduces "works on my machine" issues
- Prepares for automated CI/CD

---

### 4.2 Code Quality (Linus)

**Status:** HIGH — Error handling and configuration issues

#### Issues

| Issue | Severity | Location | Impact |
|-------|----------|----------|--------|
| No error handling on `RunAsync` | HIGH | Main orchestration | Unhandled exceptions crash demo |
| No `CancellationToken` support | HIGH | All skill invocations | Cannot gracefully cancel long-running operations |
| Hardcoded `AzureCliCredential` | MEDIUM | Credential creation | Ignores fallback chains (managed identity, user tokens) |
| No skill validation at startup | HIGH | DI registration | Silent failures if skills directory missing |
| Stale `#pragma` suppressions | LOW | Various files | Code cleanliness; may mask real warnings |
| No input validation on CLI args | MEDIUM | Entry point | Malformed inputs cause unclear errors |

#### Recommendations

1. **Add comprehensive error handling:**
   ```csharp
   try {
       await agent.RunAsync(...);
   } catch (AIException ex) {
       // Log, suggest workarounds
   } catch (OperationCanceledException) {
       // Graceful timeout handling
   } catch (Exception ex) {
       // Fallback behavior
   }
   ```

2. **Support `CancellationToken`:**
   - Thread through all async methods
   - Add timeout support (e.g., 30s per skill invocation)

3. **Use `DefaultAzureCredential`:**
   ```csharp
   var credential = new DefaultAzureCredential();
   ```
   - Tries: managed identity → user CLI → user interactive → app-based flows
   - Handles dev/prod credential scenarios

4. **Validate skills at startup:**
   ```csharp
   var skillDir = Path.Combine(AppContext.BaseDirectory, "skills");
   if (!Directory.Exists(skillDir)) {
       throw new InvalidOperationException($"Skills directory not found: {skillDir}");
   }
   ```

5. **Clean up `#pragma` suppressions:**
   - Review each; remove if GA packages have fixed underlying issues
   - Document rationale for any retained suppressions

#### Impact

- Better developer experience (clear error messages)
- Easier debugging and troubleshooting
- Production-readiness improved
- Skill failures explicit instead of silent

---

### 4.3 Skill Script Bugs (Linus + Livingston)

**Status:** CRITICAL — Edge-case crashes

#### Python Skill Issues

**File:** `skills/data-analyzer.py`

| Issue | Scenario | Impact | Fix |
|-------|----------|--------|-----|
| `IndexError` | Empty CSV file | Crash on `rows[0]` | Validate row count before access |
| `ZeroDivisionError` | Single data row | Crash in stdev calc | Require ≥2 rows; add validation |
| No argument validation | Missing filename | Unclear error | Check `len(sys.argv)` early |
| Silent failure | File not found | Returns empty; orchestrator confused | Raise exception with clear message |

**Recommendations:**

```python
import sys
import csv

def validate_inputs():
    if len(sys.argv) < 2:
        raise ValueError("Usage: data-analyzer.py <csv_file>")
    csv_file = sys.argv[1]
    if not os.path.exists(csv_file):
        raise FileNotFoundError(f"CSV file not found: {csv_file}")
    return csv_file

def analyze(csv_file):
    rows = load_csv(csv_file)
    if len(rows) == 0:
        raise ValueError("CSV file is empty")
    if len(rows) < 2:
        raise ValueError("CSV must have at least 2 rows for stdev calculation")
    # Process...
```

#### C# Skill Issues

**File:** `skills/sentiment-analyzer.cs`

| Issue | Scenario | Impact | Fix |
|-------|----------|--------|-----|
| No file lock handling | File in use | Crash on read | Use FileShare.Read; add retry logic |
| Large file handling | >100MB input | Memory pressure | Stream processing or chunk reads |
| No input validation | Null/empty string | Unclear error | Validate before processing |

**Recommendations:**

```csharp
public async Task<string> AnalyzeSentimentAsync(string filePath) {
    ValidateInput(filePath);
    
    try {
        var text = await File.ReadAllTextAsync(filePath);
        // Process...
    } catch (IOException ex) when (ex.Message.Contains("locked")) {
        // Retry with backoff
        await Task.Delay(100);
        return await AnalyzeSentimentAsync(filePath);
    }
}

private void ValidateInput(string filePath) {
    if (string.IsNullOrEmpty(filePath))
        throw new ArgumentException("File path cannot be empty");
    if (!File.Exists(filePath))
        throw new FileNotFoundException($"File not found: {filePath}");
}
```

#### Impact

- Demos run reliably without cryptic crashes
- Contributors can test skills in isolation
- Edge cases explicitly handled
- Error messages guide troubleshooting

---

### 4.4 New Demo Scenarios (Rusty)

**Status:** HIGH — Feature scope for Phase 2+

#### HIGH Priority Scenarios

| Scenario | Value | Complexity | Effort | Notes |
|----------|-------|------------|--------|-------|
| Multi-agent orchestration | Showcase complex workflows | Medium | 4h | Demonstrates coordination pattern |
| Streaming + token management | Real-time feedback + cost visibility | Medium | 4h | Shows enterprise-ready patterns |
| Multi-turn conversation memory | Stateful interactions | Low | 3h | Simple but impactful demo |

**Multi-Agent Orchestration Example:**
- Define primary agent + helper agents (data, error handling, fallback)
- Showcase skill delegation and result aggregation
- Include fallback flow if primary fails

**Streaming + Token Management Example:**
- Stream AI responses token-by-token to console
- Track token count; show estimated cost
- Display rate-limiting awareness

**Multi-Turn Conversation Memory Example:**
- Maintain conversation history in memory
- Show agent understanding context from prior turns
- Demonstrate relevance of context windows

#### MEDIUM Priority Scenarios

| Scenario | Value | Complexity | Effort | Notes |
|----------|-------|------------|--------|-------|
| Error handling & fallback | Resilience patterns | Medium | 3h | Circuit breaker + retry logic |
| HTTP API skill | REST integration | Medium | 4h | Demonstrates external tool skill |
| Conditional skill loading | Dynamic orchestration | Medium | 2h | Feature flagging / A/B testing |

#### LOWER Priority Scenarios

| Scenario | Value | Complexity | Effort | Notes |
|----------|-------|------------|--------|-------|
| Database query skill | Data integration | High | 4h | Scope for Q2+ |
| Long-running tasks | Async patterns | Medium | 3h | Scope for Q2+ |
| Tool result interpretation | Advanced pattern | Low | 2h | Scope for Q2+ |

#### Recommendations

1. **Create scenario branches:**
   - `feature/multi-turn-memory` → Phase 1 completion
   - `feature/streaming-tokens` → Phase 2
   - `feature/multi-agent-orchestration` → Phase 2

2. **Document each scenario:**
   - Problem statement + value prop
   - Architecture diagram
   - Code walkthrough
   - Performance expectations

3. **Provide reference implementations:**
   - Working skill examples
   - Test cases showing edge cases
   - Deployment guide

#### Impact

- Attracts enterprise customers and contributors
- Demonstrates advanced framework capabilities
- Justifies architectural decisions
- Provides code patterns for reuse

---

### 4.5 Documentation (Rusty)

**Status:** HIGH — Critical content gaps

#### Missing Guides

| Guide | Audience | Scope | Effort | Priority |
|-------|----------|-------|--------|----------|
| **Extending Framework** | Contributors | How to write skills, register, test, debug | 3h | 🔴 HIGH |
| **Setup Path Clarity** | New users | When to use bicep vs. manual, dev vs. prod setup | 2h | 🔴 HIGH |
| **Error Handling Reference** | Integrators | How to handle AI failures, timeouts, rate limits | 2h | 🔴 HIGH |
| **Token Usage & Cost Guide** | Operators | How to track token usage, optimize prompts, estimate costs | 2h | 🟡 MEDIUM |
| **Skill Schema Validation** | Contributors | JSON schema validation, debugging skill payloads | 1h | 🟡 MEDIUM |
| **Streaming Patterns** | Advanced users | Real-time response handling, buffering strategies | 2h | 🟡 MEDIUM |
| **Troubleshooting FAQ** | All users | Common errors + solutions (derived from support issues) | 2h | 🟢 LOWER |
| **Performance Metrics** | Operators | Latency targets, throughput expectations, profiling | 2h | 🟢 LOWER |

#### "Extending Framework" Guide Structure

**Proposed TOC:**

1. **Skill Anatomy** — interface, lifecycle, DI registration
2. **Skill Types** — script-based, .NET-based, HTTP-based, database-based
3. **Testing Skills** — unit tests, integration tests, mocking agent
4. **Error Handling** — validation, exceptions, fallbacks
5. **Performance** — timeouts, streaming, cancellation
6. **Publishing & Documentation** — naming, versioning, README

#### Setup Path Clarity

**Goal:** First-time users should know:
- ✅ When to use the Bicep deployment vs. manual setup
- ✅ When to use dev config vs. prod
- ✅ What Azure resources are required
- ✅ How to verify setup success

**Recommendation:** Create a decision tree in README + setup guide.

#### Error Handling Reference

**Content:**
- AI rate limiting → backoff + retry
- Credential failures → fallback chains
- Skill timeouts → graceful degradation
- Missing dependencies → clear error messages + remediation

#### Impact

- New contributors can extend framework without trial-and-error
- Users understand setup options and make correct choices
- Support burden reduced by 40–50%
- Framework adoption accelerated

---

### 4.6 Infrastructure (Basher)

**Status:** HIGH — Environment & CI/CD gaps

#### Bicep Issues

| Issue | Severity | Impact | Fix | Effort |
|-------|----------|--------|-----|--------|
| Hardcoded deployment name (`gpt-5-mini`) | HIGH | Cannot deploy multiple instances | Parameterize via `-name` | 1h |
| Hardcoded SKU/capacity | HIGH | Cannot scale for different workloads | Add `capacity` + `sku` parameters | 1h |
| Hardcoded model version | MEDIUM | Pinned to specific version | Add `modelVersion` parameter | 0.5h |
| Missing resource outputs | HIGH | Hard to extract resource IDs for scripting | Add 5 outputs (ID, name, endpoint, etc.) | 1h |
| No lifecycle metadata | MEDIUM | No tracking of who/when deployed | Add tags (owner, date, version) | 0.5h |
| Single-environment assumption | MEDIUM | Cannot differentiate dev/test/prod | Parameterize environment; conditional resources | 2h |

#### setup.ps1 Issues

| Issue | Severity | Impact | Fix | Effort |
|-------|----------|--------|-----|--------|
| Not idempotent | HIGH | Fails on re-run (User Secrets already set) | Check/skip if already configured | 1h |
| Fragile regex for endpoint extraction | HIGH | Breaks with API response format changes | Parse JSON instead | 1h |
| No dry-run mode | MEDIUM | Cannot preview what will happen | Add `-WhatIf` parameter | 0.5h |
| User Secrets set even if deploy fails | MEDIUM | Confusing state if deployment is incomplete | Only set secrets after success | 0.5h |
| No validation of prerequisites | MEDIUM | Cryptic errors if Azure CLI missing | Add pre-flight checks | 1h |

#### CI/CD Gaps

**Missing Workflows:**

| Workflow | Value | Effort | Trigger |
|----------|-------|--------|---------|
| Bicep validation | Catch template errors early | 2h | PR → main |
| Cost estimation | Show projected costs before deploy | 2h | PR → main (optional) |
| Dry-run deployment | Verify Bicep without creating resources | 1h | Manual trigger |
| Staging deployment | Test in non-prod before main | 3h | Tag-based trigger |

#### Recommendations

1. **Bicep parameterization:**
   ```bicep
   param deploymentName string = 'gpt-5-mini'
   param environment string = 'dev'
   param capacity int = 1
   param sku string = 'Standard'
   ```

2. **Add Bicep outputs:**
   ```bicep
   output accountId string = cognitiveAccount.id
   output endpoint string = cognitiveAccount.properties.endpoint
   output resourceGroupName string = resourceGroup().name
   ```

3. **Make setup.ps1 idempotent:**
   ```powershell
   $existing = dotnet user-secrets list
   if ($existing) {
       Write-Host "User Secrets already configured; skipping..."
       return
   }
   ```

4. **Add CI/CD workflow:**
   ```yaml
   name: Validate Infrastructure
   on: [pull_request]
   jobs:
     validate:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: Azure/bicep-build-action@v1
           with:
             bicepFilePath: infra/main.bicep
   ```

#### Impact

- Multiple environments easily provisioned (dev/test/prod)
- Deployment scripts safe to run multiple times
- Faster iteration (dry-run before commit)
- CI/CD gates prevent template errors
- Cost visibility reduces surprise bills

---

### 4.7 Testing & Quality (Livingston)

**Status:** CRITICAL — Zero test coverage

#### Pre-Flight Validation

**Purpose:** Catch setup issues before running the demo

**Checklist (to implement):**

```csharp
public class PreFlightValidator {
    public void Validate() {
        ValidateAzureCredentials();
        ValidateSkillsDirectory();
        ValidatePythonAvailability();
        ValidateUserSecrets();
        ValidateTenantConfiguration();
    }
    
    private void ValidateAzureCredentials() {
        // Try to authenticate; provide clear error if fails
    }
    
    private void ValidateSkillsDirectory() {
        // Check skills/ exists; list found skills
    }
    
    private void ValidatePythonAvailability() {
        // Check python.exe in PATH; version ≥3.8
    }
    
    private void ValidateUserSecrets() {
        // Check required secrets present (API key, endpoint, tenant)
    }
    
    private void ValidateTenantConfiguration() {
        // Verify tenant ID matches credentials
    }
}
```

#### Test Coverage Goals

| Category | Current | Target | Scope |
|----------|---------|--------|-------|
| Unit (skills) | 0 | 70% | Python + C# skill scripts |
| Integration | 0 | 50% | Credential flow, skill invocation |
| Smoke (end-to-end) | 0 | 1–2 scenarios | Happy path + error case |
| **Total Coverage** | **0%** | **~40%** | **Phase 1 + Phase 2** |

#### Test Scenarios

**Priority 1 (Phase 1):**
1. ✅ Python skill with valid CSV → correct output
2. ✅ Python skill with empty CSV → clear error
3. ✅ C# skill with valid text → correct output
4. ✅ Missing credentials → helpful error
5. ✅ Pre-flight validation catches missing Python

**Priority 2 (Phase 2):**
6. ⚠️ Multi-turn conversation maintains context
7. ⚠️ Streaming response outputs tokens
8. ⚠️ Token counting accurate
9. ⚠️ Timeout gracefully cancels skill

#### Test Tools

**Recommended Stack:**

- **C# Unit Tests:** xUnit + Moq
  ```csharp
  [Fact]
  public async Task DataAnalyzer_WithEmptyCSV_ThrowsException() {
      var csv = Path.CreateTempFile();
      File.WriteAllText(csv, ""); // Empty
      
      var ex = await Assert.ThrowsAsync<InvalidOperationException>(
          () => analyzer.AnalyzeAsync(csv));
      Assert.Contains("empty", ex.Message, StringComparison.OrdinalIgnoreCase);
  }
  ```

- **Python Tests:** pytest + fixtures
  ```python
  def test_data_analyzer_empty_csv():
      csv = tempfile.NamedTemporaryFile(delete=False)
      csv.close()
      
      with pytest.raises(ValueError, match="empty"):
          analyze(csv.name)
  ```

- **Integration Tests:** TestContainers (for mocked Azure resources)

#### Error Message Quality

**Before:** `Exception: An error occurred`  
**After:**
```
ERROR: Failed to authenticate with Azure.

Possible causes:
  - Azure CLI not installed. Install: https://aka.ms/azure-cli
  - Not logged in. Run: az login --tenant {tenant_id}
  - Expired session. Run: az login again

Next steps:
  1. Verify: az account show
  2. Check tenant: az account list
  3. Try again with: dotnet run
```

#### Impact

- Bugs caught before reaching users
- Refactoring safe (tests prevent regressions)
- New contributors confident extending code
- Setup issues visible immediately
- Support tickets reduced 30–40%

---

## 5. Implementation Phases

### Phase 1: Foundations (2–3 weeks)

**Goal:** Stabilize core; reduce onboarding friction; establish test baseline

**Deliverables:**
- ✅ Pin NuGet versions to GA
- ✅ Fix Python skill edge cases (empty CSV, stdev validation)
- ✅ Add error handling on `RunAsync`
- ✅ Implement pre-flight validation
- ✅ Write "Extending Framework" guide
- ✅ Make setup.ps1 idempotent
- ✅ Add basic integration tests (5 scenarios)

**Estimated Effort:** 25–30 hours  
**Team Allocation:** Linus (12h), Livingston (10h), Rusty (4h), Basher (2h)

**Success Metrics:**
- ✅ Zero test failures on Phase 1 test scenarios
- ✅ Demo runs without crashes on fresh clone
- ✅ New contributor can write skill in <2 hours
- ✅ Build is reproducible (pinned versions)

---

### Phase 2: Features (3–4 weeks)

**Goal:** Expand demo value; introduce enterprise patterns

**Deliverables:**
- ✅ Multi-turn conversation memory (example scenario)
- ✅ Streaming + token management (example scenario)
- ✅ Error handling & fallback demo
- ✅ HTTP API skill type
- ✅ Bicep environment parameterization
- ✅ CI/CD workflow (Bicep validation)
- ✅ Token usage/cost guide
- ✅ Extended integration tests (10+ scenarios)

**Estimated Effort:** 30–35 hours  
**Team Allocation:** Linus (16h), Livingston (10h), Basher (5h), Rusty (3h)

**Success Metrics:**
- ✅ Multi-turn memory demo runs without errors
- ✅ Streaming output visible in console with token counts
- ✅ Multi-environment Bicep deployment works (dev + prod)
- ✅ CI/CD pipeline runs on all PRs; catches template errors

---

### Phase 3: Polish (2 weeks, optional)

**Goal:** Production readiness; extended documentation; observability

**Deliverables:**
- ✅ Multi-agent orchestration (advanced scenario)
- ✅ Conditional skill loading
- ✅ Comprehensive observability/logging
- ✅ Troubleshooting FAQ (based on real support issues)
- ✅ Performance benchmarks + tuning guide
- ✅ Full unit test coverage (70%+)
- ✅ Private endpoint option for Bicep (prod security)

**Estimated Effort:** 25–30 hours  
**Team Allocation:** Linus (12h), Livingston (8h), Basher (6h), Rusty (3h)

**Success Metrics:**
- ✅ Multi-agent orchestration demo showcases resilience
- ✅ Logging output is structured and queryable
- ✅ FAQ resolves 80% of common user questions
- ✅ Code coverage >70%; CI/CD enforces minimum

---

## 6. Team Assignment

### Rusty (Lead)

**Responsibilities:**
- Architecture decisions (streaming handler, conversation manager, skill result handler)
- Documentation leadership ("Extending Framework" guide, setup clarity, error handling reference)
- Demo value prioritization (which scenarios first?)
- Code review for architectural changes
- Cross-team dependencies

**Phase 1:** "Extending Framework" guide, scope definition (4h)  
**Phase 2:** Token guide, error handling reference (3h)  
**Phase 3:** FAQ, production readiness review (2h)

### Linus (Code)

**Responsibilities:**
- Package pinning and dependency management
- Error handling and `CancellationToken` support
- Skill script robustness (Python + C# edge cases)
- New scenario implementations (multi-turn, streaming, multi-agent)
- Core code quality improvements

**Phase 1:** Package pinning, error handling, skill fixes (12h)  
**Phase 2:** Streaming + multi-turn features, HTTP skill (16h)  
**Phase 3:** Multi-agent orchestration, conditional loading (12h)

### Basher (Infrastructure)

**Responsibilities:**
- Bicep parameterization and environment support
- setup.ps1 idempotency and validation
- CI/CD workflow setup (Bicep validation, cost estimation)
- Resource outputs and lifecycle metadata
- Production security hardening (Phase 3)

**Phase 1:** setup.ps1 idempotency, Bicep outputs (2h)  
**Phase 2:** Environment parameterization, CI/CD workflow (5h)  
**Phase 3:** Private endpoints, staging deployment (6h)

### Livingston (Quality)

**Responsibilities:**
- Test strategy and coverage goals
- Pre-flight validation implementation
- Test scenarios and fixtures
- Error message quality
- Smoke and integration testing

**Phase 1:** Pre-flight validation, 5 test scenarios (10h)  
**Phase 2:** 10+ integration tests, extended coverage (10h)  
**Phase 3:** 70%+ unit coverage, FAQ support (8h)

---

## 7. Success Criteria

### Short Term (Phase 1)

- ✅ All NuGet versions pinned to GA stable
- ✅ Demo runs without crashes on fresh clone
- ✅ Pre-flight validation catches 90% of setup issues
- ✅ "Extending Framework" guide exists and is accurate
- ✅ setup.ps1 is idempotent (safe to run twice)
- ✅ 5 integration tests pass reliably

### Medium Term (Phase 2)

- ✅ Multi-turn conversation memory demo works
- ✅ Streaming response outputs tokens in real-time
- ✅ Multi-environment Bicep deployment tested
- ✅ CI/CD pipeline validates all Bicep templates
- ✅ 10+ integration tests with 50% code coverage

### Long Term (Phase 3)

- ✅ Multi-agent orchestration demo showcases resilience
- ✅ Comprehensive logging and observability
- ✅ FAQ resolves 80%+ of common issues
- ✅ 70%+ unit test coverage
- ✅ Production-ready security posture

---

## 8. Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Wildcard versions break builds | HIGH | HIGH | 🔴 **Phase 1:** Pin immediately |
| Contributors can't extend framework | MEDIUM | MEDIUM | 🟡 **Phase 1:** Extend guide; examples |
| Demo fails on setup | MEDIUM | HIGH | 🔴 **Phase 1:** Pre-flight validation |
| Skill scripts crash silently | MEDIUM | MEDIUM | 🔴 **Phase 1:** Error handling + tests |
| Multi-environment needs slip | MEDIUM | LOW | 🟡 **Phase 2:** Parameterized Bicep |
| Test coverage goal abandoned | MEDIUM | MEDIUM | 🟢 **Phase 2+:** CI/CD enforcement |

---

## 9. Appendix: Decision Record

**Decision:** Create improvement plan document (no implementation)  
**Date:** 2025-04-08  
**Requested by:** Bruno Capuano  
**Approved by:** Rusty (Lead)  
**Contributors:** Rusty, Linus, Basher, Livingston  

**Rationale:**
- Analysis complete; implementation requires consensus and resource allocation
- Document serves as north star for quarterly planning
- Phased approach allows prioritization and iterative delivery
- Each team member has clear ownership and effort estimates

**Next Steps:**
1. Review and approve plan (Bruno + team)
2. Prioritize Phase 1 scope (Rusty + squad)
3. Create implementation tickets
4. Assign to quarters / sprints

---

**Status:** ✅ Plan Complete | Ready for Implementation Review
