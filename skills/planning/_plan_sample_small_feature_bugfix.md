# Mini-Design: [Title]

> One-line description / scope statement.

**Issue:** [issue-slug]
**Branch:** `feat/[branch-name]`
**Status:** Pending | WIP | Done
**PRD:** `.feature-plans/pending/prd-<slug>.md` _(link if a PRD was written)_
**Parent design:** `.feature-plans/pending/design-<slug>.md` _(link if this is a sub-plan of a big-feature design)_

**Reference files:**
- Data / schema: `path/to/schema.ext`
- Core logic: `path/to/Module.ext`
- UI / entrypoint: `path/to/Entry.ext`
- Wiring (DI / routing / config): `path/to/wiring.ext`

---

## Problem

- What's broken / missing (1-3 bullets)
- Who's affected and how

## Out of Scope

- Explicit list of things this plan does NOT cover
- Deferred items or follow-up work

## Concept

- 1-3 bullets describing the feature / fix at a high level
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

## Architecture

```
[Component A] → [Component B] → [Store / DB]
                     ↓
              [Component C] → [UI / Output]
```

---

## Design Details

### Critical User Journeys (CUJs)

#### CUJ 1 — [Happy path title]

```
User opens [screen]
  → Taps [action]
  → System fetches / validates X
  → User sees [state A]
  → User confirms
  → System persists → shows success state
```

- **Error path:** what happens when X fails (network, validation, auth)
- **Edge case:** empty state / first-run / concurrent update

#### CUJ 2 — [Error / edge-case title]

```
User attempts [action] without [precondition]
  → System detects missing precondition
  → Shows [error / prompt] with recovery action
```

### Data Model

| Entity | Field | Type | Constraints | Notes |
|--------|-------|------|-------------|-------|
| `EntityName` | `id` | `UUID` | PK | |
| `EntityName` | `field` | `string` | NOT NULL | |
| `RelatedEntity` | `entity_id` | `UUID` | FK → Entity.id | |

- **Relationships:** Entity 1→N RelatedEntity; ...
- **Indexes:** `entity_id`, `(field, created_at)` for [query]
- **Migration:** Y — add `field`, backfill with `default`; or N

### API Contracts

```
POST /api/[resource]
  Request:  { field: type, ... }
  Response: { result: Type, meta: Meta }
  Errors:   400 VALIDATION_ERROR, 401 UNAUTHORIZED, 404 NOT_FOUND

GET /api/[resource]/:id
  Request:  —
  Response: { item: Type }
  Errors:   403 FORBIDDEN, 404 NOT_FOUND
```

_(One block per contract — REST endpoints, GraphQL mutations/queries, RPC methods, or internal service interfaces.)_

### Key Decisions

#### Decision 1: [Short title]

- **Decision:** what was chosen
- **Rationale:** why (tradeoff / constraint)
- **Where:** `file.ext:line` — what changes

```
// optional: critical snippet — only when the code pattern itself is the decision
```

#### Decision 2: [Short title]

- **Decision:** what was chosen
- **Rationale:** why (tradeoff / constraint)
- **Where:** `file.ext:line` — what changes

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
