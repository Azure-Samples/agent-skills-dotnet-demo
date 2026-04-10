# Squad Decisions

## Active Decisions

### 2026-04-08: Improvement Analysis — Four-Perspective Assessment

**Requested by:** Bruno Capuano  
**Status:** Analysis Complete (Awaiting Implementation Consensus)  
**Contributors:** Rusty, Linus, Basher, Livingston

#### A. Architectural Opportunities (Rusty)

**Scenario Improvements:**
- **HIGH Priority:** Multi-agent orchestration, streaming + token management, multi-turn conversation memory
- **MEDIUM Priority:** Error handling & fallback, HTTP API skill, conditional skill loading
- **LOWER Priority:** Database query skill, long-running tasks, tool result interpretation

**Documentation Gaps:**
- HIGH: "Extending Framework" guide, setup path clarity, error handling reference
- MEDIUM: Token usage/cost guide, skill schema validation, streaming patterns
- LOWER: Troubleshooting FAQ, performance metrics

**Architecture Patterns:**
- HIGH: Streaming response handler, conversation manager, skill result handler
- MEDIUM: Observability/logging, dependency injection, skill validation at registration
- LOWER: Custom AIContextProvider, tool call interpretation, model-specific optimization

**Prioritization Matrix:**
| Item | Impact | Effort | Priority |
|------|--------|--------|----------|
| Multi-Agent Orchestration | High | Medium | **HIGH** |
| Streaming + Tokens | High | Medium | **HIGH** |
| Multi-Turn Conversation | High | Low | **HIGH** |
| Extending Guide | High | Low | **HIGH** |

**Next Steps:** Scope prioritization per strategic goals; design APIs; plan implementation.

---

#### B. Infrastructure Posture (Basher)

**Current State:** Solid foundation, demo-stage appropriate.

**HIGH Priority Issues:**
1. Missing environment parameterization (dev/test/prod differentiation)
2. Hardcoded deployment name (`gpt-5-mini`)
3. Missing lifecycle metadata in Bicep
4. Insufficient outputs for diagnostics (only 2 of 5 needed)

**setup.ps1 Issues:**
1. Not idempotent (fails on re-run)
2. Fragile endpoint extraction (regex brittleness)
3. No dry-run/preview mode
4. User secrets set even if deployment fails

**Missing CI/CD:**
- No Bicep validation pipeline
- No ARM template validation
- No cost estimation workflow
- No staging deployment

**Security (Development-Appropriate):**
- ✅ No hardcoded secrets
- ✅ User Secrets configured correctly
- ✅ RBAC ready
- ⚠️ Public network access OK for dev; hardening needed for prod

**Recommendation Matrix:**
| Category | Current | Priority | Effort | Impact |
|----------|---------|----------|--------|--------|
| Env Parameterization | Hardcoded | HIGH | 2h | High |
| Missing Outputs | 2/5 | HIGH | 1h | High |
| setup.ps1 Idempotency | Not idempotent | MEDIUM | 2h | High |
| Bicep Validation CI/CD | None | MEDIUM | 3h | High |

**No current blockers** for demo/dev work. Production roadmap requires parameterization and CI/CD.

---

#### C. Quality Posture (Livingston)

**Test Coverage:** ZERO
- No unit, integration, or smoke tests
- Skill scripts untested in isolation
- No validation with invalid/edge-case data

**Error Paths:** UNHANDLED
- Azure credential failures → raw exceptions
- Missing skills directory → silent failure
- Python not installed → data-analyzer produces no output
- Empty/malformed CSV → crashes or silent skips
- Locked file → C# script crashes

**Skill Script Robustness:**
- Python: Crashes on empty CSV (stdev needs ≥2 values), IndexError on empty rows
- C#: No file lock handling, large-file strategy missing

**Demo UX:**
- No pre-flight validation
- Tenant awareness incomplete
- Deployment name hardcoded
- No User Secrets env var fallback

**Critical Actions:**
1. Add pre-flight validation (secrets, skills dir, Python availability)
2. Fix Python edge cases (empty CSV, malformed data)
3. Improve error messages with actionable next steps
4. Add test coverage (minimum: skill scripts, integration)

**Risk if Not Addressed:**
- Users clone → demo fails with cryptic error → poor impression
- Contributors can't refactor skills confidently
- Support questions proliferate

---

#### D. Code & Packages (Linus)

**Status:** Updated in linus/history.md  
Code structure review and dependency analysis contributed to cross-domain assessment.

