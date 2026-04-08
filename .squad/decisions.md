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

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
