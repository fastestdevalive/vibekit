# Feature Plan: [Title]

> One-line description / scope statement.

**Issue:** [issue-slug]
**Branch:** `feat/[branch-name]`
**Status:** Pending | WIP | Done

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

## Validation

- Unit test: [what to test]
- Integration test: [what to test]
- Regression: [what to verify still works]

---

## Implementation Phases

### Phase 1 — [Core / Data + Logic]

- [ ] **1.1** Schema changes in `schema.ext`
- [ ] **1.2** Core logic in `Module.ext`
- [ ] **1.3** State exposure in `ViewModel.ext`
- [ ] **1.4** Tests for the above

### Phase 2 — [UI / Entrypoint]

- [ ] **2.1** Routing / navigation
- [ ] **2.2** UI screen + state binding
- [ ] **2.3** DI / wiring registration

### Phase 3 — [Gating / Polish]

- [ ] **3.1** Feature flag / gating
- [ ] **3.2** Edge-case handling
- [ ] **3.3** Onboarding / docs

---

## Files Summary

| File | Phase | Change |
|------|-------|--------|
| `schema.ext` | 1.1 | Add new fields |
| `Module.ext` | 1.2 | Core logic |
| `ViewModel.ext` | 1.3 | Expose state |
| `routing.ext` | 2.1 | Add route |
| `wiring.ext` | 2.3 | Register new component |
