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
