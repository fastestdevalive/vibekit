# Design: [Feature / System Name]

> One-line description of what this system/feature does and why it exists.

**Issue:** [issue-slug]
**Branch:** `feat/[branch-name]`
**Status:** Pending | WIP | Done
**PRD:** `.feature-plans/pending/prd-<slug>.md`

**Sub-plans spawned from this design:**
- [ ] `.feature-plans/pending/<slug>-part1.md` — [short title]
- [ ] `.feature-plans/pending/<slug>-part2.md` — [short title]
- [ ] `.feature-plans/pending/<slug>-part3.md` — [short title]

---

## Problem

- What gap or pain this design addresses (2-4 bullets)
- Who is affected and at what scale
- Why solving it now matters

## Out of Scope

- Explicit list of adjacent problems this design does NOT address
- Future phases / follow-up work
- Known non-goals

---

## Requirements

### Functional

| # | Requirement |
|---|-------------|
| F1 | |
| F2 | |

### Non-functional

| # | Requirement | Target |
|---|-------------|--------|
| N1 | Latency | p99 < Xms |
| N2 | Throughput | Y req/s |
| N3 | Availability | Z nines |
| N4 | Security / Auth | |
| N5 | Privacy / Data retention | |

---

## System Context

High-level boundary diagram — who talks to what.

```
┌─────────────┐        ┌─────────────┐        ┌─────────────┐
│   Client    │──────▶│   Server    │──────▶│  Database   │
│  (Mobile /  │◀──────│  (API /     │◀──────│  (Postgres/ │
│   Web)      │        │   Worker)   │        │   Redis)    │
└─────────────┘        └──────┬──────┘        └─────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  3rd-party / Host │
                    │  (Auth / Storage) │
                    └───────────────────┘
```

- **Client** — [responsibilities, e.g. renders UI, local state, optimistic updates]
- **Server** — [responsibilities, e.g. business logic, auth enforcement, orchestration]
- **Database** — [what's stored, consistency requirements]
- **3rd-party / Host** — [what's delegated, trust boundary]

---

## Entities & Modules

| Entity / Module | Layer | Responsibility | Key Dependencies |
|-----------------|-------|----------------|-----------------|
| `EntityA` | DB | Source of truth for X | — |
| `ServiceB` | Server | Orchestrates X → Y | `EntityA`, `ServiceC` |
| `ServiceC` | Server | Handles Z | `EntityA` |
| `StoreD` | Client | Local cache + optimistic state | `ServiceB` (via API) |
| `ViewModelE` | Client | Transforms store state for UI | `StoreD` |

---

## Alternatives Considered

| Option | Summary | Pros | Cons | Verdict |
|--------|---------|------|------|---------|
| **A — [name]** | | | | ✅ Chosen |
| **B — [name]** | | | | ❌ Rejected |
| **C — [name]** | | | | ❌ Deferred |

**Decision rationale:** 1-3 bullets on why A wins over B and C.

---

## API / Contract

### Endpoints (REST) / Events (async)

| Method | Path / Topic | Request | Response | Auth |
|--------|-------------|---------|----------|------|
| `POST` | `/api/v1/resource` | `{field: type}` | `{id, status}` | Bearer |
| `GET` | `/api/v1/resource/:id` | — | `{...}` | Bearer |

### Key Data Schemas

```
ResourceCreate {
  field_a: string        // description
  field_b: int           // description
  field_c?: string       // optional, description
}

ResourceResponse {
  id:        uuid
  status:    "pending" | "active" | "done"
  created_at: timestamp
}
```

---

## Data Model

### New / Modified Tables

| Table | Field | Type | Notes |
|-------|-------|------|-------|
| `resources` | `id` | uuid PK | |
| `resources` | `status` | enum | pending / active / done |
| `resources` | `owner_id` | uuid FK → users | indexed |

- Migrations needed: Y — [brief description of migration steps]
- Backwards-compatible: Y/N — why

---

## Critical User Journeys (CUJs)

### CUJ 1 — [Happy path name]

```
User                Client              Server             DB
 │                    │                   │                 │
 │── tap [action] ──▶│                   │                 │
 │                    │── POST /resource ▶│                 │
 │                    │                   │── INSERT ──────▶│
 │                    │                   │◀── row ─────────│
 │                    │◀── 201 {id} ──────│                 │
 │◀── show success ───│                   │                 │
```

- Preconditions: user is authenticated, X exists
- Success: resource created, UI updates optimistically
- Error paths: → CUJ 3

---

### CUJ 2 — [Secondary happy path]

```
User                Client              Server
 │                    │                   │
 │── open screen ───▶│                   │
 │                    │── GET /resources ▶│
 │                    │◀── 200 [list] ────│
 │◀── render list ────│                   │
```

---

### CUJ 3 — [Error / edge case]

```
User                Client              Server
 │                    │                   │
 │                    │── POST /resource ▶│
 │                    │                   │── validation fails
 │                    │◀── 422 {error} ───│
 │◀── show inline ────│                   │
     error toast
```

- Error conditions: missing required field, duplicate, quota exceeded
- Recovery: user can retry inline without losing form state

---

## Rollout Strategy

| Stage | Audience | Gate | Success Signal |
|-------|----------|------|---------------|
| Internal alpha | Team only | flag `design_x_alpha` | No crashes, core CUJs work |
| Beta | X% of [segment] | flag `design_x_beta` | Retention / error rate within target |
| GA | All users | flag removed | Metrics stable for N days |

- Kill-switch: disable flag → falls back to [old behavior]
- Monitoring: [dashboard / alert names]

---

## Risks / Open Questions

| # | Question | Notes |
|---|----------|-------|
| 1 | **Short question?** | Brief answer / tradeoff |
| 2 | **Short question?** | Brief answer / tradeoff |

---

## Sub-Plan Breakdown

This design is implemented via the following mini-designs, each owning its own phases + verification.

| Sub-plan | Scope | Dependencies |
|----------|-------|-------------|
| [`<slug>-part1`](./<slug>-part1.md) | Data model + core service | none |
| [`<slug>-part2`](./<slug>-part2.md) | API layer | part1 done |
| [`<slug>-part3`](./<slug>-part3.md) | Client / UI | part2 done |

> Each sub-plan uses the **mini-design template** and carries its own phased checklist + test verification.
> This design doc is not re-opened once sub-plans are drafted — it is the stable reference.
