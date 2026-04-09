# Decisions

## Decision: Publish Comprehensive Improvement Plan

**Date:** 2026-04-08  
**Owner:** Rusty (Lead)  
**Status:** Published — Awaiting Review + Prioritization  
**Audience:** Bruno Capuano, Squad Team  

### Summary

Consolidated four-perspective analysis (Rusty architecture, Linus code, Basher infrastructure, Livingston quality) into a comprehensive, actionable improvement plan.

### What Was Decided

**Create `docs/improvement-plan.md`** as the single source of truth for quarterly planning.

**Plan Structure:**
- Executive summary + current state
- Priority matrix (32 items: 4 critical, 10 high, 12 medium, 6 lower)
- 7 improvement domains with detailed rationale and effort estimates
- 3-phase implementation roadmap (Foundations → Features → Polish)
- Team assignments with clear ownership

### Why

- **Analysis paralysis risk:** Four reports (decisions.md) fragmented; lack unified direction
- **Planning clarity:** Quantified effort estimates (80–90 hours total) enable resource allocation
- **Phasing benefit:** Stabilize core (Phase 1) before feature work (Phase 2) prevents cascading failures
- **Critical path:** Package pinning + error handling + pre-flight validation are blockers for robustness
- **Contributor onboarding:** "Extending Framework" guide enables independent skill development

### Implications

#### Team Capacity
- **Phase 1:** 25–30 hours across all agents (2–3 weeks part-time)
- **Phase 2:** 30–35 hours (3–4 weeks)
- **Phase 3:** 25–30 hours (2 weeks, optional)
- **Total:** 80–95 hours over ~8 weeks

#### Dependencies
- Phase 1 (package pinning, error handling) is prerequisite for Phase 2 (streaming, multi-turn)
- Documentation (Rusty Phase 1) enables contributor work in Phase 2

#### Risk Mitigation
- Wildcard versions: **Phase 1 CRITICAL** (non-reproducible builds)
- Skill edge cases: **Phase 1 CRITICAL** (demo stability)
- Missing documentation: **Phase 1 HIGH** (contributor friction)

### No Implementation Required

This document is **plan only**. Implementation tickets will be created separately pending Bruno's approval of prioritization.

### Next Steps

1. ✅ Bruno reviews plan (target: 2026-04-09)
2. ⏳ Squad aligns on Phase 1 scope (Rusty facilitates)
3. ⏳ Create GitHub issues for Phase 1 work
4. ⏳ Assign to Q2 sprints / quarterly goals

---

**Branch:** `squad/improvement-plan` (pushed to remote)  
**Commit:** `c79757a` — "docs: Add improvement plan from team analysis"  
**Ready for:** Bruno's review and prioritization decision
