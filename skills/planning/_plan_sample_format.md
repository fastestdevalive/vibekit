# Feature Plan: [Title]

> One-line description / scope statement.

**Issue:** [issue-slug]
**Branch:** `feat/[branch-name]`
**Status:** Pending | WIP | Done
**PRD:** `.feature-plans/pending/prd-<slug>.md` _(link if a PRD was written)_

**Reference files:**
- Data / schema: `path/to/schema.ext`
- Core logic: `path/to/Module.ext`
- UI / entrypoint: `path/to/Entry.ext`
- Wiring (DI / routing / config): `path/to/wiring.ext`

---

## Problem

- What's broken / missing (1-3 bullets)
- Who's affected and how

## Concept

- 1-3 bullets describing the feature at a high level
- What user-facing behavior changes
- What the success state looks like

## Requirements

| # | Requirement |
|---|-------------|
| 1 | Functional requirement |
| 2 | Non-functional / constraint |
| 3 | Rollout / gating rule |

---

## Research

Bullet-point findings only. Include file paths + line numbers. No prose.

### [Code path / area name]

- **File:** `path/to/file.ext:123`
- **Trigger:** when X happens
- **Risk:** HIGH / MEDIUM / LOW — why

### [Another area]

- ...

## Root Cause

- Core issue in 1-2 bullets
- Secondary factors as sub-bullets

---

## Approach

### Architecture

- Option chosen and 1-line rationale
- Key trade-offs vs alternatives (table if >2 options)

```
User action → Controller → Service → Store
                ↓
           UI state → Render
```

### Data Model

- Schema changes (1-line per field)
- Migration needed? Y/N — why

### Fix N: [Short title]

- What changes, where (`file.ext:line`)
- Key behavioral difference from current code

---

## Files to Modify

| File | Change |
|------|--------|
| `path/to/file.ext` | Brief description |

## Risks / Open Questions

| # | Question | Notes |
|---|----------|-------|
| 1 | **Short question?** | Brief answer / tradeoff |

---

## Implementation Phases

Each phase ends with a **verification block** — the phase is not complete until those tests pass.

Test items use `N.Tn` numbering (`1.T1`, `1.T2`, `2.T1` …) to distinguish them from implementation items.
Unit tests verify isolated logic; integration tests verify an end-to-end flow or boundary.

---

### Phase 1 — [Core / Data + Logic]

- [ ] **1.1** Schema changes in `schema.ext`
- [ ] **1.2** Core logic in `Module.ext`
- [ ] **1.3** State exposure in `ViewModel.ext`

**Verify phase 1:**
- [ ] **1.T1** Unit — `ModuleTest`: [specific assertion — e.g. "returns null when input is empty"]
- [ ] **1.T2** Unit — `ViewModelTest`: [state emitted when X — e.g. "emits Loading then Success on valid input"]
- [ ] **1.T3** Integration — `[flow description]`: [trigger → expected outcome — e.g. "saving entity persists to DataStore and re-emits from Flow"]

---

### Phase 2 — [UI / Entrypoint]

- [ ] **2.1** Routing / navigation in `routing.ext`
- [ ] **2.2** UI screen + state binding in `Screen.ext`
- [ ] **2.3** DI / wiring registration in `wiring.ext`

**Verify phase 2:**
- [ ] **2.T1** Unit — `ScreenTest`: [UI renders correct state — e.g. "shows empty state when list is empty"]
- [ ] **2.T2** Integration — `[navigation flow]`: [user taps X → correct screen appears with expected state]

---

### Phase 3 — [Gating / Polish]

- [ ] **3.1** Feature flag / gating
- [ ] **3.2** Edge-case handling
- [ ] **3.3** Onboarding / docs

**Verify phase 3:**
- [ ] **3.T1** Integration — `[gating flow]`: [free-tier user sees correct locked state; paid user sees unlocked]
- [ ] **3.T2** Regression — `[existing flow]`: [previously working behavior still passes]

---

## Files Summary

| File | Phase | Change |
|------|-------|--------|
| `schema.ext` | 1.1 | Add new fields |
| `Module.ext` | 1.2 | Core logic |
| `ViewModel.ext` | 1.3 | Expose state |
| `routing.ext` | 2.1 | Add route |
| `wiring.ext` | 2.3 | Register new component |
| `ModuleTest.ext` | 1.T1 | New unit tests |
| `ViewModelTest.ext` | 1.T2 | New unit tests |
| `ScreenTest.ext` | 2.T1 | New UI tests |
