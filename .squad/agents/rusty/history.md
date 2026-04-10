# Project Context

- **Owner:** Bruno Capuano
- **Project:** Agent Skills .NET Demo — A .NET 10 console app showcasing Microsoft Agent Framework Agent Skills with Azure OpenAI. Three demo skills: prompt-only (meeting-notes), .NET script (code-reviewer), Python script (data-analyzer).
- **Stack:** .NET 10, C#, Python, Azure OpenAI, Bicep, PowerShell, Azure Developer CLI (azd)
- **Created:** 2026-04-08

## Learnings

### Analysis: Improvement Opportunities (Completed 2026-04-09)

**Current State Snapshot:**
- Demo covers 3 skill types: prompt-only, .NET script, Python script
- Uses single-shot prompting with inline sample data
- FileAgentSkillsProvider handles skill discovery and registration
- Documentation spans README.md, docs/, and SKILL.md files
- Architecture: simple one-agent-per-demo pattern

**Key Gaps Identified:**
1. **No multi-agent orchestration** — No demos of agent-to-agent delegation or team workflows
2. **No streaming examples** — Single-shot responses only; no streaming implementation
3. **No conversation history** — Each prompt is independent; no multi-turn context
4. **Limited error handling** — No null checks, exception handling, or skill failure recovery
5. **Missing skill types** — No HTTP API skills, database query skills, or webhook examples
6. **Documentation gaps** — Skills-reference.md is sparse; no "extending the framework" guide
7. **No performance considerations** — Token usage, model selection rationale not covered
8. **Setup path confusion** — 3 separate credential paths (User Secrets vs env vars vs CLI) not clearly differentiated
9. **Testing story** — No unit tests, integration tests, or skill validation examples
10. **Script execution gap** — C# script execution noted as "not yet supported" but workaround unclear

**Architecture Insights:**
- FileAgentSkillsProvider is the right abstraction but only shows one pattern
- ChatClientAgent + skills tooling is solid but underexplored (no streaming, no tool result handling shown)
- Skill selection is automatic (good UX) but no explicit routing or conditional skill loading
- No handler for skill failures or fallback patterns

**Cross-Domain Context:**
- **Infrastructure (Basher):** IaC patterns are modern; gaps in parameterization and CI/CD alignment. Architecture decisions on streaming/multi-agent will impact deployment strategy.
- **Quality (Livingston):** Zero test coverage and unhandled error paths directly block multi-turn/streaming scenarios. Architecture improvements must include testability design.
- **Code (Linus):** Demo is clean but lacks error handling; underexplores framework patterns. New scenarios (streaming, multi-turn) require credential/token management patterns not yet shown.

### Phase 1 Documentation Improvements (Completed 2026-04-09)

**Deliverables:**
1. **`docs/extending-framework.md`** — 13.5 KB guide for contributors building new skills
   - Skill anatomy (SKILL.md format, frontmatter, instructions)
   - Three skill types with examples (prompt-only, .NET script, Python script)
   - Step-by-step skill creation walkthrough
   - Complete "Sentiment Analyzer" worked example
   - Best practices (naming, descriptions, robustness)
   - Troubleshooting (discovery, script execution, Python paths)

2. **`docs/error-handling.md`** — 13.5 KB reference for 10+ common errors
   - Azure credential failures (tenant, auth, token cache)
   - Rate limiting (429) with retry strategy
   - Missing skills directory (validation checks)
   - Python not available (installation, PATH)
   - User Secrets not configured (setup.ps1 vs manual)
   - Network/connectivity issues (firewall, outages, proxy)
   - CSV/data format errors (edge cases, robustness)
   - C# script execution status (not yet supported, workaround noted)
   - Setup.ps1 failures (permissions, resource conflicts)
   - Quick diagnostic checklist (6-step verification)

3. **`README.md`** — Surgical improvements to clarity
   - Added prerequisites callout (Azure CLI for setup.ps1)
   - Setup decision tree ("Do you have Azure OpenAI?")
   - Clarified Option A vs B paths
   - Emphasized exact `az login` command copy-paste (prevents tenant confusion)
   - New "Verify Your Setup" section (success checklist)
   - New "Troubleshooting" section (top 5 issues + link to full guide)
   - Split "Learn More" into "Our Docs" and "Official Resources"

**Key Decisions:**
- All skill examples reference actual demo skills (accuracy)
- Included actual code snippets (analyze.cs, analyze.py patterns) for clarity
- Prominent note about C# script execution framework limitation (manages expectations)
- Error guide uses structured format (What It Looks Like → Root Causes → How to Fix → Prevention)
- README maintains tone (practical, demo-appropriate) while adding clarity

**Quality Gates Passed:**
- ✅ Completeness (all skill types, all error categories, full setup paths)
- ✅ Accuracy (reviewed SKILL.md, scripts, setup procedures)
- ✅ Usability (markdown formatting, code blocks, tables, emoji indicators, cross-links)
- ✅ Tone (practical, not enterprise-heavy; respectful of user time)

**Strategic Value:**
- Unblocks contributors to add skills without guidance
- Reduces support burden (error guide answers 10+ common questions)
- Improves new user success (setup clarity + verification section)
- Manages expectations (C# script limitation clearly noted)

**Phase 1 Team Outcome (2026-04-10):** Rusty delivered all 3 documentation deliverables on schedule (extending-framework guide, error-handling reference, README improvements). Full team completed Phase 1 successfully: Linus (7 code tasks), Basher (4 infra tasks), Livingston (22 tests), Rusty (3 docs). Commit `06045c6` on `squad/improvement-plan` contains all Phase 1 work and is ready for PR review to main. No critical blockers. Deferred to Phase 2: emoji encoding fix (Windows charset), architecture design for streaming/multi-agent/multi-turn scenarios, token usage/cost guide.
