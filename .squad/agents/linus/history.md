# Project Context

- **Owner:** Bruno Capuano
- **Project:** Agent Skills .NET Demo — A .NET 10 console app showcasing Microsoft Agent Framework Agent Skills with Azure OpenAI. Three demo skills: prompt-only (meeting-notes), .NET script (code-reviewer), Python script (data-analyzer).
- **Stack:** .NET 10, C#, Python, Azure OpenAI, Bicep, PowerShell, Azure Developer CLI (azd)
- **Created:** 2026-04-08

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

- **2026-04-08 — Package audit:** The `#:package` directives use `*-*` wildcards for 4 of 6 packages, which pulls the latest prerelease. `Microsoft.Agents.AI` and `Microsoft.Agents.AI.OpenAI` now have stable 1.0.0 GA releases (April 2026). `Azure.AI.OpenAI` is pinned at `2.8.0-beta.1`; latest is `2.9.0-beta.1`, and latest stable is `2.7.0`. `Azure.Identity` latest stable is `1.20.0`. `Microsoft.Extensions.Configuration[.UserSecrets]` latest stable is `10.0.5`.
- **2026-04-08 — Code quality review:** Main demo is clean top-level-statements code but lacks error handling around Azure OpenAI calls (no try/catch, no CancellationToken, no graceful failure). Each `RunAsync` call creates a new conversation — no session/thread reuse shown. `AzureCliCredential` is hardcoded rather than `DefaultAzureCredential`. `skillsDir` path assumes CWD is repo root without validation.
- **2026-04-08 — Skill scripts:** `analyze.cs` is minimal (line count + TODOs only). `analyze.py` has no `requirements.txt` and crashes on empty CSV (division-by-zero if `totalLines == 0` in .cs, and `rows[0]` IndexError in .py on empty files). Neither script has argument validation.
- **2026-04-08 — Missing patterns:** Demo doesn't show multi-turn conversation, streaming responses, CancellationToken usage, OpenTelemetry observability, or the `DefaultAzureCredential` pattern — all important .NET 10 / Agent Framework 1.0 patterns for a demo.
- **2026-04-09 — Phase 1 code quality:** Pinned all NuGet packages to specific versions (eliminated `*-*` wildcards). Migrated from `FileAgentSkillsProvider` to `AgentSkillsProvider` (GA 1.0.0 API rename). Added try/catch around all `RunAsync` calls with `RequestFailedException`/`OperationCanceledException` handling. Replaced `AzureCliCredential` with `DefaultAzureCredential`. Added pre-flight validation (skills dir, config, Python). Fixed division-by-zero in analyze.cs and edge cases in analyze.py. Build verified clean.
- **Cross-Domain Integration (2026-04-09):** Improvement analysis surfaces prioritized opportunities across architecture, infrastructure, and quality. Architecture roadmap (multi-agent orchestration, streaming, multi-turn) depends on: (1) Error handling and credential validation patterns not yet shown (Quality/Livingston finding), (2) CI/CD infrastructure validation and parameterized deployments not yet in place (Infrastructure/Basher finding), (3) Testable patterns and integration design. Code quality improvements (try/catch around Azure calls, DefaultAzureCredential, skillsDir validation) are immediate prerequisites for feature development. Streaming and multi-turn require session/context storage and observability — architectural decisions needed before implementation.