---

## Consensus Needed

1. **Prioritization:** Which improvements align with strategic goals?
2. **Design:** APIs/interfaces for streaming, multi-turn, multi-agent
3. **Implementation Planning:** Assign to Linus (code), Livingston (tests), Basher (infra)
4. **Timeline:** Demo-only vs. production-ready target?

---

## 2026-04-10: Phase 1 Implementation — Complete

**Status:** Implemented (Commit `06045c6` on `squad/improvement-plan`)  
**Contributors:** Linus, Basher, Livingston, Rusty

### Phase 1 Decisions Implemented

#### A. Code Quality (Linus)

**Decision:** Pin NuGet packages, add error handling, migrate to GA API, pre-flight validation

**Changes:**
- NuGet packages pinned to specific versions (GA: 1.0.0 for Agent Framework, latest stable for others)
- API migration: `FileAgentSkillsProvider` → `AgentSkillsProvider` (GA naming)
- Try/catch around all Azure calls (`RequestFailedException`, `OperationCanceledException`)
- `AzureCliCredential` → `DefaultAzureCredential` for broader auth support
- Pre-flight validation: skills directory, Python availability, config checks
- Edge case fixes: division-by-zero (analyze.cs), empty CSV (analyze.py)

**Outcome:** ✅ Build clean, all tests passing

---

#### B. Infrastructure (Basher)

**Decision:** Make setup.ps1 idempotent, parameterize Bicep, add CI/CD validation

**Changes:**
- `setup.ps1`: Idempotency checks (skip secrets if set), new flags (-WhatIf, -Force, -SkipSecrets), pre-flight for az/python
- `main.bicep`: Environment parameterization (dev/test/prod), auto-scaling capacity by env
- `model-deployment.bicep`: Extraction of deploymentName, SKU, capacity, version into parameters
- CI/CD: New `.github/workflows/validate-infra.yml` for Bicep lint/build on infra/ changes

**Outcome:** ✅ Bicep validates clean, setup.ps1 idempotent

---

#### C. Test Coverage (Livingston)

**Decision:** Create comprehensive test suite (22 tests) across skill scripts and pre-flight validation

**Changes:**
- Python skill tests (8): Valid CSV, empty CSV, single-row, text-only, mixed data, missing file, zero-byte file
- C# skill tests (5): Valid file, empty file, TODOs/long lines, missing file, clean file
- Pre-flight tests (9): Skills directory, SKILL.md, Python/dotnet availability, User Secrets

**Decisions for Team:**
- Python emoji encoding workaround: Tests use `PYTHONIOENCODING=utf-8` to handle `📊` crash on Windows cp1252
- Empty CSV and empty file fixes already implemented by Linus — tests validate these
- Test runner: `pwsh tests/run-tests.ps1` ready for CI integration

**Outcome:** ✅ 22/22 tests passing, bug discovered (emoji encoding on Windows — deferred to Phase 2)

---

#### D. Documentation (Rusty)

**Decision:** Create extending guide, error handling reference, improve README clarity

**Changes:**
- `docs/extending-framework.md` (13.5 KB): Skill anatomy, three skill types, step-by-step walkthrough, Sentiment Analyzer example, best practices, troubleshooting
- `docs/error-handling.md` (13.5 KB): 10+ common errors (Azure auth, Python paths, CSV format, etc.), quick diagnostic checklist
- `README.md`: Added prerequisites, decision tree, setup options clarity, success verification section, troubleshooting links

**Strategic Value:**
- Unblocks contributors to add skills without guidance
- Reduces support burden (error guide answers 10+ common questions)
- Improves new user success (setup clarity, verification checklist)
- Manages expectations (C# script limitation clearly noted)

**Outcome:** ✅ All 3 deliverables complete, cross-checked for accuracy

---

### Phase 1 Consensus

- **Quality gates passed:** All agents delivered with validation/testing
- **No blockers for merge:** Ready for PR review and landing to main
- **Deferred to Phase 2:** Emoji encoding fix (Windows charset), token usage/cost guide, skill schema validation doc

### Next Decisions Needed

1. **Phase 2 Architecture:** Design APIs for streaming, multi-turn conversation, multi-agent orchestration
2. **CI/CD Integration:** Wire test runner (`tests/run-tests.ps1`) into GitHub Actions
3. **Emoji Encoding:** Decide on fix strategy for analyze.py Windows charset issue (fallback vs encoding override)

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
