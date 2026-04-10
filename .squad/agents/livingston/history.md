# Project Context

- **Owner:** Bruno Capuano
- **Project:** Agent Skills .NET Demo — A .NET 10 console app showcasing Microsoft Agent Framework Agent Skills with Azure OpenAI. Three demo skills: prompt-only (meeting-notes), .NET script (code-reviewer), Python script (data-analyzer).
- **Stack:** .NET 10, C#, Python, Azure OpenAI, Bicep, PowerShell, Azure Developer CLI (azd)
- **Created:** 2026-04-08

## Learnings

### Quality Analysis (2026-04-08)

**Test Coverage:**
- Zero tests exist. High priority: add unit tests for skill scripts, integration tests for FileAgentSkillsProvider, smoke tests for demo flow.
- Python script crashes on empty CSV (IndexError on stdev). C# script doesn't handle locked files or large files.

**Error Handling:**
- No validation that User Secrets are set until demo runs.
- No check if skills directory exists.
- Python availability not verified before demo starts.
- Azure credential failures show raw SDK exceptions instead of actionable guidance.
- C# script execution limitation (not supported in Agent Framework) not obvious to new users.

**Edge Cases:**
- **Python analyze.py**: Empty CSV crashes, malformed CSV silently skips columns, no encoding handling.
- **C# analyze.cs**: Doesn't handle file lock errors, no large-file handling, binary files treated as text.
- **Demo prompts**: Always use valid data; error paths untested.

**Configuration Robustness:**
- setup.ps1 has good fallback for endpoint extraction, but no pre-flight network checks.
- No validation that deployment name exists in Azure.
- No .env file fallback; only User Secrets supported.
- User must use exact secrets ID (`agent-skills-demo`) or demo silently fails.

**Demo UX Issues:**
- Fresh clone without setup fails at demo run with decent error message but no next step guidance.
- If Azure credential or network fails mid-demo, user sees raw SDK error.
- C# script limitation (documented in README as note) isn't obvious in practice — skill runs but script doesn't.

**Output Consistency:**
- AgentResponse text could be empty, truncated, or contain errors — no validation.
- Skill output format isn't validated against expected structure.
- Python script output format is non-deterministic based on input data.

**Recommended Priority:**
1. Add pre-flight validation (check creds, skills dir, Python).
2. Fix Python script robustness (empty CSV, malformed data).
3. Add test coverage for skill scripts.
4. Improve error messages with actionable guidance.
5. Add troubleshooting guide to README.

**Cross-Domain Context:**
- **Architecture (Rusty):** Multi-turn and streaming scenarios depend on robust error handling and validated configuration. Zero test coverage blocks confidence in feature implementations. Skill result handling (proposed architecture pattern) must include input validation and error recovery.
- **Infrastructure (Basher):** CI/CD gaps prevent validation of deployment changes. Proposed streaming + token tracking feature requires observability infrastructure (currently missing from Bicep). Multi-agent orchestration scenario will require conversation/session context persistence — not yet supported.
- **Code (Linus):** Demo lacks try/catch around Azure calls and doesn't validate skillsDir. Hardcoded AzureCliCredential prevents DefaultAzureCredential adoption. New architecture patterns (streaming, multi-turn, multi-agent) all depend on error recovery and graceful degradation — current demo has neither.

### Phase 1 Test Coverage (2026-04-10)

**Test Suite Created:** 22 tests across 3 suites — all passing.

- **Python tests (8):** Valid CSV, empty CSV, single-row, text-only columns, mixed data, missing file, zero-byte file, column names in output. Uses subprocess to test analyze.py as CLI tool.
- **C# tests (5):** Valid file, empty file (division-by-zero guard), TODOs/long lines counting, missing file, clean file. Uses `dotnet run` to test analyze.cs.
- **Pre-flight tests (9):** Skills directory structure, SKILL.md presence, Python/dotnet availability, User Secrets reference, skills path detection.

**Bug Found:** `📊` emoji in analyze.py causes `UnicodeEncodeError: 'charmap' codec can't encode character` on Windows terminals using cp1252 encoding. Tests work around this with `PYTHONIOENCODING=utf-8` but real users may hit this.

**Confirmed Fixes:** Linus already fixed empty CSV handling (now shows friendly message) and empty-file division-by-zero in C# script. Both edge-case tests pass.

**Infrastructure Note:** Test runner (`pwsh tests/run-tests.ps1`) is ready for CI integration. Basher can wire it into GitHub Actions when pipeline is set up.

**Phase 1 Team Outcome (2026-04-10):** Livingston delivered 22 passing tests on schedule. Full team completed Phase 1: Linus (7 code tasks), Basher (4 infra tasks), Rusty (3 docs deliverables). Commit `06045c6` on `squad/improvement-plan` contains all work and is ready for merge. No critical blockers. Deferred: emoji encoding fix (Windows charset), Phase 2 architecture design. Next: Wire test runner into GitHub Actions.
